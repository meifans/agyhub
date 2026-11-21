//
//  AppLifecycle.swift
//  Agyhub (macOS 状态栏多账号隔离切换与实时监控工具)
//
//  架构说明：
//  - macOS 13.0+ 原生 Swift + SwiftUI 状态栏常驻应用 (MenuBarExtra .window 样式)
//  - 严格遵守防封号安全红线：
//    1. 零网络请求（无任何 URLSession / Socket 调用，可通过 Little Snitch / Wireshark 验证）
//    2. 零 OAuth 令牌提取或官方接口轮询
//    3. 100% 纯本地文件读取（异步调用 agy-monitor.py --json 解析 SQLite 与 JSONL）
//    4. 账号切换采用官方原生 --user-data-dir 物理目录隔离与 --extensions-dir 插件共享方案
//


import AppKit
import Combine
import SwiftUI

// MARK: - 8. 毛玻璃视觉背景包装 (NSVisualEffectView)

struct VisualEffectBlurView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - 8.1 原生标准 Mac 窗口与生命周期控制 (AGYMainWindow & Lifecycle)

/// 主窗与独立窗的可拖拽尺寸上下限与持久化夹逼策略
enum WindowSizePolicy {
    static let defaultMainSize = NSSize(width: 464, height: 520)
    static let defaultStandaloneSize = NSSize(width: 476, height: 560)
    static let mainMinSize = NSSize(width: 440, height: 380)
    static let mainMaxSize = NSSize(width: 1200, height: 1400)

    static let mainWidthDefaultsKey = "agyhub.mainWindow.width"
    static let mainHeightDefaultsKey = "agyhub.mainWindow.height"
    static let standaloneWidthDefaultsKey = "agyhub.standaloneWindow.width"
    static let standaloneHeightDefaultsKey = "agyhub.standaloneWindow.height"

    static func clampedWindowSize(width: CGFloat?, height: CGFloat?, defaultSize: NSSize) -> NSSize {
        let rawW = (width ?? 0) > 0 ? width! : defaultSize.width
        let rawH = (height ?? 0) > 0 ? height! : defaultSize.height
        return NSSize(
            width: min(max(rawW, mainMinSize.width), mainMaxSize.width),
            height: min(max(rawH, mainMinSize.height), mainMaxSize.height)
        )
    }

    static func loadSavedSize(widthKey: String, heightKey: String, defaultSize: NSSize) -> NSSize {
        let ud = UserDefaults.standard
        let w = ud.object(forKey: widthKey) as? Double
        let h = ud.object(forKey: heightKey) as? Double
        return clampedWindowSize(
            width: w.map { CGFloat($0) },
            height: h.map { CGFloat($0) },
            defaultSize: defaultSize
        )
    }

    static func saveSize(_ size: NSSize, widthKey: String, heightKey: String) {
        let clamped = clampedWindowSize(width: size.width, height: size.height, defaultSize: size)
        UserDefaults.standard.set(Double(clamped.width), forKey: widthKey)
        UserDefaults.standard.set(Double(clamped.height), forKey: heightKey)
    }
}

/// 顶部叉号关闭窗口策略：点叉只隐藏对应窗口，绝不终止常驻菜单栏进程
enum WindowClosePolicy {
    enum Action: Equatable {
        case hideMainWindow
        case hideStandaloneWindow
    }

    static let headerCloseTooltip = "关闭窗口"

    static func headerCloseTooltip(language: AppLanguage.Resolved) -> String {
        L10n.t(.closeWindow, language)
    }

    static func action(isStandaloneWindow: Bool) -> Action {
        isStandaloneWindow ? .hideStandaloneWindow : .hideMainWindow
    }

    @MainActor
    static func performClose(
        isStandaloneWindow: Bool,
        mainWindow: NSWindow?,
        standaloneWindow: NSWindow?
    ) {
        switch action(isStandaloneWindow: isStandaloneWindow) {
        case .hideMainWindow:
            mainWindow?.orderOut(nil)
        case .hideStandaloneWindow:
            standaloneWindow?.orderOut(nil)
        }
    }
}

