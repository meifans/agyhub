import AppKit
import Combine
import CoreServices
import Foundation
import ServiceManagement

final class DebouncedTrigger: @unchecked Sendable {
    private let lock = NSLock()
    private let debounceInterval: TimeInterval
    private let maxCoalesceDelay: TimeInterval?
    private let queue: DispatchQueue
    private let action: () -> Void
    private var pendingWorkItem: DispatchWorkItem?
    private var firstPendingAt: Date?

    init(
        debounceInterval: TimeInterval = 0.4,
        maxCoalesceDelay: TimeInterval? = 1.6,
        queue: DispatchQueue = DispatchQueue(label: "com.antigravity.agyhub.debouncer", qos: .utility),
        action: @escaping () -> Void
    ) {
        self.debounceInterval = max(0.01, debounceInterval)
        self.maxCoalesceDelay = maxCoalesceDelay
        self.queue = queue
        self.action = action
    }

    func signal() {
        lock.lock()
        pendingWorkItem?.cancel()
        let now = Date()
        if firstPendingAt == nil {
            firstPendingAt = now
        }

        var delay = debounceInterval
        if let maxDelay = maxCoalesceDelay, let first = firstPendingAt {
            let remaining = max(0.0, maxDelay - now.timeIntervalSince(first))
            delay = min(delay, remaining)
        }

        var itemRef: DispatchWorkItem?
        let item = DispatchWorkItem { [weak self] in
            guard let self = self, let current = itemRef else { return }
            self.lock.lock()
            let shouldFire = !current.isCancelled && (self.pendingWorkItem === current)
            if shouldFire {
                self.pendingWorkItem = nil
                self.firstPendingAt = nil
            }
            self.lock.unlock()
            if shouldFire {
                self.action()
            }
        }
        itemRef = item
        pendingWorkItem = item
        lock.unlock()

        queue.asyncAfter(deadline: .now() + delay, execute: item)
    }

    func cancel() {
        lock.lock()
        pendingWorkItem?.cancel()
        pendingWorkItem = nil
        firstPendingAt = nil
        lock.unlock()
    }

    deinit {
        cancel()
    }
}

final class SessionDirectoryWatcher: @unchecked Sendable {
    private final class CallbackBox {
        weak var watcher: SessionDirectoryWatcher?
        init(watcher: SessionDirectoryWatcher) {
            self.watcher = watcher
        }
    }

    private let lock = NSLock()
    private let watchQueue = DispatchQueue(label: "com.antigravity.agyhub.fsevents", qos: .utility)
    private let debouncer: DebouncedTrigger
    private let missingDirectoryCheckInterval: TimeInterval
    private let onChange: () -> Void

    private var candidatePaths: [String]
    private var watchedPathsStorage: [String] = []
    private var missingPathsStorage: [String] = []
    private var streamRef: FSEventStreamRef?
    private var callbackBox: CallbackBox?
    private var missingTimer: DispatchSourceTimer?
    private var isStarted: Bool = false

    static func defaultCandidatePaths(homeDir: String, extraDataDirs: [String] = []) -> [String] {
        var raw = [
            "\(homeDir)/.gemini/antigravity/brain",
            "\(homeDir)/.gemini/antigravity-cli/brain"
        ]
        for dir in extraDataDirs where !dir.isEmpty {
            let trimmed = dir.hasSuffix("/") ? String(dir.dropLast()) : dir
            raw.append("\(trimmed)/brain")
        }
        var seen: Set<String> = []
        var result: [String] = []
        for path in raw {
            let normalized = (path as NSString).standardizingPath
            if seen.insert(normalized).inserted {
                result.append(normalized)
            }
        }
        return result
    }

    static func partitionWatchTargets(
        _ candidatePaths: [String],
        fileManager: FileManager = .default
    ) -> (existing: [String], missing: [String]) {
        var existing: [String] = []
        var missing: [String] = []
        for path in candidatePaths {
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue {
                existing.append(path)
            } else {
                missing.append(path)
            }
        }
        return (existing, missing)
    }

    var watchedPaths: [String] {
        lock.lock()
        defer { lock.unlock() }
        return watchedPathsStorage
    }

    var missingPaths: [String] {
        lock.lock()
        defer { lock.unlock() }
        return missingPathsStorage
    }

    init(
        candidatePaths: [String],
        debounceInterval: TimeInterval = 0.4,
        missingDirectoryCheckInterval: TimeInterval = 15.0,
        onChange: @escaping () -> Void
    ) {
        self.candidatePaths = candidatePaths
        self.missingDirectoryCheckInterval = max(0.05, missingDirectoryCheckInterval)
        self.onChange = onChange
        self.debouncer = DebouncedTrigger(
            debounceInterval: debounceInterval,
            maxCoalesceDelay: max(debounceInterval * 4.0, 0.6),
            action: onChange
        )
    }

    func start() {
        lock.lock()
        if isStarted {
            lock.unlock()
            return
        }
        isStarted = true
        rebuildStreamLocked()
        updateMissingTimerLocked()
        lock.unlock()
    }

    func updateCandidatePaths(_ newCandidates: [String]) {
        lock.lock()
        guard newCandidates != candidatePaths else {
            lock.unlock()
            return
        }
        candidatePaths = newCandidates
        if isStarted {
            rebuildStreamLocked()
            updateMissingTimerLocked()
        }
        lock.unlock()
    }

    func stop() {
        lock.lock()
        isStarted = false
        cancelMissingTimerLocked()
        teardownStreamLocked()
        watchedPathsStorage = []
        missingPathsStorage = []
        lock.unlock()
        debouncer.cancel()
    }

    @discardableResult
    func reconcileWatchedDirectories(triggerOnNewDirectory: Bool = true) -> Bool {
        lock.lock()
        guard isStarted else {
            lock.unlock()
            return false
        }
        let partition = Self.partitionWatchTargets(candidatePaths)
        let previouslyWatched = Set(watchedPathsStorage)
        let changed = (partition.existing != watchedPathsStorage) || (partition.missing != missingPathsStorage)
        let hasNewlyCreated = partition.existing.contains { !previouslyWatched.contains($0) }
        if changed {
            rebuildStreamLocked()
            updateMissingTimerLocked()
        }
        lock.unlock()

        if hasNewlyCreated && triggerOnNewDirectory {
            debouncer.signal()
        }
        return changed
    }

    private func rebuildStreamLocked() {
        teardownStreamLocked()
        let partition = Self.partitionWatchTargets(candidatePaths)
        watchedPathsStorage = partition.existing
        missingPathsStorage = partition.missing

        guard !partition.existing.isEmpty else { return }

        let box = CallbackBox(watcher: self)
        self.callbackBox = box
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(box).toOpaque(),
            retain: { info in
                guard let info else { return nil }
                _ = Unmanaged<CallbackBox>.fromOpaque(info).retain()
                return UnsafeRawPointer(info)
            },
            release: { info in
                guard let info else { return }
                Unmanaged<CallbackBox>.fromOpaque(info).release()
            },
            copyDescription: nil
        )

        let flags = FSEventStreamCreateFlags(
            kFSEventStreamCreateFlagUseCFTypes
                | kFSEventStreamCreateFlagFileEvents
                | kFSEventStreamCreateFlagNoDefer
        )
        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            Self.fsEventsCallback,
            &context,
            partition.existing as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.15,
            flags
        ) else {
            self.callbackBox = nil
            return
        }

        FSEventStreamSetDispatchQueue(stream, watchQueue)
        if FSEventStreamStart(stream) {
            self.streamRef = stream
        } else {
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            self.callbackBox = nil
        }
    }

    private func teardownStreamLocked() {
        if let stream = streamRef {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            streamRef = nil
        }
        callbackBox = nil
    }

    private func updateMissingTimerLocked() {
        cancelMissingTimerLocked()
        guard isStarted, !missingPathsStorage.isEmpty else { return }
        let timer = DispatchSource.makeTimerSource(queue: watchQueue)
        timer.schedule(
            deadline: .now() + missingDirectoryCheckInterval,
            repeating: missingDirectoryCheckInterval
        )
        timer.setEventHandler { [weak self] in
            self?.reconcileWatchedDirectories(triggerOnNewDirectory: true)
        }
        timer.resume()
        missingTimer = timer
    }

    private func cancelMissingTimerLocked() {
        missingTimer?.cancel()
        missingTimer = nil
    }

    private static let fsEventsCallback: FSEventStreamCallback = { _, clientCallBackInfo, numEvents, eventPaths, eventFlags, _ in
        guard let info = clientCallBackInfo else { return }
        let box = Unmanaged<CallbackBox>.fromOpaque(info).takeUnretainedValue()
        guard let watcher = box.watcher else { return }
        let cfArray = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue()
        let paths = (cfArray as NSArray).compactMap { $0 as? String }
        let flags = Array(UnsafeBufferPointer(start: eventFlags, count: numEvents))
        watcher.handleFSEvents(paths: paths, flags: flags)
    }

    private func handleFSEvents(paths: [String], flags: [FSEventStreamEventFlags]) {
        lock.lock()
        let active = isStarted
        lock.unlock()
        guard active else { return }

        var hasRelevantChange = false
        var needsReconcile = false
        for (idx, flag) in flags.enumerated() {
            if (flag & FSEventStreamEventFlags(kFSEventStreamEventFlagHistoryDone)) != 0 {
                continue
            }
            if (flag & FSEventStreamEventFlags(kFSEventStreamEventFlagRootChanged)) != 0 {
                needsReconcile = true
            }
            let path = idx < paths.count ? paths[idx] : ""
            if path.hasSuffix("/.DS_Store") {
                continue
            }
            hasRelevantChange = true
        }

        if needsReconcile {
            reconcileWatchedDirectories(triggerOnNewDirectory: false)
        }
        if hasRelevantChange {
            debouncer.signal()
        }
    }

    deinit {
        stop()
    }
}

final class MonitorDaemonClient: @unchecked Sendable {
    enum DaemonError: Error, Equatable {
        case shutDown
        case inBackoff
        case spawnFailed
        case eof
        case processExited(Int32)
        case timeout
        case invalidResponse
        case remoteError(String)
    }

    enum SnapshotResult: Equatable {
        case updated(payload: MonitorPayload, etag: String?)
        case unchanged(etag: String?)
    }

    private static let ignoreSIGPIPEOnce: Void = {
        signal(SIGPIPE, SIG_IGN)
    }()

    private let stateLock = NSLock()
    private let writeQueue = DispatchQueue(label: "com.antigravity.agyhub.daemon-write", qos: .utility)
    private let requestTimeout: TimeInterval
    private let initialBackoff: TimeInterval
    private let maxBackoff: TimeInterval
    private let gracefulShutdownWait: TimeInterval
    private let launchSpecProvider: (_ dataDir: String?) -> (executable: String, arguments: [String])

