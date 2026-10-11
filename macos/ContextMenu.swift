import AppKit

// Opaque native host for the existing five context actions. It deliberately avoids
// NSMenu's system glass, automatic shortening and scrollable viewport on macOS 26.
final class ContextRow: NSButton {
    let entry: NSMenuItem
    private var hovered = false
    init(entry: NSMenuItem, index: Int, owner: ContextMenuController) {
        self.entry = entry
        super.init(frame: .zero)
        title = entry.title; tag = index; target = owner; action = #selector(ContextMenuController.choose(_:))
        isBordered = false; setButtonType(.momentaryPushIn); isEnabled = entry.isEnabled
        setAccessibilityLabel(entry.title)
    }
    required init?(coder: NSCoder) { fatalError() }
    override var isFlipped: Bool { true }
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self))
    }
    override func mouseEntered(with event: NSEvent) { hovered = true; needsDisplay = true }
    override func mouseExited(with event: NSEvent) { hovered = false; needsDisplay = true }
    override func draw(_ dirtyRect: NSRect) {
        let focused = window?.firstResponder === self
        if (hovered || focused || cell?.isHighlighted == true) && isEnabled {
            NSColor(hex: 0xeef7f2).setFill()
            NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 8, yRadius: 8).fill()
        }
        let color = isEnabled ? Ink.dark : Ink.muted
        if entry.state == .on { drawText("✓", in: NSRect(x: 8, y: 0, width: 20, height: bounds.height), size: 16, color: Ink.green) }
        if let image = entry.image {
            let tinted = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { r in
                image.draw(in: r); color.setFill(); r.fill(using: .sourceIn); return true
            }
            tinted.draw(in: NSRect(x: 33, y: (bounds.height - 18) / 2, width: 18, height: 18), from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        }
        drawText(title, in: NSRect(x: 64, y: 0, width: bounds.width - 74, height: bounds.height), size: 16, color: color)
    }
}
final class ContextCard: FlippedView {
    override func draw(_ dirtyRect: NSRect) {
        let card = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 12, yRadius: 12)
        NSColor.white.setFill(); card.fill()
        Ink.line.setStroke(); card.lineWidth = 1; card.stroke()
        Ink.line.setFill(); NSRect(x: 16, y: 166, width: bounds.width - 32, height: 1).fill()
    }
}
final class ContextPanel: NSPanel {
    var dismiss: (() -> Void)?
    override var canBecomeKey: Bool { true }
    override func cancelOperation(_ sender: Any?) { dismiss?() }
}
final class ContextMenuController: NSObject {
    private(set) var panel: ContextPanel?
    private var entries: [NSMenuItem] = []
    private var localMonitor: Any?
    private var globalMonitor: Any?
    static let size = NSSize(width: 250, height: 216)

    static func frame(click: NSPoint, work: NSRect) -> NSRect {
        // AppKit screen Y grows upwards: bottom-left is eight points above/right
        // of the click, so the entire popup occupies its upper-right quadrant.
        let x = (click.x + 8).clamped(work.minX...max(work.minX, work.maxX - size.width))
        let y = (click.y + 8).clamped(work.minY...max(work.minY, work.maxY - size.height))
        return NSRect(origin: NSPoint(x: x, y: y), size: size)
    }
    func show(_ menu: NSMenu, at point: NSPoint) {
        close()
        entries = menu.items.filter { !$0.isSeparatorItem }
        let work = NSScreen.screens.first { $0.frame.contains(point) }?.visibleFrame ?? NSScreen.main!.visibleFrame
        let window = ContextPanel(contentRect: Self.frame(click: point, work: work), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        window.title = "南枫 Codex 额度菜单"; window.isOpaque = false; window.backgroundColor = .clear
        window.hasShadow = true; window.hidesOnDeactivate = false; window.isReleasedWhenClosed = false
        window.level = .popUpMenu; window.appearance = NSAppearance(named: .aqua)
        window.dismiss = { [weak self] in self?.close() }
        let card = ContextCard(frame: NSRect(origin: .zero, size: Self.size))
        card.wantsLayer = true; card.layer?.cornerRadius = 12; card.layer?.masksToBounds = true
        for (index, entry) in entries.enumerated() {
            let row = ContextRow(entry: entry, index: index, owner: self)
            row.frame = NSRect(x: 8, y: 8 + CGFloat(index) * 40, width: Self.size.width - 16, height: 38)
            card.addSubview(row)
        }
        window.contentView = card; panel = window
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self, weak window] event in
            guard let self else { return event }
            if event.type == .keyDown && event.keyCode == 53 { self.close(); return nil }
            if event.type != .keyDown && event.window !== window { self.close() }
            return event
        }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in self?.close() }
        window.makeKeyAndOrderFront(nil)
    }
    @objc func choose(_ sender: NSButton) {
        guard entries.indices.contains(sender.tag) else { return }
        let entry = entries[sender.tag]
        guard entry.isEnabled, let action = entry.action else { return }
        close()
        NSApp.sendAction(action, to: entry.target, from: entry)
    }
    func close() {
        if let localMonitor { NSEvent.removeMonitor(localMonitor); self.localMonitor = nil }
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor); self.globalMonitor = nil }
        panel?.orderOut(nil); panel = nil; entries = []
    }
}