/// 可触发窗口边缘缩放的方向位掩码（AppKit 本地坐标，bottom=minY, top=maxY）
struct WindowResizeEdges: OptionSet, Equatable {
    let rawValue: Int
    static let left = WindowResizeEdges(rawValue: 1 << 0)
    static let right = WindowResizeEdges(rawValue: 1 << 1)
    static let bottom = WindowResizeEdges(rawValue: 1 << 2)
    static let top = WindowResizeEdges(rawValue: 1 << 3)
}

/// 窗口四周热区与对边锚定缩放策略：扩大圆角内侧与四边命中范围（8pt 边 + 16pt 角），彻底解决 14pt 圆角外透明导致系统箭头极难选中的问题
enum WindowResizeEdgePolicy {
    static let horizontalEdgeInset: CGFloat = 8.0
    static let verticalEdgeInset: CGFloat = 6.5
    static let cornerExtent: CGFloat = 16.0

    /// 判断给定本地坐标是否落在四周缩放热区内；内部按钮/滚动条/正文区域返回 nil 以完全透传事件
    static func resizeEdge(at point: NSPoint, in bounds: NSRect) -> WindowResizeEdges? {
        guard bounds.width > cornerExtent * 2,
              bounds.height > cornerExtent * 2,
              bounds.contains(point) else {
            return nil
        }

        let inLeftCornerBand = point.x <= cornerExtent
        let inRightCornerBand = point.x >= bounds.maxX - cornerExtent
        let inBottomCornerBand = point.y <= cornerExtent
        let inTopCornerBand = point.y >= bounds.maxY - cornerExtent

        if inLeftCornerBand && inBottomCornerBand { return [.left, .bottom] }
        if inRightCornerBand && inBottomCornerBand { return [.right, .bottom] }
        if inLeftCornerBand && inTopCornerBand { return [.left, .top] }
        if inRightCornerBand && inTopCornerBand { return [.right, .top] }

        var edges: WindowResizeEdges = []
        if point.x <= horizontalEdgeInset {
            edges.insert(.left)
        } else if point.x >= bounds.maxX - horizontalEdgeInset {
            edges.insert(.right)
        }
        if point.y <= verticalEdgeInset {
            edges.insert(.bottom)
        } else if point.y >= bounds.maxY - verticalEdgeInset {
            edges.insert(.top)
        }
        return edges.isEmpty ? nil : edges
    }

    /// 返回用于 AppKit `addCursorRect` 的 8 个不重叠边缘/角热区矩形
    static func cursorZones(in bounds: NSRect) -> [(NSRect, WindowResizeEdges)] {
        let w = bounds.width
        let h = bounds.height
        guard w > cornerExtent * 2, h > cornerExtent * 2 else { return [] }
        return [
            (NSRect(x: 0, y: 0, width: cornerExtent, height: cornerExtent), [.left, .bottom]),
            (NSRect(x: w - cornerExtent, y: 0, width: cornerExtent, height: cornerExtent), [.right, .bottom]),
            (NSRect(x: 0, y: h - cornerExtent, width: cornerExtent, height: cornerExtent), [.left, .top]),
            (NSRect(x: w - cornerExtent, y: h - cornerExtent, width: cornerExtent, height: cornerExtent), [.right, .top]),
            (NSRect(x: 0, y: cornerExtent, width: horizontalEdgeInset, height: h - cornerExtent * 2), .left),
            (NSRect(x: w - horizontalEdgeInset, y: cornerExtent, width: horizontalEdgeInset, height: h - cornerExtent * 2), .right),
            (NSRect(x: cornerExtent, y: 0, width: w - cornerExtent * 2, height: verticalEdgeInset), .bottom),
            (NSRect(x: cornerExtent, y: h - verticalEdgeInset, width: w - cornerExtent * 2, height: verticalEdgeInset), .top),
        ]
    }

