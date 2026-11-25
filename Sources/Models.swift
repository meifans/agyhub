import Foundation
import SwiftUI

struct MonitorPayload: Codable, Equatable {
    let timestamp: String
    let dataDir: String
    let activeCount: Int
    let totalRoundtrips: Int
    let hasAlert: Bool
    let menubar: MenuBarSummary
    let todayStats: TodayStats
    let sessions: [SessionItem]

    enum CodingKeys: String, CodingKey {
        case timestamp
        case dataDir = "data_dir"
        case activeCount = "active_count"
        case totalRoundtrips = "total_roundtrips"
        case hasAlert = "has_alert"
        case menubar
        case todayStats = "today_stats"
        case sessions
    }

    static let empty = MonitorPayload(
        timestamp: "",
        dataDir: "~/.gemini/antigravity",
        activeCount: 0,
        totalRoundtrips: 0,
        hasAlert: false,
        menubar: MenuBarSummary(icon: "🟢", text: "🟢 待命 | $0.00", statusLevel: "idle", activeCount: 0),
        todayStats: TodayStats(totalTokens: 0, cacheTokens: 0, inputTokens: 0, outputTokens: 0, cachePct: 0, costUsd: 0, hasData: false, source: "none"),
        sessions: []
    )
}

struct MenuBarSummary: Codable, Equatable {
    let icon: String
    let text: String
    let statusLevel: String
    let activeCount: Int

    enum CodingKeys: String, CodingKey {
        case icon
        case text
        case statusLevel = "status_level"
        case activeCount = "active_count"
    }
}

struct TodayStats: Codable, Equatable {
    let totalTokens: Int
    let cacheTokens: Int
    let inputTokens: Int
    let outputTokens: Int
    let cachePct: Double
    let costUsd: Double
    let hasData: Bool
    let source: String?

    enum CodingKeys: String, CodingKey {
        case totalTokens = "total_tokens"
        case cacheTokens = "cache_tokens"
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case cachePct = "cache_pct"
        case costUsd = "cost_usd"
        case hasData = "has_data"
        case source
    }

    static let empty = TodayStats(
        totalTokens: 0,
        cacheTokens: 0,
        inputTokens: 0,
        outputTokens: 0,
        cachePct: 0,
        costUsd: 0,
        hasData: false,
        source: "none"
    )
}

struct Recent503Stats: Codable, Equatable {
    let count: Int
    let windowMinutes: Int
    let checkedAt: String

    enum CodingKeys: String, CodingKey {
        case count
        case windowMinutes = "window_minutes"
        case checkedAt = "checked_at"
    }
}

enum Recent503Policy {
    enum Severity: Equatable {
        case normal
        case caution
        case warning
    }

    static let refreshIntervalSeconds: TimeInterval = 300.0

    static func shouldRefresh(lastFetchedAt: Date?, now: Date = Date(), isFetching: Bool, force: Bool) -> Bool {
        if isFetching {
            return false
        }
        if force {
            return true
        }
        guard let last = lastFetchedAt else {
            return true
        }
        return now.timeIntervalSince(last) >= refreshIntervalSeconds
    }

    static func shouldShowBadge(count: Int) -> Bool {
        count > 0
    }

    static func badgeText(count: Int) -> String {
        "503: \(max(0, count))"
    }

    static func severityLevel(count: Int) -> Severity {
        if count >= 10 {
            return .warning
        }
        if count >= 1 {
            return .caution
        }
        return .normal
    }
}

enum PollingSchedulePolicy {
    static let hiddenActiveFallbackInterval: Double = 15.0
    static let hiddenIdleFallbackInterval: Double = 60.0
    static let minimumRefreshInterval: Double = 0.2
    static let hiddenFSEventThrottleInterval: Double = 4.0
    static let visibleCLIStateRefreshInterval: Double = 10.0
    static let hiddenCLIStateRefreshInterval: Double = 30.0

    static func effectiveInterval(
        userRefreshInterval: Double,
        isDashboardVisible: Bool,
        hasActiveSessions: Bool
    ) -> Double {
        let base = max(minimumRefreshInterval, userRefreshInterval)
        if isDashboardVisible {
            return base
        }
        if hasActiveSessions {
            return max(base, hiddenActiveFallbackInterval)
        }
        return max(base, hiddenIdleFallbackInterval)
    }

    static func shouldAttemptFSEventFetch(
        lastTriggeredAt: Date?,
        isDashboardVisible: Bool,
        now: Date = Date()
    ) -> Bool {
        if isDashboardVisible {
            return true
        }
        guard let lastTriggeredAt else {
            return true
        }
        return now.timeIntervalSince(lastTriggeredAt) >= hiddenFSEventThrottleInterval
    }

    static func shouldRefreshCLIState(
        lastRefreshedAt: Date?,
        isRefreshing: Bool,
        isAppSwitchInProgress: Bool,
        isDashboardVisible: Bool,
        force: Bool,
        now: Date = Date()
    ) -> Bool {
        if isRefreshing || isAppSwitchInProgress {
            return false
        }
        if force {
            return true
        }
        guard let lastRefreshedAt else {
            return true
        }
        let cooldown = isDashboardVisible ? visibleCLIStateRefreshInterval : hiddenCLIStateRefreshInterval
        return now.timeIntervalSince(lastRefreshedAt) >= cooldown
    }
}

enum MonitorPayloadEquivalencePolicy {

    static func areDisplayEquivalent(_ lhs: MonitorPayload, _ rhs: MonitorPayload) -> Bool {
        lhs.dataDir == rhs.dataDir
            && lhs.activeCount == rhs.activeCount
            && lhs.totalRoundtrips == rhs.totalRoundtrips
            && lhs.hasAlert == rhs.hasAlert
            && lhs.menubar == rhs.menubar
            && lhs.todayStats == rhs.todayStats
            && lhs.sessions == rhs.sessions
    }

    static func shouldUpdatePayload(
        current: MonitorPayload,
        incoming: MonitorPayload,
        hasLoadedInitialPayload: Bool
    ) -> Bool {
        if !hasLoadedInitialPayload {
            return true
        }
        return !areDisplayEquivalent(current, incoming)
    }
}

struct SessionStep: Codable, Identifiable, Hashable {
    var id: String { "\(index ?? 0)-\(time)-\(type)" }
    let index: Int?
    let type: String
    let time: String
    let summary: String
}

struct SessionPhaseStat: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String
    let turns: Int
    let tokens: Int
    let inputTokens: Int
    let cacheTokens: Int
    let outputTokens: Int
    let costUsd: Double
    let pct: Double

    enum CodingKeys: String, CodingKey {
        case name, turns, tokens, pct
        case inputTokens = "input_tokens"
        case cacheTokens = "cache_tokens"
        case outputTokens = "output_tokens"
        case costUsd = "cost_usd"
    }
}

struct SessionSourceStat: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String
    let chars: Int
    let count: Int
    let pct: Double
}

struct CacheMissCauseStat: Codable, Identifiable, Hashable {
    var id: String { cause }
    let cause: String
    let count: Int
    let rebuiltTokens: Int
    let extraCostUsd: Double

    enum CodingKeys: String, CodingKey {
        case cause, count
        case rebuiltTokens = "rebuilt_tokens"
        case extraCostUsd = "extra_cost_usd"
    }
}

struct CacheMissEvent: Codable, Identifiable, Hashable {
    var id: String { "\(agentName ?? "")-\(stepIndex)-\(time)" }
    let stepIndex: Int
    let time: String
    let rebuiltTokens: Int
    let ctxTokens: Int
    let extraCostUsd: Double
    let cause: String
    let detail: String
    let agentName: String?

    enum CodingKeys: String, CodingKey {
        case time, cause, detail
        case stepIndex = "step_index"
        case rebuiltTokens = "rebuilt_tokens"
        case ctxTokens = "ctx_tokens"
        case extraCostUsd = "extra_cost_usd"
        case agentName = "agent_name"
    }
}

struct CacheMissSummary: Codable, Hashable {
    let totalMisses: Int
    let rebuiltTokens: Int
    let extraCostUsd: Double
    let wastePctOfTotal: Double
    let byCause: [CacheMissCauseStat]
    let topEvents: [CacheMissEvent]

    enum CodingKeys: String, CodingKey {
        case totalMisses = "total_misses"
        case rebuiltTokens = "rebuilt_tokens"
        case extraCostUsd = "extra_cost_usd"
        case wastePctOfTotal = "waste_pct_of_total"
        case byCause = "by_cause"
        case topEvents = "top_events"
    }
}

struct SessionConsumerItem: Codable, Identifiable, Hashable {
    var id: String { "\(category)-\(label)-\(chars)" }
    let category: String
    let label: String
    let chars: Int
}

struct SessionDiagnosticsPayload: Codable, Hashable {
    let uuid: String
    let title: String
    let model: String
    let subagentCount: Int?
    let turns: Int
    let totalTokens: Int
    let inputTokens: Int
    let cacheTokens: Int
    let outputTokens: Int
    let totalCostUsd: Double
    let totalChars: Int
    let attributedPct: Double
    let phases: [SessionPhaseStat]
    let sources: [SessionSourceStat]
    let cacheMiss: CacheMissSummary
    let topConsumers: [SessionConsumerItem]
    let bloatHints: [String]?
    let recommendations: [String]

    enum CodingKeys: String, CodingKey {
        case uuid, title, model, turns, phases, sources, recommendations
        case subagentCount = "subagent_count"
        case totalTokens = "total_tokens"
        case inputTokens = "input_tokens"
        case cacheTokens = "cache_tokens"
        case outputTokens = "output_tokens"
        case totalCostUsd = "total_cost_usd"
        case totalChars = "total_chars"
        case attributedPct = "attributed_pct"
        case cacheMiss = "cache_miss"
        case topConsumers = "top_consumers"
        case bloatHints = "bloat_hints"
    }
}

enum SessionDiagnosticsPolicy {
    static func causeControlTag(_ cause: String, language: AppLanguage.Resolved = .zhHans) -> String {
        if cause.contains("报错") || cause.contains("重连") { return L10n.t(.diagTagPlatform, language) }
        if cause.contains("压缩") || cause.contains("重开") { return L10n.t(.diagTagNormal, language) }
        return L10n.t(.diagTagOptimizable, language)
    }

    static func isOptimizableCause(_ cause: String) -> Bool {
        !(cause.contains("报错") || cause.contains("重连") || cause.contains("压缩") || cause.contains("重开"))
    }
    static func phaseColor(_ name: String) -> Color {
        switch name {
        case "调研/检索":
            return .blue
        case "编码修改":
            return .green
        case "测试/构建/排错":
            return .orange
        case "调度/看板协作":
            return .purple
        default:
            return .teal
        }
    }

    static func sourceColor(_ name: String) -> Color {
        if name.contains("read_file") { return .blue }
        if name.contains("模型") { return .teal }
        if name.contains("后台") { return .orange }
        if name.contains("同步") { return .indigo }
        if name.contains("看板") || name.contains("协作") { return .purple }
        if name.contains("edit") { return .green }
        if name.contains("报错") { return .red }
        return .secondary
    }

    static func causeColor(_ cause: String) -> Color {
        if cause.contains("报错") || cause.contains("重连") { return .red }
        if cause.contains("超时") || cause.contains("等待") || cause.contains("停顿") { return .orange }
        if cause.contains("前缀") || cause.contains("注入") { return .purple }
        return .blue
    }

    static func formatChars(_ chars: Int, language: AppLanguage.Resolved = .zhHans) -> String {
        let unit = language == .zhHans ? " 字符" : " chars"
        if chars >= 1_000_000 {
            return String(format: "%.1fM%@", Double(chars) / 1_000_000.0, unit)
        }
        if chars >= 1_000 {
            return String(format: "%.1fK%@", Double(chars) / 1_000.0, unit)
        }
        return "\(chars)\(unit)"
    }

    static func compactChars(_ chars: Int) -> String {
        if chars >= 1_000_000 {
            return String(format: "%.1fM", Double(chars) / 1_000_000.0)
        }
        if chars >= 1_000 {
            return String(format: "%.1fK", Double(chars) / 1_000.0)
        }
        return "\(chars)"
    }

    static func formattedClipboardReport(_ d: SessionDiagnosticsPayload, language: AppLanguage.Resolved = .zhHans) -> String {
        var lines: [String] = []
        if language == .en {
            lines.append("[AGYHub Session Diagnostics] \(d.title) (\(String(d.uuid.prefix(8))))")
            lines.append(String(format: "Model: %@ | Turns: %d | Total Tokens: %@ | Est. Cost: $%.2f", d.model, d.turns, Formatters.formatTokens(d.totalTokens), d.totalCostUsd))
            lines.append(String(format: "Cache Misses: %d | Rebuilt %@ | Extra Cost $%.2f (%.1f%% of total)", d.cacheMiss.totalMisses, Formatters.formatTokens(d.cacheMiss.rebuiltTokens), d.cacheMiss.extraCostUsd, d.cacheMiss.wastePctOfTotal))

            if !d.cacheMiss.byCause.isEmpty {
                lines.append("\n[Cache Miss Causes]")
                for c in d.cacheMiss.byCause {
                    let causeLabel = L10n.localizeDiagnosticCause(c.cause, language: .en)
                    lines.append(String(format: "- %@: %d misses, rebuilt %@, extra $%.2f", causeLabel, c.count, Formatters.formatTokens(c.rebuiltTokens), c.extraCostUsd))
                }
            }

            if !d.phases.isEmpty {
                lines.append("\n[Work Phases]")
                for p in d.phases {
                    let phaseLabel = L10n.localizeDiagnosticPhase(p.name, language: .en)
                    lines.append(String(format: "- %@: %.1f%% (%d turns, %@, $%.2f)", phaseLabel, p.pct, p.turns, Formatters.formatTokens(p.tokens), p.costUsd))
                }
            }

            if !d.sources.isEmpty {
                lines.append(String(format: "\n[Context Sources (%.1f%% attributed)]", d.attributedPct))
                for s in d.sources.prefix(6) {
                    let srcLabel = L10n.localizeDiagnosticSource(s.name, language: .en)
                    lines.append(String(format: "- %@: %.1f%% (%@, %d calls)", srcLabel, s.pct, formatChars(s.chars, language: .en), s.count))
                }
            }

            if !d.recommendations.isEmpty {
                lines.append("\n[Recommendations]")
                for (idx, rec) in d.recommendations.enumerated() {
                    lines.append("\(idx + 1). \(L10n.localizeDiagnosticRecommendation(rec, language: .en))")
                }
            }
            return lines.joined(separator: "\n")
        }

        lines.append("【AGYHub 会话消耗诊断】\(d.title) (\(String(d.uuid.prefix(8))))")
        lines.append(String(format: "模型: %@ | 轮次: %d | 总 Token: %@ | 总花费: $%.2f", d.model, d.turns, Formatters.formatTokens(d.totalTokens), d.totalCostUsd))
        lines.append(String(format: "缓存失效: %d 次 | 重算 %@ | 多花 $%.2f (占总费用 %.1f%%)", d.cacheMiss.totalMisses, Formatters.formatTokens(d.cacheMiss.rebuiltTokens), d.cacheMiss.extraCostUsd, d.cacheMiss.wastePctOfTotal))

        if !d.cacheMiss.byCause.isEmpty {
            lines.append("\n[缓存失效根因]")
            for c in d.cacheMiss.byCause {
                lines.append(String(format: "- %@: %d 次, 重算 %@, 多花 $%.2f", c.cause, c.count, Formatters.formatTokens(c.rebuiltTokens), c.extraCostUsd))
            }
        }

        if !d.phases.isEmpty {
            lines.append("\n[工作阶段占比]")
            for p in d.phases {
                lines.append(String(format: "- %@: %.1f%% (%d 轮, %@, $%.2f)", p.name, p.pct, p.turns, Formatters.formatTokens(p.tokens), p.costUsd))
            }
        }

        if !d.sources.isEmpty {
            lines.append(String(format: "\n[上下文来源构成 (归因率 %.1f%%)]", d.attributedPct))
            for s in d.sources.prefix(6) {
                lines.append(String(format: "- %@: %.1f%% (%@, %d 次)", s.name, s.pct, formatChars(s.chars, language: .zhHans), s.count))
            }
        }

        if !d.recommendations.isEmpty {
            lines.append("\n[优化建议]")
            for (idx, rec) in d.recommendations.enumerated() {
                lines.append("\(idx + 1). \(rec)")
            }
        }
        return lines.joined(separator: "\n")
    }

