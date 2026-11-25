import AppKit
import SpriteKit

// Bunny artwork, drawn in code. Each pose is a "skeleton" of simple shapes
// (body, haunch, head, ears, paws, tail); a BunnyLook colors it in and adds
// the details that make it Snoopy or Bambi.

struct BunnyLook {
    var name: String
    var fur: NSColor              // body
    var furShade: NSColor         // far ear, shadowed bits
    var headFur: NSColor
    /// Darker color that fades in from the face (Snoopy's taupe mask).
    var faceTint: NSColor? = nil
    var earFur: NSColor
    var outline: NSColor
    var innerEar: NSColor
    var eye: NSColor              // pupil / dark of the eye
    var iris: NSColor? = nil      // ruby ring (Snoopy)
    var eyeRing: NSColor? = nil   // pale ring around the eye (Bambi)
    var nose: NSColor
    var muzzle: NSColor? = nil    // soft patch around the nose
    var chin: NSColor? = nil      // pale chin / mouth
    var cheek: NSColor? = nil
    var nape: NSColor? = nil      // warm patch behind the head
    var belly: NSColor? = nil
    var paw: NSColor
    var pawTip: NSColor? = nil
    var tail: NSColor
    var tailTop: NSColor? = nil
    var earRim: NSColor? = nil
    var earTip: NSColor? = nil
    var ticking: (dark: NSColor, light: NSColor)? = nil
    var backShade: CGFloat = 0    // darker along the back (agouti)
    var highlight: CGFloat = 0.22 // soft light from above
    /// 0 = smooth coat, 1 = angora wool (puffier shapes, wisps, ear tassels).
    var fluff: CGFloat = 0
    var wisp: NSColor? = nil
    var tassel: NSColor? = nil
    var earScale: CGFloat = 1
    /// Overall size on screen.
    var scale: CGFloat = 1
    /// Shows a name tag all the time (used for placeholder art).
    var isStandIn = false

    /// English Angora: cream-white wool, taupe-gray face and ears with smoky
    /// tips and long tassels, ruby-brown eyes.
    static let snoopy = BunnyLook(
        name: "Snoopy",
        fur: NSColor(hex: 0xF1EBE3),
        furShade: NSColor(hex: 0xA89C92),
        headFur: NSColor(hex: 0xE6DED4),
        faceTint: NSColor(hex: 0xAA9D92),
        earFur: NSColor(hex: 0xB4A79C),
        outline: NSColor(hex: 0x8E8178),
        innerEar: NSColor(hex: 0xE6B9B3),
        eye: NSColor(hex: 0x2A1515),
        iris: NSColor(hex: 0x7A3633),
        nose: NSColor(hex: 0xC9A09A),
        muzzle: NSColor(hex: 0x8D8076),
        belly: NSColor(hex: 0xF8F5F0),
        paw: NSColor(hex: 0xEDE6DD),
        tail: NSColor(hex: 0xF6F1EA),
        earTip: NSColor(hex: 0x7E736B),
        highlight: 0.18,
        fluff: 1,
        wisp: NSColor(hex: 0xFBF8F3),
        tassel: NSColor(hex: 0xD9CEC4),
        earScale: 0.92,
        scale: 1.06)

    /// Agouti: brown-gray ticked coat, darker back, cream eye ring and muzzle,
    /// white chin, dark-rimmed ears, white toe tips, tail dark on top and
    /// white underneath.
    static let bambi = BunnyLook(
        name: "Bambi",
        fur: NSColor(hex: 0x76634F),
        furShade: NSColor(hex: 0x4E4137),
        headFur: NSColor(hex: 0x7A6550),
        earFur: NSColor(hex: 0x675748),
        outline: NSColor(hex: 0x2E261F),
        innerEar: NSColor(hex: 0xB59A93),
        eye: NSColor(hex: 0x15100D),
        eyeRing: NSColor(hex: 0xD8C6A6),
        nose: NSColor(hex: 0x8C6B60),
        muzzle: NSColor(hex: 0xC9B497),
        chin: NSColor(hex: 0xEFE8DC),
        cheek: NSColor(hex: 0x8E7154),
        nape: NSColor(hex: 0xA3805A),
        belly: NSColor(hex: 0xD9CCB6),
        paw: NSColor(hex: 0x86705A),
        pawTip: NSColor(hex: 0xEEE7DB),
        tail: NSColor(hex: 0xF3EEE6),
        tailTop: NSColor(hex: 0x40362D),
        earRim: NSColor(hex: 0x2A231E),
        earTip: NSColor(hex: 0x231D19),
        ticking: (dark: NSColor(hex: 0x2B241D), light: NSColor(hex: 0xA8937A)),
        backShade: 0.32,
        highlight: 0.08,
        earScale: 1.06)

    static func standIn(named name: String) -> BunnyLook {
        BunnyLook(name: name,
                  fur: NSColor(hex: 0xD9D3CB), furShade: NSColor(hex: 0xB8AFA4), headFur: NSColor(hex: 0xD9D3CB),
                  earFur: NSColor(hex: 0xD9D3CB), outline: NSColor(hex: 0x6B625A), innerEar: NSColor(hex: 0xE8BDB8),
                  eye: NSColor(hex: 0x2A2421), nose: NSColor(hex: 0xD88E8E), paw: NSColor(hex: 0xD9D3CB),
                  tail: NSColor(hex: 0xF1EDE8), isStandIn: true)
    }
}

