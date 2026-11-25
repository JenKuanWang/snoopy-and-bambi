import AppKit
import SpriteKit

// The lower-left corner: a wooden platform with the litter box, hay box and
// water bowl on it, plus the buttons. Also the poop and pee art.

enum PropArt {
    static let scale: CGFloat = 3

    static func render(_ size: CGSize, _ draw: (CGContext) -> Void) -> SKTexture {
        let w = Int(size.width * scale), h = Int(size.height * scale)
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return SKTexture() }
        ctx.scaleBy(x: scale, y: scale)
        ctx.setLineJoin(.round)
        ctx.setLineCap(.round)
        draw(ctx)
        guard let img = ctx.makeImage() else { return SKTexture() }
        return SKTexture(cgImage: img)
    }

    // A fixed random sequence so props look the same every launch.
    struct Seeded {
        var state: UInt64
        mutating func next() -> CGFloat {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return CGFloat((state >> 33) % 10_000) / 10_000
        }
        mutating func range(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b - a) * next() }
    }

    // Everything below is drawn as seen from the front and a little above,
    // to match the side-on bunnies. Local origin = front-bottom-left corner.

    private static func rounded(_ r: CGRect, _ radius: CGFloat) -> CGPath {
        CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil)
    }

    private static func vGradient(_ ctx: CGContext, _ path: CGPath, top: NSColor, bottom: NSColor, from y0: CGFloat, to y1: CGFloat) {
        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                           colors: [top.cgColor, bottom.cgColor] as CFArray, locations: [0, 1])!
        ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: y1), end: CGPoint(x: 0, y: y0), options: [])
        ctx.restoreGState()
    }

    /// The wooden platform: a front edge and the top surface going back.
    static let platformSize = CGSize(width: 472, height: 74)
    static let platformFaceTop: CGFloat = 24      // local y where the top surface begins
    static let platformBackY: CGFloat = 70        // local y of the back edge

    static func platform() -> SKTexture {
        let s = platformSize
        return render(s) { ctx in
            let W = s.width
            // Soft shadow on the floor.
            ctx.setFillColor(NSColor(white: 0, alpha: 0.13).cgColor)
            ctx.fillEllipse(in: CGRect(x: 8, y: 0, width: W - 16, height: 10))
            // Top surface (planks running left to right, closer together towards the back).
            let top = CGMutablePath()
            top.move(to: CGPoint(x: 4, y: platformFaceTop))
            top.addLine(to: CGPoint(x: W - 4, y: platformFaceTop))
            top.addLine(to: CGPoint(x: W - 14, y: platformBackY))
            top.addLine(to: CGPoint(x: 14, y: platformBackY))
            top.closeSubpath()
            vGradient(ctx, top, top: NSColor(hex: 0xD2B184), bottom: NSColor(hex: 0xE6CDA4), from: platformFaceTop, to: platformBackY)
            ctx.saveGState()
            ctx.addPath(top)
            ctx.clip()
            var rng = Seeded(state: 3)
            var y = platformFaceTop
            var gap: CGFloat = 11
            var row = 0
            while y < platformBackY {
                let t = (y - platformFaceTop) / (platformBackY - platformFaceTop)
                let x0 = 4 + 10 * t, x1 = W - 4 - 10 * t
                ctx.setStrokeColor(NSColor(hex: 0xB08C5E, alpha: 0.75).cgColor)
                ctx.setLineWidth(0.9)
                ctx.move(to: CGPoint(x: x0, y: y)); ctx.addLine(to: CGPoint(x: x1, y: y)); ctx.strokePath()
                // Board ends, staggered per row.
                var x = x0 + (row % 2 == 0 ? 40 : 95) + rng.range(-10, 10)
                while x < x1 - 10 {
                    ctx.move(to: CGPoint(x: x, y: y)); ctx.addLine(to: CGPoint(x: x + 0.8, y: min(y + gap, platformBackY)))
                    ctx.strokePath()
                    x += 120 + rng.range(-20, 20)
                }
                // A little wood grain.
                ctx.setStrokeColor(NSColor(hex: 0xC4A072, alpha: 0.5).cgColor)
                ctx.setLineWidth(0.5)
                for _ in 0..<6 {
                    let gx = rng.range(x0 + 10, x1 - 40), gy = y + rng.range(2, max(2.5, gap - 2))
                    ctx.move(to: CGPoint(x: gx, y: gy)); ctx.addLine(to: CGPoint(x: gx + rng.range(15, 40), y: gy + rng.range(-0.4, 0.4)))
                    ctx.strokePath()
                }
                y += gap
                gap *= 0.84
                row += 1
            }
            ctx.restoreGState()
            ctx.addPath(top)
            ctx.setStrokeColor(NSColor(hex: 0x8A6A45).cgColor)
            ctx.setLineWidth(1.3)
            ctx.strokePath()
            // Front edge (the board you see from the side).
            let face = rounded(CGRect(x: 4, y: 5, width: W - 8, height: platformFaceTop - 5), 3)
            vGradient(ctx, face, top: NSColor(hex: 0xB8905F), bottom: NSColor(hex: 0x94704A), from: 5, to: platformFaceTop)
            ctx.setStrokeColor(NSColor(hex: 0x86663F, alpha: 0.55).cgColor)
            ctx.setLineWidth(0.6)
            for gy in [10.0, 15.5] as [CGFloat] {
                ctx.move(to: CGPoint(x: 10, y: gy)); ctx.addLine(to: CGPoint(x: W - 10, y: gy)); ctx.strokePath()
            }
            ctx.setStrokeColor(NSColor(hex: 0xEED9B6).cgColor)      // light catching the front edge
            ctx.setLineWidth(1.2)
            ctx.move(to: CGPoint(x: 6, y: platformFaceTop - 0.8)); ctx.addLine(to: CGPoint(x: W - 6, y: platformFaceTop - 0.8))
            ctx.strokePath()
            ctx.addPath(face)
            ctx.setStrokeColor(NSColor(hex: 0x6E5132).cgColor)
            ctx.setLineWidth(1.3)
            ctx.strokePath()
        }
    }

    /// The litter tub, in two layers so a bunny can sit *inside* it:
    /// the back (inside wall, litter, a bit of hay) and the front wall.
    static let litterSize = CGSize(width: 136, height: 64)
    static let litterWallHeight: CGFloat = 24
    /// Where the litter surface shows, in the tub's local coordinates (for poops).
    static let litterSurface = CGRect(x: 12, y: 26, width: 112, height: 9)

    static func litterBack() -> SKTexture {
        let s = litterSize
        return render(s) { ctx in
            // Inside back wall and its rim.
            let back = rounded(CGRect(x: 2, y: 18, width: s.width - 4, height: 26), 8)
            ctx.addPath(back)
            ctx.setFillColor(NSColor(hex: 0x6E9F93).cgColor)
            ctx.fillPath()
            ctx.addPath(rounded(CGRect(x: 2, y: 40, width: s.width - 4, height: 5), 2.5))
            ctx.setFillColor(NSColor(hex: 0x9CCBBE).cgColor)
            ctx.fillPath()
            // Hay tucked in the back corner (rabbits like to munch while they go).
            var rng = Seeded(state: 17)
            for i in 0..<34 {
                let x = rng.range(88, 128), y = rng.range(28, 38)
                let ang = rng.range(0.9, 2.3), len = rng.range(10, 20)
                ctx.setStrokeColor(NSColor(hex: [0xD8C468, 0xC9B455, 0xB7B85E, 0xE3D27F][i % 4]).cgColor)
                ctx.setLineWidth(rng.range(0.8, 1.3))
                ctx.move(to: CGPoint(x: x, y: y))
                ctx.addQuadCurve(to: CGPoint(x: x + cos(ang) * len, y: y + sin(ang) * len),
                                 control: CGPoint(x: x + cos(ang) * len * 0.5 + rng.range(-3, 3), y: y + sin(ang) * len * 0.5))
                ctx.strokePath()
            }
            // Litter surface.
            let litter = rounded(CGRect(x: 6, y: 22, width: s.width - 12, height: 16), 6)
            ctx.addPath(litter)
            ctx.setFillColor(NSColor(hex: 0xE9DFC9).cgColor)
            ctx.fillPath()
            for _ in 0..<110 {
                let x = rng.range(9, s.width - 9), y = rng.range(23, 37), r = rng.range(0.9, 1.6)
                ctx.setFillColor(NSColor(hex: rng.next() > 0.5 ? 0xD6C9AD : 0xF3EBDA).cgColor)
                ctx.fillEllipse(in: CGRect(x: x - r, y: y - r * 0.6, width: r * 2, height: r * 1.2))
            }
            ctx.addPath(rounded(CGRect(x: 2, y: 18, width: s.width - 4, height: 27), 8))
            ctx.setStrokeColor(NSColor(hex: 0x4E7A70).cgColor)
            ctx.setLineWidth(1.3)
            ctx.strokePath()
        }
    }

    static func litterFront() -> SKTexture {
        let s = litterSize
        return render(s) { ctx in
            let h = litterWallHeight
            let wall = CGMutablePath()
            wall.move(to: CGPoint(x: 6, y: 1))
            wall.addLine(to: CGPoint(x: s.width - 6, y: 1))
            wall.addQuadCurve(to: CGPoint(x: s.width - 1, y: h), control: CGPoint(x: s.width - 1, y: 1))
            wall.addLine(to: CGPoint(x: 1, y: h))
            wall.addQuadCurve(to: CGPoint(x: 6, y: 1), control: CGPoint(x: 1, y: 1))
            wall.closeSubpath()
            vGradient(ctx, wall, top: NSColor(hex: 0x93C5B8), bottom: NSColor(hex: 0x6E9F93), from: 1, to: h)
            // A soft highlight down the front.
            ctx.saveGState()
            ctx.addPath(wall)
            ctx.clip()
            ctx.setFillColor(NSColor.white.withAlphaComponent(0.16).cgColor)
            ctx.fill(CGRect(x: 18, y: 3, width: 20, height: h))
            ctx.restoreGState()
            ctx.addPath(wall)
            ctx.setStrokeColor(NSColor(hex: 0x4E7A70).cgColor)
            ctx.setLineWidth(1.3)
            ctx.strokePath()
            // Rolled lip along the top.
            let lip = rounded(CGRect(x: 0, y: h - 3, width: s.width, height: 6), 3)
            ctx.addPath(lip)
            ctx.setFillColor(NSColor(hex: 0xA9D5C9).cgColor)
            ctx.fillPath()
            ctx.addPath(lip)
            ctx.setStrokeColor(NSColor(hex: 0x4E7A70).cgColor)
            ctx.setLineWidth(1.1)
            ctx.strokePath()
        }
    }

    /// A slatted wooden hay box with hay heaped on top; `level` 0…1.
    static let haySize = CGSize(width: 86, height: 70)
    static let hayBoxHeight: CGFloat = 22

    static func hay(level: CGFloat) -> SKTexture {
        let s = haySize
        return render(s) { ctx in
            let boxH = hayBoxHeight
            var rng = Seeded(state: 42)
            let colors: [UInt32] = [0xD8C468, 0xC9B455, 0xE6D58A, 0xB7B85E, 0xA8A94F, 0xCDB86A]
            func strand(_ x: CGFloat, _ y: CGFloat, _ ang: CGFloat, _ len: CGFloat) {
                ctx.setStrokeColor(NSColor(hex: colors[Int(rng.next() * 6) % 6]).cgColor)
                ctx.setLineWidth(rng.range(0.8, 1.4))
                let bend = rng.range(-3, 3)
                ctx.move(to: CGPoint(x: x, y: y))
                ctx.addQuadCurve(to: CGPoint(x: x + cos(ang) * len, y: y + sin(ang) * len),
                                 control: CGPoint(x: x + cos(ang) * len / 2 - sin(ang) * bend, y: y + sin(ang) * len / 2 + cos(ang) * bend))
                ctx.strokePath()
            }
            // Heap of hay above the box.
            let moundH = 3 + 40 * level
            if level > 0.02 {
                for _ in 0..<(20 + Int(200 * level)) {
                    let u = rng.range(-1, 1)
                    let maxY = moundH * sqrt(max(0, 1 - u * u))
                    let x = s.width / 2 + u * (s.width / 2 - 6)
                    let y = boxH - 4 + rng.range(0, max(1, maxY))
                    let ang = rng.range(-0.8, 0.8) + (rng.next() > 0.5 ? 0 : .pi)
                    strand(x - cos(ang) * 6, y, ang, rng.range(8, 16))
                }
                // A few strands poking up and drooping over the front.
                for _ in 0..<Int(10 * level + 2) {
                    strand(rng.range(10, s.width - 10), boxH - 2 + moundH * 0.6, rng.range(1.2, 1.9), rng.range(6, 14))
                }
            }
            // The box: dark inside, slats in front with hay showing through.
            let box = rounded(CGRect(x: 2, y: 1, width: s.width - 4, height: boxH), 3)
            ctx.addPath(box)
            ctx.setFillColor((level > 0.02 ? NSColor(hex: 0xC9B455) : NSColor(hex: 0x6E5132)).cgColor)
            ctx.fillPath()
            if level > 0.02 {
                ctx.saveGState(); ctx.addPath(box); ctx.clip()
                for _ in 0..<40 { strand(rng.range(2, s.width - 2), rng.range(2, boxH), rng.range(-0.6, 0.6), rng.range(6, 12)) }
                ctx.restoreGState()
            }
            let slatW: CGFloat = 14
            var x: CGFloat = 2
            while x < s.width - 4 {
                let slat = rounded(CGRect(x: x, y: 1, width: min(slatW, s.width - 2 - x), height: boxH), 2)
                vGradient(ctx, slat, top: NSColor(hex: 0xD0A878), bottom: NSColor(hex: 0xB08657), from: 1, to: boxH)
                ctx.addPath(slat)
                ctx.setStrokeColor(NSColor(hex: 0x7A5A3A).cgColor)
                ctx.setLineWidth(0.9)
                ctx.strokePath()
                x += slatW + 3.6
            }
            // Top rail.
            let rail = rounded(CGRect(x: 0, y: boxH - 3, width: s.width, height: 5), 2)
            vGradient(ctx, rail, top: NSColor(hex: 0xDDB989), bottom: NSColor(hex: 0xB8905F), from: boxH - 3, to: boxH + 2)
            ctx.addPath(rail)
            ctx.setStrokeColor(NSColor(hex: 0x6E5132).cgColor)
            ctx.setLineWidth(1.1)
            ctx.strokePath()
        }
    }

    /// A small Persian-style rug under the water bowl (for traction), lying
    /// flat on the platform. Drawn in rug coordinates (u across, v going back)
    /// and mapped onto a trapezoid so it shares the platform's perspective.
    static let rugSize = CGSize(width: 144, height: 44)

    static func rug() -> SKTexture {
        let s = rugSize
        return render(s) { ctx in
            // Corners of the rug on the canvas: front edge, then the (slightly narrower) back edge.
            let fy: CGFloat = 4, by: CGFloat = 40
            let f0: CGFloat = 8, f1 = s.width - 8, b0: CGFloat = 14, b1 = s.width - 14
            func map(_ u: CGFloat, _ v: CGFloat) -> CGPoint {
                let vv = pow(v, 1.12)                       // rows get a little closer towards the back
                let x0 = f0 + (b0 - f0) * vv, x1 = f1 + (b1 - f1) * vv
                return CGPoint(x: x0 + (x1 - x0) * u, y: fy + (by - fy) * vv)
            }
            func quad(_ u0: CGFloat, _ v0: CGFloat, _ u1: CGFloat, _ v1: CGFloat) -> CGPath {
                let p = CGMutablePath()
                p.move(to: map(u0, v0)); p.addLine(to: map(u1, v0)); p.addLine(to: map(u1, v1)); p.addLine(to: map(u0, v1))
                p.closeSubpath()
                return p
            }
            func diamond(_ cu: CGFloat, _ cv: CGFloat, _ ru: CGFloat, _ rv: CGFloat) -> CGPath {
                let p = CGMutablePath()
                p.move(to: map(cu - ru, cv)); p.addLine(to: map(cu, cv - rv)); p.addLine(to: map(cu + ru, cv)); p.addLine(to: map(cu, cv + rv))
                p.closeSubpath()
                return p
            }
            func fill(_ p: CGPath, _ hex: UInt32, _ a: CGFloat = 1) {
                ctx.addPath(p); ctx.setFillColor(NSColor(hex: hex, alpha: a).cgColor); ctx.fillPath()
            }
            let navy: UInt32 = 0x3E5A6E, rose: UInt32 = 0xC88A7E, field: UInt32 = 0xE7D2C2
            let slate: UInt32 = 0x6F8CA2, cream: UInt32 = 0xF3E9DB, gold: UInt32 = 0xC9A86A

            // Soft shadow so it sits on the boards.
            ctx.setFillColor(NSColor(white: 0, alpha: 0.10).cgColor)
            ctx.addPath(quad(-0.01, -0.06, 1.01, 0.96)); ctx.fillPath()

            // Fringe on the short ends.
            ctx.setStrokeColor(NSColor(hex: cream).cgColor)
            ctx.setLineWidth(0.8)
            for i in 0...13 {
                let v = CGFloat(i) / 13
                for (u, du) in [(0.0, -0.045), (1.0, 0.045)] as [(CGFloat, CGFloat)] {
                    ctx.move(to: map(u, v)); ctx.addLine(to: map(u + du, v))
                }
            }
            ctx.strokePath()

            // Outer border, inner rose band, field.
            fill(quad(0, 0, 1, 1), navy)
            fill(quad(0.035, 0.11, 0.965, 0.89), rose)
            fill(quad(0.06, 0.2, 0.94, 0.8), field)
            // Little repeating motif in the navy border.
            for i in 0..<16 {
                let u = 0.03 + CGFloat(i) * 0.0627
                fill(diamond(u, 0.055, 0.012, 0.035), gold, 0.9)
                fill(diamond(u, 0.945, 0.012, 0.035), gold, 0.9)
            }
            // Central medallion with a cream heart, and corner spandrels.
            fill(diamond(0.5, 0.5, 0.2, 0.3), slate)
            fill(diamond(0.5, 0.5, 0.13, 0.2), cream)
            fill(diamond(0.5, 0.5, 0.06, 0.1), rose)
            for (cu, cv) in [(0.06, 0.2), (0.94, 0.2), (0.06, 0.8), (0.94, 0.8)] as [(CGFloat, CGFloat)] {
                fill(diamond(cu, cv, 0.08, 0.16), slate, 0.85)
            }
            for cu in [0.2, 0.8] as [CGFloat] {
                fill(diamond(cu, 0.5, 0.035, 0.12), rose, 0.9)
            }
            // A gently worn, woven look.
            var rng = Seeded(state: 77)
            ctx.saveGState(); ctx.addPath(quad(0, 0, 1, 1)); ctx.clip()
            for _ in 0..<220 {
                let p = map(rng.next(), rng.next())
                ctx.setFillColor(NSColor(white: 1, alpha: rng.range(0.04, 0.14)).cgColor)
                ctx.fill(CGRect(x: p.x, y: p.y, width: rng.range(0.8, 2.2), height: 0.6))
            }
            ctx.restoreGState()
            ctx.addPath(quad(0, 0, 1, 1))
            ctx.setStrokeColor(NSColor(hex: 0x2E4455).cgColor)
            ctx.setLineWidth(0.9)
            ctx.strokePath()
        }
    }

    /// A ceramic water bowl seen from the side, water showing at the top.
    static let bowlSize = CGSize(width: 56, height: 26)

    static func bowl(level: CGFloat, stale: Bool) -> SKTexture {
        let s = bowlSize
        return render(s) { ctx in
            let rimY: CGFloat = 17
            let body = CGMutablePath()
            body.move(to: CGPoint(x: 2, y: rimY))
            body.addLine(to: CGPoint(x: s.width - 2, y: rimY))
            body.addQuadCurve(to: CGPoint(x: s.width - 12, y: 1), control: CGPoint(x: s.width - 4, y: 3))
            body.addLine(to: CGPoint(x: 12, y: 1))
            body.addQuadCurve(to: CGPoint(x: 2, y: rimY), control: CGPoint(x: 4, y: 3))
            body.closeSubpath()
            vGradient(ctx, body, top: NSColor(hex: 0x8DB3E0), bottom: NSColor(hex: 0x5E86BA), from: 1, to: rimY)
            ctx.saveGState(); ctx.addPath(body); ctx.clip()
            ctx.setFillColor(NSColor.white.withAlphaComponent(0.22).cgColor)
            ctx.fill(CGRect(x: 10, y: 2, width: 7, height: rimY))
            ctx.restoreGState()
            ctx.addPath(body)
            ctx.setStrokeColor(NSColor(hex: 0x41618F).cgColor)
            ctx.setLineWidth(1.2)
            ctx.strokePath()
            // Rim and the inside, seen from a little above.
            let rim = CGRect(x: 1, y: rimY - 5, width: s.width - 2, height: 11)
            ctx.setFillColor(NSColor(hex: 0xE9EEF5).cgColor)
            ctx.fillEllipse(in: rim)
            let inside = rim.insetBy(dx: 3.5, dy: 2.2)
            ctx.setFillColor(NSColor(hex: 0xBAC7D8).cgColor)
            ctx.fillEllipse(in: inside)
            if level > 0.02 {
                let k = 0.45 + 0.55 * level
                let water = CGRect(x: inside.midX - inside.width * k / 2, y: inside.midY - inside.height * k / 2 - (1 - level) * 1.2,
                                   width: inside.width * k, height: inside.height * k)
                ctx.setFillColor((stale ? NSColor(hex: 0xA9C2A4) : NSColor(hex: 0x86C8F0)).cgColor)
                ctx.fillEllipse(in: water)
                if !stale {
                    ctx.setFillColor(NSColor.white.withAlphaComponent(0.8).cgColor)
                    ctx.fillEllipse(in: CGRect(x: water.minX + water.width * 0.2, y: water.midY + 0.4, width: water.width * 0.22, height: 1.6))
                }
            }
            ctx.setStrokeColor(NSColor(hex: 0x41618F).cgColor)
            ctx.setLineWidth(1.1)
            ctx.strokeEllipse(in: rim)
        }
    }

    static func poop() -> SKTexture {
        render(CGSize(width: 9, height: 9)) { ctx in
            ctx.setFillColor(NSColor(white: 0, alpha: 0.18).cgColor)
            ctx.fillEllipse(in: CGRect(x: 1.5, y: 0.8, width: 6.5, height: 3))
            ctx.setFillColor(NSColor(hex: 0x4B3324).cgColor)
            ctx.fillEllipse(in: CGRect(x: 1.5, y: 1.5, width: 6, height: 6))
            ctx.setFillColor(NSColor(hex: 0x6E4C36).cgColor)
            ctx.fillEllipse(in: CGRect(x: 3, y: 4.2, width: 2.2, height: 1.8))
        }
    }

    static func pee() -> SKTexture {
        render(CGSize(width: 26, height: 14)) { ctx in
            ctx.setFillColor(NSColor(hex: 0xF0DC6E, alpha: 0.38).cgColor)
            ctx.fillEllipse(in: CGRect(x: 1, y: 1, width: 24, height: 12))
            ctx.setFillColor(NSColor(hex: 0xF0DC6E, alpha: 0.25).cgColor)
            ctx.fillEllipse(in: CGRect(x: 15, y: 6, width: 9, height: 6))
        }
    }
}