    /// 根据命中的边缘或角位返回对应的原生缩放光标（macOS 15+ 使用官方 8 向 `frameResize` 斜向/双向箭头）
    static func cursor(for edges: WindowResizeEdges) -> NSCursor {
        if #available(macOS 15.0, *) {
            switch edges {
            case [.top, .left]: return .frameResize(position: .topLeft, directions: .all)
            case [.top, .right]: return .frameResize(position: .topRight, directions: .all)
            case [.bottom, .left]: return .frameResize(position: .bottomLeft, directions: .all)
            case [.bottom, .right]: return .frameResize(position: .bottomRight, directions: .all)
            case .left: return .frameResize(position: .left, directions: .all)
            case .right: return .frameResize(position: .right, directions: .all)
            case .top: return .frameResize(position: .top, directions: .all)
            case .bottom: return .frameResize(position: .bottom, directions: .all)
            default: break
            }
        }
        if edges.contains(.left) || edges.contains(.right) {
            return .resizeLeftRight
        }
        if edges.contains(.top) || edges.contains(.bottom) {
            return .resizeUpDown
        }
        return .arrow
    }

    /// 计算拖拽边缘后的新窗口 Frame：严密锚定对边/对角，夹逼到 minSize/maxSize 时也不会推动窗口整体位移
    static func resizedFrame(
        from startFrame: NSRect,
        edge: WindowResizeEdges,
        deltaX: CGFloat,
        deltaY: CGFloat,
        minSize: NSSize,
        maxSize: NSSize
    ) -> NSRect {
        var newX = startFrame.minX
        var newY = startFrame.minY
        var newW = startFrame.width
        var newH = startFrame.height

        if edge.contains(.right) {
            newW = min(max(startFrame.width + deltaX, minSize.width), maxSize.width)
        } else if edge.contains(.left) {
            newW = min(max(startFrame.width - deltaX, minSize.width), maxSize.width)
            newX = startFrame.maxX - newW
        }

        if edge.contains(.top) {
            newH = min(max(startFrame.height + deltaY, minSize.height), maxSize.height)
        } else if edge.contains(.bottom) {
            newH = min(max(startFrame.height - deltaY, minSize.height), maxSize.height)
            newY = startFrame.maxY - newH
        }

        return NSRect(x: newX, y: newY, width: newW, height: newH)
    }
}

/// 透明浮于窗口四周与四角的高容错缩放热区视图：非边缘坐标 hitTest 返回 nil，完全不拦截任何按钮、滚动条与面板交互
final class WindowResizeEdgeView: NSView {
    private var trackingArea: NSTrackingArea?

    override var isFlipped: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        guard WindowResizeEdgePolicy.resizeEdge(at: local, in: bounds) != nil else {
            return nil
        }
        return self
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        for (rect, edge) in WindowResizeEdgePolicy.cursorZones(in: bounds) {
            addCursorRect(rect, cursor: WindowResizeEdgePolicy.cursor(for: edge))
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        // 使用 activeAlways 确保即使当前焦点在其他 App，鼠标移到 Agyhub 边框时也能立刻亮出缩放箭头
        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .mouseMoved, .cursorUpdate, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseMoved(with event: NSEvent) {
        updateCursor(for: event)
    }

    override func cursorUpdate(with event: NSEvent) {
        updateCursor(for: event)
    }

    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
    }

    private func updateCursor(for event: NSEvent) {
        let local = convert(event.locationInWindow, from: nil)
        if let edge = WindowResizeEdgePolicy.resizeEdge(at: local, in: bounds) {
            WindowResizeEdgePolicy.cursor(for: edge).set()
        } else {
            NSCursor.arrow.set()
        }
    }