enum Pose: String, CaseIterable {
    case sit, sitNose, sitEarTwitch
    case crouch, hop, land
    case loaf, sleep, flop
    case eat, eatChew
    case groom, groomB
    case periscope
    case thump
}

// MARK: - Geometry

/// An ellipse: `rx` is the half-length along `angle` (degrees), `ry` across it.
struct Oval {
    var c: CGPoint
    var rx: CGFloat
    var ry: CGFloat
    var angle: CGFloat = 0

    init(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ angle: CGFloat = 0) {
        c = CGPoint(x: x, y: y); self.rx = rx; self.ry = ry; self.angle = angle
    }

    var path: CGPath {
        var t = CGAffineTransform(translationX: c.x, y: c.y).rotated(by: angle * .pi / 180)
        return CGPath(ellipseIn: CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2), transform: &t)
    }
}

struct Ear {
    var base: CGPoint
    var angle: CGFloat
    var length: CGFloat
    var width: CGFloat

    init(_ x: CGFloat, _ y: CGFloat, angle: CGFloat, length: CGFloat = 26, width: CGFloat = 9) {
        base = CGPoint(x: x, y: y); self.angle = angle; self.length = length; self.width = width
    }

    var oval: Oval {
        let r = angle * .pi / 180
        return Oval(base.x + cos(r) * length / 2, base.y + sin(r) * length / 2, length / 2, width / 2, angle)
    }

    var inner: Oval {
        var o = oval
        o.rx *= 0.78; o.ry *= 0.48
        let r = angle * .pi / 180
        o.c.x += cos(r) * 1.5; o.c.y += sin(r) * 1.5
        return o
    }
}

/// Where each body part sits for one pose. Canvas is 100×90 points, the
/// bunny faces right, and the ground is at y = 8.
struct Skeleton {
    var body: Oval
    var haunch: Oval?
    var head: Oval
    var backEar: Ear
    var frontEar: Ear
    var eye: CGPoint
    var eyeOpen: CGFloat          // 1 open, ~0.5 sleepy, 0 closed
    var nose: CGPoint
    var tail: Oval
    var hindFoot: Oval?
    var frontPaws: [Oval] = []