/// A round button with an emoji, a hover label and an attention badge.
@MainActor
final class PenButton: SKNode {
    let id: String
    let radius: CGFloat = 15
    private let disc: SKShapeNode
    private let tip: SKNode
    private let badge: SKNode

    init(id: String, emoji: String, tipText: String) {
        self.id = id
        disc = SKShapeNode(circleOfRadius: radius)
        disc.fillColor = NSColor(white: 1, alpha: 0.9)
        disc.strokeColor = NSColor(white: 0, alpha: 0.18)
        disc.lineWidth = 1
        let label = SKLabelNode(text: emoji)
        label.fontSize = 16
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: -0.5)
        disc.addChild(label)

        tip = Bubble.pill(tipText, fontSize: 11)
        tip.position = CGPoint(x: 0, y: radius + 14)
        tip.alpha = 0

        let b = SKShapeNode(circleOfRadius: 6)
        b.fillColor = NSColor(hex: 0xE5484D)
        b.strokeColor = .white
        b.lineWidth = 1.2
        let bang = SKLabelNode(text: "!")
        bang.fontName = "HelveticaNeue-Bold"
        bang.fontSize = 10
        bang.fontColor = .white
        bang.verticalAlignmentMode = .center
        b.addChild(bang)
        b.position = CGPoint(x: radius * 0.72, y: radius * 0.72)
        badge = b
        badge.isHidden = true
        super.init()
        addChild(disc)
        addChild(tip)
        addChild(badge)
        alpha = 0.8
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    func contains(scenePoint p: CGPoint) -> Bool { p.distance(to: position) <= radius + 3 }

