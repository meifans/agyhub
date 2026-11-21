//
//  Views.swift
//  Agyhub — SwiftUI 视图组件层与品牌矢量图标
//

import AppKit
import Charts
import SwiftUI

// MARK: - 4.1 精致原生交互按钮样式 (Native macOS Button Styles)

struct ModernPrimaryButtonStyle: ButtonStyle {
    var isAccent: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isAccent ? Color.accentColor : Color.primary.opacity(0.08))
            )
            .foregroundColor(isAccent ? .white : .primary)
            .opacity(configuration.isPressed ? 0.82 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct ModernSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.10 : 0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.primary.opacity(0.14), lineWidth: 0.8)
            )
            .foregroundColor(.primary)
            .opacity(configuration.isPressed ? 0.82 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

enum AccountTargetMode: String, CaseIterable {
    case app = "App"
    case cli = "CLI"
}

private struct ImpeccableIconButtonStyle: ButtonStyle {
    let size: CGFloat
    let isHovered: Bool
    let tint: Color
    let hoverTint: Color
    let hoverFill: Color

    func makeBody(configuration: Configuration) -> some View {
        let active = isHovered || configuration.isPressed
        let fillColor: Color = configuration.isPressed
            ? hoverTint.opacity(0.18)
            : (isHovered ? hoverFill : Color.primary.opacity(0.001))

        configuration.label
            .foregroundColor(active ? hoverTint : tint)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(fillColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(hoverTint.opacity(isHovered ? 0.16 : 0.0), lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.88 : (isHovered ? 1.04 : 1.0))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .animation(.easeOut(duration: 0.09), value: configuration.isPressed)
    }
}

/// /impeccable 工具栏微交互图标按钮（显式命中层防止透明穿透，带悬停背景、按压缩放与手型光标）
struct ImpeccableIconButton: View {
    let icon: String
    let tooltip: String
    var tint: Color = .secondary
    var hoverTint: Color = .primary
    var hoverFill: Color = Color.primary.opacity(0.09)
    var size: CGFloat = 24
    var iconSize: CGFloat = 11
    var spinTrigger: Int = 0
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .rotationEffect(.degrees(Double(spinTrigger) * 360.0))
                .animation(.easeOut(duration: 0.42), value: spinTrigger)
        }
        .buttonStyle(ImpeccableIconButtonStyle(
            size: size,
            isHovered: isHovered,
            tint: tint,
            hoverTint: hoverTint,
            hoverFill: hoverFill
        ))
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovered = hovering
            }
            if hovering {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
        .help(tooltip)
    }
}

private struct ImpeccablePillButtonStyle: ButtonStyle {
    var baseFill: Color
    var hoverFill: Color
    var foreground: Color
    var isHovered: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(configuration.isPressed ? hoverFill.opacity(1.25) : (isHovered ? hoverFill : baseFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(foreground.opacity(isHovered ? 0.22 : 0.0), lineWidth: 0.5)
            )
            .foregroundColor(foreground)
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .contentShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .animation(.easeOut(duration: 0.10), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.12), value: isHovered)
    }
}

/// /impeccable 实体微交互动作按钮（带悬停渐变色、边框微光、按压回弹与手型光标）
struct ImpeccableActionButton: View {
    let title: String
    var icon: String? = nil
    var baseFill: Color
    var hoverFill: Color
    var tint: Color
    var hoverTint: Color
    var cornerRadius: CGFloat = 4.5
    var horizontalPadding: CGFloat = 7
    var verticalPadding: CGFloat = 3
    var fontSize: CGFloat = 9.5
    var fontWeight: Font.Weight = .semibold
    var tooltip: String? = nil
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3.5) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: fontSize - 0.5, weight: .bold))
                }
                Text(title)
                    .font(.system(size: fontSize, weight: fontWeight))
            }
        }
        .buttonStyle(ImpeccableActionButtonStyle(
            isHovered: isHovered,
            baseFill: baseFill,
            hoverFill: hoverFill,
            tint: tint,
            hoverTint: hoverTint,
            cornerRadius: cornerRadius,
            horizontalPadding: horizontalPadding,
            verticalPadding: verticalPadding
        ))
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovered = hovering
            }
            if hovering {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
        .help(tooltip ?? title)
    }
}

private struct ImpeccableActionButtonStyle: ButtonStyle {
    let isHovered: Bool
    let baseFill: Color
    let hoverFill: Color
    let tint: Color
    let hoverTint: Color
    let cornerRadius: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        let active = isHovered || configuration.isPressed
        let bg = configuration.isPressed
            ? hoverFill.opacity(1.25)
            : (isHovered ? hoverFill : baseFill)
        let fg = active ? hoverTint : tint

        configuration.label
            .foregroundColor(fg)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(bg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(fg.opacity(isHovered ? 0.28 : 0.0), lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.92 : (isHovered ? 1.02 : 1.0))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .animation(.easeOut(duration: 0.09), value: configuration.isPressed)
    }
}

/// /impeccable 刷新间隔微交互胶囊按钮
struct ImpeccableIntervalPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 9.5, weight: isSelected ? .bold : .medium, design: .monospaced))
        }
        .buttonStyle(ImpeccablePillButtonStyle(
            baseFill: isSelected ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.04),
            hoverFill: isSelected ? Color.accentColor.opacity(0.28) : Color.primary.opacity(0.10),
            foreground: isSelected ? Color.accentColor : (isHovered ? .primary : .secondary),
            isHovered: isHovered
        ))
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovered = hovering
            }
            if hovering {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
    }
}

struct SectionCollapseToggleButton: View {
    let title: String
    let isCollapsed: Bool
    let action: () -> Void
    @Environment(\.agyLanguage) private var lang
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9.5, weight: .bold))
                    .rotationEffect(.degrees(isCollapsed ? 0 : 90))
                    .foregroundColor(isHovered ? .primary : Color.primary.opacity(0.75))
                    .animation(.easeOut(duration: 0.18), value: isCollapsed)

                Text(title)
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(isHovered ? .primary : Color.primary.opacity(0.75))
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(isHovered ? Color.primary.opacity(0.06) : Color.primary.opacity(0.001))
            )
            .contentShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovered = hovering
            }
            if hovering {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
        .help(L10n.collapseToggleHelp(title: title, isCollapsed: isCollapsed, lang))
    }
}

// MARK: - 5. UI 视图组件层 (Native macOS HIG & Distilled Minimalist Design)

/// 主面板与可拖拽窗口共用的全出血毛玻璃外壳修饰器（确保背景、圆角裁切与边框同样 ignoresSafeArea，不被顶部 32pt 标题栏安全区截掉 headerBar）
enum MainDashboardWindowChrome {
    @ViewBuilder
    static func apply<Content: View>(to content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(WindowLifecycleConfigurator())
            .background(
                ZStack {
                    // 原生 macOS 晶莹毛玻璃材质底板 (遵循 z-apple-design 规范)
                    VisualEffectBlurView(material: .hudWindow, blendingMode: .behindWindow)

                    // 纯净高对比度底衬 (不透明度 0.90)，彻底杜绝外部杂乱窗口与米黄网页透光发脏发暗
                    Color(nsColor: .windowBackgroundColor).opacity(0.90)

                    // 极微弱漫反射高光层
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white.opacity(0.06), Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            )
            .overlay(alignment: .bottomTrailing) {
                ResizeCornerGripView()
            }
            .overlay(WindowResizeOverlay())
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                // Apple 发丝级外边框，完美贴合系统微阴影
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(0.40), lineWidth: 0.75)
            )
            .ignoresSafeArea()
    }
}

struct MainDashboardView: View {
    @ObservedObject var store: AGYHubStore
    var isStandaloneWindow: Bool = false

    @AppStorage("agyhub.collapse.accounts") private var isAccountsCollapsed = false
    @AppStorage("agyhub.collapse.sessions") private var isSessionsCollapsed = false
    @State private var accountTargetMode: AccountTargetMode = .app
    @State private var refreshSpinCount: Int = 0

    @State private var showCreateProfileSheet = false
    @State private var showSettingsPopover = false
    @State private var showLogsSheet = false
    @State private var isTodayPillHovered = false
    @State private var newProfileName = ""
    @State private var newProfileNotes = ""
    @State private var newProfileDataDir = ""

    private var lang: AppLanguage.Resolved {
        store.resolvedLanguage
    }