    static func forPose(_ pose: Pose) -> Skeleton {
        switch pose {
        case .sit, .sitNose, .sitEarTwitch, .thump:
            var s = Skeleton(
                body: Oval(46, 27, 25, 17, 12),
                haunch: Oval(36, 24, 16, 15),
                head: Oval(68, 38, 14, 12, -8),
                backEar: Ear(62, 46, angle: 105),
                frontEar: Ear(65, 47, angle: 96, width: 9.5),
                eye: CGPoint(x: 72.5, y: 40.5), eyeOpen: 1,
                nose: CGPoint(x: 81.4, y: 35.6),
                tail: Oval(20, 28, 6, 6.5),
                hindFoot: Oval(42, 10.5, 15, 3.6),
                frontPaws: [Oval(63, 10.5, 5, 3)])
            if pose == .sitNose { s.nose.y += 0.8 }
            if pose == .sitEarTwitch { s.frontEar.angle = 84 }
            if pose == .thump {
                s.hindFoot = Oval(41, 14.5, 14.5, 3.6, 10)
                s.backEar.angle = 98; s.frontEar.angle = 90
            }
            return s
        case .loaf, .sleep:
            var s = Skeleton(
                body: Oval(46, 22, 27, 14.5, 3),
                haunch: Oval(36, 21, 16, 12.5),
                head: Oval(69, 27, 13.5, 11.5, -4),
                backEar: Ear(61, 33, angle: 160, length: 25, width: 8.5),
                frontEar: Ear(64, 35, angle: 154, length: 25),
                eye: CGPoint(x: 73.5, y: 29), eyeOpen: 0.5,
                nose: CGPoint(x: 82, y: 24.6),
                tail: Oval(19, 22, 5.5, 5.5),
                hindFoot: nil,
                frontPaws: [Oval(66, 9.5, 4.5, 2.6)])
            if pose == .sleep {
                s.eyeOpen = 0
                s.backEar.angle = 168; s.frontEar.angle = 163
            }
            return s
        case .crouch:
            return Skeleton(
                body: Oval(46, 22, 26, 14, 8),
                haunch: Oval(36, 22, 16, 13),
                head: Oval(69, 26, 13.5, 11.5, -6),
                backEar: Ear(62, 33, angle: 138, length: 26, width: 8.5),
                frontEar: Ear(65, 34, angle: 130),
                eye: CGPoint(x: 73.5, y: 28.5), eyeOpen: 1,
                nose: CGPoint(x: 82.2, y: 23.8),
                tail: Oval(19, 24, 5.5, 6),
                hindFoot: Oval(40, 9.5, 14, 3.4),
                frontPaws: [Oval(64, 9.5, 5, 2.8)])
        case .hop:
            return Skeleton(
                body: Oval(48, 30, 30, 13, 14),
                haunch: Oval(30, 27, 13, 11.5, 20),
                head: Oval(76, 42, 13, 11.5, 5),
                backEar: Ear(68, 49, angle: 152, length: 26, width: 8.5),
                frontEar: Ear(71, 50, angle: 144),
                eye: CGPoint(x: 80.5, y: 44.5), eyeOpen: 1,
                nose: CGPoint(x: 88.6, y: 41.5),
                tail: Oval(17, 36, 5.5, 6),
                hindFoot: Oval(14, 20, 13, 3.4, -28),
                frontPaws: [Oval(76, 21, 6.5, 2.8, -40)])
        case .land:
            return Skeleton(
                body: Oval(50, 24, 27, 15, -10),
                haunch: Oval(36, 27, 14, 13),
                head: Oval(72, 28, 13.5, 11.5, -15),
                backEar: Ear(66, 36, angle: 142, length: 26, width: 8.5),
                frontEar: Ear(68, 37, angle: 133),
                eye: CGPoint(x: 76, y: 30.5), eyeOpen: 1,
                nose: CGPoint(x: 84, y: 24.5),
                tail: Oval(22, 32, 5.5, 6),
                hindFoot: Oval(30, 16, 12, 3.4, 25),
                frontPaws: [Oval(70, 9.5, 5, 2.8)])
        case .flop:
            return Skeleton(
                body: Oval(46, 17, 31, 10.5),
                haunch: Oval(30, 17, 13, 9.5),
                head: Oval(76, 17.5, 13, 10.5, -12),
                backEar: Ear(68, 21, angle: 178, length: 25, width: 8),
                frontEar: Ear(70, 23, angle: 172, length: 25, width: 8.5),
                eye: CGPoint(x: 79.5, y: 19.5), eyeOpen: 0,
                nose: CGPoint(x: 88, y: 13.8),
                tail: Oval(15, 20, 5, 5.5),
                hindFoot: Oval(10, 12, 12, 3.2, -8),
                frontPaws: [Oval(84, 9.5, 7, 2.6, -5)])
        case .eat, .eatChew:
            var s = Skeleton(
                body: Oval(44, 26, 25, 16.5, 4),
                haunch: Oval(34, 24, 16, 14.5),
                head: Oval(71, 21, 13.5, 11.5, -30),
                backEar: Ear(63, 31, angle: 118),
                frontEar: Ear(66, 32, angle: 110, width: 9.5),
                eye: CGPoint(x: 74, y: 25.5), eyeOpen: 1,
                nose: CGPoint(x: 81, y: 14.5),
                tail: Oval(18, 28, 6, 6.5),
                hindFoot: Oval(40, 10.5, 15, 3.6),
                frontPaws: [Oval(62, 10, 5, 2.8)])
            if pose == .eatChew { s.head.c.y += 0.7; s.nose.y += 0.9 }
            return s
        case .groom, .groomB:
            var s = Skeleton(
                body: Oval(42, 30, 21, 19, 40),
                haunch: Oval(34, 22, 15, 14),
                head: Oval(58, 48, 13, 11.5, 5),
                backEar: Ear(51, 56, angle: 130, length: 25, width: 8.5),
                frontEar: Ear(54, 57, angle: 122, length: 25),
                eye: CGPoint(x: 62, y: 50), eyeOpen: 0.3,
                nose: CGPoint(x: 70.5, y: 47),
                tail: Oval(19, 22, 5.5, 6),
                hindFoot: Oval(40, 10.5, 14, 3.6),
                frontPaws: [Oval(66, 40, 4.5, 3.6, 60), Oval(63.5, 37, 4.5, 3.6, 60)])
            if pose == .groomB {
                s.frontPaws = [Oval(64, 47, 4.5, 3.6, 70), Oval(61.5, 44, 4.5, 3.6, 70)]
                s.eyeOpen = 0
            }
            return s
        case .periscope:
            return Skeleton(
                body: Oval(40, 31, 22, 14, 80),
                haunch: Oval(36, 20, 13, 12),
                head: Oval(47, 55, 12.5, 11),
                backEar: Ear(41, 62, angle: 102, length: 23, width: 8.5),
                frontEar: Ear(44, 63, angle: 94, length: 23),
                eye: CGPoint(x: 51.5, y: 57.5), eyeOpen: 1,
                nose: CGPoint(x: 59.2, y: 53.5),
                tail: Oval(25, 18, 5, 5.5),
                hindFoot: Oval(40, 10, 13, 3.4),
                frontPaws: [Oval(51, 38, 5, 3.2, -70)])
        }
    }
}

// MARK: - Drawing

enum BunnyArtist {
    static let canvas = CGSize(width: 112, height: 96)
    static let groundY: CGFloat = 8
    static let pixelScale: CGFloat = 3
    /// Skeletons are laid out on a 100-wide grid; this centers them.
    static let marginX: CGFloat = 6
    private static let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

    static func image(_ look: BunnyLook, _ pose: Pose) -> CGImage? {
        let w = Int(canvas.width * pixelScale), h = Int(canvas.height * pixelScale)
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: sRGB,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.scaleBy(x: pixelScale, y: pixelScale)
        ctx.translateBy(x: marginX, y: 0)
        draw(Skeleton.forPose(pose), look, ctx)
        return ctx.makeImage()
    }

