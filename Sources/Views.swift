import AppKit
import Charts
import SwiftUI

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

    var toggled: AccountTargetMode {
        self == .app ? .cli : .app
    }
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

enum MainDashboardWindowChrome {
    @ViewBuilder
    static func apply<Content: View>(to content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(WindowLifecycleConfigurator())
            .background(
                ZStack {

                    VisualEffectBlurView(material: .hudWindow, blendingMode: .behindWindow)

                    Color(nsColor: .windowBackgroundColor).opacity(0.90)

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

                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(0.40), lineWidth: 0.75)
            )
            .ignoresSafeArea()
    }
}

struct HakimiHeaderLogoView: View {
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

struct DashboardHeaderBarView: View {
    static let showsTodayPillInHeader = true
    static let showsLeadingLogoOnTodayPill = false

    var stats: TodayStats = .empty
    let hasAlert: Bool
    var isUsageOpen: Bool = false
    let isStandaloneWindow: Bool
    let lang: AppLanguage.Resolved
    let refreshSpinCount: Int
    var outerHorizontalPadding: CGFloat = 12
    var onToggleUsage: () -> Void = {}
    let onRefresh: () -> Void
    let onOpenStandalone: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 6) {
                HakimiHeaderLogoView()
                Text("Agyhub")
                    .font(.system(size: 14.5, weight: .bold))
                    .lineLimit(1)

                Circle()
                    .fill(hasAlert ? Color.red : Color.green)
                    .frame(width: 6, height: 6)
                    .shadow(color: (hasAlert ? Color.red : Color.green).opacity(0.55), radius: 2.5)
            }
            .fixedSize(horizontal: true, vertical: true)

            HStack(spacing: 0) {
                Spacer(minLength: 2)

                TodayUsagePillButton(
                    stats: stats,
                    isUsageOpen: isUsageOpen,
                    lang: lang,
                    onToggleUsage: onToggleUsage
                )

                Spacer(minLength: 2)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .contentShape(Rectangle())
            .background(WindowDragArea())

            HStack(spacing: 6) {
                ImpeccableIconButton(
                    icon: "arrow.clockwise",
                    tooltip: L10n.t(.refreshDataTooltip, lang),
                    size: 26,
                    iconSize: 12,
                    spinTrigger: refreshSpinCount
                ) {
                    onRefresh()
                }

                if !isStandaloneWindow {
                    ImpeccableIconButton(
                        icon: "macwindow.on.rectangle",
                        tooltip: L10n.t(.openStandaloneTooltip, lang),
                        size: 26,
                        iconSize: 12
                    ) {
                        onOpenStandalone()
                    }
                }

                ImpeccableIconButton(
                    icon: "xmark",
                    tooltip: WindowClosePolicy.headerCloseTooltip(language: lang),
                    hoverTint: .red,
                    hoverFill: Color.red.opacity(0.12),
                    size: 26,
                    iconSize: 12
                ) {
                    onClose()
                }
            }
            .fixedSize(horizontal: true, vertical: true)
        }
        .padding(.horizontal, outerHorizontalPadding)
        .padding(.vertical, 7)
    }
}

struct DashboardFooterBarView: View {
    static let showsTodayPillInFooter = false

    let lastUpdatedTimeStr: String
    var stats: TodayStats = .empty
    var isUsageOpen: Bool = false
    let lang: AppLanguage.Resolved
    var horizontalPadding: CGFloat = 12
    var onToggleUsage: () -> Void = {}
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            ViewThatFits(in: .horizontal) {
                Text(L10n.updatedAt(lastUpdatedTimeStr, lang))
                    .font(.system(size: 10.5, design: .monospaced).monospacedDigit())
                    .foregroundColor(Color.primary.opacity(0.62))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: true)

                Text(lastUpdatedTimeStr)
                    .font(.system(size: 10.5, design: .monospaced).monospacedDigit())
                    .foregroundColor(Color.primary.opacity(0.62))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: true)
            }

            Spacer(minLength: 4)

            ImpeccableIconButton(
                icon: "gearshape",
                tooltip: L10n.t(.settingsTitle, lang),
                tint: Color.primary.opacity(0.65),
                hoverTint: Color.primary,
                size: 26,
                iconSize: 12.5
            ) {
                onOpenSettings()
            }
            .fixedSize(horizontal: true, vertical: true)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 6)
    }
}

struct TodayUsagePillButton: View {
    static let closedChevronSystemName = "chevron.down"
    static let openChevronSystemName = "chevron.up"
    static let usesElevatedCrispSurface = true

    let stats: TodayStats
    let isUsageOpen: Bool
    let lang: AppLanguage.Resolved
    let onToggleUsage: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false

