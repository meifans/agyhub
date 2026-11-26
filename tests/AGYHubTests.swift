import AppKit
import Darwin
import Foundation
import SwiftUI

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
        testCLITokenValidationExtractsAccessTokenWithoutDirectHTTP()
        testOfficialAGYUsageCommandProbeAndCooldowns()
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
        testOfficialCLIUsageProbeEnvironmentAndVersionGate()
        testNativeMacOSLaunchConfigFiltersHelpersSanitizesEnvAndAllowsFullShutdownWindow()
        testSubagentAggregationBadgeAndDetailDrilldown()
        testAccountListSortsByMostRecentlyUsedOrder()
        testAggregatedSubagentStatsAndResizableWindowPolicy()
        testMainDashboardFullBleedChromeAcrossResizes()
        testWindowResizeEdgePolicyHitZonesAndAnchoredFrameMath()
        testCloseButtonHidesOnlyTargetWindowWithoutTerminating()
        testSharedKeychainCaptureAndRestoreVerifyEmbeddedCredentialEmail()
        testSwitchedAwayBackupAccountKeepsCachedQuotaAndIsNotProbed()
        testEffectiveExpectedAppEmailHoldsWithin30sSwitchLaunchWindow()
        testCLIRefreshPolicySkipsWhileAppSwitchInProgress()
        testUsageHistoryPayloadDecodingAndRangeSummarization()
        testUsageAnalyticsEdgeCasesEmptyDataAndZeroCostTokens()
        testUsageHistoryConversationAggregationAcrossRanges()
        testWindowActivationGuardBlocksAccidentalSwitchOnFocusClick()
        testRecent503PolicyRefreshThrottleAndBadgeFormatting()
        testNativeWindowActivationPolicyAndMainMenuContract()
        testSessionDiagnosticsDecodingAndCopySummaryFormatting()
        testActiveQuotaTargetsDeduplicateSharedAppAndCLIAccount()
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
        testQuotaCredentialFreshnessPriorityAnd401Fallback()
        testQuotaCachePersistenceRoundTrip()
        testActiveAccountNativeRenewalPolicyAndNeutralOAuthErrorLog()
        testMonitorDaemonClientHasBoundedMemoryAcrossRepeatedSnapshots()
        testVisibilityAwareFSEventsCLIThrottleAndBoundedLogs()
        testParseFiveHourQuotaBucketAndCapacitySummary()
        testCompactAccountSummaryResolutionForAppAndCLI()
        testCompactAccountCardAndPickerLayoutFitsWithinPanelWidths()
        testLiveTelemetrySampleExtractionAndRingBufferBounds()
        testLiveTelemetryOverviewCardFitsPanelWidthAndShowsSummary()
        testLiveTelemetrySubagentForkHandoffAndSegmentSplit()
        testLiveTelemetryYAxisLeftAlignedAndHighContrast()
        testLiveTelemetryFamilyColorHierarchyAndDescendantTiers()
        testHeaderBarNeverWrapsTodayPillVerticallyOnNarrowWidths()
        testDashboardAdaptiveLayoutReducesMarginsWhenNarrowed()
        testLiveTelemetrySmoothCurveInterpolationAndZeroCliffJumps()
        testConfigurableSessionVisibleLimitAndSessionColorLinkage()
        testDashboardSplitLayoutDraggableResizeClampingAndPersistence()
        testLiveTelemetryForkJunctionAlignsStrictlyOnParentCurveWithoutDip()
        testTodayUsagePillInHeaderWithoutLeadingIconAndFitsAllWidths()
        testChartNearestCurveHitTestAndBidirectionalHighlight()
        testLiveTelemetryColorsRemainIdenticalAcrossAllTimeRanges()
        testLiveTelemetryPaletteEightFamiliesAndUniformPerceptualProgression()
        testSettingsOverlayDismissesOnOutsideTapAndOmitsFooterQuitBar()
        testRecentUIChangesEnglishLocalizationAndTelemetryLabel()
        testLiveTelemetryIdleGapBridgingAndHollowIdleTail()
        testTelemetryDefaultHidesHorizontalGuideRulesAndOffsetsCalloutFromDot()
        testOneQuarterAdvancingTimelineCycleAndAdaptiveCallout()

        if failures > 0 {
            fputs("\n❌ 共 \(failures) 个断言失败\n", stderr)
            exit(1)
        }
        print("✅ 全部 TDD 测试通过！")
    }

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

    static func credentialJSON(email: String, accessToken: String) -> Data {
        let json = """
        {"token":{"access_token":"\(accessToken)","token_type":"Bearer","refresh_token":"r-\(email)","expiry":"2026-11-12T19:00:00+08:00"},"auth_method":"consumer","id_token_email":"\(email)","writer_id":"w"}
        """
        return json.data(using: .utf8)!
    }

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

    static func testDecodeGoKeyringBase64CredentialToRawJSON() {
        let raw = credentialJSON(email: "alice@example.com", accessToken: "ya29.A")
        let wrapped = ("go-keyring-base64:" + raw.base64EncodedString()).data(using: .utf8)!
        expectEqual(CLIAccountManager.decodeCredentialJSON(wrapped), raw, "go-keyring-base64 前缀必须被剥离并解码为原始 JSON")
        expectEqual(CLIAccountManager.decodeCredentialJSON(raw), raw, "已是纯 JSON 的凭证必须原样返回")
        expectEqual(CLIAccountManager.credentialEmail(wrapped), "alice@example.com", "两种格式都必须能解析出 id_token_email")
        expectEqual(CLIAccountManager.credentialEmail("go-keyring-base64:!!!不是base64".data(using: .utf8)!), nil, "坏数据必须返回 nil 而不是崩溃或乱猜")
    }

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

    static func testDefaultRefreshIntervalIsFiveSeconds() {
        expectEqual(AGYHubStore.defaultRefreshInterval, 5.0, "默认刷新间隔必须为 5.0 秒")
    }

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

    static func testUltraAccountQuotaDisplayLogic() {
        let now = Date()
        let gBucket = WeeklyQuotaBucket(remainingFraction: 0.85, resetTime: now.addingTimeInterval(86400 * 3), resetTimeStr: "2026-11-15T00:00:00Z")
        let aBucket = WeeklyQuotaBucket(remainingFraction: 0.40, resetTime: now.addingTimeInterval(86400 * 6), resetTimeStr: "2026-11-18T00:00:00Z")

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

    static func testQuotaCountdownFormatting() {
        let baseDate = Date(timeIntervalSince1970: 1700000000)

        let t1 = baseDate.addingTimeInterval(3 * 86400 + 18 * 3600)
        let b1 = WeeklyQuotaBucket(remainingFraction: 0.5, resetTime: t1, resetTimeStr: nil)
        expectEqual(b1.remainingCountdown(from: baseDate), "3d", "跨天应显示 3d")

        let t2 = baseDate.addingTimeInterval(5 * 3600 + 30 * 60)
        let b2 = WeeklyQuotaBucket(remainingFraction: 0.5, resetTime: t2, resetTimeStr: nil)
        expectEqual(b2.remainingCountdown(from: baseDate), "5h", "不满 1 天应显示 5h")

        let t3 = baseDate.addingTimeInterval(25 * 60)
        let b3 = WeeklyQuotaBucket(remainingFraction: 0.5, resetTime: t3, resetTimeStr: nil)
        expectEqual(b3.remainingCountdown(from: baseDate), "25m", "不满 1 小时应显示 25m")

        let t4 = baseDate.addingTimeInterval(-10)
        let b4 = WeeklyQuotaBucket(remainingFraction: 0.5, resetTime: t4, resetTimeStr: nil)
        expectEqual(b4.remainingCountdown(from: baseDate), "重置", "过期应显示「重置」")
    }

    static func testQuotaTooltipGeneration() {
        let now = Date()
        let gBucket = WeeklyQuotaBucket(remainingFraction: 0.85, resetTime: now.addingTimeInterval(86400 * 3), resetTimeStr: nil)
        let aBucket = WeeklyQuotaBucket(remainingFraction: 0.40, resetTime: now.addingTimeInterval(86400 * 6), resetTimeStr: nil)

        let ultraSummary = AccountQuotaSummary(email: "ultra@example.com", isUltra: true, geminiQuota: gBucket, argonQuota: aBucket, lastFetched: now)
        let ultraItems = AccountQuotaManager.displayItems(for: ultraSummary)
        let ultraTip = AccountQuotaManager.quotaTooltip(items: ultraItems, isUltra: true)
        expect(ultraTip.contains("Google AI Ultra"), "Ultra Tooltip 应标明 Ultra 统一共享配额池")
        expect(ultraTip.contains("Gemini 周额度: 85%"), "Ultra Tooltip 应展示 Gemini 额度")
        expect(!ultraTip.contains("Argon"), "Ultra Tooltip 严禁出现 Argon")

        let proSummary = AccountQuotaSummary(email: "pro@example.com", isUltra: false, geminiQuota: gBucket, argonQuota: aBucket, lastFetched: now)
        let proItems = AccountQuotaManager.displayItems(for: proSummary)
        let proTip = AccountQuotaManager.quotaTooltip(items: proItems, isUltra: false)
        expect(proTip.contains("Gemini 周额度: 85%"), "普通 Tooltip 应展示 Gemini 额度")
        expect(proTip.contains("Gemini 4 Argon 周额度: 40%"), "普通 Tooltip 应展示 Gemini 4 Argon 额度")
    }

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

    static func testAllSessionsAccessibleForScrolling() {
        var sessions: [SessionItem] = []
        for i in 1...15 {
            sessions.append(SessionItem(uuid: "u\(i)", title: "Session \(i)"))
        }

        let displayed = SessionListFilter.sessionsForDisplay(sessions)
        expectEqual(displayed.count, 15, "会话滚动列表应完整包含全部 15 个会话")
    }

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

        let switchArgsNonDefault = AntigravityLaunchConfig.launchArguments(
            for: nonDefaultProfile,
            targetApp: "/Applications/Antigravity.app",
            sharedExtensionsDir: "~/.antigravity/extensions",
            isParallelLaunch: false
        )
        expect(!switchArgsNonDefault.contains { $0.contains("--user-data-dir") }, "单实例切换非默认账号严禁包含 --user-data-dir，防止污染分辨率")
        expectEqual(switchArgsNonDefault, ["-a", "/Applications/Antigravity.app"], "切换模式必须遵循 macOS 原生单实例启动参数（不含 -n）")

        let switchArgsDefault = AntigravityLaunchConfig.launchArguments(
            for: defaultProfile,
            targetApp: "/Applications/Antigravity.app",
            sharedExtensionsDir: "~/.antigravity/extensions",
            isParallelLaunch: false
        )
        expectEqual(switchArgsDefault, ["-a", "/Applications/Antigravity.app"], "默认账号切换必须遵循 macOS 原生单实例启动参数（不含 -n）")

        let parallelArgs = AntigravityLaunchConfig.launchArguments(
            for: nonDefaultProfile,
            targetApp: "/Applications/Antigravity.app",
            sharedExtensionsDir: "~/.antigravity/extensions",
            isParallelLaunch: true
        )
        expect(parallelArgs.contains { $0.contains("--user-data-dir") }, "双开模式必须携带独立隔离目录")
    }

    static func testEnsureProfileDirectoryDoesNotInjectZoomPreferences() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        let mainDir = "\(home)/Library/Application Support/Antigravity"
        let sourcePref = "\(mainDir)/Preferences"
        let dirtyPrefContent = "{\"partition\":{\"per_host_zoom_levels\":{\"1234\":{\"127.0.0.1\":1.5}}}}"
        try? dirtyPrefContent.write(toFile: sourcePref, atomically: true, encoding: .utf8)

        let profileDir = "\(home)/.agy-profiles/test@example.com"
        AntigravityLaunchConfig.cleanZoomContamination(in: profileDir)

        let fakeTargetPref = "\(profileDir)/Preferences"
        try? FileManager.default.createDirectory(atPath: profileDir, withIntermediateDirectories: true)
        try? dirtyPrefContent.write(toFile: fakeTargetPref, atomically: true, encoding: .utf8)

        AntigravityLaunchConfig.cleanZoomContamination(in: profileDir)
        let exists = FileManager.default.fileExists(atPath: fakeTargetPref)
        expect(!exists, "带 zoom 污染的 Preferences 应被清除，恢复 Chromium 默认原生系统 DPI")
    }

    static func testProfileRowActionsHideParallelAndDeleteButtons() {
        expect(!ProfileRowActionPolicy.showsParallelLaunchButton, "账号行不得渲染「双开」按钮以节约横向空间")
        expect(!ProfileRowActionPolicy.showsDeleteButton, "账号行不得渲染「删除」按钮以节约横向空间")
    }

    static func testAccountListSortsActiveAccountsFirst() {
        let profiles = [
            AGYProfile(name: "alice@example.com", email: "alice@example.com", userDataDir: "~/.agy-profiles/alice@example.com"),
            AGYProfile(name: "dave@example.com", email: "dave@example.com", userDataDir: "~/.agy-profiles/dave@example.com"),
            AGYProfile(name: "grace@example.com", email: "grace@example.com", userDataDir: "~/.agy-profiles/grace@example.com"),
            AGYProfile(name: "bob@example.com", email: "bob@example.com", userDataDir: "~/Library/Application Support/Antigravity", isDefault: true),
            AGYProfile(name: "frank@example.com", email: "frank@example.com", userDataDir: "~/.agy-profiles/frank@example.com")
        ]

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

    static func testKeychainDriftPolicyIgnoresIntentionalAgyhubSwitch() {
        let tApp = glogDate(11, 12, 19, 8, 5).timeIntervalSince1970
        let tSwitch = glogDate(11, 12, 22, 10, 20).timeIntervalSince1970

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

    static func testEffectiveActiveCLIProfileFallsBackToSharedKeychainWhenTokenFileMissing() {

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

    static func testSwitchStartupRaceDoesNotPoisonCLIActiveJson() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }
        let pRoot = "\(home)/.agy-profiles"

        let tSwitch = glogDate(11, 12, 22, 10, 12).timeIntervalSince1970
        let switchState = CLIAccountManager.CLIActiveState(email: "alice@example.com", switchedAt: tSwitch)
        let cliActiveData = try! JSONEncoder().encode(switchState)
        try? cliActiveData.write(to: URL(fileURLWithPath: "\(pRoot)/cli_active.json"))

        let appStorage = "\(home)/Library/Application Support/Antigravity/app_storage.json"
        try? "{\"agy.onboarding.lastLoginUsername\":\"bob@example.com\"}".write(toFile: appStorage, atomically: true, encoding: .utf8)

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

    static func testCLITokenValidationExtractsAccessTokenWithoutDirectHTTP() {
        let raw = credentialJSON(email: "alice@example.com", accessToken: "tok-raw")
        expect(CLIAccountManager.hasAccessToken(raw), "纯 JSON 凭证包含 access_token 时应校验通过")

        let prefixed = ("go-keyring-base64:" + raw.base64EncodedString()).data(using: .utf8)!
        expect(CLIAccountManager.hasAccessToken(prefixed), "go-keyring-base64 凭证解包后应校验通过")

        let emptyTok = "{\"id_token_email\":\"alice@example.com\",\"token\":{\"access_token\":\"\"}}".data(using: .utf8)!
        expect(!CLIAccountManager.hasAccessToken(emptyTok), "空 access_token 凭证必须被拦截")
    }

    static func testOfficialAGYUsageCommandProbeAndCooldowns() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        let usageJSON = """
        {
          "conversation_id": "",
          "status": "SUCCESS",
          "duration_seconds": 0,
          "num_turns": 0,
          "usage": { "total_tokens": 0 },
          "command": {
            "name": "usage",
            "data": {
              "groups": [
                {
                  "name": "Gemini Models",
                  "description": "Models within this group: Gemini 4 Neon, Gemini 4 Argon",
                  "buckets": [
                    { "id": "gemini-weekly", "window": "weekly", "remaining_fraction": 0.96, "reset_time": "2026-12-03T14:44:25Z" },
                    { "id": "gemini-5h", "window": "5h", "remaining_fraction": 0.89, "reset_time": "2026-11-26T19:44:25Z" }
                  ]
                },
                {
                  "name": "Claude and GPT models",
                  "buckets": [
                    { "id": "3p-weekly", "window": "weekly", "remaining_fraction": 1.0, "reset_time": "1970-01-01T00:00:00Z" }
                  ]
                }
              ]
            }
          }
        }
        """.data(using: .utf8)!

        var observedSlots: [AccountQuotaManager.QuotaSlotTarget] = []
        let sem = DispatchSemaphore(value: 0)
        var appRes: AccountQuotaManager.QuotaFetchResult = .failed
        var cliRes: AccountQuotaManager.QuotaFetchResult = .failed
        var authRes: AccountQuotaManager.QuotaFetchResult = .failed

        Task {
            appRes = await AccountQuotaManager.fetchActiveSlotQuota(
                target: .activeApp,
                email: "alice@example.com",
                tier: "Google AI Pro",
                homeDir: home,
                runCLI: { slot, _ in
                    observedSlots.append(slot)
                    return (0, usageJSON, Data())
                }
            )
            cliRes = await AccountQuotaManager.fetchActiveSlotQuota(
                target: .activeCLI,
                email: "bob@example.com",
                tier: "Google AI Ultra",
                homeDir: home,
                runCLI: { slot, _ in
                    observedSlots.append(slot)
                    return (0, usageJSON, Data())
                }
            )
            authRes = await AccountQuotaManager.fetchActiveSlotQuota(
                target: .activeApp,
                email: "expired@example.com",
                tier: nil,
                homeDir: home,
                runCLI: { _, _ in
                    return (1, Data(), "Authentication required: not logged in".data(using: .utf8)!)
                }
            )
            sem.signal()
        }
        sem.wait()

        expectEqual(observedSlots, [.activeApp, .activeCLI], "应通过官方 CLI 按指定活跃槽位执行探针")
        if case .success(let summary) = appRes {
            expectEqual(summary.geminiQuota?.percentage, 96, "应解析出 command.data.groups 中的 Gemini 周额度")
            expectEqual(summary.geminiFiveHourQuota?.percentage, 89, "应解析出 command.data.groups 中的 Gemini 5h 额度")
            expect(summary.argonQuota == nil, "Gemini Models 的 description 中提及 Argon 时不得误拆分出独立 Argon 桶")
        } else {
            expect(false, "有效 JSON 输出应解析成功，实际: \(appRes)")
        }
        if case .success(let cliSummary) = cliRes {
            expect(cliSummary.isUltra, "Ultra 账号标记应正确透传")
        } else {
            expect(false, "activeCLI 有效 JSON 输出应解析成功")
        }
        expectEqual(authRes, .authRequired, "未登录/认证失效错误应准确归类为 .authRequired")

        let now = Date(timeIntervalSince1970: 1700000000)
        expect(
            !AccountQuotaManager.shouldAttemptQuotaFetch(
                lastSuccess: now.addingTimeInterval(-120),
                lastFailure: nil,
                now: now
            ),
            "自动刷新成功后 180 秒内必须冷却，避免频繁拉起 CLI 进程"
        )
        expect(
            AccountQuotaManager.shouldAttemptQuotaFetch(
                lastSuccess: now.addingTimeInterval(-190),
                lastFailure: nil,
                now: now
            ),
            "超过 180 秒冷却窗口后应允许下次自动刷新"
        )
        expect(
            !AccountQuotaManager.shouldAttemptQuotaFetch(
                lastSuccess: nil,
                lastFailure: now.addingTimeInterval(-60),
                now: now
            ),
            "探针失败后 300 秒内必须退避"
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

    static func testSyncOnboardingUsernameUpdatesAppStorageWithoutDroppingOtherKeys() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }
        let mainDir = "\(home)/Library/Application Support/Antigravity"
        let storagePath = "\(mainDir)/app_storage.json"

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

    static func testDetectLatestDesktopAppAuthDateScansBeyond128KB() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }
        let logDir = "\(home)/Library/Logs/Antigravity"
        try! FileManager.default.createDirectory(atPath: logDir, withIntermediateDirectories: true)
        let logPath = "\(logDir)/language_server.log"

        var content = "ERROR: logging before google.Init: I1113 08:19:15.100000 160 server.go:4308] Auth succeeded, refreshing features and managers\n"
        content += "ERROR: logging before google.Init: I1113 08:24:14.359773 36005 server.go:4308] Auth succeeded, refreshing features and managers\n"

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

    static func testSyncedExpectedAppStateAdvancesOnManualDesktopLoginOnlyAfterSwitchWindow() {
        let tExpected = glogDate(11, 13, 7, 54, 43).timeIntervalSince1970
        let existing = CLIAccountManager.CLIActiveState(email: "alice@example.com", switchedAt: tExpected)

        let withinWindow = KeychainDriftPolicy.syncedExpectedAppStateAfterDesktopLogin(
            existingExpected: existing,
            appStorageEmail: "dave@example.com",
            desktopAppAuthDate: Date(timeIntervalSince1970: tExpected + 10.0)
        )
        expect(withinWindow == nil, "切号 30 秒保护窗内不得误覆盖 app_expected.json")

        let tManualLogin = glogDate(11, 13, 8, 24, 14)
        let advanced = KeychainDriftPolicy.syncedExpectedAppStateAfterDesktopLogin(
            existingExpected: existing,
            appStorageEmail: "dave@example.com",
            desktopAppAuthDate: tManualLogin
        )
        expectEqual(advanced?.email, "dave@example.com", "App 内手工登录新账号且晚于切号保护窗时，app_expected.json 必须同步推进至新账号")
    }

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

    static func testSessionTitleMarqueePolicyCalculations() {

        expectEqual(
            SessionTitleMarqueePolicy.overflowDistance(textWidth: 120, containerWidth: 160),
            0.0,
            "未截断标题溢出量应为 0"
        )
        expect(
            !SessionTitleMarqueePolicy.shouldScroll(isHovered: true, textWidth: 161, containerWidth: 160),
            "极小宽度误差内不应误触发抖动滚动"
        )

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

        let shortDuration = SessionTitleMarqueePolicy.scrollDuration(overflowDistance: 10)
        let longDuration = SessionTitleMarqueePolicy.scrollDuration(overflowDistance: 140)
        expect(shortDuration >= 1.2, "短溢出应保留最低可读时长防止闪现过快")
        expect(longDuration > shortDuration, "更长标题应分配更长滚动时间保持匀速阅读感")

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

    static func testSessionRowCapsuleBadgesAndContextFormatting() {

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

        expectEqual(SessionRowBadgePolicy.contextBadgeText(contextTokens: 0), "-", "0 上下文应显示为 -")
        expectEqual(SessionRowBadgePolicy.contextBadgeText(contextTokens: -10), "-", "负数上下文应兜底为 -")
        expectEqual(SessionRowBadgePolicy.contextBadgeText(contextTokens: 850), "850", "不足 1k 应显示原始数值")
        expectEqual(SessionRowBadgePolicy.contextBadgeText(contextTokens: 50740), "51k", "50740 应格式化为 51k")
        expectEqual(SessionRowBadgePolicy.contextBadgeText(contextTokens: 141591), "142k", "141591 应格式化为 142k")
        expectEqual(SessionRowBadgePolicy.contextBadgeText(contextTokens: 1_200_000), "1.2M", "超过 1M 应格式化为 1.2M")

        expect(SessionRowBadgePolicy.modelColumnWidth < 88, "模型胶囊列宽应比原先 88pt 更小")
        expect(SessionRowBadgePolicy.modelFontSize < 10, "模型胶囊字号应比原先 10pt 更小")
        expect(SessionRowBadgePolicy.contextFontSize < 10, "上下文胶囊字号应比原先 10pt 更小")
        expect(SessionRowBadgePolicy.contextColumnWidth > 0, "上下文胶囊应具备独立列宽")

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

        expectEqual(
            SessionRowBadgePolicy.trailingColumns(showModel: false),
            [.context, .metrics],
            "默认关闭展示模型时，尾列应只渲染上下文与用量/速率，不预留空模型列"
        )
        expectEqual(
            SessionRowBadgePolicy.trailingColumns(showModel: true),
            [.context, .metrics, .model],
            "开启展示模型时，模型胶囊必须排在整行最后（上下文 -> 用量/速率 -> 模型）"
        )

        let modelToggleHost = NSHostingView(rootView: CompactSessionRowView(session: ultraLongModelSession, showModelColumn: true))
        expect(
            modelToggleHost.fittingSize.width <= 260,
            "开启模型列时超长模型名仍不得撑宽整行 (fittingWidth=\(modelToggleHost.fittingSize.width))"
        )

        let suiteName = "com.antigravity.agyhub.tests.showmodel.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        MainActor.assumeIsolated {
            let store = AGYHubStore(startMonitoring: false, userDefaults: defaults)
            expect(!store.showSessionModelColumn, "是否展示会话模型默认必须关闭")
            store.toggleSessionModelColumn(true)
            expect(store.showSessionModelColumn, "开启后应立即更新状态")

            let reloaded = AGYHubStore(startMonitoring: false, userDefaults: defaults)
            expect(reloaded.showSessionModelColumn, "重启重新实例化后应持久化保留展示模型选项")
            reloaded.toggleSessionModelColumn(false)
            expect(!reloaded.showSessionModelColumn, "关闭后应同步持久化")
        }

        expect(!L10n.t(.showSessionModelToggle, .zhHans).isEmpty, "设置项中文文案不得为空")
        expect(!containsCJK(L10n.t(.showSessionModelToggle, .en)), "设置项英文文案不得残留中文")
    }

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
        let perm = (try? FileManager.default.attributesOfItem(atPath: path)[.posixPermissions] as? NSNumber)?.intValue
        expectEqual(perm, 0o600, "CLI token 文件写入后权限必须为 0600")
    }

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

    static func testCliFileModeCommandUsesAcpLoginFlag() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }
        let cmd = AGYHubStore.buildCLIFileModeLoginCommand(homeDir: home)
        expect(cmd.hasPrefix("\(CLIAccountManager.fileTokenModeEnv) "), "登录命令必须带有 SSH_CLIENT=1 前缀")
        expect(cmd.contains(" acp --login"), "登录命令必须使用 acp --login 原地授权覆写，不依赖提前删文件 (cmd=\(cmd))")
    }

    static func testOfficialCLIUsageProbeEnvironmentAndVersionGate() {
        expect(!AccountQuotaManager.isSupportedCLIVersion("1.1.10"), "低于 1.1.11 的 agy 必须被拦截，防止把 /usage 当普通 prompt 消耗额度")
        expect(!AccountQuotaManager.isSupportedCLIVersion("0.9.99"), "旧版本必须被拦截")
        expect(AccountQuotaManager.isSupportedCLIVersion("1.1.11"), "1.1.11 起应允许无消耗执行 /usage")
        expect(AccountQuotaManager.isSupportedCLIVersion("agy version 1.5.18\n"), "应能从带前缀的版本输出解析出 1.5.18")

        let dirtyBase: [String: String] = [
            "PATH": "/opt/homebrew/bin:/usr/bin:/bin",
            "SSH_CLIENT": "10.0.0.1 5555 22",
            "SSH_TTY": "/dev/ttys001",
            "SSH_CONNECTION": "10.0.0.1 5555 10.0.0.2 22",
            "GEMINI_API_KEY": "AIza-stray-key"
        ]
        let appEnv = AccountQuotaManager.buildUsageProbeEnvironment(
            baseEnvironment: dirtyBase,
            target: .activeApp,
            homeDir: "/tmp/testhome"
        )
        expectEqual(appEnv["HOME"], "/tmp/testhome", "应锁定 HOME")
        expectEqual(appEnv["AGY_CLI_DISABLE_AUTO_UPDATE"], "true", "必须禁用后台自动更新")
        expect(appEnv["SSH_CLIENT"] == nil && appEnv["SSH_TTY"] == nil && appEnv["SSH_CONNECTION"] == nil, "App 槽位探针必须剥离 SSH 变量以使用系统钥匙串")
        expect(appEnv["GEMINI_API_KEY"] == nil, "必须剥离 GEMINI_API_KEY 避免退出码 2 无配额报错")

        let cliEnv = AccountQuotaManager.buildUsageProbeEnvironment(
            baseEnvironment: [:],
            target: .activeCLI,
            homeDir: "/tmp/testhome"
        )
        expectEqual(cliEnv["SSH_CLIENT"], "1", "独立 CLI 槽位探针必须注入 SSH_CLIENT=1 读取 CLI 文件凭证")
        expectEqual(cliEnv["AGY_CLI_DISABLE_AUTO_UPDATE"], "true", "CLI 槽位探针同样必须禁用自动更新")

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

    static func testNativeMacOSLaunchConfigFiltersHelpersSanitizesEnvAndAllowsFullShutdownWindow() {

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

        let minimalClean = AntigravityLaunchConfig.sanitizedLaunchEnvironment(from: [
            "HOME": "/tmp/testuser",
            "USER": "testuser",
            "SSH_AUTH_SOCK": ""
        ])
        expect(minimalClean["SSH_AUTH_SOCK"] == nil, "空 SSH_AUTH_SOCK 不应注入干净环境")
        expectEqual(minimalClean["PATH"], "/usr/bin:/bin:/usr/sbin:/sbin", "缺失 PATH 时仍应补齐 LaunchServices 标准 PATH")

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

        expect(
            AntigravityLaunchConfig.gracefulShutdownTimeoutSeconds >= 6.0,
            "优雅退出等待超时必须 >= 6.0s 以覆盖 Antigravity 5s killLanguageServer() 收尾窗口"
        )

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
        expect(!SessionRowBadgePolicy.showsLiveTps(for: parent), "主会话本身待命时，列表右侧不应渲染主会话历史 t/s，只能由子 Agent 徽章展示子代理速率")

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

        let leakedSub = try! JSONDecoder().decode(SessionItem.self, from: subActiveJSON.data(using: .utf8)!)
        let filtered = SessionListFilter.sessionsForDisplay([parent, leakedSub])
        expectEqual(filtered.map(\.uuid), [parent.uuid], "Swift 侧也必须防止同父子 Agent 在外层列表重复平铺")

        let sortedSubs = SessionDetailSubagentPolicy.sortedSubagents(parent.subagents)
        expectEqual(sortedSubs.first?.agentName, "verifier", "详情内子 Agent 应将运行中的 verifier 排在最前")
        expectEqual(SessionDetailSubagentPolicy.displayName(for: sortedSubs.first!), "verifier", "详情子 Agent 显示名优先取 agent_name")

        let foundChild = SessionLookup.findSession(uuid: "5def2d27-e860-4e6f-9e23-eb2ae3efc515", in: [parent])
        expectEqual(foundChild?.agentName, "verifier", "应能从父会话嵌套列表中递归查找到目标子 Agent 以支持详情下钻")

        expectEqual(SessionLookup.maxStallSeconds(in: [parent]), 18.0, "活跃子 Agent 的排队/卡顿耗时 18s 必须计入全局最长等待统计")

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

    static func testAccountListSortsByMostRecentlyUsedOrder() {

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

    static func testWindowResizeEdgePolicyHitZonesAndAnchoredFrameMath() {
        let bounds = NSRect(x: 0, y: 0, width: 464, height: 520)

        expectEqual(WindowResizeEdgePolicy.resizeEdge(at: NSPoint(x: 4, y: 260), in: bounds), .left, "左边缘 8pt 内应命中 .left")
        expectEqual(WindowResizeEdgePolicy.resizeEdge(at: NSPoint(x: 460, y: 260), in: bounds), .right, "右边缘 8pt 内应命中 .right")
        expectEqual(WindowResizeEdgePolicy.resizeEdge(at: NSPoint(x: 230, y: 517), in: bounds), .top, "上边缘 6.5pt 内应命中 .top")
        expectEqual(WindowResizeEdgePolicy.resizeEdge(at: NSPoint(x: 230, y: 3), in: bounds), .bottom, "下边缘 6.5pt 内应命中 .bottom")

        expectEqual(WindowResizeEdgePolicy.resizeEdge(at: NSPoint(x: 12, y: 12), in: bounds), [.bottom, .left], "左下 16x16pt 圆角内应命中斜向左下角缩放")
        expectEqual(WindowResizeEdgePolicy.resizeEdge(at: NSPoint(x: 452, y: 12), in: bounds), [.bottom, .right], "右下 16x16pt 圆角内应命中斜向右下角缩放")
        expectEqual(WindowResizeEdgePolicy.resizeEdge(at: NSPoint(x: 12, y: 508), in: bounds), [.top, .left], "左上 16x16pt 圆角内应命中斜向左上角缩放")
        expectEqual(WindowResizeEdgePolicy.resizeEdge(at: NSPoint(x: 452, y: 508), in: bounds), [.top, .right], "右上 16x16pt 圆角内应命中斜向右上角缩放")

        expectEqual(WindowResizeEdgePolicy.resizeEdge(at: NSPoint(x: 200, y: 200), in: bounds), nil, "面板内部不得命中缩放热区")
        expectEqual(WindowResizeEdgePolicy.resizeEdge(at: NSPoint(x: 435, y: 500), in: bounds), nil, "右上角关闭按钮区域不得被缩放热区遮挡")
        expectEqual(WindowResizeEdgePolicy.resizeEdge(at: NSPoint(x: 435, y: 20), in: bounds), nil, "右下角设置按钮区域不得被缩放热区遮挡")
        expectEqual(WindowResizeEdgePolicy.resizeEdge(at: NSPoint(x: 446, y: 260), in: bounds), nil, "右侧滚动条轨道不得被缩放热区遮挡")

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

    static func testSwitchedAwayBackupAccountKeepsCachedQuotaAndIsNotProbed() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        let now = Date()
        let aliceCached = AccountQuotaSummary(
            email: "alice@example.com",
            isUltra: false,
            geminiQuota: WeeklyQuotaBucket(remainingFraction: 0.71, resetTime: now.addingTimeInterval(3 * 86400), resetTimeStr: nil),
            argonQuota: nil,
            geminiFiveHourQuota: WeeklyQuotaBucket(remainingFraction: 0.55, resetTime: now.addingTimeInterval(3600), resetTimeStr: nil),
            lastFetched: now
        )
        AccountQuotaManager.saveQuotaCache(["alice@example.com": aliceCached], homeDir: home)

        let bobJSON = """
        {"status":"SUCCESS","num_turns":0,"command":{"name":"usage","data":{"groups":[{"name":"Gemini Models","buckets":[{"id":"gemini-weekly","window":"weekly","remaining_fraction":0.92,"reset_time":"2099-01-08T00:00:00Z"},{"id":"gemini-5h","window":"5h","remaining_fraction":0.84,"reset_time":"2099-01-01T05:00:00Z"}]}]}}}
        """.data(using: .utf8)!

        let suiteName = "com.antigravity.agyhub.tests.switchpreserve.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var probedTargets: [(email: String, slot: AccountQuotaManager.QuotaSlotTarget)] = []
        MainActor.assumeIsolated {
            let store = AGYHubStore(startMonitoring: false, userDefaults: defaults, homeDir: home)
            store.profiles = [
                AGYProfile(name: "alice@example.com", email: "alice@example.com", userDataDir: ""),
                AGYProfile(name: "bob@example.com", email: "bob@example.com", userDataDir: "")
            ]
            store.expectedAppEmail = "bob@example.com"
            store.appStorageEmail = "bob@example.com"
            store.isCLIIndependentMode = false
            store.quotaProbeRunner = { target, email, _, _ in
                probedTargets.append((email: email, slot: target))
                return (0, bobJSON, Data())
            }

            store.refreshQuotasIfNeeded(force: true)
            let deadline = Date().addingTimeInterval(2.0)
            while !store.fetchingQuotaEmails.isEmpty && Date() < deadline {
                RunLoop.main.run(until: Date().addingTimeInterval(0.02))
            }

            expectEqual(probedTargets.count, 1, "切到 bob 后只能探测当前活跃账号 bob，绝不能后台轮询已切走的 alice")
            expectEqual(probedTargets.first?.email, "bob@example.com", "应只探测新活跃账号 bob")
            expectEqual(probedTargets.first?.slot, .activeApp, "单轨模式应走 activeApp 槽位")
            expectEqual(store.accountQuotas["bob@example.com"]?.geminiQuota?.percentage, 92, "bob 应更新为新拉取配额")
            expectEqual(store.accountQuotas["alice@example.com"]?.geminiQuota?.percentage, 71, "被切走的 alice 必须保持切换前的周配额")
            expectEqual(store.accountQuotas["alice@example.com"]?.geminiFiveHourQuota?.percentage, 55, "被切走的 alice 必须保持切换前的 5h 配额")
            expect(!store.expiredQuotaEmails.contains("alice@example.com"), "被切走的 alice 不得因后台未续期而被误标为过期")
            store.shutdownBackgroundWorkers()
        }
    }

    static func testEffectiveExpectedAppEmailHoldsWithin30sSwitchLaunchWindow() {
        let tSwitch = glogDate(11, 15, 11, 36, 46).timeIntervalSince1970
        let switchState = CLIAccountManager.CLIActiveState(email: "eve@example.com", switchedAt: tSwitch)

        let duringLaunchWindow = KeychainDriftPolicy.effectiveExpectedAppEmail(
            appStorageEmail: "dave@example.com",
            desktopAppAuthDate: Date(timeIntervalSince1970: tSwitch + 2.7),
            expectedSwitchState: switchState
        )
        expectEqual(duringLaunchWindow, "eve@example.com", "切号后 30 秒启动窗口内不得被刚启动时的 Auth succeeded 翻回旧账号")

        let afterWindow = KeychainDriftPolicy.effectiveExpectedAppEmail(
            appStorageEmail: "dave@example.com",
            desktopAppAuthDate: Date(timeIntervalSince1970: tSwitch + 35.0),
            expectedSwitchState: switchState
        )
        expectEqual(afterWindow, "dave@example.com", "超过 30 秒保护窗后的桌面端重登应切换预期账号为 app_storage 邮箱")
    }

    static func testSharedKeychainCaptureAndRestoreVerifyEmbeddedCredentialEmail() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }
        let pRoot = "\(home)/.agy-profiles"

        let daveRaw = credentialJSON(email: "dave@example.com", accessToken: "ya29.DAVE")
        let aliceRaw = credentialJSON(email: "alice@example.com", accessToken: "ya29.ALICE")
        let appStorage = "\(home)/Library/Application Support/Antigravity/app_storage.json"
        let lsLog = "\(home)/Library/Logs/Antigravity/language_server.log"

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

    static func testCLIRefreshPolicySkipsWhileAppSwitchInProgress() {
        expect(KeychainDriftPolicy.shouldSkipCLIStateRefresh(isRefreshing: false, isAppSwitchInProgress: true), "App 切号进行中必须跳过并发状态刷新")
        expect(KeychainDriftPolicy.shouldSkipCLIStateRefresh(isRefreshing: true, isAppSwitchInProgress: false), "上一轮刷新未结束时必须跳过")
        expect(!KeychainDriftPolicy.shouldSkipCLIStateRefresh(isRefreshing: false, isAppSwitchInProgress: false), "空闲状态下允许正常刷新")
    }

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

        let todaySummary = UsageAnalyticsPolicy.summarize(payload: payload, range: .today)
        expectEqual(todaySummary.bars.count, 24, "今天视图应包含 24 个小时柱")
        expect(abs(todaySummary.totalCostUsd - 5.0) < 0.001, "今日总费用应为 $5.00")
        expectEqual(todaySummary.totalTokens, 3000, "今日总 Tokens 应为 3000")
        expectEqual(todaySummary.models.first?.model, "claude-sonnet-5-5", "模型列表必须按费用降序，Claude $3 排在 Hydrogen $2 之前")
        expect(abs((todaySummary.models.first?.costSharePct ?? 0) - 60.0) < 0.1, "Claude 今日费用占比应为 60%")

        let sum7 = UsageAnalyticsPolicy.summarize(payload: payload, range: .last7Days)
        expectEqual(sum7.bars.count, 7, "最近 7 天应包含 7 个日柱")
        expect(abs(sum7.totalCostUsd - 35.0) < 0.001, "最近 7 天总费用应为 $35.00")
        expectEqual(sum7.models.first?.model, "claude-sonnet-5-5", "近 7 天 Claude $21 应排第一")

        let sum30 = UsageAnalyticsPolicy.summarize(payload: payload, range: .last30Days)
        expectEqual(sum30.bars.count, 30, "最近一个月应包含 30 个日柱")
        expect(abs(sum30.totalCostUsd - 58.0) < 0.001, "最近 30 天总费用应为 $58.00")
        expectEqual(sum30.models.first?.model, "gemini-4-hydrogen", "近 30 天 Hydrogen $37 应超越 Claude $21 排第一")

        let ticks30 = UsageAnalyticsPolicy.xAxisTickLabels(for: sum30.bars, range: .last30Days)
        expect(ticks30.count <= 7, "30 天视图 X 轴刻度应保持稀疏不拥挤")
        expectEqual(UsageAnalyticsPolicy.xAxisTickLabels(for: sum7.bars, range: .last7Days).count, 7, "7 天视图 X 轴应完整显示 7 天")
    }

    static func testUsageAnalyticsEdgeCasesEmptyDataAndZeroCostTokens() {
        let empty = UsageHistoryPayload(generatedAt: "", todayDate: "2026-11-16", daysRequested: 30, daily: [], todayHourly: [])
        let sum = UsageAnalyticsPolicy.summarize(payload: empty, range: .last7Days)
        expectEqual(sum.totalTokens, 0, "空数据时总 Tokens 为 0")
        expectEqual(sum.totalCostUsd, 0.0, "空数据时总费用为 0")
        expect(!sum.cachePct.isNaN && !sum.cachePct.isInfinite, "空数据缓存命中率不得为 NaN")
        expect(sum.models.isEmpty, "空数据时模型排行列表为空")
        expect(sum.conversations.isEmpty, "空数据时按对话列表为空")
    }

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

        let todaySum = UsageAnalyticsPolicy.summarize(payload: payload, range: .today)
        expectEqual(todaySum.conversations.count, 2, "今天应有 2 个活跃对话")
        expectEqual(todaySum.conversations.first?.uuid, "conv-b", "按费用降序时今天 Task B ($4.5) 应排第一")
        let byTokensToday = UsageAnalyticsPolicy.sortedConversations(todaySum.conversations, by: .tokens)
        expectEqual(byTokensToday.first?.uuid, "conv-a", "按 Tokens 降序时今天 Task A (200k) 应排第一")

        let sum30 = UsageAnalyticsPolicy.summarize(payload: payload, range: .last30Days)
        expectEqual(sum30.conversations.count, 3, "近 30 天合并去重后应有 3 个独立对话")
        expectEqual(sum30.conversations.first?.uuid, "conv-old", "Old Task ($10) 排第一")
        let convA = sum30.conversations.first(where: { $0.uuid == "conv-a" })
        expect(abs((convA?.costUsd ?? 0) - 5.5) < 0.001, "跨天对话 conv-a 费用应累加 ($4.0 + $1.5 = $5.5)")
        expectEqual(convA?.totalTokens, 400000, "跨天对话 conv-a Tokens 应累加为 400000")
        expectEqual(convA?.subagentCount, 2, "子 Agent 数应取最大值 2")
        expectEqual(convA?.clientType, "cli", "应保留 CLI 来源端标记")
    }

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
        expect(!Recent503Policy.shouldShowBadge(count: 0), "503 为 0 时不得展示 503 胶囊")
        expect(!Recent503Policy.shouldShowBadge(count: -1), "503 为负数时不得展示 503 胶囊")
        expect(Recent503Policy.shouldShowBadge(count: 1), "存在至少 1 次 503 时应展示 503 胶囊")
        expect(Recent503Policy.shouldShowBadge(count: 58), "存在多次 503 时应展示 503 胶囊")
    }

    static func testNativeWindowActivationPolicyAndMainMenuContract() {
        expect(WindowActivationPolicy.targetPolicy(hasVisibleWindows: true) == .regular, "有窗口可见时应切为 .regular，使 Mac 顶部系统菜单栏正常工作")
        expect(WindowActivationPolicy.targetPolicy(hasVisibleWindows: false) == .accessory, "无窗口可见时应切回 .accessory，保持纯净状态栏常驻")

        let menu = AGYAppDelegate.buildMainMenu(target: nil)
        expect(menu.items.count >= 3, "原生主菜单应至少包含 应用 / 编辑 / 窗口 三栏")
        let titles = menu.items.compactMap { $0.submenu?.title }
        expect(titles.contains("编辑"), "主菜单应包含 编辑 菜单以支持系统级复制粘贴快捷键")
        expect(titles.contains("窗口"), "主菜单应包含 窗口 菜单以支持原生 Cmd+W 关闭窗口")
    }

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

    static func testActiveQuotaTargetsDeduplicateSharedAppAndCLIAccount() {
        let profiles = [
            AGYProfile(name: "app@example.com", email: "app@example.com", tier: "Google AI Ultra", userDataDir: ""),
            AGYProfile(name: "cli@example.com", email: "cli@example.com", tier: "Google AI Pro", userDataDir: ""),
            AGYProfile(name: "backup@example.com", email: "backup@example.com", tier: "Google AI Pro", userDataDir: "")
        ]

        let splitTargets = AccountQuotaManager.resolveActiveQuotaTargets(
            profiles: profiles,
            activeAppEmail: "APP@example.com",
            activeCLIEmail: "cli@example.com",
            isCLIIndependentMode: true
        )
        expectEqual(
            splitTargets,
            [
                AccountQuotaManager.QuotaProbeTarget(email: "app@example.com", tier: "Google AI Ultra", slot: .activeApp),
                AccountQuotaManager.QuotaProbeTarget(email: "cli@example.com", tier: "Google AI Pro", slot: .activeCLI)
            ],
            "独立模式下 App 与 CLI 登录不同账号时，应分别探测 App 与 CLI 两个活跃槽位，忽略 backup"
        )

        let sharedTargets = AccountQuotaManager.resolveActiveQuotaTargets(
            profiles: profiles,
            activeAppEmail: "app@example.com",
            activeCLIEmail: "app@example.com",
            isCLIIndependentMode: true
        )
        expectEqual(
            sharedTargets,
            [AccountQuotaManager.QuotaProbeTarget(email: "app@example.com", tier: "Google AI Ultra", slot: .activeApp)],
            "App 与 CLI 登录同一账号时，只能探测 1 次并复用结果"
        )

        let singleModeTargets = AccountQuotaManager.resolveActiveQuotaTargets(
            profiles: profiles,
            activeAppEmail: "app@example.com",
            activeCLIEmail: "cli@example.com",
            isCLIIndependentMode: false
        )
        expectEqual(
            singleModeTargets,
            [AccountQuotaManager.QuotaProbeTarget(email: "app@example.com", tier: "Google AI Ultra", slot: .activeApp)],
            "关闭独立 CLI 模式时只应探测 .activeApp"
        )
    }

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

        debouncer.signal()
        let wait2 = firstBatchExpectation.wait(timeout: .now() + 1.0)
        expect(wait2 == .success, "超过防抖窗口后的新事件应再次触发")
        lock.lock()
        let countAfterSecond = fireCount
        lock.unlock()
        expectEqual(countAfterSecond, 2, "间隔事件应独立计为第 2 次触发")

        debouncer.signal()
        debouncer.cancel()
        Thread.sleep(forTimeInterval: 0.25)
        lock.lock()
        let countAfterCancel = fireCount
        lock.unlock()
        expectEqual(countAfterCancel, 2, "cancel() 后待触发任务不应再执行")
    }

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

        let sessionDir = "\(existingBrain)/sess-abc"
        try? FileManager.default.createDirectory(atPath: sessionDir, withIntermediateDirectories: true)
        try? "{\"step\":1}\n".write(toFile: "\(sessionDir)/transcript.jsonl", atomically: true, encoding: .utf8)
        try? "{\"step\":2}\n".write(toFile: "\(sessionDir)/transcript.jsonl", atomically: true, encoding: .utf8)

        let gotInitialEvent = changedSem.wait(timeout: .now() + 3.0)
        expect(gotInitialEvent == .success, "已监听目录发生真实写入时 FSEvents 应触发回调")

        Thread.sleep(forTimeInterval: 0.2)
        while changedSem.wait(timeout: .now()) == .success {}

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

        try? "ok".write(toFile: modeFile, atomically: true, encoding: .utf8)
        Thread.sleep(forTimeInterval: 0.32)
        if case .success(let pong) = client.ping(dataDir: home) {
            expect(pong, "退避窗口结束后应自动重建 daemon 并恢复正常")
        } else {
            expect(false, "退避窗口结束后 daemon 应自愈成功")
        }

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

    static func testQuotaExpiredMissingCredentialsGentleHint() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        let sem = DispatchSemaphore(value: 0)
        var result: AccountQuotaManager.QuotaFetchResult? = nil
        Task {
            result = await AccountQuotaManager.fetchActiveSlotQuota(
                target: .activeApp,
                email: "active-expired@example.com",
                tier: nil,
                homeDir: home,
                runCLI: { _, _ in
                    (1, Data(), "Authentication failed: please sign in".data(using: .utf8)!)
                }
            )
            sem.signal()
        }
        sem.wait()

        expectEqual(result, .authRequired, "官方 CLI 返回登录失效时应返回 .authRequired")

        let zhHint = L10n.quotaExpiredHint(for: .zhHans)
        let enHint = L10n.quotaExpiredHint(for: .en)
        expect(!zhHint.isEmpty && !enHint.isEmpty, "过期提示中英文均不能为空")
        expect(!zhHint.contains("AGYHUB_OAUTH") && !zhHint.contains("oauth_client.json") && !zhHint.contains("401"), "中文提示不得暴露吓人的开发配置报错")
        expect(!enHint.contains("AGYHUB_OAUTH") && !enHint.contains("oauth_client.json") && !enHint.contains("401"), "英文提示不得暴露吓人的开发配置报错")
        expect(enHint.lowercased().contains("switch"), "英文提示应引导用户切换账号即可刷新")
    }

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

        let accounts = (0..<8).map { "concurrent-\($0)@example.com" }
        let sem = DispatchSemaphore(value: 0)
        var results: [AccountQuotaManager.QuotaFetchResult] = []
        Task {
            let collected = await withTaskGroup(of: AccountQuotaManager.QuotaFetchResult.self) { tg in
                for email in accounts {
                    tg.addTask {
                        return await AccountQuotaManager.fetchActiveSlotQuota(
                            target: .activeApp,
                            email: email,
                            tier: nil,
                            homeDir: home,
                            runCLI: { _, _ in
                                (1, Data(), "unauthenticated".data(using: .utf8)!)
                            }
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
        expectEqual(results.count, accounts.count, "并发配额探针请求应全部安全返回")
        expectEqual(results.allSatisfy { $0 == .authRequired }, true, "并发认证失效返回时应全部归类为 .authRequired")

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
            store.expectedAppEmail = accounts[0]
            store.appStorageEmail = accounts[0]
            store.activeCLIProfileName = accounts[1]
            store.isCLIIndependentMode = true
            store.quotaProbeRunner = { _, _, _, _ in
                (1, Data(), "network timeout".data(using: .utf8)!)
            }
            store.refreshQuotasIfNeeded(force: true)
            expectEqual(store.fetchingQuotaEmails.count, 2, "只应并发刷新活跃的 App 与 CLI 共 2 个账号，不得轮询其余 6 个备用号")
            let deadline = Date().addingTimeInterval(2.0)
            while !store.fetchingQuotaEmails.isEmpty && Date() < deadline {
                RunLoop.main.run(until: Date().addingTimeInterval(0.02))
            }
            expect(store.fetchingQuotaEmails.isEmpty, "活跃槽位并发 refreshQuotasIfNeeded 结束后应清空进行中集合")
            store.shutdownBackgroundWorkers()
        }
        LocalAccountDetector.clearDiscoveryLogs()
    }

    static func testQuotaCredentialFreshnessPriorityAnd401Fallback() {
        let nonZeroTurnsJSON = """
        {"status":"SUCCESS","num_turns":1,"command":{"name":"usage","data":{"groups":[{"name":"Gemini Models","buckets":[{"id":"gemini-weekly","window":"weekly","remaining_fraction":0.85,"reset_time":"2099-01-08T00:00:00Z"}]}]}}}
        """.data(using: .utf8)!
        let turnRejected = AccountQuotaManager.parseUsageCommandResult(
            data: nonZeroTurnsJSON,
            email: "user@example.com",
            tier: nil
        )
        expectEqual(turnRejected, .failed, "num_turns > 0 说明误触了真实模型回合，必须拒绝消费该输出")

        let wrongCmdJSON = """
        {"status":"SUCCESS","num_turns":0,"command":{"name":"help","data":{"groups":[]}}}
        """.data(using: .utf8)!
        let wrongCmdRes = AccountQuotaManager.parseUsageCommandResult(
            data: wrongCmdJSON,
            email: "user@example.com",
            tier: nil
        )
        expectEqual(wrongCmdRes, .failed, "command.name 非 usage 时必须拒绝解析")

        let errorStatusJSON = """
        {"status":"ERROR","num_turns":0,"response":"Please login with agy acp --login"}
        """.data(using: .utf8)!
        let errorRes = AccountQuotaManager.parseUsageCommandResult(
            data: errorStatusJSON,
            email: "user@example.com",
            tier: nil
        )
        expectEqual(errorRes, .authRequired, "status == ERROR 且包含登录提示时必须识别为 .authRequired")
    }

    static func testQuotaCachePersistenceRoundTrip() {
        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }

        let now = Date()
        let email = "cached-user@example.com"
        let summary = AccountQuotaSummary(
            email: email,
            isUltra: true,
            geminiQuota: WeeklyQuotaBucket(remainingFraction: 0.78, resetTime: now.addingTimeInterval(3 * 86400), resetTimeStr: nil),
            argonQuota: nil,
            lastFetched: now
        )

        AccountQuotaManager.saveQuotaCache([email: summary], homeDir: home)
        let cachePath = AccountQuotaManager.quotaCachePath(homeDir: home)
        expect(FileManager.default.fileExists(atPath: cachePath), "saveQuotaCache 应自动创建目录并落盘 quota_cache.json")

        let loaded = AccountQuotaManager.loadQuotaCache(homeDir: home)
        expectEqual(loaded[email]?.geminiQuota?.percentage, 78, "loadQuotaCache 应完整恢复上次缓存的周度配额百分比")

        let suiteName = "com.antigravity.agyhub.tests.quotacache.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        MainActor.assumeIsolated {
            let store = AGYHubStore(startMonitoring: false, userDefaults: defaults, homeDir: home)
            expectEqual(store.accountQuotas[email]?.geminiQuota?.percentage, 78, "AGYHubStore 启动时应自动从本地缓存恢复 accountQuotas")
            expectEqual(store.accountQuotas["cached-user"]?.geminiQuota?.percentage, 78, "AGYHubStore 启动恢复缓存时应同时建立短名索引")
            store.shutdownBackgroundWorkers()
        }
    }

    static func testActiveAccountNativeRenewalPolicyAndNeutralOAuthErrorLog() {
        let targets = AccountQuotaManager.resolveActiveQuotaTargets(
            profiles: [
                AGYProfile(name: "app@example.com", email: "app@example.com", userDataDir: ""),
                AGYProfile(name: "cli@example.com", email: "cli@example.com", userDataDir: ""),
                AGYProfile(name: "backup@example.com", email: "backup@example.com", userDataDir: "")
            ],
            activeAppEmail: "app@example.com",
            activeCLIEmail: "cli@example.com",
            isCLIIndependentMode: true
        )
        expect(targets.contains(where: { $0.email == "app@example.com" && $0.slot == .activeApp }), "当前活跃桌面 App 账号应匹配 .activeApp")
        expect(targets.contains(where: { $0.email == "cli@example.com" && $0.slot == .activeCLI }), "独立 CLI 模式下活跃 CLI 账号应匹配 .activeCLI")
        expect(!targets.contains(where: { $0.email == "backup@example.com" }), "闲置备用账号不得出现在任何活跃探针目标里")

        let zhHint = L10n.quotaExpiredHint(for: .zhHans)
        let enHint = L10n.quotaExpiredHint(for: .en)
        expect(!zhHint.contains("请创建") && !zhHint.contains("oauth_client.json"), "中文过期提示不得诱导用户手建 oauth_client.json")
        expect(!enHint.contains("oauth_client.json"), "英文过期提示不得诱导用户手建 oauth_client.json")
    }

    private static func currentTaskFootprintBytes() -> UInt64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size) / 4
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return kr == KERN_SUCCESS ? UInt64(info.phys_footprint) : 0
    }

    static func testMonitorDaemonClientHasBoundedMemoryAcrossRepeatedSnapshots() {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("agyhub-tdd-mem-\(UUID().uuidString)")
            .path
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }

        let scriptPath = "\(dir)/mock_mem_daemon.py"
        let mockPy = #"""