    var body: some View {
        MainDashboardWindowChrome.apply(to:
        VStack(spacing: 0) {
            // 极简顶部工具栏（整合 Today 核心指标与拖动区）
            headerBar

            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 0.5)

            // 临时状态通知条
            if let banner = store.statusBannerMessage {
                HStack(spacing: 6) {
                    Text(banner)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color.accentColor)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if store.isUsageDashboardPresented {
                UsageAnalyticsView(
                    store: store,
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            store.closeUsageDashboard()
                        }
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .transition(.opacity)
            } else {
                VStack(spacing: 10) {
                    // 区域一：账号隔离环境
                    profileManagerSection

                    Rectangle()
                        .fill(Color(nsColor: .separatorColor).opacity(0.35))
                        .frame(height: 0.5)
                        .padding(.horizontal, 2)

                    // 区域二：活跃会话列表或会话详情（Today 已精炼整合至顶部标题行）
                    if let session = store.activeSelectedSession {
                        SessionDetailCardView(
                            session: session,
                            diagnostics: store.sessionDiagnosticsByUUID[session.uuid],
                            isLoadingDiagnostics: store.isLoadingDiagnosticsUUID == session.uuid,
                            onBack: { store.popSessionDetail() },
                            onRefreshDiagnostics: {
                                store.fetchSessionDiagnostics(uuid: session.uuid, force: true)
                            },
                            onSelectSubagent: { subUUID in
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    store.drillDownToSession(subUUID)
                                }
                            }
                        )
                        .id(session.uuid)
                        .task(id: session.uuid) {
                            store.fetchSessionDiagnostics(uuid: session.uuid, force: false)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    } else {
                        activeSessionsSection
                        if isSessionsCollapsed {
                            Spacer(minLength: 0)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }

            Rectangle()
                .fill(Color(nsColor: .separatorColor).opacity(0.35))
                .frame(height: 0.5)

            // 极简底部工具栏
            footerBar
        }
        )
        .environment(\.agyLanguage, lang)
        .onAppear {
            if !NSApp.isActive {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        .sheet(isPresented: $showCreateProfileSheet) {
            createProfileSheetView
                .environment(\.agyLanguage, lang)
        }
        .sheet(isPresented: $showLogsSheet) {
            discoveryLogsSheetView
                .environment(\.agyLanguage, lang)
        }
        .sheet(isPresented: $showSettingsPopover) {
            SettingsPopoverView(store: store, onClose: {
                showSettingsPopover = false
            })
            .environment(\.agyLanguage, lang)
        }
    }

    /// 弹窗左上角品牌小图标：优先展示透明无背景的方案 3 紧裁猫头，无 Bundle 环境回退同源矢量小猫
    private struct HakimiHeaderLogoView: View {
        var body: some View {
            if let catURL = Bundle.main.url(forResource: "header-cat", withExtension: "png"),
               let catImg = NSImage(contentsOf: catURL) {
                Image(nsImage: catImg)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
            } else {
                Image(nsImage: AGYAppDelegate.HakimiBrandIcon.menuBarImage(state: .working))
                    .resizable()
                    .frame(width: 18, height: 18)
            }
        }
    }

    // MARK: - 顶部工具栏 (Header Bar - 集成精简 Today 指标与拖拽区)
    private var headerBar: some View {
        HStack(spacing: 8) {
            // 左侧标题及灵动指示灯
            HStack(spacing: 6) {
                HakimiHeaderLogoView()
                Text("Agyhub")
                    .font(.system(size: 14.5, weight: .bold))

                Circle()
                    .fill(store.payload.hasAlert ? Color.red : Color.green)
                    .frame(width: 6, height: 6)
                    .shadow(color: (store.payload.hasAlert ? Color.red : Color.green).opacity(0.55), radius: 2.5)
            }

            // 中间弹性区域：承载可点击展开的精简 Today 数据指标，两侧留白保持原生窗口拖动区
            HStack(spacing: 0) {
                Spacer(minLength: 4)

                let stats = store.payload.todayStats
                let isOpen = store.isUsageDashboardPresented
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        store.toggleUsageDashboard()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(isOpen ? Color.accentColor : .secondary.opacity(0.75))

                        Text(L10n.t(.headerTodayLabel, lang))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(isOpen ? Color.accentColor : .secondary.opacity(0.80))

                        Text(Formatters.formatCost(stats.costUsd))
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("·")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary.opacity(0.40))

                        Text(Formatters.formatTokens(stats.totalTokens))
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.90))

                        Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(isOpen ? Color.accentColor : .secondary.opacity(0.60))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(
                                isOpen
                                    ? Color.accentColor.opacity(0.12)
                                    : Color.primary.opacity(isTodayPillHovered ? 0.085 : 0.04)
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        isOpen
                                            ? Color.accentColor.opacity(0.32)
                                            : Color.primary.opacity(isTodayPillHovered ? 0.14 : 0.06),
                                        lineWidth: 0.6
                                    )
                            )
                    )
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isTodayPillHovered = hovering
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .help(L10n.todayPillTooltip(cost: stats.costUsd, totalTokens: stats.totalTokens, cachePct: stats.cachePct, lang))

                Spacer(minLength: 4)
            }
            .contentShape(Rectangle())
            .background(WindowDragArea())

            // 立即刷新
            ImpeccableIconButton(
                icon: "arrow.clockwise",
                tooltip: L10n.t(.refreshDataTooltip, lang),
                size: 26,
                iconSize: 12,
                spinTrigger: refreshSpinCount
            ) {
                refreshSpinCount += 1
                store.fetchMonitorData()
                store.refreshQuotasIfNeeded(force: true)
                store.refreshRecent503IfNeeded(force: true)
                if store.isUsageDashboardPresented {
                    store.fetchUsageHistory(force: true)
                }
            }

            // 独立主窗口
            if !isStandaloneWindow {
                ImpeccableIconButton(
                    icon: "macwindow.on.rectangle",
                    tooltip: L10n.t(.openStandaloneTooltip, lang),
                    size: 26,
                    iconSize: 12
                ) {
                    AGYAppDelegate.shared?.openStandaloneWindow()
                }
            }

            // 右上角关闭当前窗口叉号（只关窗隐藏，不退出常驻菜单栏进程）
            ImpeccableIconButton(
                icon: "xmark",
                tooltip: WindowClosePolicy.headerCloseTooltip(language: lang),
                hoverTint: .red,
                hoverFill: Color.red.opacity(0.12),
                size: 26,
                iconSize: 12
            ) {
                if let delegate = AGYAppDelegate.shared {
                    delegate.closeWindow(isStandaloneWindow: isStandaloneWindow)
                } else {
                    NSApp.keyWindow?.orderOut(nil)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
    }

    // MARK: - 账号环境列表 (Profile Manager)
    private var profileManagerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                SectionCollapseToggleButton(title: L10n.t(.accountsSectionTitle, lang), isCollapsed: isAccountsCollapsed) {
                    withAnimation(.easeOut(duration: 0.18)) {
                        isAccountsCollapsed.toggle()
                    }
                }

                // 折叠时仅展示简洁单行摘要（App / CLI 当前实际共享槽位状态）
                if isAccountsCollapsed {
                    let effectiveApp = store.sharedKeychainResolution.email ?? store.activeProfileName
                    let appLabel = effectiveApp.split(separator: "@").first.map(String.init) ?? "-"
                    let cliLabel = store.activeCLIProfileName?.split(separator: "@").first.map(String.init) ?? L10n.t(.notSignedIn, lang)
                    Text("App \(appLabel) · CLI \(cliLabel)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(store.hasSharedKeychainMismatch ? .orange : Color.primary.opacity(0.70))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer(minLength: 4)

                // App / CLI 目标端切换胶囊（仅在启用 CLI 独立模式时呈现；关闭时切一个相当于同时切，仅保留常规视图）
                if !isAccountsCollapsed && store.isCLIIndependentMode {
                    HStack(spacing: 2) {
                        ForEach(AccountTargetMode.allCases, id: \.self) { mode in
                            let isActiveMode = (accountTargetMode == mode)
                            Button(action: {
                                withAnimation(.easeOut(duration: 0.14)) {
                                    accountTargetMode = mode
                                }
                            }) {
                                HStack(spacing: 3) {
                                    if mode == .cli {
                                        Image(systemName: "terminal")
                                            .font(.system(size: 9))
                                    }
                                    Text(mode.rawValue)
                                        .font(.system(size: 11, weight: isActiveMode ? .bold : .medium))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(isActiveMode ? Color(nsColor: .controlBackgroundColor) : Color.clear)
                                        .shadow(color: isActiveMode ? Color.black.opacity(0.08) : Color.clear, radius: 1, y: 0.5)
                                )
                                .foregroundColor(isActiveMode ? .primary : Color.primary.opacity(0.70))
                                .contentShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .help(mode == .app ? L10n.t(.switchDesktopAppTooltip, lang) : L10n.t(.switchCLIAccountTooltip, lang))
                        }
                    }
                    .padding(2)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                    )
                }

                if !isAccountsCollapsed {
                    ImpeccableIconButton(
                        icon: "doc.text.magnifyingglass",
                        tooltip: L10n.t(.viewLogsTooltip, lang),
                        size: 22,
                        iconSize: 11
                    ) {
                        showLogsSheet = true
                    }

                    ImpeccableIconButton(
                        icon: "plus",
                        tooltip: L10n.t(.newProfileTooltip, lang),
                        tint: Color.accentColor,
                        hoverTint: Color.accentColor,
                        hoverFill: Color.accentColor.opacity(0.12),
                        size: 22,
                        iconSize: 11.5
                    ) {
                        newProfileName = ""
                        newProfileNotes = ""
                        newProfileDataDir = ""
                        showCreateProfileSheet = true
                    }
                }
            }
            .padding(.horizontal, 2)

            if !isAccountsCollapsed {
                if store.hasSharedKeychainMismatch,
                   let actualEmail = store.sharedKeychainResolution.email {
                    let expectedEmail = store.resolvedExpectedAppEmail
                    let appShort = String(expectedEmail.split(separator: "@").first ?? Substring(expectedEmail))
                    let actualShort = String(actualEmail.split(separator: "@").first ?? Substring(actualEmail))
                    let sourceHint = L10n.keychainDriftHint(
                        isRefreshHijack: store.sharedKeychainResolution.isTokenRefreshHijack,
                        actualShort: actualShort,
                        lang
                    )
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(L10n.primaryAppDriftLine(appShort: appShort, hint: sourceHint, lang))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                            if store.backgroundCLIProcessCount > 0 {
                                Text(L10n.backgroundCLIWarning(store.backgroundCLIProcessCount, lang))
                                    .font(.system(size: 8.5))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        Spacer(minLength: 4)
                        ImpeccableActionButton(
                            title: L10n.switchBackTo(appShort, lang),
                            icon: "arrow.uturn.backward",
                            baseFill: Color.orange.opacity(0.16),
                            hoverFill: Color.orange.opacity(0.28),
                            tint: .orange,
                            hoverTint: .orange,
                            cornerRadius: 4,
                            horizontalPadding: 7,
                            verticalPadding: 3,
                            fontSize: 9.5,
                            fontWeight: .semibold,
                            tooltip: L10n.restoreKeychainTooltip(expectedEmail, lang)
                        ) {
                            store.restoreAppKeychainAccount()
                        }
                    }
                    .padding(7)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.orange.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.orange.opacity(0.25), lineWidth: 0.6)
                    )
                }

                if store.isCLIIndependentMode && accountTargetMode == .cli && !store.isCLIVaultAuthorized {
                    HStack(spacing: 8) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.purple)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(L10n.t(.authorizeCLIAutoSwitchTitle, lang))
                                .font(.system(size: 10.5, weight: .semibold))
                            Text(L10n.t(.authorizeCLIAutoSwitchDesc, lang))
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 4)
                        Button(action: { store.authorizeCLIVault() }) {
                            Text(L10n.t(.authorizeOnceButton, lang))
                                .font(.system(size: 9.5, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3.5)
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(7)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.purple.opacity(0.07))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.purple.opacity(0.18), lineWidth: 0.6)
                    )
                } else if store.isCLIIndependentMode && accountTargetMode == .cli {
                    HStack(spacing: 5) {
                        Image(systemName: store.isCLITokenFileReady ? "info.circle" : "exclamationmark.triangle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(store.isCLITokenFileReady ? .purple.opacity(0.85) : .orange)
                        Text(
                            !store.isCLITokenFileReady
                                ? L10n.t(.cliTokenMissingOrCorrupt, lang)
                                : (store.backgroundCLIProcessCount > 0
                                    ? L10n.cliTokenRunningWarning(store.backgroundCLIProcessCount, lang)
                                    : L10n.t(.cliTokenIsolatedHint, lang))
                        )
                            .font(.system(size: 8.5))
                            .foregroundColor(store.isCLITokenFileReady ? .secondary : .orange)
                            .lineLimit(1)
                            .help(L10n.t(.cliTokenHelpTooltip, lang))
                        Spacer()
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(CLIAccountManager.fileTokenModeEnv, forType: .string)
                            store.showBanner(L10n.copiedEnvBanner(CLIAccountManager.fileTokenModeEnv, lang))
                        }) {
                            Text(L10n.t(.copyEnvButton, lang))
                                .font(.system(size: 8.5, weight: .semibold))
                                .foregroundColor(.purple)
                        }
                        .buttonStyle(.plain)
                        .help(L10n.copyEnvHelp(CLIAccountManager.fileTokenModeEnv, lang))
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                }

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 2) {
                        let effectiveTargetMode = store.isCLIIndependentMode ? accountTargetMode : .app
                        let effectiveAppEmail = AccountDisplayPolicy.effectiveRunningAppEmail(
                            expectedAppEmail: store.expectedAppEmail,
                            appStorageEmail: store.appStorageEmail,
                            sharedKeychainEmail: store.sharedKeychainResolution.email,
                            activeProfileName: store.activeProfileName
                        ).lowercased()
                        let isAppResolved = !store.expectedAppEmail.isEmpty
                            || !store.appStorageEmail.isEmpty
                            || store.sharedKeychainResolution.email != nil
                        let authenticatedEmails = store.savedCLISlots.union(
                            store.accountQuotas.keys.filter { $0.contains("@") }
                        )
                        let sortedProfiles = AccountSortOrder.sortedProfiles(
                            store.profiles,
                            mode: effectiveTargetMode,
                            effectiveAppEmail: effectiveAppEmail,
                            activeProfileName: store.activeProfileName,
                            activeCLIProfileName: store.activeCLIProfileName,
                            isSharedKeychainResolved: isAppResolved,
                            authenticatedEmails: authenticatedEmails
                        )
                        ForEach(sortedProfiles) { profile in
                            let emailKey = (profile.email ?? profile.name).lowercased()
                            let isAppActive = (emailKey == effectiveAppEmail) || (!isAppResolved && profile.name == store.activeProfileName)
                            let isCLIActive = (store.activeCLIProfileName?.lowercased() == emailKey)
                            let hasCLISlot = isCLIActive || store.savedCLISlots.contains(emailKey)
                            CompactProfileRowView(
                                profile: profile,
                                mode: effectiveTargetMode,
                                isAppActive: isAppActive,
                                isCLIActive: isCLIActive,
                                isCLIVaultAuthorized: store.isCLIVaultAuthorized,
                                isCLIIndependentMode: store.isCLIIndependentMode,
                                hasCLISlot: hasCLISlot,
                                accountQuota: store.accountQuotas[emailKey],
                                isQuotaTokenExpired: store.expiredQuotaEmails.contains(emailKey),
                                onSwitchApp: { store.switchToProfile(profile) },
                                onParallelApp: { store.launchParallelProfile(profile) },
                                onSwitchCLI: { store.switchCLIProfile(profile) },
                                onDelete: { store.deleteProfile(profile) }
                            )
                        }
                    }
                }
                .frame(maxHeight: 138)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - 今日大盘概览 (Today's Overview)
    private var todayOverviewSection: some View {
        let stats = store.payload.todayStats
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(L10n.t(.todaySectionTitle, lang))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 2)

            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(Formatters.formatCost(stats.costUsd))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text(L10n.t(.estimatedCost, lang))
                        .font(.system(size: 10.5))
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 3) {
                        Text(Formatters.formatTokens(stats.totalTokens))
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(.primary)
                        Text("Tokens")
                            .font(.system(size: 10.5))
                            .foregroundColor(.secondary)
                    }
                    Text(L10n.todayOverviewCacheLine(cachePct: stats.cachePct, newTokens: stats.inputTokens + stats.outputTokens, lang))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(0.035))
            )
        }
    }

    // MARK: - 活跃会话实时列表 (Active Sessions)
    private var activeSessionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                SectionCollapseToggleButton(title: L10n.t(.sessionsSectionTitle, lang), isCollapsed: isSessionsCollapsed) {
                    withAnimation(.easeOut(duration: 0.18)) {
                        isSessionsCollapsed.toggle()
                    }
                }

                if store.payload.activeCount > 0 {
                    HStack(spacing: 3.5) {
                        Circle()
                            .fill(Color(nsColor: .systemGreen))
                            .frame(width: 5.5, height: 5.5)
                        Text(L10n.activeCount(store.payload.activeCount, lang))
                            .font(.system(size: 10.5, weight: .bold))
                    }
                    .foregroundColor(Color(red: 0.08, green: 0.52, blue: 0.22))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Color.green.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                            .strokeBorder(Color.green.opacity(0.25), lineWidth: 0.5)
                    )
                    .cornerRadius(3.5)
                    .fixedSize()
                }

                // 需求 4：session 旁边实时显示单次最长等待耗时 tag (高对比度 WCAG AA 规范)
                let maxStall = store.maxSessionStallSeconds
                if maxStall > 0 || store.payload.activeCount > 0 {
                    let stallText = (maxStall < 1.0 && maxStall > 0) ? "<1s" : "\(Int(maxStall))s"
                    let isWarning = maxStall >= 30.0
                    let isCaution = maxStall >= 10.0 && maxStall < 30.0
                    let textColor: Color = isWarning
                        ? Color.red
                        : (isCaution ? Color(red: 0.85, green: 0.35, blue: 0.0) : Color.primary.opacity(0.75))
                    let bgColor: Color = isWarning
                        ? Color.red.opacity(0.10)
                        : (isCaution ? Color.orange.opacity(0.12) : Color.primary.opacity(0.05))
                    let borderColor: Color = isWarning
                        ? Color.red.opacity(0.35)
                        : (isCaution ? Color.orange.opacity(0.35) : Color.primary.opacity(0.12))

                    HStack(spacing: 3.5) {
                        Image(systemName: isWarning ? "exclamationmark.triangle.fill" : "hourglass")
                            .font(.system(size: 9, weight: .medium))
                        Text(L10n.maxWait(stallText, lang))
                            .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                    }
                    .foregroundColor(textColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(bgColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                            .strokeBorder(borderColor, lineWidth: 0.5)
                    )
                    .cornerRadius(3.5)
                    .fixedSize()
                    .help(L10n.maxWaitTooltip(maxStall, lang))
                }

                // 最近 1 小时 503 报错次数 tag（每 5 分钟自动刷新一次）
                let count503 = store.recent503Count
                let sev503 = Recent503Policy.severityLevel(count: count503)
                let color503: Color = sev503 == .warning
                    ? Color.red
                    : (sev503 == .caution ? Color(red: 0.85, green: 0.35, blue: 0.0) : Color.primary.opacity(0.65))
                let bg503: Color = sev503 == .warning
                    ? Color.red.opacity(0.10)
                    : (sev503 == .caution ? Color.orange.opacity(0.12) : Color.primary.opacity(0.05))
                let border503: Color = sev503 == .warning
                    ? Color.red.opacity(0.35)
                    : (sev503 == .caution ? Color.orange.opacity(0.35) : Color.primary.opacity(0.10))

                HStack(spacing: 3) {
                    if sev503 != .normal {
                        Image(systemName: "bolt.slash.fill")
                            .font(.system(size: 8.5, weight: .semibold))
                    }
                    Text(Recent503Policy.badgeText(count: count503))
                        .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                }
                .foregroundColor(color503)
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(bg503)
                .overlay(
                    RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                        .strokeBorder(border503, lineWidth: 0.5)
                )
                .cornerRadius(3.5)
                .fixedSize()
                .help(L10n.recent503Tooltip(count503, lang))

                Spacer()

                if !store.payload.sessions.isEmpty {
                    let displayedCount = SessionListFilter.sessionsForDisplay(store.payload.sessions).count
                    Text(L10n.sessionsCount(displayedCount, lang))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.primary.opacity(0.65))
                        .padding(.trailing, 2)
                }
            }
            .padding(.horizontal, 2)

            if !isSessionsCollapsed {
                if store.payload.sessions.isEmpty {
                    HStack {
                        Spacer()
                        Text(L10n.t(.noActiveSessions, lang))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 14)
                        Spacer()
                    }
                } else {
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 2.5) {
                            ForEach(SessionListFilter.sessionsForDisplay(store.payload.sessions)) { session in
                                CompactSessionRowView(session: session)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            store.openSessionDetail(session.uuid)
                                        }
                                    }
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    // MARK: - 底部状态栏 (Footer Bar)
    private var footerBar: some View {
        HStack {
            Text(L10n.updatedAt(store.lastUpdatedTimeStr, lang))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(Color.primary.opacity(0.65))

            Spacer()

            // 右下角设置按钮（从右上角移至此）
            ImpeccableIconButton(
                icon: "gearshape",
                tooltip: L10n.t(.settingsTitle, lang),
                tint: Color.primary.opacity(0.65),
                hoverTint: Color.primary,
                size: 26,
                iconSize: 12.5
            ) {
                showSettingsPopover.toggle()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
    }

    // MARK: - 新建账号隔离环境弹窗
    private var createProfileSheetView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t(.createProfileTitle, lang))
                .font(.system(size: 13, weight: .bold))

            Text(L10n.t(.createProfileSubtitle, lang))
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.t(.createProfileAccountLabel, lang))
                    .font(.system(size: 10.5, weight: .medium))
                TextField(L10n.t(.createProfileAccountPlaceholder, lang), text: $newProfileName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.t(.createProfileNotesLabel, lang))
                    .font(.system(size: 10.5, weight: .medium))
                TextField(L10n.t(.createProfileNotesPlaceholder, lang), text: $newProfileNotes)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Spacer()
                Button(L10n.t(.cancelAction, lang)) {
                    showCreateProfileSheet = false
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(.secondary)

                Button(L10n.t(.createAction, lang)) {
                    store.createProfile(
                        name: newProfileName,
                        notes: newProfileNotes,
                        customGeminiDir: newProfileDataDir
                    )
                    showCreateProfileSheet = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(newProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.top, 4)
        }
        .padding(14)
        .frame(width: 300)
    }

    // MARK: - 本地账号探测与切换日志弹窗
    private var discoveryLogsSheetView: some View {
        let logSnapshot = LocalAccountDetector.snapshotDiscoveryLogs()
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(L10n.t(.logsSheetTitle, lang), systemImage: "doc.text.magnifyingglass")
                    .font(.system(size: 12, weight: .bold))
                Spacer()
                Button(L10n.t(.copyLogsAction, lang)) {
                    let full = LocalAccountDetector.snapshotDiscoveryLogs().joined(separator: "\n")
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(full, forType: .string)
                    store.showBanner(L10n.t(.bannerCopiedLogs, lang))
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(Color.accentColor)

                Button(L10n.t(.closeAction, lang)) {
                    showLogsSheet = false
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            }

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 3) {
                    if logSnapshot.isEmpty {
                        Text(L10n.t(.logsEmpty, lang))
                            .font(.system(size: 10.5, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(8)
                    } else {
                        ForEach(Array(logSnapshot.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(size: 9.5, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding(8)
            }
            .background(Color.primary.opacity(0.04))
            .cornerRadius(6)
        }
        .padding(14)
        .frame(width: 480, height: 340)
    }

}

// MARK: - 5.1 运行设置弹窗视图 (SettingsPopoverView)

struct SettingsPopoverView: View {
    @ObservedObject var store: AGYHubStore
    var onClose: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var intervalText: String = ""

    private func closeSettings() {
        if let onClose = onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    private var lang: AppLanguage.Resolved {
        store.resolvedLanguage
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.t(.settingsTitle, lang))
                    .font(.system(size: 13.5, weight: .bold))

                Spacer()

                ImpeccableIconButton(
                    icon: "xmark",
                    tooltip: L10n.t(.closeSettingsTooltip, lang),
                    tint: .secondary,
                    hoverTint: .primary,
                    size: 22,
                    iconSize: 10.5
                ) {
                    closeSettings()
                }
            }

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 13) {

            HStack(spacing: 8) {
                Text(L10n.t(.languageSettingLabel, lang))
                    .font(.system(size: 11.5))

                Spacer()

                Picker("", selection: Binding(
                    get: { store.appLanguage },
                    set: { store.updateAppLanguage($0) }
                )) {
                    ForEach(AppLanguage.allCases) { option in
                        Text(option.pickerLabel(for: lang)).tag(option)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .controlSize(.small)
                .frame(width: 170)
            }

            Toggle(L10n.t(.launchAtLoginToggle, lang), isOn: Binding(
                get: { store.launchAtLogin },
                set: { store.toggleLaunchAtLogin($0) }
            ))
            .font(.system(size: 11.5))

            Toggle(L10n.t(.unifyMonitoringToggle, lang), isOn: $store.unifyLogMonitoring)
                .font(.system(size: 11.5))

            // 核心开关：CLI 与桌面 App 账号独立运行机制
            VStack(alignment: .leading, spacing: 4) {
                Toggle(L10n.t(.cliIndependentToggle, lang), isOn: Binding(
                    get: { store.isCLIIndependentMode },
                    set: { store.toggleCLIIndependentMode($0) }
                ))
                .font(.system(size: 11.5, weight: .medium))

                Text(L10n.t(.cliIndependentDesc, lang))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.leading, 20)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(L10n.t(.refreshIntervalLabel, lang))
                        .font(.system(size: 11.5))

                    Spacer()

                    TextField(L10n.t(.secondsPlaceholder, lang), text: $intervalText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 55, height: 24)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 11.5, design: .monospaced))
                        .onSubmit {
                            commitInterval()
                        }
                        .onChange(of: intervalText) { newText in
                            if let val = Double(newText.trimmingCharacters(in: .whitespacesAndNewlines)), val >= 0.2 {
                                store.updateRefreshInterval(val)
                            }
                        }

                    Text(L10n.t(.secondsUnit, lang))
                        .font(.system(size: 11.5))
                        .foregroundColor(.secondary)
                }
            }
            .onAppear {
                intervalText = formatInterval(store.refreshInterval)
            }

            Divider().opacity(0.3)

            // 授权与访问范围明细（随时查看并可一键取消）
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.t(.permissionsSectionTitle, lang))
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(.secondary)

                // 1. CLI 钥匙串槽位切换授权
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 7) {
                        Circle()
                            .fill(store.isCLIIndependentMode
                                  ? (store.isCLIVaultAuthorized ? Color.green : Color.secondary.opacity(0.4))
                                  : Color.secondary.opacity(0.3))
                            .frame(width: 6, height: 6)
                        VStack(alignment: .leading, spacing: 1.5) {
                            Text(L10n.t(.cliIsolatedSwitchingTitle, lang))
                                .font(.system(size: 11, weight: .medium))
                            if !store.isCLIIndependentMode {
                                Text(L10n.t(.cliNativeSharedHint, lang))
                                    .font(.system(size: 9.5))
                                    .foregroundColor(.secondary)
                            } else {
                                Text(store.isCLIVaultAuthorized ? L10n.t(.cliAuthorizedVaultHint, lang) : L10n.t(.cliUnauthorizedManualHint, lang))
                                    .font(.system(size: 9.5))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        if store.isCLIIndependentMode {
                            if store.isCLIVaultAuthorized {
                                ImpeccableActionButton(
                                    title: L10n.t(.revokeAuthButton, lang),
                                    icon: "shield.slash",
                                    baseFill: Color.red.opacity(0.10),
                                    hoverFill: Color.red.opacity(0.20),
                                    tint: .red,
                                    hoverTint: .red,
                                    cornerRadius: 4.5,
                                    horizontalPadding: 8,
                                    verticalPadding: 3.5,
                                    fontSize: 10,
                                    fontWeight: .semibold,
                                    tooltip: L10n.t(.revokeAuthTooltip, lang)
                                ) {
                                    store.revokeCLIVaultAuthorization()
                                }
                            } else {
                                ImpeccableActionButton(
                                    title: L10n.t(.enableAuthButton, lang),
                                    icon: "lock.shield",
                                    baseFill: Color.purple.opacity(0.12),
                                    hoverFill: Color.purple.opacity(0.24),
                                    tint: .purple,
                                    hoverTint: .purple,
                                    cornerRadius: 4.5,
                                    horizontalPadding: 8,
                                    verticalPadding: 3.5,
                                    fontSize: 10,
                                    fontWeight: .semibold,
                                    tooltip: L10n.t(.enableAuthTooltip, lang)
                                ) {
                                    store.authorizeCLIVault()
                                }
                            }
                        }
                    }

                    if store.isCLIIndependentMode && store.isCLIVaultAuthorized && !store.savedCLISlots.isEmpty {
                        VStack(alignment: .leading, spacing: 3.5) {
                            Text(L10n.cachedCLIAccountsTitle(store.savedCLISlots.count, lang))
                                .font(.system(size: 9.5))
                                .foregroundColor(.secondary)
                            ForEach(Array(store.savedCLISlots).sorted(), id: \.self) { email in
                                HStack(spacing: 5) {
                                    Text(String(email.split(separator: "@").first ?? Substring(email)))
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.primary.opacity(0.85))
                                        .lineLimit(1)
                                        .help(email)
                                    if store.activeCLIProfileName?.lowercased() == email {
                                        Text(L10n.t(.currentTag, lang))
                                            .font(.system(size: 8.5, weight: .semibold))
                                            .padding(.horizontal, 4.5)
                                            .padding(.vertical, 1)
                                            .background(Color.purple.opacity(0.14))
                                            .foregroundColor(.purple)
                                            .cornerRadius(3)
                                    }
                                    Spacer()
                                    ImpeccableIconButton(
                                        icon: "xmark",
                                        tooltip: L10n.t(.clearSlotTooltip, lang),
                                        tint: .secondary.opacity(0.7),
                                        hoverTint: .red,
                                        hoverFill: Color.red.opacity(0.14),
                                        size: 18,
                                        iconSize: 8.5
                                    ) {
                                        store.removeCLISlot(email)
                                    }
                                }
                            }
                        }
                        .padding(.leading, 13)
                    }
                }
                .padding(9)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.035)))

                // 2. 桌面 App 隔离目录 & 本地只读监控范围
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.isolatedProfilesLine(store.profiles.filter { !$0.isDefaultProfile }.count, lang))
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundColor(.secondary)
                    Text(L10n.t(.readOnlyScopeLine, lang))
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
                }
            }
            .frame(maxHeight: 400)

            Divider().opacity(0.3)

            HStack {
                Text(L10n.t(.closeWindowKeepsRunning, lang))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer()
                ImpeccableActionButton(
                    title: L10n.t(.quitAgyhubButton, lang),
                    icon: "power",
                    baseFill: Color.red.opacity(0.10),
                    hoverFill: Color.red.opacity(0.20),
                    tint: .red,
                    hoverTint: .red,
                    cornerRadius: 4.5,
                    horizontalPadding: 8,
                    verticalPadding: 4,
                    fontSize: 10.5,
                    fontWeight: .semibold,
                    tooltip: L10n.t(.quitAgyhubTooltip, lang)
                ) {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(16)
        .frame(width: 360)
        .environment(\.agyLanguage, lang)
        .onExitCommand {
            closeSettings()
        }
    }

    private func commitInterval() {
        if let val = Double(intervalText.trimmingCharacters(in: .whitespacesAndNewlines)), val >= 0.2 {
            store.updateRefreshInterval(val)
            intervalText = formatInterval(val)
        } else {
            intervalText = formatInterval(store.refreshInterval)
        }
    }

    private func formatInterval(_ val: Double) -> String {
        if val.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", val)
        } else {
            return String(format: "%.1f", val)
        }
    }
}

