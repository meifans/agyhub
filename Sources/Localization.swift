import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable, Codable, Equatable {
    case system = "system"
    case zhHans = "zh-Hans"
    case en = "en"

    enum Resolved: String, Equatable, Codable {
        case zhHans = "zh-Hans"
        case en = "en"

        var backendCode: String {
            self == .en ? "en" : "zh"
        }
    }

    static let userDefaultsKey = "agyhub.appLanguage"

    var id: String { rawValue }

    static func resolveSystemLanguage(preferredLanguages: [String] = Locale.preferredLanguages) -> Resolved {
        guard let first = preferredLanguages.first?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !first.isEmpty else {
            return .en
        }
        return first.hasPrefix("zh") ? .zhHans : .en
    }

    func resolved(preferredLanguages: [String] = Locale.preferredLanguages) -> Resolved {
        switch self {
        case .system:
            return Self.resolveSystemLanguage(preferredLanguages: preferredLanguages)
        case .zhHans:
            return .zhHans
        case .en:
            return .en
        }
    }

    static func load(from defaults: UserDefaults = .standard) -> AppLanguage {
        guard let raw = defaults.string(forKey: userDefaultsKey),
              let lang = AppLanguage(rawValue: raw) else {
            return .system
        }
        return lang
    }

    func save(to defaults: UserDefaults = .standard) {
        defaults.set(rawValue, forKey: Self.userDefaultsKey)
    }

    func pickerLabel(for uiLanguage: Resolved) -> String {
        switch self {
        case .system:
            return uiLanguage == .zhHans ? "自动" : "Auto"
        case .zhHans:
            return "中文"
        case .en:
            return "EN"
        }
    }
}

private struct AGYLanguageEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppLanguage.Resolved = .zhHans
}

extension EnvironmentValues {
    var agyLanguage: AppLanguage.Resolved {
        get { self[AGYLanguageEnvironmentKey.self] }
        set { self[AGYLanguageEnvironmentKey.self] = newValue }
    }
}

enum L10nKey: String, CaseIterable {

    case headerTodayLabel
    case refreshDataTooltip
    case openStandaloneTooltip
    case closeWindow
    case settingsTitle
    case closeSettingsTooltip

    case accountsSectionTitle
    case notSignedIn
    case switchDesktopAppTooltip
    case switchCLIAccountTooltip
    case viewLogsTooltip
    case newProfileTooltip
    case authorizeCLIAutoSwitchTitle
    case authorizeCLIAutoSwitchDesc
    case authorizeOnceButton
    case cliTokenMissingOrCorrupt
    case cliTokenIsolatedHint
    case cliTokenHelpTooltip
    case copyEnvButton
    case activeAppBadge
    case switchAction
    case switchAppHelp
    case parallelLaunchAction
    case parallelLaunchHelp
    case removeProfileHelp
    case activeCLIBadge
    case terminalLoginAction
    case switchCLIAction
    case loginCLIAction
    case cliUnauthorizedHelp
    case cliCachedSlotHelp
    case cliFirstLoginHelp

    case quotaExpiredBadge
    case quotaExpiredHint
    case quotaResetNow

    case todaySectionTitle
    case estimatedCost
    case sessionsSectionTitle
    case noActiveSessions
    case cliSessionTooltip
    case runningStatus
    case contextEmptyTooltip
    case subagentsSectionTitle
    case backButton
    case refreshDiagnosticsTooltip
    case copiedButton
    case copySummaryButton
    case copySummaryTooltip
    case statEstCost
    case statTotalTokens
    case statContext
    case statCacheHit

    case diagTabPhases
    case diagTabSources
    case diagLoading
    case diagEmpty
    case diagCacheMissTitle
    case diagCacheHealthy
    case diagTagPlatform
    case diagTagNormal
    case diagTagOptimizable
    case diagCollapseEvents
    case diagDistributionTitle
    case diagCenterTurns
    case diagCenterAttributed
    case diagRecommendationsTitle

    case usageRangeToday
    case usageRange7Days
    case usageRange30Days
    case usageHeaderToday
    case usageHeader7Days
    case usageHeader30Days
    case usageMetricCost
    case usageMetricTokens
    case usageDimModel
    case usageDimSession
    case usageEmptyRecord
    case usageLoadingHistory
    case usageNoModelData

    case createProfileTitle
    case createProfileSubtitle
    case createProfileAccountLabel
    case createProfileAccountPlaceholder
    case createProfileNotesLabel
    case createProfileNotesPlaceholder
    case cancelAction
    case createAction
    case logsSheetTitle
    case copyLogsAction
    case closeAction
    case logsEmpty

    case languageSettingLabel
    case launchAtLoginToggle
    case unifyMonitoringToggle
    case showSessionModelToggle
    case cliIndependentToggle
    case cliIndependentDesc
    case refreshIntervalLabel
    case secondsPlaceholder
    case secondsUnit
    case permissionsSectionTitle
    case cliIsolatedSwitchingTitle
    case cliNativeSharedHint
    case cliAuthorizedVaultHint
    case cliUnauthorizedManualHint
    case revokeAuthButton
    case revokeAuthTooltip
    case enableAuthButton
    case enableAuthTooltip
    case currentTag
    case clearSlotTooltip
    case readOnlyScopeLine
    case closeWindowKeepsRunning
    case quitAgyhubButton
    case quitAgyhubTooltip