    var body: some View {
        Button {
            onToggleUsage()
        } label: {
            ViewThatFits(in: .horizontal) {
                pillContent(
                    showTitle: true,
                    showCost: true,
                    showTokens: true,
                    horizontalPadding: 7
                )
                pillContent(
                    showTitle: false,
                    showCost: true,
                    showTokens: true,
                    horizontalPadding: 9
                )
                pillContent(
                    showTitle: false,
                    showCost: true,
                    showTokens: false,
                    horizontalPadding: 9
                )
                pillContent(
                    showTitle: true,
                    showCost: false,
                    showTokens: false,
                    horizontalPadding: 8
                )
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .help(L10n.todayPillTooltip(cost: stats.costUsd, totalTokens: stats.totalTokens, cachePct: stats.cachePct, lang))
    }

    private func pillContent(
        showTitle: Bool,
        showCost: Bool,
        showTokens: Bool,
        horizontalPadding: CGFloat
    ) -> some View {
        let fillColor: Color = {
            if isUsageOpen {
                return colorScheme == .dark
                    ? Color.accentColor.opacity(0.20)
                    : Color.accentColor.opacity(0.11)
            }
            if colorScheme == .dark {
                return Color(nsColor: .controlBackgroundColor).opacity(isHovered ? 1.0 : 0.88)
            }
            return Color.white.opacity(isHovered ? 1.0 : 0.94)
        }()

        let borderColor: Color = {
            if isUsageOpen {
                return Color.accentColor.opacity(0.42)
            }
            if colorScheme == .dark {
                return Color.white.opacity(isHovered ? 0.22 : 0.14)
            }
            return Color.black.opacity(isHovered ? 0.14 : 0.08)
        }()

        let tokenInkColor: Color = colorScheme == .dark
            ? Color.white.opacity(0.84)
            : Color(red: 0.22, green: 0.29, blue: 0.39)

        let badgeFill: Color = isUsageOpen
            ? Color.accentColor.opacity(colorScheme == .dark ? 0.28 : 0.18)
            : Color.accentColor.opacity(colorScheme == .dark ? 0.20 : 0.11)

        return HStack(spacing: 5.5) {
            if showTitle {
                Text(L10n.t(.headerTodayLabel, lang))
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(Color.accentColor)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(badgeFill)
                    )
            }

            if showCost {
                Text(Formatters.formatCost(stats.costUsd))
                    .font(.system(size: 12, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }

            if showCost && showTokens {
                Text("·")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.primary.opacity(0.28))
                    .lineLimit(1)
            }

            if showTokens {
                Text(Formatters.formatTokens(stats.totalTokens))
                    .font(.system(size: 11, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundColor(tokenInkColor)
                    .lineLimit(1)
            }

            Image(systemName: isUsageOpen ? Self.openChevronSystemName : Self.closedChevronSystemName)
                .font(.system(size: 8.5, weight: .bold))
                .foregroundColor(Color.accentColor.opacity(isUsageOpen || isHovered ? 1.0 : 0.72))
                .padding(.trailing, 1)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 3.5)
        .fixedSize(horizontal: true, vertical: true)
        .background(
            Capsule()
                .fill(fillColor)
                .overlay(
                    Capsule()
                        .strokeBorder(borderColor, lineWidth: 0.65)
                )
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.24 : (isHovered ? 0.08 : 0.045)),
            radius: isHovered ? 4 : 2.5,
            y: 1
        )
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .animation(.easeOut(duration: 0.15), value: isUsageOpen)
        .contentShape(Capsule())
    }
}

struct MainDashboardView: View {
    @ObservedObject var store: AGYHubStore
    var isStandaloneWindow: Bool = false

    @AppStorage("agyhub.collapse.sessions") private var isSessionsCollapsed = false
    @AppStorage("agyhub.collapse.telemetry") private var isTelemetryCollapsed = false
    @AppStorage("agyhub.telemetry.range") private var selectedTelemetryRangeRaw: String = TelemetryTimeRange.threeMinutes.rawValue
    @AppStorage(DashboardSplitLayoutPolicy.splitFractionDefaultsKey) private var storedSplitFraction: Double = -1
    @State private var accountTargetMode: AccountTargetMode = .app
    @State private var isAccountPickerOpen = false
    @State private var accountCardFrame: CGRect = .zero
    @State private var refreshSpinCount: Int = 0
    @State private var containerWidth: CGFloat = 464
    @State private var hoveredSessionSeriesIds: Set<String> = []
    @State private var hoveredChartAgentId: String? = nil
    @State private var dragStartTelemetryHeight: CGFloat? = nil
    @State private var liveDragTelemetryFraction: CGFloat? = nil

    @State private var showCreateProfileSheet = false
    @State private var showSettingsPopover = false
    @State private var showLogsSheet = false
    @State private var newProfileName = ""
    @State private var newProfileNotes = ""
    @State private var newProfileDataDir = ""

    private var lang: AppLanguage.Resolved {
        store.resolvedLanguage
    }

    private var layoutMetrics: DashboardAdaptiveLayoutMetrics {
        DashboardAdaptiveLayoutMetrics.metrics(forWidth: containerWidth)
    }

    var body: some View {
        let metrics = layoutMetrics
        return MainDashboardWindowChrome.apply(to:
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {

                headerBar

                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 0.5)

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
                    .padding(.horizontal, metrics.outerHorizontalPadding)
                    .padding(.vertical, 8)
                    .transition(.opacity)
                } else {
                    VStack(spacing: 8) {

                        profileManagerSection

                        Rectangle()
                            .fill(Color(nsColor: .separatorColor).opacity(0.35))
                            .frame(height: 0.5)
                            .padding(.horizontal, metrics.sectionHeaderHorizontalPadding)

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
                            dashboardSplitPaneContent(metrics: metrics)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.horizontal, metrics.outerHorizontalPadding)
                    .padding(.vertical, 8)
                }

                Rectangle()
                    .fill(Color(nsColor: .separatorColor).opacity(0.35))
                    .frame(height: 0.5)

                footerBar
            }

            if isAccountPickerOpen && !store.isUsageDashboardPresented {
                accountPickerDismissScrimAndOverlay
            }

            if showSettingsPopover {
                settingsDismissScrimAndOverlay
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        if geo.size.width > 0 {
                            containerWidth = geo.size.width
                        }
                    }
                    .onChange(of: geo.size.width) { newWidth in
                        if newWidth > 0 {
                            containerWidth = newWidth
                        }
                    }
            }
        )
        .coordinateSpace(name: "dashboardRoot")
        .onPreferenceChange(AccountCardFramePreferenceKey.self) { frame in
            if frame.width > 0 {
                accountCardFrame = frame
            }
        }
        .onChange(of: store.isUsageDashboardPresented) { open in
            if open {
                isAccountPickerOpen = false
            }
        }
        .onChange(of: store.expandedSessionRowLimit) { _ in
            storedSplitFraction = -1
            liveDragTelemetryFraction = nil
            dragStartTelemetryHeight = nil
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
    }

    private var headerBar: some View {
        DashboardHeaderBarView(
            stats: store.payload.todayStats,
            hasAlert: store.payload.hasAlert,
            isUsageOpen: store.isUsageDashboardPresented,
            isStandaloneWindow: isStandaloneWindow,
            lang: lang,
            refreshSpinCount: refreshSpinCount,
            outerHorizontalPadding: layoutMetrics.outerHorizontalPadding,
            onToggleUsage: {
                withAnimation(.easeInOut(duration: 0.16)) {
                    store.toggleUsageDashboard()
                }
            },
            onRefresh: {
                refreshSpinCount += 1
                store.fetchMonitorData()
                store.refreshQuotasIfNeeded(force: true)
                store.refreshRecent503IfNeeded(force: true)
                if store.isUsageDashboardPresented {
                    store.fetchUsageHistory(force: true)
                }
            },
            onOpenStandalone: {
                AGYAppDelegate.shared?.openStandaloneWindow()
            },
            onClose: {
                if let delegate = AGYAppDelegate.shared {
                    delegate.closeWindow(isStandaloneWindow: isStandaloneWindow)
                } else {
                    NSApp.keyWindow?.orderOut(nil)
                }
            }
        )
    }

    private var profileManagerSection: some View {
        let effectiveTargetMode = store.isCLIIndependentMode ? accountTargetMode : .app
        let snapshot = AccountCompactSummaryPolicy.resolveActiveAccount(
            mode: effectiveTargetMode,
            isCLIIndependentMode: store.isCLIIndependentMode,
            profiles: store.profiles,
            expectedAppEmail: store.expectedAppEmail,
            appStorageEmail: store.appStorageEmail,
            sharedKeychainEmail: store.sharedKeychainResolution.email,
            activeProfileName: store.activeProfileName,
            activeCLIProfileName: store.activeCLIProfileName,
            accountQuotas: store.accountQuotas,
            expiredQuotaEmails: store.expiredQuotaEmails,
            language: lang
        )

        return AccountSummaryCardView(
            targetMode: $accountTargetMode,
            isCLIIndependentMode: store.isCLIIndependentMode,
            snapshot: snapshot,
            hasSharedKeychainMismatch: store.hasSharedKeychainMismatch,
            isCLIVaultAuthorized: store.isCLIVaultAuthorized,
            isPickerOpen: isAccountPickerOpen,
            horizontalPadding: layoutMetrics.accountCardHorizontalPadding,
            onTogglePicker: {
                withAnimation(.easeOut(duration: 0.16)) {
                    isAccountPickerOpen.toggle()
                }
            },
            onRefreshQuota: {
                store.refreshQuotasIfNeeded(force: true)
            }
        )
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: AccountCardFramePreferenceKey.self,
                        value: geo.frame(in: .named("dashboardRoot"))
                    )
            }
        )
    }

    private func closeAccountPicker() {
        if isAccountPickerOpen {
            withAnimation(.easeOut(duration: 0.14)) {
                isAccountPickerOpen = false
            }
        }
    }

    @ViewBuilder
    private var settingsDismissScrimAndOverlay: some View {
        ZStack {
            Color.black.opacity(0.22)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.16)) {
                        showSettingsPopover = false
                    }
                }

            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor))
                    .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .onTapGesture {}

                SettingsPopoverView(store: store, onClose: {
                    withAnimation(.easeOut(duration: 0.16)) {
                        showSettingsPopover = false
                    }
                })
            }
            .fixedSize(horizontal: false, vertical: true)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.75)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color.black.opacity(0.22), radius: 18, y: 6)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
        .zIndex(20)
    }

    @ViewBuilder
    private var accountPickerDismissScrimAndOverlay: some View {
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
        let cardWidth = accountCardFrame.width > 0 ? accountCardFrame.width : nil
        let topCutout = max(0, accountCardFrame.minY)
        let bottomAnchor = accountCardFrame.maxY > 0 ? accountCardFrame.maxY : 80

        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                if topCutout > 0 {
                    Color.black.opacity(0.06)
                        .frame(height: topCutout)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture { closeAccountPicker() }
                }
                Spacer()
                    .frame(height: max(0, bottomAnchor - topCutout))
                Color.black.opacity(0.10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture { closeAccountPicker() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            Button("") {
                closeAccountPicker()
            }
            .keyboardShortcut(.escape, modifiers: [])
            .frame(width: 0, height: 0)
            .opacity(0)

            AccountSwitcherOverlayView(
                store: store,
                mode: effectiveTargetMode,
                sortedProfiles: sortedProfiles,
                effectiveAppEmail: effectiveAppEmail,
                isAppResolved: isAppResolved,
                onSelectProfile: { profile, isAlreadyActive in
                    if !isAlreadyActive {
                        if effectiveTargetMode == .app {
                            store.switchToProfile(profile)
                        } else {
                            store.switchCLIProfile(profile)
                        }
                    }
                    closeAccountPicker()
                },
                onRefreshQuota: {
                    store.refreshQuotasIfNeeded(force: true)
                },
                onClose: {
                    closeAccountPicker()
                }
            )
            .frame(width: cardWidth)
            .offset(x: accountCardFrame.minX, y: bottomAnchor + 6)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

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

    @ViewBuilder
    private func dashboardSplitPaneContent(metrics: DashboardAdaptiveLayoutMetrics) -> some View {
        let displayCount = SessionListFilter.sessionsForDisplay(store.payload.sessions).count

        if !isTelemetryCollapsed && !isSessionsCollapsed {
            GeometryReader { splitGeo in
                let totalH = max(0, splitGeo.size.height)
                let activeFraction = liveDragTelemetryFraction ?? CGFloat(storedSplitFraction)
                let alloc = DashboardSplitLayoutPolicy.resolveAllocation(
                    totalAvailableHeight: totalH,
                    storedFraction: activeFraction,
                    displaySessionsCount: displayCount,
                    expandedSessionRowLimit: store.expandedSessionRowLimit
                )

                VStack(spacing: 0) {
                    LiveTelemetryOverviewCardView(
                        samples: store.liveTelemetrySamples,
                        todayStats: store.payload.todayStats,
                        isCollapsedExternal: $isTelemetryCollapsed,
                        cardHorizontalPadding: metrics.telemetryCardHorizontalPadding,
                        plotHorizontalPadding: metrics.telemetryPlotHorizontalPadding,
                        highlightedSeriesIds: hoveredSessionSeriesIds,
                        minPlotHeight: DashboardSplitLayoutPolicy.splitMinPlotHeight,
                        pinnedFamilyByRoot: store.telemetryFamilyByRoot,
                        timelineAnchorDate: store.telemetryTimelineAnchor,
                        onHoverChartAgent: { agentId in
                            if hoveredChartAgentId != agentId {
                                hoveredChartAgentId = agentId
                            }
                        }
                    )
                    .frame(height: alloc.telemetryHeight > 0 ? alloc.telemetryHeight : nil, alignment: .top)
                    .clipped()

                    SplitPaneDividerBar(
                        showsSeparatorLine: true,
                        tooltip: L10n.t(.splitResizeTooltip, lang),
                        onDragBegan: {
                            dragStartTelemetryHeight = alloc.telemetryHeight
                        },
                        onDragChanged: { deltaY in
                            let base = dragStartTelemetryHeight ?? alloc.telemetryHeight
                            liveDragTelemetryFraction = DashboardSplitLayoutPolicy.updatedFractionAfterDrag(
                                startTelemetryHeight: base,
                                dragDeltaY: deltaY,
                                totalAvailableHeight: totalH
                            )
                        },
                        onDragEnded: { deltaY in
                            let base = dragStartTelemetryHeight ?? alloc.telemetryHeight
                            let committed = DashboardSplitLayoutPolicy.updatedFractionAfterDrag(
                                startTelemetryHeight: base,
                                dragDeltaY: deltaY,
                                totalAvailableHeight: totalH
                            )
                            storedSplitFraction = Double(committed)
                            liveDragTelemetryFraction = nil
                            dragStartTelemetryHeight = nil
                        },
                        onDoubleClick: {
                            withAnimation(.easeOut(duration: 0.18)) {
                                storedSplitFraction = -1
                                liveDragTelemetryFraction = nil
                                dragStartTelemetryHeight = nil
                            }
                        }
                    )
                    .frame(height: alloc.dividerHeight)
                    .padding(.horizontal, metrics.telemetryCardHorizontalPadding)

                    activeSessionsSection(
                        allocatedHeight: alloc.sessionsHeight > 0 ? alloc.sessionsHeight : nil
                    )
                }
                .frame(width: splitGeo.size.width, height: splitGeo.size.height, alignment: .top)
            }
        } else {
            VStack(spacing: 8) {
                LiveTelemetryOverviewCardView(
                    samples: store.liveTelemetrySamples,
                    todayStats: store.payload.todayStats,
                    isCollapsedExternal: $isTelemetryCollapsed,
                    cardHorizontalPadding: metrics.telemetryCardHorizontalPadding,
                    plotHorizontalPadding: metrics.telemetryPlotHorizontalPadding,
                    highlightedSeriesIds: hoveredSessionSeriesIds,
                    pinnedFamilyByRoot: store.telemetryFamilyByRoot,
                    timelineAnchorDate: store.telemetryTimelineAnchor,
                    onHoverChartAgent: { agentId in
                        if hoveredChartAgentId != agentId {
                            hoveredChartAgentId = agentId
                        }
                    }
                )
                .frame(maxHeight: !isTelemetryCollapsed ? .infinity : nil)

                activeSessionsSection(allocatedHeight: nil)

                if isSessionsCollapsed {
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private func activeSessionsSection(
        allocatedHeight: CGFloat?
    ) -> some View {
        VStack(alignment: .leading, spacing: SessionListLayoutPolicy.headerToListSpacing) {
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

                let count503 = store.recent503Count
                if Recent503Policy.shouldShowBadge(count: count503) {
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
                }

                Spacer(minLength: 8)

                if !store.payload.sessions.isEmpty {
                    let displayedCount = SessionListFilter.sessionsForDisplay(store.payload.sessions).count
                    Text(L10n.sessionsCount(displayedCount, lang))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.primary.opacity(0.65))
                        .padding(.trailing, 2)
                }
            }
            .frame(height: SessionListLayoutPolicy.headerHeight)
            .padding(.horizontal, layoutMetrics.sectionHeaderHorizontalPadding)

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
                    let displaySessions = SessionListFilter.sessionsForDisplay(store.payload.sessions)
                    let telemetryRange = TelemetryTimeRange.resolved(from: selectedTelemetryRangeRaw)
                    let referenceDate = max(Date(), store.liveTelemetrySamples.last?.timestamp ?? Date())
                    let anchorDate = store.telemetryTimelineAnchor ?? store.liveTelemetrySamples.first?.timestamp
                    let windowSamples = LiveTelemetryPolicy.visibleChartSamples(
                        in: telemetryRange,
                        from: store.liveTelemetrySamples,
                        anchorDate: anchorDate,
                        now: referenceDate
                    )
                    let seriesList = LiveTelemetryPolicy.agentSeries(
                        in: windowSamples,
                        colorAnchorSamples: store.liveTelemetrySamples,
                        pinnedFamilyByRoot: store.telemetryFamilyByRoot
                    )
                    let sessionColorLinks = LiveTelemetryPolicy.sessionColorLinks(
                        sessions: displaySessions,
                        seriesList: seriesList
                    )
                    let highlightedSessionId = LiveTelemetryPolicy.matchingSessionId(
                        forAgentId: hoveredChartAgentId,
                        links: sessionColorLinks
                    )
                    let fixedHeight: CGFloat? = allocatedHeight == nil
                        ? SessionListLayoutPolicy.scrollHeight(
                            forCount: displaySessions.count,
                            visibleLimit: store.expandedSessionRowLimit,
                            chartExpanded: !isTelemetryCollapsed
                        )
                        : nil
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: SessionListLayoutPolicy.rowSpacing) {
                            ForEach(displaySessions) { session in
                                let link = sessionColorLinks[session.uuid]
                                CompactSessionRowView(
                                    session: session,
                                    showModelColumn: store.showSessionModelColumn,
                                    horizontalPadding: layoutMetrics.sessionRowHorizontalPadding,
                                    chartColorLink: link,
                                    isHighlightedFromChart: highlightedSessionId == session.uuid,
                                    onHoverChartHighlight: { hovering in
                                        hoveredSessionSeriesIds = hovering ? (link?.seriesIds ?? []) : []
                                    }
                                )
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        hoveredSessionSeriesIds = []
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            store.openSessionDetail(session.uuid)
                                        }
                                    }
                            }
                        }
                    }
                    .frame(height: fixedHeight)
                    .frame(maxHeight: fixedHeight ?? .infinity)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .frame(height: allocatedHeight, alignment: .top)
        .clipped()
    }

    private var footerBar: some View {
        DashboardFooterBarView(
            lastUpdatedTimeStr: store.lastUpdatedTimeStr,
            stats: store.payload.todayStats,
            isUsageOpen: store.isUsageDashboardPresented,
            lang: lang,
            horizontalPadding: layoutMetrics.footerHorizontalPadding,
            onToggleUsage: {
                withAnimation(.easeInOut(duration: 0.16)) {
                    store.toggleUsageDashboard()
                }
            },
            onOpenSettings: {
                withAnimation(.easeOut(duration: 0.16)) {
                    isAccountPickerOpen = false
                    showSettingsPopover.toggle()
                }
            }
        )
    }

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

struct SettingsPopoverView: View {
    static let showsFooterQuitAndHintBar = false
    static let dismissesOnOutsideScrimTap = true

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

            Toggle(L10n.t(.showSessionModelToggle, lang), isOn: Binding(
                get: { store.showSessionModelColumn },
                set: { store.toggleSessionModelColumn($0) }
            ))
            .font(.system(size: 11.5))

            HStack(spacing: 8) {
                Text(L10n.t(.visibleSessionsCountLabel, lang))
                    .font(.system(size: 11.5))

                Spacer()

                Text(L10n.visibleSessionsCountValue(store.expandedSessionRowLimit, lang))
                    .font(.system(size: 11, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundColor(.primary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                    )

                Stepper(
                    "",
                    value: Binding(
                        get: { store.expandedSessionRowLimit },
                        set: { store.updateExpandedSessionRowLimit($0) }
                    ),
                    in: SessionListLayoutPolicy.minVisibleRowsWhenExpanded...SessionListLayoutPolicy.maxConfigurableVisibleRowsWhenExpanded
                )
                .labelsHidden()
                .controlSize(.small)
            }

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

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.t(.permissionsSectionTitle, lang))
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(.secondary)

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
        }
        .padding(16)
        .frame(minWidth: 280, maxWidth: 360)
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
        HStack(spacing: 2) {
            Text(item.title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Color.primary.opacity(0.72))
                .fixedSize()

            Text("\(item.percentage)%")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(item.remainingFraction <= 0.2 ? statusColor : Color.primary)
                .fixedSize()

            if !item.countdown.isEmpty {
                Text("·\(item.countdown)")
                    .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.primary.opacity(0.62))
                    .fixedSize()
            }
        }
        .padding(.horizontal, 4.5)
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

struct AccountCardFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next.width > 0 {
            value = next
        }
    }
}

