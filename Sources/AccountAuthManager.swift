import AppKit
import Foundation
import Security
import SQLite3

enum AntigravityLaunchConfig {

    static let gracefulShutdownTimeoutSeconds: TimeInterval = 8.0

    private static let primaryBundleIds: Set<String> = [
        "com.google.antigravity"
    ]

    static func launchArguments(
        for profile: AGYProfile,
        targetApp: String,
        sharedExtensionsDir: String = "",
        isParallelLaunch: Bool = false
    ) -> [String] {
        if !isParallelLaunch || profile.isDefaultProfile {
            return ["-a", targetApp]
        }
        let userDataDir = (profile.userDataDir as NSString).expandingTildeInPath
        let extDir = (sharedExtensionsDir as NSString).expandingTildeInPath
        var args = [
            "-n",
            "-a", targetApp,
            "--args",
            "--user-data-dir=\(userDataDir)"
        ]
        if !extDir.isEmpty {
            args.append("--extensions-dir=\(extDir)")
        }
        return args
    }

    static func sanitizedLaunchEnvironment(
        from baseEnvironment: [String: String] = ProcessInfo.processInfo.environment
    ) -> [String: String] {
        func nonEmpty(_ key: String) -> String? {
            guard let val = baseEnvironment[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !val.isEmpty else {
                return nil
            }
            return val
        }

        let user = nonEmpty("USER") ?? NSUserName()
        let home = nonEmpty("HOME") ?? NSHomeDirectory()
        var env: [String: String] = [
            "HOME": home,
            "USER": user,
            "LOGNAME": nonEmpty("LOGNAME") ?? user,
            "SHELL": nonEmpty("SHELL") ?? "/bin/zsh",
            "TMPDIR": nonEmpty("TMPDIR") ?? NSTemporaryDirectory(),
            "COMMAND_MODE": "unix2003",
            "PATH": "/usr/bin:/bin:/usr/sbin:/sbin"
        ]
        if let sshAuthSock = nonEmpty("SSH_AUTH_SOCK") {
            env["SSH_AUTH_SOCK"] = sshAuthSock
        }
        if let encoding = nonEmpty("__CF_USER_TEXT_ENCODING") {
            env["__CF_USER_TEXT_ENCODING"] = encoding
        }
        return env
    }

    static func isPrimaryAntigravityApplication(
        bundleIdentifier: String?,
        localizedName: String?,
        activationPolicy: NSApplication.ActivationPolicy,
        processIdentifier: pid_t,
        excludingPid: pid_t
    ) -> Bool {
        if processIdentifier == excludingPid { return false }
        let bundle = (bundleIdentifier ?? "").lowercased()
        let name = (localizedName ?? "").lowercased()
        if bundle.contains("agyhub") || name.contains("agyhub") { return false }
        if bundle.contains("antigravity-ide") || name.contains("antigravity ide") { return false }
        guard activationPolicy == .regular else { return false }
        if primaryBundleIds.contains(bundle) { return true }
        return bundle.isEmpty && name == "antigravity"
    }

    static func isAuxiliaryAntigravityProcess(
        bundleIdentifier: String?,
        localizedName: String?,
        processIdentifier: pid_t,
        excludingPid: pid_t
    ) -> Bool {
        if processIdentifier == excludingPid { return false }
        let bundle = (bundleIdentifier ?? "").lowercased()
        let name = (localizedName ?? "").lowercased()
        if bundle.contains("agyhub") || name.contains("agyhub") { return false }
        if bundle.contains("antigravity-ide") || name.contains("antigravity ide") { return false }
        if primaryBundleIds.contains(bundle) { return false }
        return bundle.hasPrefix("com.google.antigravity.")
    }

    static func discoverDesktopLanguageServerPids(parentPids: Set<pid_t>) -> [pid_t] {
        guard !parentPids.isEmpty else { return [] }
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/ps")
        proc.arguments = ["-axo", "pid=,ppid=,comm="]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = FileHandle.nullDevice
        guard (try? proc.run()) != nil else { return [] }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        proc.waitUntilExit()
        guard let output = String(data: data, encoding: .utf8) else { return [] }

        var rows: [(pid: pid_t, ppid: pid_t, comm: String)] = []
        for rawLine in output.split(separator: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            let parts = line.split(maxSplits: 2, omittingEmptySubsequences: true, whereSeparator: { $0.isWhitespace })
            guard parts.count == 3,
                  let pid = pid_t(parts[0]),
                  let ppid = pid_t(parts[1]) else {
                continue
            }
            rows.append((pid: pid, ppid: ppid, comm: String(parts[2])))
        }

        var trackedLSPids = Set<pid_t>()
        for row in rows where parentPids.contains(row.ppid) && row.comm.hasSuffix("/Contents/Resources/bin/language_server") {
            trackedLSPids.insert(row.pid)
        }
        for row in rows where trackedLSPids.contains(row.ppid) && row.comm.hasSuffix("/Contents/Resources/bin/language_server") {
            trackedLSPids.insert(row.pid)
        }
        return Array(trackedLSPids)
    }

    static func cleanupStaleLocks(in dir: String) {
        let fm = FileManager.default
        let expanded = (dir as NSString).expandingTildeInPath
        let lockFiles = ["SingletonLock", "SingletonSocket", "SingletonCookie"]
        for name in lockFiles {
            let path = "\(expanded)/\(name)"
            if (try? fm.attributesOfItem(atPath: path)) != nil {
                try? fm.removeItem(atPath: path)
                LocalAccountDetector.appendLog("已安全清理残留孤儿锁文件: \(path)")
            }
        }
    }

    static func cleanZoomContamination(in profileDir: String) {
        let fm = FileManager.default
        let expanded = (profileDir as NSString).expandingTildeInPath
        let prefPath = "\(expanded)/Preferences"
        guard fm.fileExists(atPath: prefPath) else { return }
        if let content = try? String(contentsOfFile: prefPath, encoding: .utf8),
           content.contains("per_host_zoom_levels") {
            try? fm.removeItem(atPath: prefPath)
            LocalAccountDetector.appendLog("已清理隔离目录下可能污染视口的残留 Preferences: \(prefPath)")
        }
    }

    static func syncOnboardingUsername(_ email: String, in mainUserDataDir: String) {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let expanded = (mainUserDataDir as NSString).expandingTildeInPath
        let storagePath = "\(expanded)/app_storage.json"
        let fm = FileManager.default
        guard fm.fileExists(atPath: storagePath),
              let rawData = try? Data(contentsOf: URL(fileURLWithPath: storagePath)),
              var root = (try? JSONSerialization.jsonObject(with: rawData)) as? [String: Any] else {
            return
        }
        if let existing = root["agy.onboarding.lastLoginUsername"] as? String,
           existing.lowercased() == trimmed.lowercased() {
            return
        }
        root["agy.onboarding.lastLoginUsername"] = trimmed
        if let updated = try? JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys]) {
            try? updated.write(to: URL(fileURLWithPath: storagePath), options: .atomic)
        }
    }
}

enum AccountDisplayPolicy {

    static func effectiveRunningAppEmail(
        expectedAppEmail: String,
        appStorageEmail: String,
        sharedKeychainEmail: String?,
        activeProfileName: String
    ) -> String {
        if !expectedAppEmail.isEmpty {
            return expectedAppEmail
        }
        if !appStorageEmail.isEmpty {
            return appStorageEmail
        }
        if let shared = sharedKeychainEmail, !shared.isEmpty {
            return shared
        }
        return activeProfileName
    }
}

enum AccountSortOrder {

    private static func matchesEmail(_ profile: AGYProfile, key: String) -> Bool {
        let emailKey = (profile.email ?? profile.name).lowercased()
        return emailKey == key || profile.name.lowercased() == key
    }

    @discardableResult
    static func markProfileUsed(
        targetEmail: String,
        previousEmail: String? = nil,
        in profiles: inout [AGYProfile],
        at timestamp: TimeInterval = Date().timeIntervalSince1970
    ) -> Bool {
        let targetKey = targetEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !targetKey.isEmpty else { return false }

        var changed = false
        if let prevRaw = previousEmail?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
           !prevRaw.isEmpty,
           prevRaw != targetKey,
           let prevIdx = profiles.firstIndex(where: { matchesEmail($0, key: prevRaw) }) {
            let prevTs = timestamp - 0.001
            if profiles[prevIdx].lastUsedAt != prevTs {
                profiles[prevIdx].lastUsedAt = prevTs
                changed = true
            }
        }

        if let targetIdx = profiles.firstIndex(where: { matchesEmail($0, key: targetKey) }) {
            if profiles[targetIdx].lastUsedAt != timestamp {
                profiles[targetIdx].lastUsedAt = timestamp
                changed = true
            }
        }
        return changed
    }

    @discardableResult
    static func syncObservedActiveAccount(
        activeEmail: String?,
        lastObservedEmail: inout String?,
        in profiles: inout [AGYProfile],
        at timestamp: TimeInterval = Date().timeIntervalSince1970
    ) -> Bool {
        guard let cur = activeEmail?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !cur.isEmpty else {
            return false
        }

        let prev = lastObservedEmail
        lastObservedEmail = cur

        if prev == nil || prev == cur {
            if let idx = profiles.firstIndex(where: { matchesEmail($0, key: cur) }),
               profiles[idx].lastUsedAt == nil {
                profiles[idx].lastUsedAt = timestamp
                return true
            }
            return false
        }

        return markProfileUsed(targetEmail: cur, previousEmail: prev, in: &profiles, at: timestamp)
    }