    struct DonutSlice: Identifiable, Hashable {
        let id: Int
        let start: Double
        let end: Double
    }

    static func donutSlices(values: [Double]) -> [DonutSlice] {
        let positives = values.enumerated().filter { $0.element > 0 }
        let total = positives.reduce(0.0) { $0 + $1.element }
        guard total > 0 else { return [] }

        var result: [DonutSlice] = []
        var cursor = 0.0
        for (pos, item) in positives.enumerated() {
            let next = (pos == positives.count - 1) ? 1.0 : min(1.0, cursor + item.element / total)
            result.append(DonutSlice(id: item.offset, start: cursor, end: next))
            cursor = next
        }
        return result
    }
}

struct SessionItem: Codable, Identifiable, Hashable {
    var id: String { uuid }
    let uuid: String
    let shortId: String
    let clientType: String?
    let parentConversationId: String
    let agentName: String
    let agentRole: String
    let title: String
    let isRunning: Bool
    let statusLabel: String?
    let interactions: Int
    let inputTokens: Int
    let cacheTokens: Int
    let outputTokens: Int
    let contextTokens: Int
    let cachePct: Double
    let tps: Double
    let totalTokensConsumed: Int
    let totalCostUsd: Double
    let totalCacheConsumed: Int
    let totalInputConsumed: Int
    let totalOutputConsumed: Int
    let currentStall: Double
    let health: String
    let healthCode: String?
    let healthDesc: String
    let errorCode: String?
    let currentPhase: String
    let currentAction: String
    let recentError: String?
    let historySteps: [SessionStep]
    let exists: Bool
    let model: String
    let subagents: [SessionItem]
    let subagentCount: Int
    let activeSubagentCount: Int
    let activeSubagentTps: Double
    let totalActiveSec: Double
    let totalLocalSec: Double
    let totalRemoteSec: Double
    let totalErrorSec: Double
    let localPct: Double?
    let remotePct: Double?
    let breakdownStr: String

    enum CodingKeys: String, CodingKey {
        case uuid
        case shortId = "short_id"
        case clientType = "client_type"
        case parentConversationId = "parent_conversation_id"
        case agentName = "agent_name"
        case agentRole = "agent_role"
        case title
        case isRunning = "is_running"
        case statusLabel = "status_label"
        case interactions
        case inputTokens = "input_tokens"
        case cacheTokens = "cache_tokens"
        case outputTokens = "output_tokens"
        case contextTokens = "context_tokens"
        case cachePct = "cache_pct"
        case tps
        case totalTokensConsumed = "total_tokens_consumed"
        case totalCostUsd = "total_cost_usd"
        case totalCacheConsumed = "total_cache_consumed"
        case totalInputConsumed = "total_input_consumed"
        case totalOutputConsumed = "total_output_consumed"
        case currentStall = "current_stall"
        case health
        case healthCode = "health_code"
        case healthDesc = "health_desc"
        case errorCode = "error_code"
        case currentPhase = "current_phase"
        case currentAction = "current_action"
        case recentError = "recent_error"
        case historySteps = "history_steps"
        case exists
        case model
        case subagents
        case subagentCount = "subagent_count"
        case activeSubagentCount = "active_subagent_count"
        case activeSubagentTps = "active_subagent_tps"
        case totalActiveSec = "total_active_sec"
        case totalLocalSec = "total_local_sec"
        case totalRemoteSec = "total_remote_sec"
        case totalErrorSec = "total_error_sec"
        case localPct = "local_pct"
        case remotePct = "remote_pct"
        case breakdownStr = "breakdown_str"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let uuid = try c.decode(String.self, forKey: .uuid)
        self.uuid = uuid
        let rawShort = try c.decodeIfPresent(String.self, forKey: .shortId) ?? ""
        self.shortId = rawShort.isEmpty ? (uuid.replacingOccurrences(of: "-", with: "").prefix(6).description) : rawShort
        self.clientType = try c.decodeIfPresent(String.self, forKey: .clientType)
        self.parentConversationId = try c.decodeIfPresent(String.self, forKey: .parentConversationId) ?? ""
        self.agentName = try c.decodeIfPresent(String.self, forKey: .agentName) ?? ""
        self.agentRole = try c.decodeIfPresent(String.self, forKey: .agentRole) ?? ""
        self.title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.isRunning = try c.decodeIfPresent(Bool.self, forKey: .isRunning) ?? false
        self.statusLabel = try c.decodeIfPresent(String.self, forKey: .statusLabel)
        self.interactions = try c.decodeIfPresent(Int.self, forKey: .interactions) ?? 0
        self.inputTokens = try c.decodeIfPresent(Int.self, forKey: .inputTokens) ?? 0
        self.cacheTokens = try c.decodeIfPresent(Int.self, forKey: .cacheTokens) ?? 0
        self.outputTokens = try c.decodeIfPresent(Int.self, forKey: .outputTokens) ?? 0
        self.contextTokens = try c.decodeIfPresent(Int.self, forKey: .contextTokens) ?? 0
        self.cachePct = try c.decodeIfPresent(Double.self, forKey: .cachePct) ?? 0.0
        self.tps = try c.decodeIfPresent(Double.self, forKey: .tps) ?? 0.0
        self.totalTokensConsumed = try c.decodeIfPresent(Int.self, forKey: .totalTokensConsumed) ?? 0
        self.totalCostUsd = try c.decodeIfPresent(Double.self, forKey: .totalCostUsd) ?? 0.0
        self.totalCacheConsumed = try c.decodeIfPresent(Int.self, forKey: .totalCacheConsumed) ?? 0
        self.totalInputConsumed = try c.decodeIfPresent(Int.self, forKey: .totalInputConsumed) ?? 0
        self.totalOutputConsumed = try c.decodeIfPresent(Int.self, forKey: .totalOutputConsumed) ?? 0
        self.currentStall = try c.decodeIfPresent(Double.self, forKey: .currentStall) ?? 0.0
        self.health = try c.decodeIfPresent(String.self, forKey: .health) ?? "🟢"
        self.healthCode = try c.decodeIfPresent(String.self, forKey: .healthCode)
        self.healthDesc = try c.decodeIfPresent(String.self, forKey: .healthDesc) ?? ""
        self.errorCode = try c.decodeIfPresent(String.self, forKey: .errorCode)
        self.currentPhase = try c.decodeIfPresent(String.self, forKey: .currentPhase) ?? ""
        self.currentAction = try c.decodeIfPresent(String.self, forKey: .currentAction) ?? ""
        self.recentError = try c.decodeIfPresent(String.self, forKey: .recentError)
        self.historySteps = try c.decodeIfPresent([SessionStep].self, forKey: .historySteps) ?? []
        self.exists = try c.decodeIfPresent(Bool.self, forKey: .exists) ?? true
        self.model = try c.decodeIfPresent(String.self, forKey: .model) ?? "3.8-flash-n"
        self.subagents = try c.decodeIfPresent([SessionItem].self, forKey: .subagents) ?? []
        self.subagentCount = try c.decodeIfPresent(Int.self, forKey: .subagentCount) ?? self.subagents.count
        self.activeSubagentCount = try c.decodeIfPresent(Int.self, forKey: .activeSubagentCount) ?? self.subagents.filter(\.isRunning).count
        self.activeSubagentTps = try c.decodeIfPresent(Double.self, forKey: .activeSubagentTps) ?? 0.0
        self.totalActiveSec = try c.decodeIfPresent(Double.self, forKey: .totalActiveSec) ?? 0.0
        self.totalLocalSec = try c.decodeIfPresent(Double.self, forKey: .totalLocalSec) ?? 0.0
        self.totalRemoteSec = try c.decodeIfPresent(Double.self, forKey: .totalRemoteSec) ?? 0.0
        self.totalErrorSec = try c.decodeIfPresent(Double.self, forKey: .totalErrorSec) ?? 0.0
        self.localPct = try c.decodeIfPresent(Double.self, forKey: .localPct)
        self.remotePct = try c.decodeIfPresent(Double.self, forKey: .remotePct)
        self.breakdownStr = try c.decodeIfPresent(String.self, forKey: .breakdownStr) ?? ""
    }

    var effectiveSubagentCount: Int {
        max(subagentCount, subagents.count)
    }

    var effectiveActiveSubagentCount: Int {
        subagents.isEmpty ? activeSubagentCount : subagents.filter(\.isRunning).count
    }

    var effectiveActiveSubagentTps: Double {
        if subagents.isEmpty {
            return activeSubagentTps
        }
        let sum = subagents.filter(\.isRunning).reduce(0.0) { $0 + $1.tps }
        return sum > 0 ? sum : activeSubagentTps
    }

    var isActivelyWorking: Bool {
        isRunning || effectiveActiveSubagentCount > 0
    }

    var aggregatedTotalTokensConsumed: Int {
        totalTokensConsumed + subagents.reduce(0) { $0 + $1.aggregatedTotalTokensConsumed }
    }

    var aggregatedTotalCostUsd: Double {
        totalCostUsd + subagents.reduce(0.0) { $0 + $1.aggregatedTotalCostUsd }
    }

    var aggregatedTotalCacheConsumed: Int {
        totalCacheConsumed + subagents.reduce(0) { $0 + $1.aggregatedTotalCacheConsumed }
    }

    var aggregatedTotalInputConsumed: Int {
        totalInputConsumed + subagents.reduce(0) { $0 + $1.aggregatedTotalInputConsumed }
    }

    var aggregatedTotalOutputConsumed: Int {
        totalOutputConsumed + subagents.reduce(0) { $0 + $1.aggregatedTotalOutputConsumed }
    }

    var aggregatedCachePct: Double {
        if subagents.isEmpty {
            return cachePct
        }
        let promptTokens = aggregatedTotalInputConsumed + aggregatedTotalCacheConsumed
        if promptTokens > 0 {
            return (Double(aggregatedTotalCacheConsumed) / Double(promptTokens)) * 100.0
        }
        let tot = aggregatedTotalTokensConsumed
        if tot > 0 && aggregatedTotalCacheConsumed > 0 {
            return (Double(aggregatedTotalCacheConsumed) / Double(tot)) * 100.0
        }
        return cachePct
    }

    var computedLocalPct: Double {
        if let lp = localPct { return lp }
        return totalActiveSec > 0 ? (totalLocalSec / totalActiveSec * 100.0) : 0.0
    }

    var isCLISession: Bool {
        (clientType ?? "app").lowercased() == "cli"
    }

    var cliBadgeLabel: String? {
        isCLISession ? "CLI" : nil
    }

    var computedRemotePct: Double {
        if let rp = remotePct { return rp }
        return totalActiveSec > 0 ? (totalRemoteSec / totalActiveSec * 100.0) : 0.0
    }

    init(
        uuid: String,
        shortId: String = "",
        clientType: String? = nil,
        parentConversationId: String = "",
        agentName: String = "",
        agentRole: String = "",
        title: String = "",
        isRunning: Bool = false,
        statusLabel: String? = nil,
        interactions: Int = 0,
        inputTokens: Int = 0,
        cacheTokens: Int = 0,
        outputTokens: Int = 0,
        contextTokens: Int = 0,
        cachePct: Double = 0.0,
        tps: Double = 0.0,
        totalTokensConsumed: Int = 0,
        totalCostUsd: Double = 0.0,
        totalCacheConsumed: Int = 0,
        totalInputConsumed: Int = 0,
        totalOutputConsumed: Int = 0,
        currentStall: Double = 0.0,
        health: String = "ok",
        healthCode: String? = nil,
        healthDesc: String = "",
        errorCode: String? = nil,
        currentPhase: String = "",
        currentAction: String = "",
        recentError: String? = nil,
        historySteps: [SessionStep] = [],
        exists: Bool = true,
        model: String = "3.8-flash-n",
        subagents: [SessionItem] = [],
        subagentCount: Int = 0,
        activeSubagentCount: Int = 0,
        activeSubagentTps: Double = 0.0,
        totalActiveSec: Double = 0.0,
        totalLocalSec: Double = 0.0,
        totalRemoteSec: Double = 0.0,
        totalErrorSec: Double = 0.0,
        localPct: Double? = nil,
        remotePct: Double? = nil,
        breakdownStr: String = ""
    ) {
        self.uuid = uuid
        self.shortId = shortId.isEmpty ? (uuid.replacingOccurrences(of: "-", with: "").prefix(6).description) : shortId
        self.clientType = clientType
        self.parentConversationId = parentConversationId
        self.agentName = agentName
        self.agentRole = agentRole
        self.title = title
        self.isRunning = isRunning
        self.statusLabel = statusLabel
        self.interactions = interactions
        self.inputTokens = inputTokens
        self.cacheTokens = cacheTokens
        self.outputTokens = outputTokens
        self.contextTokens = contextTokens
        self.cachePct = cachePct
        self.tps = tps
        self.totalTokensConsumed = totalTokensConsumed
        self.totalCostUsd = totalCostUsd
        self.totalCacheConsumed = totalCacheConsumed
        self.totalInputConsumed = totalInputConsumed
        self.totalOutputConsumed = totalOutputConsumed
        self.currentStall = currentStall
        self.health = health
        self.healthCode = healthCode
        self.healthDesc = healthDesc
        self.errorCode = errorCode
        self.currentPhase = currentPhase
        self.currentAction = currentAction
        self.recentError = recentError
        self.historySteps = historySteps
        self.exists = exists
        self.model = model
        self.subagents = subagents
        self.subagentCount = max(subagentCount, subagents.count)
        self.activeSubagentCount = activeSubagentCount
        self.activeSubagentTps = activeSubagentTps
        self.totalActiveSec = totalActiveSec
        self.totalLocalSec = totalLocalSec
        self.totalRemoteSec = totalRemoteSec
        self.totalErrorSec = totalErrorSec
        self.localPct = localPct
        self.remotePct = remotePct
        self.breakdownStr = breakdownStr
    }
}