struct AccountNameCapacityBadgeView: View {
    let name: String
    let fullEmail: String
    let mode: AccountTargetMode
    let isSignedIn: Bool
    let isActiveTarget: Bool
    let hasDriftWarning: Bool
    let fiveHourDisplay: FiveHourCapacityDisplay?
    let isQuotaTokenExpired: Bool
    var secondaryRoleBadge: String? = nil

    private var accentTint: Color {
        if hasDriftWarning {
            return Color.orange
        }
        return mode == .app ? Color.accentColor : Color.purple
    }

    private var capacityBarColor: Color {
        guard let fh = fiveHourDisplay else { return accentTint }
        if fh.remainingFraction > 0.2 {
            return mode == .app ? Color.accentColor : Color.purple
        } else if fh.remainingFraction > 0.05 {
            return Color(red: 0.85, green: 0.42, blue: 0.0)
        } else {
            return Color.red
        }
    }

    private var borderStrokeColor: Color {
        if hasDriftWarning {
            return Color.orange.opacity(0.55)
        }
        if let fh = fiveHourDisplay, fh.remainingFraction <= 0.2 {
            return capacityBarColor.opacity(0.45)
        }
        return isActiveTarget ? accentTint.opacity(0.32) : Color.primary.opacity(0.11)
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isSignedIn ? (isActiveTarget || hasDriftWarning ? accentTint : Color.secondary.opacity(0.35)) : Color.secondary.opacity(0.30))
                .frame(width: 5, height: 5)
                .fixedSize()

            Text(name)
                .font(.system(size: 11.5, weight: isActiveTarget ? .semibold : .medium))
                .foregroundColor(isSignedIn ? (isActiveTarget ? .primary : Color.primary.opacity(0.88)) : .secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .layoutPriority(0)

            if let roleBadge = secondaryRoleBadge, !roleBadge.isEmpty {
                Text(roleBadge)
                    .font(.system(size: 8.5, weight: .bold))
                    .padding(.horizontal, 3.5)
                    .padding(.vertical, 0.5)
                    .background((roleBadge == "CLI" ? Color.purple : Color.accentColor).opacity(0.14))
                    .foregroundColor(roleBadge == "CLI" ? Color.purple : Color.accentColor)
                    .cornerRadius(3)
                    .fixedSize()
                    .layoutPriority(2)
            }

            if let fh = fiveHourDisplay {
                HStack(spacing: 1) {
                    Text("\(fh.percentage)%")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundColor(fh.remainingFraction <= 0.2 ? capacityBarColor : Color.primary.opacity(0.75))
                    if !fh.countdown.isEmpty {
                        Text("·\(fh.countdown)")
                            .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.primary.opacity(0.58))
                    }
                }
                .fixedSize()
                .layoutPriority(2)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3.5)
        .background(
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.primary.opacity(0.045))

                if let fh = fiveHourDisplay {
                    GeometryReader { geo in
                        let fillWidth = max(0, geo.size.width * CGFloat(fh.remainingFraction))
                        ZStack(alignment: .bottomLeading) {
                            Rectangle()
                                .fill(capacityBarColor.opacity(0.16))
                                .frame(width: fillWidth, height: geo.size.height)

                            Rectangle()
                                .fill(capacityBarColor.opacity(0.72))
                                .frame(width: fillWidth, height: 1.75)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    }
                    .opacity(isQuotaTokenExpired ? 0.55 : 1.0)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .strokeBorder(borderStrokeColor, lineWidth: 0.6)
        )
        .help(fullEmail)
    }
}

struct AccountSummaryCardView: View {
    @Binding var targetMode: AccountTargetMode
    let isCLIIndependentMode: Bool
    let snapshot: ActiveAccountSnapshot
    let hasSharedKeychainMismatch: Bool
    let isCLIVaultAuthorized: Bool
    let isPickerOpen: Bool
    var horizontalPadding: CGFloat = 6
    let onTogglePicker: () -> Void
    let onRefreshQuota: () -> Void

    @Environment(\.agyLanguage) private var lang
    @State private var isModeHovered = false
    @State private var isSwitchHovered = false

    private var activeTint: Color {
        snapshot.effectiveMode == .app ? Color.accentColor : Color.purple
    }

    private var tooltipText: String {
        let weeklyItems = snapshot.quota.map { AccountQuotaManager.displayItems(for: $0, language: lang) } ?? []
        var parts: [String] = []
        if !snapshot.fullEmail.isEmpty && snapshot.fullEmail != snapshot.displayName {
            parts.append(snapshot.fullEmail)
        }
        if let q = snapshot.quota {
            let qTip = AccountQuotaManager.quotaTooltip(
                items: weeklyItems,
                isUltra: q.isUltra,
                fiveHourQuota: q.effectiveFiveHourQuota,
                isExpired: snapshot.isQuotaExpired,
                language: lang
            )
            if !qTip.isEmpty {
                parts.append(qTip)
            }
        } else if snapshot.isQuotaExpired {
            parts.append(L10n.quotaExpiredHint(for: lang))
        }
        return parts.joined(separator: "\n")
    }

