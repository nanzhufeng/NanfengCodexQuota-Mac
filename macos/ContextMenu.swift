import AppKit

// Native glass host for the existing five context actions, with explicit compact
// geometry so titles stay complete and the click anchor never moves.
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
            NSColor.black.withAlphaComponent(0.06).setFill()
            NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 6, yRadius: 6).fill()
        }
        let color = isEnabled ? Ink.dark : Ink.muted
        if entry.state == .on { drawText("✓", in: NSRect(x: 6, y: 0, width: 14, height: bounds.height), size: 13, color: Ink.green) }
        if let image = entry.image {
            let tinted = NSImage(size: NSSize(width: 14, height: 14), flipped: false) { r in
                image.draw(in: r); color.setFill(); r.fill(using: .sourceIn); return true
            }
            tinted.draw(in: NSRect(x: 25, y: (bounds.height - 14) / 2, width: 14, height: 14), from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        }
        drawText(title, in: NSRect(x: 48, y: 0, width: bounds.width - 56, height: bounds.height), size: 13, color: color)
    }
}
final class ContextCard: FlippedView {
    override func draw(_ dirtyRect: NSRect) {
        NSColor.labelColor.withAlphaComponent(0.13).setFill()
        NSRect(x: 12, y: 127, width: bounds.width - 24, height: 1 / (window?.backingScaleFactor ?? 2)).fill()
    }
}
// Draw only the rounded shadow, outside the unchanged glass surface. The clear
// inset gives it room to fade without exposing the rectangular window bounds.
final class ContextSurfaceHost: NSView {
    static let inset: CGFloat = 16
    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let surface = bounds.insetBy(dx: Self.inset, dy: Self.inset)
        let path = CGPath(roundedRect: surface, cornerWidth: 11, cornerHeight: 11, transform: nil)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -2), blur: 10, color: NSColor.black.withAlphaComponent(0.16).cgColor)
        context.setFillColor(NSColor.white.cgColor)
        context.addPath(path); context.fillPath()
        context.setShadow(offset: .zero, blur: 0, color: nil)
        context.setBlendMode(.clear)
        context.addPath(path); context.fillPath()
        context.restoreGState()
    }
}
final class ContextPanel: NSPanel {
    var dismiss: (() -> Void)?
    override var canBecomeKey: Bool { true }
    override func cancelOperation(_ sender: Any?) { dismiss?() }
}
final class ContextMenuController: NSObject {
    private(set) var panel: ContextPanel?
    private(set) var contentCard: ContextCard?
    var surfaceFrame: NSRect? {
        guard let panel, let contentCard else { return nil }
        return panel.convertToScreen(contentCard.convert(contentCard.bounds, to: nil))
    }
    private var entries: [NSMenuItem] = []
    private var localMonitor: Any?
    private var globalMonitor: Any?
    static let size = NSSize(width: 190, height: 166)

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
        let surface = Self.frame(click: point, work: work)
        let inset = ContextSurfaceHost.inset
        let window = ContextPanel(contentRect: surface.insetBy(dx: -inset, dy: -inset), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        window.title = "南枫 Codex 额度菜单"; window.isOpaque = false; window.backgroundColor = .clear
        // Use the rounded surface shadow, not a second rectangular window shadow.
        window.hasShadow = false; window.hidesOnDeactivate = false; window.isReleasedWhenClosed = false
        window.level = .popUpMenu; window.appearance = NSAppearance(named: .aqua)
        window.dismiss = { [weak self] in self?.close() }
        let card = ContextCard(frame: NSRect(origin: .zero, size: Self.size))
        let host = ContextSurfaceHost(frame: NSRect(origin: .zero, size: window.frame.size))
        let glassFrame = NSRect(origin: NSPoint(x: inset, y: inset), size: Self.size)
        card.wantsLayer = true
        for (index, entry) in entries.enumerated() {
            let row = ContextRow(entry: entry, index: index, owner: self)
            row.frame = NSRect(x: 6, y: 6 + CGFloat(index) * 30 + (index == 4 ? 4 : 0), width: Self.size.width - 12, height: 28)
            card.addSubview(row)
        }
        if #available(macOS 26.0, *) {
            let glass = NSGlassEffectView(frame: glassFrame)
            glass.style = .regular; glass.cornerRadius = 11
            glass.tintColor = NSColor.white.withAlphaComponent(0.08)
            glass.contentView = card
            host.addSubview(glass)
        } else {
            let glass = NSVisualEffectView(frame: glassFrame)
            glass.material = .menu; glass.blendingMode = .behindWindow; glass.state = .active
            glass.wantsLayer = true; glass.layer?.cornerRadius = 11; glass.layer?.masksToBounds = true
            glass.addSubview(card); host.addSubview(glass)
        }
        window.contentView = host
        contentCard = card; panel = window
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
        panel?.orderOut(nil); panel = nil; contentCard = nil; entries = []
    }
}