enum UsageRangeOption: String, CaseIterable, Identifiable, Equatable {
    case today = "today"
    case last7Days = "7d"
    case last30Days = "30d"

    var id: String { rawValue }

    var title: String { title(for: .zhHans) }

    func title(for lang: AppLanguage.Resolved) -> String {
        switch self {
        case .today: return L10n.t(.usageRangeToday, lang)
        case .last7Days: return L10n.t(.usageRange7Days, lang)
        case .last30Days: return L10n.t(.usageRange30Days, lang)
        }
    }

    var shortHeaderTitle: String { shortHeaderTitle(for: .zhHans) }

    func shortHeaderTitle(for lang: AppLanguage.Resolved) -> String {
        switch self {
        case .today: return L10n.t(.usageHeaderToday, lang)
        case .last7Days: return L10n.t(.usageHeader7Days, lang)
        case .last30Days: return L10n.t(.usageHeader30Days, lang)
        }
    }
}

enum UsageMetricMode: String, CaseIterable, Identifiable, Equatable {
    case cost = "cost"
    case tokens = "tokens"

    var id: String { rawValue }

    var title: String { title(for: .zhHans) }

    func title(for lang: AppLanguage.Resolved) -> String {
        switch self {
        case .cost: return L10n.t(.usageMetricCost, lang)
        case .tokens: return L10n.t(.usageMetricTokens, lang)
        }
    }
}

enum UsageBreakdownDimension: String, CaseIterable, Identifiable, Equatable {
    case model = "model"
    case conversation = "conversation"

    var id: String { rawValue }

    var title: String { title(for: .zhHans) }

    func title(for lang: AppLanguage.Resolved) -> String {
        switch self {
        case .model: return L10n.t(.usageDimModel, lang)
        case .conversation: return L10n.t(.usageDimSession, lang)
        }
    }
}

struct UsageModelStat: Codable, Identifiable, Equatable, Hashable {
    var id: String { model }
    let model: String
    let displayName: String
    let costUsd: Double
    let totalTokens: Int
    let inputTokens: Int
    let cacheTokens: Int
    let outputTokens: Int
    let calls: Int

    enum CodingKeys: String, CodingKey {
        case model
        case displayName = "display_name"
        case costUsd = "cost_usd"
        case totalTokens = "total_tokens"
        case inputTokens = "input_tokens"
        case cacheTokens = "cache_tokens"
        case outputTokens = "output_tokens"
        case calls
    }
}

struct UsageConversationStat: Codable, Identifiable, Equatable, Hashable {
    var id: String { uuid }
    let uuid: String
    let title: String
    let clientType: String
    let topModel: String
    let topModelDisplay: String
    let costUsd: Double
    let totalTokens: Int
    let inputTokens: Int
    let cacheTokens: Int
    let outputTokens: Int
    let calls: Int
    let subagentCount: Int

    enum CodingKeys: String, CodingKey {
        case uuid
        case title
        case clientType = "client_type"
        case topModel = "top_model"
        case topModelDisplay = "top_model_display"
        case costUsd = "cost_usd"
        case totalTokens = "total_tokens"
        case inputTokens = "input_tokens"
        case cacheTokens = "cache_tokens"
        case outputTokens = "output_tokens"
        case calls
        case subagentCount = "subagent_count"
    }
}

struct UsageDailyBucket: Codable, Identifiable, Equatable {
    var id: String { date }
    let date: String
    let label: String
    let costUsd: Double
    let totalTokens: Int
    let inputTokens: Int
    let cacheTokens: Int
    let outputTokens: Int
    let calls: Int
    let models: [UsageModelStat]
    let sessions: [UsageConversationStat]

    enum CodingKeys: String, CodingKey {
        case date
        case label
        case costUsd = "cost_usd"
        case totalTokens = "total_tokens"
        case inputTokens = "input_tokens"
        case cacheTokens = "cache_tokens"
        case outputTokens = "output_tokens"
        case calls
        case models
        case sessions
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.date = try c.decode(String.self, forKey: .date)
        self.label = try c.decode(String.self, forKey: .label)
        self.costUsd = try c.decode(Double.self, forKey: .costUsd)
        self.totalTokens = try c.decode(Int.self, forKey: .totalTokens)
        self.inputTokens = try c.decode(Int.self, forKey: .inputTokens)
        self.cacheTokens = try c.decode(Int.self, forKey: .cacheTokens)
        self.outputTokens = try c.decode(Int.self, forKey: .outputTokens)
        self.calls = try c.decode(Int.self, forKey: .calls)
        self.models = try c.decodeIfPresent([UsageModelStat].self, forKey: .models) ?? []
        self.sessions = try c.decodeIfPresent([UsageConversationStat].self, forKey: .sessions) ?? []
    }
}

struct UsageHourlyBucket: Codable, Identifiable, Equatable {
    var id: Int { hour }
    let hour: Int
    let label: String
    let costUsd: Double
    let totalTokens: Int
    let inputTokens: Int
    let cacheTokens: Int
    let outputTokens: Int
    let calls: Int
    let models: [UsageModelStat]

    enum CodingKeys: String, CodingKey {
        case hour
        case label
        case costUsd = "cost_usd"
        case totalTokens = "total_tokens"
        case inputTokens = "input_tokens"
        case cacheTokens = "cache_tokens"
        case outputTokens = "output_tokens"
        case calls
        case models
    }
}

struct UsageHistoryPayload: Codable, Equatable {
    let generatedAt: String
    let todayDate: String
    let daysRequested: Int
    let daily: [UsageDailyBucket]
    let todayHourly: [UsageHourlyBucket]

    enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case todayDate = "today_date"
        case daysRequested = "days_requested"
        case daily
        case todayHourly = "today_hourly"
    }
}

enum UsageAnalyticsPolicy {
    struct BarPoint: Identifiable, Equatable {
        let id: String
        let axisLabel: String
        let detailTitle: String
        let costUsd: Double
        let totalTokens: Int
        let calls: Int
        let models: [UsageModelStat]
    }

    struct ModelSummaryRow: Identifiable, Equatable {
        var id: String { model }
        let model: String
        let displayName: String
        let costUsd: Double
        let totalTokens: Int
        let inputTokens: Int
        let cacheTokens: Int
        let outputTokens: Int
        let calls: Int
        let costSharePct: Double
        let tokenSharePct: Double
        let cachePct: Double
    }

    struct ConversationSummaryRow: Identifiable, Equatable {
        var id: String { uuid }
        let uuid: String
        let title: String
        let clientType: String
        let topModel: String
        let topModelDisplay: String
        let costUsd: Double
        let totalTokens: Int
        let inputTokens: Int
        let cacheTokens: Int
        let outputTokens: Int
        let calls: Int
        let subagentCount: Int
        let costSharePct: Double
        let tokenSharePct: Double
        let cachePct: Double
    }

    struct RangeSummary: Equatable {
        let range: UsageRangeOption
        let totalCostUsd: Double
        let totalTokens: Int
        let inputTokens: Int
        let cacheTokens: Int
        let outputTokens: Int
        let cachePct: Double
        let totalCalls: Int
        let bars: [BarPoint]
        let models: [ModelSummaryRow]
        let conversations: [ConversationSummaryRow]
    }

    private struct Accumulator {
        let model: String
        var displayName: String
        var costUsd: Double = 0
        var totalTokens: Int = 0
        var inputTokens: Int = 0
        var cacheTokens: Int = 0
        var outputTokens: Int = 0
        var calls: Int = 0
    }

    private struct ConversationAccumulator {
        let uuid: String
        var title: String
        var clientType: String
        var topModel: String
        var topModelDisplay: String
        var topModelCost: Double = 0
        var costUsd: Double = 0
        var totalTokens: Int = 0
        var inputTokens: Int = 0
        var cacheTokens: Int = 0
        var outputTokens: Int = 0
        var calls: Int = 0
        var subagentCount: Int = 0
    }

    static func summarize(payload: UsageHistoryPayload, range: UsageRangeOption, language: AppLanguage.Resolved = .zhHans) -> RangeSummary {
        var bars: [BarPoint] = []
        var totalCost = 0.0
        var totalTokens = 0
        var totalInput = 0
        var totalCache = 0
        var totalOutput = 0
        var totalCalls = 0
        var modelAcc: [String: Accumulator] = [:]
        var convAcc: [String: ConversationAccumulator] = [:]

        func mergeModels(_ items: [UsageModelStat]) {
            for m in items {
                var acc = modelAcc[m.model] ?? Accumulator(model: m.model, displayName: m.displayName)
                acc.costUsd += m.costUsd
                acc.totalTokens += m.totalTokens
                acc.inputTokens += m.inputTokens
                acc.cacheTokens += m.cacheTokens
                acc.outputTokens += m.outputTokens
                acc.calls += m.calls
                modelAcc[m.model] = acc
            }
        }

        func mergeConversations(_ items: [UsageConversationStat]) {
            for s in items {
                var acc = convAcc[s.uuid] ?? ConversationAccumulator(
                    uuid: s.uuid,
                    title: s.title,
                    clientType: s.clientType,
                    topModel: s.topModel,
                    topModelDisplay: s.topModelDisplay
                )
                acc.costUsd += s.costUsd
                acc.totalTokens += s.totalTokens
                acc.inputTokens += s.inputTokens
                acc.cacheTokens += s.cacheTokens
                acc.outputTokens += s.outputTokens
                acc.calls += s.calls
                acc.subagentCount = max(acc.subagentCount, s.subagentCount)
                if s.costUsd >= acc.topModelCost {
                    acc.topModelCost = s.costUsd
                    acc.topModel = s.topModel
                    acc.topModelDisplay = s.topModelDisplay
                }
                if acc.title.isEmpty && !s.title.isEmpty {
                    acc.title = s.title
                }
                convAcc[s.uuid] = acc
            }
        }

        switch range {
        case .today:
            let sortedHours = payload.todayHourly.sorted { $0.hour < $1.hour }
            for hr in sortedHours {
                let hrStr = String(format: "%02d", hr.hour)
                bars.append(BarPoint(
                    id: hrStr,
                    axisLabel: hrStr,
                    detailTitle: L10n.usageTodayHourTitle(hr.label, language),
                    costUsd: hr.costUsd,
                    totalTokens: hr.totalTokens,
                    calls: hr.calls,
                    models: hr.models
                ))
                totalCost += hr.costUsd
                totalTokens += hr.totalTokens
                totalInput += hr.inputTokens
                totalCache += hr.cacheTokens
                totalOutput += hr.outputTokens
                totalCalls += hr.calls
                mergeModels(hr.models)
            }
            if let todayBucket = payload.daily.last {
                mergeConversations(todayBucket.sessions)
            }
        case .last7Days, .last30Days:
            let limit = range == .last7Days ? 7 : 30
            let slice = Array(payload.daily.suffix(limit))
            for day in slice {
                bars.append(BarPoint(
                    id: day.date,
                    axisLabel: day.label,
                    detailTitle: day.date,
                    costUsd: day.costUsd,
                    totalTokens: day.totalTokens,
                    calls: day.calls,
                    models: day.models
                ))
                totalCost += day.costUsd
                totalTokens += day.totalTokens
                totalInput += day.inputTokens
                totalCache += day.cacheTokens
                totalOutput += day.outputTokens
                totalCalls += day.calls
                mergeModels(day.models)
                mergeConversations(day.sessions)
            }
        }

        let cachePct = totalTokens > 0 ? (Double(totalCache) / Double(totalTokens)) * 100.0 : 0.0
        let rows: [ModelSummaryRow] = modelAcc.values
            .sorted {
                if abs($0.costUsd - $1.costUsd) > 1e-6 {
                    return $0.costUsd > $1.costUsd
                }
                if $0.totalTokens != $1.totalTokens {
                    return $0.totalTokens > $1.totalTokens
                }
                return $0.model < $1.model
            }
            .map { acc in
                let cShare = totalCost > 0 ? (acc.costUsd / totalCost) * 100.0 : 0.0
                let tShare = totalTokens > 0 ? (Double(acc.totalTokens) / Double(totalTokens)) * 100.0 : 0.0
                let mCachePct = acc.totalTokens > 0 ? (Double(acc.cacheTokens) / Double(acc.totalTokens)) * 100.0 : 0.0
                return ModelSummaryRow(
                    model: acc.model,
                    displayName: acc.displayName,
                    costUsd: acc.costUsd,
                    totalTokens: acc.totalTokens,
                    inputTokens: acc.inputTokens,
                    cacheTokens: acc.cacheTokens,
                    outputTokens: acc.outputTokens,
                    calls: acc.calls,
                    costSharePct: cShare,
                    tokenSharePct: tShare,
                    cachePct: mCachePct
                )
            }

        let convCostDenom = max(totalCost, convAcc.values.reduce(0.0) { $0 + $1.costUsd })
        let convTokDenom = max(totalTokens, convAcc.values.reduce(0) { $0 + $1.totalTokens })
        let convRows: [ConversationSummaryRow] = convAcc.values
            .sorted {
                if abs($0.costUsd - $1.costUsd) > 1e-6 {
                    return $0.costUsd > $1.costUsd
                }
                if $0.totalTokens != $1.totalTokens {
                    return $0.totalTokens > $1.totalTokens
                }
                return $0.uuid < $1.uuid
            }
            .map { acc in
                let cShare = convCostDenom > 0 ? (acc.costUsd / convCostDenom) * 100.0 : 0.0
                let tShare = convTokDenom > 0 ? (Double(acc.totalTokens) / Double(convTokDenom)) * 100.0 : 0.0
                let sCachePct = acc.totalTokens > 0 ? (Double(acc.cacheTokens) / Double(acc.totalTokens)) * 100.0 : 0.0
                return ConversationSummaryRow(
                    uuid: acc.uuid,
                    title: acc.title,
                    clientType: acc.clientType,
                    topModel: acc.topModel,
                    topModelDisplay: acc.topModelDisplay,
                    costUsd: acc.costUsd,
                    totalTokens: acc.totalTokens,
                    inputTokens: acc.inputTokens,
                    cacheTokens: acc.cacheTokens,
                    outputTokens: acc.outputTokens,
                    calls: acc.calls,
                    subagentCount: acc.subagentCount,
                    costSharePct: cShare,
                    tokenSharePct: tShare,
                    cachePct: sCachePct
                )
            }

        return RangeSummary(
            range: range,
            totalCostUsd: totalCost,
            totalTokens: totalTokens,
            inputTokens: totalInput,
            cacheTokens: totalCache,
            outputTokens: totalOutput,
            cachePct: cachePct,
            totalCalls: totalCalls,
            bars: bars,
            models: rows,
            conversations: convRows
        )
    }