    case menuAboutAgyhub
    case menuHideAgyhub
    case menuHideOthers
    case menuShowAll
    case menuQuitAgyhub
    case menuEdit
    case menuCut
    case menuCopy
    case menuPaste
    case menuSelectAll
    case menuWindow
    case menuMinimize
    case menuZoom
    case statusMenuShowDashboard
    case statusMenuOpenStandalone
    case statusMenuRefreshNow
    case statusMenuSettings

    case bannerCopiedLogs
    case bannerCLIModeShared
    case bannerCLIModeIndependent
    case bannerCLIAuthEnabled
    case bannerCLIAuthRevoked
    case bannerNeedAuthForRestore
    case bannerDefaultProfileProtected
    case bannerLaunchAtLoginOn
    case bannerLaunchAtLoginOff
    case bannerLaunchAgentWritten
    case bannerLaunchAgentRemoved

    func text(for lang: AppLanguage.Resolved) -> String {
        let pair = localizedPair
        return lang == .zhHans ? pair.0 : pair.1
    }

    private var localizedPair: (String, String) {
        switch self {

        case .headerTodayLabel: return ("Today", "Today")
        case .refreshDataTooltip: return ("刷新数据", "Refresh Data")
        case .openStandaloneTooltip: return ("在新窗口中固定打开", "Open in Standalone Window")
        case .closeWindow: return ("关闭窗口", "Close Window")
        case .settingsTitle: return ("设置", "Settings")
        case .closeSettingsTooltip: return ("关闭设置", "Close Settings")

        case .accountsSectionTitle: return ("ACCOUNTS", "ACCOUNTS")
        case .notSignedIn: return ("未登录", "Not Signed In")
        case .switchDesktopAppTooltip: return ("切换桌面 App 主应用账号", "Switch Desktop App Account")
        case .switchCLIAccountTooltip: return ("独立切换 Antigravity CLI (agy) 账号", "Switch Antigravity CLI (agy) Account")
        case .viewLogsTooltip: return ("查看账号探测与切换日志", "View Account Discovery & Switch Logs")
        case .newProfileTooltip: return ("新建隔离账号环境", "New Isolated Profile")
        case .authorizeCLIAutoSwitchTitle: return ("启用 CLI 免重登自动切换", "Enable One-Click CLI Switching")
        case .authorizeCLIAutoSwitchDesc: return ("CLI 改用独立 token 文件（SSH_CLIENT=1），与 App 钥匙串互不覆盖；授权后按邮箱本地缓存（零联网）", "CLI uses an isolated token file (SSH_CLIENT=1) separate from App keychain; cached locally by email (offline)")
        case .authorizeOnceButton: return ("授权一次", "Authorize")
        case .cliTokenMissingOrCorrupt: return ("CLI 独立 token 文件缺失或已损坏，请点击下方账号切换或重登", "CLI token file is missing or corrupted — switch or re-login below")
        case .cliTokenIsolatedHint: return ("CLI 独立 token 文件，与 App 账号互不影响；CLI / 编辑器需配置环境变量 SSH_CLIENT=1", "Isolated CLI token file won't affect App; set SSH_CLIENT=1 in your CLI / editor env")
        case .cliTokenHelpTooltip: return ("agy 带 SSH_CLIENT=1 运行时读写 ~/.gemini/antigravity-cli/antigravity-oauth-token，不访问系统钥匙串", "With SSH_CLIENT=1, agy reads/writes ~/.gemini/antigravity-cli/antigravity-oauth-token instead of macOS Keychain")
        case .copyEnvButton: return ("复制变量", "Copy Env")
        case .activeAppBadge: return ("当前 App", "Active App")
        case .switchAction: return ("切换", "Switch")
        case .switchAppHelp: return ("安全切换主应用至此账号环境", "Safely switch Desktop App to this account")
        case .parallelLaunchAction: return ("双开", "Parallel")
        case .parallelLaunchHelp: return ("并排双开新桌面实例", "Launch parallel desktop instance")
        case .removeProfileHelp: return ("移除此环境", "Remove profile")
        case .activeCLIBadge: return ("当前 CLI", "Active CLI")
        case .terminalLoginAction: return ("终端登录", "Terminal Login")
        case .switchCLIAction: return ("切换 CLI", "Switch CLI")
        case .loginCLIAction: return ("登录 CLI", "Login CLI")
        case .cliUnauthorizedHelp: return ("尚未授权自动切换；将在终端打开 agy 由您登录", "Auto-switch not authorized; opens agy in Terminal for manual login")
        case .cliCachedSlotHelp: return ("从本地已授权槽位自动切换此 CLI 账号", "Switch CLI to this cached account from local vault")
        case .cliFirstLoginHelp: return ("首次切换：退出旧槽位并在终端启动 agy 完成一次登录后即可自动互切", "First switch: opens agy in Terminal to sign in once, then enables auto-switching")

        case .quotaExpiredBadge: return ("已过期", "Expired")
        case .quotaExpiredHint: return ("凭证已过期，切换后自动更新", "Token expired — switch to refresh")
        case .quotaResetNow: return ("重置", "Reset")

        case .todaySectionTitle: return ("TODAY", "TODAY")
        case .estimatedCost: return ("预估账单", "Est. Cost")
        case .sessionsSectionTitle: return ("SESSIONS", "SESSIONS")
        case .noActiveSessions: return ("暂无活跃会话记录", "No active sessions")
        case .cliSessionTooltip: return ("Antigravity CLI 会话", "Antigravity CLI Session")
        case .runningStatus: return ("运行中", "Running")
        case .contextEmptyTooltip: return ("当前上下文: 暂无", "Context: N/A")
        case .subagentsSectionTitle: return ("SUBAGENTS", "SUBAGENTS")
        case .backButton: return ("返回", "Back")
        case .refreshDiagnosticsTooltip: return ("重新分析当前会话上下文与缓存消耗（零 Token）", "Re-analyze session context & cache misses (0 tokens)")
        case .copiedButton: return ("已复制", "Copied")
        case .copySummaryButton: return ("复制摘要", "Copy Summary")
        case .copySummaryTooltip: return ("复制纯文本诊断摘要到剪贴板，方便贴给 AI 进一步排查", "Copy plain-text diagnostic summary to clipboard")
        case .statEstCost: return ("预估账单", "Est. Cost")
        case .statTotalTokens: return ("总 Token", "Total Tokens")
        case .statContext: return ("上下文", "Context")
        case .statCacheHit: return ("缓存率", "Cache Hit")

        case .diagTabPhases: return ("按工作阶段", "By Phase")
        case .diagTabSources: return ("按上下文来源", "By Source")
        case .diagLoading: return ("正在本地解析上下文与缓存失效原因（零 Token 消耗）…", "Analyzing context & cache misses locally (0 tokens)…")
        case .diagEmpty: return ("暂无可用的本地 transcript 诊断数据（点击右上角刷新重试）", "No local transcript diagnostics available (click refresh to retry)")
        case .diagCacheMissTitle: return ("缓存失效诊断", "Cache Miss Diagnostics")
        case .diagCacheHealthy: return ("高缓存命中，无显著失效", "High cache hit rate — no misses")
        case .diagTagPlatform: return ("平台", "Platform")
        case .diagTagNormal: return ("正常", "Normal")
        case .diagTagOptimizable: return ("可优化", "Optimizable")
        case .diagCollapseEvents: return ("收起部分明细", "Show Fewer")
        case .diagDistributionTitle: return ("Token 与上下文分布", "Token & Context Breakdown")
        case .diagCenterTurns: return ("总轮次", "Turns")
        case .diagCenterAttributed: return ("已归因", "Attributed")
        case .diagRecommendationsTitle: return ("针对性优化建议", "Recommendations")

        case .usageRangeToday: return ("今天", "Today")
        case .usageRange7Days: return ("最近 7 天", "Last 7 Days")
        case .usageRange30Days: return ("最近一个月", "Last 30 Days")
        case .usageHeaderToday: return ("今日分时消耗", "Today Hourly")
        case .usageHeader7Days: return ("近 7 天趋势", "7-Day Trend")
        case .usageHeader30Days: return ("近 30 天趋势", "30-Day Trend")
        case .usageMetricCost: return ("$ 费用", "$ Cost")
        case .usageMetricTokens: return ("Tokens", "Tokens")
        case .usageDimModel: return ("按模型统计", "By Model")
        case .usageDimSession: return ("按对话统计", "By Session")
        case .usageEmptyRecord: return ("所选时间段内暂无本地消耗记录", "No local usage recorded in this period")
        case .usageLoadingHistory: return ("正在扫描本地历史消耗统计...", "Scanning local usage history...")
        case .usageNoModelData: return ("无记录", "No data")

        case .createProfileTitle: return ("新建环境", "New Profile")
        case .createProfileSubtitle: return ("自动创建隔离目录并共享插件以节省空间。", "Creates an isolated directory and shares extensions to save disk space.")
        case .createProfileAccountLabel: return ("账号邮箱或标识", "Account Email or Identifier")
        case .createProfileAccountPlaceholder: return ("如: work@example.com", "e.g. work@example.com")
        case .createProfileNotesLabel: return ("备注 (可选)", "Notes (Optional)")
        case .createProfileNotesPlaceholder: return ("如: 备用测试", "e.g. Backup / Testing")
        case .cancelAction: return ("取消", "Cancel")
        case .createAction: return ("创建", "Create")
        case .logsSheetTitle: return ("账号探测与切换日志", "Account Discovery & Switch Logs")
        case .copyLogsAction: return ("复制日志", "Copy Logs")
        case .closeAction: return ("关闭", "Close")
        case .logsEmpty: return ("暂无日志记录", "No log entries yet")

        case .languageSettingLabel: return ("界面语言", "Language")
        case .launchAtLoginToggle: return ("开机自动启动", "Launch at Login")
        case .unifyMonitoringToggle: return ("统一监控活跃会话", "Monitor All Active Sessions")
        case .showSessionModelToggle: return ("列表展示会话模型", "Show Model in Session List")
        case .cliIndependentToggle: return ("CLI 与桌面 App 账号独立", "Isolate CLI & Desktop App Accounts")
        case .cliIndependentDesc: return ("开启后 CLI 读写独立 token 文件，两端互不干扰；关闭后共用钥匙串，切号同步生效", "When enabled, CLI uses a separate token file without overwriting App keychain")
        case .refreshIntervalLabel: return ("刷新间隔:", "Refresh Interval:")
        case .secondsPlaceholder: return ("秒数", "sec")
        case .secondsUnit: return ("秒", "sec")
        case .permissionsSectionTitle: return ("已授权内容", "Permissions & Scope")
        case .cliIsolatedSwitchingTitle: return ("CLI 账号独立切换", "Isolated CLI Switching")
        case .cliNativeSharedHint: return ("当前处于原生共享模式（已关闭独立文件切号）", "Using native shared keychain mode")
        case .cliAuthorizedVaultHint: return ("改写 CLI token 文件，App 钥匙串不动 · 零联网", "Updates CLI token file only · App keychain untouched · Offline")
        case .cliUnauthorizedManualHint: return ("未授权（仅终端手动登录）", "Not authorized (manual Terminal login only)")
        case .revokeAuthButton: return ("取消授权", "Revoke")
        case .revokeAuthTooltip: return ("立即撤回授权并清空全部 CLI 钥匙串缓存槽位", "Revoke authorization and clear all cached CLI slots")
        case .enableAuthButton: return ("授权启用", "Authorize")
        case .enableAuthTooltip: return ("授权 Agyhub 本机安全切换 CLI 槽位", "Authorize Agyhub to switch local CLI slots")
        case .currentTag: return ("当前", "Active")
        case .clearSlotTooltip: return ("清除此账号的 CLI 缓存槽位", "Remove cached CLI slot for this account")
        case .readOnlyScopeLine: return ("• 会话与浏览器只读: ~/.gemini/ · Chrome/IDE 状态", "• Read-Only Scope: ~/.gemini/ · Chrome/IDE state")
        case .closeWindowKeepsRunning: return ("关闭窗口不退出常驻", "Closing window keeps Agyhub running")
        case .quitAgyhubButton: return ("退出 Agyhub", "Quit Agyhub")
        case .quitAgyhubTooltip: return ("彻底退出常驻菜单栏的 Agyhub 进程", "Quit Agyhub completely")

        case .menuAboutAgyhub: return ("关于 Agyhub", "About Agyhub")
        case .menuHideAgyhub: return ("隐藏 Agyhub", "Hide Agyhub")
        case .menuHideOthers: return ("隐藏其他", "Hide Others")
        case .menuShowAll: return ("全部显示", "Show All")
        case .menuQuitAgyhub: return ("退出 Agyhub", "Quit Agyhub")
        case .menuEdit: return ("编辑", "Edit")
        case .menuCut: return ("剪切", "Cut")
        case .menuCopy: return ("复制", "Copy")
        case .menuPaste: return ("粘贴", "Paste")
        case .menuSelectAll: return ("全选", "Select All")
        case .menuWindow: return ("窗口", "Window")
        case .menuMinimize: return ("最小化", "Minimize")
        case .menuZoom: return ("缩放", "Zoom")
        case .statusMenuShowDashboard: return ("打开主面板", "Open Dashboard")
        case .statusMenuOpenStandalone: return ("在新窗口中打开", "Open Standalone Window")
        case .statusMenuRefreshNow: return ("立即刷新", "Refresh Now")
        case .statusMenuSettings: return ("设置...", "Settings...")

        case .bannerCopiedLogs: return ("📋 已复制日志到剪贴板", "📋 Logs copied to clipboard")
        case .bannerCLIModeShared: return ("ℹ️ 已切换为原生共享模式：CLI 与桌面 App 共用钥匙串", "ℹ️ Shared keychain mode enabled: CLI & App share credentials")
        case .bannerCLIModeIndependent: return ("⚡️ 已开启 CLI 独立模式：CLI 读写独立 token 文件", "⚡️ Isolated CLI mode enabled: CLI uses separate token file")
        case .bannerCLIAuthEnabled: return ("✅ 已授权 CLI 免重登自动切换（可在设置中随时取消）", "✅ CLI auto-switching authorized (can be revoked in Settings)")
        case .bannerCLIAuthRevoked: return ("🗑️ 已取消授权并清空全部 CLI 缓存槽位", "🗑️ Authorization revoked and cached CLI slots cleared")
        case .bannerNeedAuthForRestore: return ("⚠️ 尚未授权保险箱，无法自动恢复；请在 App 内重新登录", "⚠️ Vault not authorized — please sign in again inside the App")
        case .bannerDefaultProfileProtected: return ("⚠️ 默认主应用环境不可移除", "⚠️ Default primary profile cannot be removed")
        case .bannerLaunchAtLoginOn: return ("✅ 已开启开机自启", "✅ Launch at Login enabled")
        case .bannerLaunchAtLoginOff: return ("⏸️ 已关闭开机自启", "⏸️ Launch at Login disabled")
        case .bannerLaunchAgentWritten: return ("✅ 已写入 LaunchAgents 开机自启配置", "✅ LaunchAgents login item configured")
        case .bannerLaunchAgentRemoved: return ("⏸️ 已移除开机自启配置", "⏸️ LaunchAgents login item removed")
        }
    }
}