// MARK: - 5.9 配额微胶囊组件 (Quota Pill View)

struct QuotaPillView: View {
    let item: QuotaDisplayItem

    private var statusColor: Color {
        if item.remainingFraction > 0.2 {
            return Color.primary.opacity(0.70)
        } else if item.remainingFraction > 0.05 {
            return Color(red: 0.85, green: 0.35, blue: 0.0)
        } else {
            return Color.red
        }
    }

    var body: some View {
        HStack(spacing: 2.5) {
            Text(item.title)
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundColor(Color.primary.opacity(0.72))
                .fixedSize()

            Text("\(item.percentage)%")
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .foregroundColor(item.remainingFraction <= 0.2 ? statusColor : Color.primary)
                .fixedSize()

            if !item.countdown.isEmpty {
                Text("·\(item.countdown)")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.primary.opacity(0.62))
                    .fixedSize()
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.primary.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(item.remainingFraction <= 0.2 ? statusColor.opacity(0.40) : Color.primary.opacity(0.12), lineWidth: 0.5)
                )
        )
        .fixedSize(horizontal: true, vertical: true)
    }
}

// MARK: - 6. 极简账号行视图 (CompactProfileRowView)

enum ProfileRowActionPolicy {
    /// 账号行不再显示「双开」按钮，节约横向空间并防止布局跳变
    static let showsParallelLaunchButton = false
    /// 账号行不再显示「删除」按钮，节约横向空间并防止布局跳变
    static let showsDeleteButton = false

