import AppKit
import SpriteKit

// The lower-right corner: a wooden platform with the litter box, hay box and
// water bowl on it, plus the buttons. Also the poop and pee art.

enum PropArt {
    static let scale: CGFloat = 4
    private static let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

    static func render(_ size: CGSize, _ draw: (CGContext) -> Void) -> SKTexture {
        let w = Int(size.width * scale), h = Int(size.height * scale)
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: sRGB,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return SKTexture() }
        ctx.interpolationQuality = .high
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        ctx.scaleBy(x: scale, y: scale)
        ctx.setLineJoin(.round)
        ctx.setLineCap(.round)
        draw(ctx)
        guard let img = ctx.makeImage() else { return SKTexture() }
        let tex = SKTexture(cgImage: img)
        tex.filteringMode = .linear
        return tex
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
        let g = CGGradient(colorsSpace: sRGB,
                           colors: [top.cgColor, bottom.cgColor] as CFArray, locations: [0, 1])!
        ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: y1), end: CGPoint(x: 0, y: y0), options: [])
        ctx.restoreGState()
    }

    private static func radial(_ c: CGPoint, _ r: CGFloat, _ color: NSColor, _ alpha: CGFloat, _ ctx: CGContext) {
        let g = CGGradient(colorsSpace: sRGB, colors: [color.withAlphaComponent(alpha).cgColor,
                                                       color.withAlphaComponent(alpha * 0.5).cgColor,
                                                       color.withAlphaComponent(0).cgColor] as CFArray,
                           locations: [0, 0.55, 1])!
        ctx.drawRadialGradient(g, startCenter: c, startRadius: 0, endCenter: c, endRadius: r, options: [])
    }

    /// The wooden platform: a front edge and the top surface going back.
    static let platformSize = CGSize(width: 472, height: 74)
    static let platformFaceTop: CGFloat = 24      // local y where the top surface begins
    static let platformBackY: CGFloat = 70        // local y of the back edge

    static func platform() -> SKTexture {
        let s = platformSize
        return render(s) { ctx in
            let W = s.width
            // Soft layered shadow on the floor.
            ctx.setFillColor(NSColor(hex: 0x2B1E12, alpha: 0.16).cgColor)
            ctx.fillEllipse(in: CGRect(x: 6, y: 0, width: W - 12, height: 11))
            ctx.setFillColor(NSColor(hex: 0x2B1E12, alpha: 0.12).cgColor)
            ctx.fillEllipse(in: CGRect(x: 12, y: 1.5, width: W - 24, height: 7))

            // Top surface (warm honey-oak planks running left to right, closer together towards the back).
            let top = CGMutablePath()
            top.move(to: CGPoint(x: 4, y: platformFaceTop))
            top.addLine(to: CGPoint(x: W - 4, y: platformFaceTop))
            top.addLine(to: CGPoint(x: W - 14, y: platformBackY))
            top.addLine(to: CGPoint(x: 14, y: platformBackY))
            top.closeSubpath()
            vGradient(ctx, top, top: NSColor(hex: 0xCEAA7B), bottom: NSColor(hex: 0xE9D0A8), from: platformFaceTop, to: platformBackY)

            ctx.saveGState()
            ctx.addPath(top)
            ctx.clip()
            var rng = Seeded(state: 3)
            var y = platformFaceTop
            var gap: CGFloat = 11.2
            var row = 0
            let plankTints: [UInt32] = [0xEAD2AA, 0xDFC194, 0xE6CB9F, 0xD8B888, 0xE2C598]
            while y < platformBackY {
                let t = (y - platformFaceTop) / (platformBackY - platformFaceTop)
                let x0 = 4 + 10 * t, x1 = W - 4 - 10 * t
                let nextY = min(y + gap, platformBackY)
                ctx.setFillColor(NSColor(hex: plankTints[row % plankTints.count], alpha: 0.34).cgColor)
                ctx.fill(CGRect(x: x0 - 4, y: y, width: x1 - x0 + 8, height: nextY - y))

                // Flowing organic wood grain.
                for _ in 0..<8 {
                    let gx = rng.range(x0 + 8, x1 - 44), gy = y + rng.range(1.8, max(2.2, gap - 1.8))
                    let glen = rng.range(18, 48)
                    let curve = rng.range(-1.1, 1.1)
                    ctx.setStrokeColor(NSColor(hex: rng.next() > 0.35 ? 0xB89160 : 0xF3E2C2, alpha: rng.range(0.28, 0.48)).cgColor)
                    ctx.setLineWidth(rng.range(0.45, 0.75))
                    ctx.move(to: CGPoint(x: gx, y: gy))
                    ctx.addQuadCurve(to: CGPoint(x: gx + glen, y: gy + rng.range(-0.5, 0.5)),
                                     control: CGPoint(x: gx + glen * 0.5, y: gy + curve))
                    ctx.strokePath()
                }

                // Plank seam with soft highlight.
                ctx.setStrokeColor(NSColor(hex: 0x9C784E, alpha: 0.65).cgColor)
                ctx.setLineWidth(0.85)
                ctx.move(to: CGPoint(x: x0, y: y)); ctx.addLine(to: CGPoint(x: x1, y: y)); ctx.strokePath()
                ctx.setStrokeColor(NSColor(hex: 0xF7E8CC, alpha: 0.38).cgColor)
                ctx.setLineWidth(0.55)
                ctx.move(to: CGPoint(x: x0, y: y + 0.8)); ctx.addLine(to: CGPoint(x: x1, y: y + 0.8)); ctx.strokePath()

                // Board ends, staggered per row.
                var x = x0 + (row % 2 == 0 ? 44 : 102) + rng.range(-10, 10)
                while x < x1 - 12 {
                    ctx.setStrokeColor(NSColor(hex: 0x9C784E, alpha: 0.58).cgColor)
                    ctx.setLineWidth(0.8)
                    ctx.move(to: CGPoint(x: x, y: y)); ctx.addLine(to: CGPoint(x: x + 0.9, y: nextY))
                    ctx.strokePath()
                    x += 122 + rng.range(-20, 20)
                }
                y += gap
                gap *= 0.84
                row += 1
            }
            let backShade = CGGradient(colorsSpace: sRGB,
                                       colors: [NSColor(hex: 0x6E4E2E, alpha: 0.16).cgColor,
                                                NSColor(hex: 0x6E4E2E, alpha: 0).cgColor] as CFArray,
                                       locations: [0, 1])!
            ctx.drawLinearGradient(backShade, start: CGPoint(x: 0, y: platformBackY), end: CGPoint(x: 0, y: platformBackY - 12), options: [])
            ctx.restoreGState()

            ctx.addPath(top)
            ctx.setStrokeColor(NSColor(hex: 0x7D5E3C).cgColor)
            ctx.setLineWidth(1.2)
            ctx.strokePath()

            // Front edge (the board you see from the side).
            let face = rounded(CGRect(x: 4, y: 5, width: W - 8, height: platformFaceTop - 5), 3.2)
            vGradient(ctx, face, top: NSColor(hex: 0xC19866), bottom: NSColor(hex: 0x8E6942), from: 5, to: platformFaceTop)
            ctx.saveGState(); ctx.addPath(face); ctx.clip()
            for i in 0..<4 {
                let gy = 8.2 + CGFloat(i) * 3.6
                ctx.setStrokeColor(NSColor(hex: i % 2 == 0 ? 0x7A5835 : 0xD7B282, alpha: 0.36).cgColor)
                ctx.setLineWidth(0.65)
                ctx.move(to: CGPoint(x: 8, y: gy))
                ctx.addQuadCurve(to: CGPoint(x: W - 8, y: gy + (i % 2 == 0 ? 0.5 : -0.4)),
                                 control: CGPoint(x: W * 0.5, y: gy + (i % 2 == 0 ? -0.9 : 0.8)))
                ctx.strokePath()
            }
            ctx.restoreGState()
            ctx.setStrokeColor(NSColor(hex: 0xF5E3C3, alpha: 0.9).cgColor)      // light catching the front edge
            ctx.setLineWidth(1.3)
            ctx.move(to: CGPoint(x: 6.5, y: platformFaceTop - 0.8)); ctx.addLine(to: CGPoint(x: W - 6.5, y: platformFaceTop - 0.8))
            ctx.strokePath()
            ctx.addPath(face)
            ctx.setStrokeColor(NSColor(hex: 0x64482B).cgColor)
            ctx.setLineWidth(1.25)
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
            // Inside back wall and its rolled rim.
            let back = rounded(CGRect(x: 2, y: 18, width: s.width - 4, height: 27), 8)
            vGradient(ctx, back, top: NSColor(hex: 0x7AAEA0), bottom: NSColor(hex: 0x5B8A7E), from: 18, to: 45)
            let backRim = rounded(CGRect(x: 2, y: 40, width: s.width - 4, height: 5.5), 2.8)
            vGradient(ctx, backRim, top: NSColor(hex: 0xB4DDD0), bottom: NSColor(hex: 0x89BCAD), from: 40, to: 45.5)

            // Hay tucked in the back corner (rabbits like to munch while they go).
            var rng = Seeded(state: 17)
            let hayCols: [UInt32] = [0x9F9C4C, 0xC4B45A, 0xD8C66D, 0xB6BE62, 0xE6D88C]
            for i in 0..<42 {
                let x = rng.range(86, 128), y = rng.range(27, 38)
                let ang = rng.range(0.85, 2.35), len = rng.range(10, 21)
                let bend = rng.range(-3.2, 3.2)
                ctx.setStrokeColor(NSColor(hex: hayCols[i % hayCols.count]).cgColor)
                ctx.setLineWidth(rng.range(0.75, 1.35))
                ctx.move(to: CGPoint(x: x, y: y))
                ctx.addQuadCurve(to: CGPoint(x: x + cos(ang) * len, y: y + sin(ang) * len),
                                 control: CGPoint(x: x + cos(ang) * len * 0.5 + bend, y: y + sin(ang) * len * 0.5))
                ctx.strokePath()
            }

            // Natural paper-pellet litter surface.
            let litter = rounded(CGRect(x: 5.5, y: 21.5, width: s.width - 11, height: 16.5), 6)
            vGradient(ctx, litter, top: NSColor(hex: 0xE1D6BE), bottom: NSColor(hex: 0xEFE6D3), from: 21.5, to: 38)
            ctx.saveGState(); ctx.addPath(litter); ctx.clip()
            for _ in 0..<130 {
                let x = rng.range(8, s.width - 8), y = rng.range(22.5, 37.5)
                let rw = rng.range(1.1, 2.2), rh = rng.range(0.7, 1.2)
                let col: UInt32 = rng.next() > 0.52 ? 0xD2C4A8 : (rng.next() > 0.4 ? 0xF6EFE0 : 0xC6B79A)
                ctx.setFillColor(NSColor(hex: col, alpha: 0.85).cgColor)
                ctx.fillEllipse(in: CGRect(x: x - rw * 0.5, y: y - rh * 0.5, width: rw, height: rh))
            }
            let innerAO = CGGradient(colorsSpace: sRGB,
                                     colors: [NSColor(hex: 0x3D5E55, alpha: 0.22).cgColor,
                                              NSColor(hex: 0x3D5E55, alpha: 0).cgColor] as CFArray,
                                     locations: [0, 1])!
            ctx.drawLinearGradient(innerAO, start: CGPoint(x: 0, y: 38), end: CGPoint(x: 0, y: 32), options: [])
            ctx.restoreGState()

            ctx.addPath(back)
            ctx.setStrokeColor(NSColor(hex: 0x4A7369).cgColor)
            ctx.setLineWidth(1.25)
            ctx.strokePath()
        }
    }

    static func litterFront() -> SKTexture {
        let s = litterSize
        return render(s) { ctx in
            let h = litterWallHeight
            ctx.setFillColor(NSColor(hex: 0x3A2818, alpha: 0.15).cgColor)
            ctx.fillEllipse(in: CGRect(x: 4, y: -1, width: s.width - 8, height: 6))

            let wall = CGMutablePath()
            wall.move(to: CGPoint(x: 6, y: 1.5))
            wall.addLine(to: CGPoint(x: s.width - 6, y: 1.5))
            wall.addQuadCurve(to: CGPoint(x: s.width - 1, y: h), control: CGPoint(x: s.width - 1, y: 1.5))
            wall.addLine(to: CGPoint(x: 1, y: h))
            wall.addQuadCurve(to: CGPoint(x: 6, y: 1.5), control: CGPoint(x: 1, y: 1.5))
            wall.closeSubpath()
            vGradient(ctx, wall, top: NSColor(hex: 0x99C9BC), bottom: NSColor(hex: 0x67978A), from: 1.5, to: h)

            // Soft organic curved matte sheen.
            ctx.saveGState(); ctx.addPath(wall); ctx.clip()
            radial(CGPoint(x: 34, y: h * 0.72), 28, .white, 0.24, ctx)
            let underLip = CGGradient(colorsSpace: sRGB,
                                      colors: [NSColor(hex: 0x3A6158, alpha: 0.28).cgColor,
                                               NSColor(hex: 0x3A6158, alpha: 0).cgColor] as CFArray,
                                      locations: [0, 1])!
            ctx.drawLinearGradient(underLip, start: CGPoint(x: 0, y: h - 2), end: CGPoint(x: 0, y: h - 7), options: [])
            ctx.restoreGState()

            ctx.addPath(wall)
            ctx.setStrokeColor(NSColor(hex: 0x4A7369).cgColor)
            ctx.setLineWidth(1.25)
            ctx.strokePath()

            // Rolled lip along the top.
            let lip = rounded(CGRect(x: 0, y: h - 3, width: s.width, height: 6), 3)
            vGradient(ctx, lip, top: NSColor(hex: 0xBCE2D6), bottom: NSColor(hex: 0x8BC0B1), from: h - 3, to: h + 3)
            ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.38).cgColor)
            ctx.setLineWidth(0.8)
            ctx.move(to: CGPoint(x: 4, y: h + 2)); ctx.addLine(to: CGPoint(x: s.width - 4, y: h + 2)); ctx.strokePath()
            ctx.addPath(lip)
            ctx.setStrokeColor(NSColor(hex: 0x4A7369).cgColor)
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
            ctx.setFillColor(NSColor(hex: 0x3A2818, alpha: 0.16).cgColor)
            ctx.fillEllipse(in: CGRect(x: 2, y: -1, width: s.width - 4, height: 5.5))

            let backCols: [UInt32] = [0x908C43, 0xA4984A, 0x868B46, 0xB2A352]
            let midCols: [UInt32]  = [0xC9B95D, 0xB7B95D, 0xD5C46A, 0xA8B155]
            let topCols: [UInt32]  = [0xE4D582, 0xEFE19A, 0xCDD072, 0xDFCF78]

            func strand(_ x: CGFloat, _ y: CGFloat, _ ang: CGFloat, _ len: CGFloat, palette: [UInt32], width: CGFloat) {
                ctx.setStrokeColor(NSColor(hex: palette[Int(rng.next() * CGFloat(palette.count)) % palette.count]).cgColor)
                ctx.setLineWidth(width)
                let bend = rng.range(-3.2, 3.2)
                ctx.move(to: CGPoint(x: x, y: y))
                ctx.addQuadCurve(to: CGPoint(x: x + cos(ang) * len, y: y + sin(ang) * len),
                                 control: CGPoint(x: x + cos(ang) * len * 0.5 - sin(ang) * bend,
                                                  y: y + sin(ang) * len * 0.5 + cos(ang) * bend))
                ctx.strokePath()
            }

            // Layered botanical timothy hay mound above the box.
            let moundH = 3 + 40 * level
            if level > 0.02 {
                let coreH = moundH * 0.85
                ctx.setFillColor(NSColor(hex: 0x9C9246, alpha: 0.45).cgColor)
                ctx.fillEllipse(in: CGRect(x: 10, y: boxH - 8, width: s.width - 20, height: coreH * 1.4))

                for _ in 0..<(16 + Int(85 * level)) {
                    let u = rng.range(-1, 1)
                    let maxY = moundH * sqrt(max(0, 1 - u * u))
                    let x = s.width / 2 + u * (s.width / 2 - 7)
                    let y = boxH - 4 + rng.range(0, max(1, maxY))
                    let ang = rng.range(-0.85, 0.85) + (rng.next() > 0.5 ? 0 : .pi)
                    strand(x - cos(ang) * 5, y, ang, rng.range(8, 15), palette: backCols, width: rng.range(0.9, 1.5))
                }
                for _ in 0..<(16 + Int(95 * level)) {
                    let u = rng.range(-1, 1)
                    let maxY = moundH * sqrt(max(0, 1 - u * u))
                    let x = s.width / 2 + u * (s.width / 2 - 6)
                    let y = boxH - 2 + rng.range(0, max(1, maxY))
                    let ang = rng.range(-0.75, 0.75) + (rng.next() > 0.5 ? 0 : .pi)
                    strand(x - cos(ang) * 6, y, ang, rng.range(9, 16), palette: midCols, width: rng.range(0.8, 1.3))
                }
                for _ in 0..<(10 + Int(55 * level)) {
                    let u = rng.range(-0.92, 0.92)
                    let maxY = moundH * sqrt(max(0, 1 - u * u))
                    let x = s.width / 2 + u * (s.width / 2 - 7)
                    let y = boxH + rng.range(maxY * 0.25, max(2, maxY))
                    let ang = rng.range(-0.65, 0.65) + (rng.next() > 0.5 ? 0 : .pi)
                    strand(x - cos(ang) * 5, y, ang, rng.range(7, 14), palette: topCols, width: rng.range(0.65, 1.15))
                }
                // Fluffy cylindrical timothy seed-heads poking softly out of the mound.
                for i in 0..<Int(5 * level + 1) {
                    let sx = 16 + CGFloat(i) * (s.width - 32) / max(1, CGFloat(Int(5 * level))) + rng.range(-4, 4)
                    let sy = boxH + moundH * rng.range(0.55, 0.92)
                    let ang = rng.range(1.1, 2.0)
                    let len = rng.range(7, 12)
                    strand(sx, sy, ang, len, palette: midCols, width: 0.9)
                    let tx = sx + cos(ang) * len, ty = sy + sin(ang) * len
                    ctx.saveGState()
                    ctx.translateBy(x: tx, y: ty)
                    ctx.rotate(by: ang)
                    ctx.setFillColor(NSColor(hex: 0xC6BC72).cgColor)
                    ctx.fillEllipse(in: CGRect(x: -3.2, y: -1.35, width: 6.4, height: 2.7))
                    ctx.setFillColor(NSColor(hex: 0xE7DC98, alpha: 0.7).cgColor)
                    ctx.fillEllipse(in: CGRect(x: -2.2, y: -0.6, width: 4.4, height: 1.3))
                    ctx.restoreGState()
                }
            }

            // The box: dark inside, grained wooden slats in front with hay showing through.
            let box = rounded(CGRect(x: 2, y: 1, width: s.width - 4, height: boxH), 3)
            ctx.addPath(box)
            ctx.setFillColor((level > 0.02 ? NSColor(hex: 0x8E823C) : NSColor(hex: 0x5B4229)).cgColor)
            ctx.fillPath()
            if level > 0.02 {
                ctx.saveGState(); ctx.addPath(box); ctx.clip()
                for _ in 0..<45 {
                    strand(rng.range(2, s.width - 2), rng.range(2, boxH), rng.range(-0.6, 0.6), rng.range(6, 12), palette: midCols, width: 1.0)
                }
                ctx.restoreGState()
            }

            let slatW: CGFloat = 14
            var x: CGFloat = 2
            while x < s.width - 4 {
                let w = min(slatW, s.width - 2 - x)
                let slat = rounded(CGRect(x: x, y: 1, width: w, height: boxH), 2.2)
                vGradient(ctx, slat, top: NSColor(hex: 0xD8B180), bottom: NSColor(hex: 0xA87F52), from: 1, to: boxH)
                ctx.saveGState(); ctx.addPath(slat); ctx.clip()
                ctx.setStrokeColor(NSColor(hex: 0x8E683E, alpha: 0.32).cgColor)
                ctx.setLineWidth(0.55)
                ctx.move(to: CGPoint(x: x + w * 0.35, y: 2)); ctx.addLine(to: CGPoint(x: x + w * 0.35, y: boxH - 2))
                ctx.move(to: CGPoint(x: x + w * 0.72, y: 3)); ctx.addLine(to: CGPoint(x: x + w * 0.68, y: boxH - 1))
                ctx.strokePath()
                ctx.setFillColor(NSColor(hex: 0x5E4326, alpha: 0.22).cgColor)
                ctx.fill(CGRect(x: x, y: boxH - 5.2, width: w, height: 2.6))
                ctx.restoreGState()
                ctx.addPath(slat)
                ctx.setStrokeColor(NSColor(hex: 0x6F5133).cgColor)
                ctx.setLineWidth(0.9)
                ctx.strokePath()
                x += slatW + 3.6
            }

            // Top rail.
            let rail = rounded(CGRect(x: 0, y: boxH - 3, width: s.width, height: 5.2), 2.2)
            vGradient(ctx, rail, top: NSColor(hex: 0xE7C595), bottom: NSColor(hex: 0xB48B5B), from: boxH - 3, to: boxH + 2.2)
            ctx.setStrokeColor(NSColor(hex: 0xF7E4C1, alpha: 0.7).cgColor)
            ctx.setLineWidth(0.75)
            ctx.move(to: CGPoint(x: 3, y: boxH + 1.4)); ctx.addLine(to: CGPoint(x: s.width - 3, y: boxH + 1.4)); ctx.strokePath()
            ctx.addPath(rail)
            ctx.setStrokeColor(NSColor(hex: 0x64482B).cgColor)
            ctx.setLineWidth(1.05)
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
            let fy: CGFloat = 4, by: CGFloat = 40
            let f0: CGFloat = 8, f1 = s.width - 8, b0: CGFloat = 14, b1 = s.width - 14
            func map(_ u: CGFloat, _ v: CGFloat) -> CGPoint {
                let vv = pow(v, 1.12)
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

            let navy: UInt32 = 0x355066, rose: UInt32 = 0xC47A6E, field: UInt32 = 0xEEDCCD
            let slate: UInt32 = 0x5D7E96, cream: UInt32 = 0xF7EFE2, gold: UInt32 = 0xD2AC67, rust: UInt32 = 0xA8584E

            ctx.setFillColor(NSColor(hex: 0x3A2818, alpha: 0.14).cgColor)
            ctx.addPath(quad(-0.015, -0.06, 1.015, 0.96)); ctx.fillPath()

            // Woven fringe on the short ends.
            var rng = Seeded(state: 77)
            ctx.setLineWidth(0.75)
            for i in 0...15 {
                let v = CGFloat(i) / 15
                for (u, du) in [(0.0, -0.048), (1.0, 0.048)] as [(CGFloat, CGFloat)] {
                    ctx.setStrokeColor(NSColor(hex: i % 2 == 0 ? cream : 0xE5D9C5).cgColor)
                    let p0 = map(u, v), p1 = map(u + du, v + rng.range(-0.012, 0.012))
                    ctx.move(to: p0); ctx.addLine(to: p1); ctx.strokePath()
                }
            }

            // Outer navy border, gold pinstripe, inner rose band, warm field.
            fill(quad(0, 0, 1, 1), navy)
            fill(quad(0.032, 0.11, 0.968, 0.89), gold, 0.88)
            fill(quad(0.042, 0.14, 0.958, 0.86), rose)
            fill(quad(0.068, 0.22, 0.932, 0.78), field)

            // Repeating gold/cream diamond motifs along the navy border.
            for i in 0..<18 {
                let u = 0.028 + CGFloat(i) * 0.0555
                fill(diamond(u, 0.055, 0.011, 0.034), i % 2 == 0 ? gold : cream, 0.92)
                fill(diamond(u, 0.945, 0.011, 0.034), i % 2 == 0 ? gold : cream, 0.92)
            }
            // Central stepped medallion and corner spandrels.
            fill(diamond(0.5, 0.5, 0.21, 0.30), slate)
            fill(diamond(0.5, 0.5, 0.16, 0.23), gold, 0.85)
            fill(diamond(0.5, 0.5, 0.12, 0.17), cream)
            fill(diamond(0.5, 0.5, 0.055, 0.09), rust)
            for (cu, cv) in [(0.068, 0.22), (0.932, 0.22), (0.068, 0.78), (0.932, 0.78)] as [(CGFloat, CGFloat)] {
                fill(diamond(cu, cv, 0.075, 0.15), slate, 0.88)
                fill(diamond(cu, cv, 0.035, 0.07), gold, 0.85)
            }
            for cu in [0.21, 0.79] as [CGFloat] {
                fill(diamond(cu, 0.5, 0.038, 0.13), rose, 0.92)
                fill(diamond(cu, 0.5, 0.016, 0.055), cream, 0.9)
            }

            // Gently worn, woven texture.
            ctx.saveGState(); ctx.addPath(quad(0, 0, 1, 1)); ctx.clip()
            for _ in 0..<260 {
                let p = map(rng.next(), rng.next())
                ctx.setFillColor(NSColor(white: rng.next() > 0.35 ? 1 : 0, alpha: rng.range(0.03, 0.10)).cgColor)
                ctx.fill(CGRect(x: p.x, y: p.y, width: rng.range(0.9, 2.4), height: 0.55))
            }
            ctx.restoreGState()
            ctx.addPath(quad(0, 0, 1, 1))
            ctx.setStrokeColor(NSColor(hex: 0x263B4D).cgColor)
            ctx.setLineWidth(0.9)
            ctx.strokePath()
        }
    }

    /// A glazed stoneware water bowl seen from the side, water showing at the top.
    static let bowlSize = CGSize(width: 56, height: 26)

    static func bowl(level: CGFloat, stale: Bool) -> SKTexture {
        let s = bowlSize
        return render(s) { ctx in
            let rimY: CGFloat = 17
            ctx.setFillColor(NSColor(hex: 0x2B221B, alpha: 0.18).cgColor)
            ctx.fillEllipse(in: CGRect(x: 9, y: -0.5, width: s.width - 18, height: 5.5))

            let body = CGMutablePath()
            body.move(to: CGPoint(x: 2, y: rimY))
            body.addLine(to: CGPoint(x: s.width - 2, y: rimY))
            body.addQuadCurve(to: CGPoint(x: s.width - 12, y: 1.5), control: CGPoint(x: s.width - 4, y: 3))
            body.addLine(to: CGPoint(x: 12, y: 1.5))
            body.addQuadCurve(to: CGPoint(x: 2, y: rimY), control: CGPoint(x: 4, y: 3))
            body.closeSubpath()
            vGradient(ctx, body, top: NSColor(hex: 0x8EB5DF), bottom: NSColor(hex: 0x5278AC), from: 1.5, to: rimY)

            // Handmade stoneware glaze lighting & subtle ceramic speckles.
            ctx.saveGState(); ctx.addPath(body); ctx.clip()
            radial(CGPoint(x: 16, y: 12), 14, .white, 0.32, ctx)
            radial(CGPoint(x: s.width - 10, y: 5), 14, NSColor(hex: 0x2A4366), 0.25, ctx)
            var rng = Seeded(state: 303)
            for _ in 0..<24 {
                ctx.setFillColor(NSColor(hex: rng.next() > 0.5 ? 0x3B577E : 0xDCE8F7, alpha: 0.22).cgColor)
                let rx = rng.range(6, s.width - 6), ry = rng.range(3, rimY - 2)
                ctx.fillEllipse(in: CGRect(x: rx, y: ry, width: 0.9, height: 0.9))
            }
            ctx.restoreGState()

            ctx.addPath(body)
            ctx.setStrokeColor(NSColor(hex: 0x3B5882).cgColor)
            ctx.setLineWidth(1.15)
            ctx.strokePath()

            // Rim and the inside, seen from a little above.
            let rim = CGRect(x: 1, y: rimY - 5, width: s.width - 2, height: 11)
            ctx.setFillColor(NSColor(hex: 0xF5F0E6).cgColor)
            ctx.fillEllipse(in: rim)
            let inside = rim.insetBy(dx: 3.4, dy: 2.1)
            ctx.setFillColor(NSColor(hex: 0xD3DADF).cgColor)
            ctx.fillEllipse(in: inside)

            if level > 0.02 {
                let k = 0.45 + 0.55 * level
                let water = CGRect(x: inside.midX - inside.width * k / 2,
                                   y: inside.midY - inside.height * k / 2 - (1 - level) * 1.2,
                                   width: inside.width * k, height: inside.height * k)
                let wPath = CGPath(ellipseIn: water, transform: nil)
                vGradient(ctx, wPath,
                          top: stale ? NSColor(hex: 0x99B295) : NSColor(hex: 0x6DB8E8),
                          bottom: stale ? NSColor(hex: 0xB8CEB2) : NSColor(hex: 0xA8DCFA),
                          from: water.minY, to: water.maxY)
                if !stale {
                    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.72).cgColor)
                    ctx.setLineWidth(0.9)
                    ctx.move(to: CGPoint(x: water.minX + water.width * 0.20, y: water.midY + 0.6))
                    ctx.addQuadCurve(to: CGPoint(x: water.minX + water.width * 0.46, y: water.midY + 1.0),
                                     control: CGPoint(x: water.minX + water.width * 0.33, y: water.maxY - 0.8))
                    ctx.strokePath()
                    ctx.setFillColor(NSColor.white.withAlphaComponent(0.85).cgColor)
                    ctx.fillEllipse(in: CGRect(x: water.minX + water.width * 0.54, y: water.midY + 0.6, width: 2.2, height: 1.1))
                }
            }
            ctx.setStrokeColor(NSColor(hex: 0x3B5882).cgColor)
            ctx.setLineWidth(1.05)
            ctx.strokeEllipse(in: rim)
        }
    }

    static func poop() -> SKTexture {
        render(CGSize(width: 9, height: 9)) { ctx in
            ctx.setFillColor(NSColor(hex: 0x2B1D13, alpha: 0.20).cgColor)
            ctx.fillEllipse(in: CGRect(x: 1.5, y: 0.7, width: 6.5, height: 3))
            let p = CGPath(ellipseIn: CGRect(x: 1.5, y: 1.5, width: 6, height: 6), transform: nil)
            vGradient(ctx, p, top: NSColor(hex: 0x634431), bottom: NSColor(hex: 0x3C271B), from: 1.5, to: 7.5)
            ctx.setFillColor(NSColor(hex: 0x8A634B, alpha: 0.7).cgColor)
            ctx.fillEllipse(in: CGRect(x: 2.8, y: 4.5, width: 2.0, height: 1.4))
        }
    }

    static func pee() -> SKTexture {
        render(CGSize(width: 26, height: 14)) { ctx in
            ctx.setFillColor(NSColor(hex: 0xF0DC6E, alpha: 0.36).cgColor)
            ctx.fillEllipse(in: CGRect(x: 1, y: 1, width: 24, height: 12))
            ctx.setFillColor(NSColor(hex: 0xF0DC6E, alpha: 0.24).cgColor)
            ctx.fillEllipse(in: CGRect(x: 15, y: 6, width: 9, height: 6))
            ctx.setFillColor(NSColor.white.withAlphaComponent(0.28).cgColor)
            ctx.fillEllipse(in: CGRect(x: 6, y: 7.5, width: 6, height: 2.2))
        }
    }

    /// Bespoke hand-painted storybook icon inside a frosted warm-parchment button disc.
    static func buttonIcon(id: String) -> SKTexture {
        let s = CGSize(width: 34, height: 34)
        return render(s) { ctx in
            let c = CGPoint(x: 17, y: 17)
            ctx.setFillColor(NSColor(hex: 0x2B221B, alpha: 0.14).cgColor)
            ctx.fillEllipse(in: CGRect(x: 2, y: 0.8, width: 30, height: 30))
            let disc = CGPath(ellipseIn: CGRect(x: 2, y: 2, width: 30, height: 30), transform: nil)
            vGradient(ctx, disc, top: NSColor(hex: 0xFFFDF8, alpha: 0.96), bottom: NSColor(hex: 0xF0E8DC, alpha: 0.94), from: 2, to: 32)
            ctx.addPath(disc)
            ctx.setStrokeColor(NSColor(hex: 0x8E7C6B, alpha: 0.34).cgColor)
            ctx.setLineWidth(1.0)
            ctx.strokePath()

            switch id {
            case "hay":
                let stalks: [(dx: CGFloat, ang: CGFloat, col: UInt32)] = [
                    (-3.2, 1.92, 0x9EAA52), (-1.4, 1.72, 0xD2BE62), (0.0, 1.57, 0xE2CE74),
                    (1.5, 1.42, 0xC6B256), (3.2, 1.24, 0xA4AF55)
                ]
                for st in stalks {
                    let bx = c.x + st.dx * 0.65, by = c.y - 7.5
                    let tx = bx + cos(st.ang) * 14.5, ty = by + sin(st.ang) * 14.5
                    ctx.setStrokeColor(NSColor(hex: st.col).cgColor)
                    ctx.setLineWidth(1.6)
                    ctx.move(to: CGPoint(x: bx, y: by))
                    ctx.addQuadCurve(to: CGPoint(x: tx, y: ty),
                                     control: CGPoint(x: (bx + tx) * 0.5 + st.dx * 0.4, y: (by + ty) * 0.5))
                    ctx.strokePath()
                    ctx.saveGState()
                    ctx.translateBy(x: tx, y: ty)
                    ctx.rotate(by: st.ang)
                    ctx.setFillColor(NSColor(hex: 0xE7D580).cgColor)
                    ctx.fillEllipse(in: CGRect(x: -2.4, y: -1.1, width: 4.8, height: 2.2))
                    ctx.restoreGState()
                }
                ctx.setStrokeColor(NSColor(hex: 0xA86B4C).cgColor)
                ctx.setLineWidth(1.7)
                ctx.move(to: CGPoint(x: c.x - 3.6, y: c.y - 2.6))
                ctx.addQuadCurve(to: CGPoint(x: c.x + 3.6, y: c.y - 2.6), control: CGPoint(x: c.x, y: c.y - 3.8))
                ctx.strokePath()

            case "water":
                let drop = CGMutablePath()
                drop.move(to: CGPoint(x: c.x, y: c.y + 8.5))
                drop.addCurve(to: CGPoint(x: c.x + 6.4, y: c.y - 1.8),
                              control1: CGPoint(x: c.x + 2.8, y: c.y + 4.2),
                              control2: CGPoint(x: c.x + 6.4, y: c.y + 1.4))
                drop.addArc(center: CGPoint(x: c.x, y: c.y - 1.8), radius: 6.4, startAngle: 0, endAngle: .pi, clockwise: true)
                drop.addCurve(to: CGPoint(x: c.x, y: c.y + 8.5),
                              control1: CGPoint(x: c.x - 6.4, y: c.y + 1.4),
                              control2: CGPoint(x: c.x - 2.8, y: c.y + 4.2))
                drop.closeSubpath()
                vGradient(ctx, drop, top: NSColor(hex: 0x9AD8FA), bottom: NSColor(hex: 0x4E94D4), from: c.y - 8, to: c.y + 8.5)
                ctx.addPath(drop)
                ctx.setStrokeColor(NSColor(hex: 0x3B72A8).cgColor)
                ctx.setLineWidth(1.0)
                ctx.strokePath()
                ctx.setFillColor(NSColor.white.withAlphaComponent(0.85).cgColor)
                ctx.fillEllipse(in: CGRect(x: c.x - 3.2, y: c.y - 0.5, width: 2.3, height: 4.0))

            case "clean":
                ctx.saveGState()
                ctx.translateBy(x: c.x, y: c.y)
                ctx.rotate(by: -0.58)
                let handle = rounded(CGRect(x: -1.1, y: 0, width: 2.2, height: 9.2), 1.0)
                vGradient(ctx, handle, top: NSColor(hex: 0xB8875B), bottom: NSColor(hex: 0x8A5F3B), from: 0, to: 9.2)
                ctx.addPath(handle); ctx.setStrokeColor(NSColor(hex: 0x6A482B).cgColor); ctx.setLineWidth(0.75); ctx.strokePath()
                let bristles = CGMutablePath()
                bristles.move(to: CGPoint(x: -2.2, y: 0))
                bristles.addLine(to: CGPoint(x: 2.2, y: 0))
                bristles.addLine(to: CGPoint(x: 5.2, y: -8.6))
                bristles.addQuadCurve(to: CGPoint(x: -5.2, y: -8.6), control: CGPoint(x: 0, y: -9.6))
                bristles.closeSubpath()
                vGradient(ctx, bristles, top: NSColor(hex: 0xE7CF83), bottom: NSColor(hex: 0xC6A254), from: -9, to: 0)
                ctx.addPath(bristles); ctx.setStrokeColor(NSColor(hex: 0x8A6D35).cgColor); ctx.setLineWidth(0.8); ctx.strokePath()
                ctx.setStrokeColor(NSColor(hex: 0x9C7D3E, alpha: 0.6).cgColor)
                ctx.setLineWidth(0.65)
                for dx in [-2.2, 0.0, 2.2] as [CGFloat] {
                    ctx.move(to: CGPoint(x: dx * 0.5, y: -1.5)); ctx.addLine(to: CGPoint(x: dx * 1.4, y: -8.2))
                }
                ctx.strokePath()
                let band = rounded(CGRect(x: -2.6, y: -1.6, width: 5.2, height: 2.2), 0.9)
                ctx.addPath(band); ctx.setFillColor(NSColor(hex: 0xC47462).cgColor); ctx.fillPath()
                ctx.restoreGState()

            default:
                let earL = CGPath(ellipseIn: CGRect(x: c.x - 5.2, y: c.y + 1.2, width: 3.6, height: 8.6), transform: nil)
                let earR = CGPath(ellipseIn: CGRect(x: c.x + 1.6, y: c.y + 1.2, width: 3.6, height: 8.6), transform: nil)
                let head = CGPath(ellipseIn: CGRect(x: c.x - 6.8, y: c.y - 6.8, width: 13.6, height: 11.4), transform: nil)
                for p in [earL, earR, head] {
                    ctx.addPath(p); ctx.setStrokeColor(NSColor(hex: 0x6B5A4E).cgColor); ctx.setLineWidth(1.5); ctx.strokePath()
                }
                for p in [earL, earR, head] {
                    ctx.addPath(p); ctx.setFillColor(NSColor(hex: 0xF5EFE6).cgColor); ctx.fillPath()
                }
                ctx.setFillColor(NSColor(hex: 0xE7B7B0).cgColor)
                ctx.fillEllipse(in: CGRect(x: c.x - 4.2, y: c.y + 2.6, width: 1.6, height: 5.6))
                ctx.fillEllipse(in: CGRect(x: c.x + 2.6, y: c.y + 2.6, width: 1.6, height: 5.6))
                ctx.setFillColor(NSColor(hex: 0x3A2A22).cgColor)
                ctx.fillEllipse(in: CGRect(x: c.x - 3.6, y: c.y - 1.5, width: 1.8, height: 1.9))
                ctx.fillEllipse(in: CGRect(x: c.x + 1.8, y: c.y - 1.5, width: 1.8, height: 1.9))
                ctx.setFillColor(NSColor(hex: 0xCC958E).cgColor)
                ctx.fillEllipse(in: CGRect(x: c.x - 1.2, y: c.y - 3.6, width: 2.4, height: 1.6))
            }
        }
    }
}

