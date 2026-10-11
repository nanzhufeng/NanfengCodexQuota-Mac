import AppKit
import ServiceManagement
import Darwin

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var core: Core!
    var settings = Settings()
    var latest: Snapshot?
    var panel: WidgetPanel!
    var widgetView: WidgetView!
    var settingsWindow: NSWindow?
    var settingsView: SettingsView?
    var statusItem: NSStatusItem!
    private var timer: Timer?
    private var positionTimer: Timer?
    private var instanceFD: Int32 = -1
    private var quitting = false
    private var restoring = false
    var qaRoot: String?
    var qaCLI: String?
    private var notificationName: Notification.Name!
    private var qa: NativeQA?
    var loginEnabled: Bool { qaRoot == nil && SMAppService.mainApp.status == .enabled }

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            let args = CommandLine.arguments
            func option(_ name: String) -> String? { guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }; return args[i + 1] }
            qaRoot = option("--qa-root"); qaCLI = option("--qa-cli")
            if qaCLI != nil && qaRoot == nil { throw NSError(domain: "Quota", code: 3, userInfo: [NSLocalizedDescriptionKey: "隔离 CLI 必须同时指定隔离设置目录"]) }
            let base = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/NanfengCodexQuota")
            let directory = qaRoot.map { URL(fileURLWithPath: $0) } ?? base
            if qaRoot != nil && directory.standardizedFileURL == base.standardizedFileURL { throw NSError(domain: "Quota", code: 4, userInfo: [NSLocalizedDescriptionKey: "测试目录不能使用正式设置目录"]) }
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
            let lockURL = directory.appendingPathComponent("instance.lock")
            // One advisory lock per settings root; kernel releases it even after an abnormal exit.
            instanceFD = Darwin.open(lockURL.path, O_CREAT | O_RDWR | O_CLOEXEC, 0o600)
            guard instanceFD >= 0 else { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno)) }
            notificationName = Notification.Name("studio.nanzhufeng.codex-quota.show." + Data(directory.path.utf8).base64EncodedString())
            if flock(instanceFD, LOCK_EX | LOCK_NB) != 0 {
                guard errno == EWOULDBLOCK || errno == EAGAIN else { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno)) }
                DistributedNotificationCenter.default().postNotificationName(notificationName, object: nil, userInfo: nil, deliverImmediately: true)
                Darwin.close(instanceFD); instanceFD = -1
                NSApp.terminate(nil); return
            }
            ftruncate(instanceFD, 0)
            let pid = "\(ProcessInfo.processInfo.processIdentifier)"
            pid.withCString { _ = Darwin.write(instanceFD, $0, strlen($0)) }
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(reopen), name: notificationName, object: nil)
            core = try Core(path: directory.appendingPathComponent("settings.toml").path, cli: qaCLI)
            guard let first = core.snapshot() else { throw NSError(domain: "Quota", code: 5, userInfo: [NSLocalizedDescriptionKey: "额度状态解码失败"]) }
            settings = first.config; latest = first
            buildWidget(); buildStatusItem(); buildAppMenu()
            NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(wake), name: NSWorkspace.didWakeNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(screenChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
            timer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(poll), userInfo: nil, repeats: true)
            RunLoop.main.add(timer!, forMode: .common)
            if args.contains("--show-settings") || args.contains("--qa-run") || args.contains("--verify-live") { openSettings() }
            if args.contains("--qa-run"), let qaRoot { qa = NativeQA(app: self, root: URL(fileURLWithPath: qaRoot)); qa?.start() }
            if args.contains("--verify-live"), let qaRoot { qa = NativeQA(app: self, root: URL(fileURLWithPath: qaRoot), liveOnly: true); qa?.start() }
        } catch {
            showError(error.localizedDescription)
            NSApp.terminate(nil)
        }
    }
    private func buildWidget() {
        panel = WidgetPanel(contentRect: NSRect(x: settings.x, y: settings.y, width: 132, height: 132), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.title = "南枫 Codex 额度悬浮窗"; panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = false
        panel.hidesOnDeactivate = false; panel.isFloatingPanel = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.level = settings.always_on_top ? .floating : .normal
        widgetView = WidgetView(app: self); panel.contentView = widgetView; panel.delegate = self
        widgetView.snapshot = latest
        restorePosition(); panel.orderFrontRegardless()
    }
    private func buildStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            let image = Bundle.main.url(forResource: "AppIcon", withExtension: "icns").flatMap { NSImage(contentsOf: $0) }
            image?.size = NSSize(width: 20, height: 20); button.image = image
            button.target = self; button.action = #selector(statusClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp]); button.toolTip = "南枫 Codex 额度"
        }
    }
    private func buildAppMenu() {
        let menu = NSMenu(), item = NSMenuItem(), submenu = NSMenu()
        item.submenu = submenu; menu.addItem(item)
        let open = NSMenuItem(title: "打开主界面", action: #selector(openSettings), keyEquivalent: ","); open.target = self; submenu.addItem(open)
        let refresh = NSMenuItem(title: "立即刷新", action: #selector(self.refresh), keyEquivalent: "r"); refresh.target = self; submenu.addItem(refresh)
        submenu.addItem(.separator())
        let quit = NSMenuItem(title: "退出南枫 Codex 额度", action: #selector(quitApp), keyEquivalent: "q"); quit.target = self; submenu.addItem(quit)
        NSApp.mainMenu = menu
    }
    func makeMenu() -> NSMenu {
        let menu = NSMenu()
        for (title, symbol, action, checked, disabled) in [
            ("立即刷新", "arrow.clockwise", #selector(refresh), false, latest?.refreshing == true),
            ("打开主界面", "macwindow", #selector(openSettings), false, false),
            ("保持置顶", "pin", #selector(toggleTop), settings.always_on_top, false),
            (panel.isVisible ? "隐藏悬浮窗" : "显示悬浮窗", panel.isVisible ? "eye.slash" : "eye", #selector(toggleVisible), false, false),
            ("退出", "power", #selector(quitApp), false, false)
        ] {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.target = self; item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
            item.state = checked ? .on : .off; item.isEnabled = !disabled
            menu.addItem(item)
        }
        menu.autoenablesItems = false
        return menu
    }
    @objc func statusClick(_ sender: Any?) {
        if NSApp.currentEvent?.type != .rightMouseUp { openSettings(); return }
        statusItem.menu = makeMenu(); statusItem.button?.performClick(nil); statusItem.menu = nil
    }
    @objc func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1064, height: 711), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
            window.title = "南枫 Codex 额度"; window.contentMinSize = NSSize(width: 900, height: 640)
            window.isReleasedWhenClosed = false; window.delegate = self
            window.appearance = NSAppearance(named: .aqua); window.backgroundColor = .white
            let view = SettingsView(app: self); window.contentView = view
            settingsWindow = window; settingsView = view; window.center()
        }
        if let latest { settingsView?.update(latest, loginState: loginEnabled) }
        NSApp.activate(ignoringOtherApps: true); settingsWindow?.makeKeyAndOrderFront(nil)
    }
    @objc func reopen() { findWidget(); openSettings() }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { reopen(); return false }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationDidBecomeActive(_ notification: Notification) {
        guard let core, let latest else { return }
        let actual = loginEnabled
        if qaRoot == nil && settings.start_at_login != actual {
            var c = settings; c.start_at_login = actual
            do { try core.configure(c); settings = c } catch { showError(error.localizedDescription) }
        }
        settingsView?.update(latest, loginState: actual)
    }
    @objc func poll() {
        guard !quitting, let snapshot = core?.snapshot() else { return }
        if snapshot == latest { return }
        settings = snapshot.config; latest = snapshot
        widgetView?.snapshot = snapshot; settingsView?.update(snapshot, loginState: loginEnabled)
        statusItem?.button?.toolTip = "南枫 Codex 额度\n" + snapshot.details
    }
    @objc func refresh() { core?.refresh(); poll() }
    private func apply(_ config: Settings) {
        do {
            try core.configure(config); settings = config
            panel.level = config.always_on_top ? .floating : .normal
            poll()
        } catch { showError(error.localizedDescription); poll() }
    }
    @objc func setTop(_ sender: NSButton) { var c = settings; c.always_on_top = sender.state == .on; apply(c) }
    @objc func toggleTop() { var c = settings; c.always_on_top.toggle(); apply(c) }
    @objc func setInterval(_ sender: NSMenuItem) { var c = settings; c.interval_secs = sender.tag; apply(c) }
    @objc func setStartup(_ sender: NSButton) {
        // Test paths must never create a production login service.
        guard qaRoot == nil else { sender.state = .off; return }
        let enabled = sender.state == .on
        let service = SMAppService.mainApp
        do {
            if enabled { try service.register() } else { try service.unregister() }
            var c = settings; c.start_at_login = loginEnabled
            try core.configure(c); settings = c
            if service.status == .requiresApproval {
                showError("请在系统设置 → 通用 → 登录项中允许南枫 Codex 额度。授权完成后会显示真实启用状态。")
                SMAppService.openSystemSettingsLoginItems()
            }
        } catch {
            showError("无法更新登录启动：\(error.localizedDescription)")
        }
        poll()
    }
    @objc func toggleVisible() { if panel.isVisible { savePosition(); panel.orderOut(nil) } else { restorePosition(); panel.orderFrontRegardless() } }
    @objc func findWidget() {
        let work = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        restoring = true; panel.setFrameOrigin(NSPoint(x: work.midX - 66, y: work.midY - 66)); restoring = false
        panel.orderFrontRegardless(); savePosition()
    }
    func restorePosition() {
        guard let panel else { return }
        let frame = panel.frame
        let screens = NSScreen.screens.map(\.visibleFrame)
        let nearest = screens.max { $0.intersection(frame).width * $0.intersection(frame).height < $1.intersection(frame).width * $1.intersection(frame).height }
        let work = nearest.flatMap { $0.intersects(frame) ? $0 : nil } ?? NSScreen.main?.visibleFrame
        guard let work else { return }
        let p = NSPoint(x: frame.minX.clamped(work.minX...max(work.minX, work.maxX - 132)), y: frame.minY.clamped(work.minY...max(work.minY, work.maxY - 132)))
        restoring = true; panel.setFrameOrigin(p); restoring = false
    }
    func savePosition() {
        guard !restoring, let panel, core != nil else { return }
        var c = settings; c.x = Int(panel.frame.minX.rounded()); c.y = Int(panel.frame.minY.rounded())
        if c.x != settings.x || c.y != settings.y { apply(c) }
    }
    func windowDidMove(_ notification: Notification) {
        guard notification.object as? NSWindow === panel, !restoring else { return }
        positionTimer?.invalidate()
        positionTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in self?.savePosition() }
    }
    @objc func screenChanged() { restorePosition(); savePosition() }
    @objc func wake() { restorePosition(); core?.refresh() }
    @objc func openGitHub() { NSWorkspace.shared.open(URL(string: "https://github.com/nanzhufeng/NanfengCodexQuota-Windows")!) }
    @objc func quitApp() { NSApp.terminate(nil) }
    func applicationWillTerminate(_ notification: Notification) {
        if panel != nil { savePosition() }
        quitting = true; timer?.invalidate(); positionTimer?.invalidate(); core?.close()
        if instanceFD >= 0 { flock(instanceFD, LOCK_UN); Darwin.close(instanceFD); instanceFD = -1 }
        DistributedNotificationCenter.default().removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    func showError(_ message: String) {
        let alert = NSAlert(); alert.messageText = "南枫 Codex 额度"; alert.informativeText = message; alert.addButton(withTitle: "好")
        NSApp.activate(ignoringOtherApps: true); alert.runModal()
    }
}