    /// 仅当窗口处于激活 Key 状态且鼠标悬停时才展示切换按钮，避免后台露边悬停误触
    static func shouldShowSwitchButton(isHovered: Bool, isWindowKey: Bool) -> Bool {
        isHovered && isWindowKey
    }
}

struct CompactProfileRowView: View {
    let profile: AGYProfile
    let mode: AccountTargetMode
    let isAppActive: Bool
    let isCLIActive: Bool
    let isCLIVaultAuthorized: Bool
    var isCLIIndependentMode: Bool = true
    let hasCLISlot: Bool
    var accountQuota: AccountQuotaSummary? = nil
    var isQuotaTokenExpired: Bool = false
    let onSwitchApp: () -> Void
    let onParallelApp: () -> Void
    let onSwitchCLI: () -> Void
    let onDelete: () -> Void

    @Environment(\.controlActiveState) private var controlActiveState
    @Environment(\.agyLanguage) private var lang
    @State private var isHovered = false

    private var isTargetActive: Bool {
        mode == .app ? isAppActive : isCLIActive
    }

    private var shortAccountId: String {
        if let atIdx = profile.name.firstIndex(of: "@") {
            let prefix = String(profile.name[..<atIdx])
            if !prefix.isEmpty { return prefix }
        }
        return profile.name
    }

    var body: some View {
        HStack(spacing: 5) {
            // 状态指示点
            if isTargetActive {
                Circle()
                    .fill(mode == .app ? Color.accentColor : Color.purple)
                    .frame(width: 6, height: 6)
                    .overlay(
                        Circle()
                            .stroke((mode == .app ? Color.accentColor : Color.purple).opacity(0.35), lineWidth: 2)
                    )
                    .padding(.horizontal, 2)
            } else if isAppActive || isCLIActive {
                Circle()
                    .strokeBorder(isCLIActive ? Color.purple.opacity(0.75) : Color.accentColor.opacity(0.75), lineWidth: 1.2)
                    .frame(width: 6, height: 6)
                    .padding(.horizontal, 2)
            } else {
                Circle()
                    .fill(Color.secondary.opacity(0.25))
                    .frame(width: 5, height: 5)
                    .padding(.horizontal, 2.5)
            }

            // 账号仅展示 @ 左侧 ID 与 App/CLI 当前激活徽章（完整邮箱悬浮提示）；允许尾部优雅截断，杜绝横向撑爆抖动
            HStack(spacing: 4) {
                Text(shortAccountId)
                    .font(.system(size: 13, weight: isTargetActive ? .bold : .medium))
                    .foregroundColor(isTargetActive ? .primary : Color.primary.opacity(0.88))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .layoutPriority(1)
                    .help(profile.name)

                if isAppActive {
                    Text("App")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundColor(Color.accentColor)
                        .cornerRadius(3.5)
                        .fixedSize()
                        .layoutPriority(2)
                }
                if isCLIActive {
                    Text("CLI")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.purple.opacity(0.12))
                        .foregroundColor(Color.purple)
                        .cornerRadius(3.5)
                        .fixedSize()
                        .layoutPriority(2)
                }
            }
            .layoutPriority(0)

            // 账号周额度微胶囊 (显示 Gemini / Argon 周度额度与重置时间，Ultra 账号仅展示单一 Gemini 额度；Token 过期时温和提示)
            if let quota = accountQuota {
                let items = AccountQuotaManager.displayItems(for: quota, language: lang)
                if !items.isEmpty {
                    HStack(spacing: 3.5) {
                        ForEach(items) { item in
                            QuotaPillView(item: item)
                        }
                    }
                    .opacity(isQuotaTokenExpired ? 0.65 : 1.0)
                    .fixedSize()
                    .layoutPriority(2)
                    .help(AccountQuotaManager.quotaTooltip(items: items, isUltra: quota.isUltra, isExpired: isQuotaTokenExpired, language: lang))
                }
            } else if isQuotaTokenExpired {
                HStack(spacing: 3) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 8.5, weight: .medium))
                    Text(L10n.quotaExpiredBadge(for: lang))
                        .font(.system(size: 9.5, weight: .medium))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 5.5)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.primary.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.5)
                        )
                )
                .fixedSize()
                .layoutPriority(2)
                .help(L10n.quotaExpiredHint(for: lang))
            }

            // 需求 1：账号中间空白拖拽区域，鼠标在空白区域按下可直接拖动窗口；降低布局优先级避免挤压左侧账号名
            Spacer(minLength: 2)
                .frame(height: 24)
                .contentShape(Rectangle())
                .background(WindowDragArea())
                .layoutPriority(-1)

            // 操作动作 (激活项常态显示清晰深色标识，非激活项悬停即刻清晰展示精简切换按钮，杜绝淡入残影与行宽抖动)
            HStack(spacing: 4) {
                if mode == .app {
                    if isAppActive {
                        Text(L10n.t(.activeAppBadge, lang))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.primary.opacity(0.70))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(Color.accentColor.opacity(0.08))
                            .cornerRadius(4)
                            .fixedSize()
                    } else if ProfileRowActionPolicy.shouldShowSwitchButton(isHovered: isHovered, isWindowKey: controlActiveState == .key) {
                        HStack(spacing: 3) {
                            Button {
                                guard WindowActivationGuard.shouldAllowAccountSwitch() else { return }
                                onSwitchApp()
                            } label: {
                                HStack(spacing: 2.5) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 9.5, weight: .semibold))
                                    Text(L10n.t(.switchAction, lang))
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .fixedSize()
                            }
                            .buttonStyle(ImpeccablePillButtonStyle(
                                baseFill: Color.accentColor.opacity(0.18),
                                hoverFill: Color.accentColor.opacity(0.26),
                                foreground: Color.accentColor,
                                isHovered: true
                            ))
                            .help(L10n.t(.switchAppHelp, lang))

                            if ProfileRowActionPolicy.showsParallelLaunchButton {
                                Button(action: onParallelApp) {
                                    HStack(spacing: 2.5) {
                                        Image(systemName: "plus.rectangle.on.rectangle")
                                            .font(.system(size: 9.5))
                                        Text(L10n.t(.parallelLaunchAction, lang))
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                    .fixedSize()
                                }
                                .buttonStyle(ImpeccablePillButtonStyle(
                                    baseFill: Color.primary.opacity(0.06),
                                    hoverFill: Color.primary.opacity(0.14),
                                    foreground: Color.primary.opacity(0.85),
                                    isHovered: true
                                ))
                                .help(L10n.t(.parallelLaunchHelp, lang))
                            }

                            if ProfileRowActionPolicy.showsDeleteButton && !profile.isDefaultProfile {
                                ImpeccableIconButton(
                                    icon: "trash",
                                    tooltip: L10n.t(.removeProfileHelp, lang),
                                    tint: Color.primary.opacity(0.60),
                                    hoverTint: .red,
                                    hoverFill: Color.red.opacity(0.12),
                                    size: 18,
                                    iconSize: 9.5
                                ) {
                                    onDelete()
                                }
                            }
                        }
                    }
                } else {
                    // CLI 模式
                    if isCLIActive {
                        Text(L10n.t(.activeCLIBadge, lang))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.purple.opacity(0.85))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(Color.purple.opacity(0.08))
                            .cornerRadius(4)
                            .fixedSize()
                    } else if ProfileRowActionPolicy.shouldShowSwitchButton(isHovered: isHovered, isWindowKey: controlActiveState == .key) {
                        let showHotSwap = isCLIVaultAuthorized && hasCLISlot
                        let labelText = !isCLIVaultAuthorized
                            ? L10n.t(.terminalLoginAction, lang)
                            : (hasCLISlot ? L10n.t(.switchCLIAction, lang) : L10n.t(.loginCLIAction, lang))
                        let iconName = showHotSwap ? "bolt.horizontal.fill" : "terminal"
                        HStack(spacing: 3) {
                            Button {
                                guard WindowActivationGuard.shouldAllowAccountSwitch() else { return }
                                onSwitchCLI()
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: iconName)
                                        .font(.system(size: 9.5, weight: .semibold))
                                    Text(labelText)
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .fixedSize()
                            }
                            .buttonStyle(ImpeccablePillButtonStyle(
                                baseFill: showHotSwap ? Color.purple.opacity(0.18) : Color.primary.opacity(0.09),
                                hoverFill: showHotSwap ? Color.purple.opacity(0.26) : Color.primary.opacity(0.16),
                                foreground: showHotSwap ? Color.purple : Color.primary.opacity(0.90),
                                isHovered: true
                            ))
                            .help(
                                !isCLIVaultAuthorized
                                    ? L10n.t(.cliUnauthorizedHelp, lang)
                                    : (hasCLISlot ? L10n.t(.cliCachedSlotHelp, lang) : L10n.t(.cliFirstLoginHelp, lang))
                            )

                            if ProfileRowActionPolicy.showsDeleteButton && !profile.isDefaultProfile {
                                ImpeccableIconButton(
                                    icon: "trash",
                                    tooltip: L10n.t(.removeProfileHelp, lang),
                                    tint: Color.primary.opacity(0.60),
                                    hoverTint: .red,
                                    hoverFill: Color.red.opacity(0.12),
                                    size: 18,
                                    iconSize: 9.5
                                ) {
                                    onDelete()
                                }
                            }
                        }
                    }
                }
            }
            .layoutPriority(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(isHovered ? Color.primary.opacity(0.04) : Color.clear)
        )
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
    }
}

// MARK: - 6.8 会话列表数据源过滤器与查找策略 (Session List Filter & Lookup)

enum SessionListFilter {
    /// 返回用于界面滚动的顶层会话列表（自动剔除父会话已在列表中的泄漏子 Agent，保证收折完整性与全量滚动）
    static func sessionsForDisplay(_ sessions: [SessionItem]) -> [SessionItem] {
        let topIds = Set(sessions.map(\.uuid))
        return sessions.filter { item in
            item.parentConversationId.isEmpty || !topIds.contains(item.parentConversationId)
        }
    }
}

enum SessionLookup {
    /// 递归查找会话或其旗下嵌套的子 Agent，支持详情下钻后实时跟随轮询刷新
    static func findSession(uuid: String, in sessions: [SessionItem]) -> SessionItem? {
        for item in sessions {
            if item.uuid == uuid {
                return item
            }
            if let found = findSession(uuid: uuid, in: item.subagents) {
                return found
            }
        }
        return nil
    }

    /// 计算所有运行中会话（包含收折的活跃子 Agent）中的最大排队/等待耗时
    static func maxStallSeconds(in sessions: [SessionItem]) -> Double {
        var maxVal = 0.0
        for item in sessions {
            if item.isRunning {
                maxVal = max(maxVal, item.currentStall)
            }
            maxVal = max(maxVal, maxStallSeconds(in: item.subagents))
        }
        return maxVal
    }
}

enum SessionDetailSubagentPolicy {
    /// 将正在工作的子 Agent 排在前面，其余保持顺序以便快速查看活跃工作节点
    static func sortedSubagents(_ subagents: [SessionItem]) -> [SessionItem] {
        subagents.sorted { lhs, rhs in
            if lhs.isRunning != rhs.isRunning {
                return lhs.isRunning && !rhs.isRunning
            }
            return false
        }
    }

    /// 优先展示真实角色名（agentName / agentRole），缺失时回退至清洗后的标题或短 ID
    static func displayName(for subagent: SessionItem, language: AppLanguage.Resolved = .zhHans) -> String {
        let trimmedName = subagent.agentName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            return trimmedName
        }
        let trimmedRole = subagent.agentRole.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedRole.isEmpty {
            return trimmedRole
        }
        return SessionTitleCleaner.cleanTitle(subagent.title, fallbackUUID: subagent.uuid, language: language)
    }
}

// MARK: - 6.9 会话标题清洗工具 (Session Title Cleaner)

enum SessionTitleCleaner {
    static func cleanTitle(_ rawTitle: String, fallbackUUID: String, language: AppLanguage.Resolved = .zhHans) -> String {
        let trimmed = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let invalidTitles: Set<String> = ["{", "}", "{}", "未命名会话", "[", "]", "[]"]
        let shortId = fallbackUUID.replacingOccurrences(of: "-", with: "")
        let idSnippet = shortId.count >= 6 ? String(shortId.prefix(6)) : fallbackUUID

        if trimmed.isEmpty || invalidTitles.contains(trimmed) {
            return language == .zhHans ? "会话 #\(idSnippet)" : "Session #\(idSnippet)"
        }
        return trimmed
    }
}

/// 会话长标题悬浮跑马灯计算策略：仅当真实溢出容器宽度时开启平滑来回滚动
enum SessionTitleMarqueePolicy {
    static let edgePauseDuration: Double = 0.25
    static let trailingRevealPadding: CGFloat = 10.0