    var body: some View {
        let fhDisplay = AccountQuotaManager.fiveHourDisplay(for: snapshot.quota, language: lang)
        let weeklyItems = snapshot.quota.map { AccountQuotaManager.displayItems(for: $0, language: lang) } ?? []
        let tip = tooltipText

        HStack(spacing: 4) {
            modeSwitcherSegment
            warningIndicatorButton

            AccountNameCapacityBadgeView(
                name: snapshot.displayName,
                fullEmail: tip.isEmpty ? snapshot.fullEmail : tip,
                mode: snapshot.effectiveMode,
                isSignedIn: snapshot.isSignedIn,
                isActiveTarget: snapshot.isSignedIn,
                hasDriftWarning: hasSharedKeychainMismatch && snapshot.effectiveMode == .app,
                fiveHourDisplay: fhDisplay,
                isQuotaTokenExpired: snapshot.isQuotaExpired
            )
            .layoutPriority(1)

            weeklyQuotaSection(weeklyItems: weeklyItems, tooltip: tip)

            Spacer(minLength: 2)
                .frame(height: 20)
                .contentShape(Rectangle())
                .background(WindowDragArea())
                .layoutPriority(-1)

            switchTriggerButton
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 4.5)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.035))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(
                    (hasSharedKeychainMismatch && snapshot.effectiveMode == .app)
                        ? Color.orange.opacity(0.40)
                        : Color.primary.opacity(0.09),
                    lineWidth: 0.6
                )
        )
    }

    @ViewBuilder
    private var modeSwitcherSegment: some View {
        if isCLIIndependentMode {
            let modeTint = targetMode == .app ? Color.accentColor : Color.purple
            Button {
                withAnimation(.easeOut(duration: 0.14)) {
                    targetMode = targetMode.toggled
                }
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: targetMode == .cli ? "terminal" : "macwindow")
                        .font(.system(size: 8.5, weight: .semibold))
                    Text(targetMode.rawValue)
                        .font(.system(size: 10.5, weight: .bold))
                }
                .foregroundColor(modeTint)
                .padding(.horizontal, 6.5)
                .padding(.vertical, 3.5)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(modeTint.opacity(isModeHovered ? 0.17 : 0.10))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(modeTint.opacity(isModeHovered ? 0.38 : 0.22), lineWidth: 0.5)
                )
                .contentShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            }
            .buttonStyle(.plain)
            .fixedSize()
            .layoutPriority(2)
            .onHover { hovering in
                isModeHovered = hovering
                if hovering {
                    NSCursor.pointingHand.set()
                } else {
                    NSCursor.arrow.set()
                }
            }
            .onDisappear {
                if isModeHovered {
                    isModeHovered = false
                    NSCursor.arrow.set()
                }
            }
            .help(targetMode == .app ? L10n.t(.toggleToCLIModeTooltip, lang) : L10n.t(.toggleToAppModeTooltip, lang))
        } else {
            Text(AccountTargetMode.app.rawValue)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color.accentColor)
                .padding(.horizontal, 5.5)
                .padding(.vertical, 2.5)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.accentColor.opacity(0.10))
                )
                .fixedSize()
                .layoutPriority(2)
        }
    }

    @ViewBuilder
    private var warningIndicatorButton: some View {
        if hasSharedKeychainMismatch && snapshot.effectiveMode == .app {
            Button(action: onTogglePicker) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
            }
            .buttonStyle(.plain)
            .fixedSize()
            .layoutPriority(2)
            .help(L10n.t(.switchAppHelp, lang))
        } else if snapshot.effectiveMode == .cli && !isCLIVaultAuthorized {
            Button(action: onTogglePicker) {
                Image(systemName: "key.fill")
                    .font(.system(size: 9.5))
                    .foregroundColor(.purple)
            }
            .buttonStyle(.plain)
            .fixedSize()
            .layoutPriority(2)
            .help(L10n.t(.authorizeCLIAutoSwitchTitle, lang))
        }
    }

    @ViewBuilder
    private func weeklyQuotaSection(weeklyItems: [QuotaDisplayItem], tooltip: String) -> some View {
        if snapshot.quota != nil && !weeklyItems.isEmpty {
            HStack(spacing: 3) {
                ForEach(weeklyItems) { item in
                    QuotaPillView(item: item)
                }
            }
            .opacity(snapshot.isQuotaExpired ? 0.65 : 1.0)
            .fixedSize()
            .layoutPriority(2)
            .help(tooltip)
        } else if snapshot.isQuotaExpired {
            Button(action: onRefreshQuota) {
                HStack(spacing: 2.5) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 8.5, weight: .medium))
                    Text(L10n.quotaExpiredBadge(for: lang))
                        .font(.system(size: 9, weight: .medium))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.primary.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.5)
                        )
                )
            }
            .buttonStyle(.plain)
            .fixedSize()
            .layoutPriority(2)
            .help(L10n.quotaExpiredHint(for: lang))
        }
    }

    private var switchTriggerButton: some View {
        Button(action: onTogglePicker) {
            HStack(spacing: 2.5) {
                Text(L10n.t(.switchAction, lang))
                    .font(.system(size: 10.5, weight: .semibold))
                Image(systemName: isPickerOpen ? "chevron.up" : "chevron.down")
                    .font(.system(size: 8, weight: .bold))
            }
            .foregroundColor(activeTint)
            .padding(.horizontal, 6.5)
            .padding(.vertical, 3.5)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(activeTint.opacity(isPickerOpen ? 0.22 : (isSwitchHovered ? 0.18 : 0.11)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(activeTint.opacity(isPickerOpen ? 0.42 : 0.24), lineWidth: 0.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
        .buttonStyle(.plain)
        .fixedSize()
        .layoutPriority(3)
        .onHover { hovering in
            isSwitchHovered = hovering
            if hovering {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
        .onDisappear {
            if isSwitchHovered {
                isSwitchHovered = false
                NSCursor.arrow.set()
            }
        }
        .help(snapshot.effectiveMode == .app ? L10n.t(.switchAppHelp, lang) : L10n.t(.switchCLIAccountTooltip, lang))
    }
}

struct AccountSwitcherOverlayView: View {
    @ObservedObject var store: AGYHubStore
    let mode: AccountTargetMode
    let sortedProfiles: [AGYProfile]
    let effectiveAppEmail: String
    let isAppResolved: Bool
    let onSelectProfile: (AGYProfile, Bool) -> Void
    let onRefreshQuota: () -> Void
    let onClose: () -> Void

    @Environment(\.agyLanguage) private var lang

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                ImpeccableIconButton(
                    icon: "xmark",
                    tooltip: L10n.t(.closePickerTooltip, lang),
                    hoverTint: .red,
                    hoverFill: Color.red.opacity(0.12),
                    size: 20,
                    iconSize: 10
                ) {
                    onClose()
                }
            }
            .padding(.horizontal, 6)
            .padding(.top, 5)

            driftWarningBanner
            cliAuthStatusBanner

            accountListScrollView
        }
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.98))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.75)
        )
        .shadow(color: Color.black.opacity(0.20), radius: 14, y: 6)
    }

    @ViewBuilder
    private var driftWarningBanner: some View {
        if store.hasSharedKeychainMismatch,
           let actualEmail = store.sharedKeychainResolution.email {
            let expectedEmail = store.resolvedExpectedAppEmail
            let appShort = AccountCompactSummaryPolicy.shortName(for: expectedEmail)
            let actualShort = AccountCompactSummaryPolicy.shortName(for: actualEmail)
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
                    onClose()
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
            .padding(.horizontal, 8)
        }
    }

    @ViewBuilder
    private var cliAuthStatusBanner: some View {
        if store.isCLIIndependentMode && mode == .cli && !store.isCLIVaultAuthorized {
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
            .padding(.horizontal, 8)
        } else if store.isCLIIndependentMode && mode == .cli {
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
            .padding(.horizontal, 10)
        }
    }

    private var accountListScrollView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 3) {
                ForEach(sortedProfiles) { profile in
                    let emailKey = (profile.email ?? profile.name).lowercased()
                    let isAppActive = (emailKey == effectiveAppEmail) || (!isAppResolved && profile.name == store.activeProfileName)
                    let isCLIActive = (store.activeCLIProfileName?.lowercased() == emailKey)
                    let isTargetActive = (mode == .app) ? isAppActive : isCLIActive
                    let hasCLISlot = isCLIActive || store.savedCLISlots.contains(emailKey)
                    AccountPickerRowView(
                        profile: profile,
                        mode: mode,
                        isAppActive: isAppActive,
                        isCLIActive: isCLIActive,
                        isCLIVaultAuthorized: store.isCLIVaultAuthorized,
                        hasCLISlot: hasCLISlot,
                        accountQuota: store.accountQuotas[emailKey],
                        isQuotaTokenExpired: store.expiredQuotaEmails.contains(emailKey),
                        onSelect: {
                            onSelectProfile(profile, isTargetActive)
                        },
                        onRefreshQuota: onRefreshQuota
                    )
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 7)
        }
        .frame(maxHeight: 220)
    }
}

struct AccountPickerRowView: View {
    let profile: AGYProfile
    let mode: AccountTargetMode
    let isAppActive: Bool
    let isCLIActive: Bool
    let isCLIVaultAuthorized: Bool
    let hasCLISlot: Bool
    let accountQuota: AccountQuotaSummary?
    let isQuotaTokenExpired: Bool
    let onSelect: () -> Void
    let onRefreshQuota: () -> Void

    @Environment(\.agyLanguage) private var lang
    @State private var isHovered = false

    private var isTargetActive: Bool {
        mode == .app ? isAppActive : isCLIActive
    }

    private var secondaryRoleBadge: String? {
        if mode == .app && isCLIActive {
            return "CLI"
        }
        if mode == .cli && isAppActive {
            return "App"
        }
        return nil
    }

    private var activeTint: Color {
        mode == .app ? Color.accentColor : Color.purple
    }

    var body: some View {
        let shortId = AccountCompactSummaryPolicy.shortName(for: profile.email ?? profile.name)
        let fhDisplay = AccountQuotaManager.fiveHourDisplay(for: accountQuota, language: lang)
        let weeklyItems = accountQuota.map { AccountQuotaManager.displayItems(for: $0, language: lang) } ?? []
        let tooltipText: String = {
            var parts = [profile.name]
            if let q = accountQuota {
                let qTip = AccountQuotaManager.quotaTooltip(
                    items: weeklyItems,
                    isUltra: q.isUltra,
                    fiveHourQuota: q.effectiveFiveHourQuota,
                    isExpired: isQuotaTokenExpired,
                    language: lang
                )
                if !qTip.isEmpty {
                    parts.append(qTip)
                }
            } else if isQuotaTokenExpired {
                parts.append(L10n.quotaExpiredHint(for: lang))
            }
            return parts.joined(separator: "\n")
        }()

        Button(action: onSelect) {
            HStack(spacing: 5) {
                AccountNameCapacityBadgeView(
                    name: shortId,
                    fullEmail: tooltipText,
                    mode: mode,
                    isSignedIn: true,
                    isActiveTarget: isTargetActive,
                    hasDriftWarning: false,
                    fiveHourDisplay: fhDisplay,
                    isQuotaTokenExpired: isQuotaTokenExpired,
                    secondaryRoleBadge: secondaryRoleBadge
                )
                .layoutPriority(1)

                if accountQuota != nil && !weeklyItems.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(weeklyItems) { item in
                            QuotaPillView(item: item)
                        }
                    }
                    .opacity(isQuotaTokenExpired ? 0.65 : 1.0)
                    .fixedSize()
                    .layoutPriority(2)
                    .help(tooltipText)
                } else if isQuotaTokenExpired {
                    Button(action: onRefreshQuota) {
                        HStack(spacing: 2.5) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 8.5, weight: .medium))
                            Text(L10n.quotaExpiredBadge(for: lang))
                                .font(.system(size: 9, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.primary.opacity(0.04))
                        )
                    }
                    .buttonStyle(.plain)
                    .fixedSize()
                    .layoutPriority(2)
                    .help(L10n.quotaExpiredHint(for: lang))
                }

                Spacer(minLength: 4)

                if isTargetActive {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(activeTint)
                        .fixedSize()
                } else if isHovered {
                    let actionLabel = (mode == .cli && (!isCLIVaultAuthorized || !hasCLISlot))
                        ? (!isCLIVaultAuthorized ? L10n.t(.terminalLoginAction, lang) : L10n.t(.loginCLIAction, lang))
                        : L10n.t(.switchAction, lang)
                    Text(actionLabel)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(activeTint)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(activeTint.opacity(0.14))
                        )
                        .fixedSize()
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        isTargetActive
                            ? activeTint.opacity(0.08)
                            : (isHovered ? Color.primary.opacity(0.05) : Color.clear)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(
                        isTargetActive ? activeTint.opacity(0.22) : Color.clear,
                        lineWidth: 0.6
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
        .onDisappear {
            if isHovered {
                isHovered = false
                NSCursor.arrow.set()
            }
        }
    }
}