    static func sortedModels(_ models: [ModelSummaryRow], by metric: UsageMetricMode) -> [ModelSummaryRow] {
        switch metric {
        case .cost:
            return models
        case .tokens:
            return models.sorted {
                if $0.totalTokens != $1.totalTokens {
                    return $0.totalTokens > $1.totalTokens
                }
                return $0.costUsd > $1.costUsd
            }
        }
    }

    static func sortedConversations(_ conversations: [ConversationSummaryRow], by metric: UsageMetricMode) -> [ConversationSummaryRow] {
        switch metric {
        case .cost:
            return conversations
        case .tokens:
            return conversations.sorted {
                if $0.totalTokens != $1.totalTokens {
                    return $0.totalTokens > $1.totalTokens
                }
                return $0.costUsd > $1.costUsd
            }
        }
    }

    static func xAxisTickLabels(for bars: [BarPoint], range: UsageRangeOption) -> [String] {
        guard !bars.isEmpty else { return [] }
        switch range {
        case .today:
            let targets: Set<String> = ["00", "06", "12", "18", "23"]
            return bars.map(\.axisLabel).filter { targets.contains($0) }
        case .last7Days:
            return bars.map(\.axisLabel)
        case .last30Days:
            let count = bars.count
            guard count > 6 else { return bars.map(\.axisLabel) }
            let strideStep = max(1, (count - 1) / 5)
            var result: [String] = []
            for idx in stride(from: 0, to: count, by: strideStep) {
                result.append(bars[idx].axisLabel)
            }
            if let lastLabel = bars.last?.axisLabel, result.last != lastLabel {
                if result.count >= 6 {
                    result[result.count - 1] = lastLabel
                } else {
                    result.append(lastLabel)
                }
            }
            return result
        }
    }

    static func accentColor(for modelKey: String) -> Color {
        let lower = modelKey.lowercased()
        if lower.contains("claude") {
            if lower.contains("opus") {
                return Color(red: 0.88, green: 0.42, blue: 0.18)
            }
            return Color(red: 0.94, green: 0.58, blue: 0.16)
        }
        if lower.contains("neon") {
            return Color(red: 0.91, green: 0.36, blue: 0.14)
        }
        if lower.contains("argon") {
            return Color(red: 0.08, green: 0.68, blue: 0.66)
        }
        if lower.contains("carbon") {
            return Color(red: 0.28, green: 0.56, blue: 0.86)
        }
        if lower.contains("hydrogen") {
            return Color(red: 0.25, green: 0.48, blue: 0.94)
        }
        if lower.contains("flash") {
            return Color(red: 0.20, green: 0.72, blue: 0.44)
        }
        if lower.contains("pro") {
            return Color(red: 0.68, green: 0.36, blue: 0.88)
        }
        if lower.contains("gpt") {
            return Color(red: 0.52, green: 0.44, blue: 0.82)
        }
        return Color.secondary.opacity(0.65)
    }
}

struct AGYProfile: Codable, Identifiable, Hashable {
    var id: String { name }
    var name: String
    var email: String?
    var tier: String?
    var userDataDir: String
    var geminiDataDir: String
    var notes: String
    var isDefault: Bool?
    var createdAt: String
    var lastUsedAt: TimeInterval?

    var isDefaultProfile: Bool {
        isDefault ?? false
    }

    init(
        name: String,
        email: String? = nil,
        tier: String? = nil,
        userDataDir: String,
        geminiDataDir: String = "",
        notes: String = "",
        isDefault: Bool? = false,
        createdAt: String = "",
        lastUsedAt: TimeInterval? = nil
    ) {
        self.name = name
        self.email = email
        self.tier = tier
        self.userDataDir = userDataDir
        self.geminiDataDir = geminiDataDir
        self.notes = notes
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }
}

enum Formatters {
    static func formatTokens(_ n: Int) -> String {
        if n >= 1_000_000 {
            return String(format: "%.1fM", Double(n) / 1_000_000.0)
        } else if n >= 1_000 {
            return String(format: "%.0fk", Double(n) / 1_000.0)
        }
        return "\(n)"
    }

    static func formatCost(_ usd: Double) -> String {
        if usd <= 0 { return "$0.00" }
        if usd < 0.01 { return String(format: "$%.3f", usd) }
        return String(format: "$%.2f", usd)
    }

    static func formatHMS(_ seconds: Double) -> String {
        if seconds <= 0 { return "0s" }
        let s = Int(seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 { return "\(h)h\(m)m\(sec)s" }
        if m > 0 { return "\(m)m\(sec)s" }
        return "\(sec)s"
    }
}

struct AgentContextPoint: Equatable, Hashable {
    let agentId: String
    let label: String
    let contextTokens: Int
    let isRunning: Bool
    let tps: Double
    var parentAgentId: String? = nil
}

struct AgentSeriesSamplePoint: Identifiable, Equatable {
    var id: String { customId ?? "\(isForkAnchor ? "fork-" : "")\(timestamp.timeIntervalSince1970)" }
    let timestamp: Date
    let contextTokens: Int
    let isRunning: Bool
    let tps: Double
    var isForkAnchor: Bool = false
    var customId: String? = nil
}

struct AgentCurveSegment: Identifiable, Equatable {
    let id: String
    let isForkSegment: Bool
    let points: [AgentSeriesSamplePoint]
}

struct AgentCurveStrokeRun: Identifiable, Equatable {
    let id: String
    let isIdle: Bool
    let points: [AgentSeriesSamplePoint]
}

struct ResolvedAgentCurveSegment: Identifiable, Equatable {
    let id: String
    let points: [AgentSeriesSamplePoint]
    let forkJunction: AgentSeriesSamplePoint?
    var strokeRuns: [AgentCurveStrokeRun] = []
}

struct ResolvedAgentCurveSeries: Identifiable, Equatable {
    var id: String { agentId }
    let agentId: String
    let parentAgentId: String?
    let segments: [ResolvedAgentCurveSegment]
}

struct TelemetrySeriesTone: Equatable {
    let red: Double
    let green: Double
    let blue: Double

    var color: Color {
        Color(red: red, green: green, blue: blue)
    }

    var relativeLuminance: Double {
        0.2126 * red + 0.7152 * green + 0.0722 * blue
    }

    var capsuleForegroundColor: Color {
        relativeLuminance > 0.48 ? Color.black.opacity(0.86) : .white
    }

    var hueDegrees: Double {
        let maxC = max(red, max(green, blue))
        let minC = min(red, min(green, blue))
        let delta = maxC - minC
        guard delta > 1e-6 else { return 0.0 }
        var hue: Double
        if maxC == red {
            hue = ((green - blue) / delta).truncatingRemainder(dividingBy: 6.0)
        } else if maxC == green {
            hue = ((blue - red) / delta) + 2.0
        } else {
            hue = ((red - green) / delta) + 4.0
        }
        hue *= 60.0
        if hue < 0 { hue += 360.0 }
        return hue
    }

    func euclideanDistance(to other: TelemetrySeriesTone) -> Double {
        let dr = red - other.red
        let dg = green - other.green
        let db = blue - other.blue
        return sqrt(dr * dr + dg * dg + db * db)
    }
}

struct TelemetryColorFamilySpec: Equatable {
    let index: Int
    let nameZh: String
    let nameEn: String
    let rootHex: String
    let childHexes: [String]
    let rootTone: TelemetrySeriesTone
    let childTones: [TelemetrySeriesTone]

    var allTones: [TelemetrySeriesTone] {
        [rootTone] + childTones
    }
}

enum LiveTelemetryColorPalette {
    static let familySpecs: [TelemetryColorFamilySpec] = [
        TelemetryColorFamilySpec(
            index: 0,
            nameZh: "钴蓝海系",
            nameEn: "Cobalt Blue",
            rootHex: "#004FC8",
            childHexes: ["#00A7E9", "#5FD3EC", "#566BE9", "#004E80"],
            rootTone: TelemetrySeriesTone(red: 0.000, green: 0.311, blue: 0.784),
            childTones: [
                TelemetrySeriesTone(red: 0.000, green: 0.654, blue: 0.913),
                TelemetrySeriesTone(red: 0.371, green: 0.828, blue: 0.926),
                TelemetrySeriesTone(red: 0.337, green: 0.419, blue: 0.912),
                TelemetrySeriesTone(red: 0.000, green: 0.305, blue: 0.501)
            ]
        ),
        TelemetryColorFamilySpec(
            index: 1,
            nameZh: "翡翠森绿",
            nameEn: "Emerald Jade",
            rootHex: "#157E2C",
            childHexes: ["#5BC25D", "#92E8AA", "#72A01D", "#00622F"],
            rootTone: TelemetrySeriesTone(red: 0.081, green: 0.495, blue: 0.172),
            childTones: [
                TelemetrySeriesTone(red: 0.355, green: 0.762, blue: 0.365),
                TelemetrySeriesTone(red: 0.574, green: 0.909, blue: 0.667),
                TelemetrySeriesTone(red: 0.449, green: 0.629, blue: 0.112),
                TelemetrySeriesTone(red: 0.000, green: 0.383, blue: 0.184)
            ]
        ),
        TelemetryColorFamilySpec(
            index: 2,
            nameZh: "赤陶琥珀",
            nameEn: "Terracotta Amber",
            rootHex: "#BB3F00",
            childHexes: ["#FA7C20", "#FFB76D", "#ED4B40", "#8E3609"],
            rootTone: TelemetrySeriesTone(red: 0.735, green: 0.248, blue: 0.000),
            childTones: [
                TelemetrySeriesTone(red: 0.981, green: 0.486, blue: 0.124),
                TelemetrySeriesTone(red: 1.000, green: 0.716, blue: 0.427),
                TelemetrySeriesTone(red: 0.929, green: 0.295, blue: 0.252),
                TelemetrySeriesTone(red: 0.555, green: 0.210, blue: 0.034)
            ]
        ),
        TelemetryColorFamilySpec(
            index: 3,
            nameZh: "鸢尾紫系",
            nameEn: "Iris Violet",
            rootHex: "#5731BB",
            childHexes: ["#7C6FF2", "#A7A9FF", "#AE74ED", "#505DCC"],
            rootTone: TelemetrySeriesTone(red: 0.341, green: 0.194, blue: 0.732),
            childTones: [
                TelemetrySeriesTone(red: 0.487, green: 0.435, blue: 0.950),
                TelemetrySeriesTone(red: 0.656, green: 0.663, blue: 1.000),
                TelemetrySeriesTone(red: 0.682, green: 0.454, blue: 0.931),
                TelemetrySeriesTone(red: 0.315, green: 0.366, blue: 0.800)
            ]
        ),
        TelemetryColorFamilySpec(
            index: 4,
            nameZh: "石榴玫红",
            nameEn: "Crimson Rose",
            rootHex: "#AD0445",
            childHexes: ["#F24471", "#FF96AE", "#E03CA0", "#831C42"],
            rootTone: TelemetrySeriesTone(red: 0.680, green: 0.016, blue: 0.269),
            childTones: [
                TelemetrySeriesTone(red: 0.948, green: 0.267, blue: 0.445),
                TelemetrySeriesTone(red: 1.000, green: 0.587, blue: 0.681),
                TelemetrySeriesTone(red: 0.880, green: 0.235, blue: 0.628),
                TelemetrySeriesTone(red: 0.513, green: 0.108, blue: 0.257)
            ]
        ),
        TelemetryColorFamilySpec(
            index: 5,
            nameZh: "湖水青碧",
            nameEn: "Teal Lagoon",
            rootHex: "#008391",
            childHexes: ["#00C3C5", "#7CE7DD", "#00A6C8", "#006069"],
            rootTone: TelemetrySeriesTone(red: 0.000, green: 0.513, blue: 0.568),
            childTones: [
                TelemetrySeriesTone(red: 0.000, green: 0.766, blue: 0.774),
                TelemetrySeriesTone(red: 0.487, green: 0.904, blue: 0.867),
                TelemetrySeriesTone(red: 0.000, green: 0.650, blue: 0.786),
                TelemetrySeriesTone(red: 0.000, green: 0.377, blue: 0.413)
            ]
        ),
        TelemetryColorFamilySpec(
            index: 6,
            nameZh: "琉璃金茶",
            nameEn: "Ochre Gold",
            rootHex: "#AD8700",
            childHexes: ["#E3BE1F", "#F8E277", "#DE8E00", "#815C00"],
            rootTone: TelemetrySeriesTone(red: 0.678, green: 0.530, blue: 0.000),
            childTones: [
                TelemetrySeriesTone(red: 0.890, green: 0.744, blue: 0.123),
                TelemetrySeriesTone(red: 0.973, green: 0.887, blue: 0.467),
                TelemetrySeriesTone(red: 0.869, green: 0.556, blue: 0.000),
                TelemetrySeriesTone(red: 0.504, green: 0.362, blue: 0.000)
            ]
        ),
        TelemetryColorFamilySpec(
            index: 7,
            nameZh: "梅子品红",
            nameEn: "Plum Fuchsia",
            rootHex: "#A71C96",
            childHexes: ["#E25CDB", "#F3A3F5", "#D034A4", "#702B77"],
            rootTone: TelemetrySeriesTone(red: 0.653, green: 0.109, blue: 0.588),
            childTones: [
                TelemetrySeriesTone(red: 0.888, green: 0.361, blue: 0.857),
                TelemetrySeriesTone(red: 0.952, green: 0.640, blue: 0.959),
                TelemetrySeriesTone(red: 0.817, green: 0.204, blue: 0.643),
                TelemetrySeriesTone(red: 0.440, green: 0.168, blue: 0.467)
            ]
        )
    ]

    static let families: [[TelemetrySeriesTone]] = familySpecs.map(\.allTones)

    static func tone(familyIndex: Int, tier: Int) -> TelemetrySeriesTone {
        let family = families[abs(familyIndex) % families.count]
        if tier <= 0 {
            return family[0]
        }
        let childTiers = family.count - 1
        let childOffset = ((tier - 1) % childTiers) + 1
        return family[childOffset]
    }
}

struct AgentContextSeries: Identifiable, Equatable {
    var id: String { agentId }
    let agentId: String
    let label: String
    let isRunning: Bool
    let latestContextTokens: Int
    let latestTps: Double
    let colorIndex: Int
    var familyIndex: Int = 0
    var familyTier: Int = 0
    var parentAgentId: String? = nil
    let segments: [AgentCurveSegment]
    var points: [AgentSeriesSamplePoint] { segments.flatMap(\.points) }
}

struct SessionTelemetryColorLink: Equatable {
    let primaryTone: TelemetrySeriesTone
    let childTones: [TelemetrySeriesTone]
    let seriesIds: Set<String>
    let hasDirectSeries: Bool
}

struct LiveTelemetrySample: Identifiable, Equatable {
    let id: Int
    let timestamp: Date
    let activeAgentCount: Int
    let totalTps: Double
    let totalTokensCumulative: Int
    let deltaTokens: Int
    let cachePct: Double
    let isIdleCacheHold: Bool
    var deltaCacheTokens: Int = 0
    var deltaNewTokens: Int = 0
    var agentContexts: [AgentContextPoint] = []
}

struct TelemetryWindowSummary: Equatable {
    let totalTokens: Int
    let cachePct: Double
    let hasWindowTraffic: Bool
}

enum TelemetryTimeRange: String, CaseIterable, Identifiable {
    case oneMinute = "1m"
    case threeMinutes = "3m"
    case fifteenMinutes = "15m"
    case oneHour = "1h"