    func setHover(_ on: Bool) {
        tip.removeAllActions()
        tip.run(.fadeAlpha(to: on ? 1 : 0, duration: 0.12))
        run(.group([.scale(to: on ? 1.12 : 1, duration: 0.1), .fadeAlpha(to: on ? 1 : 0.8, duration: 0.1)]))
    }

    func setBadge(_ on: Bool) {
        guard badge.isHidden == on else { return }
        badge.isHidden = !on
        badge.removeAllActions()
        if on {
            badge.run(.repeatForever(.sequence([.scale(to: 1.25, duration: 0.5), .scale(to: 1, duration: 0.5)])))
        }
    }

    func pressed() {
        run(.sequence([.scale(to: 0.85, duration: 0.06), .scale(to: 1.12, duration: 0.1)]))
    }
}

/// Little speech-bubble / pill labels.
enum Bubble {
    @MainActor
    static func pill(_ text: String, fontSize: CGFloat = 11, color: NSColor = NSColor(white: 1, alpha: 0.92),
                     textColor: NSColor = NSColor(hex: 0x3A332E)) -> SKNode {
        let label = SKLabelNode(text: text)
        label.fontName = "HelveticaNeue-Medium"
        label.fontSize = fontSize
        label.fontColor = textColor
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        let w = label.frame.width + 14, h = fontSize + 9
        let bg = SKShapeNode(rect: CGRect(x: -w / 2, y: -h / 2, width: w, height: h), cornerRadius: h / 2)
        bg.fillColor = color
        bg.strokeColor = NSColor(white: 0, alpha: 0.15)
        bg.lineWidth = 0.8
        bg.addChild(label)
        return bg
    }
}