enum ProfileRowActionPolicy {

    static let showsParallelLaunchButton = false

    static let showsDeleteButton = false

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
    var onRefreshQuota: (() -> Void)? = nil

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
                Button(action: { onRefreshQuota?() }) {
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
                }
                .buttonStyle(.plain)
                .fixedSize()
                .layoutPriority(2)
                .help(L10n.quotaExpiredHint(for: lang))
            }

            Spacer(minLength: 2)
                .frame(height: 24)
                .contentShape(Rectangle())
                .background(WindowDragArea())
                .layoutPriority(-1)

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

enum TelemetryYAxisPosition: Equatable {
    case leading
    case trailing
}

enum LiveTelemetryChartAxisPolicy {
    static let yAxisPosition: TelemetryYAxisPosition = .leading
    static let contextHeaderAlignment: HorizontalAlignment = .leading
    static let yAxisTitleOpacity: Double = 0.78
    static let yAxisTickOpacity: Double = 0.74
    static let xAxisTickOpacity: Double = 0.62
    static let yAxisTitleFontSize: CGFloat = 9.5
    static let yAxisTickFontSize: CGFloat = 9.5
    static let xAxisTickFontSize: CGFloat = 9.0

    static func horizontalGuideIndices(
        seriesList: [AgentContextSeries],
        focusedSeriesIds: Set<String>
    ) -> [Int] {
        guard !focusedSeriesIds.isEmpty else { return [] }
        if let match = seriesList.indices.first(where: { focusedSeriesIds.contains(seriesList[$0].agentId) }) {
            return [match]
        }
        return []
    }

    static func calloutCenterX(forReferenceX referenceX: CGFloat, in plotRect: CGRect) -> CGFloat {
        let minX = plotRect.minX + 22
        let maxX = max(minX, plotRect.maxX - 22)
        if referenceX <= plotRect.maxX - 46 {
            return min(max(minX, referenceX + 24), maxX)
        }
        return min(max(minX, referenceX - 24), maxX)
    }
}

struct LiveTelemetryOverviewCardView: View {
    static let showsStandaloneLegendStrip = false
    static let drawsHollowEndpointForIdleSeries = true
    static let usesOneQuarterGrowingTimelinePage = true

    let samples: [LiveTelemetrySample]
    let todayStats: TodayStats
    var isCollapsedExternal: Binding<Bool>? = nil
    var cardHorizontalPadding: CGFloat = 9
    var plotHorizontalPadding: CGFloat = 6
    var highlightedSeriesIds: Set<String> = []
    var minPlotHeight: CGFloat = DashboardSplitLayoutPolicy.defaultMinPlotHeight
    var pinnedFamilyByRoot: [String: Int] = [:]
    var timelineAnchorDate: Date? = nil
    var onHoverChartAgent: ((String?) -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.agyLanguage) private var lang
    @AppStorage("agyhub.telemetry.range") private var selectedRangeRaw: String = TelemetryTimeRange.threeMinutes.rawValue
    @AppStorage("agyhub.collapse.telemetry") private var storedCollapsed: Bool = false
    @State private var hoveredSampleId: Int? = nil
    @State private var hoveredChartAgentId: String? = nil
    @State private var hoveredLegendAgentId: String? = nil

    private var activeFocusedSeriesIds: Set<String> {
        if !highlightedSeriesIds.isEmpty {
            return highlightedSeriesIds
        }
        if let hoveredChartAgentId {
            return [hoveredChartAgentId]
        }
        if let focusId = hoveredLegendAgentId {
            return [focusId]
        }
        return []
    }

    private var isCollapsed: Bool {
        get { isCollapsedExternal?.wrappedValue ?? storedCollapsed }
        nonmutating set {
            if let ext = isCollapsedExternal {
                ext.wrappedValue = newValue
            } else {
                storedCollapsed = newValue
            }
        }
    }

    private var selectedRange: TelemetryTimeRange {
        TelemetryTimeRange.resolved(from: selectedRangeRaw)
    }

    private static let hoverTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    private static let axisMinuteFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private var referenceDate: Date {
        max(Date(), samples.last?.timestamp ?? Date())
    }

    private var effectiveAnchorDate: Date {
        timelineAnchorDate ?? samples.first?.timestamp ?? referenceDate
    }

    private var rangeSamples: [LiveTelemetrySample] {
        LiveTelemetryPolicy.visibleChartSamples(
            in: selectedRange,
            from: samples,
            anchorDate: effectiveAnchorDate,
            now: referenceDate
        )
    }

    private var latestSample: LiveTelemetrySample? {
        rangeSamples.last ?? samples.last
    }

    private var hoveredSample: LiveTelemetrySample? {
        guard let hoveredId = hoveredSampleId else { return nil }
        return rangeSamples.first(where: { $0.id == hoveredId })
    }

    private var activeSample: LiveTelemetrySample? {
        hoveredSample ?? latestSample
    }

    private var windowSummary: TelemetryWindowSummary {
        LiveTelemetryPolicy.windowSummary(
            in: selectedRange,
            from: samples,
            todayStats: todayStats,
            now: referenceDate
        )
    }

    private var displayedAgents: Int {
        activeSample?.activeAgentCount ?? 0
    }

    private var displayedTps: Double {
        activeSample?.totalTps ?? 0.0
    }

    private var displayedWindowTokens: Int {
        if let hovered = hoveredSample {
            return hovered.deltaTokens
        }
        return windowSummary.totalTokens
    }

    private var displayedCachePct: Double {
        if let hovered = hoveredSample {
            return hovered.cachePct
        }
        return windowSummary.cachePct
    }

    private var cacheColor: Color {
        if !todayStats.hasData && samples.isEmpty {
            return .secondary
        }
        if displayedCachePct >= 85.0 {
            return Color(red: 0.06, green: 0.60, blue: 0.35)
        } else if displayedCachePct >= 60.0 {
            return Color(red: 0.88, green: 0.43, blue: 0.04)
        }
        return Color.red
    }

    private var timeRangeDomain: ClosedRange<Date> {
        LiveTelemetryPolicy.xAxisDomain(
            for: selectedRange,
            referenceDate: referenceDate,
            anchorDate: effectiveAnchorDate
        )
    }

    private var xTicks: [Date] {
        LiveTelemetryPolicy.xAxisTicks(
            for: selectedRange,
            referenceDate: referenceDate,
            anchorDate: effectiveAnchorDate,
            count: 5
        )
    }

    private var cardSurfaceColor: Color {
        colorScheme == .dark
            ? Color(nsColor: .controlBackgroundColor).opacity(0.92)
            : Color(nsColor: .windowBackgroundColor).opacity(0.98)
    }