    static func sortedProfiles(
        _ profiles: [AGYProfile],
        mode: AccountTargetMode,
        effectiveAppEmail: String,
        activeProfileName: String,
        activeCLIProfileName: String?,
        isSharedKeychainResolved: Bool,
        authenticatedEmails: Set<String> = []
    ) -> [AGYProfile] {
        let appKey = effectiveAppEmail.lowercased()
        let cliKey = activeCLIProfileName?.lowercased()
        let authKeys = Set(authenticatedEmails.map { $0.lowercased() })

        func priorityRank(for profile: AGYProfile) -> Int {
            let emailKey = (profile.email ?? profile.name).lowercased()
            let isAppActive = (emailKey == appKey) || (!isSharedKeychainResolved && profile.name == activeProfileName)
            let isCLIActive = (cliKey != nil && emailKey == cliKey)
            let isTargetActive = (mode == .app) ? isAppActive : isCLIActive
            if isTargetActive { return 0 }
            if isAppActive || isCLIActive { return 1 }
            return 2
        }

        return profiles.enumerated().sorted { lhs, rhs in
            let rankL = priorityRank(for: lhs.element)
            let rankR = priorityRank(for: rhs.element)
            if rankL != rankR {
                return rankL < rankR
            }
            let usedL = lhs.element.lastUsedAt
            let usedR = rhs.element.lastUsedAt
            if usedL != nil || usedR != nil {
                let scoreL = usedL ?? -Double.greatestFiniteMagnitude
                let scoreR = usedR ?? -Double.greatestFiniteMagnitude
                if scoreL != scoreR {
                    return scoreL > scoreR
                }
            }
            let keyL = (lhs.element.email ?? lhs.element.name).lowercased()
            let keyR = (rhs.element.email ?? rhs.element.name).lowercased()
            let authL = authKeys.contains(keyL)
            let authR = authKeys.contains(keyR)
            if authL != authR {
                return authL
            }
            return lhs.offset < rhs.offset
        }.map(\.element)
    }
}

enum KeychainDriftPolicy {

    static let desktopAppAuthSwitchProtectionWindow: TimeInterval = 30.0

    static func shouldSkipCLIStateRefresh(isRefreshing: Bool, isAppSwitchInProgress: Bool) -> Bool {
        isRefreshing || isAppSwitchInProgress
    }

    static func resolveExpectedSwitchState(
        expectedAppState: CLIAccountManager.CLIActiveState?,
        cliActiveState: CLIAccountManager.CLIActiveState?,
        resolution: CLIAccountManager.SharedKeychainResolution
    ) -> CLIAccountManager.CLIActiveState? {
        if let explicit = expectedAppState {
            return explicit
        }
        guard let st = cliActiveState else { return nil }
        if resolution.source == .agyhubSwitch {
            return st
        }
        if let actual = resolution.email,
           actual.lowercased() == st.email.lowercased() {
            let eventTs = resolution.eventDate?.timeIntervalSince1970 ?? 0
            if eventTs >= st.switchedAt {
                return st
            }
        }
        return nil
    }

    static func effectiveExpectedAppEmail(
        appStorageEmail: String,
        desktopAppAuthDate: Date?,
        expectedSwitchState: CLIAccountManager.CLIActiveState?
    ) -> String {
        if let st = expectedSwitchState, !st.email.isEmpty {
            let authTs = desktopAppAuthDate?.timeIntervalSince1970 ?? 0
            if authTs <= st.switchedAt + desktopAppAuthSwitchProtectionWindow || appStorageEmail.isEmpty {
                return st.email
            }
        }
        return appStorageEmail
    }

    static func syncedExpectedAppStateAfterDesktopLogin(
        existingExpected: CLIAccountManager.CLIActiveState?,
        appStorageEmail: String,
        desktopAppAuthDate: Date?
    ) -> CLIAccountManager.CLIActiveState? {
        guard !appStorageEmail.isEmpty,
              let authDate = desktopAppAuthDate else {
            return nil
        }
        let authTs = authDate.timeIntervalSince1970
        guard let existing = existingExpected else {
            return CLIAccountManager.CLIActiveState(email: appStorageEmail, switchedAt: authTs)
        }
        if existing.email.lowercased() != appStorageEmail.lowercased(),
           authTs > existing.switchedAt + desktopAppAuthSwitchProtectionWindow {
            return CLIAccountManager.CLIActiveState(email: appStorageEmail, switchedAt: authTs)
        }
        return nil
    }

    static func isUnexpectedDrift(
        expectedAppEmail: String,
        resolution: CLIAccountManager.SharedKeychainResolution
    ) -> Bool {
        if resolution.source == .agyhubSwitch {
            return false
        }
        guard !expectedAppEmail.isEmpty,
              let actual = resolution.email,
              !actual.isEmpty else {
            return resolution.isTokenRefreshHijack
        }
        return actual.lowercased() != expectedAppEmail.lowercased()
    }
}

struct DiscoveredAccount: Hashable {
    let email: String
    let displayName: String
    let source: String
    let notes: String
}

enum LocalAccountDetector {
    private static let logLock = NSLock()
    private static let logDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df
    }()
    private static var _discoveryLogs: [String] = []

    static var discoveryLogs: [String] {
        snapshotDiscoveryLogs()
    }

    static func snapshotDiscoveryLogs() -> [String] {
        logLock.lock()
        defer { logLock.unlock() }
        return _discoveryLogs
    }

    static func clearDiscoveryLogs() {
        logLock.lock()
        _discoveryLogs.removeAll()
        logLock.unlock()
    }

    static func appendLog(_ msg: String, logFilePath: String? = nil) {
        let logPath = logFilePath ?? ("~/.gemini/antigravity/log/agyhub_accounts.log" as NSString).expandingTildeInPath
        logLock.lock()
        let line = "[\(logDateFormatter.string(from: Date()))] \(msg)"
        _discoveryLogs.append(line)
        if let data = (line + "\n").data(using: .utf8) {
            if let handle = try? FileHandle(forWritingTo: URL(fileURLWithPath: logPath)) {
                handle.seekToEndOfFile()
                handle.write(data)
                try? handle.close()
            } else {
                let parent = URL(fileURLWithPath: logPath).deletingLastPathComponent().path
                try? FileManager.default.createDirectory(atPath: parent, withIntermediateDirectories: true)
                try? data.write(to: URL(fileURLWithPath: logPath))
            }
        }
        logLock.unlock()
        print("[Agyhub][AccountDetector] \(msg)")
    }

    static func detectEmailFromUserDataDir(_ dir: String) -> String? {
        let expanded = (dir as NSString).expandingTildeInPath
        let storagePath = "\(expanded)/app_storage.json"
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: storagePath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let email = json["agy.onboarding.lastLoginUsername"] as? String,
              !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func detectBrowserGoogleAccounts(homeDir: String) -> [DiscoveredAccount] {
        var results: [DiscoveredAccount] = []
        let browserConfigs = [
            ("Google Chrome", "\(homeDir)/Library/Application Support/Google/Chrome/Local State"),
            ("Microsoft Edge", "\(homeDir)/Library/Application Support/Microsoft Edge/Local State"),
            ("Brave Browser", "\(homeDir)/Library/Application Support/BraveSoftware/Brave-Browser/Local State")
        ]

        for (browserName, path) in browserConfigs {
            guard FileManager.default.fileExists(atPath: path) else {
                appendLog("未找到 \(browserName) 配置文件: \(path)")
                continue
            }
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let profileObj = json["profile"] as? [String: Any],
                  let infoCache = profileObj["info_cache"] as? [String: Any] else {
                appendLog("\(browserName) 配置文件解析失败或未包含 profile.info_cache")
                continue
            }

            appendLog("成功读取 \(browserName) info_cache，包含 \(infoCache.keys.count) 个 Profile 记录项")

            for (pKey, pVal) in infoCache {
                guard let pDict = pVal as? [String: Any],
                      let userName = pDict["user_name"] as? String,
                      !userName.isEmpty, userName.contains("@") else {
                    continue
                }
                let name = pDict["name"] as? String ?? ""
                let gaiaName = pDict["gaia_name"] as? String ?? ""
                let display = !gaiaName.isEmpty ? gaiaName : (!name.isEmpty ? name : userName)
                let note = "\(browserName) (\(display))"
                results.append(DiscoveredAccount(
                    email: userName,
                    displayName: display,
                    source: browserName,
                    notes: note
                ))
                appendLog("发现已绑定 Google 账号: \(userName) [\(display)] 来源: \(browserName)/\(pKey)")
            }
        }
        return results
    }

    static func detectIDEAccountEmail(homeDir: String) -> String? {
        let dbPath = "\(homeDir)/Library/Application Support/Antigravity IDE/User/globalStorage/state.vscdb"
        guard FileManager.default.fileExists(atPath: dbPath) else { return nil }

        var db: OpaquePointer?
        guard sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return nil
        }
        defer { sqlite3_close(db) }

        var detectedEmail: String? = nil
        var stmt: OpaquePointer?
        let sql = "SELECT value FROM ItemTable WHERE key = 'google.google-antigravity' LIMIT 1"
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW, let textPtr = sqlite3_column_text(stmt, 0) {
                let jsonStr = String(cString: textPtr)
                if let data = jsonStr.data(using: .utf8),
                   let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let storage = dict["antigravity-storage"] as? [String: Any],
                   let email = storage["agy.onboarding.lastLoginUsername"] as? String,
                   !email.isEmpty {
                    detectedEmail = email
                }
            }
        }
        sqlite3_finalize(stmt)
        return detectedEmail
    }

    static func detectAllAccounts(homeDir: String) -> [DiscoveredAccount] {
        clearDiscoveryLogs()
        appendLog("=== 开始执行本地账号与环境全量扫描 ===")

        var accountMap: [String: DiscoveredAccount] = [:]

        let browserAccounts = detectBrowserGoogleAccounts(homeDir: homeDir)
        for acc in browserAccounts {
            accountMap[acc.email.lowercased()] = acc
        }

        let defaultAntigravityUserData = "\(homeDir)/Library/Application Support/Antigravity"
        if let mainEmail = detectEmailFromUserDataDir(defaultAntigravityUserData) {
            appendLog("Antigravity 官方主应用目录探测到活跃认证邮箱: \(mainEmail)")
            let acc = DiscoveredAccount(
                email: mainEmail,
                displayName: "主环境",
                source: "Antigravity 主应用",
                notes: "官方原生主环境 (本地已认证)"
            )
            accountMap[mainEmail.lowercased()] = acc
        }

        if let ideEmail = detectIDEAccountEmail(homeDir: homeDir) {
            appendLog("Antigravity IDE 探测到历史已认证邮箱: \(ideEmail)")
            if accountMap[ideEmail.lowercased()] == nil {
                accountMap[ideEmail.lowercased()] = DiscoveredAccount(
                    email: ideEmail,
                    displayName: "IDE 账号",
                    source: "Antigravity IDE",
                    notes: "Antigravity IDE 历史认证"
                )
            }
        }

        let sorted = Array(accountMap.values).sorted { $0.email < $1.email }
        appendLog("扫描结束，共发现 \(sorted.count) 个独立 Google 账号")
        return sorted
    }
}