/// The platform in the lower-right corner and everything on it.
@MainActor
final class CornerNode: SKNode {
    let platform = SKSpriteNode(texture: PropArt.platform())
    let rug = SKSpriteNode(texture: PropArt.rug())
    let litterBack = SKSpriteNode(texture: PropArt.litterBack())
    let litterFront = SKSpriteNode(texture: PropArt.litterFront())
    let hayPile = SKSpriteNode(texture: PropArt.hay(level: 1))
    let bowl = SKSpriteNode(texture: PropArt.bowl(level: 1, stale: false))
    let hayButton = PenButton(id: "hay", emoji: "🌾", tipText: "Add hay")
    let waterButton = PenButton(id: "water", emoji: "💧", tipText: "Fresh water")
    let cleanButton = PenButton(id: "clean", emoji: "🧹", tipText: "Clean up")
    let menuButton = PenButton(id: "menu", emoji: "🐰", tipText: "Menu")
    var buttons: [PenButton] { [hayButton, waterButton, cleanButton, menuButton] }

    // Layout, designed as measured from the corner's edge of the screen (the
    // corner node sits at the scene origin), then mirrored into the lower-RIGHT
    // corner by `layout(width:)`. The platform sits flush in the corner: its
    // front edge on the bottom of the bunny area, its far end running off the
    // right edge of the screen.
    static let platformOrigin = CGPoint(x: -34, y: -5)
    static let litterOrigin = CGPoint(x: 20, y: 25)
    static let hayOrigin = CGPoint(x: 176, y: 31)
    static let bowlOrigin = CGPoint(x: 318, y: 31)
    static let rugOrigin = CGPoint(x: 274, y: 19)