    var id: String { rawValue }

    var seconds: TimeInterval {
        switch self {
        case .oneMinute: return 60
        case .threeMinutes: return 180
        case .fifteenMinutes: return 900
        case .oneHour: return 3600
        }
    }

    static func resolved(from raw: String) -> TelemetryTimeRange {
        if raw == "5m" {
            return .threeMinutes
        }
        return TelemetryTimeRange(rawValue: raw) ?? .threeMinutes
    }
}

enum LiveTelemetryPolicy {
    struct ChartDomains: Equatable {
        let maxTps: Double
        let maxAgents: Int
        let cacheMinY: Double
    }

    static let maxSamples: Int = 720
    static let minimumSampleSpacingSeconds: TimeInterval = 1.5

    static func extractLiveMetrics(from payload: MonitorPayload) -> (activeAgentCount: Int, totalTps: Double) {
        let topIds = Set(payload.sessions.map(\.uuid))
        let topSessions = payload.sessions.filter {
            $0.parentConversationId.isEmpty || !topIds.contains($0.parentConversationId)
        }
        var agents = 0
        var tps = 0.0
        for s in topSessions {
            let selfRunning = s.isRunning ? 1 : 0
            let subRunning = s.effectiveActiveSubagentCount
            agents += selfRunning + subRunning
            if s.isRunning {
                tps += max(0.0, s.tps)
            }
            tps += max(0.0, s.effectiveActiveSubagentTps)
        }
        return (agents, tps)
    }

    static func cleanAgentLabel(session: SessionItem, isSubagent: Bool) -> String {
        if isSubagent {
            let name = session.agentName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty { return name }
            let role = session.agentRole.trimmingCharacters(in: .whitespacesAndNewlines)
            if !role.isEmpty { return role }
        }
        let raw = session.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let invalid: Set<String> = ["{", "}", "{}", "未命名会话", "[", "]", "[]", ""]
        if invalid.contains(raw) {
            return String(session.shortId.prefix(6))
        }
        return raw
    }

    static func extractAgentSnapshots(
        from payload: MonitorPayload,
        previouslyActiveIds: Set<String>
    ) -> [AgentContextPoint] {
        var byId: [String: (session: SessionItem, isSubagent: Bool, parentId: String?)] = [:]
        var order: [String] = []

        func register(_ item: SessionItem, isSubagent: Bool, explicitParentId: String?) {
            let resolvedParent = explicitParentId ?? (item.parentConversationId.isEmpty ? nil : item.parentConversationId)
            if let existing = byId[item.uuid] {
                let preferNew = (item.isActivelyWorking && !existing.session.isActivelyWorking)
                    || (item.isActivelyWorking == existing.session.isActivelyWorking && item.contextTokens > existing.session.contextTokens)
                if preferNew {
                    byId[item.uuid] = (item, existing.isSubagent && isSubagent, resolvedParent ?? existing.parentId)
                }
            } else {
                byId[item.uuid] = (item, isSubagent, resolvedParent)
                order.append(item.uuid)
            }
            for sub in item.subagents {
                register(sub, isSubagent: true, explicitParentId: item.uuid)
            }
        }

        for top in payload.sessions {
            let pId = top.parentConversationId.isEmpty ? nil : top.parentConversationId
            register(top, isSubagent: pId != nil, explicitParentId: pId)
        }

        var points: [AgentContextPoint] = []
        for uid in order {
            guard let entry = byId[uid] else { continue }
            let s = entry.session
            let isRunningSelf = s.isRunning
            let waitingOnActiveChild = !isRunningSelf && s.effectiveActiveSubagentCount > 0
            if isRunningSelf || (previouslyActiveIds.contains(uid) && !waitingOnActiveChild) {
                points.append(
                    AgentContextPoint(
                        agentId: uid,
                        label: cleanAgentLabel(session: s, isSubagent: entry.isSubagent),
                        contextTokens: max(0, s.contextTokens),
                        isRunning: isRunningSelf,
                        tps: isRunningSelf ? max(0.0, s.tps) : 0.0,
                        parentAgentId: entry.parentId
                    )
                )
            }
        }

        if points.isEmpty {
            let fallbackTop = payload.sessions
                .filter { $0.parentConversationId.isEmpty && $0.contextTokens > 0 }
                .prefix(3)
            for s in fallbackTop {
                points.append(
                    AgentContextPoint(
                        agentId: s.uuid,
                        label: cleanAgentLabel(session: s, isSubagent: false),
                        contextTokens: max(0, s.contextTokens),
                        isRunning: false,
                        tps: 0.0,
                        parentAgentId: nil
                    )
                )
            }
        }

        return points
    }

    private static func globalAncestryAndTiers(
        in anchorSamples: [LiveTelemetrySample],
        existingPinnedFamilies: [String: Int]
    ) -> (
        familyByRoot: [String: Int],
        tierByAgentId: [String: Int],
        ancestryById: [String: (rootKey: String, depth: Int)]
    ) {
        var firstSeenByAgent: [String: Int] = [:]
        var parentByAgent: [String: String] = [:]

        for (sIdx, sample) in anchorSamples.enumerated() {
            for pt in sample.agentContexts {
                if firstSeenByAgent[pt.agentId] == nil {
                    firstSeenByAgent[pt.agentId] = sIdx
                }
                if let pid = pt.parentAgentId, !pid.isEmpty {
                    parentByAgent[pt.agentId] = pid
                }
            }
        }

        func resolve(_ agentId: String) -> (rootKey: String, depth: Int) {
            var cur = agentId
            var depth = 0
            var visited = Set<String>([cur])
            while let pid = parentByAgent[cur], !pid.isEmpty {
                depth += 1
                if firstSeenByAgent[pid] != nil, !visited.contains(pid) {
                    visited.insert(pid)
                    cur = pid
                } else {
                    return (pid, depth)
                }
            }
            return (cur, depth)
        }

        var membersByRoot: [String: [(agentId: String, depth: Int, firstIdx: Int)]] = [:]
        var ancestryById: [String: (rootKey: String, depth: Int)] = [:]
        for (uid, firstIdx) in firstSeenByAgent {
            let info = resolve(uid)
            ancestryById[uid] = info
            membersByRoot[info.rootKey, default: []].append((uid, info.depth, firstIdx))
        }

        let sortedRoots = membersByRoot.keys.sorted { a, b in
            let aMin = membersByRoot[a]?.map(\.firstIdx).min() ?? Int.max
            let bMin = membersByRoot[b]?.map(\.firstIdx).min() ?? Int.max
            if aMin != bMin { return aMin < bMin }
            return a < b
        }

        let familyCount = max(1, LiveTelemetryColorPalette.families.count)
        var familyByRoot = existingPinnedFamilies
        var slotUsage = Array(repeating: 0, count: familyCount)
        for rootKey in sortedRoots {
            if let assigned = familyByRoot[rootKey] {
                let normalized = abs(assigned) % familyCount
                familyByRoot[rootKey] = normalized
                slotUsage[normalized] += 1
            }
        }
        for (_, assigned) in existingPinnedFamilies.filter({ membersByRoot[$0.key] == nil }) {
            let normalized = abs(assigned) % familyCount
            slotUsage[normalized] += 1
        }

        for rootKey in sortedRoots where familyByRoot[rootKey] == nil {
            let bestSlot = (0..<familyCount).min { a, b in
                if slotUsage[a] != slotUsage[b] {
                    return slotUsage[a] < slotUsage[b]
                }
                return a < b
            } ?? 0
            familyByRoot[rootKey] = bestSlot
            slotUsage[bestSlot] += 1
        }

        var tierByAgentId: [String: Int] = [:]
        for rootKey in sortedRoots {
            let sortedMembers = (membersByRoot[rootKey] ?? []).sorted { a, b in
                if a.depth != b.depth { return a.depth < b.depth }
                if a.firstIdx != b.firstIdx { return a.firstIdx < b.firstIdx }
                return a.agentId < b.agentId
            }
            var nextChildTier = 1
            for member in sortedMembers {
                if member.depth == 0 {
                    tierByAgentId[member.agentId] = 0
                } else {
                    tierByAgentId[member.agentId] = nextChildTier
                    nextChildTier += 1
                }
            }
        }

        return (familyByRoot, tierByAgentId, ancestryById)
    }

    static func updatedPinnedFamilies(
        existing: [String: Int],
        from samples: [LiveTelemetrySample]
    ) -> [String: Int] {
        globalAncestryAndTiers(in: samples, existingPinnedFamilies: existing).familyByRoot
    }

    static func agentSeries(
        in samples: [LiveTelemetrySample],
        colorAnchorSamples: [LiveTelemetrySample]? = nil,
        pinnedFamilyByRoot: [String: Int] = [:],
        maxSeries: Int = 8
    ) -> [AgentContextSeries] {
        struct IndexedSeriesPoint {
            let sampleIdx: Int
            let point: AgentSeriesSamplePoint
        }

        struct GroupedAccumulator {
            var label: String
            var parentAgentId: String?
            var indexedPoints: [IndexedSeriesPoint]
            var hadRunning: Bool
            var firstSampleIndex: Int
            var lastSampleIndex: Int
        }

        var grouped: [String: GroupedAccumulator] = [:]
        var sampleAgentMap: [[String: AgentContextPoint]] = []
        var directChildrenByParent: [String: Set<String>] = [:]

        for (sampleIdx, sample) in samples.enumerated() {
            var mapForTick: [String: AgentContextPoint] = [:]
            for pt in sample.agentContexts {
                mapForTick[pt.agentId] = pt
                if let pid = pt.parentAgentId, !pid.isEmpty {
                    directChildrenByParent[pid, default: []].insert(pt.agentId)
                }
                let seriesPt = AgentSeriesSamplePoint(
                    timestamp: sample.timestamp,
                    contextTokens: pt.contextTokens,
                    isRunning: pt.isRunning,
                    tps: pt.tps,
                    isForkAnchor: false
                )
                let indexed = IndexedSeriesPoint(sampleIdx: sampleIdx, point: seriesPt)
                if var existing = grouped[pt.agentId] {
                    existing.label = pt.label
                    if existing.parentAgentId == nil, let pid = pt.parentAgentId {
                        existing.parentAgentId = pid
                    }
                    existing.indexedPoints.append(indexed)
                    existing.lastSampleIndex = sampleIdx
                    existing.hadRunning = existing.hadRunning || pt.isRunning
                    grouped[pt.agentId] = existing
                } else {
                    grouped[pt.agentId] = GroupedAccumulator(
                        label: pt.label,
                        parentAgentId: pt.parentAgentId,
                        indexedPoints: [indexed],
                        hadRunning: pt.isRunning,
                        firstSampleIndex: sampleIdx,
                        lastSampleIndex: sampleIdx
                    )
                }
            }
            sampleAgentMap.append(mapForTick)
        }

        let hasAnyRunningInWindow = grouped.values.contains { $0.hadRunning }
        var keptIds = Set(
            grouped
                .filter { !hasAnyRunningInWindow || $0.value.hadRunning }
                .map(\.key)
        )
        var pendingAncestors = Array(keptIds)
        while let uid = pendingAncestors.popLast() {
            if let pid = grouped[uid]?.parentAgentId,
               grouped[pid] != nil,
               !keptIds.contains(pid) {
                keptIds.insert(pid)
                pendingAncestors.append(pid)
            }
        }

        func resolveAncestry(_ agentId: String) -> (rootKey: String, depth: Int) {
            var cur = agentId
            var depth = 0
            var visited = Set<String>([cur])
            while let pid = grouped[cur]?.parentAgentId, !pid.isEmpty {
                depth += 1
                if grouped[pid] != nil, !visited.contains(pid) {
                    visited.insert(pid)
                    cur = pid
                } else {
                    return (pid, depth)
                }
            }
            return (cur, depth)
        }

        let anchorPool = (colorAnchorSamples?.isEmpty == false) ? colorAnchorSamples! : samples
        let anchorInfo = globalAncestryAndTiers(
            in: anchorPool,
            existingPinnedFamilies: pinnedFamilyByRoot
        )

        var familyMembers: [String: [(agentId: String, depth: Int, firstSampleIndex: Int)]] = [:]
        var ancestryById: [String: (rootKey: String, depth: Int)] = [:]
        for uid in keptIds {
            guard let entry = grouped[uid] else { continue }
            let info = resolveAncestry(uid)
            let resolvedInfo = anchorInfo.ancestryById[uid] ?? info
            ancestryById[uid] = resolvedInfo
            familyMembers[resolvedInfo.rootKey, default: []].append((uid, resolvedInfo.depth, entry.firstSampleIndex))
        }

        let sortedRoots = familyMembers.keys.sorted { a, b in
            let aMin = familyMembers[a]?.map(\.firstSampleIndex).min() ?? Int.max
            let bMin = familyMembers[b]?.map(\.firstSampleIndex).min() ?? Int.max
            if aMin != bMin { return aMin < bMin }
            return a < b
        }
        var familyIndexByRoot = anchorInfo.familyByRoot
        var tierByAgentId = anchorInfo.tierByAgentId
        let familyCount = max(1, LiveTelemetryColorPalette.families.count)
        var usedSlots = Set(familyIndexByRoot.values)

        for rootKey in sortedRoots {
            if familyIndexByRoot[rootKey] == nil {
                let fallbackSlot = (0..<familyCount).first(where: { !usedSlots.contains($0) })
                    ?? (familyIndexByRoot.count % familyCount)
                familyIndexByRoot[rootKey] = fallbackSlot
                usedSlots.insert(fallbackSlot)
            }
            let sortedMembers = (familyMembers[rootKey] ?? []).sorted { a, b in
                if a.depth != b.depth { return a.depth < b.depth }
                if a.firstSampleIndex != b.firstSampleIndex { return a.firstSampleIndex < b.firstSampleIndex }
                return a.agentId < b.agentId
            }
            var nextChildTier = max(
                1,
                (sortedMembers.compactMap { tierByAgentId[$0.agentId] }.max() ?? 0) + 1
            )
            for member in sortedMembers where tierByAgentId[member.agentId] == nil {
                if member.depth == 0 {
                    tierByAgentId[member.agentId] = 0
                } else {
                    tierByAgentId[member.agentId] = nextChildTier
                    nextChildTier += 1
                }
            }
        }

        var descendantsCache: [String: Set<String>] = [:]
        func descendants(of parentId: String) -> Set<String> {
            if let cached = descendantsCache[parentId] {
                return cached
            }
            var visited = Set<String>()
            var queue = Array(directChildrenByParent[parentId] ?? [])
            while let cur = queue.popLast() {
                if visited.insert(cur).inserted {
                    queue.append(contentsOf: directChildrenByParent[cur] ?? [])
                }
            }
            descendantsCache[parentId] = visited
            return visited
        }

        func hasDescendantActivity(of agentId: String, between startExclusive: Int, and endExclusive: Int) -> Bool {
            guard startExclusive + 1 < endExclusive else { return false }
            let desc = descendants(of: agentId)
            guard !desc.isEmpty else { return false }
            for sIdx in (startExclusive + 1)..<endExclusive {
                if sampleAgentMap[sIdx].keys.contains(where: { desc.contains($0) }) {
                    return true
                }
            }
            return false
        }

        let latestSampleIndex = samples.count - 1
        let built: [AgentContextSeries] = keptIds.compactMap { agentId in
            guard let entry = grouped[agentId],
                  let firstIndexed = entry.indexedPoints.first,
                  let latestIndexed = entry.indexedPoints.last else { return nil }
            let latest = latestIndexed.point
            var runs: [[AgentSeriesSamplePoint]] = [[firstIndexed.point]]
            var prevSampleIdx = firstIndexed.sampleIdx
            for item in entry.indexedPoints.dropFirst() {
                if item.sampleIdx - prevSampleIdx > 1,
                   hasDescendantActivity(of: agentId, between: prevSampleIdx, and: item.sampleIdx) {
                    runs.append([item.point])
                } else {
                    runs[runs.count - 1].append(item.point)
                }
                prevSampleIdx = item.sampleIdx
            }

            if entry.parentAgentId == nil,
               entry.lastSampleIndex < latestSampleIndex,
               !hasDescendantActivity(of: agentId, between: entry.lastSampleIndex, and: samples.count),
               !runs.isEmpty {
                let tailPoint = AgentSeriesSamplePoint(
                    timestamp: samples[latestSampleIndex].timestamp,
                    contextTokens: latest.contextTokens,
                    isRunning: false,
                    tps: 0.0,
                    isForkAnchor: false,
                    customId: "idle-tail"
                )
                runs[runs.count - 1].append(tailPoint)
            }

            var didAttachFork = false

            if let pid = entry.parentAgentId,
               keptIds.contains(pid),
               entry.firstSampleIndex > 0,
               !runs.isEmpty {
                let lookbackStart = max(0, entry.firstSampleIndex - 2)
                var anchorPair: (timestamp: Date, point: AgentContextPoint)? = nil
                for idx in stride(from: entry.firstSampleIndex - 1, through: lookbackStart, by: -1) {
                    if let parentPt = sampleAgentMap[idx][pid] {
                        anchorPair = (samples[idx].timestamp, parentPt)
                        break
                    }
                }
                if let anchorInfo = anchorPair,
                   anchorInfo.timestamp < runs[0][0].timestamp {
                    let anchor = AgentSeriesSamplePoint(
                        timestamp: anchorInfo.timestamp,
                        contextTokens: anchorInfo.point.contextTokens,
                        isRunning: false,
                        tps: 0.0,
                        isForkAnchor: true
                    )
                    runs[0].insert(anchor, at: 0)
                    didAttachFork = true
                }
            }

            let segments: [AgentCurveSegment] = runs.enumerated().map { idx, segPoints in
                AgentCurveSegment(
                    id: "\(agentId)#\(idx)",
                    isForkSegment: didAttachFork && idx == 0,
                    points: segPoints
                )
            }

            let isLiveRunning = (entry.lastSampleIndex == latestSampleIndex) && latest.isRunning
            let hash = agentId.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }
            let rootKey = ancestryById[agentId]?.rootKey ?? agentId
            return AgentContextSeries(
                agentId: agentId,
                label: entry.label,
                isRunning: isLiveRunning,
                latestContextTokens: latest.contextTokens,
                latestTps: isLiveRunning ? latest.tps : 0.0,
                colorIndex: abs(hash),
                familyIndex: familyIndexByRoot[rootKey] ?? 0,
                familyTier: tierByAgentId[agentId] ?? 0,
                parentAgentId: entry.parentAgentId,
                segments: segments
            )
        }

