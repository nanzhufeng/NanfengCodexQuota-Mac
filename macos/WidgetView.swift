import AppKit
import ServiceManagement
import Darwin

final class WidgetView: FlippedView {
    unowned let app: AppDelegate
    private var image: NSImage?
    private var imageKey = -2
    var snapshot: Snapshot? { didSet { needsDisplay = true } }
    init(app: AppDelegate) { self.app = app; super.init(frame: NSRect(x: 0, y: 0, width: 132, height: 132)); setAccessibilityRole(.group) }
    required init?(coder: NSCoder) { fatalError() }
    override func draw(_ dirtyRect: NSRect) {
        let remaining = snapshot?.remaining ?? -1
        if imageKey != remaining {
            let side = 264
            var bytes = [UInt8](repeating: 0, count: side * side * 4)
            bytes.withUnsafeMutableBufferPointer { b in _ = quota_render(Int32(remaining), 2, b.baseAddress, b.count) }
            let data = Data(bytes) as CFData
            if let provider = CGDataProvider(data: data), let cg = CGImage(width: side, height: side, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: side * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue).union(.byteOrder32Little), provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) {
                image = NSImage(cgImage: cg, size: NSSize(width: 132, height: 132)); imageKey = remaining
            }
        }
        image?.draw(in: bounds, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        drawText(snapshot?.percentLabel ?? "--%", in: NSRect(x: 28, y: 27, width: 76, height: 37), size: 30, weight: .semibold, color: NSColor(hex: 0xffe7d3), align: .center)
        drawText(snapshot?.refreshLabel ?? "等待查询", in: NSRect(x: 23, y: 68, width: 86, height: 20), size: 11, color: NSColor(hex: 0xffe7d3), align: .center)
        toolTip = snapshot?.details
        setAccessibilityLabel("周剩余额度 \(snapshot?.percentLabel ?? "未知")，\(snapshot?.status ?? "等待查询")。拖动移动，右键打开菜单。")
    }
    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 { app.openSettings(); return }
        window?.performDrag(with: event); app.savePosition()
    }
    override func rightMouseDown(with event: NSEvent) { NSMenu.popUpContextMenu(app.makeMenu(), with: event, for: self) }
}
final class WidgetPanel: NSPanel { override var canBecomeKey: Bool { false } }
