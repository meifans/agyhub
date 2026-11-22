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