        func sortKey(_ a: AgentContextSeries, _ b: AgentContextSeries) -> Bool {
            if a.isRunning != b.isRunning { return a.isRunning }
            if a.latestContextTokens != b.latestContextTokens { return a.latestContextTokens > b.latestContextTokens }
            return a.agentId < b.agentId
        }

        let builtIds = Set(built.map(\.agentId))
        let roots = built.filter { $0.parentAgentId == nil || !builtIds.contains($0.parentAgentId!) }.sorted(by: sortKey)
        var ordered: [AgentContextSeries] = []
        var appended = Set<String>()

        func appendTree(_ node: AgentContextSeries) {
            guard !appended.contains(node.agentId) else { return }
            appended.insert(node.agentId)
            ordered.append(node)
            let children = built.filter { $0.parentAgentId == node.agentId }.sorted(by: sortKey)
            for child in children {
                appendTree(child)
            }
        }

        for root in roots {
            appendTree(root)
        }
        return Array(ordered.prefix(maxSeries))
    }

    static func sessionColorLinks(
        sessions: [SessionItem],
        seriesList: [AgentContextSeries]
    ) -> [String: SessionTelemetryColorLink] {
        guard !sessions.isEmpty, !seriesList.isEmpty else { return [:] }
        let seriesById = Dictionary(uniqueKeysWithValues: seriesList.map { ($0.agentId, $0) })

        func collectIds(of item: SessionItem, into set: inout Set<String>) {
            set.insert(item.uuid)
            for sub in item.subagents {
                collectIds(of: sub, into: &set)
            }
        }

        func belongsToFamily(_ series: AgentContextSeries, memberIds: Set<String>) -> Bool {
            if memberIds.contains(series.agentId) { return true }
            var cur = series.parentAgentId
            var visited = Set<String>([series.agentId])
            while let pid = cur, !pid.isEmpty {
                if memberIds.contains(pid) { return true }
                guard !visited.contains(pid) else { break }
                visited.insert(pid)
                cur = seriesById[pid]?.parentAgentId
            }
            return false
        }

        var result: [String: SessionTelemetryColorLink] = [:]
        for session in sessions {
            var memberIds = Set<String>()
            collectIds(of: session, into: &memberIds)

            let directSeries = seriesList.first(where: { $0.agentId == session.uuid })
            let matching = seriesList.filter { belongsToFamily($0, memberIds: memberIds) }
            guard !matching.isEmpty else { continue }

            let childSeries = matching.filter { $0.agentId != session.uuid }
            let childTones = childSeries.map {
                LiveTelemetryColorPalette.tone(familyIndex: $0.familyIndex, tier: $0.familyTier)
            }
            let primarySource = directSeries ?? childSeries[0]
            let primaryTone = LiveTelemetryColorPalette.tone(
                familyIndex: primarySource.familyIndex,
                tier: primarySource.familyTier
            )
            result[session.uuid] = SessionTelemetryColorLink(
                primaryTone: primaryTone,
                childTones: childTones,
                seriesIds: Set(matching.map(\.agentId)),
                hasDirectSeries: directSeries != nil
            )
        }
        return result
    }

    static func smoothedCurvePoints(
        _ points: [AgentSeriesSamplePoint],
        windowSeconds: TimeInterval
    ) -> [AgentSeriesSamplePoint] {
        guard points.count > 1 else { return points }

        var clean: [AgentSeriesSamplePoint] = []
        clean.reserveCapacity(points.count)
        for pt in points {
            if let last = clean.last, pt.timestamp <= last.timestamp {
                clean[clean.count - 1] = pt
            } else {
                clean.append(pt)
            }
        }
        guard clean.count > 1 else { return clean }

        if clean.count == 2 {
            let p0 = clean[0]
            let p1 = clean[1]
            let dt = p1.timestamp.timeIntervalSince(p0.timestamp)
            guard dt > 0 else { return clean }
            let y0 = Double(p0.contextTokens)
            let y1 = Double(p1.contextTokens)
            let steps = 14
            return (0...steps).map { s in
                if s == 0 {
                    return AgentSeriesSamplePoint(
                        timestamp: p0.timestamp,
                        contextTokens: p0.contextTokens,
                        isRunning: p0.isRunning,
                        tps: p0.tps,
                        isForkAnchor: p0.isForkAnchor,
                        customId: "s-\(s)"
                    )
                }
                if s == steps {
                    return AgentSeriesSamplePoint(
                        timestamp: p1.timestamp,
                        contextTokens: p1.contextTokens,
                        isRunning: p1.isRunning,
                        tps: p1.tps,
                        isForkAnchor: false,
                        customId: "s-\(s)"
                    )
                }
                let u = Double(s) / Double(steps)
                let ease = (3.0 * u * u) - (2.0 * u * u * u)
                let y = y0 + (y1 - y0) * ease
                return AgentSeriesSamplePoint(
                    timestamp: p0.timestamp.addingTimeInterval(dt * u),
                    contextTokens: Int(y.rounded()),
                    isRunning: p0.isRunning,
                    tps: p0.tps,
                    isForkAnchor: false,
                    customId: "s-\(s)"
                )
            }
        }

        let ys = clean.map { Double($0.contextTokens) }
        let minY = ys.min() ?? 0.0
        let maxY = ys.max() ?? 0.0
        let ySpan = max(1.0, maxY - minY)
        let steepThreshold = max(20_000.0, ySpan * 0.16)
        let rampDuration = max(4.0, windowSeconds * 0.065)

        struct BridgeNode {
            let timestamp: Date
            let y: Double
            let isRunning: Bool
            let tps: Double
        }

        var bridged: [BridgeNode] = [
            BridgeNode(
                timestamp: clean[0].timestamp,
                y: Double(clean[0].contextTokens),
                isRunning: clean[0].isRunning,
                tps: clean[0].tps
            )
        ]

        var i = 0
        while i < clean.count - 1 {
            let curr = bridged[bridged.count - 1]
            let nextIdx = i + 1
            let next = clean[nextIdx]
            let dy = Double(next.contextTokens) - curr.y
            let dt = next.timestamp.timeIntervalSince(curr.timestamp)

            if abs(dy) >= steepThreshold && dt < rampDuration && nextIdx < clean.count - 1 {
                let targetTime = curr.timestamp.addingTimeInterval(rampDuration)
                let plateauRef = Double(next.contextTokens)
                let plateauTol = max(14_000.0, abs(dy) * 0.15)
                var furthestIdx = nextIdx
                var beyondIdx: Int? = nil

                var k = nextIdx + 1
                while k < clean.count {
                    let pt = clean[k]
                    if abs(Double(pt.contextTokens) - plateauRef) <= plateauTol {
                        if pt.timestamp <= targetTime {
                            furthestIdx = k
                            k += 1
                            continue
                        } else {
                            beyondIdx = k
                            break
                        }
                    } else {
                        break
                    }
                }

                var endTime = clean[furthestIdx].timestamp
                var endY = Double(clean[furthestIdx].contextTokens)
                let endRunning = clean[furthestIdx].isRunning
                let endTps = clean[furthestIdx].tps

                if let bIdx = beyondIdx, bIdx == furthestIdx + 1 {
                    let prevPt = clean[furthestIdx]
                    let beyondPt = clean[bIdx]
                    let span = beyondPt.timestamp.timeIntervalSince(prevPt.timestamp)
                    if span > 0 && targetTime > prevPt.timestamp && targetTime < clean[clean.count - 1].timestamp {
                        let frac = targetTime.timeIntervalSince(prevPt.timestamp) / span
                        endTime = targetTime
                        endY = Double(prevPt.contextTokens) + (Double(beyondPt.contextTokens) - Double(prevPt.contextTokens)) * frac
                    }
                }

                let easeSpan = endTime.timeIntervalSince(curr.timestamp)
                if easeSpan > 0 {
                    let easeSteps = 6
                    for s in 1...easeSteps {
                        let u = Double(s) / Double(easeSteps)
                        let ease = (3.0 * u * u) - (2.0 * u * u * u)
                        bridged.append(
                            BridgeNode(
                                timestamp: curr.timestamp.addingTimeInterval(easeSpan * u),
                                y: curr.y + (endY - curr.y) * ease,
                                isRunning: s == easeSteps ? endRunning : curr.isRunning,
                                tps: s == easeSteps ? endTps : curr.tps
                            )
                        )
                    }
                }
                i = furthestIdx
            } else {
                bridged.append(
                    BridgeNode(
                        timestamp: next.timestamp,
                        y: Double(next.contextTokens),
                        isRunning: next.isRunning,
                        tps: next.tps
                    )
                )
                i = nextIdx
            }
        }

        let tStart = bridged[0].timestamp
        let tEnd = bridged[bridged.count - 1].timestamp
        let totalSpan = tEnd.timeIntervalSince(tStart)
        guard totalSpan > 0.05 else { return clean }

        let sampleCount = min(110, max(36, Int((totalSpan / 1.5).rounded()) + 1))
        var times = Array(repeating: 0.0, count: sampleCount)
        var uniformY = Array(repeating: 0.0, count: sampleCount)
        var uniformRunning = Array(repeating: true, count: sampleCount)
        var uniformTps = Array(repeating: 0.0, count: sampleCount)

        var bCursor = 0
        for idx in 0..<sampleCount {
            let frac = Double(idx) / Double(sampleCount - 1)
            let relT = totalSpan * frac
            times[idx] = relT
            let absTime = tStart.addingTimeInterval(relT)

            while bCursor + 1 < bridged.count - 1 && bridged[bCursor + 1].timestamp <= absTime {
                bCursor += 1
            }
            let left = bridged[bCursor]
            let right = bridged[min(bCursor + 1, bridged.count - 1)]
            let segDt = right.timestamp.timeIntervalSince(left.timestamp)
            if segDt > 0 {
                let u = min(1.0, max(0.0, absTime.timeIntervalSince(left.timestamp) / segDt))
                uniformY[idx] = left.y + (right.y - left.y) * u
                uniformRunning[idx] = u >= 0.5 ? right.isRunning : left.isRunning
                uniformTps[idx] = u >= 0.5 ? right.tps : left.tps
            } else {
                uniformY[idx] = left.y
                uniformRunning[idx] = left.isRunning
                uniformTps[idx] = left.tps
            }
        }

        let baseSigma = min(max(2.5, windowSeconds * 0.036), totalSpan * 0.18)
        let taperBand = max(1.0, baseSigma * 1.15)
        var smoothedY = Array(repeating: 0.0, count: sampleCount)
        smoothedY[0] = Double(clean[0].contextTokens)
        smoothedY[sampleCount - 1] = Double(clean[clean.count - 1].contextTokens)

        for idx in 1..<(sampleCount - 1) {
            let t = times[idx]
            let distEdge = min(t, totalSpan - t)
            let taper = min(1.0, distEdge / taperBand)
            let sigma = max(0.05, baseSigma * taper)
            let cutoff = sigma * 3.0
            let invTwoSigmaSq = 1.0 / (2.0 * sigma * sigma)

            var weightedSum = 0.0
            var weightTotal = 0.0
            for j in 0..<sampleCount {
                let dt = times[j] - t
                if abs(dt) > cutoff { continue }
                let w = exp(-(dt * dt) * invTwoSigmaSq)
                weightedSum += uniformY[j] * w
                weightTotal += w
            }
            let avg = weightTotal > 0 ? (weightedSum / weightTotal) : uniformY[idx]
            smoothedY[idx] = min(maxY, max(minY, avg))
        }

        var result: [AgentSeriesSamplePoint] = []
        result.reserveCapacity(sampleCount)
        for idx in 0..<sampleCount {
            let isFirst = (idx == 0)
            let isLast = (idx == sampleCount - 1)
            let ts = isFirst ? clean[0].timestamp : (isLast ? clean[clean.count - 1].timestamp : tStart.addingTimeInterval(times[idx]))
            let tokens = isFirst ? clean[0].contextTokens : (isLast ? clean[clean.count - 1].contextTokens : Int(smoothedY[idx].rounded()))
            result.append(
                AgentSeriesSamplePoint(
                    timestamp: ts,
                    contextTokens: tokens,
                    isRunning: isFirst ? clean[0].isRunning : (isLast ? clean[clean.count - 1].isRunning : uniformRunning[idx]),
                    tps: isFirst ? clean[0].tps : (isLast ? clean[clean.count - 1].tps : uniformTps[idx]),
                    isForkAnchor: isFirst ? clean[0].isForkAnchor : false,
                    customId: "s-\(idx)"
                )
            )
        }

        return result
    }