enum L10n {
    static func t(_ key: L10nKey, _ lang: AppLanguage.Resolved) -> String {
        key.text(for: lang)
    }

    static func quotaExpiredHint(for lang: AppLanguage.Resolved) -> String {
        t(.quotaExpiredHint, lang)
    }

    static func quotaExpiredBadge(for lang: AppLanguage.Resolved) -> String {
        t(.quotaExpiredBadge, lang)
    }

    static func updatedAt(_ timeStr: String, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans ? "更新于 \(timeStr)" : "Updated \(timeStr)"
    }

    static func activeCount(_ count: Int, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans ? "\(count) 活跃" : "\(count) Active"
    }

    static func maxWait(_ stallText: String, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans ? "最长等待 \(stallText)" : "Max Wait \(stallText)"
    }

    static func maxWaitTooltip(_ seconds: Double, _ lang: AppLanguage.Resolved) -> String {
        let formatted = String(format: "%.1f", seconds)
        return lang == .zhHans
            ? "当前所有活跃会话中的单次最长等待/卡顿耗时：\(formatted) 秒"
            : "Longest single stall across active sessions: \(formatted)s"
    }

    static func recent503Tooltip(_ count: Int, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans
            ? "最近 1 小时内本地会话遇到的云端 503 次数：\(count) 次（每 5 分钟自动统计，点右上角刷新可立即重算）"
            : "Cloud 503 errors across local sessions in the past hour: \(count) (refreshed every 5 min)"
    }