enum CLIAccountManager {
    static let activeService = "gemini"
    static let activeAccount = "antigravity"
    static let vaultService = "com.antigravity.agyhub.cli-vault"

    struct CLIActiveState: Codable {
        let email: String
        let switchedAt: TimeInterval
    }

    static func cliBinaryPath(homeDir: String) -> String {
        let localBin = "\(homeDir)/.local/bin/agy"
        if FileManager.default.isExecutableFile(atPath: localBin) {
            return localBin
        }
        return "agy"
    }

    static func hasActiveCredential() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: activeService,
            kSecAttrAccount as String: activeAccount,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var ref: CFTypeRef?
        return SecItemCopyMatching(query as CFDictionary, &ref) == errSecSuccess
    }

    static func savedVaultAccounts() -> Set<String> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: vaultService,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        var ref: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &ref) == errSecSuccess,
              let items = ref as? [[String: Any]] else {
            return []
        }
        var accounts: Set<String> = []
        for item in items {
            if let acc = item[kSecAttrAccount as String] as? String, !acc.isEmpty {
                accounts.insert(acc.lowercased())
            }
        }
        return accounts
    }

    static func readKeychainData(service: String, account: String) -> Data? {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        proc.arguments = ["find-generic-password", "-s", service, "-a", account, "-w"]
        let outPipe = Pipe()
        let errPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = errPipe
        do {
            try proc.run()
            var data = outPipe.fileHandleForReading.readDataToEndOfFile()
            proc.waitUntilExit()
            guard proc.terminationStatus == 0, !data.isEmpty else { return nil }
            if data.last == 0x0A {
                data.removeLast()
            }
            return data.isEmpty ? nil : data
        } catch {
            return nil
        }
    }

    private static func writeKeychainData(_ data: Data, service: String, account: String) -> Bool {
        let hex = data.map { String(format: "%02x", $0) }.joined()
        let sanitize: (String) -> String = { raw in
            raw.replacingOccurrences(of: "\\", with: "")
                .replacingOccurrences(of: "\"", with: "")
                .replacingOccurrences(of: "\r", with: "")
                .replacingOccurrences(of: "\n", with: "")
        }
        let safeService = sanitize(service)
        let safeAccount = sanitize(account)
        let commandLine = "add-generic-password -U -s \"\(safeService)\" -a \"\(safeAccount)\" -X \(hex)\n"

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        proc.arguments = ["-i"]
        let inPipe = Pipe()
        let outPipe = Pipe()
        let errPipe = Pipe()
        proc.standardInput = inPipe
        proc.standardOutput = outPipe
        proc.standardError = errPipe

        do {
            try proc.run()
            if let cmdData = commandLine.data(using: .utf8) {
                inPipe.fileHandleForWriting.write(cmdData)
            }
            inPipe.fileHandleForWriting.closeFile()
            proc.waitUntilExit()
            return proc.terminationStatus == 0
        } catch {
            return false
        }
    }

    static func deleteKeychainItem(service: String, account: String) {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        proc.arguments = ["delete-generic-password", "-s", service, "-a", account]
        proc.standardOutput = Pipe()
        proc.standardError = Pipe()
        try? proc.run()
        proc.waitUntilExit()
    }

    static func deleteVaultAccount(_ email: String) {
        deleteKeychainItem(service: vaultService, account: email.lowercased())
    }

    static func clearAllVaultAccounts(profilesRootDir: String) {
        for acc in savedVaultAccounts() {
            deleteKeychainItem(service: vaultService, account: acc)
        }
        writeActiveStateFile(email: nil, profilesRootDir: profilesRootDir)
    }

    enum SharedKeychainSource: String {
        case agyhubSwitch
        case desktopApp
        case cliLogin
        case cliRefresh
        case unknown
    }

    struct LogKeychainWriteEvent {
        let email: String?
        let date: Date
        let isTokenRefresh: Bool
        let isLogout: Bool
    }

    struct SharedKeychainResolution: Equatable {
        let email: String?
        let source: SharedKeychainSource
        let eventDate: Date?
        let isTokenRefreshHijack: Bool

        static let empty = SharedKeychainResolution(
            email: nil,
            source: .unknown,
            eventDate: nil,
            isTokenRefreshHijack: false
        )
    }

    private static func activeStatePath(profilesRootDir: String) -> String {
        "\(profilesRootDir)/cli_active.json"
    }

    static func readActiveStateFile(profilesRootDir: String) -> CLIActiveState? {
        let path = activeStatePath(profilesRootDir: profilesRootDir)
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return try? JSONDecoder().decode(CLIActiveState.self, from: data)
    }

    static func writeActiveStateFile(email: String?, profilesRootDir: String) {
        let path = activeStatePath(profilesRootDir: profilesRootDir)
        guard let email = email, !email.isEmpty else {
            try? FileManager.default.removeItem(atPath: path)
            return
        }
        let state = CLIActiveState(email: email, switchedAt: Date().timeIntervalSince1970)
        if let data = try? JSONEncoder().encode(state) {
            try? data.write(to: URL(fileURLWithPath: path), options: .atomic)
        }
    }

    private static func expectedAppStatePath(profilesRootDir: String) -> String {
        "\(profilesRootDir)/app_expected.json"
    }

    static func readExpectedAppStateFile(profilesRootDir: String) -> CLIActiveState? {
        let path = expectedAppStatePath(profilesRootDir: profilesRootDir)
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return try? JSONDecoder().decode(CLIActiveState.self, from: data)
    }

    static func writeExpectedAppStateFile(
        email: String?,
        profilesRootDir: String,
        switchedAt: TimeInterval = Date().timeIntervalSince1970
    ) {
        let path = expectedAppStatePath(profilesRootDir: profilesRootDir)
        guard let email = email, !email.isEmpty else {
            try? FileManager.default.removeItem(atPath: path)
            return
        }
        let state = CLIActiveState(email: email, switchedAt: switchedAt)
        if let data = try? JSONEncoder().encode(state) {
            try? data.write(to: URL(fileURLWithPath: path), options: .atomic)
        }
    }

    static func keychainModificationDate(
        service: String = activeService,
        account: String = activeAccount
    ) -> Date? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var ref: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &ref) == errSecSuccess,
              let attrs = ref as? [String: Any] else {
            return nil
        }
        return (attrs[kSecAttrModificationDate as String] as? Date)
            ?? (attrs[kSecAttrCreationDate as String] as? Date)
    }

    static func parseGlogTimestamp(_ line: String, fallbackDate: Date) -> Date? {
        let chars = Array(line)
        let cal = Calendar(identifier: .gregorian)
        let refYear = cal.component(.year, from: fallbackDate)

        for i in 0..<chars.count {
            let level = chars[i]
            guard level == "I" || level == "W" || level == "E" || level == "F" else { continue }
            guard i + 14 < chars.count else { break }

            guard chars[i + 5] == " ", chars[i + 8] == ":", chars[i + 11] == ":" else { continue }

            let slice = String(chars[(i + 1)...(i + 13)])
            let parts = slice.split(separator: " ")
            guard parts.count == 2, parts[0].count == 4 else { continue }

            let mmdd = parts[0]
            let timeParts = parts[1].split(separator: ":")
            guard timeParts.count == 3,
                  let month = Int(mmdd.prefix(2)),
                  let day = Int(mmdd.suffix(2)),
                  let hour = Int(timeParts[0]),
                  let minute = Int(timeParts[1]),
                  let second = Int(timeParts[2]) else {
                continue
            }

            var nanosecond = 0
            if i + 14 < chars.count && chars[i + 14] == "." {
                var fracDigits = ""
                var idx = i + 15
                while idx < chars.count && chars[idx].isNumber && fracDigits.count < 9 {
                    fracDigits.append(chars[idx])
                    idx += 1
                }
                if !fracDigits.isEmpty, let fracVal = Int(fracDigits) {
                    let scale = Int(pow(10.0, Double(9 - fracDigits.count)))
                    nanosecond = fracVal * scale
                }
            }

            var comps = DateComponents()
            comps.year = refYear
            comps.month = month
            comps.day = day
            comps.hour = hour
            comps.minute = minute
            comps.second = second
            comps.nanosecond = nanosecond
            guard var candidate = cal.date(from: comps) else { continue }

            if candidate.timeIntervalSince(fallbackDate) > 180 * 86400 {
                comps.year = refYear - 1
                candidate = cal.date(from: comps) ?? candidate
            } else if fallbackDate.timeIntervalSince(candidate) > 180 * 86400 {
                comps.year = refYear + 1
                candidate = cal.date(from: comps) ?? candidate
            }
            return candidate
        }
        return nil
    }

    private static func candidateCLILogFiles(homeDir: String) -> [(url: URL, mtime: Date)] {
        let fm = FileManager.default
        let cliDir = "\(homeDir)/.gemini/antigravity-cli"
        let logDir = "\(cliDir)/log"

        var candidateURLs: [(url: URL, mtime: Date)] = []
        let mainLog = URL(fileURLWithPath: "\(cliDir)/cli.log")
        if let resolvedMain = try? URL(resolvingAliasFileAt: mainLog),
           let vals = try? resolvedMain.resourceValues(forKeys: [.contentModificationDateKey]),
           let dt = vals.contentModificationDate {
            candidateURLs.append((resolvedMain, dt))
        }
        if let files = try? fm.contentsOfDirectory(at: URL(fileURLWithPath: logDir), includingPropertiesForKeys: [.contentModificationDateKey]) {
            for f in files where f.pathExtension == "log" {
                if candidateURLs.contains(where: { $0.url.standardizedFileURL == f.standardizedFileURL }) {
                    continue
                }
                if let vals = try? f.resourceValues(forKeys: [.contentModificationDateKey]),
                   let dt = vals.contentModificationDate {
                    candidateURLs.append((f, dt))
                }
            }
        }
        candidateURLs.sort { $0.mtime > $1.mtime }
        return Array(candidateURLs.prefix(12))
    }

    private static func extractEmailFromAuthLine(_ line: String) -> String? {
        if let range = line.range(of: "applyAuthResult: email=") {
            let after = line[range.upperBound...]
            let email = String(after.split(separator: ",").first ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !email.isEmpty && email.contains("@") { return email }
        }
        if let range = line.range(of: "authenticated successfully as ") {
            let email = String(line[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !email.isEmpty && email.contains("@") { return email }
        }
        if let range = line.range(of: "Headless auth: authenticated as \"") {
            let after = line[range.upperBound...]
            let email = String(after.split(separator: "\"").first ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !email.isEmpty && email.contains("@") { return email }
        }
        return nil
    }

    static func detectLatestLogKeychainWriteEvent(homeDir: String) -> LogKeychainWriteEvent? {
        let candidates = candidateCLILogFiles(homeDir: homeDir)
        var bestEvent: LogKeychainWriteEvent? = nil

        for entry in candidates {
            guard let text = try? String(contentsOf: entry.url, encoding: .utf8) else { continue }

            if text.contains("Using file-based token storage") {
                continue
            }
            var sessionEmail: String? = nil
            var fileLatest: LogKeychainWriteEvent? = nil

            for rawLine in text.split(separator: "\n") {
                let line = String(rawLine)
                if let email = extractEmailFromAuthLine(line) {
                    sessionEmail = email
                    let dt = parseGlogTimestamp(line, fallbackDate: entry.mtime) ?? entry.mtime
                    fileLatest = LogKeychainWriteEvent(
                        email: email,
                        date: dt,
                        isTokenRefresh: false,
                        isLogout: false
                    )
                } else if line.contains("token refreshed"),
                          line.contains("browser.go:"),
                          let currentEmail = sessionEmail {
                    let dt = parseGlogTimestamp(line, fallbackDate: entry.mtime) ?? entry.mtime
                    fileLatest = LogKeychainWriteEvent(
                        email: currentEmail,
                        date: dt,
                        isTokenRefresh: true,
                        isLogout: false
                    )
                } else if line.contains("Logging out current user") {
                    sessionEmail = nil
                    let dt = parseGlogTimestamp(line, fallbackDate: entry.mtime) ?? entry.mtime
                    fileLatest = LogKeychainWriteEvent(
                        email: nil,
                        date: dt,
                        isTokenRefresh: false,
                        isLogout: true
                    )
                }
            }

            if let ev = fileLatest {
                if bestEvent == nil || ev.date > bestEvent!.date {
                    bestEvent = ev
                }
            }
        }
        return bestEvent
    }

    static func detectLatestLogAuth(homeDir: String) -> (email: String, date: Date)? {
        let candidates = candidateCLILogFiles(homeDir: homeDir)
        var bestEvent: LogKeychainWriteEvent? = nil

        for entry in candidates {
            guard let text = try? String(contentsOf: entry.url, encoding: .utf8) else { continue }

            if text.contains("Using file-based token storage") {
                continue
            }
            var fileLatestAuth: LogKeychainWriteEvent? = nil

            for rawLine in text.split(separator: "\n") {
                let line = String(rawLine)
                if let email = extractEmailFromAuthLine(line) {
                    let dt = parseGlogTimestamp(line, fallbackDate: entry.mtime) ?? entry.mtime
                    fileLatestAuth = LogKeychainWriteEvent(
                        email: email,
                        date: dt,
                        isTokenRefresh: false,
                        isLogout: false
                    )
                } else if line.contains("Logging out current user") {
                    let dt = parseGlogTimestamp(line, fallbackDate: entry.mtime) ?? entry.mtime
                    fileLatestAuth = LogKeychainWriteEvent(
                        email: nil,
                        date: dt,
                        isTokenRefresh: false,
                        isLogout: true
                    )
                }
            }

            if let ev = fileLatestAuth {
                if bestEvent == nil || ev.date > bestEvent!.date {
                    bestEvent = ev
                }
            }
        }

        guard let latest = bestEvent, !latest.isLogout, let email = latest.email else {
            return nil
        }
        return (email, latest.date)
    }

    static func detectLatestDesktopAppAuthDate(homeDir: String) -> Date? {
        let logPath = "\(homeDir)/Library/Logs/Antigravity/language_server.log"
        let url = URL(fileURLWithPath: logPath)
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }

        let fileSize = (try? handle.seekToEnd()) ?? 0
        guard fileSize > 0 else { return nil }

        let chunkSize: UInt64 = 262_144
        let maxScanBytes: UInt64 = 16 * 1024 * 1024
        let minOffset = fileSize > maxScanBytes ? (fileSize - maxScanBytes) : 0
        let marker = "Auth succeeded, refreshing features and managers"
        let mtime = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()

        var cursor = fileSize
        while cursor > minOffset {
            let chunkStart = cursor > (minOffset + chunkSize) ? (cursor - chunkSize) : minOffset
            let overlap: UInt64 = (cursor < fileSize) ? min(512, fileSize - cursor) : 0
            let readLen = Int(cursor - chunkStart + overlap)
            try? handle.seek(toOffset: chunkStart)
            let data = handle.readData(ofLength: readLen)
            let text = String(decoding: data, as: UTF8.self)
            if text.contains(marker) {
                for rawLine in text.split(separator: "\n").reversed() {
                    let line = String(rawLine)
                    if line.contains(marker) {
                        return parseGlogTimestamp(line, fallbackDate: mtime) ?? mtime
                    }
                }
            }
            cursor = chunkStart
        }
        return nil
    }

    static func resolveSharedKeychainOwner(
        homeDir: String,
        profilesRootDir: String,
        keychainModDate: Date? = nil,
        hasActiveKeychain: Bool? = nil
    ) -> SharedKeychainResolution {
        let activeExists = hasActiveKeychain ?? hasActiveCredential()
        guard activeExists else { return .empty }

        let state = readActiveStateFile(profilesRootDir: profilesRootDir)
        let kcMod = keychainModDate ?? keychainModificationDate()
        let cliEvent = detectLatestLogKeychainWriteEvent(homeDir: homeDir)
        let appAuthDate = detectLatestDesktopAppAuthDate(homeDir: homeDir)
        let appStorageEmail = LocalAccountDetector.detectEmailFromUserDataDir(
            "\(homeDir)/Library/Application Support/Antigravity"
        )

        struct Candidate {
            let email: String?
            let source: SharedKeychainSource
            let date: Date
            let isLogout: Bool
        }

        var candidates: [Candidate] = []

        if let st = state {
            let switchDate = Date(timeIntervalSince1970: st.switchedAt)
            let invalidatedByExternalWrite = (kcMod != nil && kcMod!.timeIntervalSince1970 > st.switchedAt + 8.0)
            if !invalidatedByExternalWrite {
                candidates.append(Candidate(
                    email: st.email,
                    source: .agyhubSwitch,
                    date: switchDate,
                    isLogout: false
                ))
            }
        }

        if let ce = cliEvent {
            let src: SharedKeychainSource = ce.isLogout ? .unknown : (ce.isTokenRefresh ? .cliRefresh : .cliLogin)
            candidates.append(Candidate(
                email: ce.email,
                source: src,
                date: ce.date,
                isLogout: ce.isLogout
            ))
        }

        if let ad = appAuthDate, let appEmail = appStorageEmail, !appEmail.isEmpty {
            let suppressedByRecentSwitch: Bool
            if let st = state,
               !(kcMod != nil && kcMod!.timeIntervalSince1970 > st.switchedAt + 8.0),
               appEmail.lowercased() != st.email.lowercased(),
               ad.timeIntervalSince1970 <= st.switchedAt + 30.0 {
                suppressedByRecentSwitch = true
            } else {
                suppressedByRecentSwitch = false
            }
            if !suppressedByRecentSwitch {
                candidates.append(Candidate(
                    email: appEmail,
                    source: .desktopApp,
                    date: ad,
                    isLogout: false
                ))
            }
        }

        if let winner = candidates.max(by: { $0.date < $1.date }) {
            if winner.isLogout {
                return SharedKeychainResolution(
                    email: nil,
                    source: .unknown,
                    eventDate: winner.date,
                    isTokenRefreshHijack: false
                )
            }
            let isHijack: Bool
            if winner.source == .cliRefresh,
               let appEmail = appStorageEmail?.lowercased(),
               let winEmail = winner.email?.lowercased(),
               appEmail != winEmail {
                isHijack = true
            } else {
                isHijack = false
            }
            return SharedKeychainResolution(
                email: winner.email,
                source: winner.source,
                eventDate: winner.date,
                isTokenRefreshHijack: isHijack
            )
        }

        if let st = state {
            return SharedKeychainResolution(
                email: st.email,
                source: .agyhubSwitch,
                eventDate: Date(timeIntervalSince1970: st.switchedAt),
                isTokenRefreshHijack: false
            )
        }
        return .empty
    }

    static func runningBackgroundCLIProcessCount() -> Int {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        proc.arguments = ["-fl", "/.gemini/bin/agy"]
        let outPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = Pipe()
        do {
            try proc.run()
            let data = outPipe.fileHandleForReading.readDataToEndOfFile()
            proc.waitUntilExit()
            guard proc.terminationStatus == 0,
                  let text = String(data: data, encoding: .utf8) else {
                return 0
            }
            return text.split(separator: "\n").filter { line in
                !line.contains("--hub") && line.contains("agy")
            }.count
        } catch {
            return 0
        }
    }

    static func resolveActiveCLIProfileEmail(
        tokenFileEmail: String?,
        sharedKeychainEmail: String?,
        cliLogEmail: String?,
        isIndependentMode: Bool
    ) -> String? {
        if isIndependentMode {
            if let fileEmail = tokenFileEmail, !fileEmail.isEmpty {
                return fileEmail
            }
            if let shared = sharedKeychainEmail, !shared.isEmpty {
                return shared
            }
            if let logEmail = cliLogEmail, !logEmail.isEmpty {
                return logEmail
            }
            return nil
        }
        return sharedKeychainEmail ?? cliLogEmail
    }

    static func detectActiveCLIProfile(
        homeDir: String,
        profilesRootDir: String,
        allowVaultCapture: Bool,
        sharedKeychainEmail: String? = nil,
        isIndependentMode: Bool = true
    ) -> String? {
        let tokenFileEmail: String?
        if allowVaultCapture {
            captureSharedKeychainOwnerIntoVault(homeDir: homeDir, profilesRootDir: profilesRootDir)
            if isIndependentMode {
                _ = ensureCLITokenFileIfNeeded(
                    homeDir: homeDir,
                    profilesRootDir: profilesRootDir,
                    preferredEmails: [sharedKeychainEmail].compactMap { $0 },
                    vault: keychainVault
                )
            }
            tokenFileEmail = captureCLITokenFileIntoVault(homeDir: homeDir, vault: keychainVault)
        } else {
            tokenFileEmail = readCLITokenFileEmail(homeDir: homeDir)
        }
        let cliLogEmail = detectLatestLogAuth(homeDir: homeDir)?.email
        return resolveActiveCLIProfileEmail(
            tokenFileEmail: tokenFileEmail,
            sharedKeychainEmail: sharedKeychainEmail,
            cliLogEmail: cliLogEmail,
            isIndependentMode: isIndependentMode
        )
    }

    static func shouldOverwriteActiveStateFile(
        currentState: CLIActiveState?,
        resolution: SharedKeychainResolution
    ) -> Bool {
        guard let email = resolution.email, !email.isEmpty else { return false }
        guard resolution.source != .cliRefresh && resolution.source != .unknown else { return false }

        guard let st = currentState else {
            return resolution.source == .agyhubSwitch || resolution.source == .cliLogin || resolution.source == .desktopApp
        }

        guard st.email.lowercased() != email.lowercased() else { return false }
        guard resolution.source == .cliLogin || resolution.source == .desktopApp else { return false }

        let eventTs = resolution.eventDate?.timeIntervalSince1970 ?? 0
        let tolerance: TimeInterval = (resolution.source == .desktopApp) ? 30.0 : 2.0
        return eventTs > st.switchedAt + tolerance
    }

    private static var lastCaptureMismatchLogKey: String = ""

    static func captureSharedKeychainOwnerIntoVault(
        homeDir: String,
        profilesRootDir: String,
        vault: CredentialVault = keychainVault,
        sharedStore: SharedCredentialStore = systemSharedCredential,
        keychainModDate: Date? = nil
    ) {
        guard sharedStore.hasActive() else { return }

        let resolution = resolveSharedKeychainOwner(
            homeDir: homeDir,
            profilesRootDir: profilesRootDir,
            keychainModDate: keychainModDate,
            hasActiveKeychain: true
        )
        guard let email = resolution.email, !email.isEmpty else {
            return
        }

        let state = readActiveStateFile(profilesRootDir: profilesRootDir)
        let kcMod = keychainModDate ?? keychainModificationDate()
        let eventTs = resolution.eventDate?.timeIntervalSince1970 ?? 0

        let keychainConsistentWithEvent = (kcMod == nil || resolution.eventDate == nil || kcMod!.timeIntervalSince1970 <= eventTs + 30.0)
        let slots = vault.list()
        var emailMatchesCredential = true
        if keychainConsistentWithEvent && (!slots.contains(email.lowercased()) || shouldOverwriteActiveStateFile(currentState: state, resolution: resolution)),
           let activeData = sharedStore.read() {
            if let verifiedEmail = credentialEmail(activeData) {
                let verifiedKey = verifiedEmail.lowercased()
                emailMatchesCredential = (verifiedKey == email.lowercased())
                if !slots.contains(verifiedKey) {
                    _ = vault.write(activeData, verifiedKey)
                    if emailMatchesCredential {
                        LocalAccountDetector.appendLog("CLI 凭证保险箱已捕获登录账号槽位: \(verifiedEmail) (来源: \(resolution.source.rawValue))")
                    } else {
                        LocalAccountDetector.appendLog("⚠️ 捕获拦截串槽：共享钥匙串内置邮箱为「\(verifiedEmail)」（原推断为「\(email)」），已按真实邮箱入库并放弃写入「\(email)」槽位")
                    }
                } else if !emailMatchesCredential {
                    let mismatchKey = "\(email.lowercased())->\(verifiedKey)"
                    if lastCaptureMismatchLogKey != mismatchKey {
                        lastCaptureMismatchLogKey = mismatchKey
                        LocalAccountDetector.appendLog("⚠️ 共享钥匙串内置邮箱为「\(verifiedEmail)」，与推断账号「\(email)」不一致，跳过捕获与状态覆写")
                    }
                }
            } else {
                emailMatchesCredential = false
                LocalAccountDetector.appendLog("⚠️ 共享钥匙串凭证缺少 id_token_email，拒绝归档至「\(email)」以防串槽")
            }
        }

        if keychainConsistentWithEvent && emailMatchesCredential && shouldOverwriteActiveStateFile(currentState: state, resolution: resolution) {
            writeActiveStateFile(email: email, profilesRootDir: profilesRootDir)
        }
    }

    static func restoreSharedKeychainFromVault(
        homeDir: String,
        targetEmail: String,
        currentActiveEmail: String?,
        profilesRootDir: String,
        vault: CredentialVault = keychainVault,
        sharedStore: SharedCredentialStore = systemSharedCredential,
        keychainModDate: Date? = nil
    ) -> (switchedImmediately: Bool, savedSlots: Set<String>) {
        let verifiedCurrent = resolveSharedKeychainOwner(
            homeDir: homeDir,
            profilesRootDir: profilesRootDir,
            keychainModDate: keychainModDate,
            hasActiveKeychain: sharedStore.hasActive()
        ).email ?? currentActiveEmail

        if let curData = sharedStore.read() {
            if let actualEmail = credentialEmail(curData) {
                if let guessed = verifiedCurrent, !guessed.isEmpty,
                   guessed.lowercased() != actualEmail.lowercased() {
                    LocalAccountDetector.appendLog("⚠️ 切出归档拦截串槽：共享钥匙串真实持有者为「\(actualEmail)」（原推断为「\(guessed)」），已改为存回真实槽位")
                }
                _ = vault.write(curData, actualEmail.lowercased())
                LocalAccountDetector.appendLog("已同步更新原共享槽位凭证: \(actualEmail)")
            } else {
                LocalAccountDetector.appendLog("⚠️ 共享钥匙串凭证缺少 id_token_email，跳过切出存回以防污染保险箱")
            }
        }

        let targetKey = targetEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let cachedData = vault.read(targetKey) {
            guard credentialMatchesEmail(cachedData, expectedEmail: targetEmail) else {
                let actual = credentialEmail(cachedData) ?? "未知"
                vault.delete(targetKey)
                LocalAccountDetector.appendLog("❌ 拦截串槽切换：保险箱「\(targetEmail)」内实际凭证归属「\(actual)」，已清理污染槽位并保持共享钥匙串不变")
                return (false, vault.list())
            }
            if sharedStore.write(cachedData) {
                writeActiveStateFile(email: targetEmail, profilesRootDir: profilesRootDir)
                writeExpectedAppStateFile(email: targetEmail, profilesRootDir: profilesRootDir)
                LocalAccountDetector.appendLog("共享钥匙串 (gemini/antigravity) 已从保险箱切换至: \(targetEmail)")
                return (true, vault.list())
            }
        }

        LocalAccountDetector.appendLog("保险箱无「\(targetEmail)」缓存，共享钥匙串保持不变")
        return (false, vault.list())
    }

    static let fileTokenModeEnv = "SSH_CLIENT=1"

    struct CredentialVault {
        let read: (String) -> Data?
        let write: (Data, String) -> Bool
        let list: () -> Set<String>
        let delete: (String) -> Void

        init(
            read: @escaping (String) -> Data?,
            write: @escaping (Data, String) -> Bool,
            list: @escaping () -> Set<String>,
            delete: @escaping (String) -> Void = { _ in }
        ) {
            self.read = read
            self.write = write
            self.list = list
            self.delete = delete
        }
    }

    struct SharedCredentialStore {
        let hasActive: () -> Bool
        let read: () -> Data?
        let write: (Data) -> Bool
    }

    static let systemSharedCredential = SharedCredentialStore(
        hasActive: { hasActiveCredential() },
        read: { readKeychainData(service: activeService, account: activeAccount) },
        write: { writeKeychainData($0, service: activeService, account: activeAccount) }
    )

    static let keychainVault = CredentialVault(
        read: { readKeychainData(service: vaultService, account: $0) },
        write: { writeKeychainData($0, service: vaultService, account: $1) },
        list: { savedVaultAccounts() },
        delete: { deleteVaultAccount($0) }
    )

    static func cliTokenFilePath(homeDir: String) -> String {
        "\(homeDir)/.gemini/antigravity-cli/antigravity-oauth-token"
    }

    static func decodeCredentialJSON(_ data: Data) -> Data? {
        let prefix = "go-keyring-base64:"
        guard let text = String(data: data, encoding: .utf8) else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix(prefix) {
            return Data(base64Encoded: String(trimmed.dropFirst(prefix.count)))
        }
        return data
    }

    static func credentialEmail(_ data: Data) -> String? {
        guard let json = decodeCredentialJSON(data),
              let obj = try? JSONSerialization.jsonObject(with: json) as? [String: Any],
              let email = obj["id_token_email"] as? String,
              email.contains("@") else {
            return nil
        }
        return email
    }

    static func credentialMatchesEmail(_ data: Data, expectedEmail: String) -> Bool {
        guard let actual = credentialEmail(data)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(),
              !actual.isEmpty else {
            return false
        }
        let target = expectedEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !target.isEmpty else { return false }
        if target.contains("@") {
            return actual == target
        }
        let actualShort = actual.components(separatedBy: "@").first ?? actual
        return actualShort == target
    }

    static func readCLITokenFileEmail(homeDir: String) -> String? {
        guard let data = FileManager.default.contents(atPath: cliTokenFilePath(homeDir: homeDir)) else { return nil }
        return credentialEmail(data)
    }

    static func isCLITokenFileHealthy(homeDir: String) -> Bool {
        guard let data = FileManager.default.contents(atPath: cliTokenFilePath(homeDir: homeDir)),
              credentialEmail(data) != nil,
              AccountQuotaManager.extractTokensFromCredentialData(data) != nil else {
            return false
        }
        return true
    }

    static func writeValidatedTokenFile(_ credential: Data, toPath path: String) -> Bool {
        guard let json = decodeCredentialJSON(credential),
              credentialEmail(json) != nil,
              AccountQuotaManager.extractTokensFromCredentialData(json) != nil else {
            return false
        }
        let fm = FileManager.default
        let parentDir = (path as NSString).deletingLastPathComponent
        let tmpPath = (parentDir as NSString).appendingPathComponent(".antigravity-oauth-token.tmp.\(UUID().uuidString)")
        do {
            try fm.createDirectory(atPath: parentDir, withIntermediateDirectories: true)
            let fd = Darwin.open(tmpPath, O_CREAT | O_WRONLY | O_TRUNC | O_NOFOLLOW, mode_t(0o600))
            guard fd >= 0 else { return false }
            var wroteAll = false
            json.withUnsafeBytes { rawBuf in
                guard let base = rawBuf.baseAddress else { return }
                var total = 0
                while total < rawBuf.count {
                    let n = Darwin.write(fd, base.advanced(by: total), rawBuf.count - total)
                    if n <= 0 { return }
                    total += n
                }
                wroteAll = (total == rawBuf.count)
            }
            _ = Darwin.fchmod(fd, mode_t(0o600))
            _ = Darwin.close(fd)
            guard wroteAll else {
                try? fm.removeItem(atPath: tmpPath)
                return false
            }
            guard Darwin.rename(tmpPath, path) == 0 else {
                try? fm.removeItem(atPath: tmpPath)
                return false
            }
            return true
        } catch {
            try? fm.removeItem(atPath: tmpPath)
            return false
        }
    }

    static func writeCLITokenFile(_ credential: Data, homeDir: String) -> Bool {
        writeValidatedTokenFile(credential, toPath: cliTokenFilePath(homeDir: homeDir))
    }

    @discardableResult
    static func ensureCLITokenFileIfNeeded(
        homeDir: String,
        profilesRootDir: String,
        preferredEmails: [String] = [],
        vault: CredentialVault = keychainVault
    ) -> String? {
        let path = cliTokenFilePath(homeDir: homeDir)
        if let existing = FileManager.default.contents(atPath: path),
           let email = credentialEmail(existing),
           AccountQuotaManager.extractTokensFromCredentialData(existing) != nil {
            return email
        }

        var candidates: [String] = []
        var seen: Set<String> = []
        func appendCandidate(_ email: String?) {
            guard let raw = email?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return }
            let key = raw.lowercased()
            if seen.insert(key).inserted {
                candidates.append(key)
            }
        }

        appendCandidate(readActiveStateFile(profilesRootDir: profilesRootDir)?.email)
        for email in preferredEmails {
            appendCandidate(email)
        }
        for slot in vault.list().sorted() {
            appendCandidate(slot)
        }

        for candidate in candidates {
            if let cached = vault.read(candidate),
               writeCLITokenFile(cached, homeDir: homeDir) {
                let recoveredEmail = credentialEmail(cached) ?? candidate
                LocalAccountDetector.appendLog("CLI token 文件缺失或损坏，已从保险箱自动恢复: \(recoveredEmail)")
                return recoveredEmail
            }
        }
        return nil
    }

    static func captureCLITokenFileIntoVault(homeDir: String, vault: CredentialVault) -> String? {
        guard let data = FileManager.default.contents(atPath: cliTokenFilePath(homeDir: homeDir)),
              let email = credentialEmail(data) else {
            return nil
        }
        if !vault.list().contains(email.lowercased()) {
            _ = vault.write(data, email.lowercased())
            LocalAccountDetector.appendLog("CLI 凭证保险箱已捕获 token 文件账号: \(email)")
        }
        return email
    }

    static func switchCLITokenFile(
        homeDir: String,
        targetEmail: String,
        vault: CredentialVault
    ) -> (switchedImmediately: Bool, savedSlots: Set<String>) {
        let path = cliTokenFilePath(homeDir: homeDir)
        if let curData = FileManager.default.contents(atPath: path),
           let curEmail = credentialEmail(curData) {
            _ = vault.write(curData, curEmail.lowercased())
            LocalAccountDetector.appendLog("已将 CLI token 文件当前凭证存回槽位: \(curEmail)")
        }

        let targetKey = targetEmail.lowercased()
        if let cached = vault.read(targetKey) {
            guard credentialMatchesEmail(cached, expectedEmail: targetEmail) else {
                let actual = credentialEmail(cached) ?? "未知"
                vault.delete(targetKey)
                LocalAccountDetector.appendLog("❌ 拦截 CLI 串槽切换：保险箱「\(targetEmail)」内实际凭证归属「\(actual)」，已清理污染槽位，保留当前 CLI token 文件等待终端 acp --login 覆写")
                return (false, vault.list())
            }
            if writeCLITokenFile(cached, homeDir: homeDir) {
                LocalAccountDetector.appendLog("CLI token 文件已从保险箱切换至: \(targetEmail)")
                return (true, vault.list())
            }
        }

        LocalAccountDetector.appendLog("保险箱无「\(targetEmail)」可用缓存，保留当前 CLI token 文件等待终端 acp --login 覆写")
        return (false, vault.list())
    }

    static func cleanupCLITokenFile(homeDir: String) {
        let path = cliTokenFilePath(homeDir: homeDir)
        if FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.removeItem(atPath: path)
            LocalAccountDetector.appendLog("已物理清理 CLI token 文件，回归系统原生钥匙串: \(path)")
        }
    }
}

