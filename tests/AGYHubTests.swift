import AppKit
import Foundation
import SwiftUI

// 轻量 TDD 测试入口：直击 2026-11-12 账号被 alice 覆盖的真实根因
@main
struct AGYHubTestsRunner {
    static var failures = 0

    static func expect(_ condition: Bool, _ message: String, file: String = #file, line: Int = #line) {
        if !condition {
            fputs("❌ FAIL [\(URL(fileURLWithPath: file).lastPathComponent):\(line)]: \(message)\n", stderr)
            failures += 1
        }
    }

    static func expectEqual<T: Equatable>(_ actual: T?, _ expected: T?, _ message: String, file: String = #file, line: Int = #line) {
        if actual != expected {
            fputs("❌ FAIL [\(URL(fileURLWithPath: file).lastPathComponent):\(line)]: \(message) (actual=\(String(describing: actual)), expected=\(String(describing: expected)))\n", stderr)
            failures += 1
        }
    }

    static func makeTempHome() -> String {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("agyhub-tdd-\(UUID().uuidString)")
            .path
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(atPath: "\(dir)/.gemini/antigravity-cli/log", withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(atPath: "\(dir)/.agy-profiles", withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(atPath: "\(dir)/Library/Logs/Antigravity", withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(atPath: "\(dir)/Library/Application Support/Antigravity", withIntermediateDirectories: true)
        return dir
    }

    static func setMtime(_ date: Date, path: String) {
        try? FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: path)
    }

    static func glogDate(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int, _ second: Int) -> Date {
        var comps = Calendar(identifier: .gregorian).dateComponents([.year], from: Date())
        comps.month = month
        comps.day = day
        comps.hour = hour
        comps.minute = minute
        comps.second = second
        return Calendar(identifier: .gregorian).date(from: comps)!
    }

    static func main() {
        testOldCLILogHeartbeatMtimeDoesNotFakeRecentLogin()
        testLogoutInSameLogOverridesEarlierLogin()
        testTokenRefreshLogDetectsBackgroundCLIKeychainWrite()
        testDesktopAppLoginOverridesOlderCLILogWhenKeychainModified()
        testTokenRefreshHijackAfterDesktopAppLoginDetected()
        testExternalKeychainWriteInvalidatesOlderAgyhubSwitchState()
        testDecodeGoKeyringBase64CredentialToRawJSON()
        testWriteCLITokenFileStoresDecodedJSONWithOwnerOnlyPermission()
        testSwitchCLITokenFileSavesRefreshedCurrentBackAndWritesTarget()
        testSwitchCLITokenFileWithoutCachedTargetSavesCurrentAndPreservesFile()
        testSwitchCLITokenFileWithCorruptedCurrentFileDoesNotPolluteVault()
        testFileBasedCLILogDoesNotTriggerKeychainWriteEvent()
        testCLIIndependentModeCleanup()
        testDefaultRefreshIntervalIsFiveSeconds()
        testMaxSessionStallSecondsCalculation()
        testParseUserQuotaSummaryWeeklyBuckets()
        testUltraAccountQuotaDisplayLogic()
        testQuotaCountdownFormatting()
        testQuotaTooltipGeneration()
        testCleanSessionDisplayTitle()
        testAllSessionsAccessibleForScrolling()
        testDesktopAppSwitchUsesNativeLaunchWithoutUserDataDir()
        testEnsureProfileDirectoryDoesNotInjectZoomPreferences()
        testProfileRowActionsHideParallelAndDeleteButtons()
        testAccountListSortsActiveAccountsFirst()
        testKeychainDriftPolicyIgnoresIntentionalAgyhubSwitch()
        testEffectiveActiveCLIProfileFallsBackToSharedKeychainWhenTokenFileMissing()
        testSameAccountTokenRefreshAfterAgyhubSwitchIsNotDrift()
        testSwitchStartupRaceDoesNotPoisonCLIActiveJson()
        testCredentialTokenUpdatePreservesGoKeyringBase64FormatAndRawJSON()
        testQuotaRefreshPersistsNewTokenBackToVaultAndTokenFile()
        testSyncOnboardingUsernameUpdatesAppStorageWithoutDroppingOtherKeys()
        testDisplayAppEmailPrefersExpectedRunningAppOverDriftedKeychain()
        testDetectLatestDesktopAppAuthDateScansBeyond128KB()
        testSyncedExpectedAppStateAdvancesOnManualDesktopLoginOnlyAfterSwitchWindow()
        testSessionItemCLIBadgeLabelForCLIAndApp()
        testSessionTitleMarqueePolicyCalculations()
        testScrollingSessionTitleDoesNotExpandRowWidth()
        testSessionRowCapsuleBadgesAndContextFormatting()
        testWriteCLITokenFileRejectsMissingAccessTokenAndPersists0600()
        testEnsureCLITokenFileIfNeededRecoversMissingOrCorruptedFileFromVault()
        testCliFileModeCommandUsesAcpLoginFlag()
        testQuotaRequestUsesHubUserAgentForArgonSupport()
        testNativeMacOSLaunchConfigFiltersHelpersSanitizesEnvAndAllowsFullShutdownWindow()
        testSubagentAggregationBadgeAndDetailDrilldown()
        testAccountListSortsByMostRecentlyUsedOrder()
        testAggregatedSubagentStatsAndResizableWindowPolicy()
        testMainDashboardFullBleedChromeAcrossResizes()
        testWindowResizeEdgePolicyHitZonesAndAnchoredFrameMath()
        testCloseButtonHidesOnlyTargetWindowWithoutTerminating()
        testSharedKeychainCaptureAndRestoreVerifyEmbeddedCredentialEmail()
        testQuotaResolveCredentialRejectsMismatchedVaultEmail()
        testEffectiveExpectedAppEmailHoldsWithin30sSwitchLaunchWindow()
        testCLIRefreshPolicySkipsWhileAppSwitchInProgress()
        testUsageHistoryPayloadDecodingAndRangeSummarization()
        testUsageAnalyticsEdgeCasesEmptyDataAndZeroCostTokens()
        testUsageHistoryConversationAggregationAcrossRanges()
        testWindowActivationGuardBlocksAccidentalSwitchOnFocusClick()
        testRecent503PolicyRefreshThrottleAndBadgeFormatting()
        testNativeWindowActivationPolicyAndMainMenuContract()
        testSessionDiagnosticsDecodingAndCopySummaryFormatting()
        testOAuthClientConfigLoadingAndMissingCredentialsFallback()
        testPollingSchedulePolicyThreeStateIntervals()
        testMonitorPayloadDedupSkipsRedundantPublishedUpdates()
        testDebouncedTriggerCoalescesBurstsAndSupportsCancel()
        testSessionDirectoryWatcherExistingOnlyAndLateCreation()
        testMonitorDaemonClientProtocolUnchangedAndCommands()
        testMonitorDaemonClientTimeoutCrashRecoveryAndBackoff()
        testAppLanguageSystemResolutionAndPersistence()
        testL10nAllKeysNonEmptyAndLocalizedHelpers()
        testQuotaExpiredMissingCredentialsGentleHint()
        testLocalAccountDetectorAppendLogAndRefreshQuotasConcurrencySafety()

        if failures > 0 {
            fputs("\n❌ 共 \(failures) 个断言失败\n", stderr)
            exit(1)
        }
        print("✅ 全部 TDD 测试通过！")
    }

    // 用例 1：重现 16:15 真实故障 —— 旧 alice CLI 日志在 16:14 仍在打心跳，file mtime 最新，
    // 但真正的 applyAuthResult 登录发生在 11:50:22，绝不能拿 file mtime 当成 16:14 登录从而压过 15:23 的 switch 时间。
    static func testOldCLILogHeartbeatMtimeDoesNotFakeRecentLogin() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        let cliLog = "\(home)/.gemini/antigravity-cli/log/cli-20261112_115022.log"
        let content = """
        I1112 11:50:22.700473 965 server_oauth.go:221] applyAuthResult: email=alice@example.com, authMethod=consumer, quotaProject=
        I1112 11:50:22.700479 965 server_oauth.go:226] OAuth: authenticated successfully as alice@example.com
        I1112 16:14:23.444018 23782 http_helpers.go:654] URL: https://daily-cloudcode-pa.googleapis.com/v1internal:fetchAvailableModels
        """
        try? content.write(toFile: cliLog, atomically: true, encoding: .utf8)
        setMtime(glogDate(11, 12, 16, 14, 23), path: cliLog)

        let auth = CLIAccountManager.detectLatestLogAuth(homeDir: home)
        expectEqual(auth?.email, "alice@example.com", "应解析到 alice 登录邮箱")
        if let dt = auth?.date {
            let comps = Calendar(identifier: .gregorian).dateComponents([.hour, .minute, .second], from: dt)
            expectEqual(comps.hour, 11, "登录时间戳必须是日志行内的 11 点，而不是文件 mtime 的 16 点")
            expectEqual(comps.minute, 50, "登录分钟必须是 50 分")
        }
    }

    // 用例 2：同一份日志先登录了 charlie，随后又执行了 Logging out current user，绝不能继续把该日志报成已登录
    static func testLogoutInSameLogOverridesEarlierLogin() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        let cliLog = "\(home)/.gemini/antigravity-cli/log/cli-20261112_114752.log"
        let content = """
        I1112 11:47:52.951701 911 server_oauth.go:221] applyAuthResult: email=charlie@example.com, authMethod=consumer, quotaProject=
        I1112 11:47:56.536442 3152 server_oauth.go:192] Logging out current user
        """
        try? content.write(toFile: cliLog, atomically: true, encoding: .utf8)

        let auth = CLIAccountManager.detectLatestLogAuth(homeDir: home)
        expect(auth == nil, "同日志若随后已退出登录，detectLatestLogAuth 必须返回 nil")
    }

    // 用例 3：重现 15:50:22 真凶 —— 11:50 启动的旧 CLI 进程在 15:50:22 触发 token refreshed，
    // 这实际改写了共享钥匙串 ("gemini", "antigravity")，事件归属应为 alice@example.com 且时间为 15:50:22
    static func testTokenRefreshLogDetectsBackgroundCLIKeychainWrite() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        let cliLog = "\(home)/.gemini/antigravity-cli/log/cli-20261112_115022.log"
        let content = """
        I1112 11:50:22.700473 965 server_oauth.go:221] applyAuthResult: email=alice@example.com, authMethod=consumer, quotaProject=
        I1112 15:50:22.932874 22158 browser.go:265] token refreshed, new expiry=2026-11-12 16:50:21
        """
        try? content.write(toFile: cliLog, atomically: true, encoding: .utf8)
        setMtime(glogDate(11, 12, 16, 16, 33), path: cliLog)