import sys, json
payload = {
    "timestamp": "2026-11-22T00:00:00+00:00",
    "data_dir": "/tmp/mock",
    "active_count": 1,
    "total_roundtrips": 20,
    "has_alert": False,
    "today_stats": {"total_tokens": 1000, "cache_tokens": 800, "input_tokens": 100, "output_tokens": 100, "cache_pct": 80.0, "cost_usd": 1.0, "has_data": True, "source": "mock"},
    "menubar": {"icon": "⚡️", "text": "test", "status_level": "active", "active_count": 1, "tooltip": "tip"},
    "sessions": [
        {
            "uuid": f"sess-{i}",
            "title": "Memory Stress Session Title " + ("x" * 40),
            "is_running": False,
            "model": "gemini-4-hydrogen",
            "interactions": 20,
            "tps": 100.0,
            "input_tokens": 1000,
            "cache_tokens": 9000,
            "output_tokens": 500,
            "total_tokens_consumed": 10500,
            "cache_pct": 90.0,
            "total_cost_usd": 0.5,
            "total_local_sec": 10.0,
            "total_remote_sec": 20.0,
            "current_stall": 0.0,
            "health": "🟢",
            "health_code": "ok",
            "health_desc": "ok",
            "history_steps": [{"index": k, "type": "PLANNER_RESPONSE", "time": "09:00:00", "summary": "step summary " + ("y" * 30)} for k in range(10)],
            "subagents": [{"uuid": f"sub-{i}-{j}", "title": "Subagent " + ("z" * 30), "is_running": False} for j in range(5)]
        }
        for i in range(15)
    ]
}
for line in sys.stdin:
    req = json.loads(line)
    resp = {"id": req["id"], "ok": True, "unchanged": False, "etag": f"etag-{req['id']}", "payload": payload}
    sys.stdout.write(json.dumps(resp) + "\n")
    sys.stdout.flush()