struct WeeklyQuotaBucket: Codable, Equatable {
    var remainingFraction: Double
    var resetTime: Date?
    var resetTimeStr: String?

    var percentage: Int {
        Int((remainingFraction * 100.0).rounded())
    }

    func remainingCountdown(from referenceDate: Date = Date(), language: AppLanguage.Resolved = .zhHans) -> String {
        guard let resetTime = resetTime else { return "" }
        let diff = resetTime.timeIntervalSince(referenceDate)
        if diff <= 0 { return L10n.t(.quotaResetNow, language) }
        let days = Int(diff) / 86400
        let hours = (Int(diff) % 86400) / 3600
        if days >= 1 {
            return "\(days)d"
        } else if hours >= 1 {
            return "\(hours)h"
        } else {
            let mins = max(1, (Int(diff) % 3600) / 60)
            return "\(mins)m"
        }
    }
}

struct QuotaDisplayItem: Identifiable, Equatable {
    var id: String { title }
    let title: String
    let fullName: String
    let percentage: Int
    let remainingFraction: Double
    let countdown: String
    let resetTimeStr: String?
}

struct AccountQuotaSummary: Codable, Equatable {
    var email: String
    var isUltra: Bool
    var geminiQuota: WeeklyQuotaBucket?
    var argonQuota: WeeklyQuotaBucket?
    var lastFetched: Date
}