    static func sessionsCount(_ count: Int, _ lang: AppLanguage.Resolved) -> String {
        if lang == .zhHans { return "\(count) 个会话" }
        return count == 1 ? "1 session" : "\(count) sessions"
    }

    static func todayPillTooltip(cost: Double, totalTokens: Int, cachePct: Double, _ lang: AppLanguage.Resolved) -> String {
        let costStr = Formatters.formatCost(cost)
        let tokStr = Formatters.formatTokens(totalTokens)
        let pct = Int(cachePct)
        return lang == .zhHans
            ? "点击查看今日/近 7 天/近 30 天用量大图与按模型统计；今日预估 \(costStr) · \(tokStr) Tokens（缓存 \(pct)%）"
            : "Click for Today / 7D / 30D usage charts & breakdown; Today est. \(costStr) · \(tokStr) Tokens (Cache \(pct)%)"
    }

    static func todayOverviewCacheLine(cachePct: Double, newTokens: Int, _ lang: AppLanguage.Resolved) -> String {
        let tokStr = Formatters.formatTokens(newTokens)
        return lang == .zhHans
            ? String(format: "缓存 %.0f%% · 新增 %@", cachePct, tokStr)
            : String(format: "Cache %.0f%% · New %@", cachePct, tokStr)
    }