/// A round button with a hand-painted icon, a hover label and an attention badge.
@MainActor
final class PenButton: SKNode {
    let id: String
    let radius: CGFloat = 15
    private let disc: SKSpriteNode
    private let tip: SKNode
    private let badge: SKNode

    init(id: String, emoji: String, tipText: String) {
        self.id = id
        _ = emoji
        disc = SKSpriteNode(texture: PropArt.buttonIcon(id: id))
        disc.size = CGSize(width: 34, height: 34)

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
        alpha = 0.88
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    func contains(scenePoint p: CGPoint) -> Bool { p.distance(to: position) <= radius + 3 }

    /// Keeps the hover label readable when everything is drawn small.
    func setLabelScale(_ k: CGFloat) {
        tip.setScale(k)
        tip.position = CGPoint(x: 0, y: radius + 4 + 10 * k)
    }

    func setHover(_ on: Bool) {
        tip.removeAllActions()
        tip.run(.fadeAlpha(to: on ? 1 : 0, duration: 0.12))
        run(.group([.scale(to: on ? 1.12 : 1, duration: 0.1), .fadeAlpha(to: on ? 1 : 0.88, duration: 0.1)]))
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
    static func pill(_ text: String, fontSize: CGFloat = 11, color: NSColor = NSColor(hex: 0xFCF8F0, alpha: 0.95),
                     textColor: NSColor = NSColor(hex: 0x3A3029)) -> SKNode {
        let label = SKLabelNode(text: text)
        label.fontName = "HelveticaNeue-Medium"
        label.fontSize = fontSize
        label.fontColor = textColor
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        let w = label.frame.width + 14, h = fontSize + 9
        let bg = SKShapeNode(rect: CGRect(x: -w / 2, y: -h / 2, width: w, height: h), cornerRadius: h / 2)
        bg.fillColor = color
        bg.strokeColor = NSColor(hex: 0x7A6857, alpha: 0.24)
        bg.lineWidth = 0.85
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
    /// How far the platform has been slid left from the lower-right corner (points).
    private(set) var shift: CGFloat = 0
    private static let row: CGFloat = 113

    /// Mirrors a design-space x (distance from the corner's screen edge) to the
    /// right side, then slides it left by `shift`.
    private func mx(_ x: CGFloat) -> CGFloat { width - shift - x }
    private func mirrored(_ p: CGPoint) -> CGPoint { CGPoint(x: mx(p.x), y: p.y) }

    /// The furthest left the platform can go: its far end runs off the left
    /// edge by the same amount it runs off the right edge in the corner.
    static func maxShift(width: CGFloat) -> CGFloat {
        max(0, width - PropArt.platformSize.width - 2 * platformOrigin.x)
    }

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
            sprite.size = size            // textures are 4×; show them at point size
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
        layout(width: width, shift: 0)
    }

    /// Places everything in the lower-right corner of a scene this wide, slid
    /// left by `shift` (kept within the screen).
    func layout(width: CGFloat, shift: CGFloat) {
        self.width = width
        self.shift = min(max(shift, 0), Self.maxShift(width: width))
        func place(_ n: SKNode, _ origin: CGPoint, _ size: CGSize) {
            n.position = CGPoint(x: mx(origin.x) - size.width, y: origin.y)
        }
        place(platform, Self.platformOrigin, PropArt.platformSize)
        place(rug, Self.rugOrigin, PropArt.rugSize)
        place(litterBack, Self.litterOrigin, PropArt.litterSize)
        place(litterFront, Self.litterOrigin, PropArt.litterSize)
        place(hayPile, Self.hayOrigin, PropArt.haySize)
        place(bowl, Self.bowlOrigin, PropArt.bowlSize)
        // Buttons stay in reading order (hay, water, clean, menu), above the
        // litter box, ending near the platform's right end.
        for (i, b) in buttons.enumerated() {
            b.position = CGPoint(x: mx(36) - CGFloat(buttons.count - 1 - i) * 38, y: Self.row)
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
        let minX = mx(Self.platformOrigin.x + PropArt.platformSize.width + 10)
        let maxX = mx(Self.platformOrigin.x - 10)
        return CGRect(x: minX, y: 0, width: maxX - minX, height: 140)
    }

    /// Standing on the boards: bunnies and poops in here ride along when the
    /// platform is dragged.
    var surface: CGRect {
        CGRect(x: platform.position.x + 6, y: platform.position.y,
               width: PropArt.platformSize.width - 12, height: PropArt.platformBackY + 6)
    }

    /// Where a press grabs the platform: the boards, the rug and everything on them.
    func grabContains(_ p: CGPoint) -> Bool {
        [platform, rug, litterBack, hayPile, bowl].contains { $0.frame.contains(p) }
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