enum AccountQuotaManager {
    static let endpoint = "https://daily-cloudcode-pa.googleapis.com/v1internal:retrieveUserQuotaSummary"
    static let tokenEndpoint = "https://oauth2.googleapis.com/token"
    static let oauthClientIdEnvKey = "AGYHUB_OAUTH_CLIENT_ID"
    static let oauthClientSecretEnvKey = "AGYHUB_OAUTH_CLIENT_SECRET"

    static let userAgent = "antigravity/hub/2.31.2 (os_type=darwin; arch=arm64)"

    struct OAuthClientConfig: Equatable {
        let clientId: String
        let clientSecret: String
    }

    enum OAuthConfigError: Error, LocalizedError, Equatable {
        case missingCredentials
        case invalidTokenResponse
        case httpError(statusCode: Int)

        var errorDescription: String? {
            switch self {
            case .missingCredentials:
                return "当前未配置外部 OAuth 刷新凭据，跳过直连静默续期。"
            case .invalidTokenResponse:
                return "OAuth Token 刷新响应无效。"
            case .httpError(let statusCode):
                return "OAuth Token 刷新请求失败，HTTP 状态码：\(statusCode)。"
            }
        }
    }

    static func oauthClientConfigPath(homeDir: String = FileManager.default.homeDirectoryForCurrentUser.path) -> String {
        "\(homeDir)/.agy-profiles/oauth_client.json"
    }