    static func collapseToggleHelp(title: String, isCollapsed: Bool, _ lang: AppLanguage.Resolved) -> String {
        if lang == .zhHans {
            return isCollapsed ? "展开 \(title)" : "折叠 \(title)"
        }
        return isCollapsed ? "Expand \(title)" : "Collapse \(title)"
    }

    static func keychainDriftHint(isRefreshHijack: Bool, actualShort: String, _ lang: AppLanguage.Resolved) -> String {
        if lang == .zhHans {
            return isRefreshHijack
                ? "已被后台旧 CLI 自动续期覆盖为 \(actualShort)"
                : "已偏移，当前共享钥匙串为 \(actualShort)"
        }
        return isRefreshHijack
            ? "overwritten by legacy CLI refresh to \(actualShort)"
            : "drifted; shared keychain is now \(actualShort)"
    }

    static func primaryAppDriftLine(appShort: String, hint: String, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans ? "原主应用 \(appShort) \(hint)" : "App \(appShort) \(hint)"
    }

    static func backgroundCLIWarning(_ count: Int, _ lang: AppLanguage.Resolved) -> String {
        if lang == .zhHans {
            return "检测到 \(count) 个后台 agy 进程运行中，其每小时续期会回写钥匙串"
        }
        return "\(count) background agy process(es) running; hourly refresh may overwrite keychain"
    }

    static func switchBackTo(_ appShort: String, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans ? "切回 \(appShort)" : "Restore \(appShort)"
    }

    static func restoreKeychainTooltip(_ expectedEmail: String, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans ? "将共享钥匙串恢复为 \(expectedEmail)" : "Restore shared keychain to \(expectedEmail)"
    }

    static func cliTokenRunningWarning(_ count: Int, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans
            ? "CLI 独立 token 文件 · \(count) 个 agy 运行中，切换后重开会话生效"
            : "Isolated CLI token · \(count) agy running; reopen session after switch"
    }

    static func copyEnvHelp(_ envStr: String, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans ? "复制 \(envStr)" : "Copy \(envStr)"
    }

    static func copiedEnvBanner(_ envStr: String, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans
            ? "📋 已复制 \(envStr)，粘贴到 CLI 或编辑器的环境变量配置中"
            : "📋 Copied \(envStr) — add it to your CLI or editor environment variables"
    }

    static func cachedCLIAccountsTitle(_ count: Int, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans ? "已缓存 CLI 账号 (\(count))" : "Cached CLI Accounts (\(count))"
    }

    static func isolatedProfilesLine(_ count: Int, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans
            ? "• 桌面隔离目录: ~/.agy-profiles/ (\(count) 个)"
            : "• Isolated Profiles: ~/.agy-profiles/ (\(count))"
    }

    static func modelHelp(_ model: String, _ lang: AppLanguage.Resolved) -> String {
        let display = model.isEmpty ? "-" : model
        return lang == .zhHans ? "模型: \(display)" : "Model: \(display)"
    }

    static func interactionsCount(_ count: Int, _ lang: AppLanguage.Resolved) -> String {
        if lang == .zhHans { return "\(count) 轮交互" }
        return count == 1 ? "1 turn" : "\(count) turns"
    }

    static func mainAndSubagentsTooltip(
        subCount: Int,
        mainCost: Double,
        mainTokens: Int,
        subCost: Double,
        subTokens: Int,
        _ lang: AppLanguage.Resolved
    ) -> String {
        let mc = Formatters.formatCost(mainCost)
        let mt = Formatters.formatTokens(mainTokens)
        let sc = Formatters.formatCost(subCost)
        let st = Formatters.formatTokens(subTokens)
        return lang == .zhHans
            ? "含主会话 + \(subCount) 个子 Agent 合计（主会话 \(mc) / \(mt)，子 Agent \(sc) / \(st)）"
            : "Includes main + \(subCount) subagent(s) (Main \(mc) / \(mt), Subagents \(sc) / \(st))"
    }

    static func subagentFallbackBadge(_ count: Int, _ lang: AppLanguage.Resolved) -> String {
        if lang == .zhHans { return "\(count) Agent" }
        return count == 1 ? "1 Agent" : "\(count) Agents"
    }