    private let litterPoopLayer = SKNode()
    private var hayTextures: [SKTexture] = (0...5).map { PropArt.hay(level: CGFloat($0) / 5) }
    private var shownHayStep = -1
    private var shownBowl = ""
    private var shownLitter = -1
    private var hayAlert = SKNode()
    private var waterAlert = SKNode()
    private var width: CGFloat = 1200
    private static let row: CGFloat = 113

    /// Mirrors a design-space x (distance from the corner's screen edge) to the right side.
    private func mx(_ x: CGFloat) -> CGFloat { width - x }
    private func mirrored(_ p: CGPoint) -> CGPoint { CGPoint(x: width - p.x, y: p.y) }

    override init() {
        super.init()
        let items: [(SKSpriteNode, CGPoint, CGSize)] = [
            (platform, Self.platformOrigin, PropArt.platformSize),
            (rug, Self.rugOrigin, PropArt.rugSize),
            (litterBack, Self.litterOrigin, PropArt.litterSize),
            (litterFront, Self.litterOrigin, PropArt.litterSize),
            (hayPile, Self.hayOrigin, PropArt.haySize),
            (bowl, Self.bowlOrigin, PropArt.bowlSize),
        ]
        for (sprite, _, size) in items {
            sprite.anchorPoint = .zero
            sprite.size = size            // textures are 3×; show them at point size
            addChild(sprite)
        }
        platform.zPosition = 2
        rug.zPosition = 3                 // on the boards, under everything else
        litterBack.zPosition = 6
        litterPoopLayer.zPosition = 1
        litterBack.addChild(litterPoopLayer)

        for b in buttons {
            b.zPosition = 400
            addChild(b)
        }
        hayAlert = alertBubble("🌾")
        waterAlert = alertBubble("💧")
        for a in [hayAlert, waterAlert] {
            a.zPosition = 390
            a.isHidden = true
            addChild(a)
        }
        layout(width: width)
    }