    override func mouseDown(with event: NSEvent) {
        let local = convert(event.locationInWindow, from: nil)
        guard let window = self.window,
              let edge = WindowResizeEdgePolicy.resizeEdge(at: local, in: bounds) else {
            super.mouseDown(with: event)
            return
        }

        if !NSApp.isActive {
            NSApp.activate(ignoringOtherApps: true)
        }
        if !window.isKeyWindow {
            window.makeKeyAndOrderFront(nil)
        }

        let startFrame = window.frame
        let startMouse = NSEvent.mouseLocation
        let cursor = WindowResizeEdgePolicy.cursor(for: edge)
        let minSize = window.minSize
        let maxSize = window.maxSize

        cursor.push()
        defer {
            NSCursor.pop()
            window.invalidateCursorRects(for: self)
        }

        while true {
            guard let nextEvent = window.nextEvent(matching: [.leftMouseDragged, .leftMouseUp]) else {
                break
            }
            if nextEvent.type == .leftMouseUp {
                break
            }
            let currentMouse = NSEvent.mouseLocation
            let nextFrame = WindowResizeEdgePolicy.resizedFrame(
                from: startFrame,
                edge: edge,
                deltaX: currentMouse.x - startMouse.x,
                deltaY: currentMouse.y - startMouse.y,
                minSize: minSize,
                maxSize: maxSize
            )
            cursor.set()
            window.setFrame(nextFrame, display: true)
        }
    }
}

struct WindowResizeOverlay: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowResizeEdgeView {
        WindowResizeEdgeView()
    }

    func updateNSView(_ nsView: WindowResizeEdgeView, context: Context) {}
}

/// 右下角极简斜向抓手暗线提示，直观传递可自由拖拽调整大小的状态
struct ResizeCornerGripView: View {
    var body: some View {
        Canvas { context, size in
            var p1 = Path()
            p1.move(to: CGPoint(x: size.width - 9, y: size.height - 3))
            p1.addLine(to: CGPoint(x: size.width - 3, y: size.height - 9))
            var p2 = Path()
            p2.move(to: CGPoint(x: size.width - 6, y: size.height - 3))
            p2.addLine(to: CGPoint(x: size.width - 3, y: size.height - 6))
            context.stroke(p1, with: .color(.secondary.opacity(0.28)), lineWidth: 1.0)
            context.stroke(p2, with: .color(.secondary.opacity(0.28)), lineWidth: 1.0)
        }
        .frame(width: 14, height: 14)
        .padding(3)
        .allowsHitTesting(false)
    }
}

/// 原生标准应用窗口，具备完整 Key/Main 响应能力、可自由拖拽缩放、系统级阴影与 Cmd+Shift+4+空格截屏拾取能力
final class AGYMainWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    static func create<Content: View>(width: CGFloat, height: CGFloat, rootView: Content) -> AGYMainWindow {
        let initialSize = WindowSizePolicy.clampedWindowSize(
            width: width,
            height: height,
            defaultSize: NSSize(width: width, height: height)
        )
        let window = AGYMainWindow(
            contentRect: NSRect(origin: .zero, size: initialSize),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Agyhub"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        window.isMovable = true
        window.isMovableByWindowBackground = true
        window.level = .normal
        window.hasShadow = true
        window.sharingType = .readOnly
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isReleasedWhenClosed = false
        window.minSize = WindowSizePolicy.mainMinSize
        window.maxSize = WindowSizePolicy.mainMaxSize
        window.collectionBehavior = [.managed, .moveToActiveSpace, .fullScreenAuxiliary]

        let hosting = NSHostingController(rootView: rootView)
        window.contentViewController = hosting
        // 必须在挂载为 contentViewController 之后先清空 sizingOptions 再设 safeAreaRegions，否则任一提前访问都会在默认 sizingOptions 下触发 NSHostingView 初始化并导致 AutoLayout 死循环崩溃
        if #available(macOS 13.0, *) {
            hosting.sizingOptions = []
        }
        if #available(macOS 13.3, *) {
            hosting.safeAreaRegions = []
        }
        window.setContentSize(initialSize)
        return window
    }
}

/// 失焦窗口唤醒保护：后台窗口被点击置前后的极短时间窗内拦截误触切号，防止点窗口查看数据时意外切号
enum WindowActivationGuard {
    static let activationGraceWindow: TimeInterval = 0.35
    private static var lastFocusClickAt: Date = .distantPast