    static func diagSubagentCount(_ count: Int, _ lang: AppLanguage.Resolved) -> String {
        if lang == .zhHans { return "含 \(count) 个子 Agent" }
        return count == 1 ? "+1 Subagent" : "+\(count) Subagents"
    }

    static func cacheMissSummary(_ totalMisses: Int, _ extraCost: Double, _ wastePct: Double, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans
            ? String(format: "%d 次 · 多花 +$%.2f (占 %.1f%%)", totalMisses, extraCost, wastePct)
            : String(format: "%d misses · +$%.2f (%.1f%%)", totalMisses, extraCost, wastePct)
    }

    static func cacheMissCountShare(_ count: Int, _ share: Double, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans
            ? String(format: "%d次 · %.0f%%", count, share)
            : String(format: "%dx · %.0f%%", count, share)
    }

    static func diagExpandTopEvents(_ count: Int, _ lang: AppLanguage.Resolved) -> String {
        let topN = min(5, count)
        return lang == .zhHans ? "展开全部 Top \(topN) 断点" : "Show Top \(topN) Events"
    }

    static func usageSummaryCacheCalls(cachePct: Double, calls: Int, _ lang: AppLanguage.Resolved) -> String {
        let pct = Int(cachePct.rounded())
        return lang == .zhHans ? "缓存 \(pct)% · \(calls) 次" : "Cache \(pct)% · \(calls) calls"
    }

    static func usageSummaryInOut(inputTokens: Int, outputTokens: Int, _ lang: AppLanguage.Resolved) -> String {
        let iStr = Formatters.formatTokens(inputTokens)
        let oStr = Formatters.formatTokens(outputTokens)
        return lang == .zhHans ? "输入 \(iStr) · 输出 \(oStr)" : "In \(iStr) · Out \(oStr)"
    }

    static func usageBarHoverSummary(cost: Double, tokens: Int, calls: Int, _ lang: AppLanguage.Resolved) -> String {
        let cStr = Formatters.formatCost(cost)
        let tStr = Formatters.formatTokens(tokens)
        return lang == .zhHans ? "\(cStr) · \(tStr) Tokens · \(calls) 次" : "\(cStr) · \(tStr) Tokens · \(calls) calls"
    }

    static func usageChartPrompt(isToday: Bool, _ lang: AppLanguage.Resolved) -> String {
        if lang == .zhHans {
            return "消耗分布趋势（悬停查看逐\(isToday ? "小时" : "日")明细）"
        }
        return "Usage Trend (hover for \(isToday ? "hourly" : "daily") details)"
    }

    static func usageBreakdownHeader(metric: UsageMetricMode, dimension: UsageBreakdownDimension, count: Int, _ lang: AppLanguage.Resolved) -> String {
        if lang == .zhHans {
            let mLabel = metric == .cost ? "费用" : "Tokens"
            let unitLabel = dimension == .model ? "个模型" : "个对话"
            return "\(mLabel) 降序 · \(count) \(unitLabel)"
        }
        let mLabel = metric == .cost ? "Cost" : "Tokens"
        let unitLabel = dimension == .model ? (count == 1 ? "model" : "models") : (count == 1 ? "session" : "sessions")
        return "By \(mLabel) · \(count) \(unitLabel)"
    }

    static func usageModelMetricSummary(tokens: Int, calls: Int, cachePct: Double, _ lang: AppLanguage.Resolved) -> String {
        let tokStr = Formatters.formatTokens(tokens)
        let pct = Int(cachePct.rounded())
        return lang == .zhHans
            ? "\(tokStr) · \(calls)次 · 缓存\(pct)%"
            : "\(tokStr) · \(calls) calls · Cache \(pct)%"
    }

    static func usageConversationMetricSummary(topModel: String, tokens: Int, calls: Int, cachePct: Double, _ lang: AppLanguage.Resolved) -> String {
        let tokStr = Formatters.formatTokens(tokens)
        let pct = Int(cachePct.rounded())
        return lang == .zhHans
            ? "\(topModel) · \(tokStr) · \(calls)次 · 缓存\(pct)%"
            : "\(topModel) · \(tokStr) · \(calls) calls · Cache \(pct)%"
    }

    static func usageConversationSubagentBadge(_ count: Int, _ lang: AppLanguage.Resolved) -> String {
        if lang == .zhHans { return "\(count)子Agent" }
        return count == 1 ? "1 subagent" : "\(count) subagents"
    }

    static func usageTodayHourTitle(_ label: String, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans ? "今日 \(label)" : "Today \(label)"
    }

    static func bannerRemovedCLISlot(_ email: String, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans ? "🗑️ 已清除 CLI 槽位：\(email)" : "🗑️ Cleared CLI slot: \(email)"
    }

    static func bannerSwitchingCLI(_ targetEmail: String, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans ? "🔄 正在切换 CLI 至「\(targetEmail)」..." : "🔄 Switching CLI to \"\(targetEmail)\"..."
    }

    static func bannerCLILoginNoAuth(_ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans
            ? "💻 尚未授权自动切换；已在终端以文件模式打开 agy 登录，完成后自动覆盖"
            : "💻 Auto-switch not authorized; opened agy login in Terminal"
    }

    static func bannerCLISwitched(_ targetEmail: String, bgCount: Int, _ lang: AppLanguage.Resolved) -> String {
        if lang == .zhHans {
            let warn = bgCount > 0 ? "（有 \(bgCount) 个 agy 进程运行中，重开 CLI / 终端会话后生效）" : "（App 账号不受影响）"
            return "⚡️ CLI 已切换至「\(targetEmail)」\(warn)"
        }
        let warn = bgCount > 0 ? " (\(bgCount) agy running — reopen session to take effect)" : " (App account untouched)"
        return "⚡️ CLI switched to \"\(targetEmail)\"\(warn)"
    }