    /// Places everything in the lower-right corner of a scene this wide.
    func layout(width: CGFloat) {
        self.width = width
        func place(_ n: SKNode, _ origin: CGPoint, _ size: CGSize) {
            n.position = CGPoint(x: mx(origin.x) - size.width, y: origin.y)
        }
        place(platform, Self.platformOrigin, PropArt.platformSize)
        place(rug, Self.rugOrigin, PropArt.rugSize)
        place(litterBack, Self.litterOrigin, PropArt.litterSize)
        place(litterFront, Self.litterOrigin, PropArt.litterSize)
        place(hayPile, Self.hayOrigin, PropArt.haySize)
        place(bowl, Self.bowlOrigin, PropArt.bowlSize)
        // Buttons stay in reading order (hay, water, clean, menu), ending near the right edge.
        for (i, b) in buttons.enumerated() {
            b.position = CGPoint(x: width - 36 - CGFloat(buttons.count - 1 - i) * 38, y: Self.row)
        }
        hayAlert.position = CGPoint(x: hayPile.position.x + PropArt.haySize.width / 2 - 20, y: Self.row)
        waterAlert.position = CGPoint(x: bowl.position.x + PropArt.bowlSize.width / 2, y: Self.row)
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    /// Things that stand on the platform and need depth-sorting with the
    /// bunnies, with the y of their front-bottom edge.
    var depthSorted: [(SKNode, CGFloat)] {
        [(litterFront, Self.litterOrigin.y), (hayPile, Self.hayOrigin.y), (bowl, Self.bowlOrigin.y)]
    }

    private func alertBubble(_ emoji: String) -> SKNode {
        let n = Bubble.pill("\(emoji) !", fontSize: 12, color: NSColor(hex: 0xFFF4D6))
        n.run(.repeatForever(.sequence([.moveBy(x: 0, y: 3, duration: 0.6), .moveBy(x: 0, y: -3, duration: 0.6)])))
        return n
    }

    // Where bunnies stand (feet position) and which way they face.
    // A spot just *behind* an item (larger y) lets the item hide the feet/chin.
    // (Designed for the left corner, then mirrored: facing flips too.)
    var hayEatSpots: [(CGPoint, Bool)] {
        let h = Self.hayOrigin
        return [(mirrored(CGPoint(x: h.x + PropArt.haySize.width / 2 + 22, y: h.y + 20)), true),   // behind the hay box
                (mirrored(CGPoint(x: h.x + PropArt.haySize.width + 24, y: h.y + 7)), true)]        // beside it
    }

    var drinkSpots: [(CGPoint, Bool)] {
        let b = Self.bowlOrigin
        return [(mirrored(CGPoint(x: b.x + PropArt.bowlSize.width / 2 + 25, y: b.y + 18)), true),  // behind the bowl
                (mirrored(CGPoint(x: b.x + PropArt.bowlSize.width / 2 - 25, y: b.y + 8)), false)]  // beside it
    }

    var litterSpots: [CGPoint] {
        let l = Self.litterOrigin
        return [mirrored(CGPoint(x: l.x + 46, y: l.y + 11)), mirrored(CGPoint(x: l.x + 96, y: l.y + 13))]
    }

    /// Poops landing in here count as "in the litter box".
    var litterArea: CGRect {
        CGRect(x: mx(Self.litterOrigin.x) - PropArt.litterSize.width, y: Self.litterOrigin.y,
               width: PropArt.litterSize.width, height: 44)
    }

    /// The area bunnies shouldn't pick as a random wander target.
    var footprint: CGRect {
        let w = Self.platformOrigin.x + PropArt.platformSize.width + 10
        return CGRect(x: width - w, y: 0, width: w, height: 140)
    }

    func sync(with model: PenModel, now: Date) {
        let step = Int((model.hay * 5).rounded(.up))
        if step != shownHayStep {
            shownHayStep = step
            hayPile.texture = hayTextures[max(0, min(5, step))]
        }
        let waterStep = Int((model.water * 5).rounded(.up))
        let stale = model.waterStale(at: now)
        let key = "\(waterStep)-\(stale)"
        if key != shownBowl {
            shownBowl = key
            bowl.texture = PropArt.bowl(level: CGFloat(waterStep) / 5, stale: stale)
        }
        if model.litterPoops != shownLitter {
            shownLitter = model.litterPoops
            drawLitterPoops(model.litterPoops)
        }
        hayAlert.isHidden = !model.hayLow
        waterAlert.isHidden = !model.needsWaterAttention(at: now)
        hayButton.setBadge(model.hayLow)
        waterButton.setBadge(model.needsWaterAttention(at: now))
        cleanButton.setBadge(model.litterNeedsCleaning || model.floorPoops.count >= 15)
    }

    private func drawLitterPoops(_ count: Int) {
        litterPoopLayer.removeAllChildren()
        var rng = PropArt.Seeded(state: 99)
        let tex = PropArt.poop()
        let area = PropArt.litterSurface
        for _ in 0..<min(count, 50) {
            let p = SKSpriteNode(texture: tex)
            p.size = CGSize(width: 6.5, height: 6.5)
            p.position = CGPoint(x: rng.range(area.minX, area.maxX), y: rng.range(area.minY, area.maxY))
            litterPoopLayer.addChild(p)
        }
    }

    func feedbackRefillHay() {
        let o = hayPile.position
        for i in 0..<14 {
            let strand = SKShapeNode(rectOf: CGSize(width: CGFloat.random(in: 8...14), height: 1.4), cornerRadius: 0.7)
            strand.fillColor = NSColor(hex: [0xD8C468, 0xC9B455, 0xB7B85E][i % 3])
            strand.strokeColor = .clear
            strand.zRotation = CGFloat.random(in: -1...1)
            strand.position = CGPoint(x: o.x + CGFloat.random(in: 12...74), y: 150 + CGFloat(i) * 4)
            strand.zPosition = 300
            addChild(strand)
            strand.run(.sequence([.wait(forDuration: Double(i) * 0.03),
                                  .group([.moveTo(y: o.y + PropArt.hayBoxHeight + CGFloat.random(in: 8...30), duration: 0.45),
                                          .rotate(byAngle: CGFloat.random(in: -2...2), duration: 0.45)]),
                                  .fadeOut(withDuration: 0.25), .removeFromParent()]))
        }
    }

    func feedbackFreshWater() {
        let c = CGPoint(x: bowl.position.x + PropArt.bowlSize.width / 2, y: bowl.position.y + 17)
        for i in 0..<3 {
            let ring = SKShapeNode(ellipseOf: CGSize(width: 10, height: 3.5))
            ring.strokeColor = NSColor.white.withAlphaComponent(0.9)
            ring.lineWidth = 1.1
            ring.position = c
            ring.zPosition = 300
            addChild(ring)
            ring.run(.sequence([.wait(forDuration: Double(i) * 0.18),
                                .group([.scale(to: 3.6, duration: 0.6), .fadeOut(withDuration: 0.6)]),
                                .removeFromParent()]))
        }
    }
}