    static func draw(_ skeleton: Skeleton, _ L: BunnyLook, _ ctx: CGContext) {
        var s = skeleton
        s.backEar.length *= L.earScale
        s.frontEar.length *= L.earScale
        // Angora wool makes everything rounder and bigger.
        let puff = 3.4 * L.fluff
        if puff > 0 {
            s.body.rx += puff; s.body.ry += puff
            if var h = s.haunch { h.rx += puff; h.ry += puff; s.haunch = h }
            s.head.rx += puff; s.head.ry += puff
            s.frontPaws = s.frontPaws.map { var p = $0; p.rx += puff * 0.35; p.ry += puff * 0.45; return p }
            if var f = s.hindFoot { f.ry += puff * 0.3; s.hindFoot = f }
            s.tail.rx += puff; s.tail.ry += puff
            s.backEar.width += puff * 0.5; s.frontEar.width += puff * 0.5
            let a = s.head.angle * .pi / 180
            s.nose.x += cos(a) * puff * 0.85; s.nose.y += sin(a) * puff * 0.85
        }
        if puff > 0 { ctx.translateBy(x: 0, y: puff * 0.75) }
        let fluffy = L.fluff > 0
        let bump = 2.3 + 1.1 * L.fluff
        func shape(_ o: Oval, _ seed: UInt64) -> CGPath { fluffy ? fluffyPath(o, seed: seed, bump: bump) : o.path }

        let backEar = s.backEar.oval.path        // ears stay smooth; wool shows as tassels
        let tail = shape(s.tail, 2)
        let foot = s.hindFoot.map { $0.path }
        let haunch = s.haunch.map { shape($0, 4) }
        let body = shape(s.body, 5)
        let head = shape(s.head, 6)
        let paws = s.frontPaws.map { $0.path }
        let frontEar = s.frontEar.oval.path

        let silhouette = CGMutablePath()
        ([backEar, tail] + [foot, haunch].compactMap { $0 } + [body, head] + paws + [frontEar]).forEach { silhouette.addPath($0) }
        let torso = CGMutablePath()
        ([body, head] + [haunch].compactMap { $0 }).forEach { torso.addPath($0) }

        ctx.setLineJoin(.round)
        ctx.setLineCap(.round)

        // 1. Outline: stroke the silhouette; the fills then cover the inner half.
        ctx.addPath(silhouette)
        ctx.setStrokeColor(L.outline.cgColor)
        ctx.setLineWidth(fluffy ? 2.2 : 2.6)
        ctx.strokePath()

        // 2. Far ear, tail, feet, body, head.
        fill(backEar, L.furShade, ctx)
        if let tip = L.earTip { earTip(s.backEar, backEar, tip.blended(withFraction: 0.25, of: L.furShade) ?? tip, ctx) }
        fill(tail, L.tail, ctx)
        if let top = L.tailTop {
            clipped(tail, ctx) {
                ctx.setFillColor(top.cgColor)
                ctx.fillEllipse(in: CGRect(x: s.tail.c.x - s.tail.rx * 1.3, y: s.tail.c.y - s.tail.ry * 0.15,
                                           width: s.tail.rx * 2.6, height: s.tail.ry * 2.2))
            }
        }
        if let foot, let o = s.hindFoot {
            fill(foot, L.paw, ctx)
            if let tip = L.pawTip { tipOf(o, foot, tip, ctx) }
        }
        fill(body, L.fur, ctx)
        if let haunch {
            fill(haunch, L.fur, ctx)
            if !fluffy { strokeInside(haunch, L.outline.withAlphaComponent(0.3), 0.9, ctx) }
        }
        if fluffy, let wisp = L.wisp {
            // Wool strands on the body, drawn before the head so they don't cross the face.
            let light = [wisp, L.fur, wisp]
            wisps(s.body, seed: 21, count: 18, length: 2.5...5, colors: light, upperOnly: true, ctx)
            if let h = s.haunch { wisps(h, seed: 22, count: 12, length: 2.5...5, colors: light, upperOnly: false, ctx) }
            wisps(s.tail, seed: 23, count: 8, length: 2...4, colors: light, upperOnly: false, ctx)
        }
        fill(head, L.headFur, ctx)
        let faceCenter = CGPoint(x: s.eye.x * 0.4 + s.nose.x * 0.6, y: (s.eye.y + s.nose.y) / 2)
        if let tint = L.faceTint {
            // Fades from the face back into the body color, no hard edge.
            clipped(head, ctx) { radial(faceCenter, s.head.rx * 1.35, tint, 1, ctx) }
        }

        // 3. Coat details.
        if let t = L.ticking {
            clipped(torso, ctx) {
                ticks(s.body, seed: 11, count: 120, t.dark, t.light, ctx)
                if let h = s.haunch { ticks(h, seed: 12, count: 50, t.dark, t.light, ctx) }
                ticks(s.head, seed: 13, count: 32, t.dark, t.light, ctx)
            }
        }
        clipped(torso, ctx) {
            let box = torso.boundingBoxOfPath
            if L.backShade > 0 {
                let g = CGGradient(colorsSpace: sRGB, colors: [NSColor(white: 0, alpha: L.backShade).cgColor,
                                                               NSColor(white: 0, alpha: 0).cgColor] as CFArray,
                                   locations: [0, 1])!
                ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: box.maxY), end: CGPoint(x: 0, y: box.midY), options: [])
            }
            let g = CGGradient(colorsSpace: sRGB, colors: [NSColor(white: 1, alpha: L.highlight).cgColor,
                                                           NSColor(white: 1, alpha: 0).cgColor,
                                                           NSColor(white: 0, alpha: 0.12).cgColor] as CFArray,
                               locations: [0, 0.5, 1])!
            ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: box.maxY), end: CGPoint(x: 0, y: box.minY), options: [])
            if let belly = L.belly {
                let o = s.body
                ctx.setFillColor(belly.withAlphaComponent(0.9).cgColor)
                ctx.addPath(Oval(o.c.x + 3, o.c.y - o.ry * 0.95, o.rx * 0.8, o.ry * 0.45, o.angle * 0.5).path)
                ctx.fillPath()
            }
            if let nape = L.nape {
                radial(CGPoint(x: s.head.c.x - s.head.rx * 0.75, y: s.head.c.y + s.head.ry * 0.25), 7, nape, 0.85, ctx)
            }
        }
        clipped(head, ctx) {
            if let cheek = L.cheek {
                radial(CGPoint(x: s.head.c.x + 1, y: s.head.c.y - s.head.ry * 0.25), s.head.rx * 0.55, cheek, 0.8, ctx)
            }
            if let m = L.muzzle {
                let w: CGFloat = fluffy ? 0.15 : 0.3
                let c = CGPoint(x: s.eye.x * w + s.nose.x * (1 - w) - (fluffy ? 1.5 : 0), y: s.eye.y * w + s.nose.y * (1 - w) - 1)
                radial(c, fluffy ? 6 : 6.5, m, fluffy ? 0.6 : 0.9, ctx)
            }
            if let chin = L.chin {
                let c = rotated(s.nose, s.head.angle, -2.5, -4.2)
                radial(c, 4.2, chin, 0.95, ctx)
            }
            if let ring = L.eyeRing {
                ctx.setFillColor(ring.withAlphaComponent(0.75).cgColor)
                ctx.fillEllipse(in: CGRect(x: s.eye.x - 3.9, y: s.eye.y - 3.6, width: 7.8, height: 7.2))
            }
        }

        // 4. Front paws and the near ear.
        for (i, paw) in paws.enumerated() {
            fill(paw, L.paw, ctx)
            if let tip = L.pawTip { tipOf(s.frontPaws[i], paw, tip, ctx) }
            strokeInside(paw, L.outline.withAlphaComponent(fluffy ? 0.3 : 0.5), 1.0, ctx)
        }
        drawEarFront(s.frontEar, frontEar, L, ctx)

        // 5. Face.
        drawEye(at: s.eye, open: s.eyeOpen, L, ctx)
        let mouthColor = (fluffy ? (L.muzzle ?? L.outline) : L.outline).withAlphaComponent(fluffy ? 0.6 : 0.75)
        let whiskerColor = (fluffy ? L.wisp ?? L.outline : L.outline).withAlphaComponent(fluffy ? 0.55 : 0.45)
        let n = s.nose
        // Side view: nose at the tip, the lip running down and back from it.
        let a = s.head.angle
        ctx.setFillColor(L.nose.cgColor)
        ctx.fillEllipse(in: CGRect(x: n.x - 1.3, y: n.y - 1.0, width: 2.6, height: 2.1))
        ctx.setStrokeColor(mouthColor.cgColor)
        ctx.setLineWidth(fluffy ? 0.55 : 0.75)
        ctx.move(to: rotated(n, a, -0.5, -0.9))
        ctx.addLine(to: rotated(n, a, -0.9, -2.5))
        ctx.addQuadCurve(to: rotated(n, a, -3.4, -3.1), control: rotated(n, a, -1.3, -3.5))
        ctx.strokePath()
        ctx.setStrokeColor(whiskerColor.cgColor)
        ctx.setLineWidth(0.5)
        for dy in [-1.6, 0.0, 1.6] as [CGFloat] {
            ctx.move(to: rotated(n, a, -2.6, -1.6))
            ctx.addLine(to: rotated(n, a, 6.5, -1.6 + dy * 1.4))
        }
        ctx.strokePath()

        // 6. Angora wool: wisps along the edges, cheek furnishings, ear tassels, bangs.
        if fluffy, let wisp = L.wisp {
            wisps(s.head, seed: 24, count: 16, length: 2...4.5, colors: [L.headFur, (L.faceTint ?? L.furShade).withAlphaComponent(0.7)],
                  upperOnly: false, ctx)
            for ear in [s.backEar, s.frontEar] {
                let t = L.tassel ?? wisp
                tassels(ear, seed: ear.base.x > s.backEar.base.x ? 31 : 32,
                        colors: [t, t.blended(withFraction: 0.35, of: L.earTip ?? L.earFur) ?? t, t], ctx)
            }
            // A few strands of fringe falling over the eye.
            ctx.setLineWidth(0.8)
            let bangColor = L.faceTint ?? L.headFur
            for e in [s.eye] {
                for (i, dx) in ([-3.5, -1.5, 0.8] as [CGFloat]).enumerated() {
                    ctx.setStrokeColor((i == 1 ? L.muzzle ?? bangColor : bangColor).withAlphaComponent(0.85).cgColor)
                    ctx.move(to: CGPoint(x: e.x + dx - 1, y: e.y + 5.5))
                    ctx.addQuadCurve(to: CGPoint(x: e.x + dx + 2.5, y: e.y + 1.2), control: CGPoint(x: e.x + dx + 2, y: e.y + 5))
                    ctx.strokePath()
                }
            }
        }
    }

    // MARK: Shapes

    /// An ellipse with soft bumps all round its edge, for wool.
    static func fluffyPath(_ o: Oval, seed: UInt64, bump: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.addPath(o.path)
        var rng = PropArt.Seeded(state: seed &* 2_654_435_761 &+ 17)
        let a = o.angle * .pi / 180
        let perimeter = CGFloat.pi * (3 * (o.rx + o.ry) - sqrt((3 * o.rx + o.ry) * (o.rx + 3 * o.ry)))
        let n = max(8, Int(perimeter / (bump * 1.35)))
        for i in 0..<n {
            let t = (CGFloat(i) + rng.range(-0.3, 0.3)) / CGFloat(n) * 2 * .pi
            var nx = cos(t) / o.rx, ny = sin(t) / o.ry
            let len = hypot(nx, ny); nx /= len; ny /= len
            let r = bump * rng.range(0.7, 1.15)
            let lx = o.rx * cos(t) + nx * r * 0.2, ly = o.ry * sin(t) + ny * r * 0.2
            let wx = o.c.x + lx * cos(a) - ly * sin(a), wy = o.c.y + lx * sin(a) + ly * cos(a)
            path.addEllipse(in: CGRect(x: wx - r, y: wy - r, width: 2 * r, height: 2 * r))
        }
        return path
    }

    /// A point on the edge of an oval plus its outward direction, in canvas space.
    private static func edge(_ o: Oval, _ t: CGFloat) -> (CGPoint, CGVector) {
        let a = o.angle * .pi / 180
        var nx = cos(t) / o.rx, ny = sin(t) / o.ry
        let len = hypot(nx, ny); nx /= len; ny /= len
        let lx = o.rx * cos(t), ly = o.ry * sin(t)
        return (CGPoint(x: o.c.x + lx * cos(a) - ly * sin(a), y: o.c.y + lx * sin(a) + ly * cos(a)),
                CGVector(dx: nx * cos(a) - ny * sin(a), dy: nx * sin(a) + ny * cos(a)))
    }

    private static func wisps(_ o: Oval, seed: UInt64, count: Int, length: ClosedRange<CGFloat>, colors: [NSColor],
                              upperOnly: Bool, _ ctx: CGContext) {
        var rng = PropArt.Seeded(state: seed &* 7_919 &+ 3)
        for _ in 0..<count {
            let t = rng.range(0, 2 * .pi)
            let (p, n) = edge(o, t)
            let len = rng.range(length.lowerBound, length.upperBound)
            let side = rng.range(-1.8, 1.8)
            if upperOnly && n.dy < -0.2 { continue }
            let start = CGPoint(x: p.x - n.dx * 0.8, y: p.y - n.dy * 0.8)
            let end = CGPoint(x: p.x + n.dx * len - n.dy * side, y: p.y + n.dy * len + n.dx * side)
            let ctrl = CGPoint(x: p.x + n.dx * len * 0.5 + n.dy * side, y: p.y + n.dy * len * 0.5 - n.dx * side)
            ctx.setStrokeColor(colors[Int(rng.next() * CGFloat(colors.count)) % colors.count].cgColor)
            ctx.setLineWidth(rng.range(0.5, 0.85))
            ctx.move(to: start)
            ctx.addQuadCurve(to: end, control: ctrl)
            ctx.strokePath()
        }
    }

    private static func tassels(_ ear: Ear, seed: UInt64, colors: [NSColor], _ ctx: CGContext) {
        var rng = PropArt.Seeded(state: seed &* 104_729 &+ 5)
        let a = ear.angle * .pi / 180
        // A little fringe along the edges, then a soft plume swept back from the tip.
        for i in 0..<6 {
            let f = 0.5 + CGFloat(i) * 0.08
            let along = CGPoint(x: ear.base.x + cos(a) * ear.length * f, y: ear.base.y + sin(a) * ear.length * f)
            let sideSign: CGFloat = i % 2 == 0 ? 1 : -1
            let n = CGVector(dx: -sin(a) * sideSign, dy: cos(a) * sideSign)
            let start = CGPoint(x: along.x + n.dx * ear.width * 0.42, y: along.y + n.dy * ear.width * 0.42)
            let len = rng.range(2, 3.5)
            ctx.setStrokeColor(colors[0].withAlphaComponent(0.9).cgColor)
            ctx.setLineWidth(0.6)
            ctx.move(to: start)
            ctx.addLine(to: CGPoint(x: start.x + n.dx * len + cos(a) * len, y: start.y + n.dy * len + sin(a) * len))
            ctx.strokePath()
        }
        let tip = CGPoint(x: ear.base.x + cos(a) * ear.length * 0.92, y: ear.base.y + sin(a) * ear.length * 0.92)
        for i in 0..<7 {
            let ang = a + 0.25 + rng.range(-0.45, 0.45)
            let len = rng.range(6, 12)
            let bend = rng.range(1, 3.5)
            let end = CGPoint(x: tip.x + cos(ang) * len, y: tip.y + sin(ang) * len)
            ctx.setStrokeColor(colors[i % colors.count].withAlphaComponent(0.85).cgColor)
            ctx.setLineWidth(rng.range(0.8, 1.3))
            ctx.move(to: tip)
            ctx.addQuadCurve(to: end, control: CGPoint(x: (tip.x + end.x) / 2 - sin(ang) * bend,
                                                       y: (tip.y + end.y) / 2 + cos(ang) * bend))
            ctx.strokePath()
        }
    }

    /// Agouti ticking: short dark and light hairs following the body.
    private static func ticks(_ o: Oval, seed: UInt64, count: Int, _ dark: NSColor, _ light: NSColor, _ ctx: CGContext) {
        var rng = PropArt.Seeded(state: seed &* 15_485_863 &+ 9)
        let a = o.angle * .pi / 180
        ctx.setLineWidth(0.7)
        for _ in 0..<count {
            let r = sqrt(rng.next()), th = rng.range(0, 2 * .pi)
            let lx = r * cos(th) * o.rx, ly = r * sin(th) * o.ry
            let p = CGPoint(x: o.c.x + lx * cos(a) - ly * sin(a), y: o.c.y + lx * sin(a) + ly * cos(a))
            let ang = a + rng.range(-0.6, 0.6)
            let len = rng.range(1.2, 2.4)
            ctx.setStrokeColor(rng.next() < 0.6 ? dark.withAlphaComponent(0.32).cgColor : light.withAlphaComponent(0.38).cgColor)
            ctx.move(to: CGPoint(x: p.x - cos(ang) * len / 2, y: p.y - sin(ang) * len / 2))
            ctx.addLine(to: CGPoint(x: p.x + cos(ang) * len / 2, y: p.y + sin(ang) * len / 2))
            ctx.strokePath()
        }
    }

    // MARK: Small helpers

    /// A point offset from `p` in a frame turned by `degrees` (follows the head's tilt).
    private static func rotated(_ p: CGPoint, _ degrees: CGFloat, _ dx: CGFloat, _ dy: CGFloat) -> CGPoint {
        let a = degrees * .pi / 180
        return CGPoint(x: p.x + dx * cos(a) - dy * sin(a), y: p.y + dx * sin(a) + dy * cos(a))
    }

    /// An ear seen from the front: fur, pink inside, dark rim and tip.
    private static func drawEarFront(_ ear: Ear, _ path: CGPath, _ L: BunnyLook, _ ctx: CGContext) {
        fill(path, L.earFur, ctx)
        clipped(path, ctx) {
            ctx.addPath(ear.inner.path)
            ctx.setFillColor(L.innerEar.cgColor)
            ctx.fillPath()
            if let tip = L.earTip { earTip(ear, nil, tip, ctx) }
            if let rim = L.earRim {
                ctx.addPath(path)
                ctx.setStrokeColor(rim.cgColor)
                ctx.setLineWidth(2.4)
                ctx.strokePath()
            }
        }
        strokeInside(path, L.outline.withAlphaComponent(0.55), 1.0, ctx)
    }

    private static func fill(_ p: CGPath, _ color: NSColor, _ ctx: CGContext) {
        ctx.addPath(p)
        ctx.setFillColor(color.cgColor)
        ctx.fillPath()
    }

    private static func clipped(_ p: CGPath, _ ctx: CGContext, _ body: () -> Void) {
        ctx.saveGState()
        ctx.addPath(p)
        ctx.clip()
        body()
        ctx.restoreGState()
    }

    /// A line just inside a shape's edge (to separate it from what's behind).
    private static func strokeInside(_ p: CGPath, _ color: NSColor, _ width: CGFloat, _ ctx: CGContext) {
        clipped(p, ctx) {
            ctx.addPath(p)
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(width * 2)
            ctx.strokePath()
        }
    }

    private static func radial(_ c: CGPoint, _ r: CGFloat, _ color: NSColor, _ alpha: CGFloat, _ ctx: CGContext) {
        let g = CGGradient(colorsSpace: sRGB, colors: [color.withAlphaComponent(alpha).cgColor,
                                                       color.withAlphaComponent(alpha * 0.6).cgColor,
                                                       color.withAlphaComponent(0).cgColor] as CFArray,
                           locations: [0, 0.55, 1])!
        ctx.drawRadialGradient(g, startCenter: c, startRadius: 0, endCenter: c, endRadius: r, options: [])
    }

    private static func earTip(_ ear: Ear, _ clipTo: CGPath?, _ color: NSColor, _ ctx: CGContext) {
        let a = ear.angle * .pi / 180
        let c = CGPoint(x: ear.base.x + cos(a) * ear.length, y: ear.base.y + sin(a) * ear.length)
        let draw = { radial(c, ear.width * 1.1, color, 0.95, ctx) }
        if let clipTo { clipped(clipTo, ctx, draw) } else { draw() }
    }

    /// Lighter toes at the front end of a paw or foot.
    private static func tipOf(_ o: Oval, _ shape: CGPath, _ color: NSColor, _ ctx: CGContext) {
        let a = o.angle * .pi / 180
        let c = CGPoint(x: o.c.x + cos(a) * o.rx * 0.75, y: o.c.y + sin(a) * o.rx * 0.75)
        clipped(shape, ctx) { radial(c, max(o.rx * 0.55, 3.5), color, 1, ctx) }
    }

    private static func drawEye(at p: CGPoint, open: CGFloat, _ L: BunnyLook, _ ctx: CGContext) {
        let r: CGFloat = 3.1
        if open <= 0.05 {
            ctx.setStrokeColor(L.eye.cgColor)
            ctx.setLineWidth(1.1)
            ctx.addArc(center: CGPoint(x: p.x, y: p.y + 1.2), radius: r * 0.9,
                       startAngle: .pi * 1.15, endAngle: .pi * 1.85, clockwise: false)
            ctx.strokePath()
            return
        }
        ctx.saveGState()
        if open < 1 {
            ctx.clip(to: CGRect(x: p.x - r - 1, y: p.y - r - 1, width: r * 2 + 2, height: (r * 2) * open + 1))
        }
        if let iris = L.iris {
            ctx.setFillColor(iris.cgColor)
            ctx.fillEllipse(in: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2))
            ctx.setFillColor(L.eye.cgColor)
            ctx.fillEllipse(in: CGRect(x: p.x - r * 0.58, y: p.y - r * 0.58, width: r * 1.16, height: r * 1.16))
        } else {
            ctx.setFillColor(L.eye.cgColor)
            ctx.fillEllipse(in: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2))
        }
        ctx.setFillColor(NSColor.white.withAlphaComponent(0.9).cgColor)
        ctx.fillEllipse(in: CGRect(x: p.x + 0.2, y: p.y + 0.6, width: 1.5, height: 1.5))
        ctx.restoreGState()
        if open < 1 {
            ctx.setStrokeColor(L.outline.withAlphaComponent(0.7).cgColor)
            ctx.setLineWidth(0.8)
            let lidY = p.y - r + (r * 2) * open
            ctx.move(to: CGPoint(x: p.x - r, y: lidY))
            ctx.addLine(to: CGPoint(x: p.x + r, y: lidY))
            ctx.strokePath()
        }
    }
}