    static func bannerCLILoginMissingSlot(_ targetEmail: String, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans
            ? "🔑 保险箱未缓存「\(targetEmail)」，已保留原 CLI 凭证并在终端启动登录"
            : "🔑 \"\(targetEmail)\" not cached in vault; kept current CLI token and opened login in Terminal"
    }

    static func bannerRestoringAppKeychain(_ targetEmail: String, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans ? "🔄 正在恢复主应用共享钥匙串至「\(targetEmail)」..." : "🔄 Restoring shared keychain to \"\(targetEmail)\"..."
    }

    static func bannerRestoredAppKeychain(_ targetEmail: String, bgCount: Int, _ lang: AppLanguage.Resolved) -> String {
        if lang == .zhHans {
            let warn = bgCount > 0 ? "（注意有 \(bgCount) 个后台 agy 进程运行中，未带 SSH_CLIENT=1 的会回写钥匙串）" : ""
            return "✅ 已将共享钥匙串恢复为「\(targetEmail)」\(warn)"
        }
        let warn = bgCount > 0 ? " (\(bgCount) background agy process(es) without SSH_CLIENT=1 may overwrite it)" : ""
        return "✅ Shared keychain restored to \"\(targetEmail)\"\(warn)"
    }

    static func bannerRestoreMissingSlot(_ targetEmail: String, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans
            ? "⚠️ 保险箱未缓存「\(targetEmail)」，请在 App 内重新登录"
            : "⚠️ \"\(targetEmail)\" not cached in vault; please sign in again in the App"
    }

    static func bannerProfileExists(_ name: String, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans ? "⚠️ 账号环境「\(name)」已存在" : "⚠️ Profile \"\(name)\" already exists"
    }

    static func bannerProfileCreated(_ name: String, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans ? "✅ 已创建隔离环境：\(name)（已软链共享插件目录）" : "✅ Created isolated profile: \(name) (extensions linked)"
    }

    static func bannerProfileDeleted(_ name: String, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans ? "🗑️ 已移除配置项：\(name)（本地磁盘数据仍保留以防误删）" : "🗑️ Removed profile: \(name) (local data kept on disk)"
    }

    static func bannerSwitchingApp(_ name: String, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans ? "🔄 正在安全关闭当前 Antigravity 并切换至「\(name)」..." : "🔄 Safely closing Antigravity and switching to \"\(name)\"..."
    }

    static func bannerSwitchedApp(_ name: String, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans ? "🚀 已切换并启动「\(name)」" : "🚀 Switched and launched \"\(name)\""
    }

    static func bannerSwitchedAppNeedsLogin(_ name: String, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans
            ? "⚠️ 保险箱无「\(name)」有效凭证，已启动 Antigravity，请在 App 内重新登录一次"
            : "⚠️ No cached token for \"\(name)\"; launched Antigravity — please sign in once"
    }

    static func bannerParallelLaunched(_ name: String, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans ? "✨ 已并排双开启动「\(name)」" : "✨ Launched parallel instance \"\(name)\""
    }

    static func bannerCopiedTerminalFallback(_ cmd: String, _ lang: AppLanguage.Resolved) -> String {
        lang == .zhHans ? "📋 已复制 `\(cmd)` 到剪贴板并唤醒终端" : "📋 Copied `\(cmd)` to clipboard and opened Terminal"
    }

    static func localizeMenubarText(_ raw: String, language: AppLanguage.Resolved) -> String {
        guard language == .en else { return raw }
        return raw
            .replacingOccurrences(of: "待命", with: "Idle")
            .replacingOccurrences(of: "排队", with: "Queue")
            .replacingOccurrences(of: "断流", with: "EOF")
            .replacingOccurrences(of: "活跃", with: "Active")
    }

    static func localizeDiagnosticPhase(_ raw: String, language: AppLanguage.Resolved) -> String {
        guard language == .en else { return raw }
        switch raw {
        case "调研/检索": return "Research / Search"
        case "编码修改": return "Code Editing"
        case "测试/构建/排错": return "Test / Build / Debug"
        case "调度/看板协作": return "Agent Coordination"
        case "总结/文字输出": return "Summary / Response"
        default: return raw
        }
    }

    static func localizeDiagnosticSource(_ raw: String, language: AppLanguage.Resolved) -> String {
        guard language == .en else { return raw }
        switch raw {
        case "read_file 读取": return "read_file output"
        case "后台测试/E2E回传": return "Async Test / E2E output"
        case "后台其他命令回传": return "Async Command output"
        case "同步测试/构建输出": return "Sync Test / Build output"
        case "同步搜索/Git输出": return "Sync Search / Git output"
        case "同步其他命令输出": return "Sync Command output"
        case "edit/write 回执": return "edit/write receipts"
        case "看板/子Agent协作": return "Swarm / Subagent msgs"
        case "其他系统提示": return "Other system prompts"
        case "模型思考与输出": return "Model output"
        case "模型思考/回复与参数": return "Model output & args"
        case "用户输入": return "User prompts"
        case "报错信息": return "Error logs"
        default: return raw
        }
    }

    static func localizeAgentLabel(_ raw: String, language: AppLanguage.Resolved) -> String {
        guard language == .en else { return raw }
        if raw == "主会话" { return "Main" }
        return raw
    }