    static func resolveOAuthClientConfig(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        homeDir: String = FileManager.default.homeDirectoryForCurrentUser.path
    ) -> OAuthClientConfig? {
        func nonEmpty(_ value: String?) -> String? {
            guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
                return nil
            }
            return trimmed
        }

        var fileClientId: String? = nil
        var fileClientSecret: String? = nil
        let configPath = oauthClientConfigPath(homeDir: homeDir)
        if let data = FileManager.default.contents(atPath: configPath),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            fileClientId = nonEmpty(json["client_id"] as? String)
            fileClientSecret = nonEmpty(json["client_secret"] as? String)
        }

        let resolvedClientId = nonEmpty(environment[oauthClientIdEnvKey]) ?? fileClientId
        let resolvedClientSecret = nonEmpty(environment[oauthClientSecretEnvKey]) ?? fileClientSecret

        guard let clientId = resolvedClientId, let clientSecret = resolvedClientSecret else {
            return nil
        }
        return OAuthClientConfig(clientId: clientId, clientSecret: clientSecret)
    }

    static func buildQuotaRequest(token: String) -> URLRequest? {
        guard let url = URL(string: endpoint) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = "{}".data(using: .utf8)
        return request
    }

    static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static let fallbackIsoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func parseISO8601(_ string: String) -> Date? {
        isoFormatter.date(from: string) ?? fallbackIsoFormatter.date(from: string)
    }

    static func parseQuotaSummary(data: Data, email: String, tier: String? = nil, now: Date = Date()) -> AccountQuotaSummary? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let groups = json["groups"] as? [[String: Any]] else {
            return nil
        }

        let isUltra = (tier?.lowercased().contains("ultra") ?? false)

        var geminiBucket: WeeklyQuotaBucket? = nil
        var argonBucket: WeeklyQuotaBucket? = nil

        for group in groups {
            let displayName = (group["displayName"] as? String) ?? ""
            let description = (group["description"] as? String) ?? ""
            let buckets = (group["buckets"] as? [[String: Any]]) ?? []

            guard let weeklyBucket = buckets.first(where: {
                let bid = ($0["bucketId"] as? String) ?? ""
                let win = ($0["window"] as? String) ?? ""
                return win.lowercased() == "weekly" || bid.lowercased().contains("weekly")
            }) else {
                continue
            }

            let rem = (weeklyBucket["remainingFraction"] as? NSNumber)?.doubleValue ?? 1.0
            let resetStr = weeklyBucket["resetTime"] as? String
            let resetDate = resetStr.flatMap { parseISO8601($0) }
            let bucket = WeeklyQuotaBucket(remainingFraction: rem, resetTime: resetDate, resetTimeStr: resetStr)

            let bucketId = (weeklyBucket["bucketId"] as? String) ?? ""

            let isArgonGroup = bucketId.localizedCaseInsensitiveContains("argon") ||
                               displayName.localizedCaseInsensitiveContains("argon")
            let isGeminiGroup = !isArgonGroup && (
                bucketId.lowercased() == "gemini-weekly" ||
                ((displayName.localizedCaseInsensitiveContains("gemini") ||
                  description.localizedCaseInsensitiveContains("gemini")) &&
                 !displayName.localizedCaseInsensitiveContains("claude"))
            )

            if isArgonGroup {
                argonBucket = bucket
            } else if isGeminiGroup {
                geminiBucket = bucket
            }
        }

        return AccountQuotaSummary(
            email: email,
            isUltra: isUltra,
            geminiQuota: geminiBucket,
            argonQuota: argonBucket,
            lastFetched: now
        )
    }

    static func displayItems(for summary: AccountQuotaSummary, language: AppLanguage.Resolved = .zhHans) -> [QuotaDisplayItem] {
        var items: [QuotaDisplayItem] = []

        if summary.isUltra {

            if let g = summary.geminiQuota {
                items.append(QuotaDisplayItem(
                    title: "Gemini",
                    fullName: "Gemini",
                    percentage: g.percentage,
                    remainingFraction: g.remainingFraction,
                    countdown: g.remainingCountdown(language: language),
                    resetTimeStr: g.resetTimeStr
                ))
            }
        } else {

            if let g = summary.geminiQuota {
                items.append(QuotaDisplayItem(
                    title: "Gemini",
                    fullName: "Gemini",
                    percentage: g.percentage,
                    remainingFraction: g.remainingFraction,
                    countdown: g.remainingCountdown(language: language),
                    resetTimeStr: g.resetTimeStr
                ))
            }
            if let a = summary.argonQuota {
                items.append(QuotaDisplayItem(
                    title: "Argon",
                    fullName: "Gemini 4 Argon",
                    percentage: a.percentage,
                    remainingFraction: a.remainingFraction,
                    countdown: a.remainingCountdown(language: language),
                    resetTimeStr: a.resetTimeStr
                ))
            }
        }

        return items
    }

    enum CredentialSource {
        case cliTokenFile(path: String)
        case vault(account: String)
        case sharedKeychain
    }

    struct ResolvedCredentialCandidate {
        let accessToken: String
        let refreshToken: String?
        let expiry: Date?
        let source: CredentialSource
        let rawData: Data
        let sourcePriority: Int
    }

    static func resolveCredentialCandidates(
        email: String,
        homeDir: String,
        vault: CLIAccountManager.CredentialVault = CLIAccountManager.keychainVault,
        readSharedKeychain: (() -> Data?)? = nil,
        now: Date = Date()
    ) -> [ResolvedCredentialCandidate] {
        let emailKey = email.lowercased()
        let shortKey = emailKey.components(separatedBy: "@").first ?? emailKey
        var candidates: [ResolvedCredentialCandidate] = []

        let tokenPath = CLIAccountManager.cliTokenFilePath(homeDir: homeDir)
        if let data = FileManager.default.contents(atPath: tokenPath),
           CLIAccountManager.credentialMatchesEmail(data, expectedEmail: email),
           let cred = extractTokensFromCredentialData(data) {
            candidates.append(ResolvedCredentialCandidate(
                accessToken: cred.accessToken,
                refreshToken: cred.refreshToken,
                expiry: extractTokenExpiryFromCredentialData(data),
                source: .cliTokenFile(path: tokenPath),
                rawData: data,
                sourcePriority: 0
            ))
        }

        let sharedData = readSharedKeychain?() ?? CLIAccountManager.readKeychainData(
            service: CLIAccountManager.activeService,
            account: CLIAccountManager.activeAccount
        )
        if let sharedData = sharedData,
           CLIAccountManager.credentialMatchesEmail(sharedData, expectedEmail: email),
           let cred = extractTokensFromCredentialData(sharedData) {
            candidates.append(ResolvedCredentialCandidate(
                accessToken: cred.accessToken,
                refreshToken: cred.refreshToken,
                expiry: extractTokenExpiryFromCredentialData(sharedData),
                source: .sharedKeychain,
                rawData: sharedData,
                sourcePriority: 1
            ))
        }

        let vaultCandidates = (shortKey != emailKey) ? [emailKey, shortKey] : [emailKey]
        for account in vaultCandidates {
            if let vaultData = vault.read(account),
               CLIAccountManager.credentialMatchesEmail(vaultData, expectedEmail: email),
               let cred = extractTokensFromCredentialData(vaultData) {
                candidates.append(ResolvedCredentialCandidate(
                    accessToken: cred.accessToken,
                    refreshToken: cred.refreshToken,
                    expiry: extractTokenExpiryFromCredentialData(vaultData),
                    source: .vault(account: account),
                    rawData: vaultData,
                    sourcePriority: 2
                ))
            }
        }

        let sorted = candidates.sorted { lhs, rhs in
            switch (lhs.expiry, rhs.expiry) {
            case let (lExp?, rExp?):
                if lExp != rExp { return lExp > rExp }
            case (let lExp?, nil):
                let lFresh = lExp > now
                return lFresh
            case (nil, let rExp?):
                let rFresh = rExp > now
                return !rFresh
            case (nil, nil):
                break
            }
            return lhs.sourcePriority < rhs.sourcePriority
        }

        var seenTokens: Set<String> = []
        return sorted.filter { seenTokens.insert($0.accessToken).inserted }
    }

    static func resolveCredential(
        email: String,
        homeDir: String,
        vault: CLIAccountManager.CredentialVault = CLIAccountManager.keychainVault,
        readSharedKeychain: (() -> Data?)? = nil
    ) -> (accessToken: String, refreshToken: String?, source: CredentialSource, rawData: Data)? {
        guard let best = resolveCredentialCandidates(
            email: email,
            homeDir: homeDir,
            vault: vault,
            readSharedKeychain: readSharedKeychain
        ).first else {
            return nil
        }
        return (best.accessToken, best.refreshToken, best.source, best.rawData)
    }

    static func updatingCredentialData(_ originalData: Data, newAccessToken: String, newExpiry: Date? = nil) -> Data? {
        guard !newAccessToken.isEmpty,
              let jsonData = CLIAccountManager.decodeCredentialJSON(originalData),
              var root = (try? JSONSerialization.jsonObject(with: jsonData)) as? [String: Any],
              var tokenObj = root["token"] as? [String: Any] else {
            return nil
        }

        tokenObj["access_token"] = newAccessToken
        if let expiry = newExpiry {
            let fmt = ISO8601DateFormatter()
            fmt.formatOptions = [.withInternetDateTime]
            tokenObj["expiry"] = fmt.string(from: expiry)
        }
        root["token"] = tokenObj

        guard let updatedJSON = try? JSONSerialization.data(withJSONObject: root, options: [.sortedKeys]) else {
            return nil
        }

        if let text = String(data: originalData, encoding: .utf8),
           text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("go-keyring-base64:") {
            return ("go-keyring-base64:" + updatedJSON.base64EncodedString()).data(using: .utf8)
        }
        return updatedJSON
    }

    static func shouldAttemptQuotaFetch(lastSuccess: Date?, lastFailure: Date?, now: Date = Date()) -> Bool {
        if let fail = lastFailure, now.timeIntervalSince(fail) < 300.0 {
            return false
        }
        if let success = lastSuccess, now.timeIntervalSince(success) < 60.0 {
            return false
        }
        return true
    }

    static func extractTokensFromCredentialData(_ data: Data) -> (accessToken: String, refreshToken: String?)? {
        guard let json = CLIAccountManager.decodeCredentialJSON(data),
              let root = try? JSONSerialization.jsonObject(with: json) as? [String: Any],
              let tokenObj = root["token"] as? [String: Any],
              let accessToken = tokenObj["access_token"] as? String,
              !accessToken.isEmpty else {
            return nil
        }
        let refreshToken = tokenObj["refresh_token"] as? String
        return (accessToken, refreshToken)
    }

    static func extractTokenExpiryFromCredentialData(_ data: Data) -> Date? {
        guard let json = CLIAccountManager.decodeCredentialJSON(data),
              let root = try? JSONSerialization.jsonObject(with: json) as? [String: Any],
              let tokenObj = root["token"] as? [String: Any],
              let expiryStr = tokenObj["expiry"] as? String,
              !expiryStr.isEmpty else {
            return nil
        }
        return parseISO8601(expiryStr)
    }

    private static let formValueAllowedCharacters: CharacterSet = {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=+?")
        return allowed
    }()

    static func refreshAccessTokenResult(
        refreshToken: String,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        homeDir: String = FileManager.default.homeDirectoryForCurrentUser.path,
        performRequest: ((URLRequest) async throws -> (Data, URLResponse))? = nil
    ) async -> Result<(accessToken: String, expiresIn: TimeInterval?), OAuthConfigError> {
        guard let config = resolveOAuthClientConfig(environment: environment, homeDir: homeDir) else {
            LocalAccountDetector.appendLog("[OAuth] \(OAuthConfigError.missingCredentials.localizedDescription)")
            return .failure(.missingCredentials)
        }
        guard let url = URL(string: tokenEndpoint) else {
            return .failure(.invalidTokenResponse)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            ("client_id", config.clientId),
            ("client_secret", config.clientSecret),
            ("grant_type", "refresh_token"),
            ("refresh_token", refreshToken)
        ]
        let bodyString = bodyParams.map { key, value in
            let encoded = value.addingPercentEncoding(withAllowedCharacters: formValueAllowedCharacters) ?? value
            return "\(key)=\(encoded)"
        }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)

        let rawResponse: (Data, URLResponse)?
        if let customPerform = performRequest {
            rawResponse = try? await customPerform(request)
        } else {
            rawResponse = try? await URLSession.shared.data(for: request)
        }

        guard let (data, resp) = rawResponse,
              let httpResp = resp as? HTTPURLResponse else {
            return .failure(.invalidTokenResponse)
        }
        guard httpResp.statusCode == 200 else {
            return .failure(.httpError(statusCode: httpResp.statusCode))
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let newAccessToken = json["access_token"] as? String,
              !newAccessToken.isEmpty else {
            return .failure(.invalidTokenResponse)
        }
        let expiresIn = (json["expires_in"] as? NSNumber)?.doubleValue
        return .success((newAccessToken, expiresIn))
    }

    static func refreshAccessTokenWithExpiry(
        refreshToken: String,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        homeDir: String = FileManager.default.homeDirectoryForCurrentUser.path,
        performRequest: ((URLRequest) async throws -> (Data, URLResponse))? = nil
    ) async -> (accessToken: String, expiresIn: TimeInterval?)? {
        switch await refreshAccessTokenResult(
            refreshToken: refreshToken,
            environment: environment,
            homeDir: homeDir,
            performRequest: performRequest
        ) {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }

    static func refreshAccessToken(refreshToken: String) async -> String? {
        return await refreshAccessTokenWithExpiry(refreshToken: refreshToken)?.accessToken
    }

    private static func persistRefreshedCredential(
        newToken: String,
        expiresIn: TimeInterval?,
        originalData: Data,
        source: CredentialSource,
        vault: CLIAccountManager.CredentialVault
    ) {
        let expiryDate = expiresIn.map { Date().addingTimeInterval($0) } ?? Date().addingTimeInterval(3500)
        guard let updatedData = updatingCredentialData(originalData, newAccessToken: newToken, newExpiry: expiryDate) else {
            return
        }
        switch source {
        case .cliTokenFile(let path):

            let expectedEmail = CLIAccountManager.credentialEmail(updatedData)?.lowercased()
            if let diskData = FileManager.default.contents(atPath: path),
               let diskEmail = CLIAccountManager.credentialEmail(diskData)?.lowercased(),
               let expected = expectedEmail,
               diskEmail != expected {
                return
            }
            _ = CLIAccountManager.writeValidatedTokenFile(updatedData, toPath: path)
        case .vault(let account):
            _ = vault.write(updatedData, account)
        case .sharedKeychain:
            break
        }
    }

    enum QuotaFetchResult: Equatable {
        case success(AccountQuotaSummary)
        case tokenExpiredMissingOAuth
        case failed
    }

    static func fetchAccountQuotaResult(
        email: String,
        tier: String?,
        homeDir: String,
        vault: CLIAccountManager.CredentialVault = CLIAccountManager.keychainVault,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        readSharedKeychain: (() -> Data?)? = nil,
        requestQuota: ((String) async -> (Data?, Int))? = nil,
        refreshToken: ((String) async -> (String, TimeInterval?)?)? = nil
    ) async -> QuotaFetchResult {
        let candidates = resolveCredentialCandidates(
            email: email,
            homeDir: homeDir,
            vault: vault,
            readSharedKeychain: readSharedKeychain
        )
        guard !candidates.isEmpty else {
            return .failed
        }

        func executeQuotaRequest(token: String) async -> (Data?, Int) {
            if let customRequest = requestQuota {
                return await customRequest(token)
            }
            guard let request = buildQuotaRequest(token: token) else { return (nil, 0) }

            guard let (data, resp) = try? await URLSession.shared.data(for: request),
                  let httpResp = resp as? HTTPURLResponse else {
                return (nil, 0)
            }
            return (data, httpResp.statusCode)
        }

        var saw401 = false
        for candidate in candidates {
            let (data, status) = await executeQuotaRequest(token: candidate.accessToken)
            if status == 200, let validData = data,
               let summary = parseQuotaSummary(data: validData, email: email, tier: tier) {
                return .success(summary)
            }
            if status == 401 {
                saw401 = true
                continue
            }
            return .failed
        }

        if saw401 {
            guard let refreshCandidate = candidates.first(where: { $0.refreshToken != nil }),
                  let rToken = refreshCandidate.refreshToken else {
                return .tokenExpiredMissingOAuth
            }

            let refreshed: (accessToken: String, expiresIn: TimeInterval?)?
            if let customRefresh = refreshToken {
                refreshed = await customRefresh(rToken).map { ($0.0, $0.1) }
            } else {
                switch await refreshAccessTokenResult(refreshToken: rToken, environment: environment, homeDir: homeDir) {
                case .success(let val):
                    refreshed = val
                case .failure(.missingCredentials):
                    return .tokenExpiredMissingOAuth
                case .failure:
                    refreshed = nil
                }
            }
            if let refreshed = refreshed {
                persistRefreshedCredential(
                    newToken: refreshed.accessToken,
                    expiresIn: refreshed.expiresIn,
                    originalData: refreshCandidate.rawData,
                    source: refreshCandidate.source,
                    vault: vault
                )
                let (retryData, retryStatus) = await executeQuotaRequest(token: refreshed.accessToken)
                if retryStatus == 200, let validData = retryData,
                   let summary = parseQuotaSummary(data: validData, email: email, tier: tier) {
                    return .success(summary)
                }
            }
        }

        return .failed
    }

    enum NativeRenewalTarget: Equatable {
        case activeApp
        case activeCLI
    }

    private static let nativeRenewalLock = NSLock()
    private static let nativeRenewalCooldown: TimeInterval = 1800.0

    static func quotaCachePath(homeDir: String) -> String {
        "\(homeDir)/.agy-profiles/quota_cache.json"
    }

    static func saveQuotaCache(_ summariesByEmail: [String: AccountQuotaSummary], homeDir: String) {
        let normalized = summariesByEmail.reduce(into: [String: AccountQuotaSummary]()) { acc, pair in
            let email = pair.value.email.lowercased()
            guard email.contains("@") else { return }
            acc[email] = pair.value
        }
        guard !normalized.isEmpty else { return }

        let path = quotaCachePath(homeDir: homeDir)
        let dir = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(normalized) else { return }

        let tmpPath = "\(path).tmp.\(UUID().uuidString)"
        if FileManager.default.createFile(atPath: tmpPath, contents: data, attributes: [.posixPermissions: 0o600]) {
            _ = rename(tmpPath, path)
        }
    }

    static func loadQuotaCache(homeDir: String) -> [String: AccountQuotaSummary] {
        let path = quotaCachePath(homeDir: homeDir)
        guard let data = FileManager.default.contents(atPath: path) else { return [:] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([String: AccountQuotaSummary].self, from: data)) ?? [:]
    }

    static func nativeRenewalTarget(
        for email: String,
        activeAppEmail: String?,
        activeCLIEmail: String?,
        isCLIIndependentMode: Bool
    ) -> NativeRenewalTarget? {
        let targetEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !targetEmail.isEmpty else { return nil }

        let cliEmail = activeCLIEmail?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let appEmail = activeAppEmail?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if isCLIIndependentMode, let cliEmail = cliEmail, !cliEmail.isEmpty, cliEmail == targetEmail {
            return .activeCLI
        }
        if let appEmail = appEmail, !appEmail.isEmpty, appEmail == targetEmail {
            return .activeApp
        }
        return nil
    }

    static func shouldAttemptNativeRenewal(lastAttempt: Date?, force: Bool, now: Date = Date()) -> Bool {
        if force { return true }
        if let last = lastAttempt, now.timeIntervalSince(last) < nativeRenewalCooldown {
            return false
        }
        return true
    }

    static func resolveOfficialAGYBinary(homeDir: String) -> String? {
        let candidates = [
            "/usr/local/bin/agy",
            "/opt/homebrew/bin/agy",
            "\(homeDir)/.local/bin/agy",
            "\(homeDir)/.antigravity/bin/agy",
            "\(homeDir)/bin/agy"
        ]
        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            return path
        }
        return nil
    }

    static func renewActiveSlotViaOfficialCLI(target: NativeRenewalTarget, homeDir: String) async -> Bool {
        guard let agyPath = resolveOfficialAGYBinary(homeDir: homeDir) else {
            return false
        }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                nativeRenewalLock.lock()
                defer { nativeRenewalLock.unlock() }

                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: agyPath)
                proc.arguments = ["models"]

                var env = ProcessInfo.processInfo.environment
                env["HOME"] = homeDir
                switch target {
                case .activeApp:
                    env.removeValue(forKey: "SSH_CLIENT")
                    env.removeValue(forKey: "SSH_TTY")
                    env.removeValue(forKey: "SSH_CONNECTION")
                case .activeCLI:
                    env["SSH_CLIENT"] = "1"
                }
                proc.environment = env
                proc.standardOutput = FileHandle.nullDevice
                proc.standardError = FileHandle.nullDevice

                do {
                    try proc.run()
                } catch {
                    continuation.resume(returning: false)
                    return
                }

                let deadline = Date().addingTimeInterval(15.0)
                while proc.isRunning && Date() < deadline {
                    Thread.sleep(forTimeInterval: 0.05)
                }
                if proc.isRunning {
                    proc.terminate()
                    continuation.resume(returning: false)
                    return
                }
                continuation.resume(returning: proc.terminationStatus == 0)
            }
        }
    }

    static func fetchAccountQuota(
        email: String,
        tier: String?,
        homeDir: String,
        vault: CLIAccountManager.CredentialVault = CLIAccountManager.keychainVault,
        requestQuota: ((String) async -> (Data?, Int))? = nil,
        refreshToken: ((String) async -> (String, TimeInterval?)?)? = nil
    ) async -> AccountQuotaSummary? {
        switch await fetchAccountQuotaResult(
            email: email,
            tier: tier,
            homeDir: homeDir,
            vault: vault,
            requestQuota: requestQuota,
            refreshToken: refreshToken
        ) {
        case .success(let summary):
            return summary
        case .tokenExpiredMissingOAuth, .failed:
            return nil
        }
    }

    static func quotaTooltip(
        items: [QuotaDisplayItem],
        isUltra: Bool,
        isExpired: Bool = false,
        language: AppLanguage.Resolved = .zhHans
    ) -> String {
        var lines: [String] = []
        if isUltra {
            lines.append(
                language == .zhHans
                    ? "Google AI Ultra · 统一共享周配额池"
                    : "Google AI Ultra · Shared Weekly Quota Pool"
            )
        }
        for item in items {
            if language == .zhHans {
                let countdownStr = item.countdown.isEmpty ? "" : "，将在 \(item.countdown) 后重置"
                lines.append("\(item.fullName) 周额度: \(item.percentage)% 剩余\(countdownStr)")
            } else {
                let resetWord = L10n.t(.quotaResetNow, .en)
                let countdownStr: String
                if item.countdown.isEmpty {
                    countdownStr = ""
                } else if item.countdown == resetWord {
                    countdownStr = ", resets now"
                } else {
                    countdownStr = ", resets in \(item.countdown)"
                }
                lines.append("\(item.fullName) Weekly: \(item.percentage)% left\(countdownStr)")
            }
        }
        if isExpired {
            lines.append(L10n.quotaExpiredHint(for: language))
        }
        return lines.joined(separator: "\n")
    }
}