    private var process: Process?
    private var stdinHandle: FileHandle?
    private var stdoutHandle: FileHandle?
    private var stderrHandle: FileHandle?
    private var activeDataDir: String?
    private var activeGeneration: UInt64 = 0
    private var nextRequestId: Int = 1
    private var pendingWaiters: [String: (Result<Data, DaemonError>) -> Void] = [:]
    private var isShutDownFlag: Bool = false
    private var consecutiveFailures: Int = 0
    private var backoffUntil: Date = .distantPast

    init(
        requestTimeout: TimeInterval = 10.0,
        initialBackoff: TimeInterval = 1.0,
        maxBackoff: TimeInterval = 30.0,
        gracefulShutdownWait: TimeInterval = 0.4,
        launchSpecProvider: @escaping (_ dataDir: String?) -> (executable: String, arguments: [String])
    ) {
        _ = Self.ignoreSIGPIPEOnce
        self.requestTimeout = max(0.05, requestTimeout)
        self.initialBackoff = max(0.05, initialBackoff)
        self.maxBackoff = max(self.initialBackoff, maxBackoff)
        self.gracefulShutdownWait = max(0.05, gracefulShutdownWait)
        self.launchSpecProvider = launchSpecProvider
    }

    var isRunning: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return process?.isRunning ?? false
    }

    var isInBackoff: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return Date() < backoffUntil
    }

    var currentPID: Int32? {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard let proc = process, proc.isRunning else { return nil }
        return proc.processIdentifier
    }

    private struct DaemonScalarId: Decodable {
        let stringValue: String

        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let s = try? c.decode(String.self) {
                self.stringValue = s
            } else if let i = try? c.decode(Int.self) {
                self.stringValue = String(i)
            } else if let d = try? c.decode(Double.self) {
                self.stringValue = String(d)
            } else {
                throw DecodingError.typeMismatch(
                    String.self,
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported daemon id")
                )
            }
        }
    }

    private struct DaemonIdProbe: Decodable {
        let id: DaemonScalarId?
    }

    private struct EmptyDaemonPayload: Decodable {}

    private struct DaemonResponseEnvelope<Payload: Decodable>: Decodable {
        let ok: Bool?
        let error: String?
        let pong: Bool?
        let etag: String?
        let unchanged: Bool?
        let payload: Payload?
    }

    private struct DaemonRequest: Encodable {
        let id: String
        let cmd: String
        var lang: String? = nil
        var ifNoneMatch: String? = nil
        var days: Int? = nil
        var sessionId: String? = nil

        enum CodingKeys: String, CodingKey {
            case id, cmd, lang, days
            case ifNoneMatch = "if_none_match"
            case sessionId = "session_id"
        }
    }

    func ping(dataDir: String? = nil) -> Result<Bool, DaemonError> {
        let request = DaemonRequest(id: "", cmd: "ping")
        switch sendDecodedRequest(request, responseType: EmptyDaemonPayload.self, dataDir: dataDir) {
        case .success(let env):
            return .success(env.pong ?? true)
        case .failure(let err):
            return .failure(err)
        }
    }

    func fetchSnapshot(ifNoneMatch: String?, dataDir: String?, lang: String = "zh") -> Result<SnapshotResult, DaemonError> {
        let request = DaemonRequest(
            id: "",
            cmd: "snapshot",
            lang: lang,
            ifNoneMatch: (ifNoneMatch?.isEmpty == false) ? ifNoneMatch : nil
        )
        switch sendDecodedRequest(request, responseType: MonitorPayload.self, dataDir: dataDir) {
        case .success(let env):
            if env.unchanged ?? false {
                return .success(.unchanged(etag: env.etag))
            }
            guard let decoded = env.payload else {
                return .failure(.invalidResponse)
            }
            return .success(.updated(payload: decoded, etag: env.etag))
        case .failure(let err):
            return .failure(err)
        }
    }

    func fetchRecent503(dataDir: String?) -> Result<Recent503Stats, DaemonError> {
        let request = DaemonRequest(id: "", cmd: "recent_503")
        switch sendDecodedRequest(request, responseType: Recent503Stats.self, dataDir: dataDir) {
        case .success(let env):
            guard let decoded = env.payload else {
                return .failure(.invalidResponse)
            }
            return .success(decoded)
        case .failure(let err):
            return .failure(err)
        }
    }

    func fetchUsageHistory(days: Int = 30, dataDir: String?) -> Result<UsageHistoryPayload, DaemonError> {
        let request = DaemonRequest(id: "", cmd: "usage_history", days: days)
        switch sendDecodedRequest(request, responseType: UsageHistoryPayload.self, dataDir: dataDir) {
        case .success(let env):
            guard let decoded = env.payload else {
                return .failure(.invalidResponse)
            }
            return .success(decoded)
        case .failure(let err):
            return .failure(err)
        }
    }

    func analyzeSession(uuid: String, dataDir: String?, lang: String = "zh") -> Result<SessionDiagnosticsPayload, DaemonError> {
        let request = DaemonRequest(id: "", cmd: "analyze_session", lang: lang, sessionId: uuid)
        switch sendDecodedRequest(request, responseType: SessionDiagnosticsPayload.self, dataDir: dataDir) {
        case .success(let env):
            guard let decoded = env.payload else {
                return .failure(.invalidResponse)
            }
            return .success(decoded)
        case .failure(let err):
            return .failure(err)
        }
    }

    func shutdown() {
        let detached: (proc: Process?, stdin: FileHandle?, stdout: FileHandle?, stderr: FileHandle?)
        let waiters: [(Result<Data, DaemonError>) -> Void]

        stateLock.lock()
        isShutDownFlag = true
        activeGeneration &+= 1
        waiters = Array(pendingWaiters.values)
        pendingWaiters.removeAll()
        detached = detachCurrentProcessLocked()
        stateLock.unlock()

        for waiter in waiters {
            waiter(.failure(.shutDown))
        }
        terminateDetachedProcess(detached, graceful: true)
    }

    private func sendDecodedRequest<Payload: Decodable>(
        _ template: DaemonRequest,
        responseType: Payload.Type,
        dataDir: String?
    ) -> Result<DaemonResponseEnvelope<Payload>, DaemonError> {
        switch sendRawRequest(template, dataDir: dataDir) {
        case .failure(let err):
            return .failure(err)
        case .success(let respLineData):
            guard let envelope = try? JSONDecoder().decode(DaemonResponseEnvelope<Payload>.self, from: respLineData) else {
                return .failure(.invalidResponse)
            }
            let ok = envelope.ok ?? false
            if !ok {
                let errMsg = envelope.error ?? "daemon error"
                return .failure(.remoteError(errMsg))
            }
            stateLock.lock()
            consecutiveFailures = 0
            backoffUntil = .distantPast
            stateLock.unlock()
            return .success(envelope)
        }
    }

    private func sendRawRequest(
        _ template: DaemonRequest,
        dataDir: String?
    ) -> Result<Data, DaemonError> {
        var processToTerminate: (proc: Process?, stdin: FileHandle?, stdout: FileHandle?, stderr: FileHandle?)? = nil
        var staleWaiters: [(Result<Data, DaemonError>) -> Void] = []

        stateLock.lock()
        if isShutDownFlag {
            stateLock.unlock()
            return .failure(.shutDown)
        }
        if Date() < backoffUntil {
            stateLock.unlock()
            return .failure(.inBackoff)
        }

        if let existing = process, (!existing.isRunning || activeDataDir != dataDir) {
            staleWaiters = Array(pendingWaiters.values)
            pendingWaiters.removeAll()
            activeGeneration &+= 1
            processToTerminate = detachCurrentProcessLocked()
        }
        stateLock.unlock()

        for waiter in staleWaiters {
            waiter(.failure(.eof))
        }
        if let old = processToTerminate {
            terminateDetachedProcess(old, graceful: true)
        }

        let sem = DispatchSemaphore(value: 0)
        var capturedResult: Result<Data, DaemonError> = .failure(.eof)

        stateLock.lock()
        if isShutDownFlag {
            stateLock.unlock()
            return .failure(.shutDown)
        }
        if Date() < backoffUntil {
            stateLock.unlock()
            return .failure(.inBackoff)
        }
        if process == nil {
            if !spawnProcessLocked(dataDir: dataDir) {
                recordFailureLocked()
                stateLock.unlock()
                return .failure(.spawnFailed)
            }
        }

        let reqId = "\(nextRequestId)"
        nextRequestId += 1
        let gen = activeGeneration
        guard let writeHandle = stdinHandle else {
            recordFailureLocked()
            let dead = detachCurrentProcessLocked()
            stateLock.unlock()
            terminateDetachedProcess(dead, graceful: false)
            return .failure(.spawnFailed)
        }

        pendingWaiters[reqId] = { res in
            capturedResult = res
            sem.signal()
        }
        stateLock.unlock()

        let request = DaemonRequest(
            id: reqId,
            cmd: template.cmd,
            lang: template.lang,
            ifNoneMatch: template.ifNoneMatch,
            days: template.days,
            sessionId: template.sessionId
        )
        guard let jsonData = try? JSONEncoder().encode(request) else {
            stateLock.lock()
            _ = pendingWaiters.removeValue(forKey: reqId)
            stateLock.unlock()
            return .failure(.invalidResponse)
        }
        var lineData = jsonData
        lineData.append(0x0A)

        let writeSucceeded: Bool = writeQueue.sync {
            do {
                try writeHandle.write(contentsOf: lineData)
                return true
            } catch {
                return false
            }
        }

        if !writeSucceeded {
            var removedWaiter: ((Result<Data, DaemonError>) -> Void)? = nil
            var dead: (proc: Process?, stdin: FileHandle?, stdout: FileHandle?, stderr: FileHandle?)? = nil
            var otherWaiters: [(Result<Data, DaemonError>) -> Void] = []
            stateLock.lock()
            removedWaiter = pendingWaiters.removeValue(forKey: reqId)
            if activeGeneration == gen {
                activeGeneration &+= 1
                otherWaiters = Array(pendingWaiters.values)
                pendingWaiters.removeAll()
                dead = detachCurrentProcessLocked()
                recordFailureLocked()
            }
            stateLock.unlock()

            _ = removedWaiter
            for w in otherWaiters { w(.failure(.eof)) }
            if let dead { terminateDetachedProcess(dead, graceful: false) }
            return .failure(.eof)
        }

        let waitRes = sem.wait(timeout: .now() + requestTimeout)
        if waitRes == .timedOut {
            var timedOutSelfWaiter = false
            var otherWaiters: [(Result<Data, DaemonError>) -> Void] = []
            var hungProcess: (proc: Process?, stdin: FileHandle?, stdout: FileHandle?, stderr: FileHandle?)? = nil

            stateLock.lock()
            if pendingWaiters.removeValue(forKey: reqId) != nil {
                timedOutSelfWaiter = true
                if activeGeneration == gen {
                    activeGeneration &+= 1
                    otherWaiters = Array(pendingWaiters.values)
                    pendingWaiters.removeAll()
                    hungProcess = detachCurrentProcessLocked()
                    recordFailureLocked()
                }
            }
            stateLock.unlock()

            if timedOutSelfWaiter {
                for w in otherWaiters { w(.failure(.timeout)) }
                if let hungProcess {
                    terminateDetachedProcess(hungProcess, graceful: false)
                }
                return .failure(.timeout)
            }
        }

        return capturedResult
    }

    private func spawnProcessLocked(dataDir: String?) -> Bool {
        let spec = launchSpecProvider(dataDir)
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: spec.executable)
        proc.arguments = spec.arguments

        let inPipe = Pipe()
        let outPipe = Pipe()
        let errPipe = Pipe()
        proc.standardInput = inPipe
        proc.standardOutput = outPipe
        proc.standardError = errPipe

        errPipe.fileHandleForReading.readabilityHandler = { handle in
            autoreleasepool {
                _ = handle.availableData
            }
        }

        do {
            try proc.run()
        } catch {
            errPipe.fileHandleForReading.readabilityHandler = nil
            try? inPipe.fileHandleForWriting.close()
            try? outPipe.fileHandleForReading.close()
            try? errPipe.fileHandleForReading.close()
            return false
        }

        activeGeneration &+= 1
        let gen = activeGeneration
        self.process = proc
        self.stdinHandle = inPipe.fileHandleForWriting
        self.stdoutHandle = outPipe.fileHandleForReading
        self.stderrHandle = errPipe.fileHandleForReading
        self.activeDataDir = dataDir

        let outHandle = outPipe.fileHandleForReading
        let readerQueue = DispatchQueue(
            label: "com.antigravity.agyhub.daemon-read.\(gen)",
            qos: .utility,
            autoreleaseFrequency: .workItem
        )
        readerQueue.async { [weak self] in
            self?.readStdoutLoop(handle: outHandle, generation: gen)
        }
        return true
    }

    private func readStdoutLoop(handle: FileHandle, generation: UInt64) {
        var buffer = Data()
        let idDecoder = JSONDecoder()
        while true {
            var shouldStop = false
            autoreleasepool {
                let chunk = handle.availableData
                if chunk.isEmpty {
                    shouldStop = true
                    return
                }
                buffer.append(chunk)
                while let newlineIdx = buffer.firstIndex(of: 0x0A) {
                    let rawLine = buffer.subdata(in: buffer.startIndex..<newlineIdx)
                    buffer.removeSubrange(buffer.startIndex...newlineIdx)
                    autoreleasepool {
                        guard let lineText = String(data: rawLine, encoding: .utf8) else { return }
                        let trimmed = lineText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty,
                              let lineData = trimmed.data(using: .utf8),
                              let probe = try? idDecoder.decode(DaemonIdProbe.self, from: lineData),
                              let rawId = probe.id else {
                            return
                        }
                        let idStr = rawId.stringValue
                        stateLock.lock()
                        let isCurrentGen = (activeGeneration == generation)
                        let waiter = isCurrentGen ? pendingWaiters.removeValue(forKey: idStr) : nil
                        stateLock.unlock()
                        waiter?(.success(lineData))
                    }
                }
            }
            if shouldStop {
                break
            }
        }

        var waitersToFail: [(Result<Data, DaemonError>) -> Void] = []
        var detached: (proc: Process?, stdin: FileHandle?, stdout: FileHandle?, stderr: FileHandle?)? = nil
        var exitCode: Int32 = 0

        stateLock.lock()
        if activeGeneration == generation {
            activeGeneration &+= 1
            waitersToFail = Array(pendingWaiters.values)
            pendingWaiters.removeAll()
            let wasShutDown = isShutDownFlag
            detached = detachCurrentProcessLocked()
            if !wasShutDown {
                recordFailureLocked()
            }
        }
        stateLock.unlock()

        if let proc = detached?.proc {
            if !proc.isRunning {
                exitCode = proc.terminationStatus
            }
            terminateDetachedProcess(detached!, graceful: false)
        }
        let failureError: DaemonError = exitCode != 0 ? .processExited(exitCode) : .eof
        for waiter in waitersToFail {
            waiter(.failure(failureError))
        }
    }

    private func detachCurrentProcessLocked() -> (proc: Process?, stdin: FileHandle?, stdout: FileHandle?, stderr: FileHandle?) {
        let detached = (process, stdinHandle, stdoutHandle, stderrHandle)
        process = nil
        stdinHandle = nil
        stdoutHandle = nil
        stderrHandle = nil
        activeDataDir = nil
        return detached
    }

    private func terminateDetachedProcess(
        _ detached: (proc: Process?, stdin: FileHandle?, stdout: FileHandle?, stderr: FileHandle?),
        graceful: Bool
    ) {
        try? detached.stdin?.close()
        if let proc = detached.proc, proc.isRunning {
            if graceful {
                let deadline = Date().addingTimeInterval(gracefulShutdownWait)
                while proc.isRunning && Date() < deadline {
                    Thread.sleep(forTimeInterval: 0.015)
                }
            }
            if proc.isRunning {
                proc.terminate()
                let termDeadline = Date().addingTimeInterval(0.2)
                while proc.isRunning && Date() < termDeadline {
                    Thread.sleep(forTimeInterval: 0.015)
                }
                if proc.isRunning {
                    kill(proc.processIdentifier, SIGKILL)
                }
            }
        }
        detached.stderr?.readabilityHandler = nil
        try? detached.stdout?.close()
        try? detached.stderr?.close()
    }

    private func recordFailureLocked() {
        consecutiveFailures += 1
        let exponent = Double(min(max(0, consecutiveFailures - 1), 6))
        let delay = min(maxBackoff, initialBackoff * pow(2.0, exponent))
        backoffUntil = Date().addingTimeInterval(delay)
    }

    deinit {
        shutdown()
    }
}