"""#
        try? mockPy.write(toFile: scriptPath, atomically: true, encoding: .utf8)

        let client = MonitorDaemonClient(requestTimeout: 5.0) { _ in
            ("/usr/bin/python3", [scriptPath])
        }

        autoreleasepool {
            _ = client.fetchSnapshot(ifNoneMatch: nil, dataDir: nil, lang: "zh")
        }
        let baselineBytes = currentTaskFootprintBytes()

        for i in 0..<300 {
            autoreleasepool {
                let res = client.fetchSnapshot(ifNoneMatch: nil, dataDir: nil, lang: "zh")
                if case .failure(let err) = res {
                    expect(false, "第 \(i) 次 mock daemon 快照请求失败: \(err)")
                }
            }
        }
        client.shutdown()
        Thread.sleep(forTimeInterval: 0.15)

        let endBytes = currentTaskFootprintBytes()
        let deltaMB = Double(Int64(endBytes) - Int64(baselineBytes)) / (1024.0 * 1024.0)
        expect(deltaMB <= 2.5, String(format: "连续 300 次大快照后 MonitorDaemonClient 内存增长必须可控 (<=2.5MB)，当前泄漏: %.2f MB", deltaMB))
    }

    static func testVisibilityAwareFSEventsCLIThrottleAndBoundedLogs() {
        let now = Date()

        expect(
            PollingSchedulePolicy.shouldAttemptFSEventFetch(lastTriggeredAt: now.addingTimeInterval(-0.5), isDashboardVisible: true, now: now),
            "弹窗可见时 FSEvents 在防抖后应立即触发刷新"
        )
        expect(
            !PollingSchedulePolicy.shouldAttemptFSEventFetch(lastTriggeredAt: now.addingTimeInterval(-1.0), isDashboardVisible: false, now: now),
            "弹窗隐藏时 FSEvents 1 秒内不得重复触发快照，防止后台高频空转"
        )
        expect(
            PollingSchedulePolicy.shouldAttemptFSEventFetch(lastTriggeredAt: now.addingTimeInterval(-5.0), isDashboardVisible: false, now: now),
            "弹窗隐藏且超过最小间隔后应允许 FSEvents 增量同步"
        )

        expect(
            !PollingSchedulePolicy.shouldRefreshCLIState(
                lastRefreshedAt: now.addingTimeInterval(-5.0),
                isRefreshing: false,
                isAppSwitchInProgress: false,
                isDashboardVisible: true,
                force: false,
                now: now
            ),
            "可见态 10 秒冷却期内常规轮询不得重复扫盘检测 CLI 日志"
        )
        expect(
            PollingSchedulePolicy.shouldRefreshCLIState(
                lastRefreshedAt: now.addingTimeInterval(-12.0),
                isRefreshing: false,
                isAppSwitchInProgress: false,
                isDashboardVisible: true,
                force: false,
                now: now
            ),
            "可见态超过 10 秒冷却后应放行 CLI 状态刷新"
        )
        expect(
            !PollingSchedulePolicy.shouldRefreshCLIState(
                lastRefreshedAt: now.addingTimeInterval(-15.0),
                isRefreshing: false,
                isAppSwitchInProgress: false,
                isDashboardVisible: false,
                force: false,
                now: now
            ),
            "隐藏态 30 秒冷却期内常规轮询不得扫盘检测 CLI 状态"
        )
        expect(
            PollingSchedulePolicy.shouldRefreshCLIState(
                lastRefreshedAt: now.addingTimeInterval(-2.0),
                isRefreshing: false,
                isAppSwitchInProgress: false,
                isDashboardVisible: false,
                force: true,
                now: now
            ),
            "用户主动切号或显式强刷时应无视冷却立即刷新"
        )
        expect(
            !PollingSchedulePolicy.shouldRefreshCLIState(
                lastRefreshedAt: nil,
                isRefreshing: false,
                isAppSwitchInProgress: true,
                isDashboardVisible: true,
                force: true,
                now: now
            ),
            "切号进行中即使 force=true 也必须跳过以防竞态"
        )

        let home = makeTempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }
        LocalAccountDetector.clearDiscoveryLogs()
        let tempLogPath = "\(home)/accounts.log"
        for idx in 0..<1150 {
            LocalAccountDetector.appendLog("bounded-log-line-\(idx)", logFilePath: tempLogPath)
        }
        let snapshot = LocalAccountDetector.snapshotDiscoveryLogs()
        expect(snapshot.count <= LocalAccountDetector.maxInMemoryLogCount, "内存诊断日志列表必须存在上限，当前: \(snapshot.count)")
        expect(snapshot.last?.contains("bounded-log-line-1149") == true, "裁剪后应保留最新日志条目")
    }

    static func testParseFiveHourQuotaBucketAndCapacitySummary() {
        let baseDate = Date(timeIntervalSince1970: 1700000000)
        let reset5hISO = ISO8601DateFormatter().string(from: baseDate.addingTimeInterval(3 * 3600 + 1800))
        let resetWeeklyISO = ISO8601DateFormatter().string(from: baseDate.addingTimeInterval(5 * 86400))

        let jsonStr = """
        {
          "groups": [
            {
              "displayName": "Gemini Models",
              "buckets": [
                {
                  "bucketId": "gemini-weekly",
                  "window": "weekly",
                  "resetTime": "\(resetWeeklyISO)",
                  "remainingFraction": 0.83
                },
                {
                  "bucketId": "gemini-5h",
                  "window": "5h",
                  "resetTime": "\(reset5hISO)",
                  "remainingFraction": 0.64
                }
              ]
            },
            {
              "displayName": "Claude and GPT models",
              "buckets": [
                {
                  "bucketId": "3p-weekly",
                  "window": "weekly",
                  "resetTime": "\(resetWeeklyISO)",
                  "remainingFraction": 1.0
                },
                {
                  "bucketId": "3p-5h",
                  "window": "5h",
                  "resetTime": "\(reset5hISO)",
                  "remainingFraction": 0.05
                }
              ]
            },
            {
              "displayName": "Gemini 4 Argon",
              "buckets": [
                {
                  "bucketId": "gemini-argon-wtu-weekly",
                  "window": "weekly",
                  "resetTime": "\(resetWeeklyISO)",
                  "remainingFraction": 0.91
                }
              ]
            }
          ]
        }
        """

        guard let data = jsonStr.data(using: .utf8),
              let summary = AccountQuotaManager.parseQuotaSummary(data: data, email: "pro@example.com", tier: "Google AI Pro", now: baseDate) else {
            expect(false, "应成功解析同时包含 5h 与 weekly 的配额响应")
            return
        }

        expectEqual(summary.geminiQuota?.percentage, 83, "周 Gemini 额度应为 83%")
        expectEqual(summary.argonQuota?.percentage, 91, "周 Argon 额度应为 91%")
        expectEqual(summary.geminiFiveHourQuota?.percentage, 64, "5h Gemini 额度应解析为 64%（不得被 Claude/GPT 3p-5h 的 5% 污染）")
        expectEqual(summary.effectiveFiveHourQuota?.percentage, 64, "effectiveFiveHourQuota 应返回 Gemini 5h 额度")

        let display = AccountQuotaManager.fiveHourDisplay(for: summary, from: baseDate, language: .zhHans)
        expectEqual(display?.percentage, 64, "fiveHourDisplay 百分比应为 64%")
        expectEqual(display?.countdown, "3h", "3.5h 倒计时应显示为 3h")
        expect(abs((display?.remainingFraction ?? 0) - 0.64) < 0.001, "capacity bar fraction 应精确对应 0.64")

        let tip = AccountQuotaManager.quotaTooltip(
            items: AccountQuotaManager.displayItems(for: summary, language: .zhHans),
            isUltra: false,
            fiveHourQuota: summary.effectiveFiveHourQuota,
            from: baseDate,
            isExpired: false,
            language: .zhHans
        )
        expect(tip.contains("5h") && tip.contains("64%"), "Tooltip 应同时包含 5h 额度信息: \(tip)")

        let legacyJSON = """
        {"cached@example.com":{"email":"cached@example.com","isUltra":true,"geminiQuota":{"remainingFraction":0.75},"lastFetched":1700000000}}
        """.data(using: .utf8)!
        let decoded = try? JSONDecoder().decode([String: AccountQuotaSummary].self, from: legacyJSON)
        expectEqual(decoded?["cached@example.com"]?.geminiQuota?.percentage, 75, "旧版配额缓存仍应正常解码")
        expect(decoded?["cached@example.com"]?.geminiFiveHourQuota == nil, "旧版无 5h 字段缓存应安全解码为 nil")
        expect(AccountQuotaManager.fiveHourDisplay(for: decoded?["cached@example.com"], from: baseDate, language: .zhHans) == nil, "无 5h 桶时 fiveHourDisplay 应为 nil 而非假 0%")

        let clampedOver = AccountQuotaSummary(
            email: "clamp@example.com",
            isUltra: true,
            geminiQuota: nil,
            argonQuota: nil,
            geminiFiveHourQuota: WeeklyQuotaBucket(remainingFraction: 1.4, resetTime: baseDate.addingTimeInterval(1500), resetTimeStr: nil),
            lastFetched: baseDate
        )
        let clampedDisplay = AccountQuotaManager.fiveHourDisplay(for: clampedOver, from: baseDate, language: .en)
        expectEqual(clampedDisplay?.percentage, 100, "超过 1.0 的 5h 比例应钳制在 100%")
        expectEqual(clampedDisplay?.countdown, "25m", "不足 1h 应显示 25m")
    }

    static func testCompactAccountSummaryResolutionForAppAndCLI() {
        let now = Date()
        let appProfile = AGYProfile(name: "alex.dev@example.com", email: "alex.dev@example.com", userDataDir: "", isDefault: true)
        let cliProfile = AGYProfile(name: "cli.worker@example.com", email: "cli.worker@example.com", userDataDir: "", isDefault: false)
        let quotas: [String: AccountQuotaSummary] = [
            "alex.dev@example.com": AccountQuotaSummary(
                email: "alex.dev@example.com",
                isUltra: false,
                geminiQuota: WeeklyQuotaBucket(remainingFraction: 0.83, resetTime: now.addingTimeInterval(6 * 86400), resetTimeStr: nil),
                argonQuota: WeeklyQuotaBucket(remainingFraction: 1.0, resetTime: now.addingTimeInterval(6 * 86400), resetTimeStr: nil),
                geminiFiveHourQuota: WeeklyQuotaBucket(remainingFraction: 0.72, resetTime: now.addingTimeInterval(4 * 3600), resetTimeStr: nil),
                lastFetched: now
            ),
            "cli.worker@example.com": AccountQuotaSummary(
                email: "cli.worker@example.com",
                isUltra: true,
                geminiQuota: WeeklyQuotaBucket(remainingFraction: 0.96, resetTime: now.addingTimeInterval(6 * 86400), resetTimeStr: nil),
                argonQuota: nil,
                geminiFiveHourQuota: WeeklyQuotaBucket(remainingFraction: 0.90, resetTime: now.addingTimeInterval(2 * 3600), resetTimeStr: nil),
                lastFetched: now
            )
        ]

        let appSnapshot = AccountCompactSummaryPolicy.resolveActiveAccount(
            mode: .app,
            isCLIIndependentMode: true,
            profiles: [appProfile, cliProfile],
            expectedAppEmail: "alex.dev@example.com",
            appStorageEmail: "",
            sharedKeychainEmail: "other@example.com",
            activeProfileName: "default",
            activeCLIProfileName: "cli.worker@example.com",
            accountQuotas: quotas,
            expiredQuotaEmails: [],
            language: .zhHans
        )
        expectEqual(appSnapshot.effectiveMode, .app, "App 模式应解析为 .app")
        expectEqual(appSnapshot.displayName, "alex.dev", "App 模式应展示短账号名")
        expectEqual(appSnapshot.quota?.geminiFiveHourQuota?.percentage, 72, "App 模式应携带对应 5h 配额")
        expect(appSnapshot.isSignedIn, "App 账号非空时应为已登录态")

        let cliSnapshot = AccountCompactSummaryPolicy.resolveActiveAccount(
            mode: .cli,
            isCLIIndependentMode: true,
            profiles: [appProfile, cliProfile],
            expectedAppEmail: "alex.dev@example.com",
            appStorageEmail: "",
            sharedKeychainEmail: nil,
            activeProfileName: "alex.dev@example.com",
            activeCLIProfileName: "cli.worker@example.com",
            accountQuotas: quotas,
            expiredQuotaEmails: ["cli.worker@example.com"],
            language: .zhHans
        )
        expectEqual(cliSnapshot.effectiveMode, .cli, "独立 CLI 模式切到 .cli 时应解析为 .cli")
        expectEqual(cliSnapshot.displayName, "cli.worker", "CLI 模式应展示 CLI 活跃账号名")
        expect(cliSnapshot.isQuotaExpired, "CLI 账号凭据过期应标记 isQuotaExpired")

        let unsignedCLI = AccountCompactSummaryPolicy.resolveActiveAccount(
            mode: .cli,
            isCLIIndependentMode: true,
            profiles: [appProfile, cliProfile],
            expectedAppEmail: "alex.dev@example.com",
            appStorageEmail: "",
            sharedKeychainEmail: nil,
            activeProfileName: "alex.dev@example.com",
            activeCLIProfileName: nil,
            accountQuotas: quotas,
            expiredQuotaEmails: [],
            language: .zhHans
        )
        expect(!unsignedCLI.isSignedIn, "CLI 无活跃账号时应标记未登录")
        expectEqual(unsignedCLI.displayName, L10n.t(.notSignedIn, .zhHans), "CLI 未登录应显示未登录文案")

        let forcedApp = AccountCompactSummaryPolicy.resolveActiveAccount(
            mode: .cli,
            isCLIIndependentMode: false,
            profiles: [appProfile],
            expectedAppEmail: "alex.dev@example.com",
            appStorageEmail: "",
            sharedKeychainEmail: nil,
            activeProfileName: "alex.dev@example.com",
            activeCLIProfileName: "cli.worker@example.com",
            accountQuotas: quotas,
            expiredQuotaEmails: [],
            language: .zhHans
        )
        expectEqual(forcedApp.effectiveMode, .app, "未开启独立 CLI 模式时应回退展示 App 模式")
        expectEqual(AccountTargetMode.app.toggled, .cli, "App 单框点击应切到 CLI")
        expectEqual(AccountTargetMode.cli.toggled, .app, "CLI 单框点击应切回 App")
    }

    static func testCompactAccountCardAndPickerLayoutFitsWithinPanelWidths() {
        let now = Date()
        let p1 = AGYProfile(name: "alex.dev@example.com", email: "alex.dev@example.com", userDataDir: "", isDefault: true)
        let p2 = AGYProfile(name: "cli.worker@example.com", email: "cli.worker@example.com", userDataDir: "", isDefault: false)
        let q1 = AccountQuotaSummary(
            email: "alex.dev@example.com",
            isUltra: false,
            geminiQuota: WeeklyQuotaBucket(remainingFraction: 0.83, resetTime: now.addingTimeInterval(6 * 86400), resetTimeStr: nil),
            argonQuota: WeeklyQuotaBucket(remainingFraction: 1.0, resetTime: now.addingTimeInterval(6 * 86400), resetTimeStr: nil),
            geminiFiveHourQuota: WeeklyQuotaBucket(remainingFraction: 0.80, resetTime: now.addingTimeInterval(4 * 3600), resetTimeStr: nil),
            lastFetched: now
        )
        let q2 = AccountQuotaSummary(
            email: "cli.worker@example.com",
            isUltra: true,
            geminiQuota: WeeklyQuotaBucket(remainingFraction: 0.96, resetTime: now.addingTimeInterval(6 * 86400), resetTimeStr: nil),
            argonQuota: nil,
            geminiFiveHourQuota: WeeklyQuotaBucket(remainingFraction: 0.45, resetTime: now.addingTimeInterval(2 * 3600), resetTimeStr: nil),
            lastFetched: now
        )

        MainActor.assumeIsolated { () -> Void in
            let snapshot = AccountCompactSummaryPolicy.resolveActiveAccount(
                mode: .app,
                isCLIIndependentMode: true,
                profiles: [p1, p2],
                expectedAppEmail: p1.name,
                appStorageEmail: "",
                sharedKeychainEmail: nil,
                activeProfileName: p1.name,
                activeCLIProfileName: p2.name,
                accountQuotas: [p1.name: q1, p2.name: q2],
                expiredQuotaEmails: [],
                language: .zhHans
            )

            let targetMode = AccountTargetMode.app
            let cardView = AccountSummaryCardView(
                targetMode: Binding(get: { targetMode }, set: { _ in }),
                isCLIIndependentMode: true,
                snapshot: snapshot,
                hasSharedKeychainMismatch: false,
                isCLIVaultAuthorized: true,
                isPickerOpen: false,
                onTogglePicker: {},
                onRefreshQuota: {}
            )
            .environment(\.agyLanguage, .zhHans)

            for cardWidth in [CGFloat(436), CGFloat(412)] {
                let hosting = NSHostingView(rootView: cardView.frame(width: cardWidth))
                hosting.layoutSubtreeIfNeeded()
                let fit = hosting.fittingSize
                expect(fit.width <= cardWidth + 0.5, "单行 Account 卡片在 \(Int(cardWidth))pt 容器内不得横向溢出 (actual=\(fit.width))")
                expect(fit.height <= 42.0, "单行 Account 卡片高度应严格保持在单行以内 <= 42pt (actual=\(fit.height))")
            }

            let cliSnapshot = AccountCompactSummaryPolicy.resolveActiveAccount(
                mode: .cli,
                isCLIIndependentMode: true,
                profiles: [p1, p2],
                expectedAppEmail: p1.name,
                appStorageEmail: "",
                sharedKeychainEmail: nil,
                activeProfileName: p1.name,
                activeCLIProfileName: p2.name,
                accountQuotas: [p1.name: q1, p2.name: q2],
                expiredQuotaEmails: [],
                language: .zhHans
            )
            let cliCard = AccountSummaryCardView(
                targetMode: Binding(get: { AccountTargetMode.cli }, set: { _ in }),
                isCLIIndependentMode: true,
                snapshot: cliSnapshot,
                hasSharedKeychainMismatch: false,
                isCLIVaultAuthorized: true,
                isPickerOpen: false,
                onTogglePicker: {},
                onRefreshQuota: {}
            )
            .environment(\.agyLanguage, .zhHans)

            let cliHosting = NSHostingView(rootView: cliCard.frame(width: 412))
            cliHosting.layoutSubtreeIfNeeded()
            let cliFit = cliHosting.fittingSize
            expect(cliFit.width <= 412.5 && cliFit.height <= 42.0, "CLI 单框模式卡片在 412pt 容器内应同样单行不溢出 (actual=\(cliFit))")
        }
    }

    static func testLiveTelemetrySampleExtractionAndRingBufferBounds() {
        let baseDate = Date(timeIntervalSince1970: 1700000000)

        let childRunning = SessionItem(
            uuid: "child-1",
            shortId: "c1",
            parentConversationId: "parent-1",
            title: "Subagent 1",
            isRunning: true,
            interactions: 2,
            inputTokens: 1000,
            cacheTokens: 9000,
            outputTokens: 500,
            contextTokens: 10500,
            cachePct: 90.0,
            tps: 120.0
        )
        let parentIdleWithActiveSubs = SessionItem(
            uuid: "parent-1",
            shortId: "p1",
            title: "Parent",
            isRunning: false,
            interactions: 4,
            inputTokens: 2000,
            cacheTokens: 18000,
            outputTokens: 800,
            contextTokens: 20800,
            cachePct: 90.0,
            tps: 999.0,
            subagents: [childRunning],
            subagentCount: 1,
            activeSubagentCount: 1,
            activeSubagentTps: 120.0
        )
        let soloRunning = SessionItem(
            uuid: "solo-1",
            shortId: "s1",
            title: "Solo",
            isRunning: true,
            interactions: 1,
            inputTokens: 500,
            cacheTokens: 4500,
            outputTokens: 200,
            contextTokens: 5200,
            cachePct: 90.0,
            tps: 65.0
        )

        func makePayload(totalTokens: Int, cacheTokens: Int, inputTokens: Int, outputTokens: Int, cachePct: Double, sessions: [SessionItem]) -> MonitorPayload {
            MonitorPayload(
                timestamp: "17:00:00",
                dataDir: "~/.gemini/antigravity",
                activeCount: 2,
                totalRoundtrips: 10,
                hasAlert: false,
                menubar: MenuBarSummary(icon: "🟢", text: "", statusLevel: "working", activeCount: 2),
                todayStats: TodayStats(
                    totalTokens: totalTokens,
                    cacheTokens: cacheTokens,
                    inputTokens: inputTokens,
                    outputTokens: outputTokens,
                    cachePct: cachePct,
                    costUsd: 10.0,
                    hasData: true,
                    source: "test"
                ),
                sessions: sessions
            )
        }

        let p0 = makePayload(totalTokens: 1_000_000, cacheTokens: 900_000, inputTokens: 80_000, outputTokens: 20_000, cachePct: 90.0, sessions: [parentIdleWithActiveSubs, childRunning, soloRunning])
        let metrics = LiveTelemetryPolicy.extractLiveMetrics(from: p0)
        expectEqual(metrics.activeAgentCount, 2, "闲置父会话不计入运行中 Agent，应合并活跃子 Agent(1) + 独立运行会话(1)，且不得重复统计已聚合的子会话")
        expect(abs(metrics.totalTps - 185.0) < 0.01, "总速率应为 120 + 65 = 185，不得包含闲置父会话的残余 999 t/s (actual=\(metrics.totalTps))")

        var history: [LiveTelemetrySample] = []
        var prevStats: TodayStats? = nil
        var nextId = 1

        var added = false
        (history, prevStats, added) = LiveTelemetryPolicy.appendSample(to: history, payload: p0, previousStats: prevStats, nextId: &nextId, now: baseDate)
        expect(added && history.count == 1, "首次采样应写入第 1 个点")

        let burstSame = makePayload(totalTokens: 1_000_000, cacheTokens: 900_000, inputTokens: 80_000, outputTokens: 20_000, cachePct: 90.0, sessions: [parentIdleWithActiveSubs, childRunning, soloRunning])
        (history, prevStats, added) = LiveTelemetryPolicy.appendSample(to: history, payload: burstSame, previousStats: prevStats, nextId: &nextId, now: baseDate.addingTimeInterval(0.4))
        expect(!added && history.count == 1, "短间隔无变化突发轮询应被去重跳过")

        let pHit = makePayload(totalTokens: 1_100_000, cacheTokens: 990_000, inputTokens: 88_000, outputTokens: 22_000, cachePct: 90.0, sessions: [soloRunning])
        (history, prevStats, added) = LiveTelemetryPolicy.appendSample(to: history, payload: pHit, previousStats: prevStats, nextId: &nextId, now: baseDate.addingTimeInterval(5.0))
        expect(added && history.count == 2, "5s 后应写入第 2 个点")
        expectEqual(history.last?.deltaTokens, 100_000, "窗口消耗增量应为 +100k")
        expect(abs((history.last?.cachePct ?? 0) - 90.0) < 0.1, "90k/100k 瞬时缓存率应为 90%")
        expect(history.last?.isIdleCacheHold == false, "存在新增 Token 时不应标为空窗维持")

        let pMiss = makePayload(totalTokens: 1_200_000, cacheTokens: 990_000, inputTokens: 185_000, outputTokens: 25_000, cachePct: 82.5, sessions: [soloRunning])
        (history, prevStats, added) = LiveTelemetryPolicy.appendSample(to: history, payload: pMiss, previousStats: prevStats, nextId: &nextId, now: baseDate.addingTimeInterval(10.0))
        expect(abs((history.last?.cachePct ?? 100) - 0.0) < 0.1, "全部为新输入无缓存命中时，瞬时缓存率应掉至 0% 形成波谷")

        let pIdle = makePayload(totalTokens: 1_200_000, cacheTokens: 990_000, inputTokens: 185_000, outputTokens: 25_000, cachePct: 82.5, sessions: [])
        (history, prevStats, added) = LiveTelemetryPolicy.appendSample(to: history, payload: pIdle, previousStats: prevStats, nextId: &nextId, now: baseDate.addingTimeInterval(15.0))
        expect(history.last?.isIdleCacheHold == true, "无 Token 增量空窗期应标记 isIdleCacheHold 保持前值，不能假摔成 0%")
        expectEqual(history.last?.activeAgentCount, 0, "全部停止后在跑 Agent 应归零")

        for step in 1...750 {
            let pN = makePayload(totalTokens: 1_200_000 + step * 1000, cacheTokens: 990_000 + step * 950, inputTokens: 185_000 + step * 40, outputTokens: 25_000 + step * 10, cachePct: 95.0, sessions: [soloRunning])
            (history, prevStats, _) = LiveTelemetryPolicy.appendSample(to: history, payload: pN, previousStats: prevStats, nextId: &nextId, now: baseDate.addingTimeInterval(15.0 + Double(step) * 5.0))
        }
        expectEqual(history.count, LiveTelemetryPolicy.maxSamples, "环形缓冲区大小必须严格封顶在 maxSamples 以防内存无限增长")
        expectEqual(LiveTelemetryPolicy.maxSamples, 720, "应支持最长 1 小时 5s 粒度历史保留 (720 点)")

        let latestTime = history.last!.timestamp
        let oneMin = LiveTelemetryPolicy.samples(in: .oneMinute, from: history, now: latestTime)
        let threeMin = LiveTelemetryPolicy.samples(in: .threeMinutes, from: history, now: latestTime)
        let oneHour = LiveTelemetryPolicy.samples(in: .oneHour, from: history, now: latestTime)
        expect(oneMin.count >= 12 && oneMin.count <= 14, "1m 窗口应筛选最近 60s 样本 (actual=\(oneMin.count))")
        expect(threeMin.count >= 36 && threeMin.count <= 38, "3m 窗口应筛选最近 180s 样本 (actual=\(threeMin.count))")
        expectEqual(TelemetryTimeRange.threeMinutes.rawValue, "3m", "第二档时间窗标识应为 3m")
        expectEqual(TelemetryTimeRange.resolved(from: "5m"), .threeMinutes, "旧版本持久化存储的 5m 键应平滑迁移至 3m 档位")
        expectEqual(oneHour.count, LiveTelemetryPolicy.maxSamples, "1h 窗口应覆盖全量 3600s 样本")

        let domain15m = LiveTelemetryPolicy.xAxisDomain(for: .fifteenMinutes, referenceDate: latestTime)
        expectEqual(Int(domain15m.upperBound.timeIntervalSince(domain15m.lowerBound).rounded()), 900, "15m X轴跨度应精确为 900 秒")

        let firstAgents = history.first?.agentContexts ?? []
        let agentSeriesCheck = LiveTelemetryPolicy.agentSeries(in: Array(history.suffix(12)))
        expect(firstAgents.count == 2 || agentSeriesCheck.count >= 1, "应能提取活跃会话与子 Agent 的上下文轨迹且不重复")

        let ctxSeries = LiveTelemetryPolicy.agentSeries(in: [
            LiveTelemetrySample(
                id: 1,
                timestamp: baseDate,
                activeAgentCount: 2,
                totalTps: 120,
                totalTokensCumulative: 1000,
                deltaTokens: 1000,
                cachePct: 99.0,
                isIdleCacheHold: false,
                agentContexts: [
                    AgentContextPoint(agentId: "a1", label: "Coordinator", contextTokens: 120_000, isRunning: true, tps: 50),
                    AgentContextPoint(agentId: "a2", label: "worker-1", contextTokens: 45_000, isRunning: true, tps: 70),
                ]
            ),
            LiveTelemetrySample(
                id: 2,
                timestamp: baseDate.addingTimeInterval(5),
                activeAgentCount: 1,
                totalTps: 60,
                totalTokensCumulative: 5000,
                deltaTokens: 4000,
                cachePct: 95.5,
                isIdleCacheHold: false,
                agentContexts: [
                    AgentContextPoint(agentId: "a1", label: "Coordinator", contextTokens: 185_000, isRunning: true, tps: 60),
                    AgentContextPoint(agentId: "a2", label: "worker-1", contextTokens: 48_000, isRunning: false, tps: 0),
                ]
            ),
        ])
        expectEqual(ctxSeries.count, 2, "每个 Agent 应独立成一条上下文曲线")
        expectEqual(ctxSeries.first?.agentId, "a1", "活跃且上下文更大的 Agent 曲线应排在最前")
        expect(LiveTelemetryPolicy.maxContextDomain(for: ctxSeries) >= 200_000, "185k 上下文峰值时 Y 轴上限应自动对齐到 200k+ 整档 (actual=\(LiveTelemetryPolicy.maxContextDomain(for: ctxSeries)))")

        let mixedSeries = LiveTelemetryPolicy.agentSeries(in: [
            LiveTelemetrySample(
                id: 10,
                timestamp: baseDate,
                activeAgentCount: 0,
                totalTps: 0,
                totalTokensCumulative: 1000,
                deltaTokens: 0,
                cachePct: 99.0,
                isIdleCacheHold: true,
                agentContexts: [
                    AgentContextPoint(agentId: "idle-giant", label: "OldSession", contextTokens: 420_000, isRunning: false, tps: 0)
                ]
            ),
            LiveTelemetrySample(
                id: 11,
                timestamp: baseDate.addingTimeInterval(5),
                activeAgentCount: 1,
                totalTps: 50,
                totalTokensCumulative: 5000,
                deltaTokens: 4000,
                cachePct: 98.0,
                isIdleCacheHold: false,
                agentContexts: [
                    AgentContextPoint(agentId: "live-one", label: "ActiveSession", contextTokens: 85_000, isRunning: true, tps: 50)
                ]
            ),
        ])
        expectEqual(mixedSeries.count, 1, "窗口内存在活跃 Agent 时应隐藏静态历史参考线，避免把 Y 轴撑爆至 450k")
        expectEqual(mixedSeries.first?.agentId, "live-one", "应仅保留真正运行/参与工作的 Agent 曲线")

        let xTicks = LiveTelemetryPolicy.xAxisTicks(for: .threeMinutes, referenceDate: latestTime)
        expectEqual(xTicks.count, 4, "X 轴应显式生成 4 个等距时间刻度点防止末尾异常标签")
        expectEqual(Int(xTicks.last!.timeIntervalSince(xTicks.first!).rounded()), 180, "3m 刻度首尾跨度应精确等于 180s")

        let yTicks = LiveTelemetryPolicy.yAxisTicks(maxContext: 300_000)
        expectEqual(yTicks, [0.0, 100_000.0, 200_000.0, 300_000.0], "Y 轴应提供清晰 4 档整数虚线刻度")

        let nowWindow = baseDate.addingTimeInterval(600)
        let windowTestSamples = [
            LiveTelemetrySample(
                id: 101,
                timestamp: nowWindow.addingTimeInterval(-150),
                activeAgentCount: 1,
                totalTps: 100,
                totalTokensCumulative: 1_900_000,
                deltaTokens: 900_000,
                cachePct: 98.9,
                isIdleCacheHold: false,
                deltaCacheTokens: 890_000,
                deltaNewTokens: 10_000
            ),
            LiveTelemetrySample(
                id: 102,
                timestamp: nowWindow.addingTimeInterval(-30),
                activeAgentCount: 1,
                totalTps: 80,
                totalTokensCumulative: 2_000_000,
                deltaTokens: 100_000,
                cachePct: 20.0,
                isIdleCacheHold: false,
                deltaCacheTokens: 20_000,
                deltaNewTokens: 80_000
            ),
        ]
        let sum1m = LiveTelemetryPolicy.windowSummary(in: .oneMinute, from: windowTestSamples, todayStats: .empty, now: nowWindow)
        let sum3m = LiveTelemetryPolicy.windowSummary(in: .threeMinutes, from: windowTestSamples, todayStats: .empty, now: nowWindow)
        expectEqual(sum1m.totalTokens, 100_000, "1m 窗口累计消耗应只统计最近 60 秒内的 100k")
        expect(abs(sum1m.cachePct - 20.0) < 0.1, "1m 窗口缓存率应加权反映近 60 秒内的 20% 命中 (actual=\(sum1m.cachePct))")
        expectEqual(sum3m.totalTokens, 1_000_000, "3m 窗口累计消耗应包含前 2.5 分钟的 900k + 近 1 分钟的 100k = 1.0M")
        expect(abs(sum3m.cachePct - 91.0) < 0.1, "3m 窗口缓存率应为加权总计 910k / 1000k = 91.0% (actual=\(sum3m.cachePct))")
    }

    static func testLiveTelemetryOverviewCardFitsPanelWidthAndShowsSummary() {
        let now = Date()
        let samples: [LiveTelemetrySample] = (0..<24).map { idx in
            let tps = idx % 5 == 0 ? 15.0 : Double(80 + (idx * 37) % 260)
            let cache = idx == 12 ? 78.0 : (96.0 + Double(idx % 4))
            let c1 = 140_000 + idx * 4_500
            let c2 = 28_000 + idx * 2_200
            let c3 = 12_000 + idx * 1_100
            return LiveTelemetrySample(
                id: idx + 1,
                timestamp: now.addingTimeInterval(Double(idx - 24) * 5.0),
                activeAgentCount: 3,
                totalTps: tps,
                totalTokensCumulative: 273_200_000 + idx * 120_000,
                deltaTokens: 120_000,
                cachePct: cache,
                isIdleCacheHold: false,
                agentContexts: [
                    AgentContextPoint(agentId: "parent-1", label: "保险库授权", contextTokens: c1, isRunning: true, tps: 55),
                    AgentContextPoint(agentId: "sub-1", label: "monitor", contextTokens: c2, isRunning: true, tps: 90),
                    AgentContextPoint(agentId: "sub-2", label: "verifier", contextTokens: c3, isRunning: idx < 18, tps: idx < 18 ? 40 : 0),
                ]
            )
        }
        let today = TodayStats(totalTokens: 276_080_000, cacheTokens: 270_000_000, inputTokens: 4_000_000, outputTokens: 2_080_000, cachePct: 97.8, costUsd: 70.16, hasData: true, source: "test")

        MainActor.assumeIsolated { () -> Void in
            let view = LiveTelemetryOverviewCardView(samples: samples, todayStats: today)
                .environment(\.agyLanguage, .zhHans)

            for cardWidth in [CGFloat(436), CGFloat(412)] {
                let hosting = NSHostingView(rootView: view.frame(width: cardWidth))
                hosting.layoutSubtreeIfNeeded()
                let fit = hosting.fittingSize
                expect(fit.width <= cardWidth + 0.5, "单图多线上下文总览卡在 \(Int(cardWidth))pt 容器内不得横向溢出 (actual=\(fit.width))")
                expect(fit.height >= 180.0 && fit.height <= 285.0, "主图表卡片腾出空间后高度应在 180~285pt 区间清晰舒展 (actual=\(fit.height))")
            }

            expectEqual(SessionListLayoutPolicy.maxVisibleRowsWhenExpanded, 3, "底部 SESSIONS 常驻最多显示 3 条，其余滚动查看")
            expect(abs(SessionListLayoutPolicy.scrollHeight(forCount: 15, chartExpanded: true)! - 98.0) <= 4.0, "超过 3 条且上方图表展开时 SESSIONS 滚动区应锁定 3 行高度 (~98pt)")
            expect(SessionListLayoutPolicy.scrollHeight(forCount: 15, chartExpanded: false) == nil, "上方图表折叠时 SESSIONS 应自动释放扩展展示更多行")

            let emptyView = LiveTelemetryOverviewCardView(samples: [], todayStats: .empty)
                .environment(\.agyLanguage, .en)
            let emptyHosting = NSHostingView(rootView: emptyView.frame(width: 412))
            emptyHosting.layoutSubtreeIfNeeded()
            expect(emptyHosting.fittingSize.width <= 412.5, "空采样冷启动态也不得横向溢出")
        }
    }

    static func testLiveTelemetryYAxisLeftAlignedAndHighContrast() {
        expectEqual(LiveTelemetryChartAxisPolicy.yAxisPosition, .leading, "Y 轴与上下文标题应位于图表左侧")
        expectEqual(LiveTelemetryChartAxisPolicy.contextHeaderAlignment, .leading, "上下文标题容器应左对齐")
        expect(LiveTelemetryChartAxisPolicy.yAxisTitleOpacity >= 0.70, "上下文标题透明度过低会看不清 (actual=\(LiveTelemetryChartAxisPolicy.yAxisTitleOpacity))")
        expect(LiveTelemetryChartAxisPolicy.yAxisTickOpacity >= 0.70, "Y 轴刻度透明度过低会看不清 (actual=\(LiveTelemetryChartAxisPolicy.yAxisTickOpacity))")
        expect(LiveTelemetryChartAxisPolicy.yAxisTitleFontSize >= 9.5, "上下文标题字号过小 (actual=\(LiveTelemetryChartAxisPolicy.yAxisTitleFontSize))")
        expect(LiveTelemetryChartAxisPolicy.yAxisTickFontSize >= 9.5, "Y 轴刻度字号过小 (actual=\(LiveTelemetryChartAxisPolicy.yAxisTickFontSize))")

        let now = Date()
        let samples = [
            LiveTelemetrySample(
                id: 1,
                timestamp: now.addingTimeInterval(-120),
                activeAgentCount: 1,
                totalTps: 120,
                totalTokensCumulative: 1_000_000,
                deltaTokens: 100_000,
                cachePct: 98.5,
                isIdleCacheHold: false,
                agentContexts: [
                    AgentContextPoint(agentId: "a1", label: "impl skill", contextTokens: 29_000, isRunning: true, tps: 120)
                ]
            ),
            LiveTelemetrySample(
                id: 2,
                timestamp: now.addingTimeInterval(-10),
                activeAgentCount: 1,
                totalTps: 240,
                totalTokensCumulative: 1_120_000,
                deltaTokens: 120_000,
                cachePct: 98.7,
                isIdleCacheHold: false,
                agentContexts: [
                    AgentContextPoint(agentId: "a1", label: "impl skill", contextTokens: 120_000, isRunning: true, tps: 240)
                ]
            ),
        ]
        let today = TodayStats(totalTokens: 95_800_000, cacheTokens: 94_000_000, inputTokens: 1_200_000, outputTokens: 600_000, cachePct: 98.7, costUsd: 23.86, hasData: true, source: "test")

        MainActor.assumeIsolated { () -> Void in
            for lang in [AppLanguage.Resolved.zhHans, AppLanguage.Resolved.en] {
                let view = LiveTelemetryOverviewCardView(samples: samples, todayStats: today)
                    .environment(\.agyLanguage, lang)
                for width in [CGFloat(360), CGFloat(412), CGFloat(436)] {
                    let hosting = NSHostingView(rootView: view.frame(width: width))
                    hosting.layoutSubtreeIfNeeded()
                    let fit = hosting.fittingSize
                    expect(fit.width <= width + 0.5, "左侧 Y 轴下卡片在宽度 \(width) (\(lang.rawValue)) 不应横向溢出: \(fit.width)")
                    expect(fit.height >= 170, "卡片高度异常过矮 (\(lang.rawValue)): \(fit.height)")
                }
            }
        }
    }

    static func testLiveTelemetrySubagentForkHandoffAndSegmentSplit() {
        let baseDate = Date(timeIntervalSince1970: 1700001000)

        let parentRunning = SessionItem(
            uuid: "parent-auth",
            shortId: "pa",
            title: "保险库授权",
            isRunning: true,
            interactions: 4,
            inputTokens: 1000,
            cacheTokens: 9000,
            outputTokens: 500,
            contextTokens: 150_000,
            cachePct: 95.0,
            tps: 40.0
        )

        let subRunning = SessionItem(
            uuid: "sub-keepalive",
            shortId: "sk",
            parentConversationId: "parent-auth",
            agentName: "vault-ux-keepalive",
            title: "Subagent",
            isRunning: true,
            interactions: 2,
            inputTokens: 2000,
            cacheTokens: 18000,
            outputTokens: 800,
            contextTokens: 445_000,
            cachePct: 98.0,
            tps: 80.0
        )

        let parentWaitingWithChild = SessionItem(
            uuid: "parent-auth",
            shortId: "pa",
            title: "保险库授权",
            isRunning: false,
            interactions: 4,
            inputTokens: 1000,
            cacheTokens: 9000,
            outputTokens: 500,
            contextTokens: 150_000,
            cachePct: 95.0,
            tps: 0.0,
            subagents: [subRunning],
            subagentCount: 1,
            activeSubagentCount: 1,
            activeSubagentTps: 80.0
        )

        let subFinished = SessionItem(
            uuid: "sub-keepalive",
            shortId: "sk",
            parentConversationId: "parent-auth",
            agentName: "vault-ux-keepalive",
            title: "Subagent",
            isRunning: false,
            interactions: 3,
            inputTokens: 2000,
            cacheTokens: 18000,
            outputTokens: 800,
            contextTokens: 63_000,
            cachePct: 98.0,
            tps: 0.0
        )

        let parentResumed = SessionItem(
            uuid: "parent-auth",
            shortId: "pa",
            title: "保险库授权",
            isRunning: true,
            interactions: 5,
            inputTokens: 1200,
            cacheTokens: 11000,
            outputTokens: 600,
            contextTokens: 167_000,
            cachePct: 95.0,
            tps: 174.0,
            subagents: [subFinished],
            subagentCount: 1,
            activeSubagentCount: 0,
            activeSubagentTps: 0.0
        )

        func makePayload(sessions: [SessionItem], tokens: Int) -> MonitorPayload {
            MonitorPayload(
                timestamp: "19:40:00",
                dataDir: "~/.gemini/antigravity",
                activeCount: 1,
                totalRoundtrips: 10,
                hasAlert: false,
                menubar: MenuBarSummary(icon: "🟢", text: "", statusLevel: "working", activeCount: 1),
                todayStats: TodayStats(totalTokens: tokens, cacheTokens: tokens - 10_000, inputTokens: 8000, outputTokens: 2000, cachePct: 98.0, costUsd: 5.0, hasData: true, source: "test"),
                sessions: sessions
            )
        }

        var history: [LiveTelemetrySample] = []
        var prevStats: TodayStats? = nil
        var nextId = 1

        (history, prevStats, _) = LiveTelemetryPolicy.appendSample(
            to: history,
            payload: makePayload(sessions: [parentRunning], tokens: 1_000_000),
            previousStats: prevStats,
            nextId: &nextId,
            now: baseDate
        )
        (history, prevStats, _) = LiveTelemetryPolicy.appendSample(
            to: history,
            payload: makePayload(sessions: [parentWaitingWithChild], tokens: 1_200_000),
            previousStats: prevStats,
            nextId: &nextId,
            now: baseDate.addingTimeInterval(5.0)
        )
        (history, prevStats, _) = LiveTelemetryPolicy.appendSample(
            to: history,
            payload: makePayload(sessions: [parentWaitingWithChild], tokens: 1_400_000),
            previousStats: prevStats,
            nextId: &nextId,
            now: baseDate.addingTimeInterval(10.0)
        )
        (history, prevStats, _) = LiveTelemetryPolicy.appendSample(
            to: history,
            payload: makePayload(sessions: [parentWaitingWithChild], tokens: 1_550_000),
            previousStats: prevStats,
            nextId: &nextId,
            now: baseDate.addingTimeInterval(15.0)
        )

        let duringChild = LiveTelemetryPolicy.agentSeries(in: history)
        expectEqual(duringChild.count, 2, "子 Agent 运行期应有父历史干流 + 子活跃分支两条序列")
        if let parentMid = duringChild.first(where: { $0.agentId == "parent-auth" }),
           let childMid = duringChild.first(where: { $0.agentId == "sub-keepalive" }) {
            expect(!parentMid.isRunning, "子 Agent 运行且父会话未独立运行时，父曲线不得标为活跃运行以免双线争抢与平线穿底")
            expect(childMid.isRunning, "子 Agent 运行期间应唯一标记为活跃运行")
            expectEqual(parentMid.points.count, 1, "父会话等待子 Agent 期间应在分叉点停止记录，不得继续拉平线 (actual=\(parentMid.points.count))")
            expectEqual(childMid.parentAgentId, "parent-auth", "子 Agent 曲线必须关联所属父 Agent UUID")
            expect(childMid.points.first?.isForkAnchor == true, "子 Agent 首点应标记为分叉锚点 isForkAnchor")
            expectEqual(childMid.points.first?.timestamp, baseDate, "分叉锚点时间应接在父线停下的分叉点上")
            expectEqual(childMid.points.first?.contextTokens, 150_000, "分叉锚点高度应从父线当时 150k 上下文直接引出")
        } else {
            expect(false, "应分别生成父曲线 parent-auth 与子曲线 sub-keepalive")
        }

        (history, prevStats, _) = LiveTelemetryPolicy.appendSample(
            to: history,
            payload: makePayload(sessions: [parentResumed], tokens: 1_750_000),
            previousStats: prevStats,
            nextId: &nextId,
            now: baseDate.addingTimeInterval(20.0)
        )
        (history, prevStats, _) = LiveTelemetryPolicy.appendSample(
            to: history,
            payload: makePayload(sessions: [parentResumed], tokens: 1_950_000),
            previousStats: prevStats,
            nextId: &nextId,
            now: baseDate.addingTimeInterval(25.0)
        )

        let afterResume = LiveTelemetryPolicy.agentSeries(in: history)
        if let parentAfter = afterResume.first(where: { $0.agentId == "parent-auth" }),
           let childAfter = afterResume.first(where: { $0.agentId == "sub-keepalive" }) {
            expect(parentAfter.isRunning, "父会话恢复运行后应成为当前活跃曲线")
            expect(!childAfter.isRunning, "子 Agent 结束后应退出活跃态且不再向右延伸")
            expectEqual(parentAfter.segments.count, 2, "父会话分叉前与恢复后之间存在子分支运行间隔，必须拆成 2 段避免一条蓝色横线直接穿过绿色分支下方 (actual=\(parentAfter.segments.count))")
        } else {
            expect(false, "恢复运行后仍应保留完整父子记录")
        }

        var childOnlyHistory: [LiveTelemetrySample] = []
        var nextChildOnlyId = 1
        var childOnlyStats: TodayStats? = nil
        (childOnlyHistory, childOnlyStats, _) = LiveTelemetryPolicy.appendSample(
            to: childOnlyHistory,
            payload: makePayload(sessions: [parentWaitingWithChild], tokens: 500_000),
            previousStats: childOnlyStats,
            nextId: &nextChildOnlyId,
            now: baseDate
        )
        (childOnlyHistory, childOnlyStats, _) = LiveTelemetryPolicy.appendSample(
            to: childOnlyHistory,
            payload: makePayload(sessions: [parentWaitingWithChild], tokens: 700_000),
            previousStats: childOnlyStats,
            nextId: &nextChildOnlyId,
            now: baseDate.addingTimeInterval(5.0)
        )
        let childOnlySeries = LiveTelemetryPolicy.agentSeries(in: childOnlyHistory)
        expectEqual(childOnlySeries.count, 1, "窗口内仅子 Agent 在跑且父会话从未运行过时，不应画出空闲父线 (actual=\(childOnlySeries.count))")
        expectEqual(childOnlySeries.first?.agentId, "sub-keepalive", "此时窗口内唯一曲线必须是绿色的子 Agent")
    }

    static func testLiveTelemetrySmoothCurveInterpolationAndZeroCliffJumps() {
        let baseDate = Date(timeIntervalSince1970: 1700002000)
        let rawPoints: [AgentSeriesSamplePoint] = [
            AgentSeriesSamplePoint(timestamp: baseDate, contextTokens: 167_000, isRunning: false, tps: 0.0, isForkAnchor: true),
            AgentSeriesSamplePoint(timestamp: baseDate.addingTimeInterval(5.0), contextTokens: 508_000, isRunning: true, tps: 90.0),
            AgentSeriesSamplePoint(timestamp: baseDate.addingTimeInterval(10.0), contextTokens: 508_000, isRunning: true, tps: 90.0),
            AgentSeriesSamplePoint(timestamp: baseDate.addingTimeInterval(20.0), contextTokens: 508_000, isRunning: true, tps: 90.0),
            AgentSeriesSamplePoint(timestamp: baseDate.addingTimeInterval(40.0), contextTokens: 508_000, isRunning: true, tps: 90.0),
            AgentSeriesSamplePoint(timestamp: baseDate.addingTimeInterval(45.0), contextTokens: 40_000, isRunning: true, tps: 60.0),
            AgentSeriesSamplePoint(timestamp: baseDate.addingTimeInterval(50.0), contextTokens: 42_000, isRunning: true, tps: 60.0),
            AgentSeriesSamplePoint(timestamp: baseDate.addingTimeInterval(60.0), contextTokens: 48_000, isRunning: true, tps: 60.0),
            AgentSeriesSamplePoint(timestamp: baseDate.addingTimeInterval(90.0), contextTokens: 63_000, isRunning: true, tps: 60.0)
        ]

        let smoothed = LiveTelemetryPolicy.smoothedCurvePoints(rawPoints, windowSeconds: 300.0)
        expect(smoothed.count >= 25, "平滑曲线插值后应具备足够加密采样以形成流畅 S 曲线 (actual=\(smoothed.count))")
        expectEqual(smoothed.first?.timestamp, rawPoints.first?.timestamp, "曲线首点时间必须精确钉在原分叉起点")
        expectEqual(smoothed.first?.contextTokens, 167_000, "曲线首点高度必须精确钉在 167k")
        expectEqual(smoothed.last?.timestamp, rawPoints.last?.timestamp, "曲线末点时间必须精确钉在原终点")
        expectEqual(smoothed.last?.contextTokens, 63_000, "曲线末点高度必须精确钉在 63k")

        for i in 1..<smoothed.count {
            expect(smoothed[i].timestamp > smoothed[i - 1].timestamp, "平滑曲线时间戳必须严格递增")
            expect(smoothed[i].contextTokens >= 40_000 && smoothed[i].contextTokens <= 508_000, "平滑曲线不得出现上下过冲越界 (y=\(smoothed[i].contextTokens))")
        }

        var maxSingleStepSlope = 0.0
        for i in 1..<smoothed.count {
            let dt = smoothed[i].timestamp.timeIntervalSince(smoothed[i - 1].timestamp)
            let dy = abs(Double(smoothed[i].contextTokens - smoothed[i - 1].contextTokens))
            if dt > 0 {
                maxSingleStepSlope = max(maxSingleStepSlope, dy / dt)
            }
        }
        let rawCliffSlope = abs(508_000.0 - 40_000.0) / 5.0
        expect(maxSingleStepSlope < rawCliffSlope * 0.65, "原本 5 秒内 90° 垂直跳变应被舒展为柔和过渡，最大瞬时斜率须显著下降 (actual=\(Int(maxSingleStepSlope)), raw=\(Int(rawCliffSlope)))")

        let stairLevels = [62_000, 78_000, 94_000, 110_000, 126_000, 144_000]
        var stairRaw: [AgentSeriesSamplePoint] = []
        for (levelIdx, tokens) in stairLevels.enumerated() {
            for tick in 0..<6 {
                let t = Double(levelIdx * 6 + tick) * 3.0
                stairRaw.append(
                    AgentSeriesSamplePoint(
                        timestamp: baseDate.addingTimeInterval(t),
                        contextTokens: tokens,
                        isRunning: true,
                        tps: 96.0
                    )
                )
            }
        }
        let smoothedStair = LiveTelemetryPolicy.smoothedCurvePoints(stairRaw, windowSeconds: 300.0)
        expectEqual(smoothedStair.first?.contextTokens, 62_000, "去台阶化曲线首点高度必须精确保留 62k")
        expectEqual(smoothedStair.last?.contextTokens, 144_000, "去台阶化曲线末点高度必须精确保留 144k")

        var stairMaxSlope = 0.0
        var middleFlatSteps = 0
        for i in 1..<smoothedStair.count {
            let dt = smoothedStair[i].timestamp.timeIntervalSince(smoothedStair[i - 1].timestamp)
            let dy = Double(smoothedStair[i].contextTokens - smoothedStair[i - 1].contextTokens)
            if dt > 0 {
                stairMaxSlope = max(stairMaxSlope, abs(dy) / dt)
            }
            if i > smoothedStair.count / 5 && i < (smoothedStair.count * 4) / 5 && abs(dy) < 1.0 {
                middleFlatSteps += 1
            }
        }
        let rawStairStepSlope = 16_000.0 / 3.0
        expect(stairMaxSlope < rawStairStepSlope * 0.45, "高频轮询造成的锯齿台阶必须被抹平为连续流线，峰值瞬时斜率须明显下降 (actual=\(Int(stairMaxSlope)), raw=\(Int(rawStairStepSlope)))")
        expectEqual(middleFlatSteps, 0, "连续爬坡区间中段不得残留 0 斜率水平死台阶 (flatSteps=\(middleFlatSteps))")
    }

    static func testLiveTelemetryFamilyColorHierarchyAndDescendantTiers() {
        let baseDate = Date(timeIntervalSince1970: 1700003000)

        let samples: [LiveTelemetrySample] = [
            LiveTelemetrySample(
                id: 1,
                timestamp: baseDate,
                activeAgentCount: 2,
                totalTps: 100,
                totalTokensCumulative: 1_000_000,
                deltaTokens: 10_000,
                cachePct: 98.0,
                isIdleCacheHold: false,
                agentContexts: [
                    AgentContextPoint(agentId: "root-a", label: "会话A", contextTokens: 120_000, isRunning: true, tps: 50, parentAgentId: nil),
                    AgentContextPoint(agentId: "root-b", label: "会话B", contextTokens: 90_000, isRunning: true, tps: 50, parentAgentId: nil)
                ]
            ),
            LiveTelemetrySample(
                id: 2,
                timestamp: baseDate.addingTimeInterval(5.0),
                activeAgentCount: 3,
                totalTps: 180,
                totalTokensCumulative: 1_050_000,
                deltaTokens: 50_000,
                cachePct: 97.5,
                isIdleCacheHold: false,
                agentContexts: [
                    AgentContextPoint(agentId: "root-a", label: "会话A", contextTokens: 120_000, isRunning: false, tps: 0, parentAgentId: nil),
                    AgentContextPoint(agentId: "child-a1", label: "子A1", contextTokens: 45_000, isRunning: true, tps: 60, parentAgentId: "root-a"),
                    AgentContextPoint(agentId: "child-a2", label: "子A2", contextTokens: 32_000, isRunning: true, tps: 50, parentAgentId: "root-a"),
                    AgentContextPoint(agentId: "root-b", label: "会话B", contextTokens: 92_000, isRunning: false, tps: 0, parentAgentId: nil),
                    AgentContextPoint(agentId: "child-b1", label: "子B1", contextTokens: 28_000, isRunning: true, tps: 70, parentAgentId: "root-b")
                ]
            ),
            LiveTelemetrySample(
                id: 3,
                timestamp: baseDate.addingTimeInterval(10.0),
                activeAgentCount: 2,
                totalTps: 210,
                totalTokensCumulative: 1_120_000,
                deltaTokens: 70_000,
                cachePct: 98.2,
                isIdleCacheHold: false,
                agentContexts: [
                    AgentContextPoint(agentId: "grand-a1a", label: "孙A1a", contextTokens: 24_000, isRunning: true, tps: 110, parentAgentId: "child-a1"),
                    AgentContextPoint(agentId: "child-b1", label: "子B1", contextTokens: 410_000, isRunning: true, tps: 100, parentAgentId: "root-b")
                ]
            )
        ]

        let seriesList = LiveTelemetryPolicy.agentSeries(in: samples)
        let byId = Dictionary(uniqueKeysWithValues: seriesList.map { ($0.agentId, $0) })

        guard let rootA = byId["root-a"],
              let childA1 = byId["child-a1"],
              let childA2 = byId["child-a2"],
              let grandA1a = byId["grand-a1a"],
              let rootB = byId["root-b"],
              let childB1 = byId["child-b1"] else {
            expect(false, "三代祖孙链与并行会话族应全部保留在 seriesList 中 (actualIds=\(seriesList.map(\.agentId)))")
            return
        }

        expectEqual(rootA.familyIndex, 0, "先出现的根会话 A 应归属第 0 色系")
        expectEqual(childA1.familyIndex, rootA.familyIndex, "子 Agent A1 必须继承父会话 A 的色系")
        expectEqual(childA2.familyIndex, rootA.familyIndex, "子 Agent A2 必须继承父会话 A 的色系")
        expectEqual(grandA1a.familyIndex, rootA.familyIndex, "孙 Agent A1a 必须沿祖孙链继承根会话 A 的色系")

        expectEqual(rootB.familyIndex, 1, "另一个独立根会话 B 应使用不同的第 1 色系")
        expectEqual(childB1.familyIndex, rootB.familyIndex, "子 Agent B1 必须继承父会话 B 的色系")

        expectEqual(rootA.familyTier, 0, "父会话 A 本身必须处于第 0 梯队(主色)")
        expectEqual(rootB.familyTier, 0, "父会话 B 本身必须处于第 0 梯队(主色)")
        expectEqual(childB1.familyTier, 1, "B 的直接子 Agent 应处于第 1 梯队")

        let aChildTiers = [childA1.familyTier, childA2.familyTier, grandA1a.familyTier]
        expect(aChildTiers.allSatisfy { $0 >= 1 }, "所有子孙 Agent 的梯队必须 >= 1，避免与父会话完全同色")
        expectEqual(Set(aChildTiers).count, 3, "同族子孙之间梯队编号应互不相同以做出视觉区分 (tiers=\(aChildTiers))")
        expect(grandA1a.familyTier > childA1.familyTier, "孙 Agent 梯队应排在父级子 Agent 之后形成逐层递进")

        let toneA0 = LiveTelemetryColorPalette.tone(familyIndex: rootA.familyIndex, tier: rootA.familyTier)
        let toneA1 = LiveTelemetryColorPalette.tone(familyIndex: childA1.familyIndex, tier: childA1.familyTier)
        let toneA2 = LiveTelemetryColorPalette.tone(familyIndex: childA2.familyIndex, tier: childA2.familyTier)
        let toneA3 = LiveTelemetryColorPalette.tone(familyIndex: grandA1a.familyIndex, tier: grandA1a.familyTier)
        let toneB0 = LiveTelemetryColorPalette.tone(familyIndex: rootB.familyIndex, tier: rootB.familyTier)
        let toneB1 = LiveTelemetryColorPalette.tone(familyIndex: childB1.familyIndex, tier: childB1.familyTier)
        let toneB2 = LiveTelemetryColorPalette.tone(familyIndex: rootB.familyIndex, tier: 2)
        let toneB3 = LiveTelemetryColorPalette.tone(familyIndex: rootB.familyIndex, tier: 3)

        for (name, tone) in [("rootA", toneA0), ("childA1", toneA1), ("childA2", toneA2), ("grandA1a", toneA3)] {
            expect(tone.hueDegrees >= 190.0 && tone.hueDegrees <= 235.0, "\(name) 应保持在蓝色色相区间 [190°, 235°] 内，不能变成绿色或橙色 (hue=\(tone.hueDegrees))")
        }
        for (name, tone) in [("rootB", toneB0), ("childB1", toneB1), ("childB2", toneB2), ("childB3", toneB3)] {
            expect(tone.hueDegrees >= 80.0 && tone.hueDegrees <= 185.0, "\(name) 应保持在绿色色相区间 [80°, 185°] 内 (hue=\(tone.hueDegrees))")
        }

        expect(toneA0.euclideanDistance(to: toneA1) >= 0.28, "父蓝与子天蓝之间必须有明显色差以便一眼区分 (actual=\(toneA0.euclideanDistance(to: toneA1)))")
        expect(toneA1.euclideanDistance(to: toneA2) >= 0.28, "子1天蓝与子2浅蓝之间必须有明显色差以便一眼区分 (actual=\(toneA1.euclideanDistance(to: toneA2)))")
        expect(toneA0.relativeLuminance + 0.15 < toneA1.relativeLuminance, "蓝色父会话应明显深于子1天蓝")
        expect(toneA1.relativeLuminance + 0.10 < toneA2.relativeLuminance, "蓝色子2应明显浅于子1天蓝形成梯度")

        expect(toneB0.euclideanDistance(to: toneB1) >= 0.28, "绿色父会话与子1之间必须有明显色差，不能看起来像同一个绿 (actual=\(toneB0.euclideanDistance(to: toneB1)))")
        expect(toneB1.euclideanDistance(to: toneB2) >= 0.28, "绿色子1与子2之间必须有明显色差 (actual=\(toneB1.euclideanDistance(to: toneB2)))")
        expect(toneB2.euclideanDistance(to: toneB3) >= 0.28, "绿色子2与子3之间必须有明显色差 (actual=\(toneB2.euclideanDistance(to: toneB3)))")
        expect(toneB0.relativeLuminance + 0.15 < toneB1.relativeLuminance, "绿色父会话应明显深于子1亮绿")
        expect(toneB1.relativeLuminance + 0.10 < toneB2.relativeLuminance, "绿色子2薄荷绿应明显浅于子1")

        let swappedOrderSamples = samples + [
            LiveTelemetrySample(
                id: 4,
                timestamp: baseDate.addingTimeInterval(15.0),
                activeAgentCount: 2,
                totalTps: 240,
                totalTokensCumulative: 1_200_000,
                deltaTokens: 80_000,
                cachePct: 98.5,
                isIdleCacheHold: false,
                agentContexts: [
                    AgentContextPoint(agentId: "root-b", label: "会话B", contextTokens: 600_000, isRunning: true, tps: 180, parentAgentId: nil),
                    AgentContextPoint(agentId: "root-a", label: "会话A", contextTokens: 130_000, isRunning: true, tps: 60, parentAgentId: nil)
                ]
            )
        ]
        let swappedSeries = Dictionary(uniqueKeysWithValues: LiveTelemetryPolicy.agentSeries(in: swappedOrderSamples).map { ($0.agentId, $0) })
        expectEqual(swappedSeries["root-a"]?.familyIndex, 0, "当会话 B 上下文反超会话 A 时，会话 A 色系不能抖动跳变")
        expectEqual(swappedSeries["root-b"]?.familyIndex, 1, "当会话 B 上下文反超会话 A 时，会话 B 色系应保持稳定")

        let orphanSiblingSamples = [
            LiveTelemetrySample(
                id: 10,
                timestamp: baseDate,
                activeAgentCount: 3,
                totalTps: 150,
                totalTokensCumulative: 500_000,
                deltaTokens: 20_000,
                cachePct: 95.0,
                isIdleCacheHold: false,
                agentContexts: [
                    AgentContextPoint(agentId: "orphan-sub-1", label: "孤儿子1", contextTokens: 40_000, isRunning: true, tps: 50, parentAgentId: "hidden-parent-x"),
                    AgentContextPoint(agentId: "orphan-sub-2", label: "孤儿子2", contextTokens: 60_000, isRunning: true, tps: 50, parentAgentId: "hidden-parent-x"),
                    AgentContextPoint(agentId: "root-y", label: "会话Y", contextTokens: 90_000, isRunning: true, tps: 50, parentAgentId: nil)
                ]
            )
        ]
        let orphanSeries = Dictionary(uniqueKeysWithValues: LiveTelemetryPolicy.agentSeries(in: orphanSiblingSamples).map { ($0.agentId, $0) })
        if let o1 = orphanSeries["orphan-sub-1"], let o2 = orphanSeries["orphan-sub-2"], let ry = orphanSeries["root-y"] {
            expectEqual(o1.familyIndex, o2.familyIndex, "父会话不在窗口内时，同父的两个子 Agent 仍应归属同一色系")
            expect(o1.familyIndex != ry.familyIndex, "同父子 Agent 与无关会话 Y 应分属不同色系")
            expect(o1.familyTier >= 1 && o2.familyTier >= 1 && o1.familyTier != o2.familyTier, "父会话不在窗口内时，子 Agent 仍应拿到不同的子梯队序号")
        } else {
            expect(false, "缺失父节点的孤儿兄弟子 Agent 序列生成失败")
        }
    }

    static func testHeaderBarNeverWrapsTodayPillVerticallyOnNarrowWidths() {
        let stats = TodayStats(
            totalTokens: 99_600_000,
            cacheTokens: 92_000_000,
            inputTokens: 5_000_000,
            outputTokens: 2_600_000,
            cachePct: 92.4,
            costUsd: 25.97,
            hasData: true,
            source: "test"
        )
        let bigStats = TodayStats(
            totalTokens: 999_800_000,
            cacheTokens: 920_000_000,
            inputTokens: 50_000_000,
            outputTokens: 29_800_000,
            cachePct: 92.0,
            costUsd: 185.42,
            hasData: true,
            source: "test"
        )

        MainActor.assumeIsolated { () -> Void in
            for sampleStats in [stats, bigStats] {
                for lang in [AppLanguage.Resolved.zhHans, AppLanguage.Resolved.en] {
                    let bar = DashboardHeaderBarView(
                        stats: sampleStats,
                        hasAlert: false,
                        isUsageOpen: false,
                        isStandaloneWindow: false,
                        lang: lang,
                        refreshSpinCount: 0,
                        onToggleUsage: {},
                        onRefresh: {},
                        onOpenStandalone: {},
                        onClose: {}
                    )
                    for width in [CGFloat(320), CGFloat(360), CGFloat(390), CGFloat(412), CGFloat(440), CGFloat(464)] {
                        let hosting = NSHostingView(rootView: bar.frame(width: width))
                        hosting.layoutSubtreeIfNeeded()
                        let fit = hosting.fittingSize
                        expect(fit.width <= width + 0.5, "顶部标题栏在宽度 \(width) (\(lang.rawValue)) 不应横向溢出: \(fit.width)")
                        expect(fit.height <= 46.0, "缩小窗口到宽度 \(width) 时 Today 胶囊不得竖向换行撑高 (actualHeight=\(fit.height))")
                    }
                }
            }
        }
    }

    static func testDashboardAdaptiveLayoutReducesMarginsWhenNarrowed() {
        let narrow = DashboardAdaptiveLayoutMetrics.metrics(forWidth: 440)
        let extraNarrow = DashboardAdaptiveLayoutMetrics.metrics(forWidth: 360)
        let wide = DashboardAdaptiveLayoutMetrics.metrics(forWidth: 476)

        expect(narrow.isCompact, "440pt 窄窗口应触发紧凑左右边距策略")
        expect(extraNarrow.isCompact, "360pt 超窄窗口应触发紧凑左右边距策略")
        expect(!wide.isCompact, "476pt 宽窗口应保持常规边距")

        expect(narrow.outerHorizontalPadding < wide.outerHorizontalPadding, "窄窗口外层左右边距应明显小于宽窗口 (\(narrow.outerHorizontalPadding) vs \(wide.outerHorizontalPadding))")
        expect(narrow.outerHorizontalPadding <= 8.0, "窄窗口外层左右边距应压缩到 <= 8pt 以提高空间利用率 (actual=\(narrow.outerHorizontalPadding))")
        expect(narrow.outerHorizontalPadding >= WindowResizeEdgePolicy.horizontalEdgeInset, "外层边距不得小于边缘缩放热区以免遮挡按钮点击")
        expect(narrow.telemetryCardHorizontalPadding < wide.telemetryCardHorizontalPadding, "窄窗口图表卡片内边距应同步收窄")
        expect(narrow.telemetryPlotHorizontalPadding < wide.telemetryPlotHorizontalPadding, "窄窗口图表绘图区内边距应同步收窄")
        expect(narrow.totalChartEdgeInset <= 18.0, "窄窗口图表总左右留白应从原 33pt 显著压缩到 <= 18pt (actual=\(narrow.totalChartEdgeInset))")

        let now = Date()
        let samples = [
            LiveTelemetrySample(
                id: 1,
                timestamp: now.addingTimeInterval(-60),
                activeAgentCount: 1,
                totalTps: 116,
                totalTokensCumulative: 1_000_000,
                deltaTokens: 100_000,
                cachePct: 98.0,
                isIdleCacheHold: false,
                agentContexts: [AgentContextPoint(agentId: "s1", label: "Improve Codebase", contextTokens: 427_000, isRunning: true, tps: 116)]
            )
        ]
        let today = TodayStats(totalTokens: 99_600_000, cacheTokens: 95_000_000, inputTokens: 3_000_000, outputTokens: 1_600_000, cachePct: 98.0, costUsd: 26.75, hasData: true, source: "test")

        MainActor.assumeIsolated { () -> Void in
            for width in [CGFloat(360), CGFloat(412), CGFloat(440)] {
                let metrics = DashboardAdaptiveLayoutMetrics.metrics(forWidth: width)
                let bar = DashboardHeaderBarView(
                    stats: today,
                    hasAlert: false,
                    isUsageOpen: false,
                    isStandaloneWindow: false,
                    lang: .zhHans,
                    refreshSpinCount: 0,
                    outerHorizontalPadding: metrics.outerHorizontalPadding,
                    onToggleUsage: {},
                    onRefresh: {},
                    onOpenStandalone: {},
                    onClose: {}
                )
                let barHost = NSHostingView(rootView: bar.frame(width: width))
                barHost.layoutSubtreeIfNeeded()
                expect(barHost.fittingSize.height <= 46.0, "紧凑边距下标题栏高度不应溢出 (w=\(width), h=\(barHost.fittingSize.height))")

                let card = LiveTelemetryOverviewCardView(
                    samples: samples,
                    todayStats: today,
                    cardHorizontalPadding: metrics.telemetryCardHorizontalPadding,
                    plotHorizontalPadding: metrics.telemetryPlotHorizontalPadding
                )
                .environment(\.agyLanguage, .zhHans)
                let cardHost = NSHostingView(rootView: card.frame(width: width - metrics.outerHorizontalPadding * 2))
                cardHost.layoutSubtreeIfNeeded()
                expect(cardHost.fittingSize.width <= (width - metrics.outerHorizontalPadding * 2) + 0.5, "紧凑边距下监控卡片不应横向溢出 (w=\(width))")
            }
        }
    }

    static func testConfigurableSessionVisibleLimitAndSessionColorLinkage() {
        expectEqual(SessionListLayoutPolicy.defaultVisibleRowsWhenExpanded, 3, "默认展开展示会话条数应为 3")
        expectEqual(SessionListLayoutPolicy.minVisibleRowsWhenExpanded, 1, "最小展示条数下限应为 1")
        expectEqual(SessionListLayoutPolicy.maxConfigurableVisibleRowsWhenExpanded, 12, "最大展示条数上限应为 12")
        expectEqual(SessionListLayoutPolicy.clampedVisibleRows(0), 1, "低于下限时应夹紧为 1")
        expectEqual(SessionListLayoutPolicy.clampedVisibleRows(5), 5, "合法条数 5 应原样保留")
        expectEqual(SessionListLayoutPolicy.clampedVisibleRows(99), 12, "超过上限时应夹紧为 12")

        let fiveRowHeight = SessionListLayoutPolicy.scrollHeight(forCount: 15, visibleLimit: 5, chartExpanded: true)
        let expectedFiveRowHeight = SessionListLayoutPolicy.rowEstimatedHeight * 5 + SessionListLayoutPolicy.rowSpacing * 4
        expect(abs((fiveRowHeight ?? 0) - expectedFiveRowHeight) <= 0.1, "配置为 5 条且会话数为 15 时高度应严格等于 5 行总高 (actual=\(String(describing: fiveRowHeight)), expected=\(expectedFiveRowHeight))")
        let twoRowWhenLimitFive = SessionListLayoutPolicy.scrollHeight(forCount: 2, visibleLimit: 5, chartExpanded: true)
        let expectedTwoRowHeight = SessionListLayoutPolicy.rowEstimatedHeight * 2 + SessionListLayoutPolicy.rowSpacing
        expect(abs((twoRowWhenLimitFive ?? 0) - expectedTwoRowHeight) <= 0.1, "只有 2 条会话时不应按上限 5 条留空 (actual=\(String(describing: twoRowWhenLimitFive)))")

        let suiteName = "agyhub.tdd.visibleRows.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        expectEqual(SessionListLayoutPolicy.loadVisibleRows(from: defaults), 3, "未配置过时应读取默认值 3")
        MainActor.assumeIsolated { () -> Void in
            let store1 = AGYHubStore(startMonitoring: false, userDefaults: defaults)
            expectEqual(store1.expandedSessionRowLimit, 3, "新初始化 Store 默认展示条数应为 3")
            store1.updateExpandedSessionRowLimit(6)
            expectEqual(store1.expandedSessionRowLimit, 6, "更新后内存状态应立刻变为 6")

            let store2 = AGYHubStore(startMonitoring: false, userDefaults: defaults)
            expectEqual(store2.expandedSessionRowLimit, 6, "重连相同 UserDefaults 后应持久化保留 6 条")
        }

        let now = Date()
        let parentSession = SessionItem(
            uuid: "sess-parent",
            shortId: "sp",
            clientType: nil,
            parentConversationId: "",
            agentName: "",
            agentRole: "",
            title: "生成近7天线上情况报告",
            isRunning: true,
            statusLabel: nil,
            interactions: 1,
            inputTokens: 0,
            cacheTokens: 0,
            outputTokens: 0,
            contextTokens: 338_000,
            cachePct: 98,
            tps: 88,
            totalTokensConsumed: 5_000_000,
            totalCostUsd: 1.0,
            totalCacheConsumed: 4_800_000,
            totalInputConsumed: 100_000,
            totalOutputConsumed: 100_000,
            currentStall: 0,
            health: "ok",
            healthCode: nil,
            healthDesc: "",
            errorCode: nil,
            currentPhase: "",
            currentAction: "",
            recentError: nil,
            historySteps: [],
            exists: true,
            model: "gemini-2.5-pro",
            subagents: [
                SessionItem(
                    uuid: "sub-1",
                    shortId: "s1",
                    clientType: nil,
                    parentConversationId: "sess-parent",
                    agentName: "research",
                    agentRole: "research",
                    title: "research",
                    isRunning: true,
                    statusLabel: nil,
                    interactions: 1,
                    inputTokens: 0,
                    cacheTokens: 0,
                    outputTokens: 0,
                    contextTokens: 120_000,
                    cachePct: 95,
                    tps: 45,
                    totalTokensConsumed: 500_000,
                    totalCostUsd: 0.1,
                    totalCacheConsumed: 400_000,
                    totalInputConsumed: 50_000,
                    totalOutputConsumed: 50_000,
                    currentStall: 0,
                    health: "ok",
                    healthCode: nil,
                    healthDesc: "",
                    errorCode: nil,
                    currentPhase: "",
                    currentAction: "",
                    recentError: nil,
                    historySteps: [],
                    exists: true,
                    model: "gemini-2.5-flash",
                    subagents: [],
                    subagentCount: 0,
                    activeSubagentCount: 0,
                    activeSubagentTps: 0,
                    totalActiveSec: 0,
                    totalLocalSec: 0,
                    totalRemoteSec: 0,
                    totalErrorSec: 0,
                    localPct: nil,
                    remotePct: nil,
                    breakdownStr: ""
                )
            ],
            subagentCount: 1,
            activeSubagentCount: 1,
            activeSubagentTps: 45,
            totalActiveSec: 0,
            totalLocalSec: 0,
            totalRemoteSec: 0,
            totalErrorSec: 0,
            localPct: nil,
            remotePct: nil,
            breakdownStr: ""
        )

        let waitingParentWithSelfSub = SessionItem(
            uuid: "sess-waiting",
            shortId: "sw",
            clientType: nil,
            parentConversationId: "",
            agentName: "",
            agentRole: "",
            title: "🔥 插件-web 页面残影",
            isRunning: false,
            statusLabel: nil,
            interactions: 1,
            inputTokens: 0,
            cacheTokens: 0,
            outputTokens: 0,
            contextTokens: 212_000,
            cachePct: 99,
            tps: 0,
            totalTokensConsumed: 5_800_000,
            totalCostUsd: 1.2,
            totalCacheConsumed: 5_600_000,
            totalInputConsumed: 100_000,
            totalOutputConsumed: 100_000,
            currentStall: 0,
            health: "ok",
            healthCode: nil,
            healthDesc: "",
            errorCode: nil,
            currentPhase: "",
            currentAction: "",
            recentError: nil,
            historySteps: [],
            exists: true,
            model: "gemini-2.5-pro",
            subagents: [
                SessionItem(
                    uuid: "sub-self",
                    shortId: "ss",
                    clientType: nil,
                    parentConversationId: "sess-waiting",
                    agentName: "self",
                    agentRole: "self",
                    title: "self",
                    isRunning: true,
                    statusLabel: nil,
                    interactions: 1,
                    inputTokens: 0,
                    cacheTokens: 0,
                    outputTokens: 0,
                    contextTokens: 279_000,
                    cachePct: 96,
                    tps: 118,
                    totalTokensConsumed: 900_000,
                    totalCostUsd: 0.2,
                    totalCacheConsumed: 850_000,
                    totalInputConsumed: 30_000,
                    totalOutputConsumed: 20_000,
                    currentStall: 0,
                    health: "ok",
                    healthCode: nil,
                    healthDesc: "",
                    errorCode: nil,
                    currentPhase: "",
                    currentAction: "",
                    recentError: nil,
                    historySteps: [],
                    exists: true,
                    model: "gemini-2.5-pro",
                    subagents: [],
                    subagentCount: 0,
                    activeSubagentCount: 0,
                    activeSubagentTps: 0,
                    totalActiveSec: 0,
                    totalLocalSec: 0,
                    totalRemoteSec: 0,
                    totalErrorSec: 0,
                    localPct: nil,
                    remotePct: nil,
                    breakdownStr: ""
                )
            ],
            subagentCount: 1,
            activeSubagentCount: 1,
            activeSubagentTps: 118,
            totalActiveSec: 0,
            totalLocalSec: 0,
            totalRemoteSec: 0,
            totalErrorSec: 0,
            localPct: nil,
            remotePct: nil,
            breakdownStr: ""
        )

        let unplottedSession = SessionItem(
            uuid: "sess-idle",
            shortId: "si",
            clientType: nil,
            parentConversationId: "",
            agentName: "",
            agentRole: "",
            title: "历史空闲会话",
            isRunning: false,
            statusLabel: nil,
            interactions: 1,
            inputTokens: 0,
            cacheTokens: 0,
            outputTokens: 0,
            contextTokens: 62_000,
            cachePct: 96,
            tps: 0,
            totalTokensConsumed: 489_000,
            totalCostUsd: 0.1,
            totalCacheConsumed: 450_000,
            totalInputConsumed: 20_000,
            totalOutputConsumed: 19_000,
            currentStall: 0,
            health: "ok",
            healthCode: nil,
            healthDesc: "",
            errorCode: nil,
            currentPhase: "",
            currentAction: "",
            recentError: nil,
            historySteps: [],
            exists: true,
            model: "gemini-2.5-pro",
            subagents: [],
            subagentCount: 0,
            activeSubagentCount: 0,
            activeSubagentTps: 0,
            totalActiveSec: 0,
            totalLocalSec: 0,
            totalRemoteSec: 0,
            totalErrorSec: 0,
            localPct: nil,
            remotePct: nil,
            breakdownStr: ""
        )

        let telemetrySamples = [
            LiveTelemetrySample(
                id: 1,
                timestamp: now.addingTimeInterval(-30),
                activeAgentCount: 3,
                totalTps: 251,
                totalTokensCumulative: 1_000_000,
                deltaTokens: 100_000,
                cachePct: 96,
                isIdleCacheHold: false,
                agentContexts: [
                    AgentContextPoint(agentId: "sess-parent", label: "生成近7天线上情况报告", contextTokens: 338_000, isRunning: true, tps: 88),
                    AgentContextPoint(agentId: "sub-1", label: "research", contextTokens: 120_000, isRunning: true, tps: 45, parentAgentId: "sess-parent"),
                    AgentContextPoint(agentId: "sub-self", label: "self", contextTokens: 279_000, isRunning: true, tps: 118, parentAgentId: "sess-waiting")
                ]
            )
        ]

        let seriesList = LiveTelemetryPolicy.agentSeries(in: telemetrySamples)
        let links = LiveTelemetryPolicy.sessionColorLinks(
            sessions: [parentSession, waitingParentWithSelfSub, unplottedSession],
            seriesList: seriesList
        )

        expect(links["sess-idle"] == nil, "没有曲线的空闲会话不应挂载图表颜色关联")

        if let parentLink = links["sess-parent"],
           let rootSeries = seriesList.first(where: { $0.agentId == "sess-parent" }),
           let subSeries = seriesList.first(where: { $0.agentId == "sub-1" }) {
            expect(parentLink.hasDirectSeries, "自身有曲线的父会话 hasDirectSeries 应为 true")
            expectEqual(parentLink.primaryTone, LiveTelemetryColorPalette.tone(familyIndex: rootSeries.familyIndex, tier: rootSeries.familyTier), "主色调应等于父曲线本身颜色")
            expectEqual(parentLink.childTones, [LiveTelemetryColorPalette.tone(familyIndex: subSeries.familyIndex, tier: subSeries.familyTier)], "子色标应包含其子 Agent 曲线颜色")
            expectEqual(parentLink.seriesIds, Set(["sess-parent", "sub-1"]), "关联的 seriesIds 应同时覆盖父曲线和子曲线")
        } else {
            expect(false, "sess-parent 必须建立颜色映射")
        }

        if let waitingLink = links["sess-waiting"],
           let selfSeries = seriesList.first(where: { $0.agentId == "sub-self" }) {
            expect(!waitingLink.hasDirectSeries, "仅子 Agent 在图上有曲线时父会话 hasDirectSeries 应为 false")
            let expectedChildTone = LiveTelemetryColorPalette.tone(familyIndex: selfSeries.familyIndex, tier: selfSeries.familyTier)
            expectEqual(waitingLink.primaryTone, expectedChildTone, "仅子 Agent 出线时父会话行应继承子曲线家族色以便视觉追溯")
            expectEqual(waitingLink.childTones, [expectedChildTone], "childTones 应记录子曲线颜色")
            expectEqual(waitingLink.seriesIds, Set(["sub-self"]), "seriesIds 应包含 sub-self")
        } else {
            expect(false, "sess-waiting 仅通过 sub-self 出线时也必须能关联到颜色")
        }

        expect(!LiveTelemetryOverviewCardView.showsStandaloneLegendStrip, "图表底部独立 legend 盒子应默认隐藏，改为通过 SESSIONS 行关联")

        MainActor.assumeIsolated { () -> Void in
            let rowWithLink = CompactSessionRowView(
                session: waitingParentWithSelfSub,
                chartColorLink: links["sess-waiting"]
            )
            .environment(\.agyLanguage, .zhHans)
            let rowHost = NSHostingView(rootView: rowWithLink.frame(width: 420))
            rowHost.layoutSubtreeIfNeeded()
            expect(rowHost.fittingSize.width <= 420.5, "带图表颜色标识的会话行不得横向溢出")
            expect(abs(rowHost.fittingSize.height - SessionListLayoutPolicy.rowEstimatedHeight) <= 0.5, "带图标和子Agent胶囊的行高度必须严格等于 rowEstimatedHeight 才不会露出下一行半行 (actual=\(rowHost.fittingSize.height), policy=\(SessionListLayoutPolicy.rowEstimatedHeight))")

            let plainRow = CompactSessionRowView(session: unplottedSession)
                .environment(\.agyLanguage, .zhHans)
            let plainHost = NSHostingView(rootView: plainRow.frame(width: 420))
            plainHost.layoutSubtreeIfNeeded()
            expect(abs(plainHost.fittingSize.height - SessionListLayoutPolicy.rowEstimatedHeight) <= 0.5, "普通纯文本行高度也必须严格等于 rowEstimatedHeight 保证 4 条刚好是整数行 (actual=\(plainHost.fittingSize.height), policy=\(SessionListLayoutPolicy.rowEstimatedHeight))")

            for count in [3, 4, 5, 6] {
                let alloc = DashboardSplitLayoutPolicy.resolveAllocation(
                    totalAvailableHeight: 600.0,
                    storedFraction: -1,
                    displaySessionsCount: 15,
                    expandedSessionRowLimit: count
                )
                let listViewport = alloc.sessionsHeight - (SessionListLayoutPolicy.headerHeight + SessionListLayoutPolicy.headerToListSpacing)
                let exactRowsHeight = CGFloat(count) * SessionListLayoutPolicy.rowEstimatedHeight + CGFloat(count - 1) * SessionListLayoutPolicy.rowSpacing
                expect(abs(listViewport - exactRowsHeight) <= 0.1, "设置为 \(count) 条时 SESSIONS 滚动视口必须严格等于 \(count) 整行高度，零半行露出 (actual=\(listViewport), exact=\(exactRowsHeight))")
            }
        }
    }

    static func testDashboardSplitLayoutDraggableResizeClampingAndPersistence() {
        expect(DashboardSplitLayoutPolicy.embedsDragHandleInSessionsHeader, "拖拽手柄应内嵌到 SESSIONS 标题栏中，不再额外占用独立的中间横条高度")
        expect(DashboardSplitLayoutPolicy.dividerHeight <= 6.0, "嵌入标题栏后两区外间距应收紧到 <= 6pt 以节约纵向空间 (actual=\(DashboardSplitLayoutPolicy.dividerHeight))")

        let totalHeight: CGFloat = 480.0
        let dividerH = DashboardSplitLayoutPolicy.dividerHeight
        let usable = totalHeight - dividerH

        let autoDefault = DashboardSplitLayoutPolicy.resolveAllocation(
            totalAvailableHeight: totalHeight,
            storedFraction: -1,
            displaySessionsCount: 15,
            expandedSessionRowLimit: 3
        )
        expect(abs((autoDefault.telemetryHeight + autoDefault.dividerHeight + autoDefault.sessionsHeight) - totalHeight) <= 0.5, "双区高度与分隔栏之和必须严格等于可用总高度以防挤压底部状态栏")
        expect(autoDefault.sessionsHeight >= 115.0 && autoDefault.sessionsHeight <= 140.0, "未拖拽前默认 3 条会话区应占 ~126pt (actual=\(autoDefault.sessionsHeight))")

        let dragUpFraction = DashboardSplitLayoutPolicy.updatedFractionAfterDrag(
            startTelemetryHeight: autoDefault.telemetryHeight,
            dragDeltaY: -130.0,
            totalAvailableHeight: totalHeight
        )
        let afterDragUp = DashboardSplitLayoutPolicy.resolveAllocation(
            totalAvailableHeight: totalHeight,
            storedFraction: dragUpFraction,
            displaySessionsCount: 15,
            expandedSessionRowLimit: 3
        )
        expect(afterDragUp.telemetryHeight < autoDefault.telemetryHeight, "向上拖动分隔条应压缩实时监控区高度")
        expect(afterDragUp.sessionsHeight > autoDefault.sessionsHeight, "向上拖动分隔条应同步扩大 SESSIONS 区域高度")
        expect(abs((afterDragUp.telemetryHeight + afterDragUp.dividerHeight + afterDragUp.sessionsHeight) - totalHeight) <= 0.5, "上拉后总高度不得溢出")

        let extremeUpFraction = DashboardSplitLayoutPolicy.updatedFractionAfterDrag(
            startTelemetryHeight: autoDefault.telemetryHeight,
            dragDeltaY: -999.0,
            totalAvailableHeight: totalHeight
        )
        let clampedUp = DashboardSplitLayoutPolicy.resolveAllocation(
            totalAvailableHeight: totalHeight,
            storedFraction: extremeUpFraction,
            displaySessionsCount: 15,
            expandedSessionRowLimit: 3
        )
        expect(clampedUp.telemetryHeight >= DashboardSplitLayoutPolicy.minTelemetryHeight - 0.5, "极限上拖仍应保留实时监控区最小可读高度 (actual=\(clampedUp.telemetryHeight))")

        let extremeDownFraction = DashboardSplitLayoutPolicy.updatedFractionAfterDrag(
            startTelemetryHeight: autoDefault.telemetryHeight,
            dragDeltaY: 999.0,
            totalAvailableHeight: totalHeight
        )
        let clampedDown = DashboardSplitLayoutPolicy.resolveAllocation(
            totalAvailableHeight: totalHeight,
            storedFraction: extremeDownFraction,
            displaySessionsCount: 15,
            expandedSessionRowLimit: 3
        )
        expect(clampedDown.sessionsHeight >= DashboardSplitLayoutPolicy.minSessionsHeight - 0.5, "极限下拖仍应保留 SESSIONS 区最小可用高度 (actual=\(clampedDown.sessionsHeight))")

        let compactWindowAlloc = DashboardSplitLayoutPolicy.resolveAllocation(
            totalAvailableHeight: 300.0,
            storedFraction: -1,
            displaySessionsCount: 15,
            expandedSessionRowLimit: 10
        )
        expect(abs((compactWindowAlloc.telemetryHeight + compactWindowAlloc.dividerHeight + compactWindowAlloc.sessionsHeight) - 300.0) <= 0.5, "即使设置展示 10 条会话且窗口较矮，总高度也不得越界遮挡底部状态栏")
        expect(compactWindowAlloc.telemetryHeight >= usable * 0.1 || compactWindowAlloc.telemetryHeight >= DashboardSplitLayoutPolicy.minTelemetryHeight - 1.0, "较矮窗口下图表区也应保底可见")

        let now = Date()
        let sample = LiveTelemetrySample(
            id: 1,
            timestamp: now,
            activeAgentCount: 1,
            totalTps: 100,
            totalTokensCumulative: 1000,
            deltaTokens: 100,
            cachePct: 95,
            isIdleCacheHold: false,
            agentContexts: [AgentContextPoint(agentId: "a1", label: "s1", contextTokens: 100_000, isRunning: true, tps: 100)]
        )
        let today = TodayStats(totalTokens: 1000, cacheTokens: 900, inputTokens: 50, outputTokens: 50, cachePct: 90, costUsd: 1.0, hasData: true, source: "test")
        MainActor.assumeIsolated { () -> Void in
            let compactChartCard = LiveTelemetryOverviewCardView(
                samples: [sample],
                todayStats: today,
                minPlotHeight: DashboardSplitLayoutPolicy.splitMinPlotHeight
            )
            .environment(\.agyLanguage, .zhHans)
            let host = NSHostingView(rootView: compactChartCard.frame(width: 420))
            host.layoutSubtreeIfNeeded()
            expect(host.fittingSize.height <= DashboardSplitLayoutPolicy.minTelemetryHeight + 2.0, "可拖拽模式下的监控卡片最小自然高度应能在 minTelemetryHeight (~\(Int(DashboardSplitLayoutPolicy.minTelemetryHeight))pt) 内放得下而不溢出 (actual=\(host.fittingSize.height))")
        }
    }

    static func testLiveTelemetryForkJunctionAlignsStrictlyOnParentCurveWithoutDip() {
        let baseDate = Date(timeIntervalSince1970: 1700003000)
        var history: [LiveTelemetrySample] = []
        var nextId = 1
        var prevStats: TodayStats? = nil

        func makeSession(uuid: String, title: String, isRunning: Bool, contextTokens: Int, tps: Double, subagents: [SessionItem] = []) -> SessionItem {
            SessionItem(
                uuid: uuid,
                shortId: String(uuid.prefix(4)),
                clientType: nil,
                parentConversationId: "",
                agentName: "",
                agentRole: "",
                title: title,
                isRunning: isRunning,
                statusLabel: nil,
                interactions: 1,
                inputTokens: 0,
                cacheTokens: 0,
                outputTokens: 0,
                contextTokens: contextTokens,
                cachePct: 95.0,
                tps: tps,
                totalTokensConsumed: 1_000_000,
                totalCostUsd: 1.0,
                totalCacheConsumed: 950_000,
                totalInputConsumed: 30_000,
                totalOutputConsumed: 20_000,
                currentStall: 0,
                health: "ok",
                healthCode: nil,
                healthDesc: "",
                errorCode: nil,
                currentPhase: "",
                currentAction: "",
                recentError: nil,
                historySteps: [],
                exists: true,
                model: "gemini-2.5-pro",
                subagents: subagents,
                subagentCount: subagents.count,
                activeSubagentCount: subagents.filter(\.isRunning).count,
                activeSubagentTps: subagents.filter(\.isRunning).reduce(0.0) { $0 + $1.tps },
                totalActiveSec: 0,
                totalLocalSec: 0,
                totalRemoteSec: 0,
                totalErrorSec: 0,
                localPct: nil,
                remotePct: nil,
                breakdownStr: ""
            )
        }

        func makeSubagent(uuid: String, parentId: String, contextTokens: Int, tps: Double) -> SessionItem {
            SessionItem(
                uuid: uuid,
                shortId: String(uuid.prefix(4)),
                clientType: nil,
                parentConversationId: parentId,
                agentName: "research",
                agentRole: "research",
                title: "research",
                isRunning: true,
                statusLabel: nil,
                interactions: 1,
                inputTokens: 0,
                cacheTokens: 0,
                outputTokens: 0,
                contextTokens: contextTokens,
                cachePct: 95.0,
                tps: tps,
                totalTokensConsumed: 200_000,
                totalCostUsd: 0.2,
                totalCacheConsumed: 180_000,
                totalInputConsumed: 10_000,
                totalOutputConsumed: 10_000,
                currentStall: 0,
                health: "ok",
                healthCode: nil,
                healthDesc: "",
                errorCode: nil,
                currentPhase: "",
                currentAction: "",
                recentError: nil,
                historySteps: [],
                exists: true,
                model: "gemini-2.5-flash",
                subagents: [],
                subagentCount: 0,
                activeSubagentCount: 0,
                activeSubagentTps: 0,
                totalActiveSec: 0,
                totalLocalSec: 0,
                totalRemoteSec: 0,
                totalErrorSec: 0,
                localPct: nil,
                remotePct: nil,
                breakdownStr: ""
            )
        }

        func makePayload(_ sessions: [SessionItem], tokens: Int) -> MonitorPayload {
            MonitorPayload(
                timestamp: "15:27:30",
                dataDir: "~/.gemini/antigravity",
                activeCount: sessions.filter(\.isActivelyWorking).count,
                totalRoundtrips: 10,
                hasAlert: false,
                menubar: MenuBarSummary(icon: "🟢", text: "", statusLevel: "working", activeCount: sessions.filter(\.isActivelyWorking).count),
                todayStats: TodayStats(totalTokens: tokens, cacheTokens: tokens - 10_000, inputTokens: 8000, outputTokens: 2000, cachePct: 95.0, costUsd: 5.0, hasData: true, source: "test"),
                sessions: sessions
            )
        }

        let parentHigh = makeSession(uuid: "p-blue", title: "生成近7天线上情况报告", isRunning: true, contextTokens: 235_000, tps: 90)
        for offset in [0.0, 10.0, 20.0, 30.0] {
            (history, prevStats, _) = LiveTelemetryPolicy.appendSample(
                to: history,
                payload: makePayload([parentHigh], tokens: 1_000_000 + Int(offset) * 10_000),
                previousStats: prevStats,
                nextId: &nextId,
                now: baseDate.addingTimeInterval(offset)
            )
        }

        let parentCompactedWithParallelChild = makeSession(
            uuid: "p-blue",
            title: "生成近7天线上情况报告",
            isRunning: true,
            contextTokens: 29_000,
            tps: 30,
            subagents: [makeSubagent(uuid: "sub-sky", parentId: "p-blue", contextTokens: 12_000, tps: 78)]
        )
        (history, prevStats, _) = LiveTelemetryPolicy.appendSample(
            to: history,
            payload: makePayload([parentCompactedWithParallelChild], tokens: 1_500_000),
            previousStats: prevStats,
            nextId: &nextId,
            now: baseDate.addingTimeInterval(34.0)
        )

        let parentWaitingChild = makeSession(
            uuid: "p-blue",
            title: "生成近7天线上情况报告",
            isRunning: false,
            contextTokens: 29_000,
            tps: 0,
            subagents: [makeSubagent(uuid: "sub-sky", parentId: "p-blue", contextTokens: 45_000, tps: 85)]
        )
        (history, prevStats, _) = LiveTelemetryPolicy.appendSample(
            to: history,
            payload: makePayload([parentWaitingChild], tokens: 1_700_000),
            previousStats: prevStats,
            nextId: &nextId,
            now: baseDate.addingTimeInterval(40.0)
        )

        let childLater = makeSession(
            uuid: "p-blue",
            title: "生成近7天线上情况报告",
            isRunning: false,
            contextTokens: 29_000,
            tps: 0,
            subagents: [makeSubagent(uuid: "sub-sky", parentId: "p-blue", contextTokens: 129_000, tps: 95)]
        )
        (history, prevStats, _) = LiveTelemetryPolicy.appendSample(
            to: history,
            payload: makePayload([childLater], tokens: 1_900_000),
            previousStats: prevStats,
            nextId: &nextId,
            now: baseDate.addingTimeInterval(55.0)
        )

        let seriesList = LiveTelemetryPolicy.agentSeries(in: history)
        let resolved = LiveTelemetryPolicy.resolvedCurveSegments(for: seriesList, windowSeconds: 300)

        guard let parentResolved = resolved.first(where: { $0.agentId == "p-blue" }),
              let childResolved = resolved.first(where: { $0.agentId == "sub-sky" }),
              let parentPts = parentResolved.segments.first?.points,
              let childSeg = childResolved.segments.first,
              let junction = childSeg.forkJunction else {
            expect(false, "必须为子 Agent 生成带精确交点 forkJunction 的分叉曲线")
            return
        }

        let parentFirstT = parentPts.first!.timestamp
        let parentLastT = parentPts.last!.timestamp
        expect(junction.timestamp >= parentFirstT && junction.timestamp <= parentLastT, "分叉交点时间必须严格落在父曲线平滑时间区间内")

        let parentYAtFork = LiveTelemetryPolicy.interpolatedContext(in: parentPts, at: junction.timestamp)
        expect(abs(parentYAtFork - Double(junction.contextTokens)) <= 2.0, "分叉交点 Y 坐标必须严格贴合在平滑后的父曲线上，绝不能悬空脱离 (parentY=\(parentYAtFork), forkY=\(junction.contextTokens))")

        expectEqual(childSeg.points.first?.timestamp, junction.timestamp, "子曲线渲染首点时间必须严格从分叉交点出发")
        expectEqual(childSeg.points.first?.contextTokens, junction.contextTokens, "子曲线渲染首点高度必须严格等于分叉交点高度")

        for idx in 1..<childSeg.points.count {
            expect(childSeg.points[idx].timestamp >= childSeg.points[idx - 1].timestamp, "分叉后子曲线时间轴必须单调向右推进，不得回跳")
        }
    }

    static func testTodayUsagePillInHeaderWithoutLeadingIconAndFitsAllWidths() {
        expect(DashboardHeaderBarView.showsTodayPillInHeader, "Today 用量入口应重新放在顶部标题栏中央以便第一眼查看到花费与用量")
        expect(!DashboardHeaderBarView.showsLeadingLogoOnTodayPill, "Today 左侧无用柱状图图标仍应保持移除以维持极简清晰")
        expect(!DashboardFooterBarView.showsTodayPillInFooter, "底部栏应恢复为左时间戳 + 右设置按钮的纯净样式")
        expectEqual(TodayUsagePillButton.closedChevronSystemName, "chevron.down", "折叠态箭头应向下指示可展开今日账单明细")
        expectEqual(TodayUsagePillButton.openChevronSystemName, "chevron.up", "展开态箭头应向上指示可收起今日账单明细")
        expect(TodayUsagePillButton.usesElevatedCrispSurface, "Today 用量胶囊在浅色底上应使用通透亮白卡片面而非灰扑扑的半透明灰底")

        let stats = TodayStats(
            totalTokens: 218_900_000,
            cacheTokens: 210_000_000,
            inputTokens: 6_000_000,
            outputTokens: 2_900_000,
            cachePct: 96.0,
            costUsd: 57.03,
            hasData: true,
            source: "test"
        )
        let bigStats = TodayStats(
            totalTokens: 999_800_000,
            cacheTokens: 920_000_000,
            inputTokens: 50_000_000,
            outputTokens: 29_800_000,
            cachePct: 92.0,
            costUsd: 185.42,
            hasData: true,
            source: "test"
        )

        MainActor.assumeIsolated { () -> Void in
            for sampleStats in [stats, bigStats] {
                for isOpen in [false, true] {
                    for lang in [AppLanguage.Resolved.zhHans, AppLanguage.Resolved.en] {
                        for width in [CGFloat(320), CGFloat(360), CGFloat(390), CGFloat(412), CGFloat(440), CGFloat(464)] {
                            let metrics = DashboardAdaptiveLayoutMetrics.metrics(forWidth: width)
                            let header = DashboardHeaderBarView(
                                stats: sampleStats,
                                hasAlert: false,
                                isUsageOpen: isOpen,
                                isStandaloneWindow: false,
                                lang: lang,
                                refreshSpinCount: 0,
                                outerHorizontalPadding: metrics.outerHorizontalPadding,
                                onToggleUsage: {},
                                onRefresh: {},
                                onOpenStandalone: {},
                                onClose: {}
                            )
                            let headerHost = NSHostingView(rootView: header.frame(width: width))
                            headerHost.layoutSubtreeIfNeeded()
                            let hFit = headerHost.fittingSize
                            expect(hFit.width <= width + 0.5, "顶部栏在宽度 \(width) (\(lang.rawValue)) 不得横向溢出 (actual=\(hFit.width))")
                            expect(hFit.height <= 46.0, "顶部栏在宽度 \(width) 必须保持单行紧凑高度 (actual=\(hFit.height))")

                            let footer = DashboardFooterBarView(
                                lastUpdatedTimeStr: "16:07:52",
                                stats: sampleStats,
                                isUsageOpen: isOpen,
                                lang: lang,
                                horizontalPadding: metrics.footerHorizontalPadding,
                                onToggleUsage: {},
                                onOpenSettings: {}
                            )
                            let footerHost = NSHostingView(rootView: footer.frame(width: width))
                            footerHost.layoutSubtreeIfNeeded()
                            let fFit = footerHost.fittingSize
                            expect(fFit.width <= width + 0.5, "底部栏在宽度 \(width) (\(lang.rawValue)) 不得横向溢出 (actual=\(fFit.width))")
                            expect(fFit.height <= 42.0, "底部栏在宽度 \(width) 必须保持单行紧凑高度 (actual=\(fFit.height))")
                        }
                    }
                }
            }
        }
    }

    static func testChartNearestCurveHitTestAndBidirectionalHighlight() {
        let now = Date(timeIntervalSince1970: 1700004000)
        let domain = now.addingTimeInterval(-300)...now
        let plotSize = CGSize(width: 360, height: 140)
        let maxCtx = 360_000

        let topSeries = AgentContextSeries(
            agentId: "sess-top",
            label: "Agyhub 开源",
            isRunning: true,
            latestContextTokens: 277_000,
            latestTps: 88,
            colorIndex: 0,
            familyIndex: 0,
            familyTier: 0,
            parentAgentId: nil,
            segments: [
                AgentCurveSegment(
                    id: "top-0",
                    isForkSegment: false,
                    points: [
                        AgentSeriesSamplePoint(timestamp: now.addingTimeInterval(-240), contextTokens: 265_000, isRunning: true, tps: 80),
                        AgentSeriesSamplePoint(timestamp: now, contextTokens: 277_000, isRunning: true, tps: 88)
                    ]
                )
            ]
        )

        let childSeries = AgentContextSeries(
            agentId: "sub-green",
            label: "self",
            isRunning: false,
            latestContextTokens: 60_000,
            latestTps: 0,
            colorIndex: 1,
            familyIndex: 1,
            familyTier: 1,
            parentAgentId: "sess-parent",
            segments: [
                AgentCurveSegment(
                    id: "sub-0",
                    isForkSegment: false,
                    points: [
                        AgentSeriesSamplePoint(timestamp: now.addingTimeInterval(-240), contextTokens: 55_000, isRunning: false, tps: 0),
                        AgentSeriesSamplePoint(timestamp: now, contextTokens: 65_000, isRunning: false, tps: 0)
                    ]
                )
            ]
        )

        let seriesList = [topSeries, childSeries]
        let resolved = LiveTelemetryPolicy.resolvedCurveSegments(for: seriesList, windowSeconds: 300)

        let nearTopY = (1.0 - 270_000.0 / Double(maxCtx)) * Double(plotSize.height) + 6.0
        let hitTop = LiveTelemetryPolicy.nearestAgentId(
            in: resolved,
            seriesList: seriesList,
            timeDomain: domain,
            maxContext: maxCtx,
            plotSize: plotSize,
            hoverLocation: CGPoint(x: 240, y: nearTopY)
        )
        expectEqual(hitTop, "sess-top", "鼠标靠近上方 270k 曲线时应命中 sess-top")

        let nearBottomY = (1.0 - 60_000.0 / Double(maxCtx)) * Double(plotSize.height) - 8.0
        let hitBottom = LiveTelemetryPolicy.nearestAgentId(
            in: resolved,
            seriesList: seriesList,
            timeDomain: domain,
            maxContext: maxCtx,
            plotSize: plotSize,
            hoverLocation: CGPoint(x: 240, y: nearBottomY)
        )
        expectEqual(hitBottom, "sub-green", "鼠标靠近下方 60k 子曲线时应命中 sub-green")

        let middleGapY = (1.0 - 165_000.0 / Double(maxCtx)) * Double(plotSize.height)
        let hitGap = LiveTelemetryPolicy.nearestAgentId(
            in: resolved,
            seriesList: seriesList,
            timeDomain: domain,
            maxContext: maxCtx,
            plotSize: plotSize,
            hoverLocation: CGPoint(x: 240, y: middleGapY)
        )
        expect(hitGap == nil, "鼠标停留在两条线之间的空白远区时不应误触高亮 (actual=\(String(describing: hitGap)))")

        let topSession = SessionItem(uuid: "sess-top", shortId: "st", title: "Agyhub 开源", isRunning: true, contextTokens: 277_000, tps: 88)
        let subItem = SessionItem(uuid: "sub-green", shortId: "sg", parentConversationId: "sess-parent", agentName: "self", title: "self", isRunning: false, contextTokens: 65_000)
        let parentSession = SessionItem(uuid: "sess-parent", shortId: "sp", title: "生成近7天线上情况报告", isRunning: false, contextTokens: 55_000, subagents: [subItem], subagentCount: 1)
        let links = LiveTelemetryPolicy.sessionColorLinks(sessions: [topSession, parentSession], seriesList: seriesList)

        expectEqual(
            LiveTelemetryPolicy.matchingSessionId(forAgentId: "sub-green", links: links),
            "sess-parent",
            "图上悬停子 Agent 曲线 sub-green 时，应反向映射高亮所属的父会话 sess-parent"
        )
        expectEqual(
            LiveTelemetryPolicy.matchingSessionId(forAgentId: "sess-top", links: links),
            "sess-top",
            "图上悬停 sess-top 曲线时，应反向映射高亮对应的会话 sess-top"
        )

        MainActor.assumeIsolated { () -> Void in
            let row = CompactSessionRowView(
                session: parentSession,
                chartColorLink: links["sess-parent"],
                isHighlightedFromChart: true
            )
            .environment(\.agyLanguage, .zhHans)
            let host = NSHostingView(rootView: row.frame(width: 420))
            host.layoutSubtreeIfNeeded()
            expect(host.fittingSize.width <= 420.5, "被图表反向高亮的会话行不得横向溢出")
            expect(abs(host.fittingSize.height - SessionListLayoutPolicy.rowEstimatedHeight) <= 0.5, "被图表反向高亮的会话行必须保持严格单行高度 (actual=\(host.fittingSize.height))")
        }
    }

    static func testLiveTelemetryColorsRemainIdenticalAcrossAllTimeRanges() {
        let now = Date(timeIntervalSince1970: 1700005000)
        let fullHistory: [LiveTelemetrySample] = [
            LiveTelemetrySample(
                id: 1,
                timestamp: now.addingTimeInterval(-900),
                activeAgentCount: 1,
                totalTps: 60,
                totalTokensCumulative: 100_000,
                deltaTokens: 100_000,
                cachePct: 95,
                isIdleCacheHold: false,
                agentContexts: [
                    AgentContextPoint(agentId: "root-early", label: "早期会话", contextTokens: 180_000, isRunning: true, tps: 60)
                ]
            ),
            LiveTelemetrySample(
                id: 2,
                timestamp: now.addingTimeInterval(-500),
                activeAgentCount: 2,
                totalTps: 120,
                totalTokensCumulative: 250_000,
                deltaTokens: 150_000,
                cachePct: 96,
                isIdleCacheHold: false,
                agentContexts: [
                    AgentContextPoint(agentId: "root-early", label: "早期会话", contextTokens: 190_000, isRunning: false, tps: 0),
                    AgentContextPoint(agentId: "root-mid", label: "Agyhub 开源", contextTokens: 280_000, isRunning: true, tps: 120)
                ]
            ),
            LiveTelemetrySample(
                id: 3,
                timestamp: now.addingTimeInterval(-180),
                activeAgentCount: 2,
                totalTps: 160,
                totalTokensCumulative: 450_000,
                deltaTokens: 200_000,
                cachePct: 96,
                isIdleCacheHold: false,
                agentContexts: [
                    AgentContextPoint(agentId: "root-mid", label: "Agyhub 开源", contextTokens: 299_000, isRunning: true, tps: 90),
                    AgentContextPoint(agentId: "root-late", label: "生成近7天报告", contextTokens: 55_000, isRunning: true, tps: 70)
                ]
            ),
            LiveTelemetrySample(
                id: 4,
                timestamp: now.addingTimeInterval(-40),
                activeAgentCount: 3,
                totalTps: 240,
                totalTokensCumulative: 700_000,
                deltaTokens: 250_000,
                cachePct: 97,
                isIdleCacheHold: false,
                agentContexts: [
                    AgentContextPoint(agentId: "root-mid", label: "Agyhub 开源", contextTokens: 299_000, isRunning: true, tps: 80),
                    AgentContextPoint(agentId: "sub-late-1", label: "research-1", contextTokens: 75_000, isRunning: true, tps: 90, parentAgentId: "root-late"),
                    AgentContextPoint(agentId: "sub-late-2", label: "research-2", contextTokens: 82_000, isRunning: true, tps: 70, parentAgentId: "root-late")
                ]
            )
        ]

        let pinned = LiveTelemetryPolicy.updatedPinnedFamilies(existing: [:], from: fullHistory)
        let samples1m = LiveTelemetryPolicy.samples(in: .oneMinute, from: fullHistory, now: now)
        let samples3m = LiveTelemetryPolicy.samples(in: .threeMinutes, from: fullHistory, now: now)
        let samples15m = LiveTelemetryPolicy.samples(in: .fifteenMinutes, from: fullHistory, now: now)
        let samples1h = LiveTelemetryPolicy.samples(in: .oneHour, from: fullHistory, now: now)

        let s1m = Dictionary(uniqueKeysWithValues: LiveTelemetryPolicy.agentSeries(in: samples1m, colorAnchorSamples: fullHistory, pinnedFamilyByRoot: pinned).map { ($0.agentId, $0) })
        let s3m = Dictionary(uniqueKeysWithValues: LiveTelemetryPolicy.agentSeries(in: samples3m, colorAnchorSamples: fullHistory, pinnedFamilyByRoot: pinned).map { ($0.agentId, $0) })
        let s15m = Dictionary(uniqueKeysWithValues: LiveTelemetryPolicy.agentSeries(in: samples15m, colorAnchorSamples: fullHistory, pinnedFamilyByRoot: pinned).map { ($0.agentId, $0) })
        let s1h = Dictionary(uniqueKeysWithValues: LiveTelemetryPolicy.agentSeries(in: samples1h, colorAnchorSamples: fullHistory, pinnedFamilyByRoot: pinned).map { ($0.agentId, $0) })

        for agentId in ["root-mid", "sub-late-1", "sub-late-2"] {
            expectEqual(s1m[agentId]?.familyIndex, s3m[agentId]?.familyIndex, "切换 1m vs 3m 时 \(agentId) 家族色系必须完全一致")
            expectEqual(s3m[agentId]?.familyIndex, s15m[agentId]?.familyIndex, "切换 3m vs 15m 时 \(agentId) 家族色系必须完全一致")
            expectEqual(s15m[agentId]?.familyIndex, s1h[agentId]?.familyIndex, "切换 15m vs 1h 时 \(agentId) 家族色系必须完全一致")
            expectEqual(s1m[agentId]?.familyTier, s3m[agentId]?.familyTier, "切换 1m vs 3m 时 \(agentId) 子梯队色阶必须完全一致")
            expectEqual(s3m[agentId]?.familyTier, s15m[agentId]?.familyTier, "切换 3m vs 15m 时 \(agentId) 子梯队色阶必须完全一致")
            expectEqual(s15m[agentId]?.familyTier, s1h[agentId]?.familyTier, "切换 15m vs 1h 时 \(agentId) 子梯队色阶必须完全一致")
        }

        expect(s3m["root-mid"]?.familyIndex != s3m["root-late"]?.familyIndex, "不同根会话必须持有各自独立的家族色系")
    }

    static func testLiveTelemetryPaletteEightFamiliesAndUniformPerceptualProgression() {
        expectEqual(LiveTelemetryColorPalette.familySpecs.count, 8, "预设主色系配色表应包含 8 组高区分度家族")
        expectEqual(LiveTelemetryColorPalette.families.count, 8, "families 数组应与 8 组 familySpecs 严格对齐")

        for (famIdx, spec) in LiveTelemetryColorPalette.familySpecs.enumerated() {
            expect(!spec.nameZh.isEmpty && !spec.nameEn.isEmpty, "第 \(famIdx) 组配色方案必须有中英文名称")
            expect(spec.childTones.count >= 4, "第 \(famIdx) 组 (\(spec.nameZh)) 至少应定义 4 个子 Agent 梯队色")
            let t0 = LiveTelemetryColorPalette.tone(familyIndex: famIdx, tier: 0)
            let t1 = LiveTelemetryColorPalette.tone(familyIndex: famIdx, tier: 1)
            let t2 = LiveTelemetryColorPalette.tone(familyIndex: famIdx, tier: 2)
            expectEqual(t0, spec.rootTone, "family \(famIdx) tier 0 必须严格等于主会话预设色")
            expect(t0.euclideanDistance(to: t1) >= 0.28, "family \(famIdx) (\(spec.nameZh)) 主色与子1之间必须有 >= 0.28 的明显色差 (actual=\(t0.euclideanDistance(to: t1)))")
            expect(t1.euclideanDistance(to: t2) >= 0.28, "family \(famIdx) (\(spec.nameZh)) 子1与子2之间必须有 >= 0.28 的明显色差 (actual=\(t1.euclideanDistance(to: t2)))")
            expect(t0.relativeLuminance + 0.14 < t1.relativeLuminance, "family \(famIdx) 主色亮度应明显深于子1形成自然视觉锚点")
            expect(t1.relativeLuminance + 0.10 < t2.relativeLuminance, "family \(famIdx) 子2应明显浅于子1")
        }

        let roots = LiveTelemetryColorPalette.familySpecs.map(\.rootTone)
        for i in 0..<roots.count {
            for j in (i + 1)..<roots.count {
                let d = roots[i].euclideanDistance(to: roots[j])
                expect(d >= 0.24, "主会话色系 \(i) 与 \(j) 之间色彩间距过近会混淆 (d=\(d))")
            }
        }
    }

    static func testSettingsOverlayDismissesOnOutsideTapAndOmitsFooterQuitBar() {
        expect(!SettingsPopoverView.showsFooterQuitAndHintBar, "设置弹窗底部“关闭窗口不退出常驻”提示与退出按钮应移除")
        expect(SettingsPopoverView.dismissesOnOutsideScrimTap, "设置弹窗应改用支持点击外部遮罩关闭的悬浮浮层承载")

        let suiteName = "agyhub.tdd.settings.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        MainActor.assumeIsolated { () -> Void in
            let store = AGYHubStore(startMonitoring: false, userDefaults: defaults)
            for lang in [AppLanguage.Resolved.zhHans, AppLanguage.Resolved.en] {
                for width in [CGFloat(328), CGFloat(360)] {
                    let view = SettingsPopoverView(store: store, onClose: {})
                        .environment(\.agyLanguage, lang)
                    let host = NSHostingView(rootView: view.frame(width: width))
                    host.layoutSubtreeIfNeeded()
                    expect(host.fittingSize.width <= width + 0.5, "精简后的设置卡片在 \(width)pt 宽度内不得横向溢出 (actual=\(host.fittingSize.width))")
                    expect(host.fittingSize.height <= 475.0, "去掉底部常驻提示与退出栏后设置卡片高度应更紧凑 (actual=\(host.fittingSize.height))")
                }
            }
        }
    }

    static func testRecentUIChangesEnglishLocalizationAndTelemetryLabel() {
        expectEqual(L10n.t(.telemetryAgentsLabel, .zhHans), "Agent", "实时监控首列标题应去掉冗余的“运行”，直接显示 Agent")
        expectEqual(L10n.t(.telemetryAgentsLabel, .en), "Agents", "英文模式实时监控首列标题应为 Agents")
        expectEqual(L10n.telemetryAgentCount(2, .zhHans), "2 运行", "中文数值行应保留运行态提示")
        expectEqual(L10n.telemetryAgentCount(0, .zhHans), "0 待命", "中文空闲数值行应显示 0 待命")
        expectEqual(L10n.telemetryAgentCount(2, .en), "2 Running", "英文数值行应显示 2 Running")
        expectEqual(L10n.telemetryAgentCount(0, .en), "0 Idle", "英文空闲数值行应显示 0 Idle")

        let sub1 = SessionItem(uuid: "sub-en-1", parentConversationId: "p-en-1", agentName: "worker", isRunning: true, tps: 120.4)
        let sub2 = SessionItem(uuid: "sub-en-2", parentConversationId: "p-en-1", agentName: "verifier", isRunning: true, tps: 79.6)
        let pSingleRun = SessionItem(uuid: "p-en-1", isRunning: false, subagents: [sub1], subagentCount: 1, activeSubagentCount: 1, activeSubagentTps: 120.4)
        let pMultiRun = SessionItem(uuid: "p-en-2", isRunning: false, subagents: [sub1, sub2], subagentCount: 2, activeSubagentCount: 2, activeSubagentTps: 200.0)
        let pSingleIdle = SessionItem(uuid: "p-en-3", isRunning: false, subagents: [SessionItem(uuid: "sub-en-3", parentConversationId: "p-en-3", agentName: "worker", isRunning: false)], subagentCount: 1, activeSubagentCount: 0, activeSubagentTps: 0.0)
        let pMultiIdle = SessionItem(uuid: "p-en-4", isRunning: false, subagents: [SessionItem(uuid: "sub-en-4", parentConversationId: "p-en-4", agentName: "w1", isRunning: false), SessionItem(uuid: "sub-en-5", parentConversationId: "p-en-4", agentName: "w2", isRunning: false)], subagentCount: 2, activeSubagentCount: 0, activeSubagentTps: 0.0)

        expectEqual(SessionRowBadgePolicy.subagentBadgeText(for: pSingleRun, language: .en), "1 Agent · 120t/s", "英文单数子 Agent 运行徽章应使用单数 Agent")
        expectEqual(SessionRowBadgePolicy.subagentBadgeText(for: pMultiRun, language: .en), "2 Agents · 200t/s", "英文复数子 Agent 运行徽章应使用复数 Agents")
        expectEqual(SessionRowBadgePolicy.subagentBadgeText(for: pSingleIdle, language: .en), "1 Agent", "英文单数折叠子 Agent 徽章应使用单数 Agent")
        expectEqual(SessionRowBadgePolicy.subagentBadgeText(for: pMultiIdle, language: .en), "2 Agents", "英文复数折叠子 Agent 徽章应使用复数 Agents")

        let hoverSingle = L10n.telemetryHoverSummary(time: "17:02:10", agents: 1, tps: 88, cachePct: 91.5, deltaTokens: 1200, .en)
        let hoverMulti = L10n.telemetryHoverSummary(time: "17:02:10", agents: 3, tps: 297, cachePct: 79.3, deltaTokens: 2400, .en)
        expect(hoverSingle.contains("1 Agent ·") && !containsCJK(hoverSingle), "英文悬停摘要单数应为 1 Agent 且无中文: \(hoverSingle)")
        expect(hoverMulti.contains("3 Agents ·") && !containsCJK(hoverMulti), "英文悬停摘要复数应为 3 Agents 且无中文: \(hoverMulti)")
        expectEqual(L10n.visibleSessionsCountValue(1, .en), "1 row", "英文 1 条配置应为 1 row")
        expectEqual(L10n.visibleSessionsCountValue(5, .en), "5 rows", "英文多条配置应为 5 rows")
        expectEqual(L10n.localizeAgentLabel("未知会话", language: .en), "Unknown Session", "英文未知会话标签应本地化")
        expectEqual(L10n.t(.telemetrySectionTitle, .en), "LIVE", "英文实时监控卡片标题应为 LIVE")
        expectEqual(L10n.t(.telemetryTrackContextTitle, .en), "Context", "英文 Y 轴标题应为 Context")
        expect(!containsCJK(L10n.t(.splitResizeTooltip, .en)), "英文分割拖拽提示不得包含中文")

        let suiteName = "agyhub.tdd.i18n.recent.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        MainActor.assumeIsolated { () -> Void in
            let store = AGYHubStore(startMonitoring: false, userDefaults: defaults)
            store.isFetching = true
            store.updateAppLanguage(.en, userDefaults: defaults)
            expect(store.pendingMonitorRefetch, "后台正在拉取时切换语言必须登记 pendingMonitorRefetch，防止切语种后的首次拉取被静默丢弃")
            store.isFetching = false
            store.pendingMonitorRefetch = false

            let stats = TodayStats(
                totalTokens: 254_000_000,
                cacheTokens: 201_422_000,
                inputTokens: 40_000_000,
                outputTokens: 12_578_000,
                cachePct: 79.3,
                costUsd: 67.39,
                hasData: true,
                source: "test"
            )
            let header = DashboardHeaderBarView(
                stats: stats,
                hasAlert: false,
                isUsageOpen: false,
                isStandaloneWindow: false,
                lang: .en,
                refreshSpinCount: 0,
                onToggleUsage: {},
                onRefresh: {},
                onOpenStandalone: {},
                onClose: {}
            )
            let headerHost = NSHostingView(rootView: header.frame(width: 340))
            headerHost.layoutSubtreeIfNeeded()
            expect(headerHost.fittingSize.width <= 340.5, "英文顶部栏在 340pt 下不得横向溢出 (actual=\(headerHost.fittingSize.width))")
            expect(headerHost.fittingSize.height <= 46.0, "英文顶部栏不得折行变高 (actual=\(headerHost.fittingSize.height))")

            let telemetryView = LiveTelemetryOverviewCardView(
                samples: [
                    LiveTelemetrySample(
                        id: 1,
                        timestamp: Date(),
                        activeAgentCount: 2,
                        totalTps: 297,
                        totalTokensCumulative: 2_400_000,
                        deltaTokens: 120_000,
                        cachePct: 79.3,
                        isIdleCacheHold: false,
                        agentContexts: [AgentContextPoint(agentId: "r1", label: "主会话", contextTokens: 177_000, isRunning: true, tps: 162)]
                    )
                ],
                todayStats: stats
            )
            .environment(\.agyLanguage, .en)
            let telemetryHost = NSHostingView(rootView: telemetryView.frame(width: 340))
            telemetryHost.layoutSubtreeIfNeeded()
            expect(telemetryHost.fittingSize.width <= 340.5, "英文实时监控卡片在 340pt 下不得横向溢出 (actual=\(telemetryHost.fittingSize.width))")

            let settings = SettingsPopoverView(store: store, onClose: {})
                .environment(\.agyLanguage, .en)
            let settingsHost = NSHostingView(rootView: settings.frame(width: 280))
            settingsHost.layoutSubtreeIfNeeded()
            expect(settingsHost.fittingSize.width <= 280.5, "英文设置面板在最小宽度 280pt 下不得横向溢出 (actual=\(settingsHost.fittingSize.width))")
        }
    }

    static func testLiveTelemetryIdleGapBridgingAndHollowIdleTail() {
        let baseDate = Date(timeIntervalSince1970: 1700005000)
        func pt(_ id: String, _ label: String, _ ctx: Int, running: Bool, tps: Double, parent: String? = nil) -> AgentContextPoint {
            AgentContextPoint(agentId: id, label: label, contextTokens: ctx, isRunning: running, tps: tps, parentAgentId: parent)
        }
        func makeSample(_ id: Int, _ offset: TimeInterval, _ agents: [AgentContextPoint]) -> LiveTelemetrySample {
            LiveTelemetrySample(
                id: id,
                timestamp: baseDate.addingTimeInterval(offset),
                activeAgentCount: agents.filter(\.isRunning).count,
                totalTps: agents.reduce(0.0) { $0 + ($1.isRunning ? $1.tps : 0.0) },
                totalTokensCumulative: 1_000_000 + id * 10_000,
                deltaTokens: 10_000,
                cachePct: 97.5,
                isIdleCacheHold: false,
                agentContexts: agents
            )
        }

        let samples: [LiveTelemetrySample] = [
            makeSample(1, 0, [
                pt("sess-paused", "PausedRoot", 140_000, running: true, tps: 60),
                pt("sess-micro", "MicroRoot", 190_000, running: true, tps: 50),
                pt("sess-idle-tail", "IdleRoot", 288_000, running: true, tps: 40),
                pt("sess-parent-with-sub", "SubParent", 120_000, running: true, tps: 30)
            ]),
            makeSample(2, 4, [
                pt("sess-paused", "PausedRoot", 144_000, running: true, tps: 60),
                pt("sess-micro", "MicroRoot", 192_000, running: true, tps: 50),
                pt("sess-idle-tail", "IdleRoot", 288_000, running: false, tps: 0),
                pt("sub-finished", "worker_sub", 45_000, running: true, tps: 45, parent: "sess-parent-with-sub")
            ]),
            makeSample(3, 10, [
                pt("sess-micro", "MicroRoot", 195_000, running: true, tps: 50),
                pt("sess-parent-with-sub", "SubParent", 124_000, running: true, tps: 35)
            ]),
            makeSample(4, 18, [
                pt("sess-paused", "PausedRoot", 146_000, running: true, tps: 65),
                pt("sess-micro", "MicroRoot", 198_000, running: true, tps: 50),
                pt("sess-parent-with-sub", "SubParent", 128_000, running: true, tps: 35)
            ]),
            makeSample(5, 22, [
                pt("sess-paused", "PausedRoot", 150_000, running: true, tps: 65),
                pt("sess-micro", "MicroRoot", 201_000, running: true, tps: 50),
                pt("sess-parent-with-sub", "SubParent", 130_000, running: true, tps: 35)
            ])
        ]

        let seriesList = LiveTelemetryPolicy.agentSeries(in: samples)
        let seriesById = Dictionary(uniqueKeysWithValues: seriesList.map { ($0.agentId, $0) })
        let resolvedList = LiveTelemetryPolicy.resolvedCurveSegments(
            for: seriesList,
            windowSeconds: TelemetryTimeRange.threeMinutes.seconds
        )
        let resolvedById = Dictionary(uniqueKeysWithValues: resolvedList.map { ($0.agentId, $0) })

        guard let pausedSeries = seriesById["sess-paused"],
              let pausedResolved = resolvedById["sess-paused"] else {
            expect(false, "sess-paused 应生成曲线序列")
            return
        }
        expectEqual(pausedSeries.segments.count, 1, "无子分支交替的长停顿不得打断父/独立曲线，必须连成连续整段")
        let pausedRuns = pausedResolved.segments.first?.strokeRuns ?? []
        expect(pausedRuns.contains(where: { $0.isIdle }), "超过 8s 阈值的停顿区间必须标注为虚线空闲过渡 run (runs=\(pausedRuns.count))")
        expect(pausedRuns.contains(where: { !$0.isIdle }), "恢复生成后的区间必须保持实线激活 run")
        if pausedRuns.count >= 2 {
            for i in 1..<pausedRuns.count {
                expectEqual(pausedRuns[i].points.first?.timestamp, pausedRuns[i - 1].points.last?.timestamp, "实线与虚线分段首尾必须无缝重合")
            }
        }

        if let microRuns = resolvedById["sess-micro"]?.segments.first?.strokeRuns {
            expect(microRuns.allSatisfy { !$0.isIdle }, "不超过 8s 的短回合停顿应直接平滑为连续实线，避免碎虚线")
        } else {
            expect(false, "sess-micro 应产出有效 strokeRuns")
        }

        guard let idleTailSeries = seriesById["sess-idle-tail"],
              let idleTailResolved = resolvedById["sess-idle-tail"] else {
            expect(false, "窗口内曾激活而后转入空闲的根会话必须保留显示")
            return
        }
        expect(!idleTailSeries.isRunning, "当前已停机的历史根会话 isRunning 必须为 false 以触发空心圆圈与虚线尾巴")
        expectEqual(idleTailSeries.points.last?.timestamp, baseDate.addingTimeInterval(22), "窗口内激活过的根会话停止后应以水平虚线无缝延伸至当前最新采样点")
        expect(idleTailResolved.segments.last?.strokeRuns.last?.isIdle == true, "已停机会话延伸到右侧的尾巴必须标记为虚线空闲 run")

        if let subSeries = seriesById["sub-finished"] {
            expect(subSeries.points.last!.timestamp < baseDate.addingTimeInterval(22), "已结束的子 Agent 不得额外拖出虚线尾巴穿到父会话恢复区")
        }
        if let subParentSeries = seriesById["sess-parent-with-sub"] {
            expectEqual(subParentSeries.segments.count, 2, "因等待运行中子 Agent 产生的分叉让位仍须保持 2 段不穿底")
        }
        expect(LiveTelemetryOverviewCardView.drawsHollowEndpointForIdleSeries, "未激活历史曲线末端应使用空心圆环标记")
    }

    static func testTelemetryDefaultHidesHorizontalGuideRulesAndOffsetsCalloutFromDot() {
        let now = Date(timeIntervalSince1970: 1700006000)
        let seg = AgentCurveSegment(
            id: "seg",
            isForkSegment: false,
            points: [AgentSeriesSamplePoint(timestamp: now, contextTokens: 231_000, isRunning: true, tps: 90)]
        )
        let s1 = AgentContextSeries(
            agentId: "s-1",
            label: "One",
            isRunning: true,
            latestContextTokens: 231_000,
            latestTps: 90,
            colorIndex: 0,
            segments: [seg]
        )
        let s2 = AgentContextSeries(
            agentId: "s-2",
            label: "Two",
            isRunning: true,
            latestContextTokens: 228_000,
            latestTps: 85,
            colorIndex: 1,
            segments: [seg]
        )

        let defaultGuides = LiveTelemetryChartAxisPolicy.horizontalGuideIndices(
            seriesList: [s1, s2],
            focusedSeriesIds: []
        )
        expectEqual(defaultGuides, [], "未悬停/未高亮时不得绘制横穿全图的水平参考虚线，避免与空闲曲线虚线混淆并污染左侧空白")

        let hoverSingleGuides = LiveTelemetryChartAxisPolicy.horizontalGuideIndices(
            seriesList: [s1, s2],
            focusedSeriesIds: ["s-2"]
        )
        expectEqual(hoverSingleGuides, [1], "悬停或聚焦到 s-2 时应展示 s-2 对应的单根水平参考线")

        let hoverMultiGuides = LiveTelemetryChartAxisPolicy.horizontalGuideIndices(
            seriesList: [s1, s2],
            focusedSeriesIds: ["s-1", "s-2"]
        )
        expectEqual(hoverMultiGuides.count, 1, "悬停整个多子 Agent 会话时最多只绘制 1 根辅助读数线，避免双线叠成铁轨")

        let plotRect = CGRect(x: 40, y: 10, width: 380, height: 140)
        let calloutAtQuarter = LiveTelemetryChartAxisPolicy.calloutCenterX(
            forReferenceX: plotRect.minX + plotRect.width * 0.25,
            in: plotRect
        )
        expect(calloutAtQuarter - (plotRect.minX + plotRect.width * 0.25) >= 22.0, "处于 1/4 位置时胶囊应在当前圆点右侧空白区")
        let calloutAtRightEdge = LiveTelemetryChartAxisPolicy.calloutCenterX(
            forReferenceX: plotRect.maxX - 4.0,
            in: plotRect
        )
        expect((plotRect.maxX - 4.0) - calloutAtRightEdge >= 22.0, "临近 100% 右边界时胶囊应自动向左避让圆点，不能挤出或压住圆点")
    }

    static func testOneQuarterAdvancingTimelineCycleAndAdaptiveCallout() {
        let anchor = Date(timeIntervalSince1970: 1700008000)

        let d0 = LiveTelemetryPolicy.xAxisDomain(for: .threeMinutes, referenceDate: anchor, anchorDate: anchor)
        expectEqual(Int(d0.upperBound.timeIntervalSince(d0.lowerBound).rounded()), 180, "3m 窗口总跨度必须为 180s")
        expectEqual(Int(anchor.timeIntervalSince(d0.lowerBound).rounded()), 45, "初始时刻应位于整段宽度的前 1/4 处 (now - lowerBound = 45s)")
        expectEqual(Int(d0.upperBound.timeIntervalSince(anchor).rounded()), 135, "右侧前瞻区间应占 3/4 (135s)")

        let t67 = anchor.addingTimeInterval(67.5)
        let d67 = LiveTelemetryPolicy.xAxisDomain(for: .threeMinutes, referenceDate: t67, anchorDate: anchor)
        expectEqual(d67.lowerBound, d0.lowerBound, "前 135s 生长期间左边界必须锚定不动，曲线自然向右生长")
        expectEqual(Int(t67.timeIntervalSince(d67.lowerBound).rounded()), 113, "经过 67.5s 后，曲线应生长到 112.5/180 处")

        let t134 = anchor.addingTimeInterval(134)
        let d134 = LiveTelemetryPolicy.xAxisDomain(for: .threeMinutes, referenceDate: t134, anchorDate: anchor)
        expectEqual(d134.lowerBound, d0.lowerBound, "尚未抵达 100% 右边界时不得提前翻页")

        let t135 = anchor.addingTimeInterval(135)
        let d135 = LiveTelemetryPolicy.xAxisDomain(for: .threeMinutes, referenceDate: t135, anchorDate: anchor)
        expectEqual(Int(t135.timeIntervalSince(d135.lowerBound).rounded()), 45, "抵达右边界 100% 时必须平滑回落到前 1/4 位置继续向前生长")
        expectEqual(Int(d135.upperBound.timeIntervalSince(t135).rounded()), 135, "翻页后右方保留 3/4 生长空间")

        let ticks0 = LiveTelemetryPolicy.xAxisTicks(for: .threeMinutes, referenceDate: anchor, anchorDate: anchor, count: 5)
        expectEqual(ticks0.count, 5, "4 等分时间轴应产出 5 个刻度点 (0, 1/4, 2/4, 3/4, 1)")
        expectEqual(ticks0[1], anchor, "第 2 个刻度线 (1/4 处) 在重置时刻应精确对齐当前时刻")

        let tooOldAtReset = LiveTelemetrySample(
            id: 1,
            timestamp: t135.addingTimeInterval(-70),
            activeAgentCount: 1,
            totalTps: 50,
            totalTokensCumulative: 1000,
            deltaTokens: 100,
            cachePct: 95,
            isIdleCacheHold: false
        )
        let keptLeftQuarter = LiveTelemetrySample(
            id: 2,
            timestamp: t135.addingTimeInterval(-20),
            activeAgentCount: 1,
            totalTps: 60,
            totalTokensCumulative: 1200,
            deltaTokens: 200,
            cachePct: 96,
            isIdleCacheHold: false
        )
        let visible = LiveTelemetryPolicy.visibleChartSamples(
            in: .threeMinutes,
            from: [tooOldAtReset, keptLeftQuarter],
            anchorDate: anchor,
            now: t135
        )
        expectEqual(visible.map(\.id), [2], "回落到 1/4 时左侧保留最新 1/4 (45s) 历史，早于左边界的采样不得刺穿 Y 轴")
        let fullWindowSamples = LiveTelemetryPolicy.samples(in: .threeMinutes, from: [tooOldAtReset, keptLeftQuarter], now: t135)
        expectEqual(fullWindowSamples.map(\.id), [1, 2], "KPI 累计窗口统计仍保留完整 3m(180s) 口径")

        expect(LiveTelemetryOverviewCardView.usesOneQuarterGrowingTimelinePage, "实时图表应启用从 1/4 向前生长至最右端后回落 1/4 的分页模式")
    }
}
