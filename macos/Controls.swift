import AppKit
import ServiceManagement
import Darwin

enum Ink {
    static let dark = NSColor(hex: 0x142536)
    static let muted = NSColor(hex: 0x75818c)
    static let green = NSColor(hex: 0x07975b)
    static let orange = NSColor(hex: 0xff7d16)
    static let line = NSColor(hex: 0xe8edef)
    static let selected = NSColor(hex: 0xe1f6eb)
}
extension NSColor {
    convenience init(hex: UInt32) {
        self.init(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
    }
}
func drawText(_ text: String, in rect: NSRect, size: CGFloat = 16, weight: NSFont.Weight = .regular, color: NSColor = Ink.dark, align: NSTextAlignment = .left) {
    let paragraph = NSMutableParagraphStyle(); paragraph.alignment = align
    let font = NSFont.systemFont(ofSize: size, weight: weight)
    let textHeight = font.ascender - font.descender
    let r = NSRect(x: rect.minX, y: rect.minY + max(0, (rect.height - textHeight) / 2 - 1), width: rect.width, height: max(textHeight + 4, rect.height))
    (text as NSString).draw(in: r, withAttributes: [.font: font, .foregroundColor: color, .paragraphStyle: paragraph])
}
func drawSymbol(_ name: String, in rect: NSRect, color: NSColor = Ink.dark) {
    guard let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?.withSymbolConfiguration(.init(pointSize: rect.height, weight: .regular)) else { return }
    let tinted = NSImage(size: rect.size, flipped: false) { imageRect in
        image.draw(in: imageRect, from: .zero, operation: .sourceOver, fraction: 1)
        color.setFill(); imageRect.fill(using: .sourceIn)
        return true
    }
    tinted.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
}
class FlippedView: NSView { override var isFlipped: Bool { true } }
final class PillButton: NSButton {
    enum Style { case tab, primary, secondary, toggle, link, choice }
    let style: Style
    var symbol: String?
    private var hover = false
    init(_ title: String, style: Style, target: AnyObject, action: Selector, symbol: String? = nil) {
        self.style = style; self.symbol = symbol
        super.init(frame: .zero)
        self.title = title; self.target = target; self.action = action
        isBordered = false
        setButtonType(style == .toggle ? .toggle : .momentaryPushIn)
        setAccessibilityLabel(title)
        if style == .toggle { setAccessibilityRole(.checkBox) }
    }
    required init?(coder: NSCoder) { fatalError() }
    override var isFlipped: Bool { true }
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeInActiveApp, .mouseEnteredAndExited, .inVisibleRect], owner: self))
    }
    override func mouseEntered(with event: NSEvent) { hover = true; needsDisplay = true }
    override func mouseExited(with event: NSEvent) { hover = false; needsDisplay = true }
    override func draw(_ dirtyRect: NSRect) {
        let r = bounds.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(roundedRect: r, xRadius: r.height / 2, yRadius: r.height / 2)
        let pressed = cell?.isHighlighted == true
        var fill = NSColor.white
        var textColor = Ink.dark
        switch style {
        case .tab:
            fill = state == .on ? Ink.selected : (hover ? NSColor(hex: 0xf6faf8) : .white)
            textColor = state == .on ? Ink.green : Ink.dark
        case .primary:
            fill = !isEnabled ? NSColor(hex: 0xffbe87) : NSColor(hex: pressed ? 0xed6b05 : (hover ? 0xff8a27 : 0xff7d16))
            textColor = .white
        case .toggle:
            fill = state == .on ? Ink.green : NSColor(hex: 0xc9d2d8)
            if pressed { fill = fill.blended(withFraction: 0.15, of: .black)! }
        case .secondary, .choice:
            fill = hover ? NSColor(hex: 0xf5faf8) : .white
        case .link:
            textColor = hover ? Ink.green : NSColor(hex: 0x2768a6)
        }
        if style != .link { fill.setFill(); path.fill() }
        if style == .secondary || style == .choice { NSColor(hex: 0xb8c7d1).setStroke(); path.lineWidth = 1; path.stroke() }
        if style == .toggle {
            let diameter = r.height - 6
            let knob = NSRect(x: state == .on ? r.maxX - diameter - 3 : r.minX + 3, y: r.minY + 3, width: diameter, height: diameter)
            NSColor.white.setFill(); NSBezierPath(ovalIn: knob).fill()
            setAccessibilityValue(state == .on ? 1 : 0)
        } else if style == .choice {
            drawText(title, in: NSRect(x: 16, y: 0, width: bounds.width - 48, height: bounds.height), color: textColor)
            drawSymbol("chevron.down", in: NSRect(x: bounds.width - 28, y: (bounds.height - 12) / 2, width: 12, height: 12), color: textColor)
        } else if let symbol {
            let size: CGFloat = 18
            let width = (title as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: 16)]).width + 34
            let left = (bounds.width - width) / 2
            drawSymbol(symbol, in: NSRect(x: left, y: (bounds.height - size) / 2, width: size, height: size), color: textColor)
            drawText(title, in: NSRect(x: left + 34, y: 0, width: width - 34, height: bounds.height), color: textColor)
        } else {
            drawText(title, in: bounds, size: style == .tab ? 18 : 16, weight: style == .tab ? .semibold : .regular, color: textColor, align: style == .link ? .left : .center)
        }
        if window?.firstResponder === self {
            Ink.green.withAlphaComponent(0.65).setStroke()
            let focus = NSBezierPath(roundedRect: bounds.insetBy(dx: 3, dy: 3), xRadius: (bounds.height - 6) / 2, yRadius: (bounds.height - 6) / 2)
            focus.lineWidth = 2; focus.stroke()
        }
    }
}
final class BadgeView: FlippedView {
    var text = "等待查询"
    var kind = "muted"
    override func draw(_ dirtyRect: NSRect) {
        let color = kind == "success" ? Ink.green : (kind == "warning" ? NSColor(hex: 0xbc6808) : Ink.muted)
        let fill = kind == "success" ? Ink.selected : NSColor(hex: kind == "warning" ? 0xfff2de : 0xeef2f4)
        fill.setFill(); NSBezierPath(roundedRect: bounds, xRadius: 15, yRadius: 15).fill()
        color.setFill(); NSBezierPath(ovalIn: NSRect(x: 14, y: 11, width: 9, height: 9)).fill()
        drawText(text, in: NSRect(x: 30, y: 0, width: bounds.width - 34, height: bounds.height), size: 14, color: color)
        setAccessibilityLabel(text)
    }
}