    static func markActivatedByClick(at date: Date = Date()) {
        lastFocusClickAt = date
    }

    static func shouldAllowAccountSwitch(lastFocusClickAt: Date? = nil, now: Date = Date()) -> Bool {
        let refDate = lastFocusClickAt ?? Self.lastFocusClickAt
        return now.timeIntervalSince(refDate) >= activationGraceWindow
    }
}

/// 挂载在主面板根层级，确保点击窗口内任意位置即刻激活应用并置前为 Key 窗口
final class WindowLifecycleView: NSView {
    private var eventMonitor: Any?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window = self.window else { return }

        if eventMonitor == nil {
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak window] event in
                guard let win = window, event.window == win else { return event }
                let needsActivation = !NSApp.isActive || !win.isKeyWindow
                if event.type == .leftMouseDown, needsActivation {
                    WindowActivationGuard.markActivatedByClick()
                }
                if !NSApp.isActive {
                    NSApp.activate(ignoringOtherApps: true)
                }
                if !win.isKeyWindow {
                    win.makeKeyAndOrderFront(nil)
                }
                return event
            }
        }
    }

    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

struct WindowLifecycleConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowLifecycleView {
        WindowLifecycleView()
    }

    func updateNSView(_ nsView: WindowLifecycleView, context: Context) {}
}

/// 允许按住顶部空白区或标题栏使用原生系统拖动（同时适配状态栏主窗口与独立窗口）
struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> DraggableNSView {
        DraggableNSView()
    }

    func updateNSView(_ nsView: DraggableNSView, context: Context) {}

    final class DraggableNSView: NSView {
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

        override func mouseDown(with event: NSEvent) {
            guard let window = self.window else {
                super.mouseDown(with: event)
                return
            }
            if !NSApp.isActive {
                NSApp.activate(ignoringOtherApps: true)
            }
            window.makeKeyAndOrderFront(nil)
            window.performDrag(with: event)
        }
    }
}

// MARK: - 9. 应用生命周期入口 (状态栏常驻 + 原生 NSWindow 调度)

@MainActor
/// 动态进程激活策略：有窗口打开时切换为 .regular 恢复完整的 Mac 顶部应用菜单与 Cmd+Tab，全部关闭后切回 .accessory 保持菜单栏常驻
enum WindowActivationPolicy {
    nonisolated static func targetPolicy(hasVisibleWindows: Bool) -> NSApplication.ActivationPolicy {
        hasVisibleWindows ? .regular : .accessory
    }
}