    private var plotWellColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.20)
            : Color(nsColor: .textBackgroundColor).opacity(0.82)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            cardHeaderBar

            if !isCollapsed {
                topKpiBar
                chartsStack
            }
        }
        .padding(.horizontal, cardHorizontalPadding)
        .padding(.vertical, isCollapsed ? 7 : 9)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(cardSurfaceColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.07), lineWidth: 0.75)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.20 : 0.045), radius: 5, y: 1.5)
    }

    private var cardHeaderBar: some View {
        HStack(spacing: 6) {
            SectionCollapseToggleButton(title: L10n.t(.telemetrySectionTitle, lang), isCollapsed: isCollapsed) {
                withAnimation(.easeOut(duration: 0.16)) {
                    isCollapsed.toggle()
                }
            }

            if isCollapsed {
                Text("\(L10n.telemetryAgentCount(displayedAgents, lang)) · \(Int(displayedTps.rounded())) t/s · \(String(format: "%.1f%%", displayedCachePct))")
                    .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } else if let hovered = hoveredSample {
                let deltaPart = hovered.deltaTokens > 0 ? " · +\(Formatters.formatTokens(hovered.deltaTokens))" : ""
                Text("\(Self.hoverTimeFormatter.string(from: hovered.timestamp))\(deltaPart)")
                    .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color.accentColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1.5)
                    .background(Color.accentColor.opacity(0.10))
                    .cornerRadius(4)
                    .fixedSize()
            }

            Spacer(minLength: 4)

            if !isCollapsed {
                HStack(spacing: 1.5) {
                    ForEach(TelemetryTimeRange.allCases) { range in
                        let isSelected = (range == selectedRange)
                        Button {
                            hoveredSampleId = nil
                            selectedRangeRaw = range.rawValue
                        } label: {
                            Text(range.rawValue)
                                .font(.system(size: 9.5, weight: isSelected ? .bold : .medium, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2.5)
                                .background(
                                    RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                                        .fill(isSelected ? cardSurfaceColor : Color.clear)
                                        .shadow(color: isSelected ? Color.black.opacity(0.08) : Color.clear, radius: 1, y: 0.5)
                                )
                                .foregroundColor(isSelected ? .primary : .secondary)
                                .contentShape(RoundedRectangle(cornerRadius: 4.5, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(2)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(0.055))
                )
                .fixedSize()
            }
        }
    }

    private var topKpiBar: some View {
        HStack(spacing: 6) {
            kpiCell(
                label: L10n.t(.telemetryAgentsLabel, lang),
                value: L10n.telemetryAgentCount(displayedAgents, lang),
                valueColor: displayedAgents > 0 ? Color(red: 0.06, green: 0.56, blue: 0.28) : .secondary,
                dotColor: displayedAgents > 0 ? Color(nsColor: .systemGreen) : nil,
                subLabel: nil
            )

            kpiDivider

            kpiCell(
                label: L10n.t(.telemetryRateLabel, lang),
                value: "\(Int(displayedTps.rounded())) t/s",
                valueColor: displayedTps > 0 ? Color(red: 0.14, green: 0.40, blue: 0.92) : .primary,
                dotColor: nil,
                subLabel: nil
            )

            kpiDivider

            kpiCell(
                label: L10n.t(.telemetryTotalLabel, lang),
                value: Formatters.formatTokens(displayedWindowTokens),
                valueColor: .primary,
                dotColor: nil,
                subLabel: hoveredSample != nil ? nil : selectedRange.rawValue
            )

            kpiDivider

            kpiCell(
                label: L10n.t(.telemetryCacheLabel, lang),
                value: (todayStats.hasData || !samples.isEmpty) ? String(format: "%.1f%%", displayedCachePct) : "-",
                valueColor: cacheColor,
                dotColor: nil,
                subLabel: nil
            )
        }
    }

    private var kpiDivider: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor).opacity(0.28))
            .frame(width: 0.5, height: 22)
    }

    private func kpiCell(
        label: String,
        value: String,
        valueColor: Color,
        dotColor: Color?,
        subLabel: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 1.5) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)

            HStack(spacing: 3.5) {
                if let dot = dotColor {
                    Circle()
                        .fill(dot)
                        .frame(width: 5.5, height: 5.5)
                }
                Text(value)
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundColor(valueColor)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                if let sub = subLabel {
                    Text(sub)
                        .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.85))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var chartsStack: some View {
        let seriesList = LiveTelemetryPolicy.agentSeries(
            in: rangeSamples,
            colorAnchorSamples: samples,
            pinnedFamilyByRoot: pinnedFamilyByRoot
        )

        return VStack(alignment: .leading, spacing: 6) {
            if rangeSamples.isEmpty {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.accentColor.opacity(0.55))
                        .frame(width: 5, height: 5)
                    Text(L10n.t(.telemetryWaitingWaveHint, lang))
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: minPlotHeight, idealHeight: minPlotHeight, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(plotWellColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.05), lineWidth: 0.5)
                        )
                )
            } else {
                VStack(alignment: LiveTelemetryChartAxisPolicy.contextHeaderAlignment, spacing: 4) {
                    HStack {
                        if LiveTelemetryChartAxisPolicy.yAxisPosition == .trailing {
                            Spacer()
                        }
                        Text(L10n.t(.telemetryTrackContextTitle, lang))
                            .font(.system(size: LiveTelemetryChartAxisPolicy.yAxisTitleFontSize, weight: .semibold))
                            .foregroundColor(.primary.opacity(LiveTelemetryChartAxisPolicy.yAxisTitleOpacity))
                            .fixedSize(horizontal: true, vertical: false)
                            .frame(minWidth: 36, alignment: .trailing)
                        if LiveTelemetryChartAxisPolicy.yAxisPosition == .leading {
                            Spacer()
                        }
                    }

                    agentContextChart(seriesList: seriesList)
                        .padding(.top, 1)
                        .padding(.trailing, LiveTelemetryChartAxisPolicy.yAxisPosition == .leading ? 6 : 0)
                        .frame(minHeight: minPlotHeight, idealHeight: minPlotHeight, maxHeight: .infinity)
                }
                .padding(.horizontal, plotHorizontalPadding)
                .padding(.top, 6)
                .padding(.bottom, 5)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(plotWellColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .strokeBorder(Color.primary.opacity(colorScheme == .dark ? 0.10 : 0.055), lineWidth: 0.6)
                        )
                )

                if Self.showsStandaloneLegendStrip && !seriesList.isEmpty {
                    agentLegendStrip(seriesList: seriesList)
                }
            }
        }
    }

    private func toneForSeries(_ series: AgentContextSeries) -> TelemetrySeriesTone {
        LiveTelemetryColorPalette.tone(familyIndex: series.familyIndex, tier: series.familyTier)
    }

    private func colorForSeries(_ series: AgentContextSeries, offset: Int) -> Color {
        toneForSeries(series).color
    }

    private func highlightedContextValue(for series: AgentContextSeries) -> Int {
        if let hovered = hoveredSample,
           let matched = hovered.agentContexts.first(where: { $0.agentId == series.agentId }) {
            return matched.contextTokens
        }
        return series.latestContextTokens
    }

    private func indicatorSeriesIndices(seriesList: [AgentContextSeries]) -> [Int] {
        let focused = activeFocusedSeriesIds
        if !focused.isEmpty {
            let indices = seriesList.indices.filter { focused.contains(seriesList[$0].agentId) }
            if !indices.isEmpty {
                return indices
            }
        }
        let runningIndices = seriesList.indices.filter { seriesList[$0].isRunning }
        if !runningIndices.isEmpty {
            return Array(runningIndices.prefix(2))
        }
        return seriesList.isEmpty ? [] : [0]
    }

    private func agentContextChart(seriesList: [AgentContextSeries]) -> some View {
        let maxCtx = LiveTelemetryPolicy.maxContextDomain(for: seriesList)
        let maxCtxDouble = Double(maxCtx)
        let yTicks = LiveTelemetryPolicy.yAxisTicks(maxContext: maxCtx)
        let calloutIndices = indicatorSeriesIndices(seriesList: seriesList)
        let guideRuleIndices = LiveTelemetryChartAxisPolicy.horizontalGuideIndices(
            seriesList: seriesList,
            focusedSeriesIds: activeFocusedSeriesIds
        )
        let resolvedList = LiveTelemetryPolicy.resolvedCurveSegments(
            for: seriesList,
            windowSeconds: selectedRange.seconds
        )
        let externalFocusSignature = highlightedSeriesIds.sorted().joined(separator: ",")
            + "-\(hoveredLegendAgentId ?? "")"

        return Chart {
            chartSeriesMarks(seriesList: seriesList, resolvedList: resolvedList)
            chartReferenceAndHoverMarks(seriesList: seriesList, guideIndices: guideRuleIndices)
        }
        .id("\(selectedRange.rawValue)-\(externalFocusSignature)")
        .chartLegend(.hidden)
        .chartXAxis {
            AxisMarks(values: xTicks) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
                    .foregroundStyle(Color.primary.opacity(0.08))
                AxisValueLabel {
                    if let dt = value.as(Date.self) {
                        let isCenterNow = abs(dt.timeIntervalSince(referenceDate)) < 0.5
                        let showsSeconds = (selectedRange == .oneMinute || selectedRange == .threeMinutes)
                        Text(showsSeconds
                            ? Self.hoverTimeFormatter.string(from: dt)
                            : Self.axisMinuteFormatter.string(from: dt))
                            .font(.system(
                                size: LiveTelemetryChartAxisPolicy.xAxisTickFontSize,
                                weight: isCenterNow ? .bold : .medium,
                                design: .monospaced
                            ))
                            .foregroundColor(
                                isCenterNow
                                    ? Color.accentColor.opacity(0.90)
                                    : .primary.opacity(LiveTelemetryChartAxisPolicy.xAxisTickOpacity)
                            )
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(
                position: LiveTelemetryChartAxisPolicy.yAxisPosition == .leading ? .leading : .trailing,
                values: yTicks
            ) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.75, dash: [3, 3]))
                    .foregroundStyle(Color.primary.opacity(0.14))
                AxisValueLabel {
                    if let num = value.as(Double.self) {
                        Text(Formatters.formatTokens(Int(num.rounded())))
                            .font(.system(size: LiveTelemetryChartAxisPolicy.yAxisTickFontSize, weight: .semibold, design: .monospaced))
                            .foregroundColor(.primary.opacity(LiveTelemetryChartAxisPolicy.yAxisTickOpacity))
                            .frame(width: 36, alignment: .trailing)
                    }
                }
            }
        }
        .chartXScale(domain: timeRangeDomain)
        .chartYScale(domain: 0.0...maxCtxDouble)
        .chartOverlay { proxy in
            chartInteractiveAndCalloutOverlay(
                proxy: proxy,
                seriesList: seriesList,
                resolvedList: resolvedList,
                maxContext: maxCtx,
                guideIndices: calloutIndices
            )
        }
    }

    @ChartContentBuilder
    private func chartSeriesMarks(
        seriesList: [AgentContextSeries],
        resolvedList: [ResolvedAgentCurveSeries]
    ) -> some ChartContent {
        let focused = activeFocusedSeriesIds
        let defaultSpotlitId = seriesList.first(where: \.isRunning)?.agentId ?? seriesList.first?.agentId
        let resolvedById = Dictionary(uniqueKeysWithValues: resolvedList.map { ($0.agentId, $0) })
        let seriesById = Dictionary(uniqueKeysWithValues: seriesList.map { ($0.agentId, $0) })

        ForEach(Array(seriesList.enumerated()), id: \.element.id) { idx, series in
            let color = colorForSeries(series, offset: idx)
            let isSpotlit = !focused.isEmpty ? focused.contains(series.agentId) : (series.agentId == defaultSpotlitId)
            let lineAlpha: Double = {
                if !focused.isEmpty {
                    return focused.contains(series.agentId) ? 1.0 : 0.24
                }
                return series.isRunning ? 1.0 : 0.72
            }()
            let lineW: CGFloat = {
                if !focused.isEmpty {
                    return focused.contains(series.agentId) ? 3.4 : 1.5
                }
                if series.isRunning {
                    return series.familyTier == 0 ? 2.8 : 2.3
                }
                return series.familyTier == 0 ? 2.0 : 1.7
            }()
            let segments = resolvedById[series.agentId]?.segments ?? []

            ForEach(segments) { segment in
                let smoothed = segment.points

                if smoothed.count >= 2 {
                    ForEach(smoothed) { pt in
                        AreaMark(
                            x: .value("Time", pt.timestamp),
                            y: .value("Context", Double(pt.contextTokens)),
                            series: .value("AreaSeg", segment.id)
                        )
                        .interpolationMethod(.linear)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    color.opacity(isSpotlit ? 0.16 : 0.0),
                                    color.opacity(isSpotlit ? 0.01 : 0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }

                    let runs = segment.strokeRuns.isEmpty
                        ? [AgentCurveStrokeRun(id: segment.id, isIdle: false, points: smoothed)]
                        : segment.strokeRuns
                    ForEach(runs) { run in
                        if run.points.count >= 2 {
                            ForEach(run.points) { pt in
                                LineMark(
                                    x: .value("Time", pt.timestamp),
                                    y: .value("Context", Double(pt.contextTokens)),
                                    series: .value("AgentSeg", run.id)
                                )
                                .interpolationMethod(.linear)
                                .lineStyle(
                                    run.isIdle
                                        ? StrokeStyle(
                                            lineWidth: max(1.35, lineW * 0.65),
                                            lineCap: .round,
                                            lineJoin: .round,
                                            dash: [4.5, 3.5]
                                        )
                                        : StrokeStyle(
                                            lineWidth: lineW,
                                            lineCap: .round,
                                            lineJoin: .round
                                        )
                                )
                                .foregroundStyle(color.opacity(run.isIdle ? lineAlpha * 0.65 : lineAlpha))
                            }
                        }
                    }
                }
            }

            if let tail = series.points.last {
                if series.isRunning {
                    PointMark(
                        x: .value("Time", tail.timestamp),
                        y: .value("Context", Double(tail.contextTokens))
                    )
                    .symbolSize(96)
                    .foregroundStyle(color.opacity(0.20 * lineAlpha))
                    PointMark(
                        x: .value("Time", tail.timestamp),
                        y: .value("Context", Double(tail.contextTokens))
                    )
                    .symbolSize(36)
                    .foregroundStyle(color.opacity(lineAlpha))
                } else {
                    PointMark(
                        x: .value("Time", tail.timestamp),
                        y: .value("Context", Double(tail.contextTokens))
                    )
                    .symbolSize(isSpotlit ? 46 : 36)
                    .foregroundStyle(color.opacity(lineAlpha))
                    PointMark(
                        x: .value("Time", tail.timestamp),
                        y: .value("Context", Double(tail.contextTokens))
                    )
                    .symbolSize(isSpotlit ? 18 : 14)
                    .foregroundStyle(plotWellColor)
                }
            }
        }

        ForEach(Array(seriesList.enumerated()), id: \.element.id) { idx, series in
            let childColor = colorForSeries(series, offset: idx)
            let parentSeries = series.parentAgentId.flatMap { seriesById[$0] }
            let parentColor = parentSeries.map { toneForSeries($0).color } ?? childColor
            let junctionAlpha: Double = {
                if !focused.isEmpty {
                    let matchesSelf = focused.contains(series.agentId)
                    let matchesParent = series.parentAgentId.map { focused.contains($0) } ?? false
                    return (matchesSelf || matchesParent) ? 1.0 : 0.25
                }
                return series.isRunning ? 1.0 : 0.85
            }()
            let segments = resolvedById[series.agentId]?.segments ?? []

            ForEach(segments) { segment in
                if let junction = segment.forkJunction {
                    PointMark(
                        x: .value("Time", junction.timestamp),
                        y: .value("Context", Double(junction.contextTokens))
                    )
                    .symbolSize(92)
                    .foregroundStyle(parentColor.opacity(junctionAlpha))

                    PointMark(
                        x: .value("Time", junction.timestamp),
                        y: .value("Context", Double(junction.contextTokens))
                    )
                    .symbolSize(48)
                    .foregroundStyle(plotWellColor)

                    PointMark(
                        x: .value("Time", junction.timestamp),
                        y: .value("Context", Double(junction.contextTokens))
                    )
                    .symbolSize(22)
                    .foregroundStyle(childColor.opacity(junctionAlpha))
                }
            }
        }
    }

    @ChartContentBuilder
    private func chartReferenceAndHoverMarks(
        seriesList: [AgentContextSeries],
        guideIndices: [Int]
    ) -> some ChartContent {
        RuleMark(x: .value("Now", referenceDate))
            .foregroundStyle(Color.primary.opacity(0.16))
            .lineStyle(StrokeStyle(lineWidth: 1.0, dash: [3, 3]))

        ForEach(guideIndices, id: \.self) { idx in
            let series = seriesList[idx]
            let color = colorForSeries(series, offset: idx)
            let val = Double(highlightedContextValue(for: series))
            RuleMark(y: .value("Level", val))
                .foregroundStyle(color.opacity(0.45))
                .lineStyle(StrokeStyle(lineWidth: 1.0, dash: [2, 3]))
        }

        if let hovered = hoveredSample {
            RuleMark(x: .value("Hover", hovered.timestamp))
                .foregroundStyle(Color.primary.opacity(0.28))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 2]))

            ForEach(Array(seriesList.enumerated()), id: \.element.id) { idx, series in
                if let matched = hovered.agentContexts.first(where: { $0.agentId == series.agentId }) {
                    PointMark(
                        x: .value("Hover", hovered.timestamp),
                        y: .value("Context", Double(matched.contextTokens))
                    )
                    .symbolSize(36)
                    .foregroundStyle(colorForSeries(series, offset: idx))
                }
            }
        }
    }

    private func chartInteractiveAndCalloutOverlay(
        proxy: ChartProxy,
        seriesList: [AgentContextSeries],
        resolvedList: [ResolvedAgentCurveSeries],
        maxContext: Int,
        guideIndices: [Int]
    ) -> some View {
        GeometryReader { geo in
            let plotRect = geo[proxy.plotAreaFrame]
            let nowX = proxy.position(forX: referenceDate).map { plotRect.origin.x + $0 } ?? plotRect.midX
            let calloutX = LiveTelemetryChartAxisPolicy.calloutCenterX(forReferenceX: nowX, in: plotRect)
            let callouts: [(idx: Int, y: CGFloat, text: String, color: Color, fgColor: Color)] = {
                var items: [(idx: Int, y: CGFloat, text: String, color: Color, fgColor: Color)] = []
                for idx in guideIndices {
                    let series = seriesList[idx]
                    let tone = toneForSeries(series)
                    let ctxVal = highlightedContextValue(for: series)
                    guard let yInPlot = proxy.position(forY: Double(ctxVal)) else { continue }
                    let clampedY = min(max(plotRect.minY + 9, plotRect.origin.y + yInPlot), max(plotRect.minY + 9, plotRect.maxY - 9))
                    if items.allSatisfy({ abs($0.y - clampedY) >= 16 }) {
                        items.append((idx, clampedY, Formatters.formatTokens(ctxVal), tone.color, tone.capsuleForegroundColor))
                    }
                }
                return items
            }()

            ZStack(alignment: .topLeading) {
                ForEach(callouts, id: \.idx) { item in
                    Text(item.text)
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(item.fgColor)
                        .padding(.horizontal, 4.5)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(item.color)
                        )
                        .position(
                            x: calloutX,
                            y: item.y
                        )
                        .allowsHitTesting(false)
                }

                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let loc):
                            let xPos = loc.x - plotRect.origin.x
                            let yPos = loc.y - plotRect.origin.y
                            let plotW = proxy.plotAreaSize.width
                            let plotH = proxy.plotAreaSize.height
                            guard xPos >= 0, xPos <= plotW,
                                  yPos >= 0, yPos <= plotH else {
                                if hoveredSampleId != nil {
                                    hoveredSampleId = nil
                                }
                                if hoveredChartAgentId != nil {
                                    hoveredChartAgentId = nil
                                    onHoverChartAgent?(nil)
                                }
                                return
                            }
                            let futureSnapGrace = max(6.0, selectedRange.seconds * 0.04)
                            if let hoverDate = proxy.value(atX: xPos, as: Date.self),
                               hoverDate <= referenceDate.addingTimeInterval(futureSnapGrace),
                               let nearest = rangeSamples.min(by: {
                                   abs($0.timestamp.timeIntervalSince(hoverDate)) < abs($1.timestamp.timeIntervalSince(hoverDate))
                               }) {
                                if hoveredSampleId != nearest.id {
                                    hoveredSampleId = nearest.id
                                }
                            } else if hoveredSampleId != nil {
                                hoveredSampleId = nil
                            }
                            let hitAgent = LiveTelemetryPolicy.nearestAgentId(
                                in: resolvedList,
                                seriesList: seriesList,
                                timeDomain: timeRangeDomain,
                                maxContext: maxContext,
                                plotSize: CGSize(width: plotW, height: plotH),
                                hoverLocation: CGPoint(x: xPos, y: yPos)
                            )
                            if hoveredChartAgentId != hitAgent {
                                hoveredChartAgentId = hitAgent
                                onHoverChartAgent?(hitAgent)
                            }
                        case .ended:
                            hoveredSampleId = nil
                            if hoveredChartAgentId != nil {
                                hoveredChartAgentId = nil
                                onHoverChartAgent?(nil)
                            }
                        }
                    }
            }
        }
    }

    private func agentLegendStrip(seriesList: [AgentContextSeries]) -> some View {
        TelemetryLegendFlowLayout(horizontalSpacing: 5, verticalSpacing: 4) {
            ForEach(Array(seriesList.enumerated()), id: \.element.id) { idx, series in
                let tone = toneForSeries(series)
                let color = tone.color
                let hoveredPt = hoveredSample?.agentContexts.first(where: { $0.agentId == series.agentId })
                let ctxVal = hoveredPt?.contextTokens ?? series.latestContextTokens
                let tpsVal = hoveredPt?.tps ?? series.latestTps
                let isHighlighted = hoveredLegendAgentId == series.agentId
                let displayLabel = L10n.localizeAgentLabel(series.label, language: lang)

                HStack(spacing: 4) {
                    if series.parentAgentId != nil {
                        Image(systemName: "arrow.turn.down.right")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(color.opacity(series.isRunning ? 1.0 : 0.78))
                    } else {
                        Circle()
                            .fill(color.opacity(series.isRunning ? 1.0 : 0.72))
                            .frame(width: 6.5, height: 6.5)
                    }
                    Text(displayLabel)
                        .font(.system(size: 9.5, weight: (series.isRunning || isHighlighted) ? .semibold : .medium))
                        .foregroundColor((series.isRunning || isHighlighted) ? .primary : .secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: 92, alignment: .leading)
                    Text(Formatters.formatTokens(ctxVal))
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(tone.relativeLuminance > 0.58 && colorScheme == .light ? Color.primary.opacity(0.78) : color)
                        .lineLimit(1)
                    if tpsVal > 0 {
                        Text("\(Int(tpsVal.rounded()))t/s")
                            .font(.system(size: 8.5, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(isHighlighted ? color.opacity(0.14) : Color.primary.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(isHighlighted ? color.opacity(0.50) : color.opacity(0.28), lineWidth: 0.7)
                )
                .fixedSize(horizontal: true, vertical: true)
                .contentShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .onHover { hovering in
                    hoveredLegendAgentId = hovering ? series.agentId : nil
                }
                .help("\(displayLabel): \(Formatters.formatTokens(ctxVal))")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TelemetryLegendFlowLayout: Layout {
    var horizontalSpacing: CGFloat = 5
    var verticalSpacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var curX: CGFloat = 0
        var curY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var usedWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if curX > 0 && curX + size.width > maxWidth {
                usedWidth = max(usedWidth, curX - horizontalSpacing)
                curX = 0
                curY += rowHeight + verticalSpacing
                rowHeight = 0
            }
            curX += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }
        if curX > 0 {
            usedWidth = max(usedWidth, curX - horizontalSpacing)
        }
        let totalHeight = subviews.isEmpty ? 0 : curY + rowHeight
        let resolvedWidth = maxWidth.isFinite ? maxWidth : usedWidth
        return CGSize(width: resolvedWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var curX = bounds.minX
        var curY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if curX > bounds.minX && curX + size.width > bounds.maxX + 0.5 {
                curX = bounds.minX
                curY += rowHeight + verticalSpacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: curX, y: curY), proposal: ProposedViewSize(size))
            curX += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

enum SessionListFilter {

    static func sessionsForDisplay(_ sessions: [SessionItem]) -> [SessionItem] {
        let topIds = Set(sessions.map(\.uuid))
        return sessions.filter { item in
            item.parentConversationId.isEmpty || !topIds.contains(item.parentConversationId)
        }
    }
}

enum SessionLookup {

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

    static func sortedSubagents(_ subagents: [SessionItem]) -> [SessionItem] {
        subagents.sorted { lhs, rhs in
            if lhs.isRunning != rhs.isRunning {
                return lhs.isRunning && !rhs.isRunning
            }
            return false
        }
    }

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

enum SessionRowTrailingColumn: Hashable {
    case model
    case context
    case metrics
}

enum SessionRowBadgePolicy {
    static let modelFontSize: CGFloat = 9.5
    static let contextFontSize: CGFloat = 9.5
    static let modelColumnWidth: CGFloat = 70
    static let contextColumnWidth: CGFloat = 42
    static let metricsColumnWidth: CGFloat = 72
    static let showModelDefaultsKey = "agyhub.sessions.showModel"

    static func trailingColumns(showModel: Bool) -> [SessionRowTrailingColumn] {
        showModel ? [.context, .metrics, .model] : [.context, .metrics]
    }

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

    static func hasModel(_ rawModel: String) -> Bool {
        modelBadgeText(rawModel) != "-"
    }

    static func contextBadgeText(contextTokens: Int) -> String {
        guard contextTokens > 0 else { return "-" }
        return Formatters.formatTokens(contextTokens)
    }

    static func contextTooltip(contextTokens: Int, language: AppLanguage.Resolved = .zhHans) -> String {
        guard contextTokens > 0 else { return L10n.t(.contextEmptyTooltip, language) }
        return language == .zhHans
            ? "当前上下文: \(Formatters.formatTokens(contextTokens)) (\(contextTokens) tokens)"
            : "Context: \(Formatters.formatTokens(contextTokens)) (\(contextTokens) tokens)"
    }

    static func showsLiveTps(for session: SessionItem) -> Bool {
        session.isRunning
    }

    static func idleMetricsText(for session: SessionItem) -> String {
        let tokenStr = Formatters.formatTokens(session.totalTokensConsumed)
        let cacheStr = String(format: "%.0f%%", session.cachePct)
        return "\(tokenStr) \(cacheStr)"
    }

    static func isSubagentBadgeActive(for session: SessionItem) -> Bool {
        session.effectiveActiveSubagentCount > 0
    }

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
            let unit = (language == .en && active != 1) ? "Agents" : "Agent"
            return "\(active) \(unit) · \(tpsText)"
        }
        let unit = (language == .en && total != 1) ? "Agents" : "Agent"
        return "\(total) \(unit)"
    }

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
    var showModelColumn: Bool = false
    var horizontalPadding: CGFloat = 7
    var chartColorLink: SessionTelemetryColorLink? = nil
    var isHighlightedFromChart: Bool = false
    var onHoverChartHighlight: ((Bool) -> Void)? = nil
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.agyLanguage) private var lang
    @State private var isHovered = false

    private var isEmphasized: Bool {
        isHovered || isHighlightedFromChart
    }

    private var displayTitle: String {
        SessionTitleCleaner.cleanTitle(session.title, fallbackUUID: session.uuid, language: lang)
    }

    var body: some View {
        HStack(spacing: 5) {

            if let link = chartColorLink {
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(link.primaryTone.color)
                    .frame(width: isEmphasized ? 4 : 3, height: isEmphasized ? 18 : 15)
                    .shadow(
                        color: isHighlightedFromChart ? link.primaryTone.color.opacity(0.45) : .clear,
                        radius: 2.5
                    )
            }

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

            ScrollingSessionTitleView(
                title: displayTitle,
                font: .system(size: 12.5, weight: (session.isActivelyWorking || isHighlightedFromChart) ? .bold : .medium),
                foregroundColor: (session.isActivelyWorking || isHighlightedFromChart) ? .primary : Color.primary.opacity(0.88),
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
                    if let childTones = chartColorLink?.childTones, !childTones.isEmpty {
                        HStack(spacing: 2) {
                            ForEach(Array(childTones.prefix(3).enumerated()), id: \.offset) { _, tone in
                                Circle()
                                    .fill(tone.color)
                                    .frame(width: 5.5, height: 5.5)
                            }
                        }
                    }
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

            ForEach(SessionRowBadgePolicy.trailingColumns(showModel: showModelColumn), id: \.self) { column in
                trailingColumnView(for: column)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .frame(height: SessionListLayoutPolicy.rowEstimatedHeight)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(rowBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(rowBorderColor, lineWidth: isHighlightedFromChart ? 1.1 : 0.6)
        )
        .animation(.easeOut(duration: 0.14), value: isHighlightedFromChart)
        .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .onHover { hovering in
            isHovered = hovering
            onHoverChartHighlight?(hovering)
        }
    }

    private var rowBackgroundColor: Color {
        if let link = chartColorLink {
            if isHighlightedFromChart {
                return link.primaryTone.color.opacity(colorScheme == .dark ? 0.21 : 0.14)
            }
            if isHovered {
                return link.primaryTone.color.opacity(colorScheme == .dark ? 0.16 : 0.11)
            }
            return link.primaryTone.color.opacity(colorScheme == .dark ? 0.09 : 0.055)
        }
        if isHighlightedFromChart {
            return Color.accentColor.opacity(colorScheme == .dark ? 0.16 : 0.10)
        }
        return isHovered ? Color.primary.opacity(0.04) : Color.clear
    }

    private var rowBorderColor: Color {
        if let link = chartColorLink {
            if isHighlightedFromChart {
                return link.primaryTone.color.opacity(0.58)
            }
            return link.primaryTone.color.opacity(isHovered ? 0.36 : 0.18)
        }
        if isHighlightedFromChart {
            return Color.accentColor.opacity(0.45)
        }
        return .clear
    }

    @ViewBuilder
    private func trailingColumnView(for column: SessionRowTrailingColumn) -> some View {
        switch column {
        case .context:
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

        case .metrics:
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                if SessionRowBadgePolicy.showsLiveTps(for: session) {
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

        case .model:
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
                    .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("—")
                        .font(.system(size: 10))
                        .foregroundColor(Color.secondary.opacity(0.35))
                }
            }
            .frame(width: SessionRowBadgePolicy.modelColumnWidth, alignment: .trailing)
            .help(L10n.modelHelp(session.model, lang))
        }
    }
}

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

                    distributionSection(d)

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

extension AGYAppDelegate {

    enum HakimiBrandIcon {
        enum Status: Equatable {
            case idle
            case working
            case alert
        }

        static func resolveStatus(hasAlert: Bool, activeCount: Int) -> Status {
            if hasAlert { return .alert }
            if activeCount > 0 { return .working }
            return .idle
        }

        static func menuBarImage(state: Status) -> NSImage {
            let size = NSSize(width: 18, height: 18)
            let image = NSImage(size: size, flipped: true) { _ in

                let scale = 18.0 / 22.0
                guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
                ctx.saveGState()
                ctx.scaleBy(x: scale, y: scale)

                let baseColor: NSColor = (state == .alert) ? NSColor.labelColor : NSColor.black
                baseColor.setFill()

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

                ctx.setBlendMode(.clear)
                NSColor.black.setStroke()
                NSColor.black.setFill()

                switch state {
                case .idle:

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

                    let lSquint = NSBezierPath()
                    lSquint.move(to: NSPoint(x: 5.8, y: 11.4))
                    lSquint.line(to: NSPoint(x: 9.8, y: 12.6))
                    lSquint.lineWidth = 1.85
                    lSquint.lineCapStyle = .round
                    lSquint.stroke()

                    NSBezierPath(ovalIn: NSRect(x: 12.55, y: 10.55, width: 3.5, height: 3.1)).fill()

                case .alert:

                    NSBezierPath(ovalIn: NSRect(x: 5.95, y: 10.35, width: 3.5, height: 3.5)).fill()
                    NSBezierPath(ovalIn: NSRect(x: 12.55, y: 10.35, width: 3.5, height: 3.5)).fill()
                }

                if state == .alert {
                    ctx.setBlendMode(.normal)
                    NSColor(calibratedRed: 0.937, green: 0.267, blue: 0.267, alpha: 1.0).setFill()
                    NSBezierPath(ovalIn: NSRect(x: 15.4, y: 1.4, width: 5.6, height: 5.6)).fill()
                }

                ctx.restoreGState()
                return true
            }

            image.isTemplate = (state != .alert)
            return image
        }

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

struct SplitPaneDividerBar: View {
    var showsSeparatorLine: Bool = true
    let tooltip: String
    let onDragBegan: () -> Void
    let onDragChanged: (CGFloat) -> Void
    let onDragEnded: (CGFloat) -> Void
    let onDoubleClick: () -> Void

    @State private var isHovering = false
    @State private var isDragging = false

    var body: some View {
        ZStack {
            if showsSeparatorLine {
                Rectangle()
                    .fill(Color(nsColor: .separatorColor).opacity(isDragging ? 0.35 : (isHovering ? 0.22 : 0.0)))
                    .frame(height: 0.5)
            }

            Capsule()
                .fill(isDragging ? Color.accentColor : (isHovering ? Color.accentColor.opacity(0.75) : Color.primary.opacity(0.22)))
                .frame(
                    width: (isHovering || isDragging)
                        ? DashboardSplitLayoutPolicy.dividerPillHoverWidth
                        : DashboardSplitLayoutPolicy.dividerPillWidth,
                    height: (isHovering || isDragging)
                        ? DashboardSplitLayoutPolicy.dividerPillHoverHeight
                        : DashboardSplitLayoutPolicy.dividerPillHeight
                )
                .animation(.easeOut(duration: 0.12), value: isHovering || isDragging)

            SplitDividerAppKitView(
                onHoverChanged: { hovering in
                    isHovering = hovering
                },
                onDragBegan: {
                    isDragging = true
                    onDragBegan()
                },
                onDragChanged: onDragChanged,
                onDragEnded: { deltaY in
                    isDragging = false
                    onDragEnded(deltaY)
                },
                onDoubleClick: onDoubleClick
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .help(tooltip)
    }
}

private struct SplitDividerAppKitView: NSViewRepresentable {
    let onHoverChanged: (Bool) -> Void
    let onDragBegan: () -> Void
    let onDragChanged: (CGFloat) -> Void
    let onDragEnded: (CGFloat) -> Void
    let onDoubleClick: () -> Void

    final class Coordinator {
        var parent: SplitDividerAppKitView

        init(parent: SplitDividerAppKitView) {
            self.parent = parent
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> DividerTrackingNSView {
        let view = DividerTrackingNSView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: DividerTrackingNSView, context: Context) {
        context.coordinator.parent = self
        nsView.coordinator = context.coordinator
    }

    final class DividerTrackingNSView: NSView {
        weak var coordinator: Coordinator?
        private var trackingArea: NSTrackingArea?
        private var isDragging = false
        private var dragStartScreenY: CGFloat = 0

        override var mouseDownCanMoveWindow: Bool { false }

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            if let existing = trackingArea {
                removeTrackingArea(existing)
            }
            let area = NSTrackingArea(
                rect: .zero,
                options: [.mouseEnteredAndExited, .cursorUpdate, .activeAlways, .inVisibleRect],
                owner: self,
                userInfo: nil
            )
            addTrackingArea(area)
            trackingArea = area
        }

        override func resetCursorRects() {
            addCursorRect(bounds, cursor: .resizeUpDown)
        }

        override func cursorUpdate(with event: NSEvent) {
            NSCursor.resizeUpDown.set()
        }

        override func mouseEntered(with event: NSEvent) {
            NSCursor.resizeUpDown.set()
            coordinator?.parent.onHoverChanged(true)
        }

        override func mouseExited(with event: NSEvent) {
            if !isDragging {
                coordinator?.parent.onHoverChanged(false)
            }
        }

        override func mouseDown(with event: NSEvent) {
            if event.clickCount == 2 {
                isDragging = false
                coordinator?.parent.onDoubleClick()
                return
            }
            isDragging = true
            dragStartScreenY = NSEvent.mouseLocation.y
            NSCursor.resizeUpDown.set()
            coordinator?.parent.onDragBegan()
        }

        override func mouseDragged(with event: NSEvent) {
            guard isDragging else { return }
            let deltaDown = dragStartScreenY - NSEvent.mouseLocation.y
            coordinator?.parent.onDragChanged(deltaDown)
        }

        override func mouseUp(with event: NSEvent) {
            guard isDragging else { return }
            isDragging = false
            let deltaDown = dragStartScreenY - NSEvent.mouseLocation.y
            coordinator?.parent.onDragEnded(deltaDown)
            if !bounds.contains(convert(event.locationInWindow, from: nil)) {
                coordinator?.parent.onHoverChanged(false)
            }
        }
    }
}