    static func localizeDiagnosticDetail(_ raw: String, language: AppLanguage.Resolved) -> String {
        guard language == .en else { return raw }
        if raw.hasPrefix("休眠等待子Agent/后台 ") {
            return raw
                .replacingOccurrences(of: "休眠等待子Agent/后台 ", with: "Idle waiting for subagent/task ")
                .replacingOccurrences(of: " 后唤醒 ", with: " ")
        }
        if raw.hasPrefix("等待/停顿 ") {
            return raw
                .replacingOccurrences(of: "等待/停顿 ", with: "Idle ")
                .replacingOccurrences(of: " 后续聊 ", with: " before resume ")
        }
        if raw.hasPrefix("上下文从 ") {
            return raw
                .replacingOccurrences(of: "上下文从 ", with: "Context reduced ")
                .replacingOccurrences(of: " 缩减至 ", with: " → ")
        }
        if raw.contains("断流后重连重试") {
            return raw
                .replacingOccurrences(of: "云端异常", with: "Cloud error")
                .replacingOccurrences(of: " 断流后重连重试", with: " stream retry")
        }
        if raw.hasPrefix("模型切换 ") {
            return raw.replacingOccurrences(of: "模型切换 ", with: "Model switch ")
        }
        if raw.hasPrefix("收到后台 ") {
            return raw
                .replacingOccurrences(of: "收到后台 ", with: "Interrupted by async ")
                .replacingOccurrences(of: " 回传后打断 ", with: " ")
        }
        if raw.hasPrefix("收到看板/子Agent消息后重算 ") {
            return raw.replacingOccurrences(of: "收到看板/子Agent消息后重算 ", with: "Board/subagent message rebuild ")
        }
        if raw.hasPrefix("连续执行中路由或前缀变动 ") {
            return raw.replacingOccurrences(of: "连续执行中路由或前缀变动 ", with: "Mid-run route or prefix shift ")
        }
        return raw
    }

    static func localizeRuntimeText(_ raw: String, language: AppLanguage.Resolved) -> String {
        guard language == .en else { return raw }
        let directMap: [String: String] = [
            "🔴 503 云端算力不足排队中": "🔴 503 Cloud Capacity Queued",
            "⚠️ 网络断流重连中": "⚠️ Stream Disconnected, Reconnecting",
            "⚠️ 429 频控限流退避中": "⚠️ 429 Rate Limited",
            "工具执行完毕，等待大模型下发下一步决策...": "Tools finished, awaiting next model step...",
            "正在向大模型提交 Prompt...": "Submitting prompt to model...",
            "遇到异常等待处理": "Error encountered, retrying...",
            "待命中": "Idle",
            "待命 (已输出回复)": "Idle (Replied)",
            "等待云端响应": "Waiting for Model",
            "模型输出中": "Streaming Output",
            "已接收用户输入": "User Input Received",
            "异常拦截": "Error Intercepted",
            "活跃处理中": "Active",
            "畅通": "Healthy",
            "503 算力不足排队中": "503 Capacity Queue",
            "网络断流重连中": "Stream Reconnecting",
            "429 限流退避中": "429 Rate Limited"
        ]
        if let hit = directMap[raw] {
            return hit
        }
        if raw.hasPrefix("执行工具 [") {
            return raw.replacingOccurrences(of: "执行工具 [", with: "Running Tool [")
        }
        return raw
    }

    static func localizeDiagnosticCause(_ raw: String, language: AppLanguage.Resolved) -> String {
        guard language == .en else { return raw }
        switch raw {
        case "压缩/重开重建": return "Context compaction / reset"
        case "云端报错/切节点重连": return "Cloud error / reconnect"
        case "前缀/系统注入变动": return "Prefix / system prompt shift"
        case "停顿/等待续聊过期": return "Idle TTL expiration"
        default: return raw
        }
    }

    static func localizeDiagnosticRecommendation(_ raw: String, language: AppLanguage.Resolved) -> String {
        guard language == .en else { return raw }
        if raw == "当前缓存命中与上下文体积整体健康。" {
            return "Cache hit rate and context size are healthy."
        }
        if raw == "当前会话暂无显著浪费。" {
            return "No significant cache waste detected in this session."
        }
        if raw.contains("子 Agent 占总花费") {
            return raw
                .replacingOccurrences(of: "子 Agent 占总花费 ", with: "Subagents used ")
                .replacingOccurrences(of: "（最大开销：", with: " of cost (top: ")
                .replacingOccurrences(of: "），可点击上方列表单独下钻。", with: "); select one above to inspect.")
        }
        if raw.contains("命令输出大户：") {
            return raw
                .replacingOccurrences(of: "命令输出大户：「", with: "Heavy command output: \"")
                .replacingOccurrences(of: "」累计吐出 ", with: "\" emitted ")
                .replacingOccurrences(of: " 字符（占总上下文 ", with: " chars (")
                .replacingOccurrences(of: "）。", with: " of context).")
        }
        if raw.contains("等待后重算") {
            return "Cache expired after idle pause — run `/compact` or start a new session before resuming heavy contexts."
        }
        if raw.contains("运行中前缀重建") {
            return "Prefix rebuilt mid-run — avoid switching models or injecting large async logs during long tasks."
        }
        if raw.contains("云端断流重算") {
            return "Cloud stream drops forced cache rebuilds — split work into smaller tasks to limit retry cost."
        }
        if raw.contains("后台测试回传占") {
            return "Background test logs take a large share of context — use concise or silent test output flags."
        }
        if raw.contains("重复读取") {
            return "Repeated `read_file` calls detected — locate symbols with grep/codegraph first before reading."
        }
        return raw
    }
}