    static func interpolatedContext(in points: [AgentSeriesSamplePoint], at timestamp: Date) -> Double {
        guard let first = points.first else { return 0.0 }
        if timestamp <= first.timestamp {
            return Double(first.contextTokens)
        }
        guard let last = points.last else { return Double(first.contextTokens) }
        if timestamp >= last.timestamp {
            return Double(last.contextTokens)
        }
        for idx in 1..<points.count {
            let p0 = points[idx - 1]
            let p1 = points[idx]
            if timestamp <= p1.timestamp {
                let dt = p1.timestamp.timeIntervalSince(p0.timestamp)
                guard dt > 0 else { return Double(p1.contextTokens) }
                let u = min(1.0, max(0.0, timestamp.timeIntervalSince(p0.timestamp) / dt))
                return Double(p0.contextTokens) + (Double(p1.contextTokens) - Double(p0.contextTokens)) * u
            }
        }
        return Double(last.contextTokens)
    }

    private static func buildStrokeRuns(
        segmentId: String,
        rawPoints: [AgentSeriesSamplePoint],
        smoothedPoints: [AgentSeriesSamplePoint],
        windowSeconds: TimeInterval
    ) -> [AgentCurveStrokeRun] {
        guard smoothedPoints.count >= 2 else {
            return smoothedPoints.isEmpty ? [] : [
                AgentCurveStrokeRun(
                    id: "\(segmentId)#run0",
                    isIdle: !(smoothedPoints.first?.isRunning ?? true),
                    points: smoothedPoints
                )
            ]
        }

        let microPauseTolerance = min(20.0, max(8.0, windowSeconds * 0.045))
        var idleIntervals: [(start: Date, end: Date)] = []
        if rawPoints.count >= 2 {
            for idx in 0..<(rawPoints.count - 1) {
                let p0 = rawPoints[idx]
                let p1 = rawPoints[idx + 1]
                let dt = p1.timestamp.timeIntervalSince(p0.timestamp)
                let explicitIdleSpan = (!p0.isRunning && !p1.isRunning && !p0.isForkAnchor) || p1.customId == "idle-tail"
                if dt > microPauseTolerance || explicitIdleSpan {
                    idleIntervals.append((start: p0.timestamp, end: p1.timestamp))
                }
            }
        }

        if idleIntervals.isEmpty {
            return [
                AgentCurveStrokeRun(
                    id: "\(segmentId)#run0",
                    isIdle: false,
                    points: smoothedPoints
                )
            ]
        }

        var runs: [AgentCurveStrokeRun] = []
        var currentPoints: [AgentSeriesSamplePoint] = [smoothedPoints[0]]
        var currentIsIdle: Bool? = nil

        for idx in 0..<(smoothedPoints.count - 1) {
            let a = smoothedPoints[idx]
            let b = smoothedPoints[idx + 1]
            let dt = b.timestamp.timeIntervalSince(a.timestamp)
            let mid = a.timestamp.addingTimeInterval(max(0.0, dt * 0.5))
            let edgeIsIdle = idleIntervals.contains { mid >= $0.start && mid <= $0.end }

            if let activeFlag = currentIsIdle {
                if activeFlag == edgeIsIdle {
                    currentPoints.append(b)
                } else {
                    if currentPoints.count >= 2 {
                        runs.append(
                            AgentCurveStrokeRun(
                                id: "\(segmentId)#run\(runs.count)",
                                isIdle: activeFlag,
                                points: currentPoints
                            )
                        )
                    }
                    currentPoints = [a, b]
                    currentIsIdle = edgeIsIdle
                }
            } else {
                currentIsIdle = edgeIsIdle
                currentPoints.append(b)
            }
        }

        if currentPoints.count >= 2, let activeFlag = currentIsIdle {
            runs.append(
                AgentCurveStrokeRun(
                    id: "\(segmentId)#run\(runs.count)",
                    isIdle: activeFlag,
                    points: currentPoints
                )
            )
        }

        return runs.isEmpty
            ? [AgentCurveStrokeRun(id: "\(segmentId)#run0", isIdle: false, points: smoothedPoints)]
            : runs
    }

    static func resolvedCurveSegments(
        for seriesList: [AgentContextSeries],
        windowSeconds: TimeInterval
    ) -> [ResolvedAgentCurveSeries] {
        guard !seriesList.isEmpty else { return [] }
        let seriesById = Dictionary(uniqueKeysWithValues: seriesList.map { ($0.agentId, $0) })
        var resolvedById: [String: ResolvedAgentCurveSeries] = [:]
        var resolving = Set<String>()

        func resolveSeries(_ series: AgentContextSeries) -> ResolvedAgentCurveSeries {
            if let cached = resolvedById[series.agentId] {
                return cached
            }
            if resolving.contains(series.agentId) {
                let fallback = series.segments.map { seg -> ResolvedAgentCurveSegment in
                    let smoothed = smoothedCurvePoints(seg.points, windowSeconds: windowSeconds)
                    return ResolvedAgentCurveSegment(
                        id: seg.id,
                        points: smoothed,
                        forkJunction: nil,
                        strokeRuns: buildStrokeRuns(
                            segmentId: seg.id,
                            rawPoints: seg.points,
                            smoothedPoints: smoothed,
                            windowSeconds: windowSeconds
                        )
                    )
                }
                return ResolvedAgentCurveSeries(agentId: series.agentId, parentAgentId: series.parentAgentId, segments: fallback)
            }

            resolving.insert(series.agentId)
            let parentResolved: ResolvedAgentCurveSeries? = {
                guard let pid = series.parentAgentId, let pSeries = seriesById[pid] else { return nil }
                return resolveSeries(pSeries)
            }()

            let resolvedSegments: [ResolvedAgentCurveSegment] = series.segments.map { seg in
                guard seg.isForkSegment,
                      let rawAnchor = seg.points.first,
                      rawAnchor.isForkAnchor,
                      let pSegs = parentResolved?.segments.filter({ !$0.points.isEmpty }),
                      !pSegs.isEmpty else {
                    let smoothed = smoothedCurvePoints(seg.points, windowSeconds: windowSeconds)
                    return ResolvedAgentCurveSegment(
                        id: seg.id,
                        points: smoothed,
                        forkJunction: nil,
                        strokeRuns: buildStrokeRuns(
                            segmentId: seg.id,
                            rawPoints: seg.points,
                            smoothedPoints: smoothed,
                            windowSeconds: windowSeconds
                        )
                    )
                }

                let childRaw = Array(seg.points.dropFirst())
                let childSmoothed = smoothedCurvePoints(childRaw, windowSeconds: windowSeconds)
                let parentSeg: ResolvedAgentCurveSegment = {
                    if let containing = pSegs.first(where: {
                        rawAnchor.timestamp >= $0.points.first!.timestamp && rawAnchor.timestamp <= $0.points.last!.timestamp
                    }) {
                        return containing
                    }
                    if let prior = pSegs.filter({ $0.points.last!.timestamp <= rawAnchor.timestamp })
                        .max(by: { $0.points.last!.timestamp < $1.points.last!.timestamp }) {
                        return prior
                    }
                    return pSegs.min(by: { a, b in
                        let da = abs(a.points.last!.timestamp.timeIntervalSince(rawAnchor.timestamp))
                        let db = abs(b.points.last!.timestamp.timeIntervalSince(rawAnchor.timestamp))
                        return da < db
                    })!
                }()

                let pPts = parentSeg.points
                let pStart = pPts.first!.timestamp
                let pEnd = pPts.last!.timestamp
                var forkTime = min(max(rawAnchor.timestamp, pStart), pEnd)

                if let childFirstTime = childSmoothed.first?.timestamp, childFirstTime <= forkTime {
                    let availableBack = max(0.0, childFirstTime.timeIntervalSince(pStart))
                    let lead = min(max(2.0, windowSeconds * 0.02), availableBack)
                    let stepped = childFirstTime.addingTimeInterval(-lead)
                    if stepped >= pStart && stepped <= pEnd {
                        forkTime = stepped
                    }
                }

                let exactY = Int(interpolatedContext(in: pPts, at: forkTime).rounded())
                let junction = AgentSeriesSamplePoint(
                    timestamp: forkTime,
                    contextTokens: exactY,
                    isRunning: false,
                    tps: 0.0,
                    isForkAnchor: true,
                    customId: "fork-\(seg.id)"
                )

                var finalPoints: [AgentSeriesSamplePoint] = [junction]
                if let childStart = childSmoothed.first {
                    let dt = childStart.timestamp.timeIntervalSince(forkTime)
                    if dt > 0.05 {
                        let y0 = Double(exactY)
                        let y1 = Double(childStart.contextTokens)
                        let steps = 12
                        for s in 1..<steps {
                            let u = Double(s) / Double(steps)
                            let ease = (3.0 * u * u) - (2.0 * u * u * u)
                            finalPoints.append(
                                AgentSeriesSamplePoint(
                                    timestamp: forkTime.addingTimeInterval(dt * u),
                                    contextTokens: Int((y0 + (y1 - y0) * ease).rounded()),
                                    isRunning: false,
                                    tps: 0.0,
                                    isForkAnchor: false,
                                    customId: "bridge-\(seg.id)-\(s)"
                                )
                            )
                        }
                    }
                    for (cIdx, pt) in childSmoothed.enumerated() {
                        finalPoints.append(
                            AgentSeriesSamplePoint(
                                timestamp: pt.timestamp,
                                contextTokens: pt.contextTokens,
                                isRunning: pt.isRunning,
                                tps: pt.tps,
                                isForkAnchor: false,
                                customId: "child-\(seg.id)-\(cIdx)"
                            )
                        )
                    }
                }

                return ResolvedAgentCurveSegment(
                    id: seg.id,
                    points: finalPoints,
                    forkJunction: junction,
                    strokeRuns: buildStrokeRuns(
                        segmentId: seg.id,
                        rawPoints: childRaw,
                        smoothedPoints: finalPoints,
                        windowSeconds: windowSeconds
                    )
                )
            }

            resolving.remove(series.agentId)
            let built = ResolvedAgentCurveSeries(
                agentId: series.agentId,
                parentAgentId: series.parentAgentId,
                segments: resolvedSegments
            )
            resolvedById[series.agentId] = built
            return built
        }

        return seriesList.map { resolveSeries($0) }
    }

    static func nearestAgentId(
        in resolvedSeries: [ResolvedAgentCurveSeries],
        seriesList: [AgentContextSeries],
        timeDomain: ClosedRange<Date>,
        maxContext: Int,
        plotSize: CGSize,
        hoverLocation: CGPoint,
        hitRadiusPixels: CGFloat = 28.0
    ) -> String? {
        let totalTime = timeDomain.upperBound.timeIntervalSince(timeDomain.lowerBound)
        guard totalTime > 0,
              maxContext > 0,
              plotSize.width > 0,
              plotSize.height > 0 else {
            return nil
        }

        let maxCtxD = Double(maxContext)
        let runningById = Dictionary(uniqueKeysWithValues: seriesList.map { ($0.agentId, $0.isRunning) })

        func pixelPoint(for pt: AgentSeriesSamplePoint) -> CGPoint {
            let nx = pt.timestamp.timeIntervalSince(timeDomain.lowerBound) / totalTime
            let ny = Double(pt.contextTokens) / maxCtxD
            let px = CGFloat(nx) * plotSize.width
            let py = (1.0 - CGFloat(ny)) * plotSize.height
            return CGPoint(x: px, y: py)
        }

        func distanceSqToSegment(_ p: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
            let dx = b.x - a.x
            let dy = b.y - a.y
            let lenSq = dx * dx + dy * dy
            if lenSq <= 0.0001 {
                let ux = p.x - a.x
                let uy = p.y - a.y
                return ux * ux + uy * uy
            }
            let t = min(1.0, max(0.0, ((p.x - a.x) * dx + (p.y - a.y) * dy) / lenSq))
            let projX = a.x + t * dx
            let projY = a.y + t * dy
            let rx = p.x - projX
            let ry = p.y - projY
            return rx * rx + ry * ry
        }

        var bestCandidate: (agentId: String, dist: CGFloat, isRunning: Bool)? = nil

        for series in resolvedSeries {
            var minDistSq = CGFloat.greatestFiniteMagnitude
            for seg in series.segments where !seg.points.isEmpty {
                if seg.points.count == 1 {
                    let a = pixelPoint(for: seg.points[0])
                    let dSq = distanceSqToSegment(hoverLocation, a, a)
                    if dSq < minDistSq { minDistSq = dSq }
                } else {
                    for idx in 1..<seg.points.count {
                        let a = pixelPoint(for: seg.points[idx - 1])
                        let b = pixelPoint(for: seg.points[idx])
                        let dSq = distanceSqToSegment(hoverLocation, a, b)
                        if dSq < minDistSq { minDistSq = dSq }
                    }
                }
            }
            guard minDistSq.isFinite else { continue }
            let dist = sqrt(minDistSq)
            guard dist <= hitRadiusPixels else { continue }
            let running = runningById[series.agentId] ?? false

            if let cur = bestCandidate {
                let nearTie = abs(dist - cur.dist) <= 2.0
                if (nearTie && running && !cur.isRunning) || (!nearTie && dist < cur.dist) {
                    bestCandidate = (series.agentId, dist, running)
                }
            } else {
                bestCandidate = (series.agentId, dist, running)
            }
        }

        return bestCandidate?.agentId
    }

    static func matchingSessionId(
        forAgentId agentId: String?,
        links: [String: SessionTelemetryColorLink]
    ) -> String? {
        guard let agentId, !agentId.isEmpty else { return nil }
        return links.first(where: { $0.value.seriesIds.contains(agentId) })?.key
    }