@MainActor
final class AGYHubStore: ObservableObject {
    nonisolated static let defaultRefreshInterval: Double = 5.0

    @Published var payload: MonitorPayload = .empty
    @Published var profiles: [AGYProfile] = []
    @Published var activeProfileName: String = ""
    @Published var activeCLIProfileName: String? = nil
    @Published var appStorageEmail: String = ""
    @Published var expectedAppEmail: String = ""
    @Published var sharedKeychainResolution: CLIAccountManager.SharedKeychainResolution = .empty
    @Published var backgroundCLIProcessCount: Int = 0
    @Published var isCLIVaultAuthorized: Bool = UserDefaults.standard.bool(forKey: "agyhub.cliVaultAuthorized")
    @Published var isCLIIndependentMode: Bool = {
        if UserDefaults.standard.object(forKey: "agyhub.cliIndependentMode") != nil {
            return UserDefaults.standard.bool(forKey: "agyhub.cliIndependentMode")
        }
        return true
    }()
    @Published var savedCLISlots: Set<String> = []
    @Published var isCLITokenFileReady: Bool = true
    @Published var selectedSessionUUID: String? = nil
    @Published var sessionNavigationStack: [String] = []
    @Published var refreshInterval: Double = {
        let saved = UserDefaults.standard.double(forKey: "AGYHubRefreshInterval")
        return saved >= 0.2 ? saved : AGYHubStore.defaultRefreshInterval
    }()
    @Published var launchAtLogin: Bool = false
    @Published var isWindowPinned: Bool = false
    @Published var statusBannerMessage: String? = nil
    @Published var lastUpdatedTimeStr: String = "-"
    @Published var unifyLogMonitoring: Bool = true
    @Published var showSessionModelColumn: Bool = false
    @Published var expandedSessionRowLimit: Int = SessionListLayoutPolicy.defaultVisibleRowsWhenExpanded
    @Published var appLanguage: AppLanguage = .system
    @Published var accountQuotas: [String: AccountQuotaSummary] = [:]
    @Published var expiredQuotaEmails: Set<String> = []
    @Published var usageHistory: UsageHistoryPayload? = nil
    @Published var isLoadingUsageHistory: Bool = false
    @Published var isUsageDashboardPresented: Bool = false
    @Published var recent503Count: Int = 0
    @Published var recent503CheckedAt: Date? = nil
    @Published var activeDiagnosticSessionUUID: String? = nil
    @Published var sessionDiagnosticsByUUID: [String: SessionDiagnosticsPayload] = [:]
    @Published var isLoadingDiagnosticsUUID: String? = nil
    @Published var liveTelemetrySamples: [LiveTelemetrySample] = []
    @Published var telemetryTimelineAnchor: Date? = nil
    @Published var telemetryFamilyByRoot: [String: Int] = [:]

    private var timer: Timer?
    private var scheduledTimerInterval: Double? = nil
    private var lastTelemetryTodayStats: TodayStats? = nil
    private var nextTelemetrySampleId: Int = 1
    var isFetching: Bool = false
    var pendingMonitorRefetch: Bool = false
    private var isFetchingUsageHistory: Bool = false
    private var lastUsageHistoryFetchTime: Date? = nil
    private var isFetchingRecent503: Bool = false
    private var lastRecent503FetchTime: Date? = nil
    private var lastLoggedMismatchKey: String = ""
    private var lastQuotaFetchTimes: [String: Date] = [:]
    private var lastQuotaFailureTimes: [String: Date] = [:]
    private var lastNativeRenewalTimes: [String: Date] = [:]
    private(set) var fetchingQuotaEmails: Set<String> = []
    private var observedActiveAppEmail: String? = nil
    private var observedActiveCLIEmail: String? = nil
    private var isAppSwitchInProgress: Bool = false
    private var lastFSEventFetchAt: Date? = nil
    private var lastCLIStateRefreshAt: Date? = nil

    private let isMonitoringEnabled: Bool
    private let userDefaults: UserDefaults
    private(set) var isDashboardVisible: Bool = false
    private var lastSnapshotEtag: String? = nil
    private var hasLoadedMonitorPayload: Bool = false
    var onVisibleRefreshRequested: (() -> Void)? = nil

    private final class BackgroundMonitorResources: @unchecked Sendable {
        private let lock = NSLock()
        var daemonClient: MonitorDaemonClient?
        var directoryWatcher: SessionDirectoryWatcher?