    static func overflowDistance(textWidth: CGFloat, containerWidth: CGFloat) -> CGFloat {
        let overflow = textWidth - containerWidth
        return overflow > 2.0 ? overflow : 0.0
    }

    static func shouldScroll(isHovered: Bool, textWidth: CGFloat, containerWidth: CGFloat) -> Bool {
        isHovered && overflowDistance(textWidth: textWidth, containerWidth: containerWidth) > 0
    }

    static func scrollDuration(overflowDistance: CGFloat, speedPtsPerSec: CGFloat = 34.0) -> Double {
        guard overflowDistance > 0 else { return 0.0 }
        return max(1.2, Double(overflowDistance / speedPtsPerSec))
    }

    /// 按时间轴计算周期性往返偏移：首端停顿 -> 匀速左移展示末尾 -> 尾端停顿 -> 匀速回位
    static func marqueeOffset(elapsed: TimeInterval, overflowDistance: CGFloat) -> CGFloat {
        guard overflowDistance > 0, elapsed >= 0 else { return 0.0 }
        let maxShift = overflowDistance + trailingRevealPadding
        let travel = scrollDuration(overflowDistance: overflowDistance)
        let cycle = (edgePauseDuration + travel) * 2.0
        guard cycle > 0 else { return 0.0 }

        let phase = elapsed.truncatingRemainder(dividingBy: cycle)
        if phase <= edgePauseDuration {
            return 0.0
        } else if phase <= edgePauseDuration + travel {
            let progress = CGFloat((phase - edgePauseDuration) / travel)
            return -maxShift * progress
        } else if phase <= edgePauseDuration * 2.0 + travel {
            return -maxShift
        } else {
            let backProgress = CGFloat((phase - (edgePauseDuration * 2.0 + travel)) / travel)
            return -maxShift * (1.0 - backProgress)
        }
    }
}

/// 单行会话标题：默认尾部省略号截断，鼠标悬浮且发生截断时平滑自动横滚展示完整内容
struct ScrollingSessionTitleView: View {
    let title: String
    let font: Font
    let foregroundColor: Color
    let isHovered: Bool

    @State private var containerWidth: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var hoverStartedAt: Date = Date()

    private var overflow: CGFloat {
        SessionTitleMarqueePolicy.overflowDistance(textWidth: textWidth, containerWidth: containerWidth)
    }

    private var activeScroll: Bool {
        SessionTitleMarqueePolicy.shouldScroll(
            isHovered: isHovered,
            textWidth: textWidth,
            containerWidth: containerWidth
        )
    }

    var body: some View {
        // 主视图决定紧凑布局尺寸（minWidth/idealWidth 均为 0），绝不把长文本的自然宽度向上传递撑爆弹窗
        Text(title)
            .font(font)
            .foregroundColor(foregroundColor)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(minWidth: 0, idealWidth: 0, maxWidth: .infinity, alignment: .leading)
            .opacity(activeScroll ? 0 : 1)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { containerWidth = geo.size.width }
                        .onChange(of: geo.size.width) { containerWidth = $0 }
                }
            )
            .background(
                // 用 GeometryReader 隔离测量子节点，阻断 .fixedSize() 理想宽度向上传导
                GeometryReader { _ in
                    Text(title)
                        .font(font)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .background(
                            GeometryReader { textGeo in
                                Color.clear
                                    .onAppear { textWidth = textGeo.size.width }
                                    .onChange(of: textGeo.size.width) { textWidth = $0 }
                                    .onChange(of: title) { _ in textWidth = textGeo.size.width }
                            }
                        )
                        .hidden()
                }
                .allowsHitTesting(false)
            )
            .overlay(alignment: .leading) {
                if activeScroll {
                    GeometryReader { geo in
                        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
                            let elapsed = max(0, context.date.timeIntervalSince(hoverStartedAt))
                            let xOffset = SessionTitleMarqueePolicy.marqueeOffset(
                                elapsed: elapsed,
                                overflowDistance: overflow
                            )
                            Text(title)
                                .font(font)
                                .foregroundColor(foregroundColor)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .offset(x: xOffset)
                                .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
                        }
                    }
                    .allowsHitTesting(false)
                }
            }
            .clipped()
            .onChange(of: activeScroll) { shouldAnimate in
                if shouldAnimate {
                    hoverStartedAt = Date()
                }
            }
    }
}

// MARK: - 7. 极简会话行视图 (CompactSessionRowView)

/// 会话行胶囊标签（模型、上下文）的文案规范、视觉配色与紧凑尺寸常量
enum SessionRowBadgePolicy {
    static let modelFontSize: CGFloat = 9.5
    static let contextFontSize: CGFloat = 9.5
    static let modelColumnWidth: CGFloat = 70
    static let contextColumnWidth: CGFloat = 42
    static let metricsColumnWidth: CGFloat = 72

    /// 适应浅色/深色外观的冷静蓝灰上下文配色，确保与高饱和实时速率拉开主次
    static func contextForegroundColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.56, green: 0.78, blue: 1.0)
            : Color(red: 0.15, green: 0.39, blue: 0.70)
    }

    static func contextFillColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.blue.opacity(0.16) : Color.blue.opacity(0.07)
    }

    static func contextBorderColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.blue.opacity(0.28) : Color.blue.opacity(0.16)
    }

    /// 裁剪模型名称前缀，将超长编排模型映射为短促胶囊标签并兜底空值
    static func modelBadgeText(_ rawModel: String) -> String {
        var clean = rawModel
        if clean.hasPrefix("gemini-") {
            clean = String(clean.dropFirst("gemini-".count))
        }
        guard !clean.isEmpty else { return "-" }
        let lower = clean.lowercased()
        if lower.contains("orchestrator") {
            if lower.contains("pro-orchestrator") || lower.contains("argon") {
                return "argon-orch"
            }
            if lower.contains("flash-orchestrator") || lower.contains("flash") {
                return "flash-orch"
            }
            return "orch"
        }
        return clean
    }

    /// 仅在存在有效模型名时渲染胶囊，避免 "-" 占用空胶囊边框
    static func hasModel(_ rawModel: String) -> Bool {
        modelBadgeText(rawModel) != "-"
    }

    /// 格式化单会话当前上下文长度（如 51k / 142k）；无上下文时返回 "-"
    static func contextBadgeText(contextTokens: Int) -> String {
        guard contextTokens > 0 else { return "-" }
        return Formatters.formatTokens(contextTokens)
    }

    /// 构建上下文胶囊的悬停提示文案
    static func contextTooltip(contextTokens: Int, language: AppLanguage.Resolved = .zhHans) -> String {
        guard contextTokens > 0 else { return L10n.t(.contextEmptyTooltip, language) }
        return language == .zhHans
            ? "当前上下文: \(Formatters.formatTokens(contextTokens)) (\(contextTokens) tokens)"
            : "Context: \(Formatters.formatTokens(contextTokens)) (\(contextTokens) tokens)"
    }

    /// 外层会话列表空闲指标：仅展示当前会话自身总消耗与自身缓存率（详情页再汇总全部子 Agent）
    static func idleMetricsText(for session: SessionItem) -> String {
        let tokenStr = Formatters.formatTokens(session.totalTokensConsumed)
        let cacheStr = String(format: "%.0f%%", session.cachePct)
        return "\(tokenStr) \(cacheStr)"
    }

    /// 是否存在正在干活的子 Agent，决定外层动态 Tag 的绿色活跃样式
    static func isSubagentBadgeActive(for session: SessionItem) -> Bool {
        session.effectiveActiveSubagentCount > 0
    }

    /// 外层会话行动态 Agent Tag 文案：有活跃子 Agent 时展示 "<N> Agent · <t/s>"（无速率时显示"运行中"），全员待命时展示 "<总N> Agent"，无子 Agent 返回 nil
    static func subagentBadgeText(for session: SessionItem, language: AppLanguage.Resolved = .zhHans) -> String? {
        let total = session.effectiveSubagentCount
        guard total > 0 else { return nil }
        let active = session.effectiveActiveSubagentCount
        if active > 0 {
            let tps = session.effectiveActiveSubagentTps
            let tpsText: String
            if tps >= 10 {
                tpsText = "\(Int(tps.rounded()))t/s"
            } else if tps > 0 {
                tpsText = String(format: "%.1ft/s", tps)
            } else {
                tpsText = L10n.t(.runningStatus, language)
            }
            return "\(active) Agent · \(tpsText)"
        }
        return "\(total) Agent"
    }

    /// 动态 Agent Tag 悬浮提示文案
    static func subagentTooltip(for session: SessionItem, language: AppLanguage.Resolved = .zhHans) -> String {
        let total = session.effectiveSubagentCount
        let active = session.effectiveActiveSubagentCount
        let names = SessionDetailSubagentPolicy.sortedSubagents(session.subagents)
            .prefix(5)
            .map { SessionDetailSubagentPolicy.displayName(for: $0, language: language) }
            .joined(separator: ", ")
        let suffix = names.isEmpty ? "" : " (\(names))"
        if active > 0 {
            return language == .zhHans
                ? "正在工作: \(active)/\(total) 个子 Agent\(suffix) · 点击进入详情"
                : "Working: \(active)/\(total) subagent(s)\(suffix) · Click for details"
        }
        return language == .zhHans
            ? "已收折 \(total) 个子 Agent\(suffix) · 点击进入详情"
            : "\(total) collapsed subagent(s)\(suffix) · Click for details"
    }
}

/// 内容自适应胶囊标签组件，通过填充与描边区分模型（柔雾填充）与上下文（冷静蓝调微描边）
struct SessionCapsuleBadge: View {
    let text: String
    let font: Font
    let foregroundColor: Color
    let fillColor: Color
    var borderColor: Color? = nil
    var horizontalPadding: CGFloat = 6.5
    var verticalPadding: CGFloat = 2

    var body: some View {
        Text(text)
            .font(font)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                Capsule()
                    .fill(fillColor)
                    .overlay(
                        Group {
                            if let borderColor {
                                Capsule()
                                    .strokeBorder(borderColor, lineWidth: 0.5)
                            }
                        }
                    )
            )
            .foregroundColor(foregroundColor)
            .clipShape(Capsule())
    }
}

struct CompactSessionRowView: View {
    let session: SessionItem
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.agyLanguage) private var lang
    @State private var isHovered = false

    private var displayTitle: String {
        SessionTitleCleaner.cleanTitle(session.title, fallbackUUID: session.uuid, language: lang)
    }

    var body: some View {
        HStack(spacing: 5) {
            // 状态呼吸小点（本人或旗下子 Agent 任一在干活均亮绿灯）
            if session.isActivelyWorking {
                Circle()
                    .fill(Color.green)
                    .frame(width: 5.5, height: 5.5)
                    .shadow(color: Color.green.opacity(0.4), radius: 1.5)
            } else {
                Circle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 5, height: 5)
            }

            // 会话标题（全列表左侧严格对齐；悬浮时超长自动滚动；CLI 标记叠放在右上角红框区不占正文字宽）
            ScrollingSessionTitleView(
                title: displayTitle,
                font: .system(size: 12.5, weight: session.isActivelyWorking ? .bold : .medium),
                foregroundColor: session.isActivelyWorking ? .primary : Color.primary.opacity(0.88),
                isHovered: isHovered
            )
            .overlay(alignment: .topTrailing) {
                if let cliLabel = session.cliBadgeLabel {
                    Text(cliLabel)
                        .font(.system(size: 7.5, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 0.5)
                        .background(
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.95))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(Color.purple.opacity(0.14))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .strokeBorder(Color.purple.opacity(0.28), lineWidth: 0.5)
                        )
                        .foregroundColor(Color.purple)
                        .fixedSize()
                        .offset(x: -2, y: -4.5)
                        .allowsHitTesting(false)
                        .help(L10n.t(.cliSessionTooltip, lang))
                }
            }

            // 动态子 Agent 聚合 Tag（干活数量 + t/s，或已收折子 Agent 数）
            if let badgeText = SessionRowBadgePolicy.subagentBadgeText(for: session, language: lang) {
                let isActive = SessionRowBadgePolicy.isSubagentBadgeActive(for: session)
                let activeFg = colorScheme == .dark
                    ? Color(red: 0.45, green: 0.92, blue: 0.62)
                    : Color(red: 0.06, green: 0.48, blue: 0.22)
                HStack(spacing: 3) {
                    Image(systemName: isActive ? "bolt.fill" : "square.stack.3d.up")
                        .font(.system(size: 8, weight: .semibold))
                    Text(badgeText)
                        .font(.system(size: 9.5, weight: isActive ? .bold : .medium, design: .rounded).monospacedDigit())
                        .lineLimit(1)
                }
                .foregroundColor(isActive ? activeFg : Color.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(isActive ? Color.green.opacity(colorScheme == .dark ? 0.18 : 0.11) : Color.primary.opacity(0.055))
                        .overlay(
                            Capsule()
                                .strokeBorder(isActive ? Color.green.opacity(0.35) : Color.primary.opacity(0.10), lineWidth: 0.5)
                        )
                )
                .fixedSize()
                .layoutPriority(1)
                .help(SessionRowBadgePolicy.subagentTooltip(for: session, language: lang))
            }

            // 模型名称（内容自适应柔雾胶囊，右对齐固定 70pt 列槽；无模型时仅展示极轻占位符）
            Group {
                if SessionRowBadgePolicy.hasModel(session.model) {
                    SessionCapsuleBadge(
                        text: SessionRowBadgePolicy.modelBadgeText(session.model),
                        font: .system(size: SessionRowBadgePolicy.modelFontSize, weight: .medium),
                        foregroundColor: Color.primary.opacity(0.75),
                        fillColor: Color.primary.opacity(0.055),
                        horizontalPadding: 6.5,
                        verticalPadding: 2
                    )
                    // 仅锁定纵向尺寸，横向受外层 modelColumnWidth 约束以便超长未映射模型名自动省略，避免覆盖标题
                    .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("—")
                        .font(.system(size: 10))
                        .foregroundColor(Color.secondary.opacity(0.35))
                }
            }
            .frame(width: SessionRowBadgePolicy.modelColumnWidth, alignment: .trailing)
            .help(L10n.modelHelp(session.model, lang))

            // 当前上下文规模胶囊（等宽圆体数字 + 冷静蓝调描边胶囊，右对齐固定 42pt 列槽）
            Group {
                if session.contextTokens > 0 {
                    SessionCapsuleBadge(
                        text: SessionRowBadgePolicy.contextBadgeText(contextTokens: session.contextTokens),
                        font: .system(size: SessionRowBadgePolicy.contextFontSize, weight: .semibold, design: .rounded).monospacedDigit(),
                        foregroundColor: SessionRowBadgePolicy.contextForegroundColor(for: colorScheme),
                        fillColor: SessionRowBadgePolicy.contextFillColor(for: colorScheme),
                        borderColor: SessionRowBadgePolicy.contextBorderColor(for: colorScheme),
                        horizontalPadding: 6.5,
                        verticalPadding: 2
                    )
                    .fixedSize()
                } else {
                    Text("—")
                        .font(.system(size: 10))
                        .foregroundColor(Color.secondary.opacity(0.35))
                }
            }
            .frame(width: SessionRowBadgePolicy.contextColumnWidth, alignment: .trailing)
            .help(SessionRowBadgePolicy.contextTooltip(contextTokens: session.contextTokens, language: lang))

            // 核心动态指标 (固定列宽 72，严格向右对齐，垂直一条线)
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                if session.isRunning {
                    HStack(spacing: 2) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 8.5))
                        Text(session.tps > 0 ? String(format: "%.0ft/s", session.tps) : L10n.t(.runningStatus, lang))
                            .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(Color.accentColor)
                } else {
                    Text(SessionRowBadgePolicy.idleMetricsText(for: session))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.primary.opacity(0.72))
                        .lineLimit(1)
                }
            }
            .frame(width: SessionRowBadgePolicy.metricsColumnWidth, alignment: .trailing)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5.5)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isHovered ? Color.primary.opacity(0.04) : Color.clear)
        )
        .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .onHover { isHovered = $0 }
    }
}