    static func maxContextDomain(for series: [AgentContextSeries]) -> Int {
        let peak = series.flatMap(\.points).map(\.contextTokens).max() ?? 0
        if peak <= 0 {
            return 180_000
        }
        let padded = Double(peak) * 1.18
        let step = 60_000.0
        return max(120_000, Int(ceil(padded / step) * step))
    }

    static func xAxisTicks(
        for range: TelemetryTimeRange,
        referenceDate: Date = Date(),
        anchorDate: Date? = nil,
        count: Int = 4
    ) -> [Date] {
        let safeCount = max(2, count)
        let domain = xAxisDomain(for: range, referenceDate: referenceDate, anchorDate: anchorDate)
        let start = domain.lowerBound
        let step = range.seconds / Double(safeCount - 1)
        return (0..<safeCount).map { idx in
            start.addingTimeInterval(Double(idx) * step)
        }
    }

    static func yAxisTicks(maxContext: Int) -> [Double] {
        let safeMax = max(60_000, maxContext)
        let third = Double(safeMax) / 3.0
        return [0.0, third.rounded(), (third * 2.0).rounded(), Double(safeMax)]
    }

    static func appendSample(
        to history: [LiveTelemetrySample],
        payload: MonitorPayload,
        previousStats: TodayStats?,
        nextId: inout Int,
        now: Date = Date()
    ) -> ([LiveTelemetrySample], TodayStats?, Bool) {
        let metrics = extractLiveMetrics(from: payload)
        let stats = payload.todayStats

        if let last = history.last,
           now.timeIntervalSince(last.timestamp) < minimumSampleSpacingSeconds,
           last.activeAgentCount == metrics.activeAgentCount,
           Int(last.totalTps.rounded()) == Int(metrics.totalTps.rounded()),
           last.totalTokensCumulative == stats.totalTokens {
            return (history, previousStats ?? (stats.hasData ? stats : nil), false)
        }

        let prevActiveIds = Set((history.last?.agentContexts ?? []).filter(\.isRunning).map(\.agentId))
        let agentContexts = extractAgentSnapshots(from: payload, previouslyActiveIds: prevActiveIds)

        let resolvedCachePct: Double
        let deltaTokens: Int
        let deltaCacheTokens: Int
        let deltaNewTokens: Int
        let isIdleHold: Bool

        if let prev = previousStats, stats.hasData {
            deltaCacheTokens = max(0, stats.cacheTokens - prev.cacheTokens)
            deltaNewTokens = max(0, (stats.inputTokens + stats.outputTokens) - (prev.inputTokens + prev.outputTokens))
            deltaTokens = max(0, stats.totalTokens - prev.totalTokens)
            let denom = deltaCacheTokens + deltaNewTokens
            if denom > 0 {
                resolvedCachePct = min(100.0, max(0.0, Double(deltaCacheTokens) / Double(denom) * 100.0))
                isIdleHold = false
            } else {
                resolvedCachePct = history.last?.cachePct ?? (stats.hasData ? min(100.0, max(0.0, stats.cachePct)) : 0.0)
                isIdleHold = true
            }
        } else {
            deltaTokens = 0
            deltaCacheTokens = 0
            deltaNewTokens = 0
            isIdleHold = false
            let runningWithCache = payload.sessions.filter { $0.isRunning && $0.cachePct > 0 }
            if !runningWithCache.isEmpty {
                let avg = runningWithCache.reduce(0.0) { $0 + $1.cachePct } / Double(runningWithCache.count)
                resolvedCachePct = min(100.0, max(0.0, avg))
            } else if stats.hasData {
                resolvedCachePct = min(100.0, max(0.0, stats.cachePct))
            } else {
                resolvedCachePct = 0.0
            }
        }

        let sample = LiveTelemetrySample(
            id: nextId,
            timestamp: now,
            activeAgentCount: metrics.activeAgentCount,
            totalTps: metrics.totalTps,
            totalTokensCumulative: stats.totalTokens,
            deltaTokens: deltaTokens,
            cachePct: resolvedCachePct,
            isIdleCacheHold: isIdleHold,
            deltaCacheTokens: deltaCacheTokens,
            deltaNewTokens: deltaNewTokens,
            agentContexts: agentContexts
        )
        nextId += 1

        var updated = history
        updated.append(sample)
        let cutoff = now.addingTimeInterval(-TelemetryTimeRange.oneHour.seconds)
        if let firstValidIdx = updated.firstIndex(where: { $0.timestamp >= cutoff }), firstValidIdx > 0 {
            updated.removeFirst(firstValidIdx)
        }
        if updated.count > maxSamples {
            updated.removeFirst(updated.count - maxSamples)
        }
        let nextPrevStats: TodayStats? = stats.hasData ? stats : previousStats
        return (updated, nextPrevStats, true)
    }

    static func samples(
        in range: TelemetryTimeRange,
        from history: [LiveTelemetrySample],
        now: Date = Date()
    ) -> [LiveTelemetrySample] {
        let cutoff = now.addingTimeInterval(-range.seconds)
        return history.filter { $0.timestamp >= cutoff }
    }

    static func visibleChartSamples(
        in range: TelemetryTimeRange,
        from history: [LiveTelemetrySample],
        anchorDate: Date? = nil,
        now: Date = Date()
    ) -> [LiveTelemetrySample] {
        let domain = xAxisDomain(for: range, referenceDate: now, anchorDate: anchorDate)
        return history.filter { $0.timestamp >= domain.lowerBound }
    }

    static func xAxisDomain(
        for range: TelemetryTimeRange,
        referenceDate: Date = Date(),
        anchorDate: Date? = nil
    ) -> ClosedRange<Date> {
        let leadIn = range.seconds * 0.25
        let stride = range.seconds * 0.75
        let anchor = anchorDate ?? referenceDate
        let elapsed = max(0.0, referenceDate.timeIntervalSince(anchor))
        let cycleIndex = floor((elapsed + 1e-6) / stride)
        let cycleNow = anchor.addingTimeInterval(cycleIndex * stride)
        let lower = cycleNow.addingTimeInterval(-leadIn)
        return lower...lower.addingTimeInterval(range.seconds)
    }

    static func chartDomains(for samples: [LiveTelemetrySample]) -> ChartDomains {
        let peakTps = samples.map(\.totalTps).max() ?? 0.0
        let maxTps = max(50.0, ceil((peakTps * 1.15) / 10.0) * 10.0)
        let maxAgents = max(1, samples.map(\.activeAgentCount).max() ?? 1)

        if samples.isEmpty || samples.allSatisfy({ $0.cachePct <= 0.0 }) {
            return ChartDomains(maxTps: maxTps, maxAgents: maxAgents, cacheMinY: 0.0)
        }
        let minCache = samples.map(\.cachePct).min() ?? 90.0
        let buffered = max(0.0, floor(minCache - 3.0))
        let cacheMinY = min(buffered, 92.0)
        return ChartDomains(maxTps: maxTps, maxAgents: maxAgents, cacheMinY: cacheMinY)
    }

    static func windowDeltaTokens(for samples: [LiveTelemetrySample]) -> Int {
        let deltaSum = samples.reduce(0) { $0 + $1.deltaTokens }
        if deltaSum > 0 {
            return deltaSum
        }
        guard samples.count >= 2, let first = samples.first, let last = samples.last else {
            return 0
        }
        return max(0, last.totalTokensCumulative - first.totalTokensCumulative)
    }

    static func windowSummary(
        in range: TelemetryTimeRange,
        from history: [LiveTelemetrySample],
        todayStats: TodayStats,
        now: Date = Date()
    ) -> TelemetryWindowSummary {
        let inWindow = samples(in: range, from: history, now: now)
        let total = windowDeltaTokens(for: inWindow)
        let sumCache = inWindow.reduce(0) { $0 + $1.deltaCacheTokens }
        let sumNew = inWindow.reduce(0) { $0 + $1.deltaNewTokens }
        let denom = sumCache + sumNew
        if denom > 0 {
            let pct = min(100.0, max(0.0, Double(sumCache) / Double(denom) * 100.0))
            return TelemetryWindowSummary(totalTokens: total, cachePct: pct, hasWindowTraffic: true)
        }
        let fallbackCache = inWindow.last?.cachePct ?? (todayStats.hasData ? todayStats.cachePct : 0.0)
        return TelemetryWindowSummary(totalTokens: total, cachePct: fallbackCache, hasWindowTraffic: false)
    }
}

enum SessionListLayoutPolicy {
    static let maxVisibleRowsWhenExpanded = 3
    static let defaultVisibleRowsWhenExpanded = 3
    static let minVisibleRowsWhenExpanded = 1
    static let maxConfigurableVisibleRowsWhenExpanded = 12
    static let visibleRowsDefaultsKey = "agyhub.sessions.visibleRowsWhenExpanded"
    static let headerHeight: CGFloat = 22.0
    static let headerToListSpacing: CGFloat = 6.0
    static let rowEstimatedHeight: CGFloat = 30.0
    static let rowSpacing: CGFloat = 2.5

    static func clampedVisibleRows(_ raw: Int) -> Int {
        min(max(raw, minVisibleRowsWhenExpanded), maxConfigurableVisibleRowsWhenExpanded)
    }

    static func loadVisibleRows(from userDefaults: UserDefaults = .standard) -> Int {
        guard userDefaults.object(forKey: visibleRowsDefaultsKey) != nil else {
            return defaultVisibleRowsWhenExpanded
        }
        return clampedVisibleRows(userDefaults.integer(forKey: visibleRowsDefaultsKey))
    }

    static func scrollHeight(
        forCount count: Int,
        visibleLimit: Int = maxVisibleRowsWhenExpanded,
        chartExpanded: Bool
    ) -> CGFloat? {
        guard chartExpanded else { return nil }
        guard count > 0 else { return nil }
        let visible = min(count, clampedVisibleRows(visibleLimit))
        return CGFloat(visible) * rowEstimatedHeight + CGFloat(max(0, visible - 1)) * rowSpacing
    }
}

struct DashboardSplitAllocation: Equatable {
    let telemetryHeight: CGFloat
    let dividerHeight: CGFloat
    let sessionsHeight: CGFloat
    let telemetryFraction: CGFloat
}

enum DashboardSplitLayoutPolicy {
    static let embedsDragHandleInSessionsHeader = true
    static let splitFractionDefaultsKey = "agyhub.layout.telemetrySplitFraction"
    static let dividerHeight: CGFloat = 6.0
    static let minTelemetryHeight: CGFloat = 180.0
    static let minSessionsHeight: CGFloat = 62.0
    static let defaultMinPlotHeight: CGFloat = 118.0
    static let splitMinPlotHeight: CGFloat = 72.0
    static let sessionsHeaderAndGapHeight: CGFloat = SessionListLayoutPolicy.headerHeight + SessionListLayoutPolicy.headerToListSpacing

    static func clampedTelemetryHeight(
        proposed: CGFloat,
        totalAvailableHeight: CGFloat
    ) -> CGFloat {
        let usable = max(0, totalAvailableHeight - dividerHeight)
        guard usable > 0 else { return 0 }
        let minTop = min(minTelemetryHeight, usable * 0.55)
        let minBottom = min(minSessionsHeight, max(0, usable - minTop))
        let maxTop = max(minTop, usable - minBottom)
        return min(max(proposed, minTop), maxTop)
    }

    static func resolveAllocation(
        totalAvailableHeight: CGFloat,
        storedFraction: CGFloat,
        displaySessionsCount: Int,
        expandedSessionRowLimit: Int
    ) -> DashboardSplitAllocation {
        let usable = max(0, totalAvailableHeight - dividerHeight)
        guard usable > 0 else {
            return DashboardSplitAllocation(
                telemetryHeight: 0,
                dividerHeight: dividerHeight,
                sessionsHeight: 0,
                telemetryFraction: 0.5
            )
        }
        let proposedTop: CGFloat
        if storedFraction > 0 && storedFraction < 1 {
            proposedTop = usable * storedFraction
        } else {
            let desiredRowsHeight = SessionListLayoutPolicy.scrollHeight(
                forCount: max(1, displaySessionsCount),
                visibleLimit: expandedSessionRowLimit,
                chartExpanded: true
            ) ?? 42.0
            let desiredSessions = sessionsHeaderAndGapHeight + desiredRowsHeight
            proposedTop = usable - desiredSessions
        }
        let telemetryH = clampedTelemetryHeight(proposed: proposedTop, totalAvailableHeight: totalAvailableHeight)
        let sessionsH = max(0, usable - telemetryH)
        return DashboardSplitAllocation(
            telemetryHeight: telemetryH,
            dividerHeight: dividerHeight,
            sessionsHeight: sessionsH,
            telemetryFraction: telemetryH / usable
        )
    }

    static func updatedFractionAfterDrag(
        startTelemetryHeight: CGFloat,
        dragDeltaY: CGFloat,
        totalAvailableHeight: CGFloat
    ) -> CGFloat {
        let usable = max(1, totalAvailableHeight - dividerHeight)
        let newTop = clampedTelemetryHeight(
            proposed: startTelemetryHeight + dragDeltaY,
            totalAvailableHeight: totalAvailableHeight
        )
        return newTop / usable
    }
}

struct DashboardAdaptiveLayoutMetrics: Equatable {
    let isCompact: Bool
    let outerHorizontalPadding: CGFloat
    let footerHorizontalPadding: CGFloat
    let telemetryCardHorizontalPadding: CGFloat
    let telemetryPlotHorizontalPadding: CGFloat
    let accountCardHorizontalPadding: CGFloat
    let sessionRowHorizontalPadding: CGFloat
    let sectionHeaderHorizontalPadding: CGFloat

    var totalChartEdgeInset: CGFloat {
        outerHorizontalPadding + telemetryCardHorizontalPadding + telemetryPlotHorizontalPadding
    }

    static let compactThresholdWidth: CGFloat = 455

    static func metrics(forWidth width: CGFloat) -> DashboardAdaptiveLayoutMetrics {
        let effectiveWidth = width > 0 ? width : 464
        let compact = effectiveWidth < compactThresholdWidth
        if compact {
            return DashboardAdaptiveLayoutMetrics(
                isCompact: true,
                outerHorizontalPadding: 8,
                footerHorizontalPadding: 8,
                telemetryCardHorizontalPadding: 6,
                telemetryPlotHorizontalPadding: 4,
                accountCardHorizontalPadding: 5,
                sessionRowHorizontalPadding: 4,
                sectionHeaderHorizontalPadding: 0
            )
        }
        return DashboardAdaptiveLayoutMetrics(
            isCompact: false,
            outerHorizontalPadding: 12,
            footerHorizontalPadding: 12,
            telemetryCardHorizontalPadding: 9,
            telemetryPlotHorizontalPadding: 6,
            accountCardHorizontalPadding: 6,
            sessionRowHorizontalPadding: 7,
            sectionHeaderHorizontalPadding: 2
        )
    }
}