/// Caches one SpriteKit texture per (bunny, pose).
@MainActor
final class BunnyTextures {
    private var cache: [Pose: SKTexture] = [:]
    let look: BunnyLook

    init(look: BunnyLook) { self.look = look }

    func texture(_ pose: Pose) -> SKTexture {
        if let t = cache[pose] { return t }
        let t: SKTexture
        if let img = BunnyArtist.image(look, pose) {
            t = SKTexture(cgImage: img)
        } else {
            t = SKTexture()
        }
        t.filteringMode = .linear
        cache[pose] = t
        return t
    }
}

/// `--render-art <folder>`: writes every pose as PNG plus a contact sheet.
enum ArtRenderer {
    static func renderAll(to dir: URL) {
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let looks = [BunnyLook.snoopy, BunnyLook.bambi]
        let poses = Pose.allCases
        let cellW = Int(BunnyArtist.canvas.width * BunnyArtist.pixelScale)
        let cellH = Int(BunnyArtist.canvas.height * BunnyArtist.pixelScale)
        let cols = 5
        let rowsPerLook = (poses.count + cols - 1) / cols
        let sheetW = cols * cellW
        let sheetH = rowsPerLook * looks.count * cellH
        guard let sheet = CGContext(data: nil, width: sheetW, height: sheetH, bitsPerComponent: 8, bytesPerRow: 0,
                                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
        sheet.setFillColor(NSColor(hex: 0x8A9AA8).cgColor)
        sheet.fill(CGRect(x: 0, y: 0, width: sheetW, height: sheetH))
        NSGraphicsContext.current = NSGraphicsContext(cgContext: sheet, flipped: false)

        for (li, look) in looks.enumerated() {
            for (pi, pose) in poses.enumerated() {
                guard let img = BunnyArtist.image(look, pose) else { continue }
                PNG.write(img, to: dir.appendingPathComponent("\(look.name)-\(pose.rawValue).png"))
                let row = li * rowsPerLook + pi / cols
                let x = (pi % cols) * cellW
                let y = sheetH - (row + 1) * cellH
                sheet.draw(img, in: CGRect(x: x, y: y, width: cellW, height: cellH))
                let label = "\(look.name): \(pose.rawValue)" as NSString
                label.draw(at: CGPoint(x: x + 8, y: y + cellH - 26),
                           withAttributes: [.font: NSFont.boldSystemFont(ofSize: 16), .foregroundColor: NSColor.white])
            }
        }
        NSGraphicsContext.current = nil
        if let img = sheet.makeImage() {
            PNG.write(img, to: dir.appendingPathComponent("contact-sheet.png"))
        }
        print("Wrote \(looks.count * poses.count) poses to \(dir.path)")
    }
}
