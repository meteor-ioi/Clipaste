import AppKit
import CoreGraphics

guard CommandLine.arguments.count == 4 else {
    fputs("Usage: generate-dmg-background.swift <output.png> <app-icon.png> <app-name>\n", stderr)
    exit(2)
}

let outputPath = CommandLine.arguments[1]
let iconPath = CommandLine.arguments[2]
let appName = CommandLine.arguments[3]
let canvasSize = NSSize(width: 760, height: 480)

guard let icon = NSImage(contentsOfFile: iconPath) else {
    fputs("Failed to load app icon: \(iconPath)\n", stderr)
    exit(1)
}

func drawText(
    _ text: String,
    in rect: NSRect,
    font: NSFont,
    color: NSColor,
    alignment: NSTextAlignment = .center
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment

    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]
    text.draw(in: rect, withAttributes: attributes)
}

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(canvasSize.width),
    pixelsHigh: Int(canvasSize.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("Failed to create DMG background bitmap.\n", stderr)
    exit(1)
}

bitmap.size = canvasSize

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

let bounds = NSRect(origin: .zero, size: canvasSize)
NSGradient(colors: [
    NSColor(calibratedRed: 0.91, green: 0.97, blue: 1.0, alpha: 1.0),
    NSColor(calibratedRed: 0.68, green: 0.88, blue: 1.0, alpha: 1.0),
    NSColor(calibratedRed: 0.98, green: 0.99, blue: 1.0, alpha: 1.0)
])?.draw(in: bounds, angle: -28)

NSGraphicsContext.current?.cgContext.saveGState()
NSColor(calibratedWhite: 1.0, alpha: 0.32).setFill()
NSBezierPath(ovalIn: NSRect(x: -120, y: 260, width: 360, height: 300)).fill()
NSColor(calibratedRed: 0.15, green: 0.58, blue: 1.0, alpha: 0.14).setFill()
NSBezierPath(ovalIn: NSRect(x: 470, y: -80, width: 360, height: 320)).fill()
NSGraphicsContext.current?.cgContext.restoreGState()

let panelRect = NSRect(x: 84, y: 108, width: 592, height: 264)
let panelPath = NSBezierPath(roundedRect: panelRect, xRadius: 34, yRadius: 34)
NSColor(calibratedWhite: 1.0, alpha: 0.50).setFill()
panelPath.fill()
NSColor(calibratedWhite: 1.0, alpha: 0.70).setStroke()
panelPath.lineWidth = 1.2
panelPath.stroke()

let shadow = NSShadow()
shadow.shadowColor = NSColor(calibratedRed: 0.12, green: 0.45, blue: 0.85, alpha: 0.14)
shadow.shadowBlurRadius = 20
shadow.shadowOffset = NSSize(width: 0, height: -8)
shadow.set()

NSShadow().set()

drawText(
    appName,
    in: NSRect(x: 0, y: 330, width: canvasSize.width, height: 34),
    font: .systemFont(ofSize: 30, weight: .bold),
    color: NSColor(calibratedRed: 0.10, green: 0.18, blue: 0.28, alpha: 0.90)
)

drawText(
    "Drag to Applications",
    in: NSRect(x: 0, y: 304, width: canvasSize.width, height: 22),
    font: .systemFont(ofSize: 15, weight: .medium),
    color: NSColor(calibratedRed: 0.28, green: 0.42, blue: 0.56, alpha: 0.72)
)

let arrowRect = NSRect(x: 325, y: 208, width: 110, height: 42)
let arrowPath = NSBezierPath(roundedRect: arrowRect, xRadius: 21, yRadius: 21)
NSColor(calibratedRed: 0.15, green: 0.55, blue: 1.0, alpha: 0.18).setFill()
arrowPath.fill()
NSColor(calibratedRed: 0.12, green: 0.48, blue: 1.0, alpha: 0.36).setStroke()
arrowPath.lineWidth = 1
arrowPath.stroke()

let context = NSGraphicsContext.current!.cgContext
context.saveGState()
context.setStrokeColor(NSColor(calibratedRed: 0.10, green: 0.45, blue: 1.0, alpha: 0.78).cgColor)
context.setFillColor(NSColor(calibratedRed: 0.10, green: 0.45, blue: 1.0, alpha: 0.78).cgColor)
context.setLineWidth(4)
context.setLineCap(.round)
context.move(to: CGPoint(x: 352, y: 229))
context.addLine(to: CGPoint(x: 398, y: 229))
context.strokePath()
context.move(to: CGPoint(x: 418, y: 229))
context.addLine(to: CGPoint(x: 398, y: 241))
context.addLine(to: CGPoint(x: 398, y: 217))
context.closePath()
context.fillPath()
context.restoreGState()

drawText(
    "Open. Drag. Done.",
    in: NSRect(x: 0, y: 72, width: canvasSize.width, height: 18),
    font: .systemFont(ofSize: 12, weight: .medium),
    color: NSColor(calibratedRed: 0.30, green: 0.44, blue: 0.58, alpha: 0.52)
)

NSGraphicsContext.restoreGraphicsState()

guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Failed to encode DMG background.\n", stderr)
    exit(1)
}

do {
    try pngData.write(to: URL(fileURLWithPath: outputPath), options: .atomic)
} catch {
    fputs("Failed to write DMG background: \(error)\n", stderr)
    exit(1)
}