        let writeEvt = CLIAccountManager.detectLatestLogKeychainWriteEvent(homeDir: home)
        expectEqual(writeEvt?.email, "alice@example.com", "后台 token refreshed 的写入邮箱应关联到该进程登录的 alice")
        expect(writeEvt?.isTokenRefresh == true, "应识别出此次写钥匙串属于 token refreshed")
        if let dt = writeEvt?.date {
            let comps = Calendar(identifier: .gregorian).dateComponents([.hour, .minute, .second], from: dt)
            expectEqual(comps.hour, 15, "refresh 时间应为 15 点")
            expectEqual(comps.minute, 50, "refresh 分钟应为 50 分")
        }
    }

    // 用例 4：主应用在 15:15:32 完成 Auth succeeded（钥匙串 mtime=15:15:30），而旧 CLI 最近活动停在 14:50:24，
    // 共享钥匙串归属裁决应准确判定当前有效账号为主应用的 bob@example.com
    static func testDesktopAppLoginOverridesOlderCLILogWhenKeychainModified() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        let lsLog = "\(home)/Library/Logs/Antigravity/language_server.log"
        let lsContent = """
        ERROR: logging before google.Init: I1112 15:15:32.130238 458266 server.go:3634] Auth succeeded, refreshing features and managers
        """
        try? lsContent.write(toFile: lsLog, atomically: true, encoding: .utf8)

        let appStorage = "\(home)/Library/Application Support/Antigravity/app_storage.json"
        try? "{\"agy.onboarding.lastLoginUsername\":\"bob@example.com\"}".write(toFile: appStorage, atomically: true, encoding: .utf8)

        let cliLog = "\(home)/.gemini/antigravity-cli/log/cli-20261112_115022.log"
        let cliContent = """
        I1112 11:50:22.700473 965 server_oauth.go:221] applyAuthResult: email=alice@example.com, authMethod=consumer, quotaProject=
        I1112 14:50:24.139442 18140 browser.go:265] token refreshed, new expiry=2026-11-12 15:50:23
        """
        try? cliContent.write(toFile: cliLog, atomically: true, encoding: .utf8)

        let resolution = CLIAccountManager.resolveSharedKeychainOwner(
            homeDir: home,
            profilesRootDir: "\(home)/.agy-profiles",
            keychainModDate: glogDate(11, 12, 15, 15, 30),
            hasActiveKeychain: true
        )
        expectEqual(resolution.email, "bob@example.com", "主应用 15:15:32 Auth succeeded 且钥匙串在 15:15:30 创建，应归属 bob")
        expect(resolution.source == .desktopApp, "归属来源应判定为 desktopApp")
    }

    // 用例 5：精确复现今日 15:15:30 -> 15:50:22 -> 16:15 完整事故链路：
    // 桌面端在 15:15:32 登录 bob，旧 CLI 在 15:50:22 触发 token refreshed 覆写为 alice，
    // 裁决结果必须准确指出当前持有者为 alice 且 isTokenRefreshHijack == true！
    static func testTokenRefreshHijackAfterDesktopAppLoginDetected() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        let lsLog = "\(home)/Library/Logs/Antigravity/language_server.log"
        try? "ERROR: logging before google.Init: I1112 15:15:32.130238 458266 server.go:3634] Auth succeeded, refreshing features and managers\n"
            .write(toFile: lsLog, atomically: true, encoding: .utf8)

        let appStorage = "\(home)/Library/Application Support/Antigravity/app_storage.json"
        try? "{\"agy.onboarding.lastLoginUsername\":\"bob@example.com\"}".write(toFile: appStorage, atomically: true, encoding: .utf8)

        let cliLog = "\(home)/.gemini/antigravity-cli/log/cli-20261112_115022.log"
        let cliContent = """
        I1112 11:50:22.700473 965 server_oauth.go:221] applyAuthResult: email=alice@example.com, authMethod=consumer, quotaProject=
        I1112 15:50:22.932874 22158 browser.go:265] token refreshed, new expiry=2026-11-12 16:50:21
        """
        try? cliContent.write(toFile: cliLog, atomically: true, encoding: .utf8)

        let resolution = CLIAccountManager.resolveSharedKeychainOwner(
            homeDir: home,
            profilesRootDir: "\(home)/.agy-profiles",
            keychainModDate: glogDate(11, 12, 15, 50, 23),
            hasActiveKeychain: true
        )
        expectEqual(resolution.email, "alice@example.com", "15:50:22 refresh 后共享钥匙串真实持有者为 alice")
        expect(resolution.source == .cliRefresh, "归属来源应识别为 cliRefresh")
        expect(resolution.isTokenRefreshHijack == true, "当主应用记录为 bob 而旧 CLI 续期成 alice 时应标出 hijack 警告")
    }

    // 用例 6：若 cli_active.json 记录了旧切号 (15:23)，之后钥匙串在 15:50:23 被外力修改，不应再继续相信旧 cli_active.json
    static func testExternalKeychainWriteInvalidatesOlderAgyhubSwitchState() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        let cliActive = "\(home)/.agy-profiles/cli_active.json"
        let tSwitch = glogDate(11, 12, 15, 23, 20).timeIntervalSince1970
        let stateData = try! JSONEncoder().encode(CLIAccountManager.CLIActiveState(email: "bob@example.com", switchedAt: tSwitch))
        try? stateData.write(to: URL(fileURLWithPath: cliActive))

        let cliLog = "\(home)/.gemini/antigravity-cli/log/cli-20261112_115022.log"
        let cliContent = """
        I1112 11:50:22.700473 965 server_oauth.go:221] applyAuthResult: email=alice@example.com, authMethod=consumer, quotaProject=
        I1112 15:50:22.932874 22158 browser.go:265] token refreshed, new expiry=2026-11-12 16:50:21
        """
        try? cliContent.write(toFile: cliLog, atomically: true, encoding: .utf8)

        let resolution = CLIAccountManager.resolveSharedKeychainOwner(
            homeDir: home,
            profilesRootDir: "\(home)/.agy-profiles",
            keychainModDate: glogDate(11, 12, 15, 50, 23),
            hasActiveKeychain: true
        )
        expectEqual(resolution.email, "alice@example.com", "15:50:23 外部改写钥匙串后，旧 cli_active (15:23) 应失效，改为准确识别 alice")
    }

    // MARK: - CLI 文件 token 模式（agy 在 SSH_CLIENT=1 时改读写 ~/.gemini/antigravity-cli/antigravity-oauth-token，不碰系统钥匙串）

    /// 构造与 agy 真实落盘结构一致的凭证 JSON
    static func credentialJSON(email: String, accessToken: String) -> Data {
        let json = """
        {"token":{"access_token":"\(accessToken)","token_type":"Bearer","refresh_token":"r-\(email)","expiry":"2026-11-12T19:00:00+08:00"},"auth_method":"consumer","id_token_email":"\(email)","writer_id":"w"}
        """
        return json.data(using: .utf8)!
    }

    /// 内存保险箱：替代真实钥匙串，同时记录写入与清理次数，便于断言绝不碰其它槽位
    final class MemoryVault {
        var slots: [String: Data] = [:]
        var writes: [String] = []
        var deletes: [String] = []
        var vault: CLIAccountManager.CredentialVault {
            CLIAccountManager.CredentialVault(
                read: { [unowned self] acc in self.slots[acc] },
                write: { [unowned self] data, acc in self.slots[acc] = data; self.writes.append(acc); return true },
                list: { [unowned self] in Set(self.slots.keys) },
                delete: { [unowned self] acc in self.slots.removeValue(forKey: acc); self.deletes.append(acc) }
            )
        }
    }

    /// 内存共享钥匙串替身：用于测试 capture/restore 链路而不碰系统真实钥匙串
    final class MemorySharedStore {
        var data: Data?
        init(_ data: Data? = nil) { self.data = data }
        var store: CLIAccountManager.SharedCredentialStore {
            CLIAccountManager.SharedCredentialStore(
                hasActive: { [unowned self] in self.data != nil },
                read: { [unowned self] in self.data },
                write: { [unowned self] newData in self.data = newData; return true }
            )
        }
    }

    // 用例 7：保险箱里从系统钥匙串捕获的是 go-keyring-base64 前缀格式，写进 agy 文件前必须还原成纯 JSON，否则 agy 会当成未登录
    static func testDecodeGoKeyringBase64CredentialToRawJSON() {
        let raw = credentialJSON(email: "alice@example.com", accessToken: "ya29.A")
        let wrapped = ("go-keyring-base64:" + raw.base64EncodedString()).data(using: .utf8)!
        expectEqual(CLIAccountManager.decodeCredentialJSON(wrapped), raw, "go-keyring-base64 前缀必须被剥离并解码为原始 JSON")
        expectEqual(CLIAccountManager.decodeCredentialJSON(raw), raw, "已是纯 JSON 的凭证必须原样返回")
        expectEqual(CLIAccountManager.credentialEmail(wrapped), "alice@example.com", "两种格式都必须能解析出 id_token_email")
        expectEqual(CLIAccountManager.credentialEmail("go-keyring-base64:!!!不是base64".data(using: .utf8)!), nil, "坏数据必须返回 nil 而不是崩溃或乱猜")
    }

    // 用例 8：token 文件含 refresh_token，必须仅本人可读写 (0600)，且父目录不存在时也能写入
    static func testWriteCLITokenFileStoresDecodedJSONWithOwnerOnlyPermission() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }
        try? FileManager.default.removeItem(atPath: "\(home)/.gemini/antigravity-cli")

        let raw = credentialJSON(email: "bob@example.com", accessToken: "ya29.B")
        let wrapped = ("go-keyring-base64:" + raw.base64EncodedString()).data(using: .utf8)!
        expect(CLIAccountManager.writeCLITokenFile(wrapped, homeDir: home), "写入 token 文件应成功（自动创建父目录）")

        let path = CLIAccountManager.cliTokenFilePath(homeDir: home)
        expectEqual(FileManager.default.contents(atPath: path), raw, "落盘内容必须是解码后的纯 JSON")
        let perm = (try? FileManager.default.attributesOfItem(atPath: path)[.posixPermissions] as? NSNumber)?.intValue
        expectEqual(perm, 0o600, "token 文件权限必须是 0600")
        expectEqual(CLIAccountManager.readCLITokenFileEmail(homeDir: home), "bob@example.com", "应从文件读出当前 CLI 账号")
    }

    // 用例 9：agy 运行期间会自己刷新文件里的 token；切号时必须把文件里「最新」的 alice 存回 alice 槽位，再写入 bob，且只动这两个槽位
    static func testSwitchCLITokenFileSavesRefreshedCurrentBackAndWritesTarget() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        let mem = MemoryVault()
        mem.slots["alice@example.com"] = credentialJSON(email: "alice@example.com", accessToken: "ya29.OLD")
        let bob = credentialJSON(email: "bob@example.com", accessToken: "ya29.N")
        mem.slots["bob@example.com"] = ("go-keyring-base64:" + bob.base64EncodedString()).data(using: .utf8)!
        mem.slots["charlie@example.com"] = credentialJSON(email: "charlie@example.com", accessToken: "ya29.H")

        let refreshed = credentialJSON(email: "alice@example.com", accessToken: "ya29.REFRESHED")
        _ = CLIAccountManager.writeCLITokenFile(refreshed, homeDir: home)

        let result = CLIAccountManager.switchCLITokenFile(homeDir: home, targetEmail: "Bob@Example.com", vault: mem.vault)
        expect(result.switchedImmediately, "目标已缓存时应立即切换")
        expectEqual(mem.slots["alice@example.com"], refreshed, "切走前必须把文件里刷新后的 alice token 存回 alice 槽位")
        expectEqual(FileManager.default.contents(atPath: CLIAccountManager.cliTokenFilePath(homeDir: home)), bob, "文件必须换成 bob 的纯 JSON")
        expectEqual(CLIAccountManager.readCLITokenFileEmail(homeDir: home), "bob@example.com", "切换后文件归属应为 bob")
        expectEqual(mem.writes, ["alice@example.com"], "保险箱只允许写回原账号槽位，绝不改动目标或其它槽位")
    }

    // 用例 10：目标从未缓存时，先保住当前账号进保险箱，且保留现用 token 文件不删除（由 acp --login 成功后覆写，防止切号半途中断影响在用 CLI 会话）
    static func testSwitchCLITokenFileWithoutCachedTargetSavesCurrentAndPreservesFile() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        let mem = MemoryVault()
        let current = credentialJSON(email: "alice@example.com", accessToken: "ya29.CUR")
        _ = CLIAccountManager.writeCLITokenFile(current, homeDir: home)

        let path = CLIAccountManager.cliTokenFilePath(homeDir: home)
        let result = CLIAccountManager.switchCLITokenFile(homeDir: home, targetEmail: "dave@example.com", vault: mem.vault)
        expect(!result.switchedImmediately, "目标未缓存时不能报告切换成功")
        expectEqual(mem.slots["alice@example.com"], current, "发起登录前必须先把当前账号存进保险箱，否则会丢登录态")
        expect(FileManager.default.fileExists(atPath: path), "目标未缓存时绝不能提前删掉现用 token 文件，避免终端未登录完成前后台会话全部中断")
        expectEqual(FileManager.default.contents(atPath: path), current, "现有 token 文件内容必须保持原样")
        expectEqual(result.savedSlots, ["alice@example.com"], "返回的槽位列表应包含刚存回的账号")
    }

    // 用例 11：文件被截断/损坏时识别不出归属，绝不能把垃圾写进任何槽位；目标仍可正常切入
    static func testSwitchCLITokenFileWithCorruptedCurrentFileDoesNotPolluteVault() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        let mem = MemoryVault()
        let target = credentialJSON(email: "bob@example.com", accessToken: "ya29.N")
        mem.slots["bob@example.com"] = target
        let path = CLIAccountManager.cliTokenFilePath(homeDir: home)
        try? "{\"token\":{\"access_tok".write(toFile: path, atomically: true, encoding: .utf8)

        let result = CLIAccountManager.switchCLITokenFile(homeDir: home, targetEmail: "bob@example.com", vault: mem.vault)
        expect(result.switchedImmediately, "损坏的旧文件不应阻止切入目标账号")
        expect(mem.writes.isEmpty, "无法识别归属的损坏内容绝不能写入任何保险箱槽位")
        expectEqual(FileManager.default.contents(atPath: path), target, "文件应被目标凭证覆盖")
    }

    // 用例 12：重现 18:48 橙色警告假阳性 —— 当 CLI 在 SSH_CLIENT=1 文件模式运行（日志包含 Using file-based token storage），
    // 即使随后的日志打印了 applyAuthResult，它写的是 token 文件，绝不修改系统钥匙串，detectLatestLogKeychainWriteEvent 必须忽略它
    static func testFileBasedCLILogDoesNotTriggerKeychainWriteEvent() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        let acpLog = "\(home)/.gemini/antigravity-cli/log/acp-server-20261112_184530.log"
        let content = """
        I1112 18:45:30.123456 12345 main.go:100] Using file-based token storage because SSH session detected
        I1112 18:45:30.234567 12345 server_oauth.go:221] applyAuthResult: email=alice@example.com, authMethod=consumer, quotaProject=
        I1112 18:45:30.345678 12345 browser.go:265] token refreshed, new expiry=2026-11-12 19:45:30
        """
        try? content.write(toFile: acpLog, atomically: true, encoding: .utf8)

        let event = CLIAccountManager.detectLatestLogKeychainWriteEvent(homeDir: home)
        expect(event == nil, "文件存储模式的 CLI 日志绝不能被识别为钥匙串写入事件")
    }

    // 用例 13：当关闭 CLI 独立模式时，应清理独立 token 文件，回归系统原生钥匙串共享
    static func testCLIIndependentModeCleanup() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        let tokenPath = CLIAccountManager.cliTokenFilePath(homeDir: home)
        let tokenData = credentialJSON(email: "alice@example.com", accessToken: "ya29.TOK")
        _ = CLIAccountManager.writeCLITokenFile(tokenData, homeDir: home)
        expect(FileManager.default.fileExists(atPath: tokenPath), "前置：token 文件应存在")

        CLIAccountManager.cleanupCLITokenFile(homeDir: home)
        expect(!FileManager.default.fileExists(atPath: tokenPath), "清理后 token 文件必须被物理移除")
    }

    // 用例 14：默认刷新间隔必须为 5.0 秒
    static func testDefaultRefreshIntervalIsFiveSeconds() {
        expectEqual(AGYHubStore.defaultRefreshInterval, 5.0, "默认刷新间隔必须为 5.0 秒")
    }

    // 用例 15：准确计算活跃会话中的单次最长等待耗时 (currentStall)
    @MainActor
    static func testMaxSessionStallSecondsCalculation() {
        let store = AGYHubStore(startMonitoring: false)
        expectEqual(store.maxSessionStallSeconds, 0.0, "空会话列表时最长等待时间应为 0")

        func makeSession(uuid: String, isRunning: Bool, stall: Double) -> SessionItem {
            let json = """
            {
                "uuid": "\(uuid)",
                "short_id": "\(uuid)",
                "client_type": "cli",
                "title": "测试会话",
                "is_running": \(isRunning),
                "interactions": 1,
                "input_tokens": 10,
                "cache_tokens": 0,
                "output_tokens": 10,
                "context_tokens": 20,
                "cache_pct": 0.0,
                "tps": 20.0,
                "total_tokens_consumed": 20,
                "total_cost_usd": 0.01,
                "total_cache_consumed": 0,
                "total_input_consumed": 10,
                "total_output_consumed": 10,
                "current_stall": \(stall),
                "health": "good",
                "health_desc": "良好",
                "current_phase": "streaming",
                "current_action": "running",
                "history_steps": [],
                "exists": true,
                "model": "gemini",
                "total_active_sec": 1.0,
                "total_local_sec": 0.5,
                "total_remote_sec": 0.5,
                "total_error_sec": 0.0,
                "breakdown_str": "1.0s"
            }
            """
            return try! JSONDecoder().decode(SessionItem.self, from: json.data(using: .utf8)!)
        }

        let s1 = makeSession(uuid: "s1", isRunning: true, stall: 12.4)
        let s2 = makeSession(uuid: "s2", isRunning: true, stall: 35.8)
        let s3 = makeSession(uuid: "s3", isRunning: false, stall: 99.0)

        store.payload = MonitorPayload(
            timestamp: "now", dataDir: "/test", activeCount: 2, totalRoundtrips: 3, hasAlert: false,
            menubar: MenuBarSummary(icon: "🟢", text: "ok", statusLevel: "ok", activeCount: 2),
            todayStats: TodayStats(totalTokens: 100, cacheTokens: 0, inputTokens: 50, outputTokens: 50, cachePct: 0, costUsd: 0.05, hasData: true, source: nil),
            sessions: [s1, s2, s3]
        )

        expectEqual(store.maxSessionStallSeconds, 35.8, "应准确计算当前活跃会话中的最大等待耗时 35.8s")
    }

    // 用例 16：解析官方 retrieveUserQuotaSummary 响应，准确区分 Gemini Models 与 Gemini 4 Argon（不被 3P Claude/GPT 混淆，也不因 "Gemini 4 Argon" 含 Gemini 字样而覆盖 Gemini）
    static func testParseUserQuotaSummaryWeeklyBuckets() {
        let sampleJSON = """
        {
          "groups": [
            {
              "displayName": "Gemini Models",
              "description": "Models within this group: Gemini Flash, Gemini Pro",
              "buckets": [
                {
                  "bucketId": "gemini-weekly",
                  "displayName": "Weekly Limit Remaining",
                  "window": "weekly",
                  "resetTime": "2026-11-14T22:59:34Z",
                  "remainingFraction": 0.51667786
                },
                {
                  "bucketId": "gemini-5h",
                  "displayName": "Five Hour Limit Remaining",
                  "window": "5h",
                  "resetTime": "2026-11-13T05:25:16Z",
                  "remainingFraction": 0
                }
              ]
            },
            {
              "displayName": "Claude and GPT models",
              "description": "Models within this group: Claude Opus, Claude Sonnet, GPT-OSS",
              "buckets": [
                {
                  "bucketId": "3p-weekly",
                  "displayName": "Weekly Limit Remaining",
                  "window": "weekly",
                  "resetTime": "2026-11-20T04:36:07Z",
                  "remainingFraction": 1
                },
                {
                  "bucketId": "3p-5h",
                  "displayName": "Five Hour Limit Remaining",
                  "window": "5h",
                  "resetTime": "2026-11-13T09:36:07Z",
                  "remainingFraction": 1
                }
              ]
            },
            {
              "displayName": "Gemini 4 Argon",
              "description": "For paid Pro plans, Argon quota is separate.",
              "buckets": [
                {
                  "bucketId": "gemini-argon-wtu-weekly",
                  "displayName": "Gemini 4 Argon Weekly Limit",
                  "window": "weekly",
                  "resetTime": "2026-11-14T23:00:02Z",
                  "remainingFraction": 0
                }
              ]
            }
          ]
        }
        """

        guard let data = sampleJSON.data(using: .utf8),
              let summary = AccountQuotaManager.parseQuotaSummary(data: data, email: "test@example.com", tier: "Google AI Pro") else {
            expect(false, "应成功解析配额数据")
            return
        }

        expectEqual(summary.email, "test@example.com", "邮箱应匹配")
        expectEqual(summary.isUltra, false, "Pro 账号 isUltra 应为 false")

        guard let gemini = summary.geminiQuota else {
            expect(false, "应提取到 Gemini 周配额")
            return
        }
        expectEqual(gemini.percentage, 52, "Gemini 剩余额度百分比应为 52%（不能被 Gemini 4 Argon 的 0% 覆盖）")
        expectEqual(gemini.remainingFraction, 0.51667786, "Gemini 剩余小数精确对齐")
        expectEqual(gemini.resetTimeStr, "2026-11-14T22:59:34Z", "Gemini 重置时间字符串对齐")

        guard let argon = summary.argonQuota else {
            expect(false, "应提取到 Gemini 4 Argon 周配额")
            return
        }
        expectEqual(argon.percentage, 0, "Argon 剩余额度百分比应为 0%（不能误取 3p-weekly 的 100%）")
        expectEqual(argon.remainingFraction, 0.0, "Argon 剩余小数精确对齐")
        expectEqual(argon.resetTimeStr, "2026-11-14T23:00:02Z", "Argon 重置时间字符串应来自 gemini-argon-wtu-weekly")

        // 无 Gemini 4 Argon 组时，3p-weekly 不得冒充 argonQuota
        let noArgonJSON = """
        {
          "groups": [
            {
              "displayName": "Gemini Models",
              "buckets": [{"bucketId": "gemini-weekly", "window": "weekly", "resetTime": "2026-11-14T22:59:34Z", "remainingFraction": 0.6}]
            },
            {
              "displayName": "Claude and GPT models",
              "buckets": [{"bucketId": "3p-weekly", "window": "weekly", "resetTime": "2026-11-20T04:36:07Z", "remainingFraction": 1.0}]
            }
          ]
        }
        """
        let noArgonSummary = noArgonJSON.data(using: .utf8).flatMap {
            AccountQuotaManager.parseQuotaSummary(data: $0, email: "noargon@example.com", tier: "Google AI Pro")
        }
        expectEqual(noArgonSummary?.geminiQuota?.percentage, 60, "无 Argon 时 Gemini 配额正常")
        expect(noArgonSummary?.argonQuota == nil, "无 Gemini 4 Argon 组时不应把 3P (Claude/GPT) 误认为 Argon")
    }

    // 用例 17：Ultra 账号仅展示 Gemini 周额度（配额池统一合并），非 Ultra 账号同时展示 Gemini 和 Argon
    static func testUltraAccountQuotaDisplayLogic() {
        let now = Date()
        let gBucket = WeeklyQuotaBucket(remainingFraction: 0.85, resetTime: now.addingTimeInterval(86400 * 3), resetTimeStr: "2026-11-15T00:00:00Z")
        let aBucket = WeeklyQuotaBucket(remainingFraction: 0.40, resetTime: now.addingTimeInterval(86400 * 6), resetTimeStr: "2026-11-18T00:00:00Z")

        // 1. Ultra 账号：displayItems 仅应包含 Gemini
        let ultraSummary = AccountQuotaSummary(
            email: "ultra@example.com",
            isUltra: true,
            geminiQuota: gBucket,
            argonQuota: aBucket,
            lastFetched: now
        )
        let ultraItems = AccountQuotaManager.displayItems(for: ultraSummary)
        expectEqual(ultraItems.count, 1, "Ultra 账号仅展示 1 项额度")
        expectEqual(ultraItems.first?.title, "Gemini", "Ultra 账号展示标题应为 Gemini")
        expectEqual(ultraItems.first?.percentage, 85, "Ultra 账号展示额度百分比为 85%")

        // 2. 普通/Pro 账号：displayItems 应同时包含 Gemini 与 Argon
        let proSummary = AccountQuotaSummary(
            email: "pro@example.com",
            isUltra: false,
            geminiQuota: gBucket,
            argonQuota: aBucket,
            lastFetched: now
        )
        let proItems = AccountQuotaManager.displayItems(for: proSummary)
        expectEqual(proItems.count, 2, "普通账号应展示 Gemini 与 Argon 2 项额度")
        expectEqual(proItems.first?.title, "Gemini", "首项应为 Gemini")
        expectEqual(proItems.last?.title, "Argon", "次项应为 Argon")
    }

    // 用例 18：周额度重置倒计时格式化验证 (d / h / m / 重置)
    static func testQuotaCountdownFormatting() {
        let baseDate = Date(timeIntervalSince1970: 1700000000)

        // 3 天 18 小时 -> "3d"
        let t1 = baseDate.addingTimeInterval(3 * 86400 + 18 * 3600)
        let b1 = WeeklyQuotaBucket(remainingFraction: 0.5, resetTime: t1, resetTimeStr: nil)
        expectEqual(b1.remainingCountdown(from: baseDate), "3d", "跨天应显示 3d")

        // 5 小时 30 分钟 -> "5h"
        let t2 = baseDate.addingTimeInterval(5 * 3600 + 30 * 60)
        let b2 = WeeklyQuotaBucket(remainingFraction: 0.5, resetTime: t2, resetTimeStr: nil)
        expectEqual(b2.remainingCountdown(from: baseDate), "5h", "不满 1 天应显示 5h")

        // 25 分钟 -> "25m"
        let t3 = baseDate.addingTimeInterval(25 * 60)
        let b3 = WeeklyQuotaBucket(remainingFraction: 0.5, resetTime: t3, resetTimeStr: nil)
        expectEqual(b3.remainingCountdown(from: baseDate), "25m", "不满 1 小时应显示 25m")

        // 已过重置时间 -> "重置"
        let t4 = baseDate.addingTimeInterval(-10)
        let b4 = WeeklyQuotaBucket(remainingFraction: 0.5, resetTime: t4, resetTimeStr: nil)
        expectEqual(b4.remainingCountdown(from: baseDate), "重置", "过期应显示「重置」")
    }

    // 用例 19：周配额详细悬浮 Tooltip 文本多行排版验证
    static func testQuotaTooltipGeneration() {
        let now = Date()
        let gBucket = WeeklyQuotaBucket(remainingFraction: 0.85, resetTime: now.addingTimeInterval(86400 * 3), resetTimeStr: nil)
        let aBucket = WeeklyQuotaBucket(remainingFraction: 0.40, resetTime: now.addingTimeInterval(86400 * 6), resetTimeStr: nil)

        // 1. Ultra 账号 Tooltip
        let ultraSummary = AccountQuotaSummary(email: "ultra@example.com", isUltra: true, geminiQuota: gBucket, argonQuota: aBucket, lastFetched: now)
        let ultraItems = AccountQuotaManager.displayItems(for: ultraSummary)
        let ultraTip = AccountQuotaManager.quotaTooltip(items: ultraItems, isUltra: true)
        expect(ultraTip.contains("Google AI Ultra"), "Ultra Tooltip 应标明 Ultra 统一共享配额池")
        expect(ultraTip.contains("Gemini 周额度: 85%"), "Ultra Tooltip 应展示 Gemini 额度")
        expect(!ultraTip.contains("Argon"), "Ultra Tooltip 严禁出现 Argon")

        // 2. 普通账号 Tooltip
        let proSummary = AccountQuotaSummary(email: "pro@example.com", isUltra: false, geminiQuota: gBucket, argonQuota: aBucket, lastFetched: now)
        let proItems = AccountQuotaManager.displayItems(for: proSummary)
        let proTip = AccountQuotaManager.quotaTooltip(items: proItems, isUltra: false)
        expect(proTip.contains("Gemini 周额度: 85%"), "普通 Tooltip 应展示 Gemini 额度")
        expect(proTip.contains("Gemini 4 Argon 周额度: 40%"), "普通 Tooltip 应展示 Gemini 4 Argon 额度")
    }

    // 用例 20：会话标题清洗过滤（剔除脏括号与无意义字符，优雅回退）
    static func testCleanSessionDisplayTitle() {
        let dirty1 = "{"
        let dirty2 = "   {  "
        let dirty3 = "{}"
        let dirty4 = ""
        let normal = "Analyzing Codebase Performance"

        let c1 = SessionTitleCleaner.cleanTitle(dirty1, fallbackUUID: "abcdef12-3456-7890")
        expectEqual(c1, "会话 #abcdef", "单括号应回退为会话编号")

        let c2 = SessionTitleCleaner.cleanTitle(dirty2, fallbackUUID: "12345678-abcd")
        expectEqual(c2, "会话 #123456", "带空格单括号应回退为会话编号")

        let c3 = SessionTitleCleaner.cleanTitle(dirty3, fallbackUUID: "99887766")
        expectEqual(c3, "会话 #998877", "空花括号对回退")

        let c4 = SessionTitleCleaner.cleanTitle(dirty4, fallbackUUID: "aabbccdd")
        expectEqual(c4, "会话 #aabbcc", "空字符串回退")

        let c5 = SessionTitleCleaner.cleanTitle(normal, fallbackUUID: "normal-uuid")
        expectEqual(c5, normal, "合规标题保持原样")
    }

    // 用例 21：会话列表全量支持滚动，严禁人为死板截断至 prefix(6)
    static func testAllSessionsAccessibleForScrolling() {
        var sessions: [SessionItem] = []
        for i in 1...15 {
            sessions.append(SessionItem(uuid: "u\(i)", title: "Session \(i)"))
        }

        let displayed = SessionListFilter.sessionsForDisplay(sessions)
        expectEqual(displayed.count, 15, "会话滚动列表应完整包含全部 15 个会话")
    }

    // 用例 22：桌面 App 单实例切换必须使用官方原生启动（严禁传 --user-data-dir 破坏 Retina 视口与分辨率）
    static func testDesktopAppSwitchUsesNativeLaunchWithoutUserDataDir() {
        let nonDefaultProfile = AGYProfile(
            name: "alice@example.com",
            userDataDir: "~/.agy-profiles/alice@example.com",
            isDefault: false
        )
        let defaultProfile = AGYProfile(
            name: "bob@example.com",
            userDataDir: "~/Library/Application Support/Antigravity",
            isDefault: true
        )

        // 1. 切换模式：非默认账号切换，必须使用 macOS 原生单实例参数 ["-a", targetApp]（不加 -n，不加 --user-data-dir）
        let switchArgsNonDefault = AntigravityLaunchConfig.launchArguments(
            for: nonDefaultProfile,
            targetApp: "/Applications/Antigravity.app",
            sharedExtensionsDir: "~/.antigravity/extensions",
            isParallelLaunch: false
        )
        expect(!switchArgsNonDefault.contains { $0.contains("--user-data-dir") }, "单实例切换非默认账号严禁包含 --user-data-dir，防止污染分辨率")
        expectEqual(switchArgsNonDefault, ["-a", "/Applications/Antigravity.app"], "切换模式必须遵循 macOS 原生单实例启动参数（不含 -n）")

        // 2. 默认账号切换，同样是官方原生单实例启动参数
        let switchArgsDefault = AntigravityLaunchConfig.launchArguments(
            for: defaultProfile,
            targetApp: "/Applications/Antigravity.app",
            sharedExtensionsDir: "~/.antigravity/extensions",
            isParallelLaunch: false
        )
        expectEqual(switchArgsDefault, ["-a", "/Applications/Antigravity.app"], "默认账号切换必须遵循 macOS 原生单实例启动参数（不含 -n）")

        // 3. 仅在明确并排双开模式下才附带隔离目录
        let parallelArgs = AntigravityLaunchConfig.launchArguments(
            for: nonDefaultProfile,
            targetApp: "/Applications/Antigravity.app",
            sharedExtensionsDir: "~/.antigravity/extensions",
            isParallelLaunch: true
        )
        expect(parallelArgs.contains { $0.contains("--user-data-dir") }, "双开模式必须携带独立隔离目录")
    }

    // 用例 23：环境初始化严禁向隔离目录复制带动态端口 zoom 缩放的 Preferences，杜绝双开分辨率错乱
    static func testEnsureProfileDirectoryDoesNotInjectZoomPreferences() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        // 模拟主环境带 1.5 zoom 的 Preferences
        let mainDir = "\(home)/Library/Application Support/Antigravity"
        let sourcePref = "\(mainDir)/Preferences"
        let dirtyPrefContent = "{\"partition\":{\"per_host_zoom_levels\":{\"1234\":{\"127.0.0.1\":1.5}}}}"
        try? dirtyPrefContent.write(toFile: sourcePref, atomically: true, encoding: .utf8)

        let profileDir = "\(home)/.agy-profiles/test@example.com"
        AntigravityLaunchConfig.cleanZoomContamination(in: profileDir)

        // 如果用户以前目录残留了带 zoom 的 Preferences，应被安全清除
        let fakeTargetPref = "\(profileDir)/Preferences"
        try? FileManager.default.createDirectory(atPath: profileDir, withIntermediateDirectories: true)
        try? dirtyPrefContent.write(toFile: fakeTargetPref, atomically: true, encoding: .utf8)

        AntigravityLaunchConfig.cleanZoomContamination(in: profileDir)
        let exists = FileManager.default.fileExists(atPath: fakeTargetPref)
        expect(!exists, "带 zoom 污染的 Preferences 应被清除，恢复 Chromium 默认原生系统 DPI")
    }

    // 用例 24：账号行悬停操作区裁决：去掉双开按钮与删除按钮，只保留单实例切换，防止横向撑爆抖动
    static func testProfileRowActionsHideParallelAndDeleteButtons() {
        expect(!ProfileRowActionPolicy.showsParallelLaunchButton, "账号行不得渲染「双开」按钮以节约横向空间")
        expect(!ProfileRowActionPolicy.showsDeleteButton, "账号行不得渲染「删除」按钮以节约横向空间")
    }

    // 用例 25：当前活跃账号排序置顶：目标模式当前账号排第 1，另一端活跃账号排第 2
    static func testAccountListSortsActiveAccountsFirst() {
        let profiles = [
            AGYProfile(name: "alice@example.com", email: "alice@example.com", userDataDir: "~/.agy-profiles/alice@example.com"),
            AGYProfile(name: "dave@example.com", email: "dave@example.com", userDataDir: "~/.agy-profiles/dave@example.com"),
            AGYProfile(name: "grace@example.com", email: "grace@example.com", userDataDir: "~/.agy-profiles/grace@example.com"),
            AGYProfile(name: "bob@example.com", email: "bob@example.com", userDataDir: "~/Library/Application Support/Antigravity", isDefault: true),
            AGYProfile(name: "frank@example.com", email: "frank@example.com", userDataDir: "~/.agy-profiles/frank@example.com")
        ]

        // 场景 A：App 模式，bob 是 App 当前，alice 是 CLI 当前
        let sortedApp = AccountSortOrder.sortedProfiles(
            profiles,
            mode: .app,
            effectiveAppEmail: "bob@example.com",
            activeProfileName: "bob@example.com",
            activeCLIProfileName: "alice@example.com",
            isSharedKeychainResolved: true
        )
        expectEqual(sortedApp.first?.name, "bob@example.com", "App 模式下当前 App 账号必须排在第 1 位")
        expectEqual(sortedApp[1].name, "alice@example.com", "App 模式下当前 CLI 账号应紧随其后排在第 2 位")

        // 场景 B：CLI 模式，alice 是 CLI 当前，bob 是 App 当前
        let sortedCLI = AccountSortOrder.sortedProfiles(
            profiles,
            mode: .cli,
            effectiveAppEmail: "bob@example.com",
            activeProfileName: "bob@example.com",
            activeCLIProfileName: "alice@example.com",
            isSharedKeychainResolved: true
        )
        expectEqual(sortedCLI.first?.name, "alice@example.com", "CLI 模式下当前 CLI 账号必须排在第 1 位")
        expectEqual(sortedCLI[1].name, "bob@example.com", "CLI 模式下当前 App 账号应紧随其后排在第 2 位")
    }

    // 用例 26：在 Agyhub 内主动切号（.agyhubSwitch）不视为偏移，仅后台 CLI 续期或外部篡改才判定偏移
    static func testKeychainDriftPolicyIgnoresIntentionalAgyhubSwitch() {
        let tApp = glogDate(11, 12, 19, 8, 5).timeIntervalSince1970
        let tSwitch = glogDate(11, 12, 22, 10, 20).timeIntervalSince1970

        // 场景 A：app_storage.json 仍是旧值 alice，但用户已在 Agyhub 主动切到 bob
        let switchState = CLIAccountManager.CLIActiveState(email: "bob@example.com", switchedAt: tSwitch)
        let expectedAfterSwitch = KeychainDriftPolicy.effectiveExpectedAppEmail(
            appStorageEmail: "alice@example.com",
            desktopAppAuthDate: Date(timeIntervalSince1970: tApp),
            expectedSwitchState: switchState
        )
        expectEqual(expectedAfterSwitch, "bob@example.com", "用户主动切号晚于主应用 OAuth 登录时，预期主应用账号应更新为 bob")

        let resolutionSwitch = CLIAccountManager.SharedKeychainResolution(
            email: "bob@example.com",
            source: .agyhubSwitch,
            eventDate: Date(timeIntervalSince1970: tSwitch),
            isTokenRefreshHijack: false
        )
        expect(
            !KeychainDriftPolicy.isUnexpectedDrift(expectedAppEmail: expectedAfterSwitch, resolution: resolutionSwitch),
            "Agyhub 主动切号不得误报主应用已偏移"
        )
        expect(
            !KeychainDriftPolicy.isUnexpectedDrift(expectedAppEmail: "alice@example.com", resolution: resolutionSwitch),
            "即使主应用预期仍停留旧引导值，source == .agyhubSwitch 也不应触发偏移告警"
        )

        // 场景 B：同名账号 CLI 后台正常续期（bob 续期 bob），不应误报
        let sameAccountRefresh = CLIAccountManager.SharedKeychainResolution(
            email: "bob@example.com",
            source: .cliRefresh,
            eventDate: Date(timeIntervalSince1970: tSwitch + 600),
            isTokenRefreshHijack: false
        )
        expect(
            !KeychainDriftPolicy.isUnexpectedDrift(expectedAppEmail: expectedAfterSwitch, resolution: sameAccountRefresh),
            "与预期主应用同账号的 CLI 续期不应视为偏移"
        )

        // 场景 C：后台旧 CLI 将共享钥匙串覆盖成另一账号 alice，必须真实告警
        let hijacked = CLIAccountManager.SharedKeychainResolution(
            email: "alice@example.com",
            source: .cliRefresh,
            eventDate: Date(timeIntervalSince1970: tSwitch + 1200),
            isTokenRefreshHijack: true
        )
        expect(
            KeychainDriftPolicy.isUnexpectedDrift(expectedAppEmail: expectedAfterSwitch, resolution: hijacked),
            "后台旧 CLI 续期覆盖成另一账号时必须触发主应用偏移告警"
        )
    }

    // 用例 27：独立 token 文件缺失时，CLI 当前使用账号必须回落共享钥匙串/CLI 日志，确保 CLI 标签可见
    static func testEffectiveActiveCLIProfileFallsBackToSharedKeychainWhenTokenFileMissing() {
        // 有独立 token 文件时优先采用独立文件账号
        expectEqual(
            CLIAccountManager.resolveActiveCLIProfileEmail(
                tokenFileEmail: "alice@example.com",
                sharedKeychainEmail: "bob@example.com",
                cliLogEmail: "dave@example.com",
                isIndependentMode: true
            ),
            "alice@example.com",
            "存在独立 CLI token 文件时，CLI 标签必须显示独立文件对应账号"
        )

        // 无独立 token 文件（常态本地终端直接走共享钥匙串）时，必须回落共享钥匙串账号
        expectEqual(
            CLIAccountManager.resolveActiveCLIProfileEmail(
                tokenFileEmail: nil,
                sharedKeychainEmail: "bob@example.com",
                cliLogEmail: nil,
                isIndependentMode: true
            ),
            "bob@example.com",
            "无独立 token 文件时，本地 agy 实际使用共享钥匙串，账号行必须展示 CLI 标签"
        )

        // 若共享钥匙串归属暂未解析但存在非文件模式 CLI 登录日志，也应展示 CLI 标签
        expectEqual(
            CLIAccountManager.resolveActiveCLIProfileEmail(
                tokenFileEmail: nil,
                sharedKeychainEmail: nil,
                cliLogEmail: "alice@example.com",
                isIndependentMode: true
            ),
            "alice@example.com",
            "无独立 token 文件且钥匙串未决时，应回落最近 CLI 非文件认证日志邮箱"
        )
    }

    // 用例 28：复现 22:56:06 真机现场：22:10 切到 bob 后，同账号 CLI 在 22:56 正常 token refreshed 使 kcMod 晚于 cli_active，仍不得误报偏移
    static func testSameAccountTokenRefreshAfterAgyhubSwitchIsNotDrift() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }
        let pRoot = "\(home)/.agy-profiles"

        let appStorage = "\(home)/Library/Application Support/Antigravity/app_storage.json"
        try? "{\"agy.onboarding.lastLoginUsername\":\"alice@example.com\"}".write(toFile: appStorage, atomically: true, encoding: .utf8)

        let lsLog = "\(home)/Library/Logs/Antigravity/language_server.log"
        try? "I1112 19:08:05.699621 58 server.go:4405] Auth succeeded, refreshing features and managers\n"
            .write(toFile: lsLog, atomically: true, encoding: .utf8)

        let tSwitch = glogDate(11, 12, 22, 10, 20).timeIntervalSince1970
        let cliActiveData = try! JSONEncoder().encode(CLIAccountManager.CLIActiveState(email: "bob@example.com", switchedAt: tSwitch))
        try? cliActiveData.write(to: URL(fileURLWithPath: "\(pRoot)/cli_active.json"))

        let cliLog = "\(home)/.gemini/antigravity-cli/log/cli-20261112_190805.log"
        let cliContent = """
        I1112 19:08:05.884625 395 server_oauth.go:221] applyAuthResult: email=bob@example.com, authMethod=consumer, quotaProject=
        I1112 22:56:06.345391 15007 browser.go:265] token refreshed, new expiry=2026-11-12 23:56:05
        """
        try? cliContent.write(toFile: cliLog, atomically: true, encoding: .utf8)

        let resolution = CLIAccountManager.resolveSharedKeychainOwner(
            homeDir: home,
            profilesRootDir: pRoot,
            keychainModDate: glogDate(11, 12, 22, 56, 6),
            hasActiveKeychain: true
        )
        let appAuthDate = CLIAccountManager.detectLatestDesktopAppAuthDate(homeDir: home)
        let switchState = KeychainDriftPolicy.resolveExpectedSwitchState(
            expectedAppState: CLIAccountManager.readExpectedAppStateFile(profilesRootDir: pRoot),
            cliActiveState: CLIAccountManager.readActiveStateFile(profilesRootDir: pRoot),
            resolution: resolution
        )
        let expected = KeychainDriftPolicy.effectiveExpectedAppEmail(
            appStorageEmail: "alice@example.com",
            desktopAppAuthDate: appAuthDate,
            expectedSwitchState: switchState
        )
        expectEqual(expected, "bob@example.com", "即使同账号 CLI 在切号后触发续期，预期主应用账号仍应保持为 bob")
        expect(
            !KeychainDriftPolicy.isUnexpectedDrift(expectedAppEmail: expected, resolution: resolution),
            "同账号 CLI 正常 token refreshed 不得误报原主应用 alice 被覆盖"
        )
    }

    // 用例 29：复现 22:10:12 -> 22:10:15 -> 22:10:20 启动期竞态事故：
    // Agyhub 在 22:10:12 切到 alice 并启动桌面端，22:10:15 LS 打印 Auth succeeded 时 app_storage.json 尚未落盘仍残留旧账号 bob，
    // 钥匙串 mtime 未离开 22:10:12 窗口，绝不能被旧 app_storage 抢占并反写污染 cli_active.json 为 bob。
    static func testSwitchStartupRaceDoesNotPoisonCLIActiveJson() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }
        let pRoot = "\(home)/.agy-profiles"

        let tSwitch = glogDate(11, 12, 22, 10, 12).timeIntervalSince1970
        let switchState = CLIAccountManager.CLIActiveState(email: "alice@example.com", switchedAt: tSwitch)
        let cliActiveData = try! JSONEncoder().encode(switchState)
        try? cliActiveData.write(to: URL(fileURLWithPath: "\(pRoot)/cli_active.json"))

        // Electron 尚未来得及覆盖旧 app_storage.json
        let appStorage = "\(home)/Library/Application Support/Antigravity/app_storage.json"
        try? "{\"agy.onboarding.lastLoginUsername\":\"bob@example.com\"}".write(toFile: appStorage, atomically: true, encoding: .utf8)

        // LS 在 +3s 后认证成功，但钥匙串修改时间仍在 22:10:12（切号本人写入）
        let lsLog = "\(home)/Library/Logs/Antigravity/language_server.log"
        try? "I1112 22:10:15.419355 182 server.go:4308] Auth succeeded, refreshing features and managers\n"
            .write(toFile: lsLog, atomically: true, encoding: .utf8)

        let resolution = CLIAccountManager.resolveSharedKeychainOwner(
            homeDir: home,
            profilesRootDir: pRoot,
            keychainModDate: glogDate(11, 12, 22, 10, 12),
            hasActiveKeychain: true
        )
        expectEqual(resolution.email, "alice@example.com", "切号刚启动且钥匙串未被外力改写时，绝不能被旧 app_storage 误判为 bob")
        expect(resolution.source == .agyhubSwitch, "归属来源仍应保持为 agyhubSwitch")

        // 防御二：即使出现 .desktopApp / .cliRefresh 结果，capture 阶段也不得在非显式外力登录时覆写 cli_active.json
        let desktopRaceResolution = CLIAccountManager.SharedKeychainResolution(
            email: "bob@example.com",
            source: .desktopApp,
            eventDate: Date(timeIntervalSince1970: tSwitch + 3.0),
            isTokenRefreshHijack: false
        )
        expect(
            !CLIAccountManager.shouldOverwriteActiveStateFile(currentState: switchState, resolution: desktopRaceResolution),
            "切号后窗口期内的 desktopApp 事件不得覆写 cli_active.json"
        )

        let cliHijackResolution = CLIAccountManager.SharedKeychainResolution(
            email: "bob@example.com",
            source: .cliRefresh,
            eventDate: Date(timeIntervalSince1970: tSwitch + 600.0),
            isTokenRefreshHijack: true
        )
        expect(
            !CLIAccountManager.shouldOverwriteActiveStateFile(currentState: switchState, resolution: cliHijackResolution),
            "后台旧 CLI 的 cliRefresh 劫持绝不能覆写用户的主动切号记录 cli_active.json"
        )
    }

    // 用例 30：配额刷新写回新 access_token 时，必须同时兼容 go-keyring-base64 前缀与纯 JSON，并保留 refresh_token 等其余字段
    static func testCredentialTokenUpdatePreservesGoKeyringBase64FormatAndRawJSON() {
        let raw = credentialJSON(email: "alice@example.com", accessToken: "old-tok")
        let expiry = Date(timeIntervalSince1970: 1800000000)

        // 1. 纯 JSON 更新
        guard let updatedRaw = AccountQuotaManager.updatingCredentialData(raw, newAccessToken: "new-tok-raw", newExpiry: expiry) else {
            expect(false, "纯 JSON 凭证应能成功更新 access_token")
            return
        }
        let parsedRaw = AccountQuotaManager.extractTokensFromCredentialData(updatedRaw)
        expectEqual(parsedRaw?.accessToken, "new-tok-raw", "更新后应读出新 access_token")
        expectEqual(parsedRaw?.refreshToken, "r-alice@example.com", "更新后应完整保留原 refresh_token")
        expectEqual(CLIAccountManager.credentialEmail(updatedRaw), "alice@example.com", "更新后应完整保留 id_token_email")

        // 2. go-keyring-base64 格式更新
        let prefixed = ("go-keyring-base64:" + raw.base64EncodedString()).data(using: .utf8)!
        guard let updatedPrefixed = AccountQuotaManager.updatingCredentialData(prefixed, newAccessToken: "new-tok-kc", newExpiry: expiry),
              let text = String(data: updatedPrefixed, encoding: .utf8) else {
            expect(false, "go-keyring-base64 凭证应能成功更新并保留编码前缀")
            return
        }
        expect(text.hasPrefix("go-keyring-base64:"), "更新后必须保留 go-keyring-base64: 前缀供 agy CLI 正常解码")
        let parsedPrefixed = AccountQuotaManager.extractTokensFromCredentialData(updatedPrefixed)
        expectEqual(parsedPrefixed?.accessToken, "new-tok-kc", "go-keyring-base64 更新后应能解出新 access_token")
        expectEqual(parsedPrefixed?.refreshToken, "r-alice@example.com", "go-keyring-base64 更新后应保留 refresh_token")
    }

    // 用例 31：401 刷新拿到新 access_token 后必须持久化回保险箱与 CLI token 文件，杜绝每分钟重复调用 OAuth /token；失败后应退避
    static func testQuotaRefreshPersistsNewTokenBackToVaultAndTokenFile() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        // A. 保险箱路径持久化测试
        let mv = MemoryVault()
        let oldVaultRaw = credentialJSON(email: "alice@example.com", accessToken: "expired-vault-tok")
        let oldVaultEncoded = ("go-keyring-base64:" + oldVaultRaw.base64EncodedString()).data(using: .utf8)!
        mv.slots["alice@example.com"] = oldVaultEncoded

        // B. CLI token 文件持久化测试
        let cliRaw = credentialJSON(email: "bob@example.com", accessToken: "expired-cli-tok")
        _ = CLIAccountManager.writeCLITokenFile(cliRaw, homeDir: home)

        let sampleQuota = """
        {"groups":[{"displayName":"Gemini","buckets":[{"window":"weekly","remainingFraction":0.75}]}]}
        """.data(using: .utf8)!

        let sem = DispatchSemaphore(value: 0)
        var vaultRefreshCalls = 0
        var seenVaultTokens: [String] = []
        var cliRefreshCalls = 0
        var seenCLITokens: [String] = []

        Task {
            // 第 1 次拉取 alice（保险箱）：old -> 401 -> refresh -> new -> 200 并回写 vault
            let s1 = await AccountQuotaManager.fetchAccountQuota(
                email: "alice@example.com",
                tier: nil,
                homeDir: home,
                vault: mv.vault,
                requestQuota: { token in
                    seenVaultTokens.append(token)
                    return token == "expired-vault-tok" ? (nil, 401) : (sampleQuota, 200)
                },
                refreshToken: { _ in
                    vaultRefreshCalls += 1
                    return ("fresh-vault-tok", 3599)
                }
            )
            expect(s1 != nil, "保险箱 401 刷新后应成功返回配额")

            // 第 2 次拉取 alice（模拟下一轮 60s 轮询）：必须直接命中 fresh-vault-tok，不得再次刷 /token
            let s2 = await AccountQuotaManager.fetchAccountQuota(
                email: "alice@example.com",
                tier: nil,
                homeDir: home,
                vault: mv.vault,
                requestQuota: { token in
                    seenVaultTokens.append(token)
                    return token == "fresh-vault-tok" ? (sampleQuota, 200) : (nil, 401)
                },
                refreshToken: { _ in
                    vaultRefreshCalls += 1
                    return ("should-not-happen", 3599)
                }
            )
            expect(s2 != nil, "第 2 次拉取应直接复用落盘的新 access_token")

            // CLI token 文件场景同理
            let c1 = await AccountQuotaManager.fetchAccountQuota(
                email: "bob@example.com",
                tier: nil,
                homeDir: home,
                vault: mv.vault,
                requestQuota: { token in
                    seenCLITokens.append(token)
                    return token == "expired-cli-tok" ? (nil, 401) : (sampleQuota, 200)
                },
                refreshToken: { _ in
                    cliRefreshCalls += 1
                    return ("fresh-cli-tok", 3599)
                }
            )
            expect(c1 != nil, "CLI token 文件 401 刷新后应成功返回配额")
            let fileData = FileManager.default.contents(atPath: CLIAccountManager.cliTokenFilePath(homeDir: home))
            expectEqual(
                fileData.flatMap { AccountQuotaManager.extractTokensFromCredentialData($0)?.accessToken },
                "fresh-cli-tok",
                "CLI token 文件落盘后应包含最新 access_token"
            )
            sem.signal()
        }
        sem.wait()

        expectEqual(vaultRefreshCalls, 1, "保险箱刷新后持久化成功，两轮配额请求只允许调 1 次 OAuth /token")
        expectEqual(seenVaultTokens, ["expired-vault-tok", "fresh-vault-tok", "fresh-vault-tok"], "第二轮应直接用 fresh-vault-tok 请求配额")
        expectEqual(cliRefreshCalls, 1, "CLI token 文件刷新后持久化成功，只允许调 1 次 OAuth /token")

        // 失败退避策略验证：失败后 60 秒内不应像旧逻辑那样每 5 秒重试，至少退避 300 秒
        let now = Date(timeIntervalSince1970: 1700000000)
        expect(
            !AccountQuotaManager.shouldAttemptQuotaFetch(
                lastSuccess: nil,
                lastFailure: now.addingTimeInterval(-60),
                now: now
            ),
            "配额拉取失败后 60 秒内必须退避，严禁每 5 秒轮询猛打 OAuth"
        )
        expect(
            AccountQuotaManager.shouldAttemptQuotaFetch(
                lastSuccess: nil,
                lastFailure: now.addingTimeInterval(-305),
                now: now
            ),
            "超过 300 秒退避窗口后应允许恢复尝试"
        )
    }

    // 用例 32：切号时同步更新 app_storage.json 的 lastLoginUsername，避免每次切号弹出 "One last thing" 引导框，且不破坏其它配置项
    static func testSyncOnboardingUsernameUpdatesAppStorageWithoutDroppingOtherKeys() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }
        let mainDir = "\(home)/Library/Application Support/Antigravity"
        let storagePath = "\(mainDir)/app_storage.json"

        // 若文件尚未存在（首次安装），不凭空创建干扰首次引导
        AntigravityLaunchConfig.syncOnboardingUsername("alice@example.com", in: mainDir)
        expect(!FileManager.default.fileExists(atPath: storagePath), "app_storage.json 不存在时不应凭空创建")

        let initial: [String: Any] = [
            "agy.onboarding.lastLoginUsername": "bob@example.com",
            "agy.onboarding.lastLoginIsGcpTos": "false",
            "ide-install-wizard-shown": "true",
            "customNumericSetting": 42
        ]
        let rawData = try! JSONSerialization.data(withJSONObject: initial, options: [.sortedKeys])
        try! rawData.write(to: URL(fileURLWithPath: storagePath))

        AntigravityLaunchConfig.syncOnboardingUsername("alice@example.com", in: mainDir)

        let updatedData = try! Data(contentsOf: URL(fileURLWithPath: storagePath))
        let updated = try! JSONSerialization.jsonObject(with: updatedData) as! [String: Any]
        expectEqual(updated["agy.onboarding.lastLoginUsername"] as? String, "alice@example.com", "切号后应同步更新 lastLoginUsername 为目标账号")
        expectEqual(updated["agy.onboarding.lastLoginIsGcpTos"] as? String, "false", "不得丢失 lastLoginIsGcpTos")
        expectEqual(updated["ide-install-wizard-shown"] as? String, "true", "不得丢失其余 Antigravity 配置项")
        expectEqual(updated["customNumericSetting"] as? Int, 42, "不得丢失非字符串自定义配置项")
    }

    // 用例 33：即使共享钥匙串已被后台 CLI 漂移为 bob，UI 显示“当前 App / [App]”时仍必须准确展示实际运行的预期桌面账号 alice
    static func testDisplayAppEmailPrefersExpectedRunningAppOverDriftedKeychain() {
        let resolved = AccountDisplayPolicy.effectiveRunningAppEmail(
            expectedAppEmail: "alice@example.com",
            appStorageEmail: "alice@example.com",
            sharedKeychainEmail: "bob@example.com",
            activeProfileName: "bob@example.com"
        )
        expectEqual(resolved, "alice@example.com", "共享钥匙串漂移到 bob 时，UI 当前 App 仍必须标示正在运行的 alice，而非把 bob 当成 App")

        let fallback = AccountDisplayPolicy.effectiveRunningAppEmail(
            expectedAppEmail: "",
            appStorageEmail: "",
            sharedKeychainEmail: "bob@example.com",
            activeProfileName: "dave@example.com"
        )
        expectEqual(fallback, "bob@example.com", "当尚无桌面端引导与预期记录时，才回落到共享钥匙串邮箱")
    }

    // 用例 34：复现 08:27 真机 Bug —— language_server.log 在 Auth succeeded 之后狂刷超过 220KB（突破原 128KB 限制）时，仍必须准确扫出最近一次登录时间
    static func testDetectLatestDesktopAppAuthDateScansBeyond128KB() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }
        let logDir = "\(home)/Library/Logs/Antigravity"
        try! FileManager.default.createDirectory(atPath: logDir, withIntermediateDirectories: true)
        let logPath = "\(logDir)/language_server.log"

        var content = "ERROR: logging before google.Init: I1113 08:19:15.100000 160 server.go:4308] Auth succeeded, refreshing features and managers\n"
        content += "ERROR: logging before google.Init: I1113 08:24:14.359773 36005 server.go:4308] Auth succeeded, refreshing features and managers\n"
        // 紧随其后追加超过 350KB 噪音日志，把 Auth succeeded 推到距离文件尾 >350KB 的位置（远超原 128KB）
        let noiseLine = "ERROR: logging before google.Init: W1113 08:27:05.000000 673 extract_searchable_content.go:50] conversationsearch: loading trajectory dummy-padding-uuid-0000 not found in any store\n"
        content += String(repeating: noiseLine, count: 2400)
        try! content.write(toFile: logPath, atomically: true, encoding: .utf8)

        let detected = CLIAccountManager.detectLatestDesktopAppAuthDate(homeDir: home)
        let expected = glogDate(11, 13, 8, 24, 14)
        expect(detected != nil, "超过 128KB 噪音后仍必须能扫描到 Auth succeeded 时间")
        if let dt = detected {
            expect(abs(dt.timeIntervalSince(expected)) < 2.0, "应精确返回 08:24:14 的最新 Auth 时间，而不是更早的 08:19:15 或 nil")
        }
    }

    // 用例 35：用户在 App 内手工 Sign Out 登录新账号（超过切号 30 秒保护窗）时，必须同步推进 app_expected.json，避免继续死守旧账号
    static func testSyncedExpectedAppStateAdvancesOnManualDesktopLoginOnlyAfterSwitchWindow() {
        let tExpected = glogDate(11, 13, 7, 54, 43).timeIntervalSince1970
        let existing = CLIAccountManager.CLIActiveState(email: "alice@example.com", switchedAt: tExpected)

        // 1. 刚切号后 10 秒窗内，即使 app_storage 仍旧写着别的邮箱也不得覆盖 app_expected.json
        let withinWindow = KeychainDriftPolicy.syncedExpectedAppStateAfterDesktopLogin(
            existingExpected: existing,
            appStorageEmail: "dave@example.com",
            desktopAppAuthDate: Date(timeIntervalSince1970: tExpected + 10.0)
        )
        expect(withinWindow == nil, "切号 30 秒保护窗内不得误覆盖 app_expected.json")

        // 2. 用户半小时后（08:24:14）在 App 内手工登录 dave，必须推进为 dave
        let tManualLogin = glogDate(11, 13, 8, 24, 14)
        let advanced = KeychainDriftPolicy.syncedExpectedAppStateAfterDesktopLogin(
            existingExpected: existing,
            appStorageEmail: "dave@example.com",
            desktopAppAuthDate: tManualLogin
        )
        expectEqual(advanced?.email, "dave@example.com", "App 内手工登录新账号且晚于切号保护窗时，app_expected.json 必须同步推进至新账号")
    }

    // 用例 36：会话列表的 CLI 来源小标记：CLI 会话返回清晰 "CLI" 标签，App/未知来源不打标记
    static func testSessionItemCLIBadgeLabelForCLIAndApp() {
        func decodeSession(clientTypeJSON: String) -> SessionItem {
            let json = """
            {
                "uuid": "u-1",
                "short_id": "u-1",
                \(clientTypeJSON)
                "title": "测试会话",
                "is_running": false,
                "interactions": 1,
                "input_tokens": 10,
                "cache_tokens": 0,
                "output_tokens": 10,
                "context_tokens": 20,
                "cache_pct": 0.0,
                "tps": 0.0,
                "total_tokens_consumed": 20,
                "total_cost_usd": 0.01,
                "total_cache_consumed": 0,
                "total_input_consumed": 10,
                "total_output_consumed": 10,
                "current_stall": 0.0,
                "health": "good",
                "health_desc": "良好",
                "current_phase": "idle",
                "current_action": "idle",
                "history_steps": [],
                "exists": true,
                "model": "gemini",
                "total_active_sec": 1.0,
                "total_local_sec": 0.5,
                "total_remote_sec": 0.5,
                "total_error_sec": 0.0,
                "breakdown_str": "1.0s"
            }
            """
            return try! JSONDecoder().decode(SessionItem.self, from: json.data(using: .utf8)!)
        }

        let cliSession = decodeSession(clientTypeJSON: "\"client_type\": \"cli\",")
        expect(cliSession.isCLISession, "client_type == cli 应识别为 CLI 会话")
        expectEqual(cliSession.cliBadgeLabel, "CLI", "CLI 会话必须生成 CLI 小标记文本")

        let cliUpper = decodeSession(clientTypeJSON: "\"client_type\": \"CLI\",")
        expect(cliUpper.isCLISession, "大小写变体 CLI 也应识别为 CLI 会话")
        expectEqual(cliUpper.cliBadgeLabel, "CLI", "大小写变体 CLI 也应生成 CLI 小标记文本")

        let appSession = decodeSession(clientTypeJSON: "\"client_type\": \"app\",")
        expect(!appSession.isCLISession, "app 会话不应识别为 CLI")
        expect(appSession.cliBadgeLabel == nil, "app 会话不显示 CLI 小标记")

        let nilSession = decodeSession(clientTypeJSON: "")
        expect(!nilSession.isCLISession, "缺失 client_type 时默认视为 app 会话")
        expect(nilSession.cliBadgeLabel == nil, "缺失 client_type 时不显示 CLI 小标记")
    }

    // 用例 37：会话标题悬浮自动滚动（跑马灯）阈值与时长计算验证
    static func testSessionTitleMarqueePolicyCalculations() {
        // 1. 标题未超出可用宽度（或仅 1pt 浮点误差）时不触发滚动
        expectEqual(
            SessionTitleMarqueePolicy.overflowDistance(textWidth: 120, containerWidth: 160),
            0.0,
            "未截断标题溢出量应为 0"
        )
        expect(
            !SessionTitleMarqueePolicy.shouldScroll(isHovered: true, textWidth: 161, containerWidth: 160),
            "极小宽度误差内不应误触发抖动滚动"
        )

        // 2. 标题真实溢出且悬浮时触发滚动，离开悬浮立即停止
        let overflow = SessionTitleMarqueePolicy.overflowDistance(textWidth: 230, containerWidth: 160)
        expectEqual(overflow, 70.0, "应精确返回溢出宽度 70pt")
        expect(
            SessionTitleMarqueePolicy.shouldScroll(isHovered: true, textWidth: 230, containerWidth: 160),
            "长标题被截断且鼠标悬浮时应开启自动滚动"
        )
        expect(
            !SessionTitleMarqueePolicy.shouldScroll(isHovered: false, textWidth: 230, containerWidth: 160),
            "鼠标未悬浮时严禁自顾自滚动"
        )

        // 3. 滚动时长随溢出距离合理缩放并具备最低保底时间
        let shortDuration = SessionTitleMarqueePolicy.scrollDuration(overflowDistance: 10)
        let longDuration = SessionTitleMarqueePolicy.scrollDuration(overflowDistance: 140)
        expect(shortDuration >= 1.2, "短溢出应保留最低可读时长防止闪现过快")
        expect(longDuration > shortDuration, "更长标题应分配更长滚动时间保持匀速阅读感")

        // 4. 基于时间轴的跑马灯偏移曲线：起始停顿 -> 线性左移展示末尾 -> 末尾停顿 -> 平滑回位
        let travel = SessionTitleMarqueePolicy.scrollDuration(overflowDistance: 60)
        let maxShift = -(60.0 + SessionTitleMarqueePolicy.trailingRevealPadding)
        expectEqual(
            SessionTitleMarqueePolicy.marqueeOffset(elapsed: 0.0, overflowDistance: 60),
            0.0,
            "刚悬浮时应先停顿展示标题开头，偏移为 0"
        )
        let midOffset = SessionTitleMarqueePolicy.marqueeOffset(
            elapsed: SessionTitleMarqueePolicy.edgePauseDuration + travel * 0.5,
            overflowDistance: 60
        )
        expect(midOffset < -10.0 && midOffset > maxShift + 5.0, "滚动中段应平滑处于中间偏移 (midOffset=\(midOffset))")
        let endPauseOffset = SessionTitleMarqueePolicy.marqueeOffset(
            elapsed: SessionTitleMarqueePolicy.edgePauseDuration + travel + 0.1,
            overflowDistance: 60
        )
        expectEqual(endPauseOffset, maxShift, "滚到最右侧时应在末尾停顿以展示完整尾部文字")
    }

    // 用例 38：防回归 —— 超长会话标题（无论静态截断还是悬浮滚动）绝不能撑破 464pt 弹窗宽度导致左右裁切
    static func testScrollingSessionTitleDoesNotExpandRowWidth() {
        let longTitle = String(repeating: "AnalyzingCodexPluginPromoVideoLongTitle", count: 6)
        let json = """
        {
            "uuid": "long-title-session-001",
            "short_id": "long-1",
            "client_type": "cli",
            "title": "\(longTitle)",
            "is_running": false,
            "interactions": 1,
            "input_tokens": 10,
            "cache_tokens": 0,
            "output_tokens": 10,
            "context_tokens": 20,
            "cache_pct": 98.0,
            "tps": 0.0,
            "total_tokens_consumed": 3400000,
            "total_cost_usd": 0.01,
            "total_cache_consumed": 0,
            "total_input_consumed": 10,
            "total_output_consumed": 10,
            "current_stall": 0.0,
            "health": "good",
            "health_desc": "良好",
            "current_phase": "idle",
            "current_action": "idle",
            "history_steps": [],
            "exists": true,
            "model": "3.8-flash-n",
            "total_active_sec": 1.0,
            "total_local_sec": 0.5,
            "total_remote_sec": 0.5,
            "total_error_sec": 0.0,
            "breakdown_str": "1.0s"
        }
        """.data(using: .utf8)!
        let session = try! JSONDecoder().decode(SessionItem.self, from: json)

        let rowHost = NSHostingView(rootView: CompactSessionRowView(session: session))
        let fittingWidth = rowHost.fittingSize.width
        expect(
            fittingWidth <= 260,
            "长标题行最小/理想宽度不应被 fixedSize 文本撑大到超过固定列宽之和，否则会撑爆 464pt 弹窗导致左右裁切 (fittingWidth=\(fittingWidth))"
        )

        let constrainedRowHost = NSHostingView(
            rootView: CompactSessionRowView(session: session).frame(width: 436)
        )
        let constrainedWidth = constrainedRowHost.fittingSize.width
        expect(
            constrainedWidth <= 436.5,
            "受限于 436pt 列表宽度时整行实际渲染宽不得越界 (constrainedWidth=\(constrainedWidth))"
        )
    }

    // 用例 39：会话行模型胶囊缩小（较原 88pt/10pt 更紧凑）与上下文 xxxk 胶囊格式化与布局防越界
    static func testSessionRowCapsuleBadgesAndContextFormatting() {
        // 1. 模型名裁剪与兜底（缺失模型时不渲染空胶囊边框）
        expectEqual(SessionRowBadgePolicy.modelBadgeText("gemini-4-hydrogen"), "4-hydrogen", "应去除 gemini- 前缀")
        expectEqual(SessionRowBadgePolicy.modelBadgeText("gemini-3.8-flash-q"), "3.8-flash-q", "应保留 3.8-flash-q")
        expectEqual(SessionRowBadgePolicy.modelBadgeText("gemini-pro-orchestrator-g1-pro"), "argon-orch", "编排模型应映射为短促的 argon-orch")
        expectEqual(SessionRowBadgePolicy.modelBadgeText("pro-orchestrator-g1-pro"), "argon-orch", "无 gemini- 前缀的编排模型也应映射为 argon-orch")
        expectEqual(SessionRowBadgePolicy.modelBadgeText("gemini-flash-orchestrator-g1"), "flash-orch", "Flash 编排模型应映射为 flash-orch")
        expectEqual(SessionRowBadgePolicy.modelBadgeText(""), "-", "空模型名应兜底为 -")
        expectEqual(SessionRowBadgePolicy.modelBadgeText("-"), "-", "横杠模型名应保持 -")
        expect(SessionRowBadgePolicy.hasModel("gemini-4-hydrogen"), "有效模型名应标记为有模型")
        expect(!SessionRowBadgePolicy.hasModel("-"), "横杠占位不应渲染模型胶囊")
        expect(!SessionRowBadgePolicy.hasModel(""), "空字符串不应渲染模型胶囊")

        // 2. 上下文 xxxk 文案格式化
        expectEqual(SessionRowBadgePolicy.contextBadgeText(contextTokens: 0), "-", "0 上下文应显示为 -")
        expectEqual(SessionRowBadgePolicy.contextBadgeText(contextTokens: -10), "-", "负数上下文应兜底为 -")
        expectEqual(SessionRowBadgePolicy.contextBadgeText(contextTokens: 850), "850", "不足 1k 应显示原始数值")
        expectEqual(SessionRowBadgePolicy.contextBadgeText(contextTokens: 50740), "51k", "50740 应格式化为 51k")
        expectEqual(SessionRowBadgePolicy.contextBadgeText(contextTokens: 141591), "142k", "141591 应格式化为 142k")
        expectEqual(SessionRowBadgePolicy.contextBadgeText(contextTokens: 1_200_000), "1.2M", "超过 1M 应格式化为 1.2M")

        // 3. 模型胶囊确实缩小（小于原先的 88pt 列宽和 10pt 字号），且模型与上下文使用独立字号与列宽
        expect(SessionRowBadgePolicy.modelColumnWidth < 88, "模型胶囊列宽应比原先 88pt 更小")
        expect(SessionRowBadgePolicy.modelFontSize < 10, "模型胶囊字号应比原先 10pt 更小")
        expect(SessionRowBadgePolicy.contextFontSize < 10, "上下文胶囊字号应比原先 10pt 更小")
        expect(SessionRowBadgePolicy.contextColumnWidth > 0, "上下文胶囊应具备独立列宽")

        // 4. 带长模型名 + 大上下文（如 245k）+ 长标题渲染不撑爆 436pt 行宽
        let session = SessionItem(
            uuid: "capsule-test-001",
            title: String(repeating: "LongSessionTitle", count: 8),
            isRunning: false,
            contextTokens: 244667,
            cachePct: 98.0,
            totalTokensConsumed: 298_800_000,
            model: "gemini-3.8-flash-q"
        )
        let rowHost = NSHostingView(rootView: CompactSessionRowView(session: session))
        let fittingWidth = rowHost.fittingSize.width
        expect(
            fittingWidth <= 260,
            "新增上下文胶囊后行最小宽度仍应控制在 260pt 以内 (fittingWidth=\(fittingWidth))"
        )

        // 5. 即使出现未预见的超长模型名，模型胶囊也必须被约束在 modelColumnWidth 内截断，不能向左挤占或覆盖标题
        let ultraLongModelSession = SessionItem(
            uuid: "capsule-test-002",
            title: String(repeating: "LongSessionTitle", count: 8),
            isRunning: false,
            contextTokens: 236596,
            cachePct: 95.0,
            totalTokensConsumed: 2_700_000,
            model: "gemini-experimental-super-long-unmapped-model-v99-ultra"
        )
        let longModelHost = NSHostingView(rootView: CompactSessionRowView(session: ultraLongModelSession))
        expect(
            longModelHost.fittingSize.width <= 260,
            "超长模型名不得借助 fixedSize 突破 70pt 列宽撑宽整行或压盖标题 (fittingWidth=\(longModelHost.fittingSize.width))"
        )
    }

    // 用例 40：writeCLITokenFile 必须拒绝缺少有效 access_token 的残缺凭证，且配额刷新回写必须保持 0600 权限并不跨账号倒盖
    static func testWriteCLITokenFileRejectsMissingAccessTokenAndPersists0600() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        let valid = credentialJSON(email: "alice@example.com", accessToken: "ya29.GOOD")
        expect(CLIAccountManager.writeCLITokenFile(valid, homeDir: home), "有效凭证应允许写入")

        let invalidEmptyTok = """
        {"token":{"access_token":"","refresh_token":"r-alice"},"auth_method":"consumer","id_token_email":"dave@example.com"}
        """.data(using: .utf8)!
        expect(!CLIAccountManager.writeCLITokenFile(invalidEmptyTok, homeDir: home), "access_token 为空的残缺凭证必须被拒绝，不能覆盖好文件")

        let path = CLIAccountManager.cliTokenFilePath(homeDir: home)
        expectEqual(FileManager.default.contents(atPath: path), valid, "被拒绝写入后，原有效文件必须毫发无损")

        // 模拟 401 刷新写回后权限仍保持 0600，且若等待刷新期间磁盘文件已被切到另一账号则不倒盖
        let sem = DispatchSemaphore(value: 0)
        let mv = MemoryVault()
        let sampleQuota = """
        {"groups":[{"displayName":"Gemini","buckets":[{"window":"weekly","remainingFraction":0.8}]}]}
        """.data(using: .utf8)!
        Task {
            _ = await AccountQuotaManager.fetchAccountQuota(
                email: "alice@example.com",
                tier: nil,
                homeDir: home,
                vault: mv.vault,
                requestQuota: { token in
                    return token == "ya29.GOOD" ? (nil, 401) : (sampleQuota, 200)
                },
                refreshToken: { _ in
                    return ("ya29.NEW_TOK", 3599)
                }
            )
            let perm = (try? FileManager.default.attributesOfItem(atPath: path)[.posixPermissions] as? NSNumber)?.intValue
            expectEqual(perm, 0o600, "配额刷新写回 CLI token 文件后权限仍必须为 0600")

            // 模拟刷新过程中外部切走了账号：写回绝不能把 dave 倒盖成 alice
            let switched = credentialJSON(email: "dave@example.com", accessToken: "ya29.DAVE")
            _ = CLIAccountManager.writeCLITokenFile(switched, homeDir: home)
            _ = await AccountQuotaManager.fetchAccountQuota(
                email: "alice@example.com",
                tier: nil,
                homeDir: home,
                vault: mv.vault,
                requestQuota: { _ in (nil, 401) },
                refreshToken: { _ in ("ya29.STALE", 3599) }
            )
            expectEqual(CLIAccountManager.readCLITokenFileEmail(homeDir: home), "dave@example.com", "已有其它账号文件时，不应被旧请求回写覆盖")
            sem.signal()
        }
        sem.wait()
    }

    // 用例 41：独立模式下 token 文件缺失或变成 0 字节/损坏 JSON 时，应自动从 cli-vault 按优先级恢复；已有有效文件时不误覆盖
    static func testEnsureCLITokenFileIfNeededRecoversMissingOrCorruptedFileFromVault() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }
        let profilesRoot = "\(home)/.agy-profiles"
        let path = CLIAccountManager.cliTokenFilePath(homeDir: home)

        let mem = MemoryVault()
        let aliceRaw = credentialJSON(email: "alice@example.com", accessToken: "ya29.ALICE")
        let aliceWrapped = ("go-keyring-base64:" + aliceRaw.base64EncodedString()).data(using: .utf8)!
        let daveRaw = credentialJSON(email: "dave@example.com", accessToken: "ya29.DAVE")
        mem.slots["alice@example.com"] = aliceWrapped
        mem.slots["dave@example.com"] = daveRaw

        // A. 文件缺失，cli_active.json 指向 alice -> 优先恢复 alice，权限 0600
        CLIAccountManager.writeActiveStateFile(email: "alice@example.com", profilesRootDir: profilesRoot)
        let recoveredA = CLIAccountManager.ensureCLITokenFileIfNeeded(
            homeDir: home,
            profilesRootDir: profilesRoot,
            preferredEmails: ["dave@example.com"],
            vault: mem.vault
        )
        expectEqual(recoveredA, "alice@example.com", "文件缺失时应按 cli_active.json 优先恢复 alice")
        expectEqual(FileManager.default.contents(atPath: path), aliceRaw, "恢复出的文件必须是解码后的纯 JSON")
        let perm = (try? FileManager.default.attributesOfItem(atPath: path)[.posixPermissions] as? NSNumber)?.intValue
        expectEqual(perm, 0o600, "自动恢复的文件权限必须是 0600")

        // B. 文件被截断成 0 字节且无 cli_active.json -> 应按 preferredEmails 恢复 dave
        try? FileManager.default.removeItem(atPath: "\(profilesRoot)/cli_active.json")
        try? Data().write(to: URL(fileURLWithPath: path))
        let recoveredB = CLIAccountManager.ensureCLITokenFileIfNeeded(
            homeDir: home,
            profilesRootDir: profilesRoot,
            preferredEmails: ["dave@example.com"],
            vault: mem.vault
        )
        expectEqual(recoveredB, "dave@example.com", "0 字节空文件应被识别为损坏并自动从 preferredEmails 槽位修复")
        expectEqual(FileManager.default.contents(atPath: path), daveRaw, "修复后内容应为 dave 凭证")

        // C. 文件当前有效（bob） -> 绝不能被 cli_active 或 preferredEmails 覆盖
        let bobRaw = credentialJSON(email: "bob@example.com", accessToken: "ya29.BOB")
        _ = CLIAccountManager.writeCLITokenFile(bobRaw, homeDir: home)
        let kept = CLIAccountManager.ensureCLITokenFileIfNeeded(
            homeDir: home,
            profilesRootDir: profilesRoot,
            preferredEmails: ["dave@example.com"],
            vault: mem.vault
        )
        expectEqual(kept, "bob@example.com", "已有有效文件时必须保持原样")
        expectEqual(FileManager.default.contents(atPath: path), bobRaw, "有效文件内容不可被自愈误改")
    }

    // 用例 42：终端登录命令必须包含 SSH_CLIENT=1 与 acp --login（支持在已有 token 文件时直接安全覆写，无需先删文件）
    static func testCliFileModeCommandUsesAcpLoginFlag() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }
        let cmd = AGYHubStore.buildCLIFileModeLoginCommand(homeDir: home)
        expect(cmd.hasPrefix("\(CLIAccountManager.fileTokenModeEnv) "), "登录命令必须带有 SSH_CLIENT=1 前缀")
        expect(cmd.contains(" acp --login"), "登录命令必须使用 acp --login 原地授权覆写，不依赖提前删文件 (cmd=\(cmd))")
    }

    // 用例 43：配额请求必须使用 Antigravity Hub 2.31.2+ User-Agent 以使后端返回 Gemini 4 Argon 组，且组顺序互换也不混淆
    static func testQuotaRequestUsesHubUserAgentForArgonSupport() {
        let req = AccountQuotaManager.buildQuotaRequest(token: "ya29.TEST")
        let ua = req?.value(forHTTPHeaderField: "User-Agent") ?? ""
        expect(ua.hasPrefix("antigravity/hub/2.31."), "User-Agent 必须包含 antigravity/hub/2.31.x 前缀以获取 Gemini 4 Argon 配额 (ua=\(ua))")
        expect(ua.contains("os_type=darwin"), "User-Agent 必须携带平台信息 (ua=\(ua))")

        // 当 Gemini 4 Argon 排在 Gemini Models 之前时也应各自独立提取
        let reversedJSON = """
        {
          "groups": [
            {
              "displayName": "Gemini 4 Argon",
              "buckets": [{"bucketId": "gemini-argon-wtu-weekly", "window": "weekly", "resetTime": "2026-11-19T10:13:38Z", "remainingFraction": 0.9384851}]
            },
            {
              "displayName": "Gemini Models",
              "buckets": [{"bucketId": "gemini-weekly", "window": "weekly", "resetTime": "2026-11-14T12:56:53Z", "remainingFraction": 0.623546}]
            }
          ]
        }
        """
        let summary = reversedJSON.data(using: .utf8).flatMap {
            AccountQuotaManager.parseQuotaSummary(data: $0, email: "alice@example.com", tier: "Google AI Pro")
        }
        expectEqual(summary?.geminiQuota?.percentage, 62, "顺序调换时 Gemini 应为 62%")
        expectEqual(summary?.argonQuota?.percentage, 94, "顺序调换时 Argon 应为 94%")
        expectEqual(summary?.argonQuota?.resetTimeStr, "2026-11-19T10:13:38Z", "顺序调换时 Argon 重置时间应为 2026-11-19T10:13:38Z")
    }

    // 用例 44：遵循 macOS 原生退出与启动 —— 剥离父进程脏环境变量、仅向 .regular 主应用发退出请求、等待时间覆盖 Electron 5s 收尾窗口、可清理悬空孤儿锁软链
    static func testNativeMacOSLaunchConfigFiltersHelpersSanitizesEnvAndAllowsFullShutdownWindow() {
        // 1. 环境变量净化：必须剥离 ANTIGRAVITY_*、API Key 与终端污染变量，还原 LaunchServices 极简 GUI 白名单
        let dirtyEnv: [String: String] = [
            "HOME": "/tmp/testuser",
            "USER": "testuser",
            "LOGNAME": "testuser",
            "SHELL": "/bin/zsh",
            "TMPDIR": "/var/folders/xx/T/",
            "SSH_AUTH_SOCK": "/private/tmp/com.apple.launchd.abc/Listeners",
            "__CF_USER_TEXT_ENCODING": "0x1F5:0x19:0x34",
            "PATH": "/opt/homebrew/bin:/tmp/testuser/.nvm/versions/node/v22/bin:/usr/bin",
            "ANTIGRAVITY_AGENT": "1",
            "ANTIGRAVITY_LS_ADDRESS": "127.0.0.1:51234",
            "ANTIGRAVITY_APP_DATA_DIR": "/tmp/testuser/.gemini/antigravity",
            "ANTIGRAVITY_PROJECT_ID": "proj-123",
            "AGY_BROWSER_WS_URL": "ws://127.0.0.1:9222",
            "GEMINI_API_KEY": "AIza-secret",
            "DISABLE_AUTO_UPDATE": "true",
            "NVM_BIN": "/tmp/testuser/.nvm/bin",
            "SSH_CLIENT": "1"
        ]
        let cleanEnv = AntigravityLaunchConfig.sanitizedLaunchEnvironment(from: dirtyEnv)
        expectEqual(cleanEnv["HOME"], "/tmp/testuser", "必须保留 HOME")
        expectEqual(cleanEnv["USER"], "testuser", "必须保留 USER")
        expectEqual(cleanEnv["LOGNAME"], "testuser", "必须保留 LOGNAME")
        expectEqual(cleanEnv["SHELL"], "/bin/zsh", "必须保留 SHELL")
        expectEqual(cleanEnv["TMPDIR"], "/var/folders/xx/T/", "必须保留 TMPDIR")
        expectEqual(cleanEnv["SSH_AUTH_SOCK"], "/private/tmp/com.apple.launchd.abc/Listeners", "必须保留 SSH_AUTH_SOCK")
        expectEqual(cleanEnv["__CF_USER_TEXT_ENCODING"], "0x1F5:0x19:0x34", "必须保留 __CF_USER_TEXT_ENCODING")
        expectEqual(cleanEnv["COMMAND_MODE"], "unix2003", "必须设置 macOS 原生 COMMAND_MODE=unix2003")
        expectEqual(cleanEnv["PATH"], "/usr/bin:/bin:/usr/sbin:/sbin", "必须还原为 macOS LaunchServices 标准 PATH")

        let forbiddenKeys = [
            "ANTIGRAVITY_AGENT", "ANTIGRAVITY_LS_ADDRESS", "ANTIGRAVITY_APP_DATA_DIR",
            "ANTIGRAVITY_PROJECT_ID", "AGY_BROWSER_WS_URL", "GEMINI_API_KEY",
            "DISABLE_AUTO_UPDATE", "NVM_BIN", "SSH_CLIENT"
        ]
        for key in forbiddenKeys {
            expect(cleanEnv[key] == nil, "禁止将脏环境变量 \(key) 泄漏给 Antigravity.app")
        }

        // 空 SSH_AUTH_SOCK 与缺失可选键时不应注入空值
        let minimalClean = AntigravityLaunchConfig.sanitizedLaunchEnvironment(from: [
            "HOME": "/tmp/testuser",
            "USER": "testuser",
            "SSH_AUTH_SOCK": ""
        ])
        expect(minimalClean["SSH_AUTH_SOCK"] == nil, "空 SSH_AUTH_SOCK 不应注入干净环境")
        expectEqual(minimalClean["PATH"], "/usr/bin:/bin:/usr/sbin:/sbin", "缺失 PATH 时仍应补齐 LaunchServices 标准 PATH")

        // 2. 进程过滤：只允许向 .regular 主应用发 terminate()，绝不能误杀 .helper 进程，更不能误杀 Agyhub 自身
        expect(
            AntigravityLaunchConfig.isPrimaryAntigravityApplication(
                bundleIdentifier: "com.google.antigravity",
                localizedName: "Antigravity",
                activationPolicy: .regular,
                processIdentifier: 12860,
                excludingPid: 29176
            ),
            "com.google.antigravity (.regular) 必须识别为可优雅退出的主应用"
        )
        expect(
            !AntigravityLaunchConfig.isPrimaryAntigravityApplication(
                bundleIdentifier: "com.google.antigravity.helper",
                localizedName: "Antigravity Helper",
                activationPolicy: .accessory,
                processIdentifier: 13444,
                excludingPid: 29176
            ),
            "不得将 com.google.antigravity.helper 识别为主应用并直接发 terminate/SIGKILL"
        )
        expect(
            !AntigravityLaunchConfig.isPrimaryAntigravityApplication(
                bundleIdentifier: "com.antigravity.agyhub",
                localizedName: "Agyhub",
                activationPolicy: .accessory,
                processIdentifier: 29176,
                excludingPid: 29176
            ),
            "必须严格排除 Agyhub 自身进程"
        )
        expect(
            !AntigravityLaunchConfig.isPrimaryAntigravityApplication(
                bundleIdentifier: "com.google.antigravity-ide",
                localizedName: "Antigravity IDE",
                activationPolicy: .regular,
                processIdentifier: 50419,
                excludingPid: 29176
            ),
            "不得将独立的 Antigravity IDE (com.google.antigravity-ide) 纳入切号关闭范围"
        )
        expect(
            !AntigravityLaunchConfig.isPrimaryAntigravityApplication(
                bundleIdentifier: nil,
                localizedName: "Antigravity IDE",
                activationPolicy: .regular,
                processIdentifier: 50419,
                excludingPid: 29176
            ),
            "无 Bundle ID 回退匹配时也不得误关闭 Antigravity IDE"
        )
        expect(
            !AntigravityLaunchConfig.isAuxiliaryAntigravityProcess(
                bundleIdentifier: "com.google.antigravity-ide.helper",
                localizedName: "Antigravity IDE Helper",
                processIdentifier: 50428,
                excludingPid: 29176
            ),
            "不得将 Antigravity IDE Helper 纳入关闭范围"
        )
        expect(
            AntigravityLaunchConfig.isAuxiliaryAntigravityProcess(
                bundleIdentifier: "com.google.antigravity.helper",
                localizedName: "Antigravity Helper",
                processIdentifier: 13444,
                excludingPid: 29176
            ),
            "com.google.antigravity.helper 应被识别为需要等待自然随同退出的辅助进程"
        )

        // 3. 优雅退出超时窗口必须覆盖 Antigravity Electron 自身的 5 秒 killLanguageServer() 窗口
        expect(
            AntigravityLaunchConfig.gracefulShutdownTimeoutSeconds >= 6.0,
            "优雅退出等待超时必须 >= 6.0s 以覆盖 Antigravity 5s killLanguageServer() 收尾窗口"
        )

        // 4. 孤儿单例锁清理必须能删掉 Chromium 的悬空软链接（SingletonLock -> host-pid）
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }
        let mainDir = "\(home)/Library/Application Support/Antigravity"
        let danglingLock = "\(mainDir)/SingletonLock"
        let danglingCookie = "\(mainDir)/SingletonCookie"
        try? FileManager.default.createSymbolicLink(atPath: danglingLock, withDestinationPath: "192.0.2.1-99999")
        try? FileManager.default.createSymbolicLink(atPath: danglingCookie, withDestinationPath: "13073049681621671138")
        AntigravityLaunchConfig.cleanupStaleLocks(in: mainDir)
        let lockRemains = (try? FileManager.default.attributesOfItem(atPath: danglingLock)) != nil
        let cookieRemains = (try? FileManager.default.attributesOfItem(atPath: danglingCookie)) != nil
        expect(!lockRemains && !cookieRemains, "cleanupStaleLocks 必须清理悬空 SingletonLock / SingletonCookie 软链接")
    }

    // 用例 45：子 Agent 识别收折入父会话详情、外层动态 Agent Tag (工作数 + t/s)、递归查找与宽度边界保护
    static func testSubagentAggregationBadgeAndDetailDrilldown() {
        let subActiveJSON = """
        {
            "uuid": "5def2d27-e860-4e6f-9e23-eb2ae3efc515",
            "short_id": "5def2d27",
            "client_type": "app",
            "parent_conversation_id": "73afac2a-3258-43cf-8cea-2d55f3404557",
            "agent_name": "verifier",
            "agent_role": "Swarm Worker (verifier)",
            "title": "",
            "is_running": true,
            "interactions": 4,
            "input_tokens": 1000,
            "cache_tokens": 121000,
            "output_tokens": 300,
            "context_tokens": 122000,
            "cache_pct": 97.0,
            "tps": 120.4,
            "total_tokens_consumed": 1500000,
            "total_cost_usd": 0.12,
            "total_cache_consumed": 1400000,
            "total_input_consumed": 90000,
            "total_output_consumed": 10000,
            "current_stall": 18.0,
            "health": "🟢",
            "health_desc": "畅通",
            "current_phase": "执行工具 [run_command]",
            "current_action": "run_command: pytest tests/",
            "history_steps": [],
            "exists": true,
            "model": "gemini-4-hydrogen",
            "total_active_sec": 20.0,
            "total_local_sec": 10.0,
            "total_remote_sec": 10.0,
            "total_error_sec": 0.0,
            "breakdown_str": "20秒"
        }
        """
        let subIdleJSON = """
        {
            "uuid": "7f5a2c2b-27f1-47ee-bd61-4b3fd8c65c30",
            "short_id": "7f5a2c2b",
            "client_type": "app",
            "parent_conversation_id": "73afac2a-3258-43cf-8cea-2d55f3404557",
            "agent_name": "monitor",
            "agent_role": "Swarm Worker (monitor)",
            "title": "",
            "is_running": false,
            "interactions": 2,
            "input_tokens": 500,
            "cache_tokens": 34500,
            "output_tokens": 100,
            "context_tokens": 35000,
            "cache_pct": 93.0,
            "tps": 50.0,
            "total_tokens_consumed": 386000,
            "total_cost_usd": 0.02,
            "total_cache_consumed": 350000,
            "total_input_consumed": 35000,
            "total_output_consumed": 1000,
            "current_stall": 0.0,
            "health": "⏸️",
            "health_desc": "待命中",
            "current_phase": "待命中",
            "current_action": "",
            "history_steps": [],
            "exists": true,
            "model": "gemini-4-hydrogen",
            "total_active_sec": 8.0,
            "total_local_sec": 2.0,
            "total_remote_sec": 6.0,
            "total_error_sec": 0.0,
            "breakdown_str": "8秒"
        }
        """
        let parentJSON = """
        {
            "uuid": "73afac2a-3258-43cf-8cea-2d55f3404557",
            "short_id": "73afac2a",
            "client_type": "app",
            "parent_conversation_id": "",
            "agent_name": "",
            "agent_role": "",
            "title": "/sp Local Changes Review",
            "is_running": false,
            "interactions": 12,
            "input_tokens": 2000,
            "cache_tokens": 184000,
            "output_tokens": 500,
            "context_tokens": 186000,
            "cache_pct": 99.0,
            "tps": 72.0,
            "total_tokens_consumed": 8600000,
            "total_cost_usd": 0.45,
            "total_cache_consumed": 8500000,
            "total_input_consumed": 90000,
            "total_output_consumed": 10000,
            "current_stall": 0.0,
            "health": "⏸️",
            "health_desc": "待命中",
            "current_phase": "待命中",
            "current_action": "",
            "history_steps": [],
            "exists": true,
            "model": "gemini-4-hydrogen",
            "subagent_count": 2,
            "active_subagent_count": 1,
            "active_subagent_tps": 120.4,
            "subagents": [\(subIdleJSON), \(subActiveJSON)],
            "total_active_sec": 60.0,
            "total_local_sec": 20.0,
            "total_remote_sec": 40.0,
            "total_error_sec": 0.0,
            "breakdown_str": "1分00秒"
        }
        """.data(using: .utf8)!

        let parent = try! JSONDecoder().decode(SessionItem.self, from: parentJSON)
        expectEqual(parent.effectiveSubagentCount, 2, "父会话应解析到 2 个子 Agent")
        expectEqual(parent.effectiveActiveSubagentCount, 1, "应准确统计当前 1 个正在干活的子 Agent")
        expectEqual(parent.effectiveActiveSubagentTps, 120.4, "应汇总活跃子 Agent 速率 120.4 t/s")
        expect(parent.isActivelyWorking, "哪怕协调者本身 IDLE，只要有子 Agent 在跑，整条父会话应判定为工作中")

        // 2. 动态 Tag 文案策略：有干活 vs 运行中无 tps vs 全员待命 vs 无子 Agent
        let plainSession = SessionItem(uuid: "plain-1", title: "Normal Task")
        expect(SessionRowBadgePolicy.subagentBadgeText(for: plainSession) == nil, "普通无子 Agent 会话不得渲染子 Agent Tag")
        expectEqual(SessionRowBadgePolicy.subagentBadgeText(for: parent), "1 Agent · 120t/s", "有子 Agent 在跑时外层 Tag 应展示干活数量和 t/s")
        expect(SessionRowBadgePolicy.isSubagentBadgeActive(for: parent), "有子 Agent 在干活时 Tag 必须为高亮活跃态")

        let zeroTpsActiveSub = SessionItem(uuid: "sub-zero", parentConversationId: "p-zero", agentName: "research", isRunning: true, tps: 0.0)
        let parentZeroTps = SessionItem(uuid: "p-zero", isRunning: false, subagents: [zeroTpsActiveSub], subagentCount: 1, activeSubagentCount: 1, activeSubagentTps: 0.0)
        expectEqual(SessionRowBadgePolicy.subagentBadgeText(for: parentZeroTps), "1 Agent · 运行中", "子 Agent 运行中但暂无 t/s 时应降级显示运行中")

        let multiRun1 = SessionItem(uuid: "mr-1", parentConversationId: "p-multi", agentName: "w1", isRunning: true, tps: 120.4)
        let multiRun2 = SessionItem(uuid: "mr-2", parentConversationId: "p-multi", agentName: "w2", isRunning: true, tps: 79.6)
        let parentMultiRun = SessionItem(uuid: "p-multi", isRunning: false, subagents: [multiRun1, multiRun2], subagentCount: 2, activeSubagentCount: 2, activeSubagentTps: 0.0)
        expect(abs(parentMultiRun.effectiveActiveSubagentTps - 200.0) < 0.01, "多个子 Agent 同时运行时应汇总总吞吐速率 (120.4 + 79.6 = 200.0)")
        expectEqual(SessionRowBadgePolicy.subagentBadgeText(for: parentMultiRun), "2 Agent · 200t/s", "外层徽章应展示子 Agent 汇总速率 200t/s")

        let multiIdleSub1 = SessionItem(uuid: "s1", parentConversationId: "p-idle", agentName: "verifier", isRunning: false)
        let multiIdleSub2 = SessionItem(uuid: "s2", parentConversationId: "p-idle", agentName: "monitor", isRunning: false)
        let parentAllIdle = SessionItem(uuid: "p-idle", isRunning: false, subagents: [multiIdleSub1, multiIdleSub2], subagentCount: 2, activeSubagentCount: 0, activeSubagentTps: 0.0)
        expectEqual(SessionRowBadgePolicy.subagentBadgeText(for: parentAllIdle), "2 Agent", "全部子 Agent 待命时应显示收折总数 2 Agent")
        expect(!SessionRowBadgePolicy.isSubagentBadgeActive(for: parentAllIdle), "全部待命时 Tag 不应标为正在干活")

        // 3. 过滤防重复 + 排序 + 递归查找 + 最长卡顿包含子 Agent
        let leakedSub = try! JSONDecoder().decode(SessionItem.self, from: subActiveJSON.data(using: .utf8)!)
        let filtered = SessionListFilter.sessionsForDisplay([parent, leakedSub])
        expectEqual(filtered.map(\.uuid), [parent.uuid], "Swift 侧也必须防止同父子 Agent 在外层列表重复平铺")

        let sortedSubs = SessionDetailSubagentPolicy.sortedSubagents(parent.subagents)
        expectEqual(sortedSubs.first?.agentName, "verifier", "详情内子 Agent 应将运行中的 verifier 排在最前")
        expectEqual(SessionDetailSubagentPolicy.displayName(for: sortedSubs.first!), "verifier", "详情子 Agent 显示名优先取 agent_name")

        let foundChild = SessionLookup.findSession(uuid: "5def2d27-e860-4e6f-9e23-eb2ae3efc515", in: [parent])
        expectEqual(foundChild?.agentName, "verifier", "应能从父会话嵌套列表中递归查找到目标子 Agent 以支持详情下钻")

        expectEqual(SessionLookup.maxStallSeconds(in: [parent]), 18.0, "活跃子 Agent 的排队/卡顿耗时 18s 必须计入全局最长等待统计")

        // 4. 带动态 Agent Tag 的 CompactSessionRowView 在 436pt 宽度约束内绝不越界撑爆弹窗
        let constrainedHost = NSHostingView(
            rootView: CompactSessionRowView(session: parent).frame(width: 436)
        )
        expect(constrainedHost.fittingSize.width <= 436.5, "带动态 Agent Tag 的会话行在 436pt 约束下不得越界 (width=\(constrainedHost.fittingSize.width))")

        let detailHost = NSHostingView(
            rootView: SessionDetailCardView(
                session: parent,
                onBack: {},
                onSelectSubagent: { _ in }
            ).frame(width: 436)
        )
        expect(detailHost.fittingSize.width <= 436.5, "包含子 Agent 列表的详情卡片不得撑爆 436pt 宽度 (width=\(detailHost.fittingSize.width))")
    }

    // 用例 46：账号列表按上次使用顺序 (MRU) 排序并持久化，兼容历史配置与外部手工切号
    static func testAccountListSortsByMostRecentlyUsedOrder() {
        // 1. 兼容历史无 lastUsedAt 字段的 profiles.json 解码，并能往返持久化 lastUsedAt
        let legacyJSON = """
        [
          {"name":"alice@example.com","email":"alice@example.com","userDataDir":"~/Library/Application Support/Antigravity","geminiDataDir":"~/.gemini/antigravity","notes":"","isDefault":true,"createdAt":"2026-11-14T00:00:00Z"}
        ]
        """
        let legacyDecoded = try? JSONDecoder().decode([AGYProfile].self, from: legacyJSON.data(using: .utf8)!)
        expectEqual(legacyDecoded?.count, 1, "历史无 lastUsedAt 的 profiles.json 应正常解码")
        expect(legacyDecoded?.first?.lastUsedAt == nil, "历史配置解码后 lastUsedAt 应默认为 nil")

        var profiles = [
            AGYProfile(name: "alice@example.com", email: "alice@example.com", userDataDir: "~/Library/Application Support/Antigravity", isDefault: true, lastUsedAt: nil),
            AGYProfile(name: "dave@example.com", email: "dave@example.com", userDataDir: "~/.agy-profiles/dave@example.com", lastUsedAt: nil),
            AGYProfile(name: "charlie@example.com", email: "charlie@example.com", userDataDir: "~/.agy-profiles/charlie@example.com", lastUsedAt: nil),
            AGYProfile(name: "grace@example.com", email: "grace@example.com", userDataDir: "~/.agy-profiles/grace@example.com", lastUsedAt: nil),
            AGYProfile(name: "bob@example.com", email: "bob@example.com", userDataDir: "~/.agy-profiles/bob@example.com", lastUsedAt: nil),
            AGYProfile(name: "frank@example.com", email: "frank@example.com", userDataDir: "~/.agy-profiles/frank@example.com", lastUsedAt: nil)
        ]

        // 2. 连续切号：alice -> bob (t=100) -> frank (t=200) -> dave (t=300)
        expect(
            AccountSortOrder.markProfileUsed(
                targetEmail: "bob@example.com",
                previousEmail: "alice@example.com",
                in: &profiles,
                at: 100
            ),
            "切换到 bob 时应更新使用时间"
        )
        expect(
            AccountSortOrder.markProfileUsed(
                targetEmail: "frank@example.com",
                previousEmail: "bob@example.com",
                in: &profiles,
                at: 200
            ),
            "切换到 frank 时应更新使用时间"
        )

        let sortedAfterSecondSwitch = AccountSortOrder.sortedProfiles(
            profiles,
            mode: .app,
            effectiveAppEmail: "frank@example.com",
            activeProfileName: "frank@example.com",
            activeCLIProfileName: nil,
            isSharedKeychainResolved: true
        )
        expectEqual(
            sortedAfterSecondSwitch.map(\.name),
            [
                "frank@example.com",
                "bob@example.com",
                "alice@example.com",
                "dave@example.com",
                "charlie@example.com",
                "grace@example.com"
            ],
            "当前活跃排第 1，其余账号必须按上次使用时间倒序排列，未使用过的排在最后"
        )

        // 3. 切到 dave 且 CLI 同时停留在 alice 时：App 第一、CLI 第二、之后严格按 MRU (frank > bob > 未使用)
        _ = AccountSortOrder.markProfileUsed(
            targetEmail: "dave@example.com",
            previousEmail: "frank@example.com",
            in: &profiles,
            at: 300
        )
        let sortedWithDistinctCLI = AccountSortOrder.sortedProfiles(
            profiles,
            mode: .app,
            effectiveAppEmail: "dave@example.com",
            activeProfileName: "dave@example.com",
            activeCLIProfileName: "alice@example.com",
            isSharedKeychainResolved: true
        )
        expectEqual(
            Array(sortedWithDistinctCLI.prefix(4)).map(\.name),
            [
                "dave@example.com",
                "alice@example.com",
                "frank@example.com",
                "bob@example.com"
            ],
            "两端同时活跃时双活跃置顶，随后严格按最近使用顺序 (frank -> bob)"
        )

        // 4. 外部手工切号观察：从未记录过切换的外部登录被轮询发现时，也同步更新 MRU 顺序
        var lastObserved: String? = "dave@example.com"
        expect(
            !AccountSortOrder.syncObservedActiveAccount(
                activeEmail: "dave@example.com",
                lastObservedEmail: &lastObserved,
                in: &profiles,
                at: 350
            ),
            "活跃账号未变化且已有 lastUsedAt 时不应重复触发修改"
        )
        expect(
            AccountSortOrder.syncObservedActiveAccount(
                activeEmail: "bob@example.com",
                lastObservedEmail: &lastObserved,
                in: &profiles,
                at: 400
            ),
            "外部手工切号到 bob 时应捕获并更新 MRU 顺序"
        )
        expectEqual(lastObserved, "bob@example.com", "已观察到的最新活跃账号应推进")

        // 5. 冷启动尚无 lastUsedAt 时，已认证过的槽位账号应排在未认证的 Chrome 发现账号之前
        let coldProfiles = [
            AGYProfile(name: "charlie@example.com", email: "charlie@example.com", userDataDir: "~/.agy-profiles/charlie@example.com"),
            AGYProfile(name: "grace@example.com", email: "grace@example.com", userDataDir: "~/.agy-profiles/grace@example.com"),
            AGYProfile(name: "bob@example.com", email: "bob@example.com", userDataDir: "~/.agy-profiles/bob@example.com")
        ]
        let coldSorted = AccountSortOrder.sortedProfiles(
            coldProfiles,
            mode: .app,
            effectiveAppEmail: "",
            activeProfileName: "",
            activeCLIProfileName: nil,
            isSharedKeychainResolved: false,
            authenticatedEmails: ["bob@example.com"]
        )
        expectEqual(coldSorted.first?.name, "bob@example.com", "尚无切换时间时，已认证过的槽位账号应优先于纯浏览器探测账号")
    }

    // 用例 47：主会话总 Token / 账单 / 缓存率聚合子 Agent 消耗，且主窗口支持自由拖拽调整大小与尺寸持久化夹逼
    static func testAggregatedSubagentStatsAndResizableWindowPolicy() {
        let subMonitor = SessionItem(
            uuid: "cc4a3e3f-0000-0000-0000-000000000001",
            parentConversationId: "5375841a",
            agentName: "monitor",
            inputTokens: 2000,
            cacheTokens: 40000,
            contextTokens: 42000,
            cachePct: 95.0,
            totalTokensConsumed: 517_732,
            totalCostUsd: 0.307348,
            totalCacheConsumed: 470_000,
            totalInputConsumed: 24_732,
            totalOutputConsumed: 23_000
        )
        let subVerifier = SessionItem(
            uuid: "7de063b8-0000-0000-0000-000000000002",
            parentConversationId: "5375841a",
            agentName: "verifier",
            inputTokens: 11000,
            cacheTokens: 142000,
            contextTokens: 153000,
            cachePct: 92.8,
            totalTokensConsumed: 3_205_262,
            totalCostUsd: 2.149383,
            totalCacheConsumed: 2_900_000,
            totalInputConsumed: 225_000,
            totalOutputConsumed: 80_262
        )
        let subSlice = SessionItem(
            uuid: "b000dd69-0000-0000-0000-000000000003",
            parentConversationId: "5375841a",
            agentName: "slice-1",
            inputTokens: 3000,
            cacheTokens: 151000,
            contextTokens: 154000,
            cachePct: 98.2,
            totalTokensConsumed: 3_333_843,
            totalCostUsd: 0.131191,
            totalCacheConsumed: 3_200_000,
            totalInputConsumed: 60_000,
            totalOutputConsumed: 73_843
        )
        let rootSession = SessionItem(
            uuid: "5375841a-0000-0000-0000-000000000000",
            title: "Optimize Agent Prompt For Hydrogen",
            contextTokens: 105_000,
            cachePct: 94.8,
            totalTokensConsumed: 977_642,
            totalCostUsd: 0.04,
            totalCacheConsumed: 682_818,
            totalInputConsumed: 270_478,
            totalOutputConsumed: 24_346,
            subagents: [subMonitor, subVerifier, subSlice],
            subagentCount: 3
        )

        expectEqual(
            SessionRowBadgePolicy.idleMetricsText(for: rootSession),
            "978k 95%",
            "外层列表行空闲指标应展示主会话自身消耗与自身缓存率，不把子 Agent 混算进去"
        )
        expectEqual(
            rootSession.aggregatedTotalTokensConsumed,
            8_034_479,
            "详情页总 Token 必须汇总主会话与全部子 Agent 的消耗"
        )
        let expectedCost = 0.04 + 0.307348 + 2.149383 + 0.131191
        expect(
            abs(rootSession.aggregatedTotalCostUsd - expectedCost) < 0.0001,
            "父会话预估账单必须汇总主会话与全部子 Agent 费用 (got=\(rootSession.aggregatedTotalCostUsd))"
        )
        expectEqual(rootSession.contextTokens, 105_000, "主会话当前上下文窗口不得把子 Agent 窗口相加")
        let expectedWeightedCachePct = (Double(682_818 + 470_000 + 2_900_000 + 3_200_000) / Double(270_478 + 682_818 + 24_732 + 470_000 + 225_000 + 2_900_000 + 60_000 + 3_200_000)) * 100.0
        expect(
            abs(rootSession.aggregatedCachePct - expectedWeightedCachePct) < 0.05,
            "含子 Agent 时缓存率必须按树级总缓存/总输入提示加权计算"
        )
        expectEqual(subVerifier.aggregatedTotalTokensConsumed, 3_205_262, "下钻单个无子 Agent 的子会话时只展示自身 Token")
        expectEqual(subVerifier.aggregatedCachePct, 92.8, "单个无子 Agent 会话应沿用自身 cachePct")

        // 2. 可拖拽窗口尺寸策略 + AGYMainWindow 真窗口验证
        expectEqual(
            WindowSizePolicy.clampedWindowSize(width: nil, height: nil, defaultSize: WindowSizePolicy.defaultMainSize),
            WindowSizePolicy.defaultMainSize,
            "未保存尺寸时应使用默认主窗口大小"
        )
        expectEqual(
            WindowSizePolicy.clampedWindowSize(width: 220, height: 180, defaultSize: WindowSizePolicy.defaultMainSize),
            WindowSizePolicy.mainMinSize,
            "过小窗口尺寸必须被夹逼到最小可读边界"
        )
        expectEqual(
            WindowSizePolicy.clampedWindowSize(width: 720, height: 860, defaultSize: WindowSizePolicy.defaultMainSize),
            NSSize(width: 720, height: 860),
            "合法的放大尺寸必须完整保留"
        )

        let window = AGYMainWindow.create(width: 464, height: 520, rootView: Text("ResizableCheck"))
        expect(window.styleMask.contains(.resizable), "主窗口 styleMask 必须包含 .resizable 才能自由拖拽边框改变大小")
        window.setContentSize(NSSize(width: 680, height: 820))
        expect(window.frame.size.width >= 679 && window.frame.size.height >= 819, "AGYMainWindow 放大到 680x820 不得被锁定在 464x520 (actual=\(window.frame.size))")

        // 3. 回归验证：内含长 ScrollView（理想高度 > 1400pt）时不得触发 NSHostingView 自动撑大窗口或约束更新死循环崩溃
        let scrollRoot = VStack(spacing: 0) {
            Text("Header")
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(0..<40, id: \.self) { idx in
                        Text("Item \(idx)").frame(height: 36)
                    }
                }
            }
            .frame(maxHeight: .infinity)
            Text("Footer")
        }
        .frame(
            minWidth: WindowSizePolicy.mainMinSize.width,
            maxWidth: .infinity,
            minHeight: WindowSizePolicy.mainMinSize.height,
            maxHeight: .infinity
        )
        .ignoresSafeArea()
        let scrollWindow = AGYMainWindow.create(width: 464, height: 520, rootView: scrollRoot)
        scrollWindow.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        expectEqual(
            scrollWindow.frame.size,
            NSSize(width: 464, height: 520),
            "含长 ScrollView 的可拖拽主窗口不得被 SwiftUI 理想高度自动撑大或触发约束更新死循环 (actual=\(scrollWindow.frame.size))"
        )
    }

    // 用例 48：验证主窗口在默认/缩小/放大各尺寸下全出血铺满 (0,0,W,H)，绝不因 .ignoresSafeArea() 与边框修饰器顺序错位而被顶部 32pt 标题栏截掉 Header
    @MainActor
    static func testMainDashboardFullBleedChromeAcrossResizes() {
        let body = VStack(spacing: 0) {
            HStack {
                Text("Agyhub")
                Spacer()
                Text("Today $25.96")
            }
            .padding(10)
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(0..<40, id: \.self) { idx in
                        Text("Session \(idx)").frame(maxWidth: .infinity, alignment: .leading).frame(height: 24)
                    }
                }
            }
            .frame(maxHeight: .infinity)
            HStack {
                Text("更新于 10:55:00")
                Spacer()
            }
            .padding(10)
        }

        let win = AGYMainWindow.create(
            width: 464,
            height: 520,
            rootView: MainDashboardWindowChrome.apply(to: body)
        )
        win.orderBack(nil)
        defer { win.close() }

        let targetSizes: [NSSize] = [
            NSSize(width: 464, height: 520),
            NSSize(width: 440, height: 380),
            NSSize(width: 820, height: 640),
        ]

        for size in targetSizes {
            win.setContentSize(size)
            win.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            win.layoutIfNeeded()

            expectEqual(win.frame.size, size, "窗口尺寸应精确保持为 \(size)")
            if let cv = win.contentView {
                expectEqual(cv.frame.size, size, "contentView 尺寸应精确保持为 \(size)")
                let fullWidthSubviews = cv.subviews.filter { abs($0.frame.width - size.width) < 1.0 }
                for sub in fullWidthSubviews {
                    expect(
                        abs(sub.frame.origin.y) < 1.0 && abs(sub.frame.height - size.height) < 1.0,
                        "铺满窗口的渲染层不得被顶部 32pt 标题栏安全区截断 (size=\(size), sub=\(type(of: sub)), frame=\(sub.frame))"
                    )
                }
            }
        }
    }

    // 用例 49：窗口边缘与圆角拖拽命中热区（含 8pt 边/16pt 角，避开右上×/右下设置/滚动条）及反向边锚定缩放数学
    static func testWindowResizeEdgePolicyHitZonesAndAnchoredFrameMath() {
        let bounds = NSRect(x: 0, y: 0, width: 464, height: 520)

        // 1. 四条直边热区命中
        expectEqual(WindowResizeEdgePolicy.resizeEdge(at: NSPoint(x: 4, y: 260), in: bounds), .left, "左边缘 8pt 内应命中 .left")
        expectEqual(WindowResizeEdgePolicy.resizeEdge(at: NSPoint(x: 460, y: 260), in: bounds), .right, "右边缘 8pt 内应命中 .right")
        expectEqual(WindowResizeEdgePolicy.resizeEdge(at: NSPoint(x: 230, y: 517), in: bounds), .top, "上边缘 6.5pt 内应命中 .top")
        expectEqual(WindowResizeEdgePolicy.resizeEdge(at: NSPoint(x: 230, y: 3), in: bounds), .bottom, "下边缘 6.5pt 内应命中 .bottom")

        // 2. 四角 16x16pt 圆角热区命中（解决 14pt 圆角外透明穿透导致难以选中斜向缩放箭头的问题）
        expectEqual(WindowResizeEdgePolicy.resizeEdge(at: NSPoint(x: 12, y: 12), in: bounds), [.bottom, .left], "左下 16x16pt 圆角内应命中斜向左下角缩放")
        expectEqual(WindowResizeEdgePolicy.resizeEdge(at: NSPoint(x: 452, y: 12), in: bounds), [.bottom, .right], "右下 16x16pt 圆角内应命中斜向右下角缩放")
        expectEqual(WindowResizeEdgePolicy.resizeEdge(at: NSPoint(x: 12, y: 508), in: bounds), [.top, .left], "左上 16x16pt 圆角内应命中斜向左上角缩放")
        expectEqual(WindowResizeEdgePolicy.resizeEdge(at: NSPoint(x: 452, y: 508), in: bounds), [.top, .right], "右上 16x16pt 圆角内应命中斜向右上角缩放")

        // 3. 按钮、滚动条与内容区绝不误触
        expectEqual(WindowResizeEdgePolicy.resizeEdge(at: NSPoint(x: 200, y: 200), in: bounds), nil, "面板内部不得命中缩放热区")
        expectEqual(WindowResizeEdgePolicy.resizeEdge(at: NSPoint(x: 435, y: 500), in: bounds), nil, "右上角关闭按钮区域不得被缩放热区遮挡")
        expectEqual(WindowResizeEdgePolicy.resizeEdge(at: NSPoint(x: 435, y: 20), in: bounds), nil, "右下角设置按钮区域不得被缩放热区遮挡")
        expectEqual(WindowResizeEdgePolicy.resizeEdge(at: NSPoint(x: 446, y: 260), in: bounds), nil, "右侧滚动条轨道不得被缩放热区遮挡")

        // 4. 对边锚定缩放数学 + minSize/maxSize 夹逼
        let start = NSRect(x: 500, y: 300, width: 464, height: 520)
        let minS = WindowSizePolicy.mainMinSize
        let maxS = WindowSizePolicy.mainMaxSize

        let draggedLeft = WindowResizeEdgePolicy.resizedFrame(from: start, edge: .left, deltaX: -50, deltaY: 0, minSize: minS, maxSize: maxS)
        expectEqual(draggedLeft, NSRect(x: 450, y: 300, width: 514, height: 520), "向左拖左边界应拉宽 50pt 且右边界 maxX 严丝合缝固定在 964")

        let clampedLeft = WindowResizeEdgePolicy.resizedFrame(from: start, edge: .left, deltaX: 500, deltaY: 0, minSize: minS, maxSize: maxS)
        expectEqual(clampedLeft, NSRect(x: 964 - minS.width, y: 300, width: minS.width, height: 520), "向右缩过 minWidth 时窗口不得整体右移，右边界 maxX 必须保持 964")

        let draggedBottom = WindowResizeEdgePolicy.resizedFrame(from: start, edge: .bottom, deltaX: 0, deltaY: -80, minSize: minS, maxSize: maxS)
        expectEqual(draggedBottom, NSRect(x: 500, y: 220, width: 464, height: 600), "向下拖底边应增高 80pt 且顶部 maxY 锚定在 820")

        let draggedTopRight = WindowResizeEdgePolicy.resizedFrame(from: start, edge: [.top, .right], deltaX: 100, deltaY: 120, minSize: minS, maxSize: maxS)
        expectEqual(draggedTopRight, NSRect(x: 500, y: 300, width: 564, height: 640), "拖右上角时左下角原点 (500, 300) 必须保持不变")
    }

    // 用例 50：点顶部叉号只关闭/隐藏对应窗口，绝不退出常驻 Agyhub 进程
    @MainActor
    static func testCloseButtonHidesOnlyTargetWindowWithoutTerminating() {
        expectEqual(WindowClosePolicy.headerCloseTooltip, "关闭窗口", "叉号悬浮提示必须明确是关闭窗口而不是退出应用")
        expectEqual(WindowClosePolicy.action(isStandaloneWindow: false), .hideMainWindow, "状态栏主窗口点叉应隐藏主窗口")
        expectEqual(WindowClosePolicy.action(isStandaloneWindow: true), .hideStandaloneWindow, "独立固定窗口点叉应隐藏独立窗口")

        let mainWin = AGYMainWindow.create(width: 464, height: 520, rootView: Text("Main"))
        let standaloneWin = AGYMainWindow.create(width: 476, height: 560, rootView: Text("Standalone"))
        mainWin.orderBack(nil)
        standaloneWin.orderBack(nil)
        defer {
            mainWin.close()
            standaloneWin.close()
        }

        expect(mainWin.isVisible && standaloneWin.isVisible, "初始两扇窗口均应处于可见状态")

        WindowClosePolicy.performClose(isStandaloneWindow: true, mainWindow: mainWin, standaloneWindow: standaloneWin)
        expect(standaloneWin.isVisible == false, "独立窗口点叉后必须隐藏")
        expect(mainWin.isVisible == true, "关闭独立窗口不得连带关闭主窗口")

        WindowClosePolicy.performClose(isStandaloneWindow: false, mainWindow: mainWin, standaloneWindow: standaloneWin)
        expect(mainWin.isVisible == false, "主窗口点叉后必须隐藏")

        let delegate = AGYAppDelegate()
        expect(delegate.applicationShouldTerminateAfterLastWindowClosed(NSApplication.shared) == false, "全部窗口关闭后常驻菜单栏应用绝不得自动退出")
    }

    // 用例 52：保险箱槽位内存储了其它账号（id_token_email 不匹配）时，AccountQuotaManager 不得张冠李戴拿别人 Token 查配额
    static func testQuotaResolveCredentialRejectsMismatchedVaultEmail() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        let mv = MemoryVault()
        let poisoned = credentialJSON(email: "dave@example.com", accessToken: "ya29.DAVE_POISON")
        mv.slots["eve@example.com"] = ("go-keyring-base64:" + poisoned.base64EncodedString()).data(using: .utf8)!

        let resolved = AccountQuotaManager.resolveCredential(
            email: "eve@example.com",
            homeDir: home,
            vault: mv.vault
        )
        expect(resolved == nil, "eve 槽位里若误存了 dave 的凭证，配额读取必须拒绝并返回 nil")

        let sem = DispatchSemaphore(value: 0)
        var requested = false
        var summary: AccountQuotaSummary? = nil
        Task {
            summary = await AccountQuotaManager.fetchAccountQuota(
                email: "eve@example.com",
                tier: nil,
                homeDir: home,
                vault: mv.vault,
                requestQuota: { _ in
                    requested = true
                    return ("{\"groups\":[]}".data(using: .utf8), 200)
                }
            )
            sem.signal()
        }
        sem.wait()
        expect(!requested, "槽位凭证邮箱不匹配时绝不能拿错号 Token 发起配额请求")
        expect(summary == nil, "串槽时不得返回其它账号的配额数据")
    }

    // 用例 53：切号重启 Antigravity 后 1~3 秒内 language_server 打印 Auth succeeded，但 app_storage 仍含旧邮箱时，
    // effectiveExpectedAppEmail 必须在 30 秒切号保护窗内继续保持预期目标账号，直到窗口外才让位给手工重登
    static func testEffectiveExpectedAppEmailHoldsWithin30sSwitchLaunchWindow() {
        let tSwitch = glogDate(11, 15, 11, 36, 46).timeIntervalSince1970
        let switchState = CLIAccountManager.CLIActiveState(email: "eve@example.com", switchedAt: tSwitch)

        // Antigravity 启动后 2.7 秒（11:36:49）打出 Auth succeeded，app_storage 仍旧写着 dave
        let duringLaunchWindow = KeychainDriftPolicy.effectiveExpectedAppEmail(
            appStorageEmail: "dave@example.com",
            desktopAppAuthDate: Date(timeIntervalSince1970: tSwitch + 2.7),
            expectedSwitchState: switchState
        )
        expectEqual(duringLaunchWindow, "eve@example.com", "切号后 30 秒启动窗口内不得被刚启动时的 Auth succeeded 翻回旧账号")

        // 超过 30 秒保护窗后的显式手工重登，才应切到 app_storage 的新账号
        let afterWindow = KeychainDriftPolicy.effectiveExpectedAppEmail(
            appStorageEmail: "dave@example.com",
            desktopAppAuthDate: Date(timeIntervalSince1970: tSwitch + 35.0),
            expectedSwitchState: switchState
        )
        expectEqual(afterWindow, "dave@example.com", "超过 30 秒保护窗后的桌面端重登应切换预期账号为 app_storage 邮箱")
    }

    // 用例 51：复现 2026-11-15 10:30~11:36 真实串槽事故：
    // 1) captureSharedKeychainOwnerIntoVault 遇到推断邮箱与载荷 id_token_email 冲突时，绝不能写进错槽位或覆盖 cli_active.json
    // 2) restoreSharedKeychainFromVault 切出时必须按凭证真实 id_token_email 存回，切入若命中历史污染槽位必须拦截、删脏槽并保住共享钥匙串
    // 3) switchCLITokenFile 若命中污染槽位同样必须拒绝写入并清脏槽
    static func testSharedKeychainCaptureAndRestoreVerifyEmbeddedCredentialEmail() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }
        let pRoot = "\(home)/.agy-profiles"

        let daveRaw = credentialJSON(email: "dave@example.com", accessToken: "ya29.DAVE")
        let aliceRaw = credentialJSON(email: "alice@example.com", accessToken: "ya29.ALICE")
        let appStorage = "\(home)/Library/Application Support/Antigravity/app_storage.json"
        let lsLog = "\(home)/Library/Logs/Antigravity/language_server.log"

        // A. 捕获防串槽：app_storage 与 LS 推断为 eve，但共享钥匙串实际存着 dave 凭证
        try? "{\"agy.onboarding.lastLoginUsername\":\"eve@example.com\"}".write(toFile: appStorage, atomically: true, encoding: .utf8)
        let tDesktop = glogDate(11, 15, 10, 30, 50)
        try? "I1115 10:30:50.100000 100 server.go:4464] Auth succeeded, refreshing features and managers\n"
            .write(toFile: lsLog, atomically: true, encoding: .utf8)

        let mvCapture = MemoryVault()
        let sharedA = MemorySharedStore(daveRaw)
        CLIAccountManager.captureSharedKeychainOwnerIntoVault(
            homeDir: home,
            profilesRootDir: pRoot,
            vault: mvCapture.vault,
            sharedStore: sharedA.store,
            keychainModDate: tDesktop.addingTimeInterval(2.0)
        )
        expect(mvCapture.slots["eve@example.com"] == nil, "绝不能把 dave 凭证误捕获写进 eve 槽位")
        expectEqual(mvCapture.slots["dave@example.com"], daveRaw, "冲突时应按凭证内置真实 id_token_email 捕获到 dave 槽位")
        expect(CLIAccountManager.readActiveStateFile(profilesRootDir: pRoot) == nil, "内置邮箱与推断不符时不得写入错误的 cli_active.json")

        // B. 切出防串槽（重现 11:36:04 切向 alice）：推断原主为 eve，但共享钥匙串实为 dave
        let mvSwitchOut = MemoryVault()
        mvSwitchOut.slots["alice@example.com"] = aliceRaw
        let sharedB = MemorySharedStore(daveRaw)
        CLIAccountManager.writeActiveStateFile(email: "eve@example.com", profilesRootDir: pRoot)
        let resOut = CLIAccountManager.restoreSharedKeychainFromVault(
            homeDir: home,
            targetEmail: "alice@example.com",
            currentActiveEmail: "eve@example.com",
            profilesRootDir: pRoot,
            vault: mvSwitchOut.vault,
            sharedStore: sharedB.store,
            keychainModDate: tDesktop.addingTimeInterval(5.0)
        )
        expect(resOut.switchedImmediately, "目标 alice 槽位正常时应完成切换")
        expect(mvSwitchOut.slots["eve@example.com"] == nil, "切出时绝不能把 dave 的现用凭证写进 eve 槽位")
        expectEqual(mvSwitchOut.slots["dave@example.com"], daveRaw, "切出时必须按内置真实邮箱存回 dave 槽位")
        expectEqual(sharedB.data, aliceRaw, "共享钥匙串应切换为目标 alice 凭证")

        // C. 切入历史污染槽位拦截（重现 11:36:46 切向 eve）：若库里 eve 槽位已被毒化成 dave，切换必须拦截并清掉脏槽
        let mvPoisoned = MemoryVault()
        mvPoisoned.slots["eve@example.com"] = ("go-keyring-base64:" + daveRaw.base64EncodedString()).data(using: .utf8)!
        mvPoisoned.slots["alice@example.com"] = aliceRaw
        let sharedC = MemorySharedStore(aliceRaw)
        let resPoisonApp = CLIAccountManager.restoreSharedKeychainFromVault(
            homeDir: home,
            targetEmail: "eve@example.com",
            currentActiveEmail: "alice@example.com",
            profilesRootDir: pRoot,
            vault: mvPoisoned.vault,
            sharedStore: sharedC.store,
            keychainModDate: Date()
        )
        expect(!resPoisonApp.switchedImmediately, "命中串槽脏凭证时必须拒绝 App 切换")
        expectEqual(sharedC.data, aliceRaw, "被拦截后原共享钥匙串 alice 必须保持完整不动")
        expect(mvPoisoned.slots["eve@example.com"] == nil, "检测到 eve 槽位被毒化后应立即删除该脏槽")
        expect(mvPoisoned.deletes.contains("eve@example.com"), "应记录已清理被污染的 eve 槽位")

        // D. CLI 切号命中污染槽位同样拒绝写入并清理
        mvPoisoned.slots["eve@example.com"] = daveRaw
        _ = CLIAccountManager.writeCLITokenFile(aliceRaw, homeDir: home)
        let resPoisonCLI = CLIAccountManager.switchCLITokenFile(
            homeDir: home,
            targetEmail: "eve@example.com",
            vault: mvPoisoned.vault
        )
        expect(!resPoisonCLI.switchedImmediately, "命中串槽脏凭证时必须拒绝 CLI 切换")
        expectEqual(CLIAccountManager.readCLITokenFileEmail(homeDir: home), "alice@example.com", "原有效 CLI token 文件不得被错号覆盖")
        expect(mvPoisoned.slots["eve@example.com"] == nil, "CLI 切号拦截串槽后也应清除污染槽位")
    }

    // 用例 54：切号进行中（isAppSwitchInProgress == true）必须屏蔽并发 CLI 状态轮询，杜绝切号中途误报错配日志
    static func testCLIRefreshPolicySkipsWhileAppSwitchInProgress() {
        expect(KeychainDriftPolicy.shouldSkipCLIStateRefresh(isRefreshing: false, isAppSwitchInProgress: true), "App 切号进行中必须跳过并发状态刷新")
        expect(KeychainDriftPolicy.shouldSkipCLIStateRefresh(isRefreshing: true, isAppSwitchInProgress: false), "上一轮刷新未结束时必须跳过")
        expect(!KeychainDriftPolicy.shouldSkipCLIStateRefresh(isRefreshing: false, isAppSwitchInProgress: false), "空闲状态下允许正常刷新")
    }

    // 用例 55：验证用量历史 JSON 解码与 今天 / 最近 7 天 / 最近一个月 聚合汇总及按模型排序统计
    static func testUsageHistoryPayloadDecodingAndRangeSummarization() {
        var dailyJSONParts: [String] = []
        for idx in 1...30 {
            let dateStr = String(format: "2026-10-%02d", idx)
            let label = String(format: "10/%d", idx)
            let hCost = idx >= 24 ? 2.0 : 1.0
            let cCost = idx >= 24 ? 3.0 : 0.0
            let hTok = idx >= 24 ? 2000 : 1000
            let cTok = idx >= 24 ? 1000 : 0
            let totCost = hCost + cCost
            let totTok = hTok + cTok
            var modelsArr = [
                """
                {"model":"gemini-4-hydrogen","display_name":"Gemini 4 Hydrogen","cost_usd":\(hCost),"total_tokens":\(hTok),"input_tokens":\(hTok / 10),"cache_tokens":\(hTok * 8 / 10),"output_tokens":\(hTok / 10),"calls":2}
                """
            ]
            if cTok > 0 {
                modelsArr.append(
                    """
                    {"model":"claude-sonnet-5-5","display_name":"Claude Sonnet 5.5","cost_usd":\(cCost),"total_tokens":\(cTok),"input_tokens":100,"cache_tokens":800,"output_tokens":100,"calls":1}
                    """
                )
            }
            dailyJSONParts.append("""
            {"date":"\(dateStr)","label":"\(label)","cost_usd":\(totCost),"total_tokens":\(totTok),"input_tokens":\((hTok / 10) + (cTok > 0 ? 100 : 0)),"cache_tokens":\((hTok * 8 / 10) + (cTok > 0 ? 800 : 0)),"output_tokens":\((hTok / 10) + (cTok > 0 ? 100 : 0)),"calls":\(cTok > 0 ? 3 : 2),"models":[\(modelsArr.joined(separator: ","))]}
            """)
        }

        var hourlyParts: [String] = []
        for hr in 0..<24 {
            let lbl = String(format: "%02d:00", hr)
            if hr == 14 {
                hourlyParts.append("""
                {"hour":14,"label":"\(lbl)","cost_usd":5.0,"total_tokens":3000,"input_tokens":300,"cache_tokens":2400,"output_tokens":300,"calls":3,"models":[{"model":"claude-sonnet-5-5","display_name":"Claude Sonnet 5.5","cost_usd":3.0,"total_tokens":1000,"input_tokens":100,"cache_tokens":800,"output_tokens":100,"calls":1},{"model":"gemini-4-hydrogen","display_name":"Gemini 4 Hydrogen","cost_usd":2.0,"total_tokens":2000,"input_tokens":200,"cache_tokens":1600,"output_tokens":200,"calls":2}]}
                """)
            } else {
                hourlyParts.append("""
                {"hour":\(hr),"label":"\(lbl)","cost_usd":0.0,"total_tokens":0,"input_tokens":0,"cache_tokens":0,"output_tokens":0,"calls":0,"models":[]}
                """)
            }
        }

        let jsonStr = """
        {"generated_at":"2026-10-30T15:00:00","today_date":"2026-10-30","days_requested":30,"daily":[\(dailyJSONParts.joined(separator: ","))],"today_hourly":[\(hourlyParts.joined(separator: ","))]}
        """
        let data = jsonStr.data(using: .utf8)!
        let payload = try? JSONDecoder().decode(UsageHistoryPayload.self, from: data)
        expect(payload != nil, "应成功解码 UsageHistoryPayload")
        guard let payload = payload else { return }

        // 1. 今天（24 小时柱 + 按费用降序的模型排行）
        let todaySummary = UsageAnalyticsPolicy.summarize(payload: payload, range: .today)
        expectEqual(todaySummary.bars.count, 24, "今天视图应包含 24 个小时柱")
        expect(abs(todaySummary.totalCostUsd - 5.0) < 0.001, "今日总费用应为 $5.00")
        expectEqual(todaySummary.totalTokens, 3000, "今日总 Tokens 应为 3000")
        expectEqual(todaySummary.models.first?.model, "claude-sonnet-5-5", "模型列表必须按费用降序，Claude $3 排在 Hydrogen $2 之前")
        expect(abs((todaySummary.models.first?.costSharePct ?? 0) - 60.0) < 0.1, "Claude 今日费用占比应为 60%")

        // 2. 最近 7 天（24..30 号共 7 天，每天 $5 -> $35）
        let sum7 = UsageAnalyticsPolicy.summarize(payload: payload, range: .last7Days)
        expectEqual(sum7.bars.count, 7, "最近 7 天应包含 7 个日柱")
        expect(abs(sum7.totalCostUsd - 35.0) < 0.001, "最近 7 天总费用应为 $35.00")
        expectEqual(sum7.models.first?.model, "claude-sonnet-5-5", "近 7 天 Claude $21 应排第一")

        // 3. 最近一个月（23*1 + 7*5 = $58；Hydrogen $37 > Claude $21）
        let sum30 = UsageAnalyticsPolicy.summarize(payload: payload, range: .last30Days)
        expectEqual(sum30.bars.count, 30, "最近一个月应包含 30 个日柱")
        expect(abs(sum30.totalCostUsd - 58.0) < 0.001, "最近 30 天总费用应为 $58.00")
        expectEqual(sum30.models.first?.model, "gemini-4-hydrogen", "近 30 天 Hydrogen $37 应超越 Claude $21 排第一")

        // X 轴稀疏刻度防重叠检查
        let ticks30 = UsageAnalyticsPolicy.xAxisTickLabels(for: sum30.bars, range: .last30Days)
        expect(ticks30.count <= 7, "30 天视图 X 轴刻度应保持稀疏不拥挤")
        expectEqual(UsageAnalyticsPolicy.xAxisTickLabels(for: sum7.bars, range: .last7Days).count, 7, "7 天视图 X 轴应完整显示 7 天")
    }

    // 用例 56：零消耗边界下百分比计算不得产生 NaN / Inf
    static func testUsageAnalyticsEdgeCasesEmptyDataAndZeroCostTokens() {
        let empty = UsageHistoryPayload(generatedAt: "", todayDate: "2026-11-16", daysRequested: 30, daily: [], todayHourly: [])
        let sum = UsageAnalyticsPolicy.summarize(payload: empty, range: .last7Days)
        expectEqual(sum.totalTokens, 0, "空数据时总 Tokens 为 0")
        expectEqual(sum.totalCostUsd, 0.0, "空数据时总费用为 0")
        expect(!sum.cachePct.isNaN && !sum.cachePct.isInfinite, "空数据缓存命中率不得为 NaN")
        expect(sum.models.isEmpty, "空数据时模型排行列表为空")
        expect(sum.conversations.isEmpty, "空数据时按对话列表为空")
    }

    // 用例 57：验证按对话统计在 今天 / 最近 7 天 / 最近一个月 下的跨天累加、占比与排序
    static func testUsageHistoryConversationAggregationAcrossRanges() {
        let jsonStr = """
        {
          "generated_at": "2026-11-17T09:00:00",
          "today_date": "2026-11-17",
          "days_requested": 30,
          "daily": [
            {
              "date": "2026-11-10",
              "label": "11/10",
              "cost_usd": 10.0,
              "total_tokens": 500000,
              "input_tokens": 50000,
              "cache_tokens": 440000,
              "output_tokens": 10000,
              "calls": 10,
              "models": [{"model":"gemini-4-hydrogen","display_name":"Gemini 4 Hydrogen","cost_usd":10.0,"total_tokens":500000,"input_tokens":50000,"cache_tokens":440000,"output_tokens":10000,"calls":10}],
              "sessions": [{"uuid":"conv-old","title":"Old Task","client_type":"app","top_model":"gemini-4-hydrogen","top_model_display":"Gemini 4 Hydrogen","cost_usd":10.0,"total_tokens":500000,"input_tokens":50000,"cache_tokens":440000,"output_tokens":10000,"calls":10,"subagent_count":2}]
            },
            {
              "date": "2026-11-16",
              "label": "11/16",
              "cost_usd": 4.0,
              "total_tokens": 200000,
              "input_tokens": 20000,
              "cache_tokens": 176000,
              "output_tokens": 4000,
              "calls": 4,
              "models": [{"model":"gemini-4-hydrogen","display_name":"Gemini 4 Hydrogen","cost_usd":4.0,"total_tokens":200000,"input_tokens":20000,"cache_tokens":176000,"output_tokens":4000,"calls":4}],
              "sessions": [{"uuid":"conv-a","title":"Task A","client_type":"cli","top_model":"gemini-4-hydrogen","top_model_display":"Gemini 4 Hydrogen","cost_usd":4.0,"total_tokens":200000,"input_tokens":20000,"cache_tokens":176000,"output_tokens":4000,"calls":4,"subagent_count":1}]
            },
            {
              "date": "2026-11-17",
              "label": "11/17",
              "cost_usd": 6.0,
              "total_tokens": 300000,
              "input_tokens": 30000,
              "cache_tokens": 264000,
              "output_tokens": 6000,
              "calls": 6,
              "models": [{"model":"gemini-4-argon","display_name":"Gemini 4 Argon","cost_usd":6.0,"total_tokens":300000,"input_tokens":30000,"cache_tokens":264000,"output_tokens":6000,"calls":6}],
              "sessions": [
                {"uuid":"conv-b","title":"Task B","client_type":"app","top_model":"gemini-4-argon","top_model_display":"Gemini 4 Argon","cost_usd":4.5,"total_tokens":100000,"input_tokens":10000,"cache_tokens":88000,"output_tokens":2000,"calls":3,"subagent_count":0},
                {"uuid":"conv-a","title":"Task A","client_type":"cli","top_model":"gemini-4-hydrogen","top_model_display":"Gemini 4 Hydrogen","cost_usd":1.5,"total_tokens":200000,"input_tokens":20000,"cache_tokens":176000,"output_tokens":4000,"calls":3,"subagent_count":2}
              ]
            }
          ],
          "today_hourly": []
        }
        """
        let data = jsonStr.data(using: .utf8)!
        let payload = try? JSONDecoder().decode(UsageHistoryPayload.self, from: data)
        expect(payload != nil, "应成功解码包含 sessions 字段的 UsageHistoryPayload")
        guard let payload = payload else { return }

        expectEqual(UsageBreakdownDimension.allCases.count, 2, "统计维度应包含 按模型 与 按对话")

        // 1. 今天（取 daily 最后一天）
        let todaySum = UsageAnalyticsPolicy.summarize(payload: payload, range: .today)
        expectEqual(todaySum.conversations.count, 2, "今天应有 2 个活跃对话")
        expectEqual(todaySum.conversations.first?.uuid, "conv-b", "按费用降序时今天 Task B ($4.5) 应排第一")
        let byTokensToday = UsageAnalyticsPolicy.sortedConversations(todaySum.conversations, by: .tokens)
        expectEqual(byTokensToday.first?.uuid, "conv-a", "按 Tokens 降序时今天 Task A (200k) 应排第一")

        // 2. 最近 7 天（3 条 daily 都在 30 天内，假设测试 fixture 的 suffix(7) 覆盖 11/10..11/17）
        let sum30 = UsageAnalyticsPolicy.summarize(payload: payload, range: .last30Days)
        expectEqual(sum30.conversations.count, 3, "近 30 天合并去重后应有 3 个独立对话")
        expectEqual(sum30.conversations.first?.uuid, "conv-old", "Old Task ($10) 排第一")
        let convA = sum30.conversations.first(where: { $0.uuid == "conv-a" })
        expect(abs((convA?.costUsd ?? 0) - 5.5) < 0.001, "跨天对话 conv-a 费用应累加 ($4.0 + $1.5 = $5.5)")
        expectEqual(convA?.totalTokens, 400000, "跨天对话 conv-a Tokens 应累加为 400000")
        expectEqual(convA?.subagentCount, 2, "子 Agent 数应取最大值 2")
        expectEqual(convA?.clientType, "cli", "应保留 CLI 来源端标记")
    }

    // 用例 58：后台/失焦窗口首击仅用于唤醒置前，严禁穿透触发 切换/切换 CLI，且失焦状态下不展示悬停切换按钮
    static func testWindowActivationGuardBlocksAccidentalSwitchOnFocusClick() {
        expect(!ProfileRowActionPolicy.shouldShowSwitchButton(isHovered: true, isWindowKey: false), "窗口未激活置前时，悬停边缘不得弹出切换按钮")
        expect(!ProfileRowActionPolicy.shouldShowSwitchButton(isHovered: false, isWindowKey: true), "未悬停时不显示切换按钮")
        expect(ProfileRowActionPolicy.shouldShowSwitchButton(isHovered: true, isWindowKey: true), "窗口已激活且鼠标悬停时正常显示切换按钮")

        let now = Date(timeIntervalSince1970: 1000.0)
        expect(!WindowActivationGuard.shouldAllowAccountSwitch(lastFocusClickAt: now.addingTimeInterval(-0.05), now: now), "刚因点击唤醒窗口的 50ms 内绝不能触发切号")
        expect(!WindowActivationGuard.shouldAllowAccountSwitch(lastFocusClickAt: now.addingTimeInterval(-0.30), now: now), "唤醒窗口保护窗（0.35s）内绝不能触发切号")
        expect(WindowActivationGuard.shouldAllowAccountSwitch(lastFocusClickAt: now.addingTimeInterval(-0.50), now: now), "超过保护窗后的主动点击允许正常切号")
        expect(WindowActivationGuard.shouldAllowAccountSwitch(lastFocusClickAt: .distantPast, now: now), "未曾触发失焦唤醒点击时允许正常切号")
    }

    // 用例 59：最近 1 小时 503 计数 JSON 解码、5 分钟节流调度策略与等待旁徽章分级文案
    static func testRecent503PolicyRefreshThrottleAndBadgeFormatting() {
        let jsonStr = """
        {"count":58,"window_minutes":60,"checked_at":"2026-11-19T12:53:30+08:00"}
        """
        let decoded = try? JSONDecoder().decode(Recent503Stats.self, from: jsonStr.data(using: .utf8)!)
        expect(decoded != nil, "应成功解码 Recent503Stats")
        expectEqual(decoded?.count, 58, "503 计数应为 58")
        expectEqual(decoded?.windowMinutes, 60, "窗口应为 60 分钟")

        expectEqual(Recent503Policy.refreshIntervalSeconds, 300.0, "503 计数刷新周期必须严格为 5 分钟 (300s)")
        let now = Date(timeIntervalSince1970: 2000.0)
        expect(Recent503Policy.shouldRefresh(lastFetchedAt: nil, now: now, isFetching: false, force: false), "首次启动尚未拉取时应立即拉取")
        expect(!Recent503Policy.shouldRefresh(lastFetchedAt: now.addingTimeInterval(-299.0), now: now, isFetching: false, force: false), "5 分钟节流窗内不重复扫描")
        expect(Recent503Policy.shouldRefresh(lastFetchedAt: now.addingTimeInterval(-300.0), now: now, isFetching: false, force: false), "满 5 分钟后应自动触发下一次刷新")
        expect(Recent503Policy.shouldRefresh(lastFetchedAt: now.addingTimeInterval(-10.0), now: now, isFetching: false, force: true), "手动强刷应忽略 5 分钟节流窗")
        expect(!Recent503Policy.shouldRefresh(lastFetchedAt: nil, now: now, isFetching: true, force: true), "正在抓取中不得重入并发调用")

        expectEqual(Recent503Policy.badgeText(count: 0), "503: 0", "0 次 503 徽章文案")
        expectEqual(Recent503Policy.badgeText(count: 58), "503: 58", "58 次 503 徽章文案")
        expect(Recent503Policy.severityLevel(count: 0) == .normal, "0 次为正常态")
        expect(Recent503Policy.severityLevel(count: 3) == .caution, "1-9 次为提醒态")
        expect(Recent503Policy.severityLevel(count: 58) == .warning, ">=10 次为告警态")
    }

    // 用例 60：验证原生窗口动态 ActivationPolicy（开窗切 .regular 让 Mac 顶栏菜单正常可用，全部隐藏后切回 .accessory）及原生主菜单构建
    static func testNativeWindowActivationPolicyAndMainMenuContract() {
        expect(WindowActivationPolicy.targetPolicy(hasVisibleWindows: true) == .regular, "有窗口可见时应切为 .regular，使 Mac 顶部系统菜单栏正常工作")
        expect(WindowActivationPolicy.targetPolicy(hasVisibleWindows: false) == .accessory, "无窗口可见时应切回 .accessory，保持纯净状态栏常驻")

        let menu = AGYAppDelegate.buildMainMenu(target: nil)
        expect(menu.items.count >= 3, "原生主菜单应至少包含 应用 / 编辑 / 窗口 三栏")
        let titles = menu.items.compactMap { $0.submenu?.title }
        expect(titles.contains("编辑"), "主菜单应包含 编辑 菜单以支持系统级复制粘贴快捷键")
        expect(titles.contains("窗口"), "主菜单应包含 窗口 菜单以支持原生 Cmd+W 关闭窗口")
    }

    // 用例 61：验证会话上下文与缓存失效诊断载荷解码及一键复制摘要格式
    static func testSessionDiagnosticsDecodingAndCopySummaryFormatting() {
        let jsonStr = """
        {
            "uuid": "8bb54407-1abd-4f79-a476-6e6c9aa48c11",
            "title": "CI E2E 排查",
            "model": "gemini-4-hydrogen",
            "turns": 80,
            "total_tokens": 12430884,
            "input_tokens": 726984,
            "cache_tokens": 11632229,
            "output_tokens": 71671,
            "total_cost_usd": 2.5004,
            "total_chars": 549906,
            "attributed_pct": 99.6,
            "phases": [
                {"name": "调研/检索", "turns": 50, "tokens": 6884428, "input_tokens": 219384, "cache_tokens": 6624712, "output_tokens": 40332, "cost_usd": 1.1284, "pct": 55.38},
                {"name": "编码修改", "turns": 13, "tokens": 2255678, "input_tokens": 45852, "cache_tokens": 2182426, "output_tokens": 27400, "cost_usd": 0.438, "pct": 18.15}
            ],
            "sources": [
                {"name": "read_file 读取", "chars": 219051, "count": 47, "pct": 39.83},
                {"name": "后台测试/E2E回传", "chars": 113218, "count": 11, "pct": 20.59}
            ],
            "cache_miss": {
                "total_misses": 2,
                "rebuilt_tokens": 416897,
                "extra_cost_usd": 0.5941,
                "waste_pct_of_total": 23.76,
                "by_cause": [
                    {"cause": "前缀/系统注入变动", "count": 1, "rebuilt_tokens": 242075, "extra_cost_usd": 0.345},
                    {"cause": "云端报错/切节点重连", "count": 1, "rebuilt_tokens": 174822, "extra_cost_usd": 0.2491}
                ],
                "top_events": [
                    {"step_index": 205, "time": "13:45:50", "rebuilt_tokens": 242075, "ctx_tokens": 242075, "extra_cost_usd": 0.345, "cause": "前缀/系统注入变动", "detail": "短间隔（162s）但前缀或系统消息变动"}
                ]
            },
            "top_consumers": [
                {"category": "read_file 读取", "label": "app.py", "chars": 16495}
            ],
            "recommendations": [
                "read_file 占用了 39.8% 上下文，建议先用 grep 精确定位。"
            ]
        }
        """

        let payload = try? JSONDecoder().decode(SessionDiagnosticsPayload.self, from: jsonStr.data(using: .utf8)!)
        expect(payload != nil, "应成功解码 SessionDiagnosticsPayload")
        expectEqual(payload?.uuid, "8bb54407-1abd-4f79-a476-6e6c9aa48c11", "UUID 匹配")
        expectEqual(payload?.phases.count, 2, "阶段列表应包含 2 项")
        expectEqual(payload?.sources.count, 2, "来源列表应包含 2 项")
        expectEqual(payload?.cacheMiss.totalMisses, 2, "缓存失效次数应为 2")
        expectEqual(payload?.cacheMiss.byCause.count, 2, "缓存失效根因应为 2 类")
        expectEqual(payload?.cacheMiss.topEvents.first?.stepIndex, 205, "最高耗时事件应为 step 205")

        if let payload {
            let report = SessionDiagnosticsPolicy.formattedClipboardReport(payload)
            expect(report.contains("CI E2E 排查"), "剪贴板摘要应包含会话标题")
            expect(report.contains("$2.50") || report.contains("2.50"), "剪贴板摘要应包含总费用")
            expect(report.contains("前缀/系统注入变动"), "剪贴板摘要应包含缓存失效根因")
            expect(report.contains("调研/检索"), "剪贴板摘要应包含工作阶段")
            expect(report.contains("read_file 读取"), "剪贴板摘要应包含上下文来源")
            expect(report.contains("建议"), "剪贴板摘要应包含优化建议")
        }

        let slices = SessionDiagnosticsPolicy.donutSlices(values: [75.0, 25.0, 0.0])
        expectEqual(slices.count, 2, "零值切片应被过滤，仅保留有效正值分片")
        expectEqual(slices.first?.start ?? -1.0, 0.0, "首片起始角度应为 0.0")
        expectEqual(slices.last?.end ?? -1.0, 1.0, "末片结束角度应严格闭合至 1.0")
        expect(SessionDiagnosticsPolicy.donutSlices(values: [0.0, 0.0]).isEmpty, "全零数组应安全返回空切片且不除零")

        MainActor.assumeIsolated {
            let store = AGYHubStore(startMonitoring: false)
            store.openSessionDetail("parent-uuid-1")
            expectEqual(store.isLoadingDiagnosticsUUID, "parent-uuid-1", "打开主会话详情应主动触发诊断加载")
            store.drillDownToSession("subagent-uuid-2")
            expectEqual(store.isLoadingDiagnosticsUUID, "subagent-uuid-2", "下钻进入子 Agent 时必须主动触发子 Agent 诊断加载")
        }
    }

    // 用例 62：OAuth 密钥外部化加载（环境变量优先 -> ~/.agy-profiles/oauth_client.json 回退 -> 缺失优雅降级不发无效请求）
    static func testOAuthClientConfigLoadingAndMissingCredentialsFallback() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        let configPath = AccountQuotaManager.oauthClientConfigPath(homeDir: home)
        expectEqual(configPath, "\(home)/.agy-profiles/oauth_client.json", "OAuth 配置文件路径应位于 ~/.agy-profiles/oauth_client.json")

        // 1. 环境变量与配置文件均缺失 -> 返回 nil，刷新时返回明确错误且绝不触发网络请求
        expect(
            AccountQuotaManager.resolveOAuthClientConfig(environment: [:], homeDir: home) == nil,
            "均未配置时应返回 nil"
        )
        do {
            let sem = DispatchSemaphore(value: 0)
            var requestAttempted = false
            var refreshRes: Result<(accessToken: String, expiresIn: TimeInterval?), AccountQuotaManager.OAuthConfigError>? = nil
            var legacyRes: (accessToken: String, expiresIn: TimeInterval?)? = ("dummy", 1)
            Task {
                refreshRes = await AccountQuotaManager.refreshAccessTokenResult(
                    refreshToken: "r-token-1",
                    environment: [:],
                    homeDir: home,
                    performRequest: { _ in
                        requestAttempted = true
                        throw URLError(.badURL)
                    }
                )
                legacyRes = await AccountQuotaManager.refreshAccessTokenWithExpiry(
                    refreshToken: "r-token-1",
                    environment: [:],
                    homeDir: home,
                    performRequest: { _ in
                        requestAttempted = true
                        throw URLError(.badURL)
                    }
                )
                sem.signal()
            }
            sem.wait()
            expect(!requestAttempted, "未配置 OAuth 凭证时绝不能发送无效 HTTP 请求")
            expect(legacyRes == nil, "未配置 OAuth 凭证时兼容接口应安全返回 nil")
            if case .failure(let err) = refreshRes {
                expectEqual(err, .missingCredentials, "应返回 missingCredentials 错误")
                let desc = err.localizedDescription
                expect(desc.contains("AGYHUB_OAUTH_CLIENT_ID") && desc.contains("oauth_client.json"), "错误提示必须明确说明环境变量与配置文件方式")
            } else {
                expect(false, "未配置凭证时刷新必须返回 .failure(.missingCredentials)")
            }
        }

        // 2. 配置文件畸形 JSON 或只配了一半 -> 同样优雅降级为 nil，不崩溃
        try? "{bad json".write(toFile: configPath, atomically: true, encoding: .utf8)
        expect(
            AccountQuotaManager.resolveOAuthClientConfig(environment: [:], homeDir: home) == nil,
            "畸形 JSON 应安全忽略并返回 nil"
        )
        try? "{\"client_id\":\"file-only-id\",\"client_secret\":\"\"}".write(toFile: configPath, atomically: true, encoding: .utf8)
        expect(
            AccountQuotaManager.resolveOAuthClientConfig(environment: [:], homeDir: home) == nil,
            "缺少 client_secret 时应视为未完整配置并返回 nil"
        )

        // 3. 仅配置文件有效 -> 回退读取 ~/.agy-profiles/oauth_client.json
        let validJSON = """
        {
          "client_id": "file-client-id",
          "client_secret": "file-client-secret"
        }
        """
        try? validJSON.write(toFile: configPath, atomically: true, encoding: .utf8)
        let fromFile = AccountQuotaManager.resolveOAuthClientConfig(environment: [:], homeDir: home)
        expectEqual(
            fromFile,
            AccountQuotaManager.OAuthClientConfig(clientId: "file-client-id", clientSecret: "file-client-secret"),
            "未设置环境变量时应回退读取 oauth_client.json"
        )

        // 4. 环境变量优先于配置文件（全覆盖与单字段覆盖）
        let fromEnv = AccountQuotaManager.resolveOAuthClientConfig(
            environment: [
                "AGYHUB_OAUTH_CLIENT_ID": "env-client-id",
                "AGYHUB_OAUTH_CLIENT_SECRET": "env-client-secret"
            ],
            homeDir: home
        )
        expectEqual(
            fromEnv,
            AccountQuotaManager.OAuthClientConfig(clientId: "env-client-id", clientSecret: "env-client-secret"),
            "环境变量必须优先于 oauth_client.json"
        )

        let partialOverride = AccountQuotaManager.resolveOAuthClientConfig(
            environment: ["AGYHUB_OAUTH_CLIENT_ID": "  env-override-id  "],
            homeDir: home
        )
        expectEqual(
            partialOverride,
            AccountQuotaManager.OAuthClientConfig(clientId: "env-override-id", clientSecret: "file-client-secret"),
            "单字段环境变量应覆盖配置文件对应字段并保留另一字段回退"
        )

        // 5. 有效配置刷新 token -> 校验 POST 请求体使用外部化凭证并正确解析返回值
        do {
            let sem = DispatchSemaphore(value: 0)
            var capturedBody = ""
            var capturedMethod = ""
            var capturedURL = ""
            var refreshRes: Result<(accessToken: String, expiresIn: TimeInterval?), AccountQuotaManager.OAuthConfigError>? = nil
            Task {
                refreshRes = await AccountQuotaManager.refreshAccessTokenResult(
                    refreshToken: "r-test-token",
                    environment: [
                        "AGYHUB_OAUTH_CLIENT_ID": "env-client-id",
                        "AGYHUB_OAUTH_CLIENT_SECRET": "env-client-secret"
                    ],
                    homeDir: home,
                    performRequest: { req in
                        capturedMethod = req.httpMethod ?? ""
                        capturedURL = req.url?.absoluteString ?? ""
                        capturedBody = req.httpBody.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                        let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                        let body = "{\"access_token\":\"ya29.REFRESHED_OK\",\"expires_in\":3600}".data(using: .utf8)!
                        return (body, resp)
                    }
                )
                sem.signal()
            }
            sem.wait()
            expectEqual(capturedMethod, "POST", "刷新请求应使用 POST")
            expectEqual(capturedURL, AccountQuotaManager.tokenEndpoint, "刷新请求应发往官方 tokenEndpoint")
            expect(capturedBody.contains("client_id=env-client-id"), "请求体应包含外部化 client_id")
            expect(capturedBody.contains("client_secret=env-client-secret"), "请求体应包含外部化 client_secret")
            expect(capturedBody.contains("refresh_token=r-test-token"), "请求体应包含 refresh_token")
            if case .success(let val) = refreshRes {
                expectEqual(val.accessToken, "ya29.REFRESHED_OK", "应解析返回的新 access_token")
                expectEqual(val.expiresIn, 3600.0, "应解析返回的 expires_in")
            } else {
                expect(false, "有效配置与 200 响应下刷新应成功")
            }
        }
    }

    // 用例 63：弹窗/窗口可见性自适应轮询三态策略（展开 / 收起活跃 / 收起空闲）
    @MainActor
    static func testPollingSchedulePolicyThreeStateIntervals() {
        expectEqual(
            PollingSchedulePolicy.effectiveInterval(
                userRefreshInterval: 5.0,
                isDashboardVisible: true,
                hasActiveSessions: false
            ),
            5.0,
            "界面可见时应使用用户设定的正常刷新间隔"
        )
        expectEqual(
            PollingSchedulePolicy.effectiveInterval(
                userRefreshInterval: 5.0,
                isDashboardVisible: true,
                hasActiveSessions: true
            ),
            5.0,
            "界面可见且有活跃会话时应保持正常刷新间隔"
        )
        expectEqual(
            PollingSchedulePolicy.effectiveInterval(
                userRefreshInterval: 5.0,
                isDashboardVisible: false,
                hasActiveSessions: true
            ),
            15.0,
            "界面收起且存在活跃会话时兜底轮询应降频至 15 秒"
        )
        expectEqual(
            PollingSchedulePolicy.effectiveInterval(
                userRefreshInterval: 5.0,
                isDashboardVisible: false,
                hasActiveSessions: false
            ),
            60.0,
            "界面收起且完全空闲无活跃会话时兜底轮询应降频至 60 秒"
        )
        expectEqual(
            PollingSchedulePolicy.effectiveInterval(
                userRefreshInterval: 25.0,
                isDashboardVisible: false,
                hasActiveSessions: true
            ),
            25.0,
            "用户自定义间隔大于 15 秒时收起活跃态不应比用户设置更快"
        )
        expectEqual(
            PollingSchedulePolicy.effectiveInterval(
                userRefreshInterval: 90.0,
                isDashboardVisible: false,
                hasActiveSessions: false
            ),
            90.0,
            "用户自定义间隔大于 60 秒时收起空闲态不应比用户设置更快"
        )
        expectEqual(
            PollingSchedulePolicy.effectiveInterval(
                userRefreshInterval: 0.05,
                isDashboardVisible: true,
                hasActiveSessions: false
            ),
            0.2,
            "可见态下刷新间隔不得低于 0.2 秒安全下限"
        )

        var immediateRefreshCount = 0
        let store = AGYHubStore(startMonitoring: false)
        store.refreshInterval = 5.0
        store.onVisibleRefreshRequested = { immediateRefreshCount += 1 }
        expect(!store.isDashboardVisible, "Store 初始化时弹窗默认应为未展开状态")
        expectEqual(store.effectivePollingInterval, 60.0, "初始未展开且空闲时轮询间隔应为 60 秒")

        store.setDashboardVisible(true)
        expect(store.isDashboardVisible, "切为可见后状态应为 true")
        expectEqual(store.effectivePollingInterval, 5.0, "切为可见后轮询间隔应恢复正常 5 秒")
        expectEqual(immediateRefreshCount, 1, "从收起切回可见时必须立即触发一次刷新")

        store.setDashboardVisible(true)
        expectEqual(immediateRefreshCount, 1, "重复设置可见态不应重复触发切回刷新")

        store.setDashboardVisible(false)
        expect(!store.isDashboardVisible, "关闭窗口后可见性应回到 false")
        expectEqual(store.effectivePollingInterval, 60.0, "收起且无活跃会话时应回到 60 秒降频间隔")
    }

    // 用例 64：MonitorPayload 展示状态去重，未实质变化时跳过 @Published 赋值防 SwiftUI 整树重绘
    @MainActor
    static func testMonitorPayloadDedupSkipsRedundantPublishedUpdates() {
        func makePayload(timestamp: String, activeCount: Int, costUsd: Double, stall: Double) -> MonitorPayload {
            let session = SessionItem(
                uuid: "sess-1",
                clientType: "cli",
                title: "并发优化",
                isRunning: activeCount > 0,
                interactions: 3,
                inputTokens: 100,
                cacheTokens: 800,
                outputTokens: 50,
                contextTokens: 950,
                cachePct: 88.9,
                tps: 42.0,
                totalTokensConsumed: 950,
                totalCostUsd: costUsd,
                currentStall: stall,
                health: "🟢",
                healthDesc: "畅通",
                model: "3.8-flash-n"
            )
            return MonitorPayload(
                timestamp: timestamp,
                dataDir: "/tmp/mock-gemini",
                activeCount: activeCount,
                totalRoundtrips: 3,
                hasAlert: false,
                menubar: MenuBarSummary(
                    icon: activeCount > 0 ? "⚡️" : "🟢",
                    text: activeCount > 0 ? "⚡️ 1 | $\(String(format: "%.2f", costUsd))" : "🟢 待命 | $\(String(format: "%.2f", costUsd))",
                    statusLevel: activeCount > 0 ? "active" : "idle",
                    activeCount: activeCount
                ),
                todayStats: TodayStats(
                    totalTokens: 950,
                    cacheTokens: 800,
                    inputTokens: 100,
                    outputTokens: 50,
                    cachePct: 88.9,
                    costUsd: costUsd,
                    hasData: true,
                    source: "local"
                ),
                sessions: [session]
            )
        }

        let p1 = makePayload(timestamp: "2026-11-21T10:00:00", activeCount: 0, costUsd: 1.25, stall: 0.0)
        let p2OnlyTimestampChanged = makePayload(timestamp: "2026-11-21T10:00:05", activeCount: 0, costUsd: 1.25, stall: 0.0)
        let p3RealChange = makePayload(timestamp: "2026-11-21T10:00:10", activeCount: 1, costUsd: 1.30, stall: 2.5)

        expect(
            MonitorPayloadEquivalencePolicy.areDisplayEquivalent(p1, p2OnlyTimestampChanged),
            "仅 timestamp 变化而业务展示字段完全一致时应判定为等价"
        )
        expect(
            !MonitorPayloadEquivalencePolicy.areDisplayEquivalent(p1, p3RealChange),
            "活跃状态、费用或卡顿耗时变化时必须判定为实质变化"
        )

        let store = AGYHubStore(startMonitoring: false)
        var objectWillChangeCount = 0
        let cancellable = store.objectWillChange.sink { _ in
            objectWillChangeCount += 1
        }
        defer { cancellable.cancel() }

        let applied1 = store.applyMonitorPayloadIfChanged(p1, now: Date(timeIntervalSince1970: 1_700_000_000))
        expect(applied1, "首次载入监控数据必须应用更新")
        let countAfterFirst = objectWillChangeCount
        expect(countAfterFirst > 0, "首次应用应触发一次 @Published 更新")
        let initialTimeStr = store.lastUpdatedTimeStr

        let applied2 = store.applyMonitorPayloadIfChanged(p2OnlyTimestampChanged, now: Date(timeIntervalSince1970: 1_700_000_005))
        expect(!applied2, "展示字段未变化时必须跳过 @Published 赋值")
        expectEqual(objectWillChangeCount, countAfterFirst, "跳过赋值时绝不能触发 SwiftUI objectWillChange 重绘")
        expectEqual(store.lastUpdatedTimeStr, initialTimeStr, "跳过赋值时不应刷新 lastUpdatedTimeStr 导致视图重绘")

        let applied3 = store.applyMonitorPayloadIfChanged(p3RealChange, now: Date(timeIntervalSince1970: 1_700_000_010))
        expect(applied3, "展示字段实质变化时必须应用新数据")
        expect(objectWillChangeCount > countAfterFirst, "实质变化时必须触发 SwiftUI 更新")
        expectEqual(store.payload.activeCount, 1, "store.payload 应更新为最新活跃数")
        expectEqual(store.effectivePollingInterval, 15.0, "收起状态下检测到活跃会话后，轮询间隔应自动切为 15 秒")
    }

    // 用例 65：DebouncedTrigger 突发写入合并防抖与取消隔离
    static func testDebouncedTriggerCoalescesBurstsAndSupportsCancel() {
        let lock = NSLock()
        var fireCount = 0
        let firstBatchExpectation = DispatchSemaphore(value: 0)

        let debouncer = DebouncedTrigger(debounceInterval: 0.12, maxCoalesceDelay: 0.6) {
            lock.lock()
            fireCount += 1
            let current = fireCount
            lock.unlock()
            if current == 1 || current == 2 {
                firstBatchExpectation.signal()
            }
        }

        // 1. 50ms 内突发 6 次写入 -> 必须合并为 1 次触发
        for i in 0..<6 {
            debouncer.signal()
            if i < 5 {
                Thread.sleep(forTimeInterval: 0.01)
            }
        }
        let wait1 = firstBatchExpectation.wait(timeout: .now() + 1.0)
        expect(wait1 == .success, "突发事件在防抖窗口结束后应触发一次回调")
        Thread.sleep(forTimeInterval: 0.18)
        lock.lock()
        let countAfterBurst = fireCount
        lock.unlock()
        expectEqual(countAfterBurst, 1, "突发 6 次事件必须被防抖合并为 1 次")

        // 2. 间隔超过防抖窗口后的新事件 -> 应独立触发第 2 次
        debouncer.signal()
        let wait2 = firstBatchExpectation.wait(timeout: .now() + 1.0)
        expect(wait2 == .success, "超过防抖窗口后的新事件应再次触发")
        lock.lock()
        let countAfterSecond = fireCount
        lock.unlock()
        expectEqual(countAfterSecond, 2, "间隔事件应独立计为第 2 次触发")

        // 3. cancel() 必须在窗口到期前彻底取消待触发任务
        debouncer.signal()
        debouncer.cancel()
        Thread.sleep(forTimeInterval: 0.25)
        lock.lock()
        let countAfterCancel = fireCount
        lock.unlock()
        expectEqual(countAfterCancel, 2, "cancel() 后待触发任务不应再执行")
    }

    // 用例 66：SessionDirectoryWatcher 仅监听存在目录、防抖触发、兼容目录后创建与干净停止
    static func testSessionDirectoryWatcherExistingOnlyAndLateCreation() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        let existingBrain = "\(home)/.gemini/antigravity/brain"
        let missingCLIBrain = "\(home)/.gemini/antigravity-cli/brain"
        try? FileManager.default.createDirectory(atPath: existingBrain, withIntermediateDirectories: true)

        let candidates = SessionDirectoryWatcher.defaultCandidatePaths(homeDir: home)
        expectEqual(candidates.count, 2, "默认应包含 app 与 cli 两个 brain 候选目录")

        let lock = NSLock()
        var changeCount = 0
        let changedSem = DispatchSemaphore(value: 0)

        let watcher = SessionDirectoryWatcher(
            candidatePaths: candidates,
            debounceInterval: 0.12,
            missingDirectoryCheckInterval: 0.2
        ) {
            lock.lock()
            changeCount += 1
            lock.unlock()
            changedSem.signal()
        }

        watcher.start()
        defer { watcher.stop() }

        expectEqual(watcher.watchedPaths, [existingBrain], "仅应将实际存在的目录加入 FSEvents 监听列表")
        expectEqual(watcher.missingPaths, [missingCLIBrain], "尚未创建的目录应记录在 missingPaths 等待后创建")

        // 1. 在已监听目录内连续写入文件 -> 应触发一次防抖回调
        let sessionDir = "\(existingBrain)/sess-abc"
        try? FileManager.default.createDirectory(atPath: sessionDir, withIntermediateDirectories: true)
        try? "{\"step\":1}\n".write(toFile: "\(sessionDir)/transcript.jsonl", atomically: true, encoding: .utf8)
        try? "{\"step\":2}\n".write(toFile: "\(sessionDir)/transcript.jsonl", atomically: true, encoding: .utf8)

        let gotInitialEvent = changedSem.wait(timeout: .now() + 3.0)
        expect(gotInitialEvent == .success, "已监听目录发生真实写入时 FSEvents 应触发回调")

        // 排干可能的信号队列并记录计数
        Thread.sleep(forTimeInterval: 0.2)
        while changedSem.wait(timeout: .now()) == .success {}

        // 2. 后期创建原本不存在的 antigravity-cli/brain -> 自动纳管并触发变更
        try? FileManager.default.createDirectory(atPath: missingCLIBrain, withIntermediateDirectories: true)
        let deadline = Date().addingTimeInterval(3.0)
        while watcher.watchedPaths.count < 2 && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }
        expect(watcher.watchedPaths.contains(missingCLIBrain), "后创建的 CLI brain 目录必须被自动纳管进 FSEvents")
        expect(watcher.missingPaths.isEmpty, "全部目录就绪后 missingPaths 应为空")

        let cliSessionDir = "\(missingCLIBrain)/cli-sess-1"
        try? FileManager.default.createDirectory(atPath: cliSessionDir, withIntermediateDirectories: true)
        try? "{\"cli\":1}\n".write(toFile: "\(cliSessionDir)/transcript.jsonl", atomically: true, encoding: .utf8)

        let gotLateDirEvent = changedSem.wait(timeout: .now() + 3.0)
        expect(gotLateDirEvent == .success, "后创建目录内的文件写入也必须能触发 FSEvents 回调")

        // 3. stop() 后不再回调
        Thread.sleep(forTimeInterval: 0.2)
        lock.lock()
        let countBeforeStop = changeCount
        lock.unlock()
        watcher.stop()
        try? "{\"cli\":2}\n".write(toFile: "\(cliSessionDir)/transcript.jsonl", atomically: true, encoding: .utf8)
        Thread.sleep(forTimeInterval: 0.3)
        lock.lock()
        let countAfterStop = changeCount
        lock.unlock()
        expectEqual(countAfterStop, countBeforeStop, "stop() 后不应再响应文件系统事件")
    }

    // 用例 67：MonitorDaemonClient NDJSON 协议全命令、unchanged 跳过解码、与 EOF 优雅退出无孤儿进程
    static func testMonitorDaemonClientProtocolUnchangedAndCommands() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        let mockScript = "\(home)/mock_daemon.py"
        let pidFile = "\(home)/daemon.pid"
        let scriptContent = """
        import json, os, sys

        with open(\(String(reflecting: pidFile)), "w") as f:
            f.write(str(os.getpid()))

        etag = "etag-v1"
        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            req = json.loads(line)
            rid = req.get("id")
            cmd = req.get("cmd")
            if cmd == "ping":
                resp = {"id": rid, "ok": True, "pong": True}
            elif cmd == "snapshot":
                if req.get("if_none_match") == etag:
                    resp = {"id": rid, "ok": True, "unchanged": True, "etag": etag}
                else:
                    resp = {
                        "id": rid,
                        "ok": True,
                        "unchanged": False,
                        "etag": etag,
                        "payload": {
                            "timestamp": "2026-11-21T10:10:00",
                            "data_dir": "/tmp/mock",
                            "active_count": 1,
                            "total_roundtrips": 4,
                            "has_alert": False,
                            "menubar": {"icon": "⚡️", "text": "⚡️ 1 | $0.50", "status_level": "active", "active_count": 1},
                            "today_stats": {"total_tokens": 1000, "cache_tokens": 500, "input_tokens": 400, "output_tokens": 100, "cache_pct": 50.0, "cost_usd": 0.5, "has_data": True, "source": "mock"},
                            "sessions": []
                        }
                    }
            elif cmd == "recent_503":
                resp = {"id": rid, "ok": True, "payload": {"count": 2, "window_minutes": 60, "checked_at": "10:10:00"}}
            elif cmd == "usage_history":
                resp = {"id": rid, "ok": True, "payload": {"generated_at": "2026-11-21", "today_date": "2026-11-21", "days_requested": 30, "today_hourly": [], "daily": []}}
            elif cmd == "analyze_session":
                sid = req.get("session_id", "")
                resp = {
                    "id": rid,
                    "ok": True,
                    "payload": {
                        "uuid": sid,
                        "title": "诊断会话",
                        "model": "3.8-flash-n",
                        "turns": 2,
                        "total_tokens": 100,
                        "input_tokens": 50,
                        "cache_tokens": 30,
                        "output_tokens": 20,
                        "total_cost_usd": 0.1,
                        "total_chars": 400,
                        "attributed_pct": 100.0,
                        "phases": [],
                        "sources": [],
                        "cache_miss": {"total_misses": 0, "rebuilt_tokens": 0, "extra_cost_usd": 0.0, "waste_pct_of_total": 0.0, "by_cause": [], "top_events": []},
                        "top_consumers": [],
                        "recommendations": []
                    }
                }
            else:
                resp = {"id": rid, "ok": False, "error": f"unknown cmd: {cmd}"}
            sys.stdout.write(json.dumps(resp) + "\\n")
            sys.stdout.flush()
        """
        try? scriptContent.write(toFile: mockScript, atomically: true, encoding: .utf8)

        let client = MonitorDaemonClient(
            requestTimeout: 3.0,
            initialBackoff: 0.2,
            maxBackoff: 2.0,
            gracefulShutdownWait: 0.8,
            launchSpecProvider: { _ in ("/usr/bin/python3", [mockScript]) }
        )

        if case .success(let pong) = client.ping(dataDir: home) {
            expect(pong, "ping 应返回 true")
        } else {
            expect(false, "ping 必须成功")
        }

        let spawnedPID = client.currentPID
        expect(spawnedPID != nil, "daemon 启动后应记录子进程 PID")

        if case .success(let snap1) = client.fetchSnapshot(ifNoneMatch: nil, dataDir: home) {
            if case .updated(let payload, let etag) = snap1 {
                expectEqual(etag, "etag-v1", "首次 snapshot 应返回新 etag")
                expectEqual(payload.activeCount, 1, "首次 snapshot 应返回完整 payload")
                expectEqual(payload.totalRoundtrips, 4, "snapshot 字段应正确解码")
            } else {
                expect(false, "无 if_none_match 时应返回 .updated")
            }
        } else {
            expect(false, "首次 snapshot 必须成功")
        }

        if case .success(let snap2) = client.fetchSnapshot(ifNoneMatch: "etag-v1", dataDir: home) {
            if case .unchanged(let etag) = snap2 {
                expectEqual(etag, "etag-v1", "命中 if_none_match 时应返回 .unchanged")
            } else {
                expect(false, "匹配 etag 时应返回 .unchanged")
            }
        } else {
            expect(false, "unchanged snapshot 必须成功")
        }

        expectEqual(client.currentPID, spawnedPID, "连续请求必须复用同一常驻子进程而非重复 fork")

        if case .success(let stats503) = client.fetchRecent503(dataDir: home) {
            expectEqual(stats503.count, 2, "recent_503 应返回正确计数")
        } else {
            expect(false, "recent_503 必须成功")
        }

        if case .success(let history) = client.fetchUsageHistory(days: 30, dataDir: home) {
            expectEqual(history.daysRequested, 30, "usage_history 应返回正确天数")
        } else {
            expect(false, "usage_history 必须成功")
        }

        if case .success(let diag) = client.analyzeSession(uuid: "uuid-999", dataDir: home) {
            expectEqual(diag.uuid, "uuid-999", "analyze_session 应返回指定 uuid 诊断")
        } else {
            expect(false, "analyze_session 必须成功")
        }

        client.shutdown()
        expect(!client.isRunning, "shutdown 后 daemon 状态应停止")
        if let pid = spawnedPID {
            let deadline = Date().addingTimeInterval(1.5)
            while kill(pid, 0) == 0 && Date() < deadline {
                Thread.sleep(forTimeInterval: 0.03)
            }
            expect(kill(pid, 0) != 0, "shutdown 关闭 stdin 后子进程必须干净退出，不可残留孤儿进程")
        }
    }

    // 用例 68：MonitorDaemonClient 崩溃重启、单次超时清理退避与降级机制
    static func testMonitorDaemonClientTimeoutCrashRecoveryAndBackoff() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        let modeFile = "\(home)/mode.txt"
        let mockScript = "\(home)/flaky_daemon.py"
        let scriptContent = """
        import json, os, sys, time

        mode_path = \(String(reflecting: modeFile))
        def read_mode():
            try:
                with open(mode_path, "r") as f:
                    return f.read().strip()
            except Exception:
                return "ok"

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            req = json.loads(line)
            rid = req.get("id")
            mode = read_mode()
            if mode == "crash":
                sys.exit(2)
            if mode == "hang":
                time.sleep(5.0)
                continue
            resp = {"id": rid, "ok": True, "pong": True}
            sys.stdout.write(json.dumps(resp) + "\\n")
            sys.stdout.flush()
        """
        try? scriptContent.write(toFile: mockScript, atomically: true, encoding: .utf8)

        // 1. 测试子进程崩溃 -> 返回失败并进入退避窗口 -> 退避结束后恢复
        try? "crash".write(toFile: modeFile, atomically: true, encoding: .utf8)
        let client = MonitorDaemonClient(
            requestTimeout: 0.35,
            initialBackoff: 0.25,
            maxBackoff: 1.0,
            gracefulShutdownWait: 0.2,
            launchSpecProvider: { _ in ("/usr/bin/python3", [mockScript]) }
        )
        defer { client.shutdown() }

        let crashRes = client.ping(dataDir: home)
        if case .failure = crashRes {
            expect(true, "子进程崩溃时应返回失败结果")
        } else {
            expect(false, "子进程崩溃时不应成功")
        }
        expect(client.isInBackoff, "子进程崩溃后必须进入退避期避免高频拉起")

        if case .failure(let err) = client.ping(dataDir: home) {
            expectEqual(err, .inBackoff, "退避期内请求应立即返回 .inBackoff 供上层秒级降级")
        } else {
            expect(false, "退避期内不应直接阻塞拉起进程")
        }

        // 恢复正常模式并等待退避过期 -> 应自动拉起新 daemon 并恢复成功
        try? "ok".write(toFile: modeFile, atomically: true, encoding: .utf8)
        Thread.sleep(forTimeInterval: 0.32)
        if case .success(let pong) = client.ping(dataDir: home) {
            expect(pong, "退避窗口结束后应自动重建 daemon 并恢复正常")
        } else {
            expect(false, "退避窗口结束后 daemon 应自愈成功")
        }

        // 2. 测试请求超时 -> 主动终止卡死子进程且进入退避 -> 退避后可恢复
        let healthyPID = client.currentPID
        try? "hang".write(toFile: modeFile, atomically: true, encoding: .utf8)
        let timeoutRes = client.ping(dataDir: home)
        if case .failure(let err) = timeoutRes {
            expectEqual(err, .timeout, "卡死请求在超时后应返回 .timeout")
        } else {
            expect(false, "卡死请求必须触发超时失败")
        }
        if let pid = healthyPID {
            let deadline = Date().addingTimeInterval(1.0)
            while kill(pid, 0) == 0 && Date() < deadline {
                Thread.sleep(forTimeInterval: 0.02)
            }
            expect(kill(pid, 0) != 0, "请求超时后必须清理并终止卡死子进程")
        }
        expect(!client.isRunning && client.isInBackoff, "超时清理后应清空进程状态并进入退避")
    }

    // 用例 69：AppLanguage 系统语言解析（zh-* -> 简体中文，其余 -> English）与 UserDefaults 持久化及 Store 实时更新
    static func testAppLanguageSystemResolutionAndPersistence() {
        expectEqual(
            AppLanguage.resolveSystemLanguage(preferredLanguages: ["zh-Hans-CN", "en-US"]),
            .zhHans,
            "zh-Hans 首选语言应解析为简体中文"
        )
        expectEqual(
            AppLanguage.resolveSystemLanguage(preferredLanguages: ["zh-Hant-TW", "en-US"]),
            .zhHans,
            "zh-Hant 首选语言应解析为简体中文"
        )
        expectEqual(
            AppLanguage.resolveSystemLanguage(preferredLanguages: ["en-US", "zh-Hans"]),
            .en,
            "en-US 首选语言应解析为英文"
        )
        expectEqual(
            AppLanguage.resolveSystemLanguage(preferredLanguages: ["ja-JP", "zh-Hans"]),
            .en,
            "非中文首选语言（如 ja-JP）应回退为英文"
        )
        expectEqual(
            AppLanguage.resolveSystemLanguage(preferredLanguages: []),
            .en,
            "空首选语言列表应安全回退为英文"
        )

        expectEqual(AppLanguage.zhHans.resolved(preferredLanguages: ["en-US"]), .zhHans, "手动指定中文应覆盖系统英文")
        expectEqual(AppLanguage.en.resolved(preferredLanguages: ["zh-Hans"]), .en, "手动指定英文应覆盖系统中文")

        let suiteName = "com.antigravity.agyhub.tests.lang.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        expectEqual(AppLanguage.load(from: defaults), .system, "未持久化时默认应为 .system")
        AppLanguage.en.save(to: defaults)
        expectEqual(AppLanguage.load(from: defaults), .en, "保存 .en 后应能从 UserDefaults 读回")
        AppLanguage.zhHans.save(to: defaults)
        expectEqual(AppLanguage.load(from: defaults), .zhHans, "保存 .zhHans 后应能从 UserDefaults 读回")
        defaults.set("invalid_lang", forKey: AppLanguage.userDefaultsKey)
        expectEqual(AppLanguage.load(from: defaults), .system, "非法存储值应回退为 .system")

        MainActor.assumeIsolated {
            let store = AGYHubStore(startMonitoring: false, userDefaults: defaults)
            store.updateAppLanguage(.en, userDefaults: defaults)
            expectEqual(store.appLanguage, .en, "Store 更新语言应立即反映在 appLanguage")
            expectEqual(store.resolvedLanguage, .en, "Store resolvedLanguage 应立即切换为 .en")
            expectEqual(AppLanguage.load(from: defaults), .en, "Store 更新语言应同步持久化到 UserDefaults")
        }
    }

    // 用例 70：L10n 全量词条非空一致性校验与核心辅助函数/菜单双语输出验证
    private static func containsCJK(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (0x4E00...0x9FFF).contains(scalar.value)
        }
    }

    static func testL10nAllKeysNonEmptyAndLocalizedHelpers() {
        expect(L10nKey.allCases.count >= 60, "L10nKey 应完整覆盖主要 UI 词条")
        for key in L10nKey.allCases {
            let zh = key.text(for: .zhHans).trimmingCharacters(in: .whitespacesAndNewlines)
            let en = key.text(for: .en).trimmingCharacters(in: .whitespacesAndNewlines)
            expect(!zh.isEmpty, "L10nKey.\(key.rawValue) 简体中文不能为空")
            expect(!en.isEmpty, "L10nKey.\(key.rawValue) 英文不能为空")
            expect(!containsCJK(en), "L10nKey.\(key.rawValue) 英文翻译绝不能包含中文: \(en)")
            expect(!zh.contains("TODO") && !en.contains("TODO"), "L10nKey.\(key.rawValue) 不得包含未完成占位符")
        }

        // 硬性护栏：所有诊断来源/原因/阶段/建议/详情/主会话标签/运行时文案在英文模式下绝不能残留中文
        let diagSources = [
            "read_file 读取", "后台测试/E2E回传", "后台其他命令回传",
            "同步测试/构建输出", "同步搜索/Git输出", "同步其他命令输出",
            "edit/write 回执", "看板/子Agent协作", "其他系统提示",
            "模型思考与输出", "模型思考/回复与参数", "用户输入", "报错信息"
        ]
        for raw in diagSources {
            let enVal = L10n.localizeDiagnosticSource(raw, language: .en)
            expect(!containsCJK(enVal), "诊断来源英文翻译残留中文 [\(raw)] -> \(enVal)")
        }

        expectEqual(L10n.localizeAgentLabel("主会话", language: .en), "Main", "主会话标签英文应为 Main")
        expectEqual(AppLanguage.Resolved.en.backendCode, "en", "英文模式 backendCode 应为 en")

        let diagDetails = [
            "休眠等待子Agent/后台 6m21s 后唤醒 (ctx 58k)",
            "上下文从 343k 缩减至 23k",
            "等待/停顿 28m12s 后续聊 (ctx 266k)",
            "503 断流后重连重试 (ctx 192k)",
            "收到后台 task-11 (npm test) 回传后打断 (5s)",
            "收到看板/子Agent消息后重算 (12s)",
            "连续执行中路由或前缀变动 (4s)"
        ]
        for raw in diagDetails {
            let enVal = L10n.localizeDiagnosticDetail(raw, language: .en)
            expect(!containsCJK(enVal), "缓存失效详情英文翻译残留中文 [\(raw)] -> \(enVal)")
        }

        let diagRecs = [
            "子 Agent 占总花费 58%（最大开销：ui-i18n $2.90），可点击上方列表单独下钻。",
            "重复读取：AGYHub.swift 等 3 个文件被 read_file 读取 12 次（占 240K 字符），建议优先用 grep/codegraph 定位。",
            "命令输出大户：「swiftc」累计吐出 320K 字符（占总上下文 18.3%）。",
            "等待后重算 2 次（+$0.96）：久停后继续高上下文前先 `/compact` 或开新会话。"
        ]
        for raw in diagRecs {
            let enVal = L10n.localizeDiagnosticRecommendation(raw, language: .en)
            expect(!containsCJK(enVal), "优化建议英文翻译残留中文 [\(raw)] -> \(enVal)")
        }

        let runtimeSamples = [
            "🔴 503 云端算力不足排队中",
            "⚠️ 网络断流重连中",
            "⚠️ 429 频控限流退避中",
            "工具执行完毕，等待大模型下发下一步决策...",
            "正在向大模型提交 Prompt..."
        ]
        for raw in runtimeSamples {
            let enVal = L10n.localizeRuntimeText(raw, language: .en)
            expect(!containsCJK(enVal), "运行状态英文翻译残留中文 [\(raw)] -> \(enVal)")
        }

        let past = Date().addingTimeInterval(-60)
        let bucket = WeeklyQuotaBucket(remainingFraction: 0.4, resetTime: past, resetTimeStr: nil)
        expectEqual(bucket.remainingCountdown(from: Date(), language: .zhHans), "重置", "中文倒计时过期应为 重置")
        expectEqual(bucket.remainingCountdown(from: Date(), language: .en), "Reset", "英文倒计时过期应为 Reset")

        expectEqual(WindowClosePolicy.headerCloseTooltip(language: .zhHans), "关闭窗口", "中文关闭提示")
        expectEqual(WindowClosePolicy.headerCloseTooltip(language: .en), "Close Window", "英文关闭提示")

        expectEqual(SessionTitleCleaner.cleanTitle("{}", fallbackUUID: "abcdef12", language: .en), "Session #abcdef", "英文未命名会话回退")
        expectEqual(UsageRangeOption.today.title(for: .en), "Today", "英文 Today 范围标签")
        expectEqual(UsageMetricMode.cost.title(for: .en), "$ Cost", "英文费用指标标签")
        expectEqual(UsageBreakdownDimension.model.title(for: .en), "By Model", "英文按模型统计标签")

        let enMenuBar = L10n.localizeMenubarText("🟢 待命 | $0.45", language: .en)
        expectEqual(enMenuBar, "🟢 Idle | $0.45", "英文模式状态栏待命文案应完成本地化")
        let enQueueMenuBar = L10n.localizeMenubarText("🔴 503 | 排队 45s", language: .en)
        expectEqual(enQueueMenuBar, "🔴 503 | Queue 45s", "英文模式状态栏排队文案应完成本地化")

        let enMainMenu = AGYAppDelegate.buildMainMenu(target: nil, language: .en)
        let enMenuTitles = enMainMenu.items.compactMap { $0.submenu?.title }
        expect(enMenuTitles.contains("Edit") && enMenuTitles.contains("Window"), "英文主菜单应包含 Edit 与 Window")

        let enStatusMenu = AGYAppDelegate.buildStatusContextMenu(target: nil, language: .en)
        let enStatusTitles = enStatusMenu.items.map(\.title)
        expect(enStatusTitles.contains("Quit Agyhub"), "英文状态栏右键菜单应包含 Quit Agyhub")
    }

    // 用例 71：备用账号 Token 过期且未配置 OAuth (.missingCredentials) 时，返回温和提示而非开发报错
    static func testQuotaExpiredMissingCredentialsGentleHint() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        let email = "backup-expired@example.com"
        let tokenPath = CLIAccountManager.cliTokenFilePath(homeDir: home)
        let credJSON: [String: Any] = [
            "id_token_email": email,
            "token": [
                "access_token": "expired-access-token",
                "refresh_token": "valid-refresh-token"
            ]
        ]
        let credData = try! JSONSerialization.data(withJSONObject: credJSON)
        try? FileManager.default.createDirectory(
            atPath: URL(fileURLWithPath: tokenPath).deletingLastPathComponent().path,
            withIntermediateDirectories: true
        )
        try? credData.write(to: URL(fileURLWithPath: tokenPath))

        let sem = DispatchSemaphore(value: 0)
        var result: AccountQuotaManager.QuotaFetchResult? = nil
        Task {
            result = await AccountQuotaManager.fetchAccountQuotaResult(
                email: email,
                tier: nil,
                homeDir: home,
                vault: CLIAccountManager.CredentialVault(
                    read: { _ in nil },
                    write: { _, _ in true },
                    list: { [] },
                    delete: { _ in }
                ),
                environment: [:],
                requestQuota: { _ in (nil, 401) }
            )
            sem.signal()
        }
        sem.wait()

        expectEqual(result, .tokenExpiredMissingOAuth, "401 且未配置 OAuth 凭证时应返回 .tokenExpiredMissingOAuth")

        let zhHint = L10n.quotaExpiredHint(for: .zhHans)
        let enHint = L10n.quotaExpiredHint(for: .en)
        expect(!zhHint.isEmpty && !enHint.isEmpty, "过期提示中英文均不能为空")
        expect(!zhHint.contains("AGYHUB_OAUTH") && !zhHint.contains("oauth_client.json") && !zhHint.contains("401"), "中文提示不得暴露吓人的开发配置报错")
        expect(!enHint.contains("AGYHUB_OAUTH") && !enHint.contains("oauth_client.json") && !enHint.contains("401"), "英文提示不得暴露吓人的开发配置报错")
        expect(enHint.lowercased().contains("switch"), "英文提示应引导用户切换账号即可刷新")
    }

    // 用例 72：多线程并发写入 LocalAccountDetector.appendLog 与多账号并发 refreshQuotasIfNeeded 不得触发数组竞争崩溃
    static func testLocalAccountDetectorAppendLogAndRefreshQuotasConcurrencySafety() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        let tempLogPath = "\(home)/agyhub_accounts_concurrency.log"
        LocalAccountDetector.clearDiscoveryLogs()

        let workers = 8
        let perWorker = 80
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "com.antigravity.agyhub.tests.lograce", attributes: .concurrent)

        for w in 0..<workers {
            group.enter()
            queue.async {
                for i in 0..<perWorker {
                    LocalAccountDetector.appendLog("worker-\(w)-line-\(i)", logFilePath: tempLogPath)
                    if i % 10 == 0 {
                        _ = LocalAccountDetector.snapshotDiscoveryLogs()
                    }
                }
                group.leave()
            }
        }
        group.wait()

        let snapshot = LocalAccountDetector.snapshotDiscoveryLogs()
        expectEqual(snapshot.count, workers * perWorker, "并发写入后日志快照条目数必须完整无丢失")
        let fileText = (try? String(contentsOfFile: tempLogPath, encoding: .utf8)) ?? ""
        let fileLines = fileText.split(separator: "\n").count
        expectEqual(fileLines, workers * perWorker, "并发落盘后日志文件行数必须完整无交错丢失")

        // 同时并发模拟多账号 401 -> refreshAccessTokenResult(.missingCredentials) -> appendLog 与主线程 refreshQuotasIfNeeded
        let accounts = (0..<8).map { "concurrent-\($0)@example.com" }
        let sem = DispatchSemaphore(value: 0)
        var results: [AccountQuotaManager.QuotaFetchResult] = []
        Task {
            let collected = await withTaskGroup(of: AccountQuotaManager.QuotaFetchResult.self) { tg in
                for email in accounts {
                    tg.addTask {
                        let vault = CLIAccountManager.CredentialVault(
                            read: { key in
                                key == email ? "{\"id_token_email\":\"\(email)\",\"token\":{\"access_token\":\"tok\",\"refresh_token\":\"ref\"}}".data(using: .utf8) : nil
                            },
                            write: { _, _ in true },
                            list: { Set(accounts) },
                            delete: { _ in }
                        )
                        return await AccountQuotaManager.fetchAccountQuotaResult(
                            email: email,
                            tier: nil,
                            homeDir: home,
                            vault: vault,
                            environment: [:],
                            requestQuota: { _ in (nil, 401) }
                        )
                    }
                }
                var list: [AccountQuotaManager.QuotaFetchResult] = []
                for await res in tg {
                    list.append(res)
                }
                return list
            }
            results = collected
            sem.signal()
        }
        sem.wait()
        expectEqual(results.count, accounts.count, "并发多账号配额请求应全部安全返回")
        expectEqual(results.allSatisfy { $0 == .tokenExpiredMissingOAuth }, true, "并发 401 且无 OAuth 凭证时应全部安全降级为 .tokenExpiredMissingOAuth")

        let suiteName = "com.antigravity.agyhub.tests.quota.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        MainActor.assumeIsolated {
            let store = AGYHubStore(startMonitoring: false, userDefaults: defaults, homeDir: home)
            store.profiles = accounts.map { email in
                AGYProfile(
                    name: email,
                    email: email,
                    userDataDir: "\(home)/.agy-profiles/\(email)"
                )
            }
            store.refreshQuotasIfNeeded(force: true)
            expectEqual(store.fetchingQuotaEmails.count, accounts.count, "隔离 homeDir 下多账号 refreshQuotasIfNeeded 应安全启动后台任务")
            let deadline = Date().addingTimeInterval(2.0)
            while !store.fetchingQuotaEmails.isEmpty && Date() < deadline {
                RunLoop.main.run(until: Date().addingTimeInterval(0.02))
            }
            expect(store.fetchingQuotaEmails.isEmpty, "多账号并发 refreshQuotasIfNeeded 应在安全退避/结束后清空进行中集合")
            store.shutdownBackgroundWorkers()
        }
        LocalAccountDetector.clearDiscoveryLogs()
    }
}
