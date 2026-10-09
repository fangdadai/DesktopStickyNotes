#!/usr/bin/env swift
import AppKit

// Run from the repository root. All artwork uses a 1024-point canvas.
let directory = URL(fileURLWithPath: "DesktopStickyNotes/Assets.xcassets/AppIcon.appiconset")
func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
            green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: alpha)
}

func paper(_ rect: NSRect, angle: CGFloat, tint: UInt32) {
    NSGraphicsContext.saveGraphicsState()
    let transform = NSAffineTransform()
    transform.translateX(by: rect.midX, yBy: rect.midY)
    transform.rotate(byDegrees: angle)
    transform.translateX(by: -rect.midX, yBy: -rect.midY)
    transform.concat()
    let shadow = NSShadow()
    shadow.shadowColor = color(0x3B2930, alpha: 0.16)
    shadow.shadowBlurRadius = 24
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.set()
    color(tint).setFill()
    NSBezierPath(roundedRect: rect, xRadius: 48, yRadius: 48).fill()
    NSGraphicsContext.restoreGraphicsState()
}

func drawIcon() {
    paper(NSRect(x: 132, y: 191, width: 670, height: 685), angle: -9, tint: 0xC7E3FF)
    paper(NSRect(x: 183, y: 154, width: 660, height: 714), angle: 8, tint: 0xFFCFD9)

    let note = NSBezierPath()
    note.move(to: NSPoint(x: 226, y: 158))
    note.line(to: NSPoint(x: 728, y: 158))
    note.line(to: NSPoint(x: 856, y: 286))
    note.line(to: NSPoint(x: 856, y: 820))
    note.curve(to: NSPoint(x: 806, y: 870), controlPoint1: NSPoint(x: 856, y: 848), controlPoint2: NSPoint(x: 834, y: 870))
    note.line(to: NSPoint(x: 226, y: 870))
    note.curve(to: NSPoint(x: 176, y: 820), controlPoint1: NSPoint(x: 198, y: 870), controlPoint2: NSPoint(x: 176, y: 848))
    note.line(to: NSPoint(x: 176, y: 208))
    note.curve(to: NSPoint(x: 226, y: 158), controlPoint1: NSPoint(x: 176, y: 180), controlPoint2: NSPoint(x: 198, y: 158))
    note.close()

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = color(0x5B4231, alpha: 0.23)
    shadow.shadowBlurRadius = 28
    shadow.shadowOffset = NSSize(width: 0, height: -16)
    shadow.set()
    color(0xFFE594).setFill()
    note.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGradient(starting: color(0xFFE18B), ending: color(0xFFF0A8))!.draw(in: note, angle: 90)

    NSGraphicsContext.saveGraphicsState()
    note.addClip()
    color(0xFFFFFF, alpha: 0.18).setFill()
    NSRect(x: 176, y: 752, width: 680, height: 118).fill()
    NSGraphicsContext.restoreGraphicsState()

    color(0x866631, alpha: 0.50).setFill()
    for (y, width) in [(650.0, 400.0), (550.0, 340.0), (450.0, 260.0)] {
        NSBezierPath(roundedRect: NSRect(x: 276, y: y, width: width, height: 30), xRadius: 15, yRadius: 15).fill()
    }

    let fold = NSBezierPath()
    fold.move(to: NSPoint(x: 728, y: 158))
    fold.line(to: NSPoint(x: 728, y: 254))
    fold.curve(to: NSPoint(x: 760, y: 286), controlPoint1: NSPoint(x: 728, y: 272), controlPoint2: NSPoint(x: 742, y: 286))
    fold.line(to: NSPoint(x: 856, y: 286))
    fold.close()
    NSGradient(starting: color(0xE3B95A), ending: color(0xFFF6C6))!.draw(in: fold, angle: 45)
}

for pixels in [16, 32, 64, 128, 256, 512, 1024] {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                  isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let transform = NSAffineTransform()
    transform.scale(by: CGFloat(pixels) / 1024)
    transform.concat()
    drawIcon()
    NSGraphicsContext.restoreGraphicsState()
    try bitmap.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent("icon-\(pixels).png"))
}
print("Generated AppIcon PNGs (16–1024 px).")
