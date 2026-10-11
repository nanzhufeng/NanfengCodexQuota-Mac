import AppKit
import ServiceManagement
import Darwin

// Native UI integration checks run with isolated settings and an explicit fixture CLI.
// They drive the same NSButton targets and NSWindow lifecycle as the shipped interface.
final class NativeQA {
    unowned let app: AppDelegate
    let root: URL
    var step = 0, ticks = 0
    var results: [String: Bool] = [:]
    var timer: Timer?
    let liveOnly: Bool
    init(app: AppDelegate, root: URL, liveOnly: Bool = false) { self.app = app; self.root = root; self.liveOnly = liveOnly }
    func check(_ name: String, _ value: Bool) { results[name] = value }
    func capture(_ name: String, view: NSView) {
        view.layoutSubtreeIfNeeded(); view.displayIfNeeded()
        guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: rep)
        try? rep.representation(using: .png, properties: [:])?.write(to: root.appendingPathComponent(name + ".png"))
    }
    func start() { timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(tick), userInfo: nil, repeats: true) }
    @objc func tick() {
        ticks += 1
        if ticks > 180 { check("completed_before_timeout", false); finish(); return }
        guard let view = app.settingsView, let snapshot = app.latest else { return }
        if liveOnly {
            guard snapshot.status == "已连接" && !snapshot.refreshing else { return }
            check("native_app_reads_real_service", true)
            check("login_stays_disabled", !app.loginEnabled)
            capture("live-settings", view: view)
            capture("live-widget", view: app.widgetView)
            let summary: [String: Any] = ["status": snapshot.status, "percentLabel": snapshot.percentLabel, "shortLabel": snapshot.shortLabel, "commit": snapshot.commit, "dirty": snapshot.dirty, "version": snapshot.version]
            try? JSONSerialization.data(withJSONObject: summary, options: [.prettyPrinted, .sortedKeys]).write(to: root.appendingPathComponent("live-summary.json"))
            finish(); return
        }
        switch step {
        case 0:
            guard snapshot.status == "已连接" else { return }
            check("weekly_and_short_window", snapshot.percentLabel == "34%" && snapshot.shortLabel == "剩余 77%")
            capture("settings", view: view); capture("widget", view: app.widgetView)
            let click = NSPoint(x: NSScreen.main!.visibleFrame.midX, y: NSScreen.main!.visibleFrame.midY)
            app.showContextMenu(at: click)
            if let menu = app.contextMenu.panel, let card = app.contextMenu.contentCard {
                let rows = card.subviews.compactMap { $0 as? ContextRow }
                check("context_menu_all_five_items", rows.map(\.title) == ["立即刷新", "打开主界面", "保持置顶", "隐藏悬浮窗", "退出"] && rows.allSatisfy { card.bounds.contains($0.frame) })
                let surface = app.contextMenu.surfaceFrame!
                check("context_menu_upper_right_anchor", surface.minX == click.x + 8 && surface.minY == click.y + 8 && surface.size == ContextMenuController.size)
                let anchored = menu.frame
                app.poll()
                check("context_menu_position_stable", menu.frame == anchored)
                capture("context-menu", view: menu.contentView!)
                rows[1].performClick(nil)
                check("context_menu_action_closes_panel", app.contextMenu.panel == nil && app.settingsWindow?.isVisible == true)
            }
            view.aboutButton.performClick(nil)
            check("about_navigation", view.about && !view.githubButton.isHidden && view.refreshButton.isHidden)
            capture("about", view: view)
            app.settingsWindow?.setContentSize(NSSize(width: 900, height: 640)); view.generalButton.performClick(nil); view.layoutSubtreeIfNeeded()
            check("minimum_layout", [view.refreshButton, view.positionButton, view.topButton, view.startupButton, view.intervalButton].allSatisfy { view.bounds.contains($0!.frame) })
            capture("minimum", view: view)
            app.settingsWindow?.setContentSize(NSSize(width: 1064, height: 711))
            view.topButton.performClick(nil)
            check("top_toggle_off", !app.settings.always_on_top && app.panel.level == .normal)
            view.topButton.performClick(nil)
            check("top_toggle_on", app.settings.always_on_top && app.panel.level == .floating)
            let interval = NSMenuItem(); interval.tag = 120; app.setInterval(interval)
            check("interval_change", app.settings.interval_secs == 120)
            app.toggleVisible(); check("hide_widget", !app.panel.isVisible)
            view.positionButton.performClick(nil); check("find_hidden_widget", app.panel.isVisible)
            app.panel.setFrameOrigin(NSPoint(x: 240, y: 260)); app.savePosition()
            check("position_persistence", app.settings.x == 240 && app.settings.y == 260)
            app.settingsWindow?.close(); check("close_keeps_widget_alive", app.panel.isVisible)
            app.openSettings(); check("reopen_settings", app.settingsWindow?.isVisible == true)
            step = 10
        case 10:
            guard !snapshot.refreshing else { return }
            try? "failure".write(to: root.appendingPathComponent("fixture-state"), atomically: true, encoding: .utf8)
            app.refresh(); step = 1
        case 1:
            guard snapshot.status == "连接失败" else { return }
            check("failure_preserves_success", snapshot.percentLabel == "34%" && snapshot.statusKind == "warning")
            capture("failure", view: view)
            try? "missing".write(to: root.appendingPathComponent("fixture-state"), atomically: true, encoding: .utf8)
            app.refresh(); step = 2
        case 2:
            guard snapshot.status == "已连接" && !snapshot.refreshing else { return }
            check("missing_window_is_unknown", snapshot.percentLabel == "--%" && snapshot.shortLabel == "接口未提供")
            capture("missing", view: view)
            try? "success".write(to: root.appendingPathComponent("fixture-state"), atomically: true, encoding: .utf8)
            app.refresh(); step = 3
        case 3:
            guard snapshot.percentLabel == "34%" && snapshot.status == "已连接" else { return }
            check("recovery", true)
            app.panel.setFrameOrigin(NSPoint(x: 99999, y: 99999)); app.restorePosition()
            check("offscreen_recovery", NSScreen.screens.contains { $0.visibleFrame.contains(app.panel.frame) })
            app.settingsWindow?.orderOut(nil)
            let second = Process(); second.executableURL = Bundle.main.executableURL; second.arguments = ["--qa-root", root.path, "--qa-cli", app.qaCLI!]
            try? second.run()
            step = 4
        case 4:
            guard app.settingsWindow?.isVisible == true else { return }
            check("single_instance_reopens_existing", true)
            check("login_not_registered_during_qa", !app.loginEnabled)
            check("completed_before_timeout", true)
            finish()
        default: break
        }
    }
    func finish() {
        timer?.invalidate()
        let data = try? JSONSerialization.data(withJSONObject: results, options: [.prettyPrinted, .sortedKeys])
        try? data?.write(to: root.appendingPathComponent("native-qa.json"))
        app.quitApp()
    }
}