        func shutdownAll() {
            lock.lock()
            let client = daemonClient
            let watcher = directoryWatcher
            daemonClient = nil
            directoryWatcher = nil
            lock.unlock()

            watcher?.stop()
            client?.shutdown()
        }
    }

    private let backgroundResources = BackgroundMonitorResources()

    var resolvedLanguage: AppLanguage.Resolved {
        appLanguage.resolved()
    }

    func updateAppLanguage(_ language: AppLanguage, userDefaults: UserDefaults? = nil) {
        appLanguage = language
        language.save(to: userDefaults ?? self.userDefaults)
        sessionDiagnosticsByUUID.removeAll()
        lastSnapshotEtag = nil
        if isFetching {
            pendingMonitorRefetch = true
        } else {
            fetchMonitorData()
        }
        if let activeUUID = selectedSessionUUID {
            fetchSessionDiagnostics(uuid: activeUUID, force: true)
        }
    }

    private func loadPersistedQuotaCache() {
        let cached = AccountQuotaManager.loadQuotaCache(homeDir: homeDir)
        for (email, summary) in cached {
            let key = email.lowercased()
            let short = key.components(separatedBy: "@").first ?? key
            accountQuotas[key] = summary
            accountQuotas[short] = summary
        }
    }

    func refreshQuotasIfNeeded(force: Bool = false) {
        let hDir = homeDir
        let activeApp = resolvedExpectedAppEmail
        let activeCLI = activeCLIProfileName
        let cliIndependent = isCLIIndependentMode

        for profile in profiles {
            let email = (profile.email ?? profile.name).lowercased()
            guard !email.isEmpty, email.contains("@") else { continue }
            if !force {
                guard AccountQuotaManager.shouldAttemptQuotaFetch(
                    lastSuccess: lastQuotaFetchTimes[email],
                    lastFailure: lastQuotaFailureTimes[email]
                ) else {
                    continue
                }
            }
            guard !fetchingQuotaEmails.contains(email) else { continue }
            fetchingQuotaEmails.insert(email)

            let tier = profile.tier
            let renewalTarget = AccountQuotaManager.nativeRenewalTarget(
                for: email,
                activeAppEmail: activeApp,
                activeCLIEmail: activeCLI,
                isCLIIndependentMode: cliIndependent
            )
            let allowNativeRenewal = renewalTarget != nil && AccountQuotaManager.shouldAttemptNativeRenewal(
                lastAttempt: lastNativeRenewalTimes[email],
                force: force
            )

            Task.detached(priority: .utility) { [weak self] in
                var result = await AccountQuotaManager.fetchAccountQuotaResult(email: email, tier: tier, homeDir: hDir)
                var didAttemptNativeRenewal = false
                if result == .tokenExpiredMissingOAuth, allowNativeRenewal, let target = renewalTarget {
                    didAttemptNativeRenewal = true
                    let renewed = await AccountQuotaManager.renewActiveSlotViaOfficialCLI(target: target, homeDir: hDir)
                    if renewed {
                        result = await AccountQuotaManager.fetchAccountQuotaResult(email: email, tier: tier, homeDir: hDir)
                    }
                }
                let finalResult = result
                let attemptedRenewal = didAttemptNativeRenewal
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.fetchingQuotaEmails.remove(email)
                    if attemptedRenewal {
                        self.lastNativeRenewalTimes[email] = Date()
                    }
                    let short = email.components(separatedBy: "@").first ?? email
                    switch finalResult {
                    case .success(let summary):
                        self.accountQuotas[email] = summary
                        self.accountQuotas[short] = summary
                        self.expiredQuotaEmails.remove(email)
                        self.expiredQuotaEmails.remove(short)
                        self.lastQuotaFetchTimes[email] = Date()
                        self.lastQuotaFailureTimes.removeValue(forKey: email)
                        AccountQuotaManager.saveQuotaCache(self.accountQuotas, homeDir: hDir)
                    case .tokenExpiredMissingOAuth:
                        self.expiredQuotaEmails.insert(email)
                        self.lastQuotaFailureTimes[email] = Date()
                    case .failed:
                        self.lastQuotaFailureTimes[email] = Date()
                    }
                }
            }
        }
    }

    var resolvedExpectedAppEmail: String {
        expectedAppEmail.isEmpty ? appStorageEmail : expectedAppEmail
    }

    var hasSharedKeychainMismatch: Bool {
        KeychainDriftPolicy.isUnexpectedDrift(
            expectedAppEmail: resolvedExpectedAppEmail,
            resolution: sharedKeychainResolution
        )
    }

    var maxSessionStallSeconds: Double {
        SessionLookup.maxStallSeconds(in: payload.sessions)
    }

    var activeSelectedSession: SessionItem? {
        guard let uuid = selectedSessionUUID else { return nil }
        return SessionLookup.findSession(uuid: uuid, in: payload.sessions)
    }

    func openSessionDetail(_ uuid: String) {
        sessionNavigationStack.removeAll()
        selectedSessionUUID = uuid
        fetchSessionDiagnostics(uuid: uuid, force: false)
    }

    func drillDownToSession(_ uuid: String) {
        if let current = selectedSessionUUID, current != uuid {
            sessionNavigationStack.append(current)
        }
        selectedSessionUUID = uuid
        fetchSessionDiagnostics(uuid: uuid, force: false)
    }

    func popSessionDetail() {
        activeDiagnosticSessionUUID = nil
        if let parentUUID = sessionNavigationStack.popLast() {
            selectedSessionUUID = parentUUID
        } else {
            selectedSessionUUID = nil
        }
    }

    func openSessionDiagnostics(uuid: String) {
        activeDiagnosticSessionUUID = uuid
        fetchSessionDiagnostics(uuid: uuid, force: false)
    }

    func closeSessionDiagnostics() {
        activeDiagnosticSessionUUID = nil
    }

    func fetchSessionDiagnostics(uuid: String, force: Bool = false) {
        if !force, sessionDiagnosticsByUUID[uuid] != nil {
            return
        }
        if isLoadingDiagnosticsUUID == uuid {
            return
        }
        isLoadingDiagnosticsUUID = uuid

        let scriptPath = resolveMonitorScriptPath()
        let pythonBin = resolvePythonBinary()
        let dataDir = currentDataDir()
        let langCode = resolvedLanguage.backendCode
        let daemon = ensureDaemonClient()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            var decoded: SessionDiagnosticsPayload? = nil
            if let daemon, case .success(let payload) = daemon.analyzeSession(uuid: uuid, dataDir: dataDir, lang: langCode) {
                decoded = payload
            } else if let data = Self.runOneShotMonitorProcess(
                pythonBin: pythonBin,
                arguments: [scriptPath, "--analyze-session", uuid, "--data-dir", dataDir, "--lang", langCode]
            ) {
                decoded = try? JSONDecoder().decode(SessionDiagnosticsPayload.self, from: data)
            }

            Task { @MainActor in
                if let decoded {
                    self.sessionDiagnosticsByUUID[uuid] = decoded
                }
                if self.isLoadingDiagnosticsUUID == uuid {
                    self.isLoadingDiagnosticsUUID = nil
                }
            }
        }
    }

    let homeDir: String
    var profilesRootDir: String { "\(homeDir)/.agy-profiles" }
    var profilesConfigPath: String { "\(profilesRootDir)/profiles.json" }
    var sharedExtensionsDir: String { "\(homeDir)/.antigravity/extensions" }
    var defaultGeminiDir: String { "\(homeDir)/.gemini/antigravity" }

    init(
        startMonitoring: Bool = true,
        userDefaults: UserDefaults = .standard,
        homeDir: String = FileManager.default.homeDirectoryForCurrentUser.path
    ) {
        self.isMonitoringEnabled = startMonitoring
        self.userDefaults = userDefaults
        self.homeDir = homeDir
        self.appLanguage = AppLanguage.load(from: userDefaults)
        self.showSessionModelColumn = userDefaults.bool(forKey: SessionRowBadgePolicy.showModelDefaultsKey)
        self.expandedSessionRowLimit = SessionListLayoutPolicy.loadVisibleRows(from: userDefaults)
        loadPersistedQuotaCache()
        loadProfiles()
        checkLaunchAtLoginStatus()
        if startMonitoring {
            startPolling()
            refreshQuotasIfNeeded(force: true)
        }
    }

    deinit {
        backgroundResources.shutdownAll()
    }

    private var hasActiveMonitorSessions: Bool {
        payload.activeCount > 0 || payload.sessions.contains(where: \.isActivelyWorking)
    }

    var effectivePollingInterval: Double {
        PollingSchedulePolicy.effectiveInterval(
            userRefreshInterval: refreshInterval,
            isDashboardVisible: isDashboardVisible,
            hasActiveSessions: hasActiveMonitorSessions
        )
    }

    func setDashboardVisible(_ visible: Bool) {
        let wasVisible = isDashboardVisible
        guard wasVisible != visible else { return }
        isDashboardVisible = visible
        reschedulePollingTimerIfNeeded()
        if visible {
            onVisibleRefreshRequested?()
            if isMonitoringEnabled {
                fetchMonitorData()
                refreshCLIAccountState(force: false)
            }
        }
    }

    @discardableResult
    func applyMonitorPayloadIfChanged(_ incoming: MonitorPayload, now: Date = Date()) -> Bool {
        let shouldApply = MonitorPayloadEquivalencePolicy.shouldUpdatePayload(
            current: payload,
            incoming: incoming,
            hasLoadedInitialPayload: hasLoadedMonitorPayload
        )
        hasLoadedMonitorPayload = true
        guard shouldApply else {
            return false
        }
        payload = incoming
        lastUpdatedTimeStr = Self.shortTimeFormatter.string(from: now)
        reschedulePollingTimerIfNeeded()
        return true
    }

    func shutdownBackgroundWorkers() {
        timer?.invalidate()
        timer = nil
        scheduledTimerInterval = nil
        backgroundResources.shutdownAll()
    }

    private func ensureDaemonClient() -> MonitorDaemonClient? {
        guard isMonitoringEnabled else { return nil }
        if let existing = backgroundResources.daemonClient {
            return existing
        }
        let client = MonitorDaemonClient { [weak self] dataDir in
            guard let self = self else {
                return ("/usr/bin/python3", ["./agy-monitor.py", "--daemon"])
            }
            let pythonBin = self.resolvePythonBinary()
            let scriptPath = self.resolveMonitorScriptPath()
            var args = [scriptPath, "--daemon"]
            if let dir = dataDir, !dir.isEmpty {
                args.append(contentsOf: ["--data-dir", dir])
            }
            return (pythonBin, args)
        }
        backgroundResources.daemonClient = client
        return client
    }

    private func ensureDirectoryWatcherStarted() {
        guard isMonitoringEnabled else { return }
        let candidates = SessionDirectoryWatcher.defaultCandidatePaths(
            homeDir: homeDir,
            extraDataDirs: unifyLogMonitoring ? [] : [currentDataDir()]
        )
        if let existing = backgroundResources.directoryWatcher {
            existing.updateCandidatePaths(candidates)
            return
        }
        let watcher = SessionDirectoryWatcher(
            candidatePaths: candidates,
            debounceInterval: 0.4
        ) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let now = Date()
                guard PollingSchedulePolicy.shouldAttemptFSEventFetch(
                    lastTriggeredAt: self.lastFSEventFetchAt,
                    isDashboardVisible: self.isDashboardVisible,
                    now: now
                ) else {
                    return
                }
                self.lastFSEventFetchAt = now
                self.fetchMonitorData()
            }
        }
        backgroundResources.directoryWatcher = watcher
        watcher.start()
    }

    private func reschedulePollingTimerIfNeeded() {
        guard isMonitoringEnabled else { return }
        let targetInterval = effectivePollingInterval
        if timer != nil, scheduledTimerInterval == targetInterval {
            return
        }
        timer?.invalidate()
        scheduledTimerInterval = targetInterval
        timer = Timer.scheduledTimer(withTimeInterval: targetInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fetchMonitorData()
            }
        }
    }

    func startPolling() {
        guard isMonitoringEnabled else { return }
        ensureDirectoryWatcherStarted()
        fetchMonitorData()
        reschedulePollingTimerIfNeeded()
    }

    func updateRefreshInterval(_ newInterval: Double) {
        refreshInterval = newInterval
        UserDefaults.standard.set(newInterval, forKey: "AGYHubRefreshInterval")
        if isMonitoringEnabled {
            fetchMonitorData()
            reschedulePollingTimerIfNeeded()
        }
    }

    func toggleSessionModelColumn(_ enabled: Bool) {
        showSessionModelColumn = enabled
        userDefaults.set(enabled, forKey: SessionRowBadgePolicy.showModelDefaultsKey)
    }

    func updateExpandedSessionRowLimit(_ limit: Int) {
        let clamped = SessionListLayoutPolicy.clampedVisibleRows(limit)
        expandedSessionRowLimit = clamped
        userDefaults.set(clamped, forKey: SessionListLayoutPolicy.visibleRowsDefaultsKey)
    }

    func toggleCLIIndependentMode(_ enabled: Bool) {
        isCLIIndependentMode = enabled
        UserDefaults.standard.set(enabled, forKey: "agyhub.cliIndependentMode")
        let hDir = homeDir
        let lang = resolvedLanguage
        if !enabled {
            CLIAccountManager.cleanupCLITokenFile(homeDir: hDir)
            LocalAccountDetector.appendLog("用户关闭了 CLI 独立模式，已清理 token 文件，回归共用钥匙串模式")
            showBanner(L10n.t(.bannerCLIModeShared, lang))
        } else {
            LocalAccountDetector.appendLog("用户开启了 CLI 独立模式")
            showBanner(L10n.t(.bannerCLIModeIndependent, lang))
        }
        refreshCLIAccountState()
    }

    func resolveMonitorScriptPath() -> String {

        if let bundled = Bundle.main.path(forResource: "agy-monitor", ofType: "py"),
           FileManager.default.fileExists(atPath: bundled) {
            return bundled
        }

        let userToolPath = "\(homeDir)/.gemini/config/tools/agy-monitor.py"
        if FileManager.default.fileExists(atPath: userToolPath) {
            return userToolPath
        }

        return "./agy-monitor.py"
    }

    func resolvePythonBinary() -> String {
        let candidates = [
            "/opt/homebrew/bin/python3",
            "/usr/local/bin/python3",
            "/usr/bin/python3"
        ]
        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            return path
        }
        return "/usr/bin/python3"
    }

    func currentDataDir() -> String {
        if unifyLogMonitoring {
            return defaultGeminiDir
        }
        if let profile = profiles.first(where: { $0.name == activeProfileName }),
           !profile.geminiDataDir.isEmpty {
            return (profile.geminiDataDir as NSString).expandingTildeInPath
        }
        return defaultGeminiDir
    }

    private nonisolated static func runOneShotMonitorProcess(pythonBin: String, arguments: [String]) -> Data? {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: pythonBin)
        proc.arguments = arguments

        let outPipe = Pipe()
        let errPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = errPipe

        do {
            try proc.run()
            let data = outPipe.fileHandleForReading.readDataToEndOfFile()
            proc.waitUntilExit()
            return data.isEmpty ? nil : data
        } catch {
            return nil
        }
    }

    func fetchMonitorData() {
        guard !isFetching else { return }
        isFetching = true

        ensureDirectoryWatcherStarted()
        let scriptPath = resolveMonitorScriptPath()
        let pythonBin = resolvePythonBinary()
        let dataDir = currentDataDir()
        let langCode = resolvedLanguage.backendCode
        let etagSnapshot = lastSnapshotEtag
        let daemon = ensureDaemonClient()

        DispatchQueue.global(qos: .utility).async { [weak self] in
            autoreleasepool {
                guard let self = self else { return }

                if let daemon, case .success(let snapResult) = daemon.fetchSnapshot(ifNoneMatch: etagSnapshot, dataDir: dataDir, lang: langCode) {
                    Task { @MainActor in
                        switch snapResult {
                        case .unchanged(let newEtag):
                            if let newEtag, !newEtag.isEmpty {
                                self.lastSnapshotEtag = newEtag
                            }
                            self.recordLiveTelemetrySample(for: self.payload)
                        case .updated(let decoded, let newEtag):
                            self.lastSnapshotEtag = newEtag
                            _ = self.applyMonitorPayloadIfChanged(decoded)
                            self.recordLiveTelemetrySample(for: decoded)
                        }
                        self.completeMonitorFetchCycle(refreshAncillary: true)
                    }
                    return
                }

                if let data = Self.runOneShotMonitorProcess(
                    pythonBin: pythonBin,
                    arguments: [scriptPath, "--json", "--data-dir", dataDir, "--lang", langCode]
                ),
                   let decoded = try? JSONDecoder().decode(MonitorPayload.self, from: data) {
                    Task { @MainActor in
                        self.lastSnapshotEtag = nil
                        _ = self.applyMonitorPayloadIfChanged(decoded)
                        self.recordLiveTelemetrySample(for: decoded)
                        self.completeMonitorFetchCycle(refreshAncillary: true)
                    }
                    return
                }

                Task { @MainActor in
                    self.completeMonitorFetchCycle(refreshAncillary: false)
                }
            }
        }
    }

    @MainActor
    private func completeMonitorFetchCycle(refreshAncillary: Bool) {
        isFetching = false
        if refreshAncillary {
            refreshCLIAccountState(force: false)
            refreshQuotasIfNeeded()
            refreshRecent503IfNeeded()
            if isUsageDashboardPresented {
                fetchUsageHistory(force: false)
            }
        }
        if pendingMonitorRefetch {
            pendingMonitorRefetch = false
            lastSnapshotEtag = nil
            fetchMonitorData()
        }
    }

    private func recordLiveTelemetrySample(for targetPayload: MonitorPayload) {
        let (updated, nextPrev, added) = LiveTelemetryPolicy.appendSample(
            to: liveTelemetrySamples,
            payload: targetPayload,
            previousStats: lastTelemetryTodayStats,
            nextId: &nextTelemetrySampleId
        )
        lastTelemetryTodayStats = nextPrev
        if added {
            liveTelemetrySamples = updated
            if telemetryTimelineAnchor == nil {
                telemetryTimelineAnchor = updated.first?.timestamp
            }
            let nextPinned = LiveTelemetryPolicy.updatedPinnedFamilies(
                existing: telemetryFamilyByRoot,
                from: updated
            )
            if nextPinned != telemetryFamilyByRoot {
                telemetryFamilyByRoot = nextPinned
            }
        }
    }

    func refreshRecent503IfNeeded(force: Bool = false) {
        guard Recent503Policy.shouldRefresh(
            lastFetchedAt: lastRecent503FetchTime,
            isFetching: isFetchingRecent503,
            force: force
        ) else {
            return
        }
        isFetchingRecent503 = true

        let scriptPath = resolveMonitorScriptPath()
        let pythonBin = resolvePythonBinary()
        let dataDir = currentDataDir()
        let daemon = ensureDaemonClient()

        DispatchQueue.global(qos: .utility).async { [weak self] in
            autoreleasepool {
                guard let self = self else { return }
                var decoded: Recent503Stats? = nil
                if let daemon, case .success(let stats) = daemon.fetchRecent503(dataDir: dataDir) {
                    decoded = stats
                } else if let data = Self.runOneShotMonitorProcess(
                    pythonBin: pythonBin,
                    arguments: [scriptPath, "--recent-503", "--data-dir", dataDir]
                ) {
                    decoded = try? JSONDecoder().decode(Recent503Stats.self, from: data)
                }

                if let decoded {
                    Task { @MainActor in
                        if self.recent503Count != decoded.count {
                            self.recent503Count = decoded.count
                        }
                        let now = Date()
                        self.recent503CheckedAt = now
                        self.lastRecent503FetchTime = now
                        self.isFetchingRecent503 = false
                    }
                    return
                }

                Task { @MainActor in
                    self.isFetchingRecent503 = false
                }
            }
        }
    }

    func toggleUsageDashboard() {
        isUsageDashboardPresented.toggle()
        if isUsageDashboardPresented {
            fetchUsageHistory(force: usageHistory == nil)
        }
    }

    func closeUsageDashboard() {
        isUsageDashboardPresented = false
    }

    func fetchUsageHistory(days: Int = 30, force: Bool = false) {
        if !force, let last = lastUsageHistoryFetchTime, Date().timeIntervalSince(last) < 15.0 {
            return
        }
        guard !isFetchingUsageHistory else { return }
        isFetchingUsageHistory = true
        if usageHistory == nil {
            isLoadingUsageHistory = true
        }

        let scriptPath = resolveMonitorScriptPath()
        let pythonBin = resolvePythonBinary()
        let dataDir = currentDataDir()
        let daemon = ensureDaemonClient()

        DispatchQueue.global(qos: .utility).async { [weak self] in
            autoreleasepool {
                guard let self = self else { return }
                var decoded: UsageHistoryPayload? = nil
                if let daemon, case .success(let payload) = daemon.fetchUsageHistory(days: days, dataDir: dataDir) {
                    decoded = payload
                } else if let data = Self.runOneShotMonitorProcess(
                    pythonBin: pythonBin,
                    arguments: [scriptPath, "--usage-history", "--days", String(days), "--data-dir", dataDir]
                ) {
                    decoded = try? JSONDecoder().decode(UsageHistoryPayload.self, from: data)
                }

                if let decoded {
                    Task { @MainActor in
                        if self.usageHistory != decoded {
                            self.usageHistory = decoded
                        }
                        self.lastUsageHistoryFetchTime = Date()
                        if self.isLoadingUsageHistory {
                            self.isLoadingUsageHistory = false
                        }
                        self.isFetchingUsageHistory = false
                    }
                    return
                }

                Task { @MainActor in
                    if self.isLoadingUsageHistory {
                        self.isLoadingUsageHistory = false
                    }
                    self.isFetchingUsageHistory = false
                }
            }
        }
    }

    private static let shortTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    func loadProfiles() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: profilesRootDir) {
            try? fm.createDirectory(atPath: profilesRootDir, withIntermediateDirectories: true)
        }

        var savedByKey: [String: AGYProfile] = [:]
        var savedCustomProfiles: [AGYProfile] = []
        if fm.fileExists(atPath: profilesConfigPath),
           let data = try? Data(contentsOf: URL(fileURLWithPath: profilesConfigPath)),
           let loaded = try? JSONDecoder().decode([AGYProfile].self, from: data) {
            savedCustomProfiles = loaded
            for item in loaded {
                savedByKey[item.name.lowercased()] = item
                if let email = item.email, !email.isEmpty {
                    savedByKey[email.lowercased()] = item
                }
            }
        }

        var detectedProfiles: [AGYProfile] = []

        let allDiscovered = LocalAccountDetector.detectAllAccounts(homeDir: homeDir)

        let defaultAntigravityUserData = "\(homeDir)/Library/Application Support/Antigravity"
        let detectedStorageEmail = LocalAccountDetector.detectEmailFromUserDataDir(defaultAntigravityUserData)
        appStorageEmail = detectedStorageEmail ?? ""
        if expectedAppEmail.isEmpty {
            expectedAppEmail = appStorageEmail
        }
        let defaultEmail = detectedStorageEmail ?? ""
        let mainName = defaultEmail.isEmpty ? "默认主应用" : defaultEmail
        let mainDiscovered = defaultEmail.isEmpty ? nil : allDiscovered.first { $0.email.lowercased() == defaultEmail.lowercased() }
        let mainDisplayName = mainDiscovered?.displayName ?? (defaultEmail.isEmpty ? "未登录" : "当前活跃")
        let savedMain = savedByKey[mainName.lowercased()]
        let nowIso = ISO8601DateFormatter().string(from: Date())

        let mainProfile = AGYProfile(
            name: mainName,
            email: defaultEmail.isEmpty ? nil : defaultEmail,
            tier: "\(mainDisplayName) · 主应用",
            userDataDir: defaultAntigravityUserData,
            geminiDataDir: defaultGeminiDir,
            notes: defaultEmail.isEmpty ? "官方原生主环境 (待登录)" : "官方原生主环境 (本地已认证)",
            isDefault: true,
            createdAt: (savedMain?.createdAt.isEmpty == false ? savedMain!.createdAt : nowIso),
            lastUsedAt: savedMain?.lastUsedAt
        )
        detectedProfiles.append(mainProfile)

        for acc in allDiscovered {
            if !defaultEmail.isEmpty, acc.email.lowercased() == defaultEmail.lowercased() { continue }
            let isolatedDir = "\(profilesRootDir)/\(acc.email)"
            let savedAcc = savedByKey[acc.email.lowercased()]
            let profile = AGYProfile(
                name: acc.email,
                email: acc.email,
                tier: acc.displayName,
                userDataDir: isolatedDir,
                geminiDataDir: defaultGeminiDir,
                notes: "\(acc.source) 发现",
                isDefault: false,
                createdAt: (savedAcc?.createdAt.isEmpty == false ? savedAcc!.createdAt : nowIso),
                lastUsedAt: savedAcc?.lastUsedAt
            )
            detectedProfiles.append(profile)
        }

        for custom in savedCustomProfiles where !custom.isDefaultProfile {
            let fixedDir = custom.userDataDir.contains("Antigravity IDE")
                ? "\(profilesRootDir)/\(custom.name)"
                : custom.userDataDir
            if !detectedProfiles.contains(where: { $0.name.lowercased() == custom.name.lowercased() || $0.userDataDir == fixedDir }) {
                var sanitized = custom
                sanitized.userDataDir = fixedDir
                detectedProfiles.append(sanitized)
            }
        }

        if let subdirs = try? fm.contentsOfDirectory(atPath: profilesRootDir) {
            for sub in subdirs {
                if sub.hasPrefix(".") || sub == "profiles.json" { continue }
                let fullPath = "\(profilesRootDir)/\(sub)"
                var isDir: ObjCBool = false
                if fm.fileExists(atPath: fullPath, isDirectory: &isDir), isDir.boolValue {
                    let detectedSubEmail = LocalAccountDetector.detectEmailFromUserDataDir(fullPath)
                    let displayName = detectedSubEmail ?? sub
                    if !detectedProfiles.contains(where: { $0.userDataDir == fullPath || $0.name.lowercased() == displayName.lowercased() }) {
                        let savedSub = savedByKey[displayName.lowercased()]
                        detectedProfiles.append(AGYProfile(
                            name: displayName,
                            email: detectedSubEmail,
                            tier: "自定义隔离",
                            userDataDir: fullPath,
                            geminiDataDir: defaultGeminiDir,
                            notes: detectedSubEmail != nil ? "已认证隔离环境" : "独立隔离环境 (待首次登录)",
                            isDefault: false,
                            createdAt: (savedSub?.createdAt.isEmpty == false ? savedSub!.createdAt : nowIso),
                            lastUsedAt: savedSub?.lastUsedAt
                        ))
                    }
                }
            }
        }

        let initialObserved = AccountDisplayPolicy.effectiveRunningAppEmail(
            expectedAppEmail: expectedAppEmail,
            appStorageEmail: appStorageEmail,
            sharedKeychainEmail: nil,
            activeProfileName: mainProfile.name
        )
        _ = AccountSortOrder.syncObservedActiveAccount(
            activeEmail: initialObserved,
            lastObservedEmail: &observedActiveAppEmail,
            in: &detectedProfiles
        )

        profiles = detectedProfiles
        if !profiles.contains(where: { $0.name == activeProfileName }) {
            activeProfileName = mainProfile.name
        }
        saveProfiles()
        refreshCLIAccountState()
    }

    private var isRefreshingCLIState = false

    func refreshCLIAccountState(force: Bool = true) {
        let now = Date()
        guard PollingSchedulePolicy.shouldRefreshCLIState(
            lastRefreshedAt: lastCLIStateRefreshAt,
            isRefreshing: isRefreshingCLIState,
            isAppSwitchInProgress: isAppSwitchInProgress,
            isDashboardVisible: isDashboardVisible,
            force: force,
            now: now
        ) else { return }
        lastCLIStateRefreshAt = now
        isRefreshingCLIState = true
        let hDir = homeDir
        let pRoot = profilesRootDir
        let authorized = isCLIVaultAuthorized
        let storageEmailSnapshot = appStorageEmail
        let isIndependent = isCLIIndependentMode
        DispatchQueue.global(qos: .utility).async { [weak self] in
            autoreleasepool {
                let mainDir = "\(hDir)/Library/Application Support/Antigravity"
                let storageEmail = LocalAccountDetector.detectEmailFromUserDataDir(mainDir) ?? storageEmailSnapshot
                let appAuthDate = CLIAccountManager.detectLatestDesktopAppAuthDate(homeDir: hDir)
                let resolution = CLIAccountManager.resolveSharedKeychainOwner(
                    homeDir: hDir,
                    profilesRootDir: pRoot,
                    precomputedAppAuthDate: appAuthDate,
                    precomputedAppStorageEmail: storageEmail
                )
                let sharedEmailFallback = resolution.email ?? (storageEmail.isEmpty ? nil : storageEmail)
                let activeCLI = CLIAccountManager.detectActiveCLIProfile(
                    homeDir: hDir,
                    profilesRootDir: pRoot,
                    allowVaultCapture: authorized,
                    sharedKeychainEmail: sharedEmailFallback,
                    isIndependentMode: isIndependent
                )
                let existingExpected = CLIAccountManager.readExpectedAppStateFile(profilesRootDir: pRoot)
                let advancedExpected = KeychainDriftPolicy.syncedExpectedAppStateAfterDesktopLogin(
                    existingExpected: existingExpected,
                    appStorageEmail: storageEmail,
                    desktopAppAuthDate: appAuthDate
                )
                let switchState = advancedExpected ?? KeychainDriftPolicy.resolveExpectedSwitchState(
                    expectedAppState: existingExpected,
                    cliActiveState: CLIAccountManager.readActiveStateFile(profilesRootDir: pRoot),
                    resolution: resolution
                )
                if let updatedExpected = advancedExpected ?? (existingExpected == nil ? switchState : nil) {
                    CLIAccountManager.writeExpectedAppStateFile(
                        email: updatedExpected.email,
                        profilesRootDir: pRoot,
                        switchedAt: updatedExpected.switchedAt
                    )
                }
                let computedExpectedApp = KeychainDriftPolicy.effectiveExpectedAppEmail(
                    appStorageEmail: storageEmail,
                    desktopAppAuthDate: appAuthDate,
                    expectedSwitchState: switchState
                )
                let slots = authorized ? CLIAccountManager.savedVaultAccounts() : []
                let tokenFileReady = isIndependent ? CLIAccountManager.isCLITokenFileHealthy(homeDir: hDir) : true
                let bgCount = CLIAccountManager.runningBackgroundCLIProcessCount()
                Task { @MainActor in
                    guard let self = self else { return }
                    self.isRefreshingCLIState = false
                    guard !self.isAppSwitchInProgress else { return }
                    if !storageEmail.isEmpty && self.appStorageEmail != storageEmail {
                        self.appStorageEmail = storageEmail
                    }
                    if self.sharedKeychainResolution != resolution {
                        self.sharedKeychainResolution = resolution
                    }
                    if self.expectedAppEmail != computedExpectedApp {
                        self.expectedAppEmail = computedExpectedApp
                    }
                    if self.backgroundCLIProcessCount != bgCount {
                        self.backgroundCLIProcessCount = bgCount
                    }
                    if self.isCLITokenFileReady != tokenFileReady {
                        self.isCLITokenFileReady = tokenFileReady
                    }
                    if self.activeCLIProfileName != activeCLI {
                        self.activeCLIProfileName = activeCLI
                    }
                    if self.savedCLISlots != slots {
                        self.savedCLISlots = slots
                    }

                    if KeychainDriftPolicy.isUnexpectedDrift(expectedAppEmail: computedExpectedApp, resolution: resolution),
                       let actualEmail = resolution.email {
                        let key = "\(computedExpectedApp.lowercased())->\(actualEmail.lowercased())->\(resolution.source.rawValue)"
                        if self.lastLoggedMismatchKey != key {
                            self.lastLoggedMismatchKey = key
                            LocalAccountDetector.appendLog(
                                "检测到共享钥匙串账号错配：预期主应用为 \(computedExpectedApp)，但钥匙串实际由 \(actualEmail) 持有 (来源: \(resolution.source.rawValue))"
                            )
                        }
                    } else {
                        self.lastLoggedMismatchKey = ""
                    }

                    var shouldSaveProfiles = false
                    if let cliEmail = activeCLI,
                       !self.profiles.contains(where: { $0.name.lowercased() == cliEmail.lowercased() }) {
                        let cliProfile = AGYProfile(
                            name: cliEmail,
                            email: cliEmail,
                            tier: "CLI 账号",
                            userDataDir: "\(self.profilesRootDir)/\(cliEmail)",
                            geminiDataDir: self.defaultGeminiDir,
                            notes: "Antigravity CLI 已认证",
                            isDefault: false,
                            createdAt: ISO8601DateFormatter().string(from: Date())
                        )
                        self.profiles.append(cliProfile)
                        shouldSaveProfiles = true
                    }

                    let effectiveApp = AccountDisplayPolicy.effectiveRunningAppEmail(
                        expectedAppEmail: computedExpectedApp,
                        appStorageEmail: self.appStorageEmail,
                        sharedKeychainEmail: resolution.email,
                        activeProfileName: self.activeProfileName
                    )
                    if AccountSortOrder.syncObservedActiveAccount(
                        activeEmail: effectiveApp,
                        lastObservedEmail: &self.observedActiveAppEmail,
                        in: &self.profiles
                    ) {
                        shouldSaveProfiles = true
                    }
                    if AccountSortOrder.syncObservedActiveAccount(
                        activeEmail: activeCLI,
                        lastObservedEmail: &self.observedActiveCLIEmail,
                        in: &self.profiles
                    ) {
                        shouldSaveProfiles = true
                    }
                    if shouldSaveProfiles {
                        self.saveProfiles()
                    }
                }
            }
        }
    }

    func authorizeCLIVault() {
        UserDefaults.standard.set(true, forKey: "agyhub.cliVaultAuthorized")
        isCLIVaultAuthorized = true
        LocalAccountDetector.appendLog("用户已授权启用 CLI 本机钥匙串槽位自动切换")
        refreshCLIAccountState()
        showBanner(L10n.t(.bannerCLIAuthEnabled, resolvedLanguage))
    }

    func revokeCLIVaultAuthorization() {
        UserDefaults.standard.set(false, forKey: "agyhub.cliVaultAuthorized")
        isCLIVaultAuthorized = false
        savedCLISlots = []
        let pRoot = profilesRootDir
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            CLIAccountManager.clearAllVaultAccounts(profilesRootDir: pRoot)
            LocalAccountDetector.appendLog("用户已取消 CLI 钥匙串授权并清空全部本地保险箱槽位")
            Task { @MainActor in
                guard let self = self else { return }
                self.showBanner(L10n.t(.bannerCLIAuthRevoked, self.resolvedLanguage))
                self.refreshCLIAccountState()
            }
        }
    }

    func removeCLISlot(_ email: String) {
        savedCLISlots.remove(email.lowercased())
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            CLIAccountManager.deleteVaultAccount(email)
            let updated = CLIAccountManager.savedVaultAccounts()
            LocalAccountDetector.appendLog("已清除单个 CLI 槽位缓存: \(email)")
            Task { @MainActor in
                guard let self = self else { return }
                self.savedCLISlots = updated
                self.showBanner(L10n.bannerRemovedCLISlot(email, self.resolvedLanguage))
            }
        }
    }

    nonisolated static func buildCLIFileModeLoginCommand(homeDir: String) -> String {
        "\(CLIAccountManager.fileTokenModeEnv) \(CLIAccountManager.cliBinaryPath(homeDir: homeDir)) acp --login"
    }

    var cliFileModeCommand: String {
        Self.buildCLIFileModeLoginCommand(homeDir: homeDir)
    }

    func switchCLIProfile(_ profile: AGYProfile) {
        let targetEmail = profile.email ?? profile.name
        let loginCommand = cliFileModeCommand

        guard isCLIVaultAuthorized else {
            runCommandInTerminal(
                loginCommand,
                successBanner: L10n.bannerCLILoginNoAuth(resolvedLanguage)
            )
            return
        }

        let hDir = homeDir
        let previousCLIEmail = activeCLIProfileName
        showBanner(L10n.bannerSwitchingCLI(targetEmail, resolvedLanguage))
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = CLIAccountManager.switchCLITokenFile(
                homeDir: hDir,
                targetEmail: targetEmail,
                vault: CLIAccountManager.keychainVault
            )
            let tokenFileReady = CLIAccountManager.isCLITokenFileHealthy(homeDir: hDir)
            let currentFileEmail = CLIAccountManager.readCLITokenFileEmail(homeDir: hDir)
            let bgCount = CLIAccountManager.runningBackgroundCLIProcessCount()
            Task { @MainActor in
                guard let self = self else { return }
                self.savedCLISlots = result.savedSlots
                self.backgroundCLIProcessCount = bgCount
                self.isCLITokenFileReady = tokenFileReady
                let targetKey = targetEmail.lowercased()
                self.lastQuotaFailureTimes.removeValue(forKey: targetKey)
                self.expiredQuotaEmails.remove(targetKey)
                if result.switchedImmediately {
                    self.activeCLIProfileName = targetEmail
                    self.observedActiveCLIEmail = targetKey
                    if AccountSortOrder.markProfileUsed(
                        targetEmail: targetEmail,
                        previousEmail: previousCLIEmail,
                        in: &self.profiles
                    ) {
                        self.saveProfiles()
                    }

                    self.showBanner(L10n.bannerCLISwitched(targetEmail, bgCount: bgCount, self.resolvedLanguage))
                } else {
                    if let currentFileEmail = currentFileEmail {
                        self.activeCLIProfileName = currentFileEmail
                    }
                    self.runCommandInTerminal(
                        loginCommand,
                        successBanner: L10n.bannerCLILoginMissingSlot(targetEmail, self.resolvedLanguage)
                    )
                }
            }
        }
    }

    func restoreAppKeychainAccount() {
        let targetEmail = resolvedExpectedAppEmail
        guard !targetEmail.isEmpty else { return }
        guard isCLIVaultAuthorized else {
            showBanner(L10n.t(.bannerNeedAuthForRestore, resolvedLanguage))
            return
        }
        let currentOwner = sharedKeychainResolution.email
        let hDir = homeDir
        let pRoot = profilesRootDir
        showBanner(L10n.bannerRestoringAppKeychain(targetEmail, resolvedLanguage))
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = CLIAccountManager.restoreSharedKeychainFromVault(
                homeDir: hDir,
                targetEmail: targetEmail,
                currentActiveEmail: currentOwner,
                profilesRootDir: pRoot
            )
            let bgCount = CLIAccountManager.runningBackgroundCLIProcessCount()
            Task { @MainActor in
                guard let self = self else { return }
                self.savedCLISlots = result.savedSlots
                self.backgroundCLIProcessCount = bgCount
                if result.switchedImmediately {
                    self.sharedKeychainResolution = CLIAccountManager.SharedKeychainResolution(
                        email: targetEmail,
                        source: .agyhubSwitch,
                        eventDate: Date(),
                        isTokenRefreshHijack: false
                    )
                    self.showBanner(L10n.bannerRestoredAppKeychain(targetEmail, bgCount: bgCount, self.resolvedLanguage))
                } else {
                    self.showBanner(L10n.bannerRestoreMissingSlot(targetEmail, self.resolvedLanguage))
                }
            }
        }
    }

    func saveProfiles() {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        try? data.write(to: URL(fileURLWithPath: profilesConfigPath), options: .atomic)
    }

    func createProfile(name: String, notes: String, customGeminiDir: String = "") {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !profiles.contains(where: { $0.name.lowercased() == trimmed.lowercased() }) else {
            showBanner(L10n.bannerProfileExists(trimmed, resolvedLanguage))
            return
        }

        let dirPath = "\(profilesRootDir)/\(trimmed)"
        let gDir = customGeminiDir.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? defaultGeminiDir
            : (customGeminiDir as NSString).expandingTildeInPath

        let newProfile = AGYProfile(
            name: trimmed,
            email: trimmed.contains("@") ? trimmed : nil,
            tier: "手动新建",
            userDataDir: dirPath,
            geminiDataDir: gDir,
            notes: notes.isEmpty ? "独立物理隔离环境" : notes,
            isDefault: false,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        ensureProfileDirectoryAndExtensionsSymlink(profile: newProfile)
        profiles.append(newProfile)
        activeProfileName = newProfile.name
        saveProfiles()
        showBanner(L10n.bannerProfileCreated(trimmed, resolvedLanguage))
    }

    func deleteProfile(_ profile: AGYProfile) {
        if profile.isDefaultProfile {
            showBanner(L10n.t(.bannerDefaultProfileProtected, resolvedLanguage))
            return
        }
        profiles.removeAll { $0.id == profile.id }
        if activeProfileName == profile.name, let first = profiles.first {
            activeProfileName = first.name
        }
        saveProfiles()
        showBanner(L10n.bannerProfileDeleted(profile.name, resolvedLanguage))
    }

    func ensureProfileDirectoryAndExtensionsSymlink(profile: AGYProfile) {
        if profile.isDefaultProfile { return }
        let fm = FileManager.default
        let expandedProfileDir = (profile.userDataDir as NSString).expandingTildeInPath
        if !fm.fileExists(atPath: expandedProfileDir) {
            try? fm.createDirectory(atPath: expandedProfileDir, withIntermediateDirectories: true)
        }

        if !fm.fileExists(atPath: sharedExtensionsDir) {
            try? fm.createDirectory(atPath: sharedExtensionsDir, withIntermediateDirectories: true)
        }

        let profileExtLink = "\(expandedProfileDir)/extensions"
        if !fm.fileExists(atPath: profileExtLink) {
            try? fm.createSymbolicLink(atPath: profileExtLink, withDestinationPath: sharedExtensionsDir)
        }

        AntigravityLaunchConfig.cleanZoomContamination(in: expandedProfileDir)
    }

    func switchToProfile(_ profile: AGYProfile) {
        ensureProfileDirectoryAndExtensionsSymlink(profile: profile)
        let targetEmail = profile.email ?? profile.name
        let previousAppEmail = AccountDisplayPolicy.effectiveRunningAppEmail(
            expectedAppEmail: expectedAppEmail,
            appStorageEmail: appStorageEmail,
            sharedKeychainEmail: sharedKeychainResolution.email,
            activeProfileName: activeProfileName
        )
        isAppSwitchInProgress = true
        activeProfileName = profile.name
        observedActiveAppEmail = targetEmail.lowercased()
        if AccountSortOrder.markProfileUsed(
            targetEmail: targetEmail,
            previousEmail: previousAppEmail,
            in: &profiles
        ) {
            saveProfiles()
        }
        showBanner(L10n.bannerSwitchingApp(profile.name, resolvedLanguage))
        LocalAccountDetector.appendLog("=== 开始切换账号环境: \(profile.name) [官方原生模式，免 --user-data-dir 视口破坏] ===")

        let extDir = self.sharedExtensionsDir
        let hDir = self.homeDir
        let pRoot = self.profilesRootDir
        let curOwner = self.sharedKeychainResolution.email

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let vaultRes = CLIAccountManager.restoreSharedKeychainFromVault(
                homeDir: hDir,
                targetEmail: targetEmail,
                currentActiveEmail: curOwner,
                profilesRootDir: pRoot
            )
            if vaultRes.switchedImmediately {
                LocalAccountDetector.appendLog("已成功将「\(targetEmail)」凭证热写入系统钥匙串")
            } else {
                LocalAccountDetector.appendLog("保险箱尚未缓存「\(targetEmail)」，保持原钥匙串，拉起后在 App 内登录一次即可自动归档")
            }

            let currentPid = ProcessInfo.processInfo.processIdentifier
            let allRunningApps = NSWorkspace.shared.runningApplications
            let primaryApps = allRunningApps.filter { app in
                AntigravityLaunchConfig.isPrimaryAntigravityApplication(
                    bundleIdentifier: app.bundleIdentifier,
                    localizedName: app.localizedName,
                    activationPolicy: app.activationPolicy,
                    processIdentifier: app.processIdentifier,
                    excludingPid: currentPid
                )
            }
            let auxApps = allRunningApps.filter { app in
                AntigravityLaunchConfig.isAuxiliaryAntigravityProcess(
                    bundleIdentifier: app.bundleIdentifier,
                    localizedName: app.localizedName,
                    processIdentifier: app.processIdentifier,
                    excludingPid: currentPid
                )
            }
            let trackedLSPids = AntigravityLaunchConfig.discoverDesktopLanguageServerPids(
                parentPids: Set(primaryApps.map { $0.processIdentifier })
            )

            LocalAccountDetector.appendLog(
                "发现 \(primaryApps.count) 个主 Antigravity 应用实例（含 \(auxApps.count) 个辅助进程、\(trackedLSPids.count) 个 language_server），仅向主应用发送优雅退出请求..."
            )
            for app in primaryApps {
                app.terminate()
            }

            let maxWaitLoops = Int(AntigravityLaunchConfig.gracefulShutdownTimeoutSeconds / 0.1)
            var waitLoops = 0
            while waitLoops < maxWaitLoops {
                let primaryAlive = primaryApps.contains { !$0.isTerminated }
                let auxAlive = auxApps.contains { !$0.isTerminated }
                let lsAlive = trackedLSPids.contains { kill($0, 0) == 0 }
                if !primaryAlive && !auxAlive && !lsAlive { break }
                Thread.sleep(forTimeInterval: 0.1)
                waitLoops += 1
            }

            var didForceKill = false
            for app in primaryApps where !app.isTerminated {
                LocalAccountDetector.appendLog("主实例 PID \(app.processIdentifier) 超过 \(AntigravityLaunchConfig.gracefulShutdownTimeoutSeconds)s 仍未退出，执行 SIGKILL 终结")
                kill(app.processIdentifier, SIGKILL)
                didForceKill = true
            }
            for app in auxApps where !app.isTerminated {
                LocalAccountDetector.appendLog("辅助实例 PID \(app.processIdentifier) 未随主进程退出，执行 SIGKILL 终结")
                kill(app.processIdentifier, SIGKILL)
                didForceKill = true
            }
            for lsPid in trackedLSPids where kill(lsPid, 0) == 0 {
                LocalAccountDetector.appendLog("残留 language_server PID \(lsPid) 未随主进程退出，执行 SIGKILL 终结")
                kill(lsPid, SIGKILL)
                didForceKill = true
            }
            if didForceKill {
                Thread.sleep(forTimeInterval: 0.2)
            }

            let mainDir = "\(hDir)/Library/Application Support/Antigravity"
            AntigravityLaunchConfig.cleanupStaleLocks(in: mainDir)
            let targetDir = (profile.userDataDir as NSString).expandingTildeInPath
            AntigravityLaunchConfig.cleanupStaleLocks(in: targetDir)

            if vaultRes.switchedImmediately {
                AntigravityLaunchConfig.syncOnboardingUsername(targetEmail, in: mainDir)
            }

            LocalAccountDetector.appendLog("以官方原生模式拉起 Antigravity 实例 [\(profile.name)]")
            Self.launchAntigravityProcess(for: profile, sharedExtensionsDir: extDir, isParallelLaunch: false)

            Task { @MainActor in
                self.isAppSwitchInProgress = false
                self.savedCLISlots = vaultRes.savedSlots
                let targetKey = targetEmail.lowercased()
                self.lastQuotaFailureTimes.removeValue(forKey: targetKey)
                self.expiredQuotaEmails.remove(targetKey)
                if vaultRes.switchedImmediately {
                    self.expectedAppEmail = targetEmail
                    self.appStorageEmail = targetEmail
                    self.showBanner(L10n.bannerSwitchedApp(profile.name, self.resolvedLanguage))
                } else {
                    self.showBanner(L10n.bannerSwitchedAppNeedsLogin(profile.name, self.resolvedLanguage))
                }
                self.fetchMonitorData()
            }
        }
    }

    func launchParallelProfile(_ profile: AGYProfile) {
        ensureProfileDirectoryAndExtensionsSymlink(profile: profile)
        activeProfileName = profile.name
        if AccountSortOrder.markProfileUsed(
            targetEmail: profile.email ?? profile.name,
            in: &profiles
        ) {
            saveProfiles()
        }
        let extDir = self.sharedExtensionsDir
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            Self.launchAntigravityProcess(for: profile, sharedExtensionsDir: extDir, isParallelLaunch: true)
            Task { @MainActor in
                self.showBanner(L10n.bannerParallelLaunched(profile.name, self.resolvedLanguage))
            }
        }
    }

    private nonisolated static func launchAntigravityProcess(
        for profile: AGYProfile,
        sharedExtensionsDir: String,
        isParallelLaunch: Bool
    ) {
        let primaryAppPath = "/Applications/Antigravity.app"
        let targetApp = FileManager.default.fileExists(atPath: primaryAppPath) ? primaryAppPath : "Antigravity"

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        proc.environment = AntigravityLaunchConfig.sanitizedLaunchEnvironment()
        proc.arguments = AntigravityLaunchConfig.launchArguments(
            for: profile,
            targetApp: targetApp,
            sharedExtensionsDir: sharedExtensionsDir,
            isParallelLaunch: isParallelLaunch
        )

        LocalAccountDetector.appendLog("执行启动命令（洁净原生 GUI 环境）: /usr/bin/open \(proc.arguments?.joined(separator: " ") ?? "")")
        try? proc.run()
        proc.waitUntilExit()
    }

    nonisolated static func shellSingleQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    @discardableResult
    func runCommandInTerminal(_ fullCommand: String, successBanner: String) -> Bool {
        let singleLine = fullCommand
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
        let escaped = singleLine
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let scriptSource = """
        tell application "Terminal"
            activate
            do script "\(escaped)"
        end tell
        """

        if let appleScript = NSAppleScript(source: scriptSource) {
            var errorDict: NSDictionary? = nil
            appleScript.executeAndReturnError(&errorDict)
            if errorDict == nil {
                showBanner(successBanner)
                return true
            }
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(singleLine, forType: .string)
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"))
        showBanner(L10n.bannerCopiedTerminalFallback(singleLine, resolvedLanguage))
        return false
    }

    private var launchAgentPlistPath: String {
        "\(homeDir)/Library/LaunchAgents/com.antigravity.agyhub.plist"
    }

    func checkLaunchAtLoginStatus() {
        if #available(macOS 13.0, *) {
            if SMAppService.mainApp.status == .enabled {
                launchAtLogin = true
                return
            }
        }
        launchAtLogin = FileManager.default.fileExists(atPath: launchAgentPlistPath)
    }

    func toggleLaunchAtLogin(_ enabled: Bool) {
        launchAtLogin = enabled
        let lang = resolvedLanguage
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                    showBanner(L10n.t(.bannerLaunchAtLoginOn, lang))
                    return
                } else {
                    try SMAppService.mainApp.unregister()
                    showBanner(L10n.t(.bannerLaunchAtLoginOff, lang))
                    return
                }
            } catch {

            }
        }

        let fm = FileManager.default
        if enabled {
            let execPath = Bundle.main.executablePath ?? "/Applications/Agyhub.app/Contents/MacOS/Agyhub"
            let plistContent = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key>
                <string>com.antigravity.agyhub</string>
                <key>ProgramArguments</key>
                <array>
                    <string>\(execPath)</string>
                </array>
                <key>RunAtLoad</key>
                <true/>
                <key>KeepAlive</key>
                <false/>
            </dict>
            </plist>
            """
            let launchAgentsDir = "\(homeDir)/Library/LaunchAgents"
            if !fm.fileExists(atPath: launchAgentsDir) {
                try? fm.createDirectory(atPath: launchAgentsDir, withIntermediateDirectories: true)
            }
            try? plistContent.write(toFile: launchAgentPlistPath, atomically: true, encoding: .utf8)
            showBanner(L10n.t(.bannerLaunchAgentWritten, lang))
        } else {
            try? fm.removeItem(atPath: launchAgentPlistPath)
            showBanner(L10n.t(.bannerLaunchAgentRemoved, lang))
        }
    }

    func showBanner(_ msg: String) {
        statusBannerMessage = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) { [weak self] in
            if self?.statusBannerMessage == msg {
                self?.statusBannerMessage = nil
            }
        }
    }
}
