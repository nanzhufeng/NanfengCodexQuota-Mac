import AppKit
import ServiceManagement
import Darwin

struct Layout {
    let width: CGFloat, height: CGFloat
    var divider: CGFloat { floor(width * 0.43) }
    var right: CGFloat { divider + 40 }
    var leftWidth: CGFloat { divider - 68 }
    var ring: CGFloat { min(min(floor(leftWidth * 0.73), height - 386), 280).clamped(190...280) }
    var ringX: CGFloat { 34 + (leftWidth - ring) / 2 }
    var dataY: CGFloat { 190 + ring + 20 }
}
extension CGFloat { func clamped(_ range: ClosedRange<CGFloat>) -> CGFloat { Swift.min(Swift.max(self, range.lowerBound), range.upperBound) } }

final class SettingsView: FlippedView {
    unowned let app: AppDelegate
    var about = false
    var snapshot: Snapshot?
    private(set) var generalButton: PillButton!
    private(set) var aboutButton: PillButton!
    private(set) var refreshButton: PillButton!
    private(set) var positionButton: PillButton!
    private(set) var topButton: PillButton!
    private(set) var startupButton: PillButton!
    private(set) var intervalButton: PillButton!
    private(set) var githubButton: PillButton!
    private var badge = BadgeView()
    private var labels: [String: NSTextField] = [:]
    init(app: AppDelegate) {
        self.app = app
        super.init(frame: NSRect(x: 0, y: 0, width: 1064, height: 711))
        wantsLayer = true; layer?.backgroundColor = NSColor.white.cgColor
        generalButton = PillButton("常规", style: .tab, target: self, action: #selector(general))
        aboutButton = PillButton("关于", style: .tab, target: self, action: #selector(showAbout))
        refreshButton = PillButton("立即刷新", style: .primary, target: app, action: #selector(AppDelegate.refresh), symbol: "arrow.clockwise")
        positionButton = PillButton("找回悬浮窗", style: .secondary, target: app, action: #selector(AppDelegate.findWidget), symbol: "macwindow")
        topButton = PillButton("保持悬浮窗置顶", style: .toggle, target: app, action: #selector(AppDelegate.setTop(_:)))
        startupButton = PillButton("登录 Mac 时启动", style: .toggle, target: app, action: #selector(AppDelegate.setStartup(_:)))
        intervalButton = PillButton("60 秒", style: .choice, target: self, action: #selector(intervalMenu))
        githubButton = PillButton("GitHub · nanzhufeng/NanfengCodexQuota-Windows ↗", style: .link, target: app, action: #selector(AppDelegate.openGitHub))
        for b in [generalButton, aboutButton, refreshButton, positionButton, topButton, startupButton, intervalButton, githubButton] { addSubview(b!) }
        addSubview(badge)
        for (key, text, size, weight, color, align) in [
            ("quotaTitle", "周剩余额度", 24.0, NSFont.Weight.semibold, Ink.dark, NSTextAlignment.left),
            ("percent", "--%", 54.0, .bold, Ink.dark, .center),
            ("remaining", "剩余", 16.0, .regular, Ink.muted, .center),
            ("resetName", "下次重置", 16.0, .regular, Ink.dark, .left),
            ("reset", "接口未提供", 16.0, .regular, Ink.dark, .left),
            ("sampleName", "最近成功", 16.0, .regular, Ink.dark, .left),
            ("sample", "尚无成功记录", 16.0, .regular, Ink.dark, .left),
            ("shortName", "五小时", 16.0, .regular, Ink.muted, .left),
            ("short", "接口未提供", 16.0, .regular, Ink.muted, .left),
            ("prefs", "悬浮窗偏好", 24.0, .semibold, Ink.dark, .left),
            ("instant", "设置即时生效。", 16.0, .regular, Ink.muted, .left),
            ("intervalName", "刷新间隔", 18.0, .regular, Ink.dark, .left),
            ("topName", "保持悬浮窗置顶", 18.0, .regular, Ink.dark, .left),
            ("startupName", "登录 Mac 时启动", 18.0, .regular, Ink.dark, .left),
            ("footer", "只读监控，不调用模型。", 14.0, .regular, Ink.muted, .left)
        ] {
            let label = NSTextField(labelWithString: text)
            label.font = NSFont.systemFont(ofSize: size, weight: weight)
            label.textColor = color; label.alignment = align
            label.maximumNumberOfLines = 1; label.lineBreakMode = .byClipping
            labels[key] = label; addSubview(label)
        }
        layout()
    }
    required init?(coder: NSCoder) { fatalError() }
    @objc func general() { about = false; layout(); needsDisplay = true }
    @objc func showAbout() { about = true; layout(); needsDisplay = true }
    @objc func intervalMenu() {
        let menu = NSMenu()
        for s in [30, 60, 120, 300, 600] {
            let item = NSMenuItem(title: "\(s) 秒", action: #selector(AppDelegate.setInterval(_:)), keyEquivalent: "")
            item.target = app; item.tag = s
            item.state = app.settings.interval_secs == s ? .on : .off
            menu.addItem(item)
        }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: intervalButton.bounds.height + 2), in: intervalButton)
    }
    override func layout() {
        super.layout()
        let l = Layout(width: bounds.width, height: bounds.height)
        generalButton.frame = NSRect(x: l.width - 234, y: 27, width: 90, height: 44)
        aboutButton.frame = NSRect(x: l.width - 124, y: 27, width: 90, height: 44)
        generalButton.state = about ? .off : .on; aboutButton.state = about ? .on : .off
        githubButton.isHidden = !about
        for b in [refreshButton, positionButton, topButton, startupButton, intervalButton] { b?.isHidden = about }
        labels.values.forEach { $0.isHidden = about }; badge.isHidden = about
        let cardW = min(660, l.width - 96)
        githubButton.frame = NSRect(x: (l.width - cardW) / 2 + 24, y: 414, width: cardW - 48, height: 28)
        refreshButton.frame = NSRect(x: 34, y: l.height - 78, width: l.leftWidth, height: 50)
        positionButton.frame = NSRect(x: l.right, y: l.height - 155, width: 282, height: 50)
        topButton.frame = NSRect(x: l.width - 110, y: 334, width: 72, height: 34)
        startupButton.frame = NSRect(x: l.width - 110, y: 440, width: 72, height: 34)
        intervalButton.frame = NSRect(x: l.width - 216, y: 220, width: 180, height: 44)
        badge.frame = NSRect(x: 34, y: 151, width: 110, height: 30)
        func place(_ name: String, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
            guard let label = labels[name] else { return }
            let fh = label.font!.ascender - label.font!.descender + 2
            label.frame = NSRect(x: x, y: y + (h - fh) / 2, width: w, height: fh)
        }
        place("quotaTitle", 34, 108, l.leftWidth, 36)
        place("percent", l.ringX + l.ring / 2 - 80, 190 + l.ring / 2 - 42, 160, 70)
        place("remaining", l.ringX + l.ring / 2 - 50, 190 + l.ring / 2 + 29, 100, 26)
        for (i, names) in [("resetName", "reset"), ("sampleName", "sample"), ("shortName", "short")].enumerated() {
            place(names.0, 68, l.dataY + CGFloat(i * 34), 114, 28)
            place(names.1, 180, l.dataY + CGFloat(i * 34), l.divider - 206, 28)
        }
        let rw = l.width - l.right - 36
        place("prefs", l.right, 108, rw, 36)
        place("instant", l.right, 151, rw, 30)
        place("intervalName", l.right + 52, 226, rw - 258, 34)
        place("topName", l.right + 52, 332, rw - 156, 34)
        place("startupName", l.right + 52, 438, rw - 156, 34)
        place("footer", l.right, l.height - 52, rw, 28)
        needsDisplay = true
    }
    func update(_ snapshot: Snapshot, loginState: Bool) {
        self.snapshot = snapshot
        labels["percent"]?.stringValue = snapshot.percentLabel
        labels["reset"]?.stringValue = snapshot.resetLabel
        labels["sample"]?.stringValue = snapshot.sampledLabel
        labels["short"]?.stringValue = snapshot.shortLabel
        labels["instant"]?.stringValue = snapshot.suggestion.isEmpty ? "设置即时生效。" : snapshot.suggestion
        // Long errors use a tooltip while the layout retains its fixed one-line anchor.
        labels["instant"]?.toolTip = snapshot.suggestion
        labels["instant"]?.lineBreakMode = .byTruncatingTail
        topButton.state = snapshot.config.always_on_top ? .on : .off
        startupButton.state = loginState ? .on : .off
        intervalButton.title = "\(snapshot.config.interval_secs) 秒"
        refreshButton.title = "立即刷新"
        refreshButton.isEnabled = !snapshot.refreshing
        badge.text = snapshot.status; badge.kind = snapshot.statusKind; badge.needsDisplay = true
        [topButton, startupButton, intervalButton, refreshButton].forEach { $0?.needsDisplay = true }
        needsDisplay = true
    }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.setFill(); bounds.fill()
        let l = Layout(width: bounds.width, height: bounds.height)
        func line(_ a: NSPoint, _ b: NSPoint) {
            Ink.line.setStroke(); let p = NSBezierPath(); p.move(to: a); p.line(to: b); p.lineWidth = 1; p.stroke()
        }
        line(NSPoint(x: 0, y: 86), NSPoint(x: l.width, y: 86))
        if about { drawAbout(l); return }
        line(NSPoint(x: l.divider, y: 108), NSPoint(x: l.divider, y: l.height - 24))
        for y in [CGFloat(294), 400, l.height - 70] { line(NSPoint(x: l.right, y: y), NSPoint(x: l.width - 36, y: y)) }
        let center = NSPoint(x: l.ringX + l.ring / 2, y: 190 + l.ring / 2)
        func arc(_ start: CGFloat, _ sweep: CGFloat, _ color: NSColor) {
            guard sweep > 0 else { return }
            let p = NSBezierPath(); p.appendArc(withCenter: center, radius: l.ring / 2 - 11, startAngle: start, endAngle: start + sweep, clockwise: false)
            p.lineWidth = 21; p.lineCapStyle = .round; color.setStroke(); p.stroke()
        }
        arc(-90, 360, NSColor(hex: 0xedf1f2))
        if let remaining = snapshot?.remaining {
            let sweep = CGFloat(remaining) * 3.6
            arc(-90, sweep, NSColor(hex: 0x12bb77))
            let tail = min(11, sweep); arc(-90 + sweep - tail, tail, NSColor(hex: 0xff9b1b))
        }
        for (i, name) in ["calendar", "clock", "xmark"].enumerated() {
            drawSymbol(name, in: NSRect(x: 34, y: l.dataY + CGFloat(i * 34) + 3, width: 24, height: 24), color: i == 2 ? Ink.muted : Ink.dark)
        }
        for (i, name) in ["clock", "pin", "power"].enumerated() {
            drawSymbol(name, in: NSRect(x: l.right + 2, y: 230 + CGFloat(i * 106), width: 24, height: 24))
        }
    }
    private func drawAbout(_ l: Layout) {
        let width = min(660, l.width - 96), left = (l.width - width) / 2
        drawText("关于", in: NSRect(x: left, y: 109, width: width, height: 38), size: 24, weight: .semibold, align: .center)
        let card = NSBezierPath(roundedRect: NSRect(x: left, y: 166, width: width, height: min(l.height - 192, 458)), xRadius: 16, yRadius: 16)
        Ink.line.setStroke(); card.lineWidth = 1; card.stroke()
        let commit = String((snapshot?.commit ?? "不可用").prefix(12))
        let local = snapshot?.dirty == true ? "（本地改动）" : ""
        let groups = [
            ("产品信息", "南枫 Codex 额度\nmacOS 只读额度悬浮窗，复用本机 Codex 登录。"),
            ("版本信息", "Mac 版 \(snapshot?.version ?? "0.1.4") · 开发日期 2026-10-11\nGit Commit：\(commit)\(local)"),
            ("开发者信息", "开发者：席瑞\n联系邮箱：nanzhufeng.studio@gmail.com\n版权所有 © 2026 席瑞")
        ]
        for (i, group) in groups.enumerated() {
            let y = CGFloat(188 + i * 139)
            drawText(group.0, in: NSRect(x: left + 24, y: y, width: width - 48, height: 28), weight: .semibold)
            let paragraph = NSMutableParagraphStyle(); paragraph.lineSpacing = 2
            (group.1 as NSString).draw(in: NSRect(x: left + 24, y: y + 36, width: width - 48, height: 82), withAttributes: [.font: NSFont.systemFont(ofSize: 16), .foregroundColor: Ink.dark, .paragraphStyle: paragraph])
            if i < 2 { Ink.line.setFill(); NSRect(x: left + 24, y: y + 126, width: width - 48, height: 1).fill() }
        }
        setAccessibilityLabel("关于南枫 Codex 额度，Mac 版 \(snapshot?.version ?? "")，Git Commit \(commit)\(local)，开发者席瑞")
    }
}