// MARK: - 8. 极简会话详情视图 (SessionDetailCardView)

struct SessionDetailCardView: View {
    let session: SessionItem
    var diagnostics: SessionDiagnosticsPayload? = nil
    var isLoadingDiagnostics: Bool = false
    let onBack: () -> Void
    var onRefreshDiagnostics: (() -> Void)? = nil
    var onSelectSubagent: ((String) -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.agyLanguage) private var lang
    @State private var copiedDiagnosticsRecently: Bool = false

    private var headerDisplayTitle: String {
        let cleaned = SessionTitleCleaner.cleanTitle(session.title, fallbackUUID: session.uuid, language: lang)
        if !session.agentName.isEmpty && session.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(session.agentName) · \(session.shortId)"
        }
        return cleaned
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 9.5, weight: .bold))
                        Text(L10n.t(.backButton, lang))
                            .font(.system(size: 11.5, weight: .medium))
                    }
                    .foregroundColor(Color.accentColor)
                }
                .buttonStyle(.plain)

                Spacer()

                if let onRefreshDiagnostics {
                    Button(action: onRefreshDiagnostics) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(4)
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(3.5)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoadingDiagnostics)
                    .help(L10n.t(.refreshDiagnosticsTooltip, lang))
                }

                if let diagnostics {
                    Button(action: {
                        let pb = NSPasteboard.general
                        pb.clearContents()
                        pb.setString(SessionDiagnosticsPolicy.formattedClipboardReport(diagnostics, language: lang), forType: .string)
                        copiedDiagnosticsRecently = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                            copiedDiagnosticsRecently = false
                        }
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: copiedDiagnosticsRecently ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 9.5, weight: .semibold))
                            Text(copiedDiagnosticsRecently ? L10n.t(.copiedButton, lang) : L10n.t(.copySummaryButton, lang))
                                .font(.system(size: 10.5, weight: .medium))
                        }
                        .foregroundColor(copiedDiagnosticsRecently ? .green : Color.accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background((copiedDiagnosticsRecently ? Color.green : Color.accentColor).opacity(0.1))
                        .cornerRadius(3.5)
                    }
                    .buttonStyle(.plain)
                    .help(L10n.t(.copySummaryTooltip, lang))
                }
            }

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 7) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            if session.isActivelyWorking {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                            }
                            Text(headerDisplayTitle)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                        }

                        if !session.agentRole.isEmpty {
                            Text(session.agentRole)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color.accentColor)
                        }

                        HStack(spacing: 6) {
                            Text(session.model)
                                .font(.system(size: 10.5, design: .monospaced))
                                .foregroundColor(.secondary)

                            Text("·")
                                .foregroundColor(.secondary.opacity(0.4))

                            Text(L10n.interactionsCount(session.interactions, lang))
                                .font(.system(size: 10.5))
                                .foregroundColor(.secondary)

                            Text("·")
                                .foregroundColor(.secondary.opacity(0.4))

                            Text(Formatters.formatHMS(session.totalActiveSec))
                                .font(.system(size: 10.5, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider().opacity(0.25)

                    // 核心统计行（存在子 Agent 时汇总主会话与全部子 Agent 的账单、总 Token 与加权缓存率；上下文保持主会话自身窗口规模）
                    let hasSubagents = !session.subagents.isEmpty
                    let statHelpText: String = {
                        guard hasSubagents else { return "" }
                        let subCost = max(0, session.aggregatedTotalCostUsd - session.totalCostUsd)
                        let subTokens = max(0, session.aggregatedTotalTokensConsumed - session.totalTokensConsumed)
                        return L10n.mainAndSubagentsTooltip(
                            subCount: session.subagents.count,
                            mainCost: session.totalCostUsd,
                            mainTokens: session.totalTokensConsumed,
                            subCost: subCost,
                            subTokens: subTokens,
                            lang
                        )
                    }()
                    HStack(spacing: 0) {
                        detailStatItem(title: L10n.t(.statEstCost, lang), value: Formatters.formatCost(session.aggregatedTotalCostUsd))
                        detailStatItem(title: L10n.t(.statTotalTokens, lang), value: Formatters.formatTokens(session.aggregatedTotalTokensConsumed))
                        detailStatItem(title: L10n.t(.statContext, lang), value: Formatters.formatTokens(session.contextTokens))
                        detailStatItem(title: L10n.t(.statCacheHit, lang), value: String(format: "%.0f%%", session.aggregatedCachePct))
                    }
                    .padding(.vertical, 2)
                    .help(statHelpText)

                    if !session.subagents.isEmpty {
                        Divider().opacity(0.25)
                        subagentsDetailSection
                    }

                    Divider().opacity(0.25)

                    SessionDiagnosticsInlineSection(
                        payload: diagnostics,
                        isLoading: isLoadingDiagnostics
                    )
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(0.025))
        )
    }

    private var subagentsDetailSection: some View {
        let sortedSubs = SessionDetailSubagentPolicy.sortedSubagents(session.subagents)
        let activeBadge = SessionRowBadgePolicy.subagentBadgeText(for: session, language: lang) ?? L10n.subagentFallbackBadge(sortedSubs.count, lang)
        let isActive = SessionRowBadgePolicy.isSubagentBadgeActive(for: session)
        let activeFg = colorScheme == .dark
            ? Color(red: 0.45, green: 0.92, blue: 0.62)
            : Color(red: 0.06, green: 0.48, blue: 0.22)

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(L10n.t(.subagentsSectionTitle, lang))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                Text(activeBadge)
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundColor(isActive ? activeFg : .secondary)
                    .padding(.horizontal, 5.5)
                    .padding(.vertical, 1.5)
                    .background(
                        Capsule()
                            .fill(isActive ? Color.green.opacity(0.12) : Color.primary.opacity(0.055))
                    )
            }

            VStack(spacing: 3) {
                ForEach(sortedSubs) { sub in
                    subagentDetailRow(sub)
                }
            }
        }
    }

    private func subagentDetailRow(_ sub: SessionItem) -> some View {
        let name = SessionDetailSubagentPolicy.displayName(for: sub, language: lang)
        let rawActionHint = sub.recentError ?? (sub.isRunning ? sub.currentAction : "")
        let actionHint = L10n.localizeRuntimeText(rawActionHint, language: lang)

        return Button {
            onSelectSubagent?(sub.uuid)
        } label: {
            VStack(alignment: .leading, spacing: 2.5) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(sub.isRunning ? Color.green : Color.secondary.opacity(0.35))
                        .frame(width: 5, height: 5)

                    Text(name)
                        .font(.system(size: 11, weight: sub.isRunning ? .bold : .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(sub.shortId)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary)

                    Spacer(minLength: 4)

                    if SessionRowBadgePolicy.hasModel(sub.model) {
                        Text(SessionRowBadgePolicy.modelBadgeText(sub.model))
                            .font(.system(size: 8.5, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4.5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color.primary.opacity(0.055)))
                            .lineLimit(1)
                    }

                    if sub.contextTokens > 0 {
                        Text(Formatters.formatTokens(sub.contextTokens))
                            .font(.system(size: 9, weight: .semibold, design: .rounded).monospacedDigit())
                            .foregroundColor(SessionRowBadgePolicy.contextForegroundColor(for: colorScheme))
                    }

                    if sub.isRunning {
                        HStack(spacing: 1.5) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 8))
                            Text(sub.tps > 0 ? String(format: "%.0ft/s", sub.tps) : L10n.t(.runningStatus, lang))
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(Color.accentColor)
                    } else {
                        Text("\(Formatters.formatTokens(sub.totalTokensConsumed)) \(String(format: "%.0f%%", sub.cachePct))")
                            .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.primary.opacity(0.72))
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 8.5, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.6))
                }

                if !actionHint.isEmpty {
                    Text(actionHint)
                        .font(.system(size: 9))
                        .foregroundColor(sub.recentError != nil ? .red : .secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.leading, 10)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4.5)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(sub.isRunning ? Color.green.opacity(0.06) : Color.primary.opacity(0.035))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(sub.isRunning ? Color.green.opacity(0.22) : Color.primary.opacity(0.06), lineWidth: 0.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(!sub.agentRole.isEmpty ? "\(sub.agentRole) (\(sub.uuid))" : sub.uuid)
    }

    private func detailStatItem(title: String, value: String) -> some View {
        VStack(spacing: 1) {
            Text(title)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 7.5 会话上下文与缓存失效内嵌诊断视图 (SessionDiagnosticsInlineSection)

enum DiagnosticDistributionTab: String, CaseIterable {
    case phases = "按工作阶段"
    case sources = "按上下文来源"

    func title(for lang: AppLanguage.Resolved) -> String {
        switch self {
        case .phases: return L10n.t(.diagTabPhases, lang)
        case .sources: return L10n.t(.diagTabSources, lang)
        }
    }
}

struct SessionDiagnosticsInlineSection: View {
    let payload: SessionDiagnosticsPayload?
    let isLoading: Bool

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.agyLanguage) private var lang
    @State private var distributionTab: DiagnosticDistributionTab = .sources
    @State private var showMissEvents: Bool = false

    private var cardSurface: Color {
        colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.035)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isLoading && payload == nil {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text(L10n.t(.diagLoading, lang))
                        .font(.system(size: 10.5))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 18)
                .background(cardSurface)
                .cornerRadius(7)
            } else if let d = payload {
                VStack(alignment: .leading, spacing: 8) {
                    // 一、Token 与上下文分布（单张可切换饼图 + 实测元凶提示）
                    distributionSection(d)

                    // 二、缓存失效诊断（可控 vs 平台 + 案发现场 + 可行动建议）
                    cacheMissSection(
                        d.cacheMiss,
                        recommendations: d.recommendations,
                        hasSubagents: (d.subagentCount ?? 0) > 0
                    )
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.7))
                    Text(L10n.t(.diagEmpty, lang))
                        .font(.system(size: 10.5))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 14)
                .background(cardSurface)
                .cornerRadius(7)
            }
        }
    }

    private func donutChartView(
        values: [Double],
        colors: [Color],
        centerTop: String,
        centerBottom: String
    ) -> some View {
        let slices = SessionDiagnosticsPolicy.donutSlices(values: values)
        return ZStack {
            if slices.isEmpty {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 11)
            } else {
                ForEach(slices) { slice in
                    let color = slice.id < colors.count ? colors[slice.id] : Color.accentColor
                    Circle()
                        .trim(from: slice.start, to: max(slice.start, slice.end - 0.006))
                        .stroke(color.opacity(0.88), style: StrokeStyle(lineWidth: 11, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                }
            }
            VStack(spacing: 0.5) {
                Text(centerTop)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                Text(centerBottom)
                    .font(.system(size: 8.5))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 78, height: 78)
        .padding(4)
    }

    private func cacheMissSection(
        _ miss: CacheMissSummary,
        recommendations: [String],
        hasSubagents: Bool
    ) -> some View {
        let maxCauseCost = max(0.01, miss.byCause.map(\.extraCostUsd).max() ?? 0.01)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(L10n.t(.diagCacheMissTitle, lang), systemImage: "flame.fill")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(miss.totalMisses > 0 ? .orange : .green)
                Spacer()
                if miss.totalMisses > 0 {
                    Text(L10n.cacheMissSummary(miss.totalMisses, miss.extraCostUsd, miss.wastePctOfTotal, lang))
                        .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(miss.extraCostUsd >= 1.0 ? .red : .orange)
                } else {
                    Text(L10n.t(.diagCacheHealthy, lang))
                        .font(.system(size: 9.5))
                        .foregroundColor(.green)
                }
            }

            if !miss.byCause.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(miss.byCause) { item in
                        let cColor = SessionDiagnosticsPolicy.causeColor(item.cause)
                        let tag = SessionDiagnosticsPolicy.causeControlTag(item.cause, language: lang)
                        let isOptimizable = SessionDiagnosticsPolicy.isOptimizableCause(item.cause)
                        let share = miss.extraCostUsd > 0 ? (item.extraCostUsd / miss.extraCostUsd * 100.0) : 0.0
                        let barRatio = max(0.04, min(1.0, item.extraCostUsd / maxCauseCost))
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 5) {
                                Circle().fill(cColor).frame(width: 6, height: 6)
                                Text(L10n.localizeDiagnosticCause(item.cause, language: lang))
                                    .font(.system(size: 10, weight: .medium))
                                    .lineLimit(1)
                                Text(tag)
                                    .font(.system(size: 8.5, weight: .medium))
                                    .foregroundColor(isOptimizable ? .orange : .secondary)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 0.5)
                                    .background((isOptimizable ? Color.orange : Color.secondary).opacity(0.12))
                                    .cornerRadius(3)
                                Spacer(minLength: 4)
                                Text(L10n.cacheMissCountShare(item.count, share, lang))
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.secondary)
                                Text(String(format: "+$%.2f", item.extraCostUsd))
                                    .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                    .foregroundColor(cColor)
                                    .frame(width: 48, alignment: .trailing)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.primary.opacity(0.06))
                                        .frame(height: 3.5)
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(cColor.opacity(0.85))
                                        .frame(width: max(3, geo.size.width * barRatio), height: 3.5)
                                }
                            }
                            .frame(height: 3.5)
                        }
                    }
                }
            }

            if !miss.topEvents.isEmpty {
                Divider().opacity(0.25)
                let visibleEvents = showMissEvents
                    ? Array(miss.topEvents.prefix(5))
                    : Array(miss.topEvents.prefix(2))
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(visibleEvents) { ev in
                        let cColor = SessionDiagnosticsPolicy.causeColor(ev.cause)
                        HStack(alignment: .top, spacing: 5) {
                            Text(ev.time)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .frame(width: 54, alignment: .leading)
                            VStack(alignment: .leading, spacing: 0.5) {
                                HStack(spacing: 4) {
                                    if hasSubagents, let agent = ev.agentName, !agent.isEmpty {
                                        Text("[\(L10n.localizeAgentLabel(agent, language: lang))]")
                                            .font(.system(size: 8.5, weight: .semibold))
                                            .foregroundColor(.primary.opacity(0.8))
                                    }
                                    Text(L10n.localizeDiagnosticCause(ev.cause, language: lang))
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundColor(cColor)
                                    Text("#\(ev.stepIndex)")
                                        .font(.system(size: 8.5, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                                Text(L10n.localizeDiagnosticDetail(ev.detail, language: lang))
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 4)
                            Text(String(format: "+$%.2f", ev.extraCostUsd))
                                .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                .foregroundColor(cColor)
                                .frame(width: 46, alignment: .trailing)
                        }
                    }
                }
                .padding(.top, 1)

                if miss.topEvents.count > 2 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            showMissEvents.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(showMissEvents ? L10n.t(.diagCollapseEvents, lang) : L10n.diagExpandTopEvents(miss.topEvents.count, lang))
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                            Image(systemName: showMissEvents ? "chevron.up" : "chevron.down")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            if !recommendations.isEmpty {
                Divider().opacity(0.25)
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(Array(recommendations.prefix(3).enumerated()), id: \.offset) { _, rec in
                        HStack(alignment: .top, spacing: 5) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.yellow)
                                .padding(.top, 1.5)
                            Text(L10n.localizeDiagnosticRecommendation(rec, language: lang))
                                .font(.system(size: 9.5))
                                .foregroundColor(.primary.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(cardSurface)
        .cornerRadius(7)
    }

    private func distributionSection(_ d: SessionDiagnosticsPayload) -> some View {
        let isPhases = (distributionTab == .phases)
        let topSources = Array(d.sources.prefix(6))
        let values = isPhases ? d.phases.map(\.pct) : topSources.map(\.pct)
        let colors = isPhases
            ? d.phases.map { SessionDiagnosticsPolicy.phaseColor($0.name) }
            : topSources.map { SessionDiagnosticsPolicy.sourceColor($0.name) }

        return VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Text(L10n.t(.diagDistributionTitle, lang))
                    .font(.system(size: 10.5, weight: .semibold))
                if let subCount = d.subagentCount, subCount > 0 {
                    Text(L10n.diagSubagentCount(subCount, lang))
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundColor(Color.accentColor)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(3)
                }
                Spacer()
                HStack(spacing: 2) {
                    ForEach(DiagnosticDistributionTab.allCases, id: \.self) { tab in
                        let selected = (distributionTab == tab)
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.12)) {
                                distributionTab = tab
                            }
                        }) {
                            Text(tab.title(for: lang))
                                .font(.system(size: 9.5, weight: selected ? .semibold : .regular))
                                .foregroundColor(selected ? .primary : .secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(selected ? Color.primary.opacity(0.1) : Color.clear)
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(1.5)
                .background(Color.primary.opacity(0.04))
                .cornerRadius(5)
            }

            HStack(alignment: .center, spacing: 12) {
                donutChartView(
                    values: values,
                    colors: colors,
                    centerTop: isPhases ? "\(d.turns)" : String(format: "%.0f%%", d.attributedPct),
                    centerBottom: isPhases ? L10n.t(.diagCenterTurns, lang) : L10n.t(.diagCenterAttributed, lang)
                )

                if isPhases {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(d.phases) { phase in
                            let pColor = SessionDiagnosticsPolicy.phaseColor(phase.name)
                            HStack(spacing: 5) {
                                Circle().fill(pColor).frame(width: 6.5, height: 6.5)
                                Text(L10n.localizeDiagnosticPhase(phase.name, language: lang))
                                    .font(.system(size: 10, weight: .medium))
                                    .lineLimit(1)
                                Spacer(minLength: 4)
                                Text(String(format: "%.1f%%", phase.pct))
                                    .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.primary)
                                Text(String(format: "$%.2f", phase.costUsd))
                                    .font(.system(size: 9.5, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 46, alignment: .trailing)
                            }
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 3.5) {
                        ForEach(topSources) { src in
                            let sColor = SessionDiagnosticsPolicy.sourceColor(src.name)
                            HStack(spacing: 5) {
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(sColor)
                                    .frame(width: 6.5, height: 6.5)
                                Text(L10n.localizeDiagnosticSource(src.name, language: lang))
                                    .font(.system(size: 9.5))
                                    .lineLimit(1)
                                Spacer(minLength: 4)
                                Text(String(format: "%.1f%%", src.pct))
                                    .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.primary)
                                Text(SessionDiagnosticsPolicy.compactChars(src.chars))
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 40, alignment: .trailing)
                            }
                        }
                    }
                }
            }

            if let hints = d.bloatHints, !hints.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(hints.prefix(2), id: \.self) { hint in
                        HStack(alignment: .top, spacing: 4) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 8.5))
                                .foregroundColor(.accentColor)
                                .padding(.top, 1.5)
                            Text(L10n.localizeDiagnosticRecommendation(hint, language: lang))
                                .font(.system(size: 9.5))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(8)
        .background(cardSurface)
        .cornerRadius(7)
    }

    private func recommendationsSection(_ recs: [String]) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(L10n.t(.diagRecommendationsTitle, lang), systemImage: "lightbulb.fill")
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundColor(.yellow)
            ForEach(Array(recs.enumerated()), id: \.offset) { idx, rec in
                HStack(alignment: .top, spacing: 5) {
                    Text("\(idx + 1).")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                    Text(L10n.localizeDiagnosticRecommendation(rec, language: lang))
                        .font(.system(size: 10))
                        .foregroundColor(.primary.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(8)
        .background(Color.yellow.opacity(colorScheme == .dark ? 0.08 : 0.1))
        .cornerRadius(7)
    }
}

// MARK: - 8. 用量趋势大图与按模型统计视图 (UsageAnalyticsView)

struct UsageAnalyticsView: View {
    @ObservedObject var store: AGYHubStore
    let onBack: () -> Void

    @AppStorage("agyhub.usage.selectedRange") private var selectedRangeRaw: String = UsageRangeOption.today.rawValue
    @AppStorage("agyhub.usage.metricMode") private var selectedMetricRaw: String = UsageMetricMode.cost.rawValue
    @AppStorage("agyhub.usage.breakdownDimension") private var breakdownDimensionRaw: String = UsageBreakdownDimension.model.rawValue
    @State private var hoveredBarId: String? = nil

    private var selectedRange: UsageRangeOption {
        UsageRangeOption(rawValue: selectedRangeRaw) ?? .today
    }

    private var metricMode: UsageMetricMode {
        UsageMetricMode(rawValue: selectedMetricRaw) ?? .cost
    }

    private var breakdownDimension: UsageBreakdownDimension {
        UsageBreakdownDimension(rawValue: breakdownDimensionRaw) ?? .model
    }

    private var lang: AppLanguage.Resolved {
        store.resolvedLanguage
    }

    private var activeSummary: UsageAnalyticsPolicy.RangeSummary? {
        guard let payload = store.usageHistory else { return nil }
        return UsageAnalyticsPolicy.summarize(payload: payload, range: selectedRange, language: lang)
    }

    private func setRange(_ range: UsageRangeOption) {
        hoveredBarId = nil
        selectedRangeRaw = range.rawValue
    }

    private func setMetric(_ mode: UsageMetricMode) {
        selectedMetricRaw = mode.rawValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            topNavigationRow

            if let summary = activeSummary {
                summaryStrip(summary)
                chartSection(summary)
                modelBreakdownSection(summary)
            } else {
                loadingPlaceholder
            }

            bottomRangeSelector
        }
        .onAppear {
            store.fetchUsageHistory(force: store.usageHistory == nil)
        }
        .onExitCommand {
            onBack()
        }
    }

    private var topNavigationRow: some View {
        HStack(spacing: 8) {
            Button(action: onBack) {
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 9.5, weight: .bold))
                        Text(L10n.t(.backButton, lang))
                            .font(.system(size: 11.5, weight: .medium))
                    }
                    .foregroundColor(Color.accentColor)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Text(selectedRange.shortHeaderTitle(for: lang))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)

                if store.isLoadingUsageHistory {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.68)
                }

                Spacer()

                // 右上角：费用 ($) / Tokens 视图指标切换
                HStack(spacing: 2) {
                    ForEach(UsageMetricMode.allCases) { mode in
                        let isSelected = metricMode == mode
                        Button {
                            withAnimation(.easeInOut(duration: 0.14)) {
                                setMetric(mode)
                            }
                        } label: {
                            Text(mode.title(for: lang))
                            .font(.system(size: 10.5, weight: isSelected ? .semibold : .medium))
                            .foregroundColor(isSelected ? .primary : .secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                                    .fill(isSelected ? Color(nsColor: .controlBackgroundColor) : Color.clear)
                                    .shadow(color: isSelected ? Color.black.opacity(0.08) : .clear, radius: 1, y: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2)
            .background(Color.primary.opacity(0.055))
            .cornerRadius(6)
        }
    }

    private func summaryStrip(_ summary: UsageAnalyticsPolicy.RangeSummary) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(Formatters.formatCost(summary.totalCostUsd))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text("·")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary.opacity(0.45))

            Text("\(Formatters.formatTokens(summary.totalTokens)) Tokens")
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 1) {
                Text(L10n.usageSummaryCacheCalls(cachePct: summary.cachePct, calls: summary.totalCalls, lang))
                    .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                Text(L10n.usageSummaryInOut(inputTokens: summary.inputTokens, outputTokens: summary.outputTokens, lang))
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.75))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.primary.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                )
        )
    }

    private struct ChartSegment: Identifiable {
        let id: String
        let barId: String
        let axisLabel: String
        let modelKey: String
        let modelName: String
        let value: Double
    }

    private func buildChartSegments(for summary: UsageAnalyticsPolicy.RangeSummary) -> [ChartSegment] {
        var result: [ChartSegment] = []
        for bar in summary.bars {
            if bar.models.isEmpty {
                result.append(ChartSegment(
                    id: "\(bar.id)-empty",
                    barId: bar.id,
                    axisLabel: bar.axisLabel,
                    modelKey: "__empty__",
                    modelName: L10n.t(.usageNoModelData, lang),
                    value: 0
                ))
            } else {
                // 先放主模型或按名称稳定排序，使堆叠顺序上下一致
                for m in bar.models {
                    let val = metricMode == .cost ? m.costUsd : Double(m.totalTokens)
                    result.append(ChartSegment(
                        id: "\(bar.id)-\(m.model)",
                        barId: bar.id,
                        axisLabel: bar.axisLabel,
                        modelKey: m.model,
                        modelName: m.displayName,
                        value: val
                    ))
                }
            }
        }
        return result
    }

    @ViewBuilder
    private func chartSection(_ summary: UsageAnalyticsPolicy.RangeSummary) -> some View {
        let segments = buildChartSegments(for: summary)
        let ticks = UsageAnalyticsPolicy.xAxisTickLabels(for: summary.bars, range: selectedRange)
        let hoveredBar = summary.bars.first(where: { $0.id == hoveredBarId })

        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                if let bar = hoveredBar {
                    Text(bar.detailTitle)
                        .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)
                    Text(L10n.usageBarHoverSummary(cost: bar.costUsd, tokens: bar.totalTokens, calls: bar.calls, lang))
                        .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.accentColor)
                    if let topModel = bar.models.first {
                        Text("(\(topModel.displayName))")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                } else {
                    Text(L10n.usageChartPrompt(isToday: selectedRange == .today, lang))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.85))
                }
                Spacer(minLength: 0)
            }
            .frame(height: 15)

            Chart(segments) { seg in
                if seg.modelKey == "__empty__" {
                    BarMark(
                        x: .value("Time", seg.axisLabel),
                        y: .value("Usage", 0)
                    )
                } else {
                    BarMark(
                        x: .value("Time", seg.axisLabel),
                        y: .value("Usage", seg.value)
                    )
                    .foregroundStyle(UsageAnalyticsPolicy.accentColor(for: seg.modelKey))
                    .opacity(hoveredBarId == nil || hoveredBarId == seg.barId ? 1.0 : 0.45)
                }

                if let bar = hoveredBar, bar.id == seg.barId {
                    RuleMark(x: .value("Time", bar.axisLabel))
                        .foregroundStyle(Color.primary.opacity(0.14))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 2]))
                }
            }
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks(values: ticks) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                        .foregroundStyle(Color.primary.opacity(0.06))
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.secondary.opacity(0.85))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                        .foregroundStyle(Color.primary.opacity(0.08))
                    AxisValueLabel {
                        if let num = value.as(Double.self) {
                            Text(metricMode == .cost ? Formatters.formatCost(num) : Formatters.formatTokens(Int(num)))
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.secondary.opacity(0.80))
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(let loc):
                                let origin = geo[proxy.plotAreaFrame].origin
                                let xPos = loc.x - origin.x
                                guard xPos >= 0, xPos <= proxy.plotAreaSize.width,
                                      let axisLabel = proxy.value(atX: xPos, as: String.self),
                                      let matched = summary.bars.first(where: { $0.axisLabel == axisLabel }) else {
                                    hoveredBarId = nil
                                    return
                                }
                                if hoveredBarId != matched.id {
                                    hoveredBarId = matched.id
                                }
                            case .ended:
                                hoveredBarId = nil
                            }
                        }
                }
            }
            .frame(minHeight: 148, idealHeight: 165, maxHeight: 220)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.025))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                )
        )
    }

    @ViewBuilder
    private func modelBreakdownSection(_ summary: UsageAnalyticsPolicy.RangeSummary) -> some View {
        let sortedModels = UsageAnalyticsPolicy.sortedModels(summary.models, by: metricMode)
        let sortedConversations = UsageAnalyticsPolicy.sortedConversations(summary.conversations, by: metricMode)
        let activeCount = breakdownDimension == .model ? sortedModels.count : sortedConversations.count

        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                HStack(spacing: 2) {
                    ForEach(UsageBreakdownDimension.allCases) { dim in
                        let isSelected = breakdownDimension == dim
                        Button {
                            withAnimation(.easeInOut(duration: 0.14)) {
                                breakdownDimensionRaw = dim.rawValue
                            }
                        } label: {
                            Text(dim.title(for: lang))
                                .font(.system(size: 10.5, weight: isSelected ? .semibold : .medium))
                                .foregroundColor(isSelected ? .primary : .secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                                        .fill(isSelected ? Color(nsColor: .controlBackgroundColor) : Color.clear)
                                        .shadow(color: isSelected ? Color.black.opacity(0.08) : .clear, radius: 1, y: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(2)
                .background(Color.primary.opacity(0.055))
                .cornerRadius(6)

                Spacer()

                Text(L10n.usageBreakdownHeader(metric: metricMode, dimension: breakdownDimension, count: activeCount, lang))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.8))
            }

            if activeCount == 0 {
                VStack(spacing: 4) {
                    Spacer(minLength: 8)
                    Text(L10n.t(.usageEmptyRecord, lang))
                        .font(.system(size: 11.5))
                        .foregroundColor(.secondary)
                    Spacer(minLength: 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 4) {
                        if breakdownDimension == .model {
                            ForEach(sortedModels) { row in
                                modelStatRow(row)
                            }
                        } else {
                            ForEach(sortedConversations) { conv in
                                conversationStatRow(conv)
                            }
                        }
                    }
                    .padding(.vertical, 1)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func modelStatRow(_ row: UsageAnalyticsPolicy.ModelSummaryRow) -> some View {
        let color = UsageAnalyticsPolicy.accentColor(for: row.model)
        let pct = metricMode == .cost ? row.costSharePct : row.tokenSharePct
        return breakdownStatCard(
            color: color,
            title: row.displayName,
            badgeText: nil,
            pct: pct,
            costUsd: row.costUsd,
            metricSummary: L10n.usageModelMetricSummary(tokens: row.totalTokens, calls: row.calls, cachePct: row.cachePct, lang)
        )
    }

    private func conversationStatRow(_ conv: UsageAnalyticsPolicy.ConversationSummaryRow) -> some View {
        let color = UsageAnalyticsPolicy.accentColor(for: conv.topModel)
        let pct = metricMode == .cost ? conv.costSharePct : conv.tokenSharePct
        let cleanTitle = SessionTitleCleaner.cleanTitle(conv.title, fallbackUUID: conv.uuid, language: lang)
        let badge: String? = {
            var parts: [String] = []
            if conv.clientType.lowercased() == "cli" { parts.append("CLI") }
            if conv.subagentCount > 0 { parts.append(L10n.usageConversationSubagentBadge(conv.subagentCount, lang)) }
            return parts.isEmpty ? nil : parts.joined(separator: "·")
        }()
        return breakdownStatCard(
            color: color,
            title: cleanTitle,
            badgeText: badge,
            pct: pct,
            costUsd: conv.costUsd,
            metricSummary: L10n.usageConversationMetricSummary(topModel: conv.topModelDisplay, tokens: conv.totalTokens, calls: conv.calls, cachePct: conv.cachePct, lang)
        )
    }

    private func breakdownStatCard(
        color: Color,
        title: String,
        badgeText: String?,
        pct: Double,
        costUsd: Double,
        metricSummary: String
    ) -> some View {
        let progressRatio = min(max(pct / 100.0, 0.0), 1.0)

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 7, height: 7)

                Text(title)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if let badgeText = badgeText {
                    Text(badgeText)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4.5)
                        .padding(.vertical, 1)
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(3.5)
                }

                Spacer(minLength: 6)

                Text(String(format: "%.1f%%", pct))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)

                Text(Formatters.formatCost(costUsd))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .frame(minWidth: 50, alignment: .trailing)
            }

            HStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.06))
                        Capsule()
                            .fill(color.opacity(0.85))
                            .frame(width: max(3, geo.size.width * progressRatio))
                    }
                }
                .frame(height: 4)

                Text(metricSummary)
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.85))
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.primary.opacity(0.028))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.05), lineWidth: 0.5)
                )
        )
    }

    private var bottomRangeSelector: some View {
        HStack(spacing: 3) {
            ForEach(UsageRangeOption.allCases) { option in
                let isSelected = selectedRange == option
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        setRange(option)
                    }
                } label: {
                    Text(option.title(for: lang))
                        .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 5.5, style: .continuous)
                                .fill(isSelected ? Color(nsColor: .controlBackgroundColor) : Color.clear)
                                .shadow(color: isSelected ? Color.black.opacity(0.08) : .clear, radius: 1.5, y: 0.5)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.primary.opacity(0.055))
        .cornerRadius(7.5)
    }

    private var loadingPlaceholder: some View {
        VStack(spacing: 8) {
            Spacer()
            ProgressView()
                .controlSize(.regular)
            Text(L10n.t(.usageLoadingHistory, lang))
                .font(.system(size: 11.5))
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


// MARK: - 品牌矢量图标 (方案 3 同源半边脸拽猫 — Menu Bar 三态纯图标)

extension AGYAppDelegate {
    /// 顶部 Menu Bar 仅展示这只小猫的三态表情（不展示速度与金额文字，悬停通过 Tooltip 查看详情）
    enum HakimiBrandIcon {
        enum Status: Equatable {
            case idle     // 待命：双目微闭小憩
            case working  // 工作中：左眼斜压紧眯 + 右眼冷瞪（方案 3 同源监工神态）+ 翠绿微点
            case alert    // 告警：双目警觉睁大 + 醒目红点
        }

        static func resolveStatus(hasAlert: Bool, activeCount: Int) -> Status {
            if hasAlert { return .alert }
            if activeCount > 0 { return .working }
            return .idle
        }

        /// 生成 macOS 原生极简 18×18pt 实心剪影小猫图标（负空间镂空眼神：待命闭眼 / 工作中左眯右瞪 / 告警睁眼+红点）
        static func menuBarImage(state: Status) -> NSImage {
            let size = NSSize(width: 18, height: 18)
            let image = NSImage(size: size, flipped: true) { _ in
                // 坐标系从 22×22 精准缩放到 18×18，保持宽润饱满的猫头比例
                let scale = 18.0 / 22.0
                guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
                ctx.saveGState()
                ctx.scaleBy(x: scale, y: scale)

                let baseColor: NSColor = (state == .alert) ? NSColor.labelColor : NSColor.black
                baseColor.setFill()

                // 1. 饱满圆润的极简猫头剪影
                let head = NSBezierPath()
                head.move(to: NSPoint(x: 3.0, y: 12.2))
                head.line(to: NSPoint(x: 3.4, y: 4.4))
                head.curve(to: NSPoint(x: 5.3, y: 3.5), controlPoint1: NSPoint(x: 3.4, y: 3.4), controlPoint2: NSPoint(x: 4.5, y: 2.9))
                head.line(to: NSPoint(x: 8.6, y: 6.4))
                head.curve(to: NSPoint(x: 13.4, y: 6.4), controlPoint1: NSPoint(x: 9.6, y: 6.0), controlPoint2: NSPoint(x: 12.4, y: 6.0))
                head.line(to: NSPoint(x: 16.7, y: 3.5))
                head.curve(to: NSPoint(x: 18.6, y: 4.4), controlPoint1: NSPoint(x: 17.5, y: 2.9), controlPoint2: NSPoint(x: 18.6, y: 3.4))
                head.line(to: NSPoint(x: 19.0, y: 12.2))
                head.curve(to: NSPoint(x: 11.0, y: 19.2), controlPoint1: NSPoint(x: 19.3, y: 16.6), controlPoint2: NSPoint(x: 15.8, y: 19.2))
                head.curve(to: NSPoint(x: 3.0, y: 12.2), controlPoint1: NSPoint(x: 6.2, y: 19.2), controlPoint2: NSPoint(x: 2.7, y: 16.6))
                head.close()
                head.fill()

                // 2. 使用 .clear 负空间精确镂空三态眼神
                ctx.setBlendMode(.clear)
                NSColor.black.setStroke()
                NSColor.black.setFill()

                switch state {
                case .idle:
                    // 待命：两道温柔微弯闭眼弧线
                    let lEye = NSBezierPath()
                    lEye.move(to: NSPoint(x: 6.2, y: 12.2))
                    lEye.curve(to: NSPoint(x: 9.6, y: 12.2), controlPoint1: NSPoint(x: 7.4, y: 13.4), controlPoint2: NSPoint(x: 8.6, y: 13.4))
                    lEye.lineWidth = 1.65
                    lEye.lineCapStyle = .round
                    lEye.stroke()

                    let rEye = NSBezierPath()
                    rEye.move(to: NSPoint(x: 12.4, y: 12.2))
                    rEye.curve(to: NSPoint(x: 15.8, y: 12.2), controlPoint1: NSPoint(x: 13.4, y: 13.4), controlPoint2: NSPoint(x: 14.6, y: 13.4))
                    rEye.lineWidth = 1.65
                    rEye.lineCapStyle = .round
                    rEye.stroke()

                case .working:
                    // 工作中：标志性不对称「左眼斜眯 + 右眼圆瞪」
                    let lSquint = NSBezierPath()
                    lSquint.move(to: NSPoint(x: 5.8, y: 11.4))
                    lSquint.line(to: NSPoint(x: 9.8, y: 12.6))
                    lSquint.lineWidth = 1.85
                    lSquint.lineCapStyle = .round
                    lSquint.stroke()

                    NSBezierPath(ovalIn: NSRect(x: 12.55, y: 10.55, width: 3.5, height: 3.1)).fill()

                case .alert:
                    // 告警：双目圆睁
                    NSBezierPath(ovalIn: NSRect(x: 5.95, y: 10.35, width: 3.5, height: 3.5)).fill()
                    NSBezierPath(ovalIn: NSRect(x: 12.55, y: 10.35, width: 3.5, height: 3.5)).fill()
                }

                // 3. 告警态右耳尖醒目红点
                if state == .alert {
                    ctx.setBlendMode(.normal)
                    NSColor(calibratedRed: 0.937, green: 0.267, blue: 0.267, alpha: 1.0).setFill()
                    NSBezierPath(ovalIn: NSRect(x: 15.4, y: 1.4, width: 5.6, height: 5.6)).fill()
                }

                ctx.restoreGState()
                return true
            }
            // 待命与工作中启用 macOS 原生 Template 模式（自动完美适配亮/暗菜单栏），告警保留红点色彩
            image.isTemplate = (state != .alert)
            return image
        }

        /// 生成悬停 Tooltip 文本（剥离状态圆点 emoji，保留清晰信息）
        static func formatTooltip(_ raw: String, language: AppLanguage.Resolved) -> String {
            var s = L10n.localizeMenubarText(raw, language: language)
            for prefix in ["🟢 ", "🟡 ", "🔴 ", "🟠 ", "⚪ ", "🟢", "🟡", "🔴", "🟠", "⚪"] {
                if s.hasPrefix(prefix) {
                    s = String(s.dropFirst(prefix.count))
                    break
                }
            }
            let trimmed = s.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? "Agyhub" : "Agyhub · \(trimmed)"
        }
    }
}