@MainActor
final class AGYAppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: AGYAppDelegate?

    private var store: AGYHubStore!
    private var statusItem: NSStatusItem!
    private var mainWindow: AGYMainWindow?
    private var standaloneWindow: AGYMainWindow?
    private var hasUserMovedMainWindow = false
    private var isProgrammaticPositioning = false
    private var cancellables = Set<AnyCancellable>()

    nonisolated override init() {
        super.init()
    }

    nonisolated static func buildMainMenu(target: AnyObject?, language: AppLanguage.Resolved = .zhHans) -> NSMenu {
        let mainMenu = NSMenu()

        // 1. 应用菜单 (Agyhub)
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "Agyhub")
        appMenu.addItem(withTitle: L10n.t(.menuAboutAgyhub, language), action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: L10n.t(.menuHideAgyhub, language), action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = appMenu.addItem(withTitle: L10n.t(.menuHideOthers, language), action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(withTitle: L10n.t(.menuShowAll, language), action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: L10n.t(.menuQuitAgyhub, language), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // 2. 编辑菜单（确保弹窗输入框等原生支持 Cmd+C / Cmd+V / Cmd+A）
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: L10n.t(.menuEdit, language))
        editMenu.addItem(withTitle: L10n.t(.menuCut, language), action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: L10n.t(.menuCopy, language), action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: L10n.t(.menuPaste, language), action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: L10n.t(.menuSelectAll, language), action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // 3. 窗口菜单（确保 Cmd+W / Cmd+M 等原生窗口控制可用）
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: L10n.t(.menuWindow, language))
        windowMenu.addItem(withTitle: L10n.t(.closeWindow, language), action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowMenu.addItem(withTitle: L10n.t(.menuMinimize, language), action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: L10n.t(.menuZoom, language), action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        return mainMenu
    }

    nonisolated static func buildStatusContextMenu(
        target: AnyObject?,
        language: AppLanguage.Resolved = .zhHans,
        currentLanguage: AppLanguage = .system
    ) -> NSMenu {
        let menu = NSMenu()

        let showItem = NSMenuItem(
            title: L10n.t(.statusMenuShowDashboard, language),
            action: #selector(showMainWindowMenuAction),
            keyEquivalent: ""
        )
        showItem.target = target
        menu.addItem(showItem)

        let standaloneItem = NSMenuItem(
            title: L10n.t(.statusMenuOpenStandalone, language),
            action: #selector(openStandaloneWindowMenuAction),
            keyEquivalent: ""
        )
        standaloneItem.target = target
        menu.addItem(standaloneItem)

        let refreshItem = NSMenuItem(
            title: L10n.t(.statusMenuRefreshNow, language),
            action: #selector(refreshNowMenuAction),
            keyEquivalent: "r"
        )
        refreshItem.target = target
        menu.addItem(refreshItem)

        menu.addItem(.separator())

        let langMenuItem = NSMenuItem(title: L10n.t(.languageSettingLabel, language), action: nil, keyEquivalent: "")
        let langSubmenu = NSMenu(title: L10n.t(.languageSettingLabel, language))
        for option in AppLanguage.allCases {
            let item = NSMenuItem(
                title: option.pickerLabel(for: language),
                action: #selector(selectLanguageMenuAction(_:)),
                keyEquivalent: ""
            )
            item.target = target
            item.representedObject = option.rawValue
            item.state = (option == currentLanguage) ? .on : .off
            langSubmenu.addItem(item)
        }
        langMenuItem.submenu = langSubmenu
        menu.addItem(langMenuItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: L10n.t(.menuQuitAgyhub, language),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        return menu
    }

    func ensureStore() -> AGYHubStore {
        if let existing = store {
            return existing
        }
        let created = AGYHubStore()
        store = created
        return created
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        AGYAppDelegate.shared = self
        let activeStore = ensureStore()
        // 挂载原生系统菜单栏；初始无窗口打开时保持 .accessory 常驻状态栏，开窗时自动升为 .regular
        NSApp.mainMenu = Self.buildMainMenu(target: self, language: activeStore.resolvedLanguage)
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        setupMainWindow()
    }

    private func syncActivationPolicy() {
        let mainVisible = (mainWindow?.isVisible == true) && !(mainWindow?.isMiniaturized ?? false)
        let standaloneVisible = (standaloneWindow?.isVisible == true) && !(standaloneWindow?.isMiniaturized ?? false)
        let hasVisible = mainVisible || standaloneVisible
        store?.setDashboardVisible(hasVisible)
        let desired = WindowActivationPolicy.targetPolicy(hasVisibleWindows: hasVisible)
        if NSApp.activationPolicy() != desired {
            NSApp.setActivationPolicy(desired)
        }
        if desired == .regular && NSApp.mainMenu == nil {
            let resolved = store?.resolvedLanguage ?? AppLanguage.load().resolved()
            NSApp.mainMenu = Self.buildMainMenu(target: self, language: resolved)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        store?.shutdownBackgroundWorkers()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func closeWindow(isStandaloneWindow: Bool) {
        WindowClosePolicy.performClose(
            isStandaloneWindow: isStandaloneWindow,
            mainWindow: mainWindow,
            standaloneWindow: standaloneWindow
        )
        syncActivationPolicy()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            let initialState = HakimiBrandIcon.resolveStatus(
                hasAlert: store.payload.hasAlert,
                activeCount: store.payload.menubar.activeCount
            )
            button.imagePosition = .imageOnly
            button.title = ""
            button.image = HakimiBrandIcon.menuBarImage(state: initialState)
            button.toolTip = HakimiBrandIcon.formatTooltip(store.payload.menubar.text, language: store.resolvedLanguage)
            button.target = self
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        Publishers.CombineLatest4(
            store.$payload.map(\.menubar.text).removeDuplicates(),
            store.$payload.map(\.menubar.activeCount).removeDuplicates(),
            store.$payload.map(\.hasAlert).removeDuplicates(),
            store.$appLanguage.removeDuplicates()
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] text, activeCount, hasAlert, lang in
            guard let self = self else { return }
            let resolved = lang.resolved()
            let state = HakimiBrandIcon.resolveStatus(hasAlert: hasAlert, activeCount: activeCount)
            self.statusItem.button?.title = ""
            self.statusItem.button?.image = HakimiBrandIcon.menuBarImage(state: state)
            self.statusItem.button?.toolTip = HakimiBrandIcon.formatTooltip(text, language: resolved)
        }
        .store(in: &cancellables)

        store.$appLanguage
            .dropFirst()
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] lang in
                guard let self = self else { return }
                NSApp.mainMenu = Self.buildMainMenu(target: self, language: lang.resolved())
            }
            .store(in: &cancellables)
    }

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        if let event = NSApp.currentEvent,
           event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            let menu = Self.buildStatusContextMenu(
                target: self,
                language: store.resolvedLanguage,
                currentLanguage: store.appLanguage
            )
            statusItem.menu = menu
            sender.performClick(nil)
            statusItem.menu = nil
            return
        }
        toggleMainWindow()
    }

    @objc private func showMainWindowMenuAction() {
        showMainWindow()
    }

    @objc private func openStandaloneWindowMenuAction() {
        openStandaloneWindow()
    }

    @objc private func refreshNowMenuAction() {
        store.fetchMonitorData()
        store.refreshQuotasIfNeeded(force: true)
        store.refreshRecent503IfNeeded(force: true)
        if store.isUsageDashboardPresented {
            store.fetchUsageHistory(force: true)
        }
    }

    @objc private func selectLanguageMenuAction(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let lang = AppLanguage(rawValue: raw) else { return }
        store.updateAppLanguage(lang)
    }

    private func setupMainWindow() {
        let savedSize = WindowSizePolicy.loadSavedSize(
            widthKey: WindowSizePolicy.mainWidthDefaultsKey,
            heightKey: WindowSizePolicy.mainHeightDefaultsKey,
            defaultSize: WindowSizePolicy.defaultMainSize
        )
        let win = AGYMainWindow.create(
            width: savedSize.width,
            height: savedSize.height,
            rootView: MainDashboardView(store: store, isStandaloneWindow: false)
        )
        NotificationCenter.default.publisher(for: NSWindow.didMoveNotification, object: win)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self, !self.isProgrammaticPositioning else { return }
                self.hasUserMovedMainWindow = true
            }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: NSWindow.didResizeNotification, object: win)
            .receive(on: RunLoop.main)
            .sink { [weak win] _ in
                guard let w = win else { return }
                WindowSizePolicy.saveSize(
                    w.contentLayoutRect.size,
                    widthKey: WindowSizePolicy.mainWidthDefaultsKey,
                    heightKey: WindowSizePolicy.mainHeightDefaultsKey
                )
            }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: NSWindow.willCloseNotification, object: win)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async { self?.syncActivationPolicy() }
            }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: NSWindow.didMiniaturizeNotification, object: win)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.syncActivationPolicy()
            }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: NSWindow.didDeminiaturizeNotification, object: win)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.syncActivationPolicy()
            }
            .store(in: &cancellables)
        mainWindow = win
    }

    @objc func toggleMainWindow() {
        guard let win = mainWindow else {
            setupMainWindow()
            showMainWindow()
            return
        }
        if win.isVisible && win.isKeyWindow && NSApp.isActive {
            win.orderOut(nil)
            syncActivationPolicy()
        } else {
            showMainWindow()
        }
    }

    func showMainWindow() {
        if mainWindow == nil {
            setupMainWindow()
        }
        guard let win = mainWindow else { return }

        if !hasUserMovedMainWindow,
           let button = statusItem.button,
           let buttonWindow = button.window {
            let buttonFrame = buttonWindow.frame
            let winWidth = win.frame.width
            let winHeight = win.frame.height
            let targetScreen = buttonWindow.screen ?? NSScreen.main
            let screenFrame = targetScreen?.visibleFrame ?? .zero
            let fullFrame = targetScreen?.frame ?? screenFrame
            let menuBarFloorY = fullFrame.maxY - max(NSStatusBar.system.thickness, 24) - 6
            var x = buttonFrame.midX - winWidth / 2
            x = max(screenFrame.minX + 8, min(x, screenFrame.maxX - winWidth - 8))
            let topY = min(buttonFrame.minY - 6, min(screenFrame.maxY - 6, menuBarFloorY))
            let y = max(screenFrame.minY + 8, topY - winHeight)

            isProgrammaticPositioning = true
            win.setFrameOrigin(NSPoint(x: x, y: y))
            isProgrammaticPositioning = false
        }

        win.makeKeyAndOrderFront(nil)
        syncActivationPolicy()
        NSApp.activate(ignoringOtherApps: true)
        win.invalidateShadow()
    }

    func openStandaloneWindow() {
        if standaloneWindow == nil {
            let savedSize = WindowSizePolicy.loadSavedSize(
                widthKey: WindowSizePolicy.standaloneWidthDefaultsKey,
                heightKey: WindowSizePolicy.standaloneHeightDefaultsKey,
                defaultSize: WindowSizePolicy.defaultStandaloneSize
            )
            let win = AGYMainWindow.create(
                width: savedSize.width,
                height: savedSize.height,
                rootView: MainDashboardView(store: store, isStandaloneWindow: true)
            )
            win.center()
            NotificationCenter.default.publisher(for: NSWindow.didResizeNotification, object: win)
                .receive(on: RunLoop.main)
                .sink { [weak win] _ in
                    guard let w = win else { return }
                    WindowSizePolicy.saveSize(
                        w.contentLayoutRect.size,
                        widthKey: WindowSizePolicy.standaloneWidthDefaultsKey,
                        heightKey: WindowSizePolicy.standaloneHeightDefaultsKey
                    )
                }
                .store(in: &cancellables)
            NotificationCenter.default.publisher(for: NSWindow.willCloseNotification, object: win)
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in
                    DispatchQueue.main.async { self?.syncActivationPolicy() }
                }
                .store(in: &cancellables)
            NotificationCenter.default.publisher(for: NSWindow.didMiniaturizeNotification, object: win)
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in
                    self?.syncActivationPolicy()
                }
                .store(in: &cancellables)
            NotificationCenter.default.publisher(for: NSWindow.didDeminiaturizeNotification, object: win)
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in
                    self?.syncActivationPolicy()
                }
                .store(in: &cancellables)
            standaloneWindow = win
        }
        guard let win = standaloneWindow else { return }
        win.makeKeyAndOrderFront(nil)
        syncActivationPolicy()
        NSApp.activate(ignoringOtherApps: true)
        win.invalidateShadow()
    }
}

private struct LocalizedSettingsSceneView: View {
    @ObservedObject var store: AGYHubStore

    var body: some View {
        SettingsPopoverView(store: store)
            .environment(\.agyLanguage, store.resolvedLanguage)
    }
}

#if !AGYHUB_TESTING
@main
#endif
struct AGYHubApp: App {
    @NSApplicationDelegateAdaptor(AGYAppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            LocalizedSettingsSceneView(store: appDelegate.ensureStore())
        }
    }
}
