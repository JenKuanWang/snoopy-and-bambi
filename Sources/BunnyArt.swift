import AppKit
import ImageIO
import SpriteKit

// Bunny artwork painted from real photos of Snoopy (sable-point English Angora)
// and Bambi (dark chestnut/wild-type agouti) in a warm storybook gouache style.
// Each pose defines an anatomical rig; each BunnyLook defines the coat, markings,
// eye character, ear posture, and fur/wool rendering unique to Snoopy or Bambi.

struct BunnyLook {
    var name: String
    var fur: NSColor              // primary coat
    var furShade: NSColor         // far ear, deeper coat shadows
    var furLight: NSColor         // sunlit wool/coat highlight
    var flankShade: NSColor? = nil // warm toasted-taupe lower flank shading (Snoopy) or fawn flank (Bambi)
    var headFur: NSColor
    /// Velvety taupe-gray face/crown/snout mask (Snoopy's sable-point markings).
    var faceTint: NSColor? = nil
    var crownTint: NSColor? = nil
    var earFur: NSColor
    var outline: NSColor
    var innerEar: NSColor
    var innerEarDeep: NSColor
    var eye: NSColor              // pupil / dark of the eye
    var iris: NSColor? = nil      // deep garnet-ruby (Snoopy) or dark chestnut (Bambi)
    var irisGlow: NSColor? = nil  // luminous lower-iris light reflection
    var eyeRing: NSColor? = nil   // pale cream eye ring (Bambi) or delicate soft peach rim (Snoopy)
    var eyeRingAlpha: CGFloat = 0.85
    var nose: NSColor
    var muzzle: NSColor? = nil    // dark smoky snout tip (Snoopy) or pale nostril halo (Bambi)
    var chin: NSColor? = nil      // snowy chin / mouth
    var cheek: NSColor? = nil     // cheek warmth (Bambi) or pale fluffy cheek-puff highlight (Snoopy)
    var nape: NSColor? = nil      // warm cinnamon nape triangle behind the ears
    var belly: NSColor? = nil
    var paw: NSColor
    var pawTip: NSColor? = nil
    var tail: NSColor
    var tailTop: NSColor? = nil
    var earRim: NSColor? = nil
    var earTip: NSColor? = nil
    /// Three-band agouti ticking (dark guard tips, warm mid-hairs, pale buff under-ticks).
    var ticking: (dark: NSColor, mid: NSColor, light: NSColor)? = nil
    var backShade: CGFloat = 0    // darker dorsal saddle along the back (agouti)
    var highlight: CGFloat = 0.22 // soft sunlight from above
    /// 0 = sleek coat, 1 = plush English Angora wool (cheek mutton-chops, shaggy fleece, draping ear tassels).
    var fluff: CGFloat = 0
    var wisp: NSColor? = nil
    var tassel: NSColor? = nil
    var earScale: CGFloat = 1
    /// Subtle ear angle relaxation (Snoopy's softer V-spread Angora ears vs Bambi's crisp upright ears).
    var earRelax: CGFloat = 0
    /// Overall size on screen.
    var scale: CGFloat = 1
    /// Shows a name tag all the time (used for placeholder art).
    var isStandIn = false

    /// Real Snoopy (English Angora): warm ivory-cream fleece wool with toasted oatmeal-taupe
    /// lower flanks, broad fluffy cheek puffs ("mutton chops"), velvety warm mushroom-taupe
    /// forehead & snout mask, wider soft ears with smoky dark tips & sweeping silky tassels,
    /// warm mahogany-ruby eyes with soft blush rim, and a smoky taupe-capped fluffy wool tail.
    static let snoopy = BunnyLook(
        name: "Snoopy",
        fur: NSColor(hex: 0xF5EFE6),
        furShade: NSColor(hex: 0xBEB0A1),
        furLight: NSColor(hex: 0xFFFDF8),
        flankShade: NSColor(hex: 0xD8C9B7),
        headFur: NSColor(hex: 0xECE3D8),
        faceTint: NSColor(hex: 0x9E8E7F),
        crownTint: NSColor(hex: 0xAA9A8B),
        earFur: NSColor(hex: 0xA49588),
        outline: NSColor(hex: 0x87796E),
        innerEar: NSColor(hex: 0xE2C1BC),
        innerEarDeep: NSColor(hex: 0xBF9994),
        eye: NSColor(hex: 0x220B0A),
        iris: NSColor(hex: 0x7A2B24),
        irisGlow: NSColor(hex: 0xC45A48),
        eyeRing: NSColor(hex: 0xE8BDB5),
        eyeRingAlpha: 0.65,
        nose: NSColor(hex: 0xAC8C86),
        muzzle: NSColor(hex: 0x7E7065),
        chin: NSColor(hex: 0xF0E8DD),
        cheek: NSColor(hex: 0xF7F1E7),
        belly: NSColor(hex: 0xFAF6F0),
        paw: NSColor(hex: 0xEAE0D4),
        pawTip: NSColor(hex: 0xD4C6B7),
        tail: NSColor(hex: 0xF9F4EC),
        tailTop: NSColor(hex: 0x8F8073),
        earRim: nil,
        earTip: NSColor(hex: 0x524740),
        highlight: 0.24,
        fluff: 1,
        wisp: NSColor(hex: 0xFCF9F3),
        tassel: NSColor(hex: 0xDDD0C2),
        earScale: 0.90,
        earRelax: 11,
        scale: 1.09)

    /// Real Bambi (Dark Chestnut / Wild Agouti): dense charcoal-ticked brown-gray coat,
    /// deeper dark dorsal saddle, subtle tawny-cinnamon nape, crisp snowy-cream nostril halo
    /// & white chin, pale almond eye ring around dark obsidian eyes, tall sleek ears with
    /// bold dark charcoal-black lacing, crisp snowy-white toe tips, and dark-topped / white-bottomed tail.
    static let bambi = BunnyLook(
        name: "Bambi",
        fur: NSColor(hex: 0x645648),
        furShade: NSColor(hex: 0x3D332B),
        furLight: NSColor(hex: 0xB89D78),
        flankShade: NSColor(hex: 0x9C7F5C),
        headFur: NSColor(hex: 0x625447),
        earFur: NSColor(hex: 0x594C40),
        outline: NSColor(hex: 0x261F1A),
        innerEar: NSColor(hex: 0xB9A39C),
        innerEarDeep: NSColor(hex: 0x8C7872),
        eye: NSColor(hex: 0x110C09),
        iris: NSColor(hex: 0x301E14),
        irisGlow: NSColor(hex: 0x7A4F34),
        eyeRing: NSColor(hex: 0xE2D6BE),
        eyeRingAlpha: 0.86,
        nose: NSColor(hex: 0x52453E),
        muzzle: NSColor(hex: 0xEFE8DA),
        chin: NSColor(hex: 0xF7F3EA),
        cheek: NSColor(hex: 0x7E674E),
        nape: NSColor(hex: 0x9B7650),
        belly: NSColor(hex: 0xEFE9DC),
        paw: NSColor(hex: 0x6E5D4C),
        pawTip: NSColor(hex: 0xF7F3EA),
        tail: NSColor(hex: 0xF8F5EE),
        tailTop: NSColor(hex: 0x251F1A),
        earRim: NSColor(hex: 0x1C1713),
        earTip: NSColor(hex: 0x181310),
        ticking: (dark: NSColor(hex: 0x1E1814), mid: NSColor(hex: 0x846B4E), light: NSColor(hex: 0xC8B392)),
        backShade: 0.42,
        highlight: 0.12,
        earScale: 1.07,
        earRelax: 0,
        scale: 1.00)

    static func standIn(named name: String) -> BunnyLook {
        BunnyLook(name: name,
                  fur: NSColor(hex: 0xD9D3CB), furShade: NSColor(hex: 0xB8AFA4), furLight: NSColor(hex: 0xEFECE7),
                  headFur: NSColor(hex: 0xD9D3CB), earFur: NSColor(hex: 0xD9D3CB), outline: NSColor(hex: 0x6B625A),
                  innerEar: NSColor(hex: 0xE8BDB8), innerEarDeep: NSColor(hex: 0xC89690),
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

    /// The closest pose to use if a realistic sprite for this one is missing.
    var nearest: Pose? {
        switch self {
        case .sit: return nil
        case .sitNose, .sitEarTwitch, .thump, .periscope, .groom, .loaf, .crouch: return .sit
        case .land: return .crouch
        case .hop: return .land
        case .sleep: return .loaf
        case .flop: return .sleep
        case .eat: return .loaf
        case .eatChew: return .eat
        case .groomB: return .groom
        }
    }
}

/// Which artwork the bunnies wear: drawn in code (BunnyArtist), or the
/// realistic painted sprites in Resources/Sprites (made with Gemini).
enum ArtStyle: String, CaseIterable {
    case drawn, realistic

    var menuTitle: String { self == .drawn ? "Drawn" : "Realistic" }

    /// Realistic if asked for and the sprites are there; drawn otherwise.
    static func resolve(_ name: String?) -> ArtStyle {
        let wanted = name.flatMap(ArtStyle.init(rawValue:)) ?? .realistic
        return wanted == .realistic && BunnyArtist.hasRealisticSprites ? .realistic : .drawn
    }
}

// MARK: - Anatomical Geometry

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
    var bend: CGFloat = 1.6

    init(_ x: CGFloat, _ y: CGFloat, angle: CGFloat, length: CGFloat = 26, width: CGFloat = 9.2, bend: CGFloat = 1.6) {
        base = CGPoint(x: x, y: y); self.angle = angle; self.length = length; self.width = width; self.bend = bend
    }

    func point(along t: CGFloat, offset: CGFloat = 0) -> CGPoint {
        let a = angle * .pi / 180
        let ux = cos(a), uy = sin(a)
        let nx = -uy, ny = ux
        let curve = bend * t * t
        let along = length * t
        return CGPoint(x: base.x + ux * along + nx * (curve + offset),
                       y: base.y + uy * along + ny * (curve + offset))
    }

    func outerPath(fluffBoost: CGFloat = 0) -> CGPath {
        let hw = (width + fluffBoost) * 0.5
        let p = CGMutablePath()
        let rootL = point(along: -0.05, offset: hw * 0.45)
        let rootR = point(along: -0.05, offset: -hw * 0.45)
        let tip = point(along: 1.0, offset: 0)
        p.move(to: rootL)
        p.addCurve(to: tip,
                   control1: point(along: 0.36, offset: hw * 1.15),
                   control2: point(along: 0.84, offset: hw * 0.90))
        p.addCurve(to: rootR,
                   control1: point(along: 0.84, offset: -hw * 0.86),
                   control2: point(along: 0.36, offset: -hw * 1.08))
        p.closeSubpath()
        return p
    }

    var innerPath: CGPath {
        let hw = width * 0.27
        let p = CGMutablePath()
        let start = point(along: 0.14, offset: 0)
        let tip = point(along: 0.84, offset: -width * 0.02)
        p.move(to: start)
        p.addCurve(to: tip,
                   control1: point(along: 0.36, offset: hw * 1.05),
                   control2: point(along: 0.72, offset: hw * 0.85))
        p.addCurve(to: start,
                   control1: point(along: 0.72, offset: -hw * 0.72),
                   control2: point(along: 0.36, offset: -hw * 0.85))
        p.closeSubpath()
        return p
    }
}

struct PawShape {
    var heel: CGPoint
    var toe: CGPoint
    var joint: CGPoint? = nil
    var thickness: CGFloat
    var isHind: Bool = false

    var center: CGPoint { CGPoint(x: (heel.x + toe.x) * 0.5, y: (heel.y + toe.y) * 0.5) }
    var length: CGFloat { hypot(toe.x - heel.x, toe.y - heel.y) }
    var tipAngle: CGFloat {
        let origin = joint ?? heel
        return atan2(toe.y - origin.y, toe.x - origin.x)
    }

    func path(fluff: CGFloat = 0) -> CGPath {
        let t = thickness + fluff * (isHind ? 1.1 : 1.05)
        if let j = joint {
            let p = CGMutablePath()
            let d1x = j.x - heel.x, d1y = j.y - heel.y
            let l1 = max(hypot(d1x, d1y), 0.1)
            let u1x = d1x / l1, u1y = d1y / l1
            let n1x = -u1y, n1y = u1x

            let d2x = toe.x - j.x, d2y = toe.y - j.y
            let l2 = max(hypot(d2x, d2y), 0.1)
            let u2x = d2x / l2, u2y = d2y / l2
            let n2x = -u2y, n2y = u2x

            let w0 = t * 1.08
            let w1 = t * 0.85
            let w2 = t * 0.94
            let front = CGPoint(x: toe.x + u2x * w2 * 0.65, y: toe.y + u2y * w2 * 0.65)
            let topMid = CGPoint(x: (j.x + toe.x) * 0.5 + n2x * w2 * 0.95, y: (j.y + toe.y) * 0.5 + n2y * w2 * 0.95)
            let botMid = CGPoint(x: (j.x + toe.x) * 0.5 - n2x * w2 * 0.62, y: (j.y + toe.y) * 0.5 - n2y * w2 * 0.62)

            p.move(to: CGPoint(x: heel.x + n1x * w0, y: heel.y + n1y * w0))
            p.addQuadCurve(to: CGPoint(x: j.x + n2x * w1, y: j.y + n2y * w1),
                           control: CGPoint(x: j.x + n1x * w1 * 0.95, y: j.y + n1y * w1 * 0.95))
            p.addQuadCurve(to: front, control: topMid)
            p.addQuadCurve(to: CGPoint(x: j.x - n2x * w1 * 0.72, y: j.y - n2y * w1 * 0.72), control: botMid)
            p.addQuadCurve(to: CGPoint(x: heel.x - n1x * w0 * 0.9, y: heel.y - n1y * w0 * 0.9),
                           control: CGPoint(x: j.x - n1x * w1 * 0.85, y: j.y - n1y * w1 * 0.85))
            p.closeSubpath()
            return p
        }

        let dx = toe.x - heel.x, dy = toe.y - heel.y
        let len = max(hypot(dx, dy), 0.1)
        let ux = dx / len, uy = dy / len
        let nx = -uy, ny = ux
        let p = CGMutablePath()
        let back = CGPoint(x: heel.x - ux * t * 0.45, y: heel.y - uy * t * 0.45)
        let front = CGPoint(x: toe.x + ux * t * 0.58, y: toe.y + uy * t * 0.58)
        let topMid = CGPoint(x: heel.x + dx * 0.56 + nx * t * (isHind ? 0.92 : 1.05),
                             y: heel.y + dy * 0.56 + ny * t * (isHind ? 0.92 : 1.05))
        let botMid = CGPoint(x: heel.x + dx * 0.48 - nx * t * 0.52,
                             y: heel.y + dy * 0.48 - ny * t * 0.52)
        p.move(to: back)
        p.addCurve(to: front,
                   control1: CGPoint(x: heel.x + dx * 0.25 + nx * t * 0.85, y: heel.y + dy * 0.25 + ny * t * 0.85),
                   control2: CGPoint(x: topMid.x + ux * len * 0.32, y: topMid.y + uy * len * 0.32))
        p.addCurve(to: back,
                   control1: CGPoint(x: toe.x - ux * len * 0.12 - nx * t * 0.55, y: toe.y - uy * len * 0.12 - ny * t * 0.55),
                   control2: CGPoint(x: botMid.x - ux * len * 0.28, y: botMid.y - uy * len * 0.28))
        p.closeSubpath()
        return p
    }
}

/// Sculpted anatomical rig for one pose on a 100×96 grid (facing right, ground y = 8).
struct BunnyRig {
    var bodyOutline: [CGPoint]
    var bodyFrame: Oval
    var haunch: Oval?
    var head: Oval
    var snoutLength: CGFloat = 1.0
    var backEar: Ear
    var frontEar: Ear
    var eye: CGPoint
    var eyeOpen: CGFloat
    var nose: CGPoint
    var tail: Oval
    var backHindFoot: PawShape? = nil
    var hindFoot: PawShape? = nil
    var backFrontPaw: PawShape? = nil
    var frontPaws: [PawShape] = []
    var bellyOval: Oval? = nil
    var isFlop: Bool = false
    var isUpright: Bool = false
    var chewLift: CGFloat = 0
    var noseTwitch: CGFloat = 0

    static func forPose(_ pose: Pose) -> BunnyRig {
        switch pose {
        case .sit, .sitNose, .sitEarTwitch, .thump:
            var r = BunnyRig(
                bodyOutline: [
                    CGPoint(x: 22, y: 24),
                    CGPoint(x: 24.5, y: 36),
                    CGPoint(x: 36.5, y: 44.5),
                    CGPoint(x: 52.5, y: 43),
                    CGPoint(x: 64, y: 34.5),
                    CGPoint(x: 66.5, y: 21),
                    CGPoint(x: 57, y: 12),
                    CGPoint(x: 42, y: 11),
                    CGPoint(x: 27, y: 14.5),
                ],
                bodyFrame: Oval(45, 27, 23, 16.5, 10),
                haunch: Oval(35.5, 24.5, 15.5, 14.5, 5),
                head: Oval(66.5, 40.5, 13.6, 11.6, -6),
                backEar: Ear(60.5, 48.5, angle: 108, length: 25.5, width: 8.6, bend: -2.0),
                frontEar: Ear(64, 49.5, angle: 95, length: 26, width: 9.4, bend: 1.8),
                eye: CGPoint(x: 71.2, y: 42.7),
                eyeOpen: 1,
                nose: CGPoint(x: 80.3, y: 38.0),
                tail: Oval(20.5, 23.5, 6.2, 6.4, 18),
                hindFoot: PawShape(heel: CGPoint(x: 31, y: 10.6), toe: CGPoint(x: 51, y: 10.5), thickness: 3.2, isHind: true),
                backFrontPaw: PawShape(heel: CGPoint(x: 63.5, y: 21), toe: CGPoint(x: 70, y: 10.4),
                                       joint: CGPoint(x: 64.5, y: 10.8), thickness: 2.7),
                frontPaws: [PawShape(heel: CGPoint(x: 59.5, y: 22), toe: CGPoint(x: 66.5, y: 10.3),
                                     joint: CGPoint(x: 60.5, y: 10.7), thickness: 3.0)],
                bellyOval: Oval(49, 14.5, 16, 5.2, 6)
            )
            if pose == .sitNose {
                r.nose.y += 0.9
                r.noseTwitch = 1.0
            }
            if pose == .sitEarTwitch {
                r.frontEar.angle = 78
                r.frontEar.bend = 3.2
            }
            if pose == .thump {
                r.hindFoot = PawShape(heel: CGPoint(x: 30, y: 12.5), toe: CGPoint(x: 49, y: 17.8), thickness: 3.3, isHind: true)
                r.backEar.angle = 98
                r.frontEar.angle = 85
                r.frontEar.bend = 2.6
            }
            return r

        case .loaf, .sleep:
            var r = BunnyRig(
                bodyOutline: [
                    CGPoint(x: 20, y: 19),
                    CGPoint(x: 23, y: 31),
                    CGPoint(x: 36, y: 37.5),
                    CGPoint(x: 53, y: 36.8),
                    CGPoint(x: 68, y: 29.5),
                    CGPoint(x: 72, y: 17),
                    CGPoint(x: 63, y: 9.8),
                    CGPoint(x: 45, y: 9.4),
                    CGPoint(x: 28, y: 10.5),
                ],
                bodyFrame: Oval(46, 23, 26, 14, 2),
                haunch: Oval(35, 21.5, 15.5, 12.5, 2),
                head: Oval(68.5, 27.6, 13.4, 11.2, -5),
                backEar: Ear(60.5, 34, angle: 162, length: 24.5, width: 8.4, bend: -1.8),
                frontEar: Ear(63.5, 35.5, angle: 155, length: 25, width: 9.0, bend: -2.2),
                eye: CGPoint(x: 73.2, y: 29.5),
                eyeOpen: 0.62,
                nose: CGPoint(x: 81.9, y: 25.3),
                tail: Oval(19, 19.5, 5.6, 5.6, 15),
                hindFoot: nil,
                frontPaws: [PawShape(heel: CGPoint(x: 64, y: 10.5), toe: CGPoint(x: 69.5, y: 10.1), thickness: 2.3)],
                bellyOval: Oval(48, 11.2, 18, 3.4, 0)
            )
            if pose == .sleep {
                r.eyeOpen = 0
                r.head.c.y -= 1.2
                r.eye.y -= 1.2
                r.nose.y -= 1.3
                r.backEar.angle = 170; r.backEar.base.y -= 1.2
                r.frontEar.angle = 165; r.frontEar.base.y -= 1.2
            }
            return r

        case .crouch:
            return BunnyRig(
                bodyOutline: [
                    CGPoint(x: 20, y: 20),
                    CGPoint(x: 23, y: 31),
                    CGPoint(x: 37, y: 37),
                    CGPoint(x: 54, y: 35.5),
                    CGPoint(x: 67, y: 28),
                    CGPoint(x: 69, y: 16),
                    CGPoint(x: 58, y: 10.5),
                    CGPoint(x: 41, y: 10.2),
                    CGPoint(x: 26, y: 12),
                ],
                bodyFrame: Oval(45, 23, 25, 13.5, 4),
                haunch: Oval(34, 22, 15.5, 12.5, 6),
                head: Oval(69.5, 27, 13.4, 11.2, -7),
                backEar: Ear(62, 34, angle: 140, length: 25, width: 8.5, bend: -1.8),
                frontEar: Ear(65, 35, angle: 132, length: 25.5, width: 9.2, bend: -1.2),
                eye: CGPoint(x: 74.2, y: 29.0),
                eyeOpen: 1,
                nose: CGPoint(x: 82.9, y: 24.4),
                tail: Oval(18.5, 22, 5.8, 6.0, 22),
                hindFoot: PawShape(heel: CGPoint(x: 28, y: 10.4), toe: CGPoint(x: 48, y: 10.2), thickness: 3.1, isHind: true),
                frontPaws: [PawShape(heel: CGPoint(x: 60.5, y: 15), toe: CGPoint(x: 68.5, y: 10.2),
                                     joint: CGPoint(x: 62.5, y: 10.6), thickness: 2.8)],
                bellyOval: Oval(48, 12.5, 17, 4.0, 2)
            )

        case .hop:
            return BunnyRig(
                bodyOutline: [
                    CGPoint(x: 21, y: 25),
                    CGPoint(x: 24, y: 36),
                    CGPoint(x: 40, y: 44),
                    CGPoint(x: 58, y: 45),
                    CGPoint(x: 72, y: 39),
                    CGPoint(x: 69, y: 27),
                    CGPoint(x: 52, y: 23),
                    CGPoint(x: 34, y: 20),
                ],
                bodyFrame: Oval(47, 33, 27, 12.5, 13),
                haunch: Oval(31, 28, 13.5, 11.0, 18),
                head: Oval(75.5, 43, 13.0, 11.0, 6),
                backEar: Ear(68, 49.5, angle: 156, length: 25, width: 8.4, bend: -2.4),
                frontEar: Ear(71, 50.5, angle: 147, length: 25.5, width: 9.0, bend: -2.0),
                eye: CGPoint(x: 80.2, y: 45.6),
                eyeOpen: 1,
                nose: CGPoint(x: 88.7, y: 43.2),
                tail: Oval(18.5, 34, 5.8, 6.0, 28),
                backHindFoot: PawShape(heel: CGPoint(x: 26, y: 25), toe: CGPoint(x: 11, y: 19), thickness: 2.8, isHind: true),
                hindFoot: PawShape(heel: CGPoint(x: 28, y: 23), toe: CGPoint(x: 10.5, y: 15.5), thickness: 3.1, isHind: true),
                backFrontPaw: PawShape(heel: CGPoint(x: 68, y: 31), toe: CGPoint(x: 80, y: 24.5), thickness: 2.6),
                frontPaws: [PawShape(heel: CGPoint(x: 66, y: 29.5), toe: CGPoint(x: 77.5, y: 21.5), thickness: 2.9)],
                bellyOval: Oval(51, 24.5, 17, 4.2, 12)
            )

        case .land:
            return BunnyRig(
                bodyOutline: [
                    CGPoint(x: 23, y: 29),
                    CGPoint(x: 29, y: 39.5),
                    CGPoint(x: 46, y: 41.5),
                    CGPoint(x: 63, y: 35.5),
                    CGPoint(x: 71, y: 23.5),
                    CGPoint(x: 63, y: 14.5),
                    CGPoint(x: 46, y: 15.5),
                    CGPoint(x: 30, y: 20),
                ],
                bodyFrame: Oval(48, 27, 25, 13.5, -10),
                haunch: Oval(34, 29, 13.5, 12.0, -8),
                head: Oval(72, 29.5, 13.2, 11.2, -14),
                backEar: Ear(65.5, 37, angle: 144, length: 25, width: 8.5, bend: -1.8),
                frontEar: Ear(68, 38, angle: 135, length: 25.5, width: 9.0, bend: -1.4),
                eye: CGPoint(x: 76.2, y: 32.0),
                eyeOpen: 1,
                nose: CGPoint(x: 84.5, y: 26.2),
                tail: Oval(21, 34, 5.8, 6.0, -10),
                hindFoot: PawShape(heel: CGPoint(x: 26, y: 21), toe: CGPoint(x: 41, y: 12.5), thickness: 3.1, isHind: true),
                backFrontPaw: PawShape(heel: CGPoint(x: 67, y: 19), toe: CGPoint(x: 75, y: 10.3),
                                       joint: CGPoint(x: 69.5, y: 10.7), thickness: 2.6),
                frontPaws: [PawShape(heel: CGPoint(x: 64, y: 18.5), toe: CGPoint(x: 72, y: 10.2),
                                     joint: CGPoint(x: 66.5, y: 10.6), thickness: 2.9)],
                bellyOval: Oval(49, 17, 16, 4.2, -10)
            )

        case .flop:
            return BunnyRig(
                bodyOutline: [
                    CGPoint(x: 19, y: 17),
                    CGPoint(x: 24, y: 26.5),
                    CGPoint(x: 43, y: 29.5),
                    CGPoint(x: 63, y: 28),
                    CGPoint(x: 74, y: 21),
                    CGPoint(x: 70, y: 10.8),
                    CGPoint(x: 50, y: 9.2),
                    CGPoint(x: 29, y: 10.2),
                ],
                bodyFrame: Oval(47, 19, 28, 10.8, 0),
                haunch: Oval(31, 18.5, 13.5, 9.5, 0),
                head: Oval(75.5, 18.5, 13.0, 10.4, -10),
                backEar: Ear(67.5, 22.5, angle: 176, length: 24, width: 8.2, bend: -2.0),
                frontEar: Ear(69.5, 24.0, angle: 169, length: 24.5, width: 8.8, bend: -2.6),
                eye: CGPoint(x: 79.8, y: 20.0),
                eyeOpen: 0,
                nose: CGPoint(x: 88.3, y: 15.2),
                tail: Oval(17, 20.5, 5.5, 5.5, 10),
                backHindFoot: PawShape(heel: CGPoint(x: 23, y: 15.5), toe: CGPoint(x: 8.5, y: 13.5), thickness: 2.8, isHind: true),
                hindFoot: PawShape(heel: CGPoint(x: 25, y: 12.2), toe: CGPoint(x: 9.5, y: 10.4), thickness: 3.0, isHind: true),
                backFrontPaw: PawShape(heel: CGPoint(x: 75, y: 11.5), toe: CGPoint(x: 84.5, y: 10.8), thickness: 2.5),
                frontPaws: [PawShape(heel: CGPoint(x: 72, y: 10.8), toe: CGPoint(x: 82, y: 9.8), thickness: 2.7)],
                bellyOval: Oval(49, 13.8, 22, 6.5, -2),
                isFlop: true
            )

        case .eat, .eatChew:
            var r = BunnyRig(
                bodyOutline: [
                    CGPoint(x: 20, y: 23),
                    CGPoint(x: 22, y: 35.5),
                    CGPoint(x: 36, y: 42.5),
                    CGPoint(x: 53, y: 39.5),
                    CGPoint(x: 66, y: 30),
                    CGPoint(x: 68, y: 17),
                    CGPoint(x: 57, y: 11.2),
                    CGPoint(x: 40, y: 10.8),
                    CGPoint(x: 26, y: 13.5),
                ],
                bodyFrame: Oval(44, 26, 24.5, 15.5, 2),
                haunch: Oval(33.5, 24.5, 15.5, 14.0, 4),
                head: Oval(70.5, 22.5, 13.4, 11.2, -28),
                backEar: Ear(63.5, 32, angle: 116, length: 25, width: 8.6, bend: -1.6),
                frontEar: Ear(66.5, 33, angle: 106, length: 25.5, width: 9.2, bend: 1.6),
                eye: CGPoint(x: 73.6, y: 26.7),
                eyeOpen: 1,
                nose: CGPoint(x: 81.3, y: 15.2),
                tail: Oval(18.5, 24, 6.0, 6.2, 18),
                hindFoot: PawShape(heel: CGPoint(x: 29, y: 10.6), toe: CGPoint(x: 49, y: 10.4), thickness: 3.2, isHind: true),
                frontPaws: [PawShape(heel: CGPoint(x: 55, y: 18), toe: CGPoint(x: 62.5, y: 10.3),
                                     joint: CGPoint(x: 56.5, y: 10.6), thickness: 2.9)],
                bellyOval: Oval(46, 13.5, 16, 4.5, 2)
            )
            if pose == .eatChew {
                r.head.c.y += 0.9
                r.eye.y += 0.8
                r.nose.y += 1.2
                r.chewLift = 1.0
            }
            return r

        case .groom, .groomB:
            var r = BunnyRig(
                bodyOutline: [
                    CGPoint(x: 22, y: 19),
                    CGPoint(x: 23.5, y: 33),
                    CGPoint(x: 32, y: 46),
                    CGPoint(x: 44.5, y: 52),
                    CGPoint(x: 55.5, y: 44),
                    CGPoint(x: 58.5, y: 27),
                    CGPoint(x: 51, y: 12.5),
                    CGPoint(x: 37, y: 11),
                    CGPoint(x: 26.5, y: 13),
                ],
                bodyFrame: Oval(41, 31, 19.5, 20.5, 22),
                haunch: Oval(33.5, 22.5, 14.5, 13.5, 10),
                head: Oval(55.5, 50.5, 13.0, 11.2, -10),
                backEar: Ear(48, 58, angle: 132, length: 24, width: 8.4, bend: -2.0),
                frontEar: Ear(51.5, 59, angle: 122, length: 24.5, width: 9.0, bend: -1.2),
                eye: CGPoint(x: 60.0, y: 52.5),
                eyeOpen: 0.58,
                nose: CGPoint(x: 68.4, y: 47.2),
                tail: Oval(19.5, 19.5, 5.6, 5.8, 12),
                hindFoot: PawShape(heel: CGPoint(x: 28, y: 10.6), toe: CGPoint(x: 49.5, y: 10.4), thickness: 3.2, isHind: true),
                backFrontPaw: PawShape(heel: CGPoint(x: 55, y: 34.5), toe: CGPoint(x: 70.0, y: 43.2),
                                       joint: CGPoint(x: 63.0, y: 37.5), thickness: 2.7),
                frontPaws: [PawShape(heel: CGPoint(x: 51.5, y: 33.5), toe: CGPoint(x: 68.0, y: 41.2),
                                     joint: CGPoint(x: 60.5, y: 35.8), thickness: 2.9)],
                bellyOval: Oval(49, 25, 9.5, 12.5, -14),
                isUpright: true
            )
            if pose == .groomB {
                r.backFrontPaw = PawShape(heel: CGPoint(x: 54.5, y: 37), toe: CGPoint(x: 68.0, y: 50.4),
                                          joint: CGPoint(x: 63.5, y: 42.5), thickness: 2.7)
                r.frontPaws = [PawShape(heel: CGPoint(x: 51.0, y: 36), toe: CGPoint(x: 65.8, y: 48.8),
                                        joint: CGPoint(x: 61.2, y: 41.2), thickness: 2.9)]
                r.eyeOpen = 0
                r.head.angle = -15
                r.nose.y -= 1.0
                r.frontEar.angle = 112
            }
            return r

        case .periscope:
            return BunnyRig(
                bodyOutline: [
                    CGPoint(x: 25.5, y: 16.5),
                    CGPoint(x: 24.5, y: 29.5),
                    CGPoint(x: 30, y: 44.5),
                    CGPoint(x: 38.5, y: 54.5),
                    CGPoint(x: 50.5, y: 51.5),
                    CGPoint(x: 55, y: 36),
                    CGPoint(x: 52, y: 18.5),
                    CGPoint(x: 42, y: 11),
                    CGPoint(x: 31, y: 11.5),
                ],
                bodyFrame: Oval(40, 32, 22, 14.5, 82),
                haunch: Oval(35, 21.5, 13.8, 12.2, 20),
                head: Oval(47, 57.5, 12.6, 10.8, 4),
                backEar: Ear(41, 64.5, angle: 105, length: 23, width: 8.2, bend: -1.8),
                frontEar: Ear(44.5, 65.2, angle: 92, length: 23.5, width: 8.8, bend: 1.8),
                eye: CGPoint(x: 51.5, y: 59.8),
                eyeOpen: 1,
                nose: CGPoint(x: 59.8, y: 56.8),
                tail: Oval(23.5, 16.5, 5.4, 5.6, -10),
                backHindFoot: PawShape(heel: CGPoint(x: 33, y: 11.2), toe: CGPoint(x: 53, y: 11.2), thickness: 2.9, isHind: true),
                hindFoot: PawShape(heel: CGPoint(x: 30, y: 10.4), toe: CGPoint(x: 50.5, y: 10.3), thickness: 3.1, isHind: true),
                backFrontPaw: PawShape(heel: CGPoint(x: 49.5, y: 46.5), toe: CGPoint(x: 58.2, y: 41.5),
                                       joint: CGPoint(x: 54.5, y: 44.2), thickness: 2.4),
                frontPaws: [PawShape(heel: CGPoint(x: 46.5, y: 45.5), toe: CGPoint(x: 56.2, y: 39.8),
                                     joint: CGPoint(x: 52.2, y: 42.6), thickness: 2.6)],
                bellyOval: Oval(48.5, 30.5, 8.6, 16.2, 8),
                isUpright: true
            )
        }
    }
}

// MARK: - Drawing

enum BunnyArtist {
    static let canvas = CGSize(width: 112, height: 96)
    static let groundY: CGFloat = 8
    static let pixelScale: CGFloat = 4
    static let marginX: CGFloat = 6
    private static let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

    /// Where the realistic sprites (`<Name>-<pose>.png`, 448×384, feet on the
    /// ground line) are: inside the app, or next to the source when a test
    /// build runs from the project folder.
    private static let spriteFolder: URL? = {
        let fm = FileManager.default
        let candidates = [Bundle.main.resourceURL?.appendingPathComponent("Sprites", isDirectory: true),
                          URL(fileURLWithPath: fm.currentDirectoryPath).appendingPathComponent("Resources/Sprites", isDirectory: true)]
        return candidates.compactMap { $0 }.first { fm.fileExists(atPath: $0.appendingPathComponent("Snoopy-sit.png").path) }
    }()

    static var hasRealisticSprites: Bool { spriteFolder != nil }

    /// A realistic sprite for this pose, or the nearest pose that has one.
    private static func realisticSprite(_ look: BunnyLook, _ pose: Pose) -> CGImage? {
        guard !look.isStandIn, let folder = spriteFolder else { return nil }
        var p: Pose? = pose
        while let q = p {
            let url = folder.appendingPathComponent("\(look.name)-\(q.rawValue).png")
            if let src = CGImageSourceCreateWithURL(url as CFURL, nil),
               let img = CGImageSourceCreateImageAtIndex(src, 0, nil) { return img }
            p = q.nearest
        }
        return nil
    }

    static func image(_ look: BunnyLook, _ pose: Pose, style: ArtStyle = .drawn) -> CGImage? {
        if style == .realistic, let sprite = realisticSprite(look, pose) { return sprite }
        let w = Int(canvas.width * pixelScale), h = Int(canvas.height * pixelScale)
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: sRGB,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.interpolationQuality = .high
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        ctx.scaleBy(x: pixelScale, y: pixelScale)
        ctx.translateBy(x: marginX, y: 0)
        draw(BunnyRig.forPose(pose), look, ctx)
        return ctx.makeImage()
    }

    static func draw(_ rig: BunnyRig, _ L: BunnyLook, _ ctx: CGContext) {
        var r = rig
        r.backEar.length *= L.earScale
        r.frontEar.length *= L.earScale
        let fluffy = L.fluff > 0.05

        if fluffy {
            let p = 3.2 * L.fluff
            r.head.rx += p * 0.85
            r.head.ry += p * 1.15
            r.snoutLength = 0.88
            r.tail.rx += p * 1.05
            r.tail.ry += p * 1.05
            r.backEar.width += p * 0.65
            r.frontEar.width += p * 0.72
            if r.frontEar.angle < 140 {
                r.backEar.angle += L.earRelax * 1.05
                r.frontEar.angle += L.earRelax * 0.65
                r.frontEar.bend -= 1.0
                r.backEar.bend -= 0.8
            }
            let a = r.head.angle * .pi / 180
            r.nose.x += cos(a) * p * 0.36
            r.nose.y += sin(a) * p * 0.36
        }

        let bodyPath = fluffy
            ? woollyContour(points: r.bodyOutline, puff: 3.3 * L.fluff, seed: 101, groundFloor: groundY + 0.3)
            : smoothClosedPath(r.bodyOutline, tension: 0.52)
        let headPath = fluffy
            ? angoraHeadPath(r.head, puff: 1.55 * L.fluff, seed: 202)
            : sculptedHeadPath(r.head, snoutLength: r.snoutLength)
        let tailPath = fluffy
            ? woollyOvalPath(r.tail, puff: 2.1 * L.fluff, seed: 303)
            : fluffyTailPath(r.tail, seed: 303)
        let backEarPath = r.backEar.outerPath(fluffBoost: fluffy ? 1.5 : 0)
        let frontEarPath = r.frontEar.outerPath(fluffBoost: fluffy ? 1.6 : 0)
        let backHindPath = r.backHindFoot?.path(fluff: L.fluff)
        let hindPath = r.hindFoot?.path(fluff: L.fluff)
        let backFrontPawPath = r.backFrontPaw?.path(fluff: L.fluff * 0.8)
        let frontPawPaths = r.frontPaws.map { $0.path(fluff: L.fluff * 0.9) }

        let silhouette = CGMutablePath()
        silhouette.addPath(backEarPath)
        silhouette.addPath(tailPath)
        if let p = backHindPath { silhouette.addPath(p) }
        if let p = backFrontPawPath { silhouette.addPath(p) }
        if let p = hindPath { silhouette.addPath(p) }
        silhouette.addPath(bodyPath)
        silhouette.addPath(headPath)
        for p in frontPawPaths { silhouette.addPath(p) }
        silhouette.addPath(frontEarPath)

        ctx.setLineJoin(.round)
        ctx.setLineCap(.round)

        ctx.saveGState()
        ctx.addPath(silhouette)
        ctx.setStrokeColor(L.outline.withAlphaComponent(fluffy ? 0.66 : 0.90).cgColor)
        ctx.setLineWidth(fluffy ? 1.9 : 2.1)
        ctx.strokePath()
        ctx.restoreGState()

        drawEar(r.backEar, backEarPath, isFront: false, L, ctx)

        if let path = backHindPath, let paw = r.backHindFoot {
            drawPaw(paw, path, shade: true, L, ctx)
        }
        if let path = backFrontPawPath, let paw = r.backFrontPaw {
            drawPaw(paw, path, shade: true, L, ctx)
        }

        drawTail(r.tail, tailPath, L, ctx)

        if let path = hindPath, let paw = r.hindFoot {
            drawPaw(paw, path, shade: false, L, ctx)
        }

        drawBody(r, bodyPath, L, ctx)

        clipped(bodyPath, ctx) {
            let neckAO = CGPoint(x: r.head.c.x - 2.2, y: r.head.c.y - r.head.ry * 0.62)
            radial(neckAO, r.head.rx * 1.05, L.furShade, fluffy ? 0.24 : 0.28, ctx)
        }

        drawHead(r, headPath, L, ctx)

        for (i, path) in frontPawPaths.enumerated() {
            drawPaw(r.frontPaws[i], path, shade: false, L, ctx)
            if fluffy, r.frontPaws[i].joint != nil, !r.isUpright {
                radial(r.frontPaws[i].heel, 5.6, L.fur, 0.94, ctx)
            }
        }

        drawEar(r.frontEar, frontEarPath, isFront: true, L, ctx)
        drawFace(r, L, ctx)

        if fluffy {
            drawAngoraFinish(r, L, ctx)
        }
    }

    // MARK: - Part Painters

    private static func drawBody(_ r: BunnyRig, _ bodyPath: CGPath, _ L: BunnyLook, _ ctx: CGContext) {
        let fluffy = L.fluff > 0.05
        fill(bodyPath, L.fur, ctx)

        clipped(bodyPath, ctx) {
            let box = bodyPath.boundingBoxOfPath

            let lightTop = L.furLight.withAlphaComponent(fluffy ? 0.62 : 0.24)
            let midClear = L.fur.withAlphaComponent(0)
            let botShade = L.furShade.withAlphaComponent(fluffy ? 0.28 : 0.44)
            let vol = CGGradient(colorsSpace: sRGB,
                                 colors: [lightTop.cgColor, midClear.cgColor, botShade.cgColor] as CFArray,
                                 locations: [0.0, 0.56, 1.0])!
            ctx.drawLinearGradient(vol,
                                   start: CGPoint(x: box.midX - 8, y: box.maxY),
                                   end: CGPoint(x: box.midX + 4, y: box.minY),
                                   options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])

            if let flank = L.flankShade {
                if fluffy {
                    let lowFlank = CGPoint(x: r.bodyFrame.c.x + (r.isUpright ? 2 : 5),
                                           y: r.bodyFrame.c.y - r.bodyFrame.ry * (r.isUpright ? 0.1 : 0.48))
                    radial(lowFlank, max(r.bodyFrame.rx, r.bodyFrame.ry) * 0.85, flank, 0.52, ctx)
                } else {
                    let lowFlank = CGPoint(x: r.bodyFrame.c.x + 2, y: r.bodyFrame.c.y - r.bodyFrame.ry * 0.35)
                    radial(lowFlank, max(r.bodyFrame.rx, r.bodyFrame.ry) * 0.72, flank, 0.36, ctx)
                }
            }

            if L.backShade > 0 {
                let saddle = CGGradient(colorsSpace: sRGB,
                                        colors: [NSColor(hex: 0x1E1813, alpha: L.backShade).cgColor,
                                                 NSColor(hex: 0x2F261E, alpha: L.backShade * 0.48).cgColor,
                                                 NSColor(hex: 0x2F261E, alpha: 0).cgColor] as CFArray,
                                        locations: [0, 0.48, 1])!
                if r.isUpright {
                    ctx.drawLinearGradient(saddle,
                                           start: CGPoint(x: box.minX, y: box.maxY),
                                           end: CGPoint(x: box.midX + 6, y: box.midY - 6),
                                           options: [])
                } else {
                    ctx.drawLinearGradient(saddle,
                                           start: CGPoint(x: box.midX, y: box.maxY),
                                           end: CGPoint(x: box.midX, y: box.midY - 3),
                                           options: [])
                }
            }

            if let nape = L.nape {
                let a = r.head.angle * .pi / 180
                let napePt = CGPoint(x: r.head.c.x - cos(a) * r.head.rx * 0.85,
                                     y: r.head.c.y - sin(a) * r.head.rx * 0.85 + 3.5)
                radial(napePt, 9.2, nape, 0.78, ctx)
            }

            if let belly = L.belly, let bo = r.bellyOval {
                let bAlpha: CGFloat = r.isFlop ? 0.96 : (fluffy ? 0.50 : 0.90)
                radialOval(bo, belly, bAlpha, ctx)
                if !fluffy {
                    paintBellyFeathering(bo, belly, seed: 55, ctx)
                }
            }

            if let h = r.haunch {
                if fluffy {
                    radial(CGPoint(x: h.c.x + h.rx * 0.32, y: h.c.y - h.ry * 0.42), h.rx * 0.90, L.furShade, 0.22, ctx)
                    radial(CGPoint(x: h.c.x - h.rx * 0.18, y: h.c.y + h.ry * 0.48), h.rx * 0.90, L.furLight, 0.65, ctx)
                } else {
                    ctx.saveGState()
                    let crease = CGMutablePath()
                    crease.move(to: CGPoint(x: h.c.x + h.rx * 0.78, y: h.c.y + h.ry * 0.15))
                    crease.addQuadCurve(to: CGPoint(x: h.c.x + h.rx * 0.12, y: h.c.y - h.ry * 0.82),
                                        control: CGPoint(x: h.c.x + h.rx * 0.68, y: h.c.y - h.ry * 0.58))
                    ctx.addPath(crease)
                    ctx.setStrokeColor(L.furShade.withAlphaComponent(0.42).cgColor)
                    ctx.setLineWidth(1.4)
                    ctx.strokePath()
                    ctx.restoreGState()
                    radial(CGPoint(x: h.c.x - 2, y: h.c.y + h.ry * 0.35), h.rx * 0.72, L.furLight, 0.16, ctx)
                }
            }

            if let t = L.ticking {
                paintAgoutiFur(in: r.bodyFrame, haunch: r.haunch, isUpright: r.isUpright, seed: 11, t, ctx)
            } else if fluffy {
                paintAngoraCloudWool(in: r.bodyFrame, haunch: r.haunch, isUpright: r.isUpright, seed: 21, L, ctx)
            }

            let sheen = CGGradient(colorsSpace: sRGB,
                                   colors: [NSColor(hex: 0xFFFBF2, alpha: L.highlight).cgColor,
                                            NSColor(hex: 0xFFFBF2, alpha: 0).cgColor] as CFArray,
                                   locations: [0, 1])!
            ctx.drawLinearGradient(sheen,
                                   start: CGPoint(x: box.midX - 6, y: box.maxY),
                                   end: CGPoint(x: box.midX, y: box.maxY - box.height * 0.38),
                                   options: [])
        }
    }

    private static func drawHead(_ r: BunnyRig, _ headPath: CGPath, _ L: BunnyLook, _ ctx: CGContext) {
        let fluffy = L.fluff > 0.05
        let h = r.head
        let a = h.angle

        fill(headPath, L.headFur, ctx)

        clipped(headPath, ctx) {
            let box = headPath.boundingBoxOfPath

            let g = CGGradient(colorsSpace: sRGB,
                               colors: [L.furLight.withAlphaComponent(fluffy ? 0.50 : 0.20).cgColor,
                                        L.headFur.withAlphaComponent(0).cgColor,
                                        L.furShade.withAlphaComponent(fluffy ? 0.26 : 0.38).cgColor] as CFArray,
                               locations: [0, 0.55, 1])!
            ctx.drawLinearGradient(g, start: CGPoint(x: box.midX, y: box.maxY), end: CGPoint(x: box.midX, y: box.minY), options: [])

            if fluffy {
                if let crownTint = L.crownTint {
                    let crownPt = rotated(h.c, a, h.rx * 0.05, h.ry * 0.62)
                    radial(crownPt, h.rx * 0.92, crownTint, 0.88, ctx)
                }
                if let tint = L.faceTint {
                    let bridge = CGPoint(x: r.eye.x * 0.42 + r.nose.x * 0.58,
                                         y: r.eye.y * 0.45 + r.nose.y * 0.55)
                    radial(bridge, h.rx * 0.96, tint, 0.92, ctx)
                }
                if let m = L.muzzle {
                    let snout = rotated(r.nose, a, -2.0, -0.2)
                    radial(snout, 5.8, m, 0.82, ctx)
                }
                if let cheek = L.cheek {
                    let muttonChop = rotated(h.c, a, -h.rx * 0.14, -h.ry * 0.44)
                    radialOval(Oval(muttonChop.x, muttonChop.y, h.rx * 0.72, h.ry * 0.58, a - 12), cheek, 0.92, ctx)
                    let backRuff = rotated(h.c, a, -h.rx * 0.58, -h.ry * 0.18)
                    radial(backRuff, h.rx * 0.58, L.furLight, 0.78, ctx)
                }
                if let chin = L.chin {
                    let cc = rotated(r.nose, a, -3.2, -4.2)
                    radial(cc, 4.6, chin, 0.75, ctx)
                }
            } else {
                if L.backShade > 0 {
                    let crown = rotated(h.c, a, 0.0, h.ry * 0.78)
                    radial(crown, h.rx * 0.90, NSColor(hex: 0x221B15), L.backShade * 0.88, ctx)
                    let noseBridge = rotated(r.nose, a, -3.2, 2.2)
                    radial(noseBridge, 5.2, NSColor(hex: 0x2D241C), 0.48, ctx)
                }
                if let cheek = L.cheek {
                    let c = rotated(h.c, a, h.rx * 0.05, -h.ry * 0.25)
                    radial(c, h.rx * 0.62, cheek, 0.55, ctx)
                }
                if let t = L.ticking {
                    paintHeadAgoutiFur(r, seed: 13, t, ctx)
                }
                if let m = L.muzzle {
                    let halo = rotated(r.nose, a, -1.6, -1.8)
                    radialOval(Oval(halo.x, halo.y, 4.6, 3.2, a), m, 0.92, ctx)
                }
                if let chin = L.chin {
                    let cc = rotated(r.nose, a, -3.6, -4.1)
                    radial(cc, 4.5, chin, 0.96, ctx)
                }
            }

            if let ring = L.eyeRing {
                let ringOval = fluffy
                    ? Oval(r.eye.x - 0.1, r.eye.y - 0.15, 4.5, 4.1, a * 0.4)
                    : Oval(r.eye.x - 0.1, r.eye.y, 5.0, 4.3, a * 0.5)
                radialOval(ringOval, ring, L.eyeRingAlpha, ctx)
            }
        }

        ctx.saveGState()
        let jaw = CGMutablePath()
        let j0 = rotated(h.c, a, h.rx * 0.54, -h.ry * 0.66)
        let j1 = rotated(h.c, a, -h.rx * 0.08, -h.ry * 0.92)
        let j2 = rotated(h.c, a, -h.rx * 0.50, -h.ry * 0.68)
        jaw.move(to: j0)
        jaw.addQuadCurve(to: j2, control: j1)
        ctx.addPath(jaw)
        ctx.setStrokeColor(L.outline.withAlphaComponent(fluffy ? 0.25 : 0.38).cgColor)
        ctx.setLineWidth(fluffy ? 0.78 : 0.85)
        ctx.strokePath()
        ctx.restoreGState()
    }

    private static func drawEar(_ ear: Ear, _ path: CGPath, isFront: Bool, _ L: BunnyLook, _ ctx: CGContext) {
        let fluffy = L.fluff > 0.05
        let baseColor = isFront ? L.earFur : L.furShade
        fill(path, baseColor, ctx)

        clipped(path, ctx) {
            let p0 = ear.point(along: 0)
            let p1 = ear.point(along: 1)

            let g = CGGradient(colorsSpace: sRGB,
                               colors: [baseColor.blended(withFraction: 0.18, of: L.furLight)?.cgColor ?? baseColor.cgColor,
                                        baseColor.cgColor,
                                        (L.earTip ?? L.furShade).withAlphaComponent(isFront ? 0.82 : 0.92).cgColor] as CFArray,
                               locations: [0, 0.55, 1])!
            ctx.drawLinearGradient(g, start: p0, end: p1, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])

            if isFront {
                let inner = ear.innerPath
                ctx.saveGState()
                ctx.addPath(inner)
                ctx.clip()
                let ig = CGGradient(colorsSpace: sRGB,
                                    colors: [L.innerEarDeep.cgColor,
                                             L.innerEar.cgColor,
                                             L.innerEar.blended(withFraction: 0.20, of: .white)?.cgColor ?? L.innerEar.cgColor] as CFArray,
                                    locations: [0.0, 0.55, 1.0])!
                ctx.drawLinearGradient(ig, start: ear.point(along: 0.12), end: ear.point(along: 0.85), options: [])
                ctx.restoreGState()

                ctx.saveGState()
                ctx.addPath(inner)
                ctx.setStrokeColor(L.innerEarDeep.withAlphaComponent(0.30).cgColor)
                ctx.setLineWidth(0.55)
                ctx.strokePath()
                ctx.restoreGState()

                let guardColor = (fluffy ? L.furLight : (L.eyeRing ?? L.furLight)).withAlphaComponent(fluffy ? 0.55 : 0.44)
                ctx.setStrokeColor(guardColor.cgColor)
                ctx.setLineWidth(fluffy ? 0.65 : 0.50)
                for i in 0..<(fluffy ? 3 : 4) {
                    let f = 0.12 + CGFloat(i) * 0.065
                    let sPt = ear.point(along: f, offset: ear.width * 0.28)
                    let ePt = ear.point(along: f + 0.05, offset: -ear.width * 0.02)
                    ctx.move(to: sPt); ctx.addLine(to: ePt)
                }
                ctx.strokePath()
            } else {
                let peek = ear.innerPath
                ctx.saveGState()
                ctx.addPath(peek)
                ctx.setFillColor(L.innerEarDeep.withAlphaComponent(0.30).cgColor)
                ctx.fillPath()
                ctx.restoreGState()
            }

            if let tip = L.earTip {
                let tipPt = ear.point(along: 0.96)
                radial(tipPt, ear.width * (fluffy ? 0.95 : 1.15), tip, isFront ? 0.88 : 0.94, ctx)
            }

            if let rim = L.earRim {
                ctx.addPath(path)
                ctx.setStrokeColor(rim.withAlphaComponent(fluffy ? (isFront ? 0.58 : 0.45) : (isFront ? 0.94 : 0.78)).cgColor)
                ctx.setLineWidth(fluffy ? 1.5 : (isFront ? 2.1 : 1.7))
                ctx.strokePath()
            }
        }

        strokeInside(path, L.outline.withAlphaComponent(isFront ? 0.45 : 0.38), 0.68, ctx)

        if isFront {
            let b = ear.base
            radial(CGPoint(x: b.x, y: b.y - 0.6), fluffy ? 5.2 : 3.4, fluffy ? (L.crownTint ?? L.headFur) : L.headFur, 0.88, ctx)
        }
    }

    private static func drawTail(_ o: Oval, _ path: CGPath, _ L: BunnyLook, _ ctx: CGContext) {
        let fluffy = L.fluff > 0.05
        fill(path, L.tail, ctx)
        clipped(path, ctx) {
            radial(CGPoint(x: o.c.x + o.rx * 0.25, y: o.c.y - o.ry * 0.55), o.rx * 1.15, L.furShade, fluffy ? 0.22 : 0.18, ctx)
            radial(CGPoint(x: o.c.x - o.rx * 0.2, y: o.c.y + o.ry * 0.35), o.rx * 0.95, .white, 0.48, ctx)
            if let top = L.tailTop {
                if fluffy {
                    let cap = CGPoint(x: o.c.x + o.rx * 0.05, y: o.c.y + o.ry * 0.26)
                    radial(cap, o.rx * 0.78, top, 0.88, ctx)
                    radial(CGPoint(x: o.c.x + o.rx * 0.10, y: o.c.y + o.ry * 0.34), o.rx * 0.45, L.earTip ?? top, 0.48, ctx)
                } else {
                    let capCenter = CGPoint(x: o.c.x + o.rx * 0.16, y: o.c.y + o.ry * 0.58)
                    radial(capCenter, o.rx * 1.18, top, 0.98, ctx)
                    ctx.setFillColor(top.withAlphaComponent(0.92).cgColor)
                    ctx.fillEllipse(in: CGRect(x: o.c.x - o.rx * 0.85, y: o.c.y + o.ry * 0.10, width: o.rx * 2.0, height: o.ry * 1.35))
                }
            }
        }
    }

    private static func drawPaw(_ paw: PawShape, _ path: CGPath, shade: Bool, _ L: BunnyLook, _ ctx: CGContext) {
        let fluffy = L.fluff > 0.05
        let base = shade ? (L.paw.blended(withFraction: 0.26, of: L.furShade) ?? L.paw) : L.paw
        fill(path, base, ctx)
        clipped(path, ctx) {
            let a = paw.tipAngle
            let nx = -sin(a), ny = cos(a)
            let shadowPt = CGPoint(x: paw.center.x - nx * paw.thickness * 0.85, y: paw.center.y - ny * paw.thickness * 0.85)
            radial(shadowPt, max(paw.length * 0.55, 5), L.furShade, shade ? 0.42 : 0.26, ctx)

            if let tip = L.pawTip {
                let r = max(paw.thickness * (fluffy ? 1.6 : 1.95), 4.2)
                radial(paw.toe, r, tip, fluffy ? 0.42 : 1.0, ctx)
            }

            if !shade {
                let ux = cos(a), uy = sin(a)
                ctx.setStrokeColor(L.outline.withAlphaComponent(fluffy ? 0.30 : 0.42).cgColor)
                ctx.setLineWidth(0.55)
                for sgn in [-0.30, 0.18] as [CGFloat] {
                    let t1 = CGPoint(x: paw.toe.x + ux * paw.thickness * 0.42 + nx * paw.thickness * sgn,
                                     y: paw.toe.y + uy * paw.thickness * 0.42 + ny * paw.thickness * sgn)
                    let t0 = CGPoint(x: t1.x - ux * 1.7, y: t1.y - uy * 1.7)
                    ctx.move(to: t0); ctx.addLine(to: t1)
                }
                ctx.strokePath()
            }
        }
        strokeInside(path, L.outline.withAlphaComponent(shade ? 0.36 : (fluffy ? 0.30 : 0.52)), 0.72, ctx)
    }

    private static func drawFace(_ r: BunnyRig, _ L: BunnyLook, _ ctx: CGContext) {
        let fluffy = L.fluff > 0.05
        let a = r.head.angle

        drawEye(at: r.eye, open: r.eyeOpen, headAngle: a, L, ctx)

        let n = r.nose
        ctx.saveGState()
        ctx.translateBy(x: n.x, y: n.y)
        ctx.rotate(by: a * .pi / 180)

        let nosePath = CGMutablePath()
        nosePath.move(to: CGPoint(x: 1.35, y: 0.45))
        nosePath.addQuadCurve(to: CGPoint(x: -1.25, y: 0.55), control: CGPoint(x: 0.0, y: 1.25))
        nosePath.addQuadCurve(to: CGPoint(x: 0.1, y: -1.15), control: CGPoint(x: -0.95, y: -0.65))
        nosePath.addQuadCurve(to: CGPoint(x: 1.35, y: 0.45), control: CGPoint(x: 1.15, y: -0.65))
        nosePath.closeSubpath()
        ctx.addPath(nosePath)
        ctx.setFillColor(L.nose.cgColor)
        ctx.fillPath()
        ctx.setFillColor(NSColor.white.withAlphaComponent(0.38).cgColor)
        ctx.fillEllipse(in: CGRect(x: -0.35, y: 0.1, width: 0.85, height: 0.5))

        let mouthColor = (fluffy ? (L.muzzle ?? L.outline) : L.outline).withAlphaComponent(fluffy ? 0.65 : 0.80)
        ctx.setStrokeColor(mouthColor.cgColor)
        ctx.setLineWidth(fluffy ? 0.62 : 0.72)
        let chew = r.chewLift * 0.55
        ctx.move(to: CGPoint(x: -0.1, y: -1.05))
        ctx.addLine(to: CGPoint(x: -0.5, y: -2.4 + chew))
        ctx.addQuadCurve(to: CGPoint(x: -3.2, y: -2.7 + chew * 0.6), control: CGPoint(x: -1.4, y: -3.55 + chew))
        ctx.strokePath()

        let whiskerColor = (fluffy ? (L.wisp ?? L.outline) : (L.chin ?? L.outline)).withAlphaComponent(fluffy ? 0.76 : 0.62)
        let whiskerShadow = L.outline.withAlphaComponent(fluffy ? 0.26 : 0.36)
        let twitch = r.noseTwitch * 0.6
        for (idx, dy) in ([-1.5, 0.0, 1.5] as [CGFloat]).enumerated() {
            let len: CGFloat = idx == 1 ? 8.2 : 7.0
            let start = CGPoint(x: -2.5, y: -1.5 + dy * 0.28)
            let end = CGPoint(x: -2.5 + len, y: -1.8 + dy * 1.45 + twitch)
            let ctrl = CGPoint(x: -2.5 + len * 0.55, y: -1.1 + dy * 0.65 + twitch * 0.5)
            ctx.setStrokeColor(whiskerShadow.cgColor)
            ctx.setLineWidth(0.68)
            ctx.move(to: start); ctx.addQuadCurve(to: end, control: ctrl); ctx.strokePath()
            ctx.setStrokeColor(whiskerColor.cgColor)
            ctx.setLineWidth(0.45)
            ctx.move(to: start); ctx.addQuadCurve(to: end, control: ctrl); ctx.strokePath()
        }
        ctx.restoreGState()
    }

    private static func drawEye(at p: CGPoint, open: CGFloat, headAngle: CGFloat, _ L: BunnyLook, _ ctx: CGContext) {
        let fluffy = L.fluff > 0.05
        let rx: CGFloat = fluffy ? 3.15 : 3.45
        let ry: CGFloat = fluffy ? 3.25 : 3.55

        if open <= 0.05 {
            ctx.saveGState()
            ctx.translateBy(x: p.x, y: p.y)
            ctx.rotate(by: headAngle * 0.5 * .pi / 180)
            ctx.setStrokeColor(L.eye.withAlphaComponent(0.88).cgColor)
            ctx.setLineWidth(1.15)
            ctx.move(to: CGPoint(x: -rx * 0.85, y: 0.35))
            ctx.addQuadCurve(to: CGPoint(x: rx * 0.85, y: 0.25), control: CGPoint(x: 0, y: -ry * 0.72))
            ctx.strokePath()
            ctx.setLineWidth(0.7)
            ctx.move(to: CGPoint(x: -rx * 0.78, y: 0.22))
            ctx.addLine(to: CGPoint(x: -rx * 1.06, y: 0.85))
            ctx.strokePath()
            ctx.restoreGState()
            return
        }

        ctx.saveGState()
        ctx.translateBy(x: p.x, y: p.y)
        ctx.rotate(by: headAngle * 0.35 * .pi / 180)

        let lidBaseY = -ry + (ry * 2) * open + 0.1
        if open < 0.95 {
            let clipPath = CGMutablePath()
            clipPath.move(to: CGPoint(x: -rx - 1, y: lidBaseY - 0.2))
            clipPath.addQuadCurve(to: CGPoint(x: rx + 1, y: lidBaseY - 0.15), control: CGPoint(x: 0, y: lidBaseY + 1.35))
            clipPath.addLine(to: CGPoint(x: rx + 1, y: -ry - 1.5))
            clipPath.addLine(to: CGPoint(x: -rx - 1, y: -ry - 1.5))
            clipPath.closeSubpath()
            ctx.addPath(clipPath)
            ctx.clip()
        }

        if !fluffy && open >= 0.95 {
            ctx.setFillColor(NSColor(hex: 0xF5F0E4, alpha: 0.75).cgColor)
            ctx.fillEllipse(in: CGRect(x: -rx - 0.45, y: -ry * 0.78, width: rx * 1.9, height: ry * 1.65))
        }

        let eyeRect = CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2)
        if let iris = L.iris {
            ctx.setFillColor(iris.cgColor)
            ctx.fillEllipse(in: eyeRect)
            if let glow = L.irisGlow {
                ctx.saveGState()
                ctx.addEllipse(in: eyeRect)
                ctx.clip()
                radial(CGPoint(x: -rx * 0.36, y: -ry * 0.42), rx * 0.98, glow, fluffy ? 0.86 : 0.65, ctx)
                ctx.restoreGState()
            }
            let pr = fluffy ? 0.58 : 0.74
            ctx.setFillColor(L.eye.cgColor)
            ctx.fillEllipse(in: CGRect(x: -rx * pr, y: -ry * pr, width: rx * 2 * pr, height: ry * 2 * pr))
        } else {
            ctx.setFillColor(L.eye.cgColor)
            ctx.fillEllipse(in: eyeRect)
        }

        let glintY: CGFloat = open < 0.95 ? 0.10 : 0.68
        ctx.setFillColor(NSColor.white.withAlphaComponent(0.96).cgColor)
        ctx.fillEllipse(in: CGRect(x: 0.35, y: glintY, width: open < 0.95 ? 1.5 : 1.8, height: open < 0.95 ? 1.5 : 1.8))
        ctx.setFillColor(NSColor.white.withAlphaComponent(0.62).cgColor)
        ctx.fillEllipse(in: CGRect(x: -1.5, y: -1.65, width: 0.8, height: 0.8))

        ctx.setStrokeColor(L.eye.withAlphaComponent(0.65).cgColor)
        ctx.setLineWidth(0.45)
        ctx.strokeEllipse(in: eyeRect)
        ctx.restoreGState()

        ctx.saveGState()
        ctx.translateBy(x: p.x, y: p.y)
        ctx.rotate(by: headAngle * 0.35 * .pi / 180)
        if open < 0.95 {
            let hood = CGMutablePath()
            hood.move(to: CGPoint(x: -rx * 1.05, y: lidBaseY - 0.12))
            hood.addQuadCurve(to: CGPoint(x: rx * 1.05, y: lidBaseY - 0.08), control: CGPoint(x: 0, y: lidBaseY + 1.45))
            hood.addQuadCurve(to: CGPoint(x: -rx * 1.05, y: lidBaseY - 0.12), control: CGPoint(x: 0, y: ry + 0.7))
            hood.closeSubpath()
            ctx.addPath(hood)
            ctx.setFillColor((L.eyeRing ?? L.headFur).withAlphaComponent(0.75).cgColor)
            ctx.fillPath()

            ctx.setStrokeColor(L.outline.withAlphaComponent(0.82).cgColor)
            ctx.setLineWidth(0.92)
            ctx.move(to: CGPoint(x: -rx * 0.96, y: lidBaseY - 0.10))
            ctx.addQuadCurve(to: CGPoint(x: rx * 0.96, y: lidBaseY - 0.06), control: CGPoint(x: 0, y: lidBaseY + 1.42))
            ctx.strokePath()
        } else {
            ctx.setStrokeColor(L.eye.withAlphaComponent(0.75).cgColor)
            ctx.setLineWidth(0.78)
            ctx.move(to: CGPoint(x: -rx * 0.86, y: ry * 0.52))
            ctx.addQuadCurve(to: CGPoint(x: rx * 0.78, y: ry * 0.60), control: CGPoint(x: 0, y: ry * 1.18))
            ctx.strokePath()
        }
        ctx.restoreGState()
    }

    // MARK: - Painterly Fur & Fleece Textures

    private static func paintAgoutiFur(in body: Oval, haunch: Oval?, isUpright: Bool, seed: UInt64,
                                       _ t: (dark: NSColor, mid: NSColor, light: NSColor), _ ctx: CGContext) {
        var rng = PropArt.Seeded(state: seed &* 15_485_863 &+ 9)
        let a = body.angle * .pi / 180

        for _ in 0..<260 {
            let rad = sqrt(rng.next())
            let th = rng.range(0, 2 * .pi)
            let lx = rad * cos(th) * body.rx * 1.08
            let ly = rad * sin(th) * body.ry * 1.08
            let p = CGPoint(x: body.c.x + lx * cos(a) - ly * sin(a),
                            y: body.c.y + lx * sin(a) + ly * cos(a))

            let dorsal = isUpright
                ? max(0, min(1, 1 - (lx / max(body.rx, 1) * 0.5 + 0.5)))
                : max(0, min(1, (ly / max(body.ry, 1)) * 0.5 + 0.5))

            let roll = rng.next()
            let color: NSColor
            if dorsal < 0.22 {
                color = roll < 0.65 ? t.light.withAlphaComponent(0.32) : t.mid.withAlphaComponent(0.24)
            } else if dorsal > 0.56 {
                color = roll < 0.62 ? t.dark.withAlphaComponent(0.42)
                      : (roll < 0.86 ? t.light.withAlphaComponent(0.40) : t.mid.withAlphaComponent(0.34))
            } else {
                color = roll < 0.48 ? t.dark.withAlphaComponent(0.36)
                      : (roll < 0.80 ? t.light.withAlphaComponent(0.38) : t.mid.withAlphaComponent(0.34))
            }

            let flowAngle = a + (isUpright ? -.pi * 0.95 : .pi) + (ly / max(body.ry, 1)) * 0.25 + rng.range(-0.22, 0.22)
            let len = rng.range(1.7, 3.4)
            let bend = rng.range(-0.45, 0.45)
            let p0 = CGPoint(x: p.x - cos(flowAngle) * len * 0.5, y: p.y - sin(flowAngle) * len * 0.5)
            let p1 = CGPoint(x: p.x + cos(flowAngle) * len * 0.5, y: p.y + sin(flowAngle) * len * 0.5)
            let ctrl = CGPoint(x: p.x - sin(flowAngle) * bend, y: p.y + cos(flowAngle) * bend)

            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(rng.range(0.45, 0.74))
            ctx.move(to: p0); ctx.addQuadCurve(to: p1, control: ctrl); ctx.strokePath()
        }

        if let h = haunch {
            for _ in 0..<92 {
                let rad = sqrt(rng.next())
                let th = rng.range(0, 2 * .pi)
                let p = CGPoint(x: h.c.x + rad * cos(th) * h.rx, y: h.c.y + rad * sin(th) * h.ry)
                let tangent = th - .pi * 0.55 + rng.range(-0.25, 0.25)
                let len = rng.range(1.5, 3.1)
                let roll = rng.next()
                let color = roll < 0.54 ? t.dark.withAlphaComponent(0.38)
                          : (roll < 0.84 ? t.light.withAlphaComponent(0.38) : t.mid.withAlphaComponent(0.32))
                ctx.setStrokeColor(color.cgColor)
                ctx.setLineWidth(rng.range(0.45, 0.70))
                ctx.move(to: CGPoint(x: p.x - cos(tangent) * len * 0.5, y: p.y - sin(tangent) * len * 0.5))
                ctx.addLine(to: CGPoint(x: p.x + cos(tangent) * len * 0.5, y: p.y + sin(tangent) * len * 0.5))
                ctx.strokePath()
            }
        }
    }

    private static func paintHeadAgoutiFur(_ r: BunnyRig, seed: UInt64,
                                           _ t: (dark: NSColor, mid: NSColor, light: NSColor), _ ctx: CGContext) {
        var rng = PropArt.Seeded(state: seed &* 9_973 &+ 7)
        let h = r.head
        let a = h.angle * .pi / 180
        for _ in 0..<68 {
            let rad = sqrt(rng.next())
            let th = rng.range(0, 2 * .pi)
            let lx = rad * cos(th) * h.rx * 0.95
            let ly = rad * sin(th) * h.ry * 0.95
            let p = CGPoint(x: h.c.x + lx * cos(a) - ly * sin(a),
                            y: h.c.y + lx * sin(a) + ly * cos(a))
            if p.distance(to: r.eye) < 5.0 { continue }
            let fromNose = atan2(p.y - r.nose.y, p.x - r.nose.x) + rng.range(-0.2, 0.2)
            let len = rng.range(1.3, 2.4)
            let roll = rng.next()
            let color = roll < 0.50 ? t.dark.withAlphaComponent(0.34)
                      : (roll < 0.82 ? t.light.withAlphaComponent(0.36) : t.mid.withAlphaComponent(0.30))
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(rng.range(0.42, 0.64))
            ctx.move(to: CGPoint(x: p.x - cos(fromNose) * len * 0.5, y: p.y - sin(fromNose) * len * 0.5))
            ctx.addLine(to: CGPoint(x: p.x + cos(fromNose) * len * 0.5, y: p.y + sin(fromNose) * len * 0.5))
            ctx.strokePath()
        }
    }

    private static func paintBellyFeathering(_ bo: Oval, _ belly: NSColor, seed: UInt64, _ ctx: CGContext) {
        var rng = PropArt.Seeded(state: seed &* 4_999 &+ 11)
        let a = bo.angle * .pi / 180
        ctx.setLineWidth(0.6)
        for _ in 0..<34 {
            let th = rng.range(0.08 * .pi, 0.92 * .pi)
            let lx = cos(th) * bo.rx * rng.range(0.75, 1.02)
            let ly = sin(th) * bo.ry * rng.range(0.7, 1.05)
            let p = CGPoint(x: bo.c.x + lx * cos(a) - ly * sin(a),
                            y: bo.c.y + lx * sin(a) + ly * cos(a))
            let ang = a + .pi + rng.range(-0.35, 0.35)
            let len = rng.range(1.6, 3.0)
            ctx.setStrokeColor(belly.withAlphaComponent(rng.range(0.35, 0.68)).cgColor)
            ctx.move(to: p)
            ctx.addLine(to: CGPoint(x: p.x + cos(ang) * len, y: p.y + sin(ang) * len))
            ctx.strokePath()
        }
    }

    private static func paintAngoraCloudWool(in body: Oval, haunch: Oval?, isUpright: Bool, seed: UInt64,
                                             _ L: BunnyLook, _ ctx: CGContext) {
        var rng = PropArt.Seeded(state: seed &* 7_919 &+ 13)
        let a = body.angle * .pi / 180

        for _ in 0..<32 {
            let rad = sqrt(rng.next()) * 0.88
            let th = rng.range(0, 2 * .pi)
            let lx = rad * cos(th) * body.rx
            let ly = rad * sin(th) * body.ry
            let p = CGPoint(x: body.c.x + lx * cos(a) - ly * sin(a),
                            y: body.c.y + lx * sin(a) + ly * cos(a))
            let r = rng.range(4.4, 8.2)
            radial(CGPoint(x: p.x + 0.9, y: p.y - 1.4), r, L.furShade, rng.range(0.11, 0.20), ctx)
            radial(CGPoint(x: p.x - 0.6, y: p.y + 1.1), r * 0.92, L.furLight, rng.range(0.46, 0.74), ctx)
        }

        for _ in 0..<14 {
            let rad = sqrt(rng.next()) * 0.78
            let th = rng.range(0, 2 * .pi)
            let lx = rad * cos(th) * body.rx
            let ly = rad * sin(th) * body.ry
            let p = CGPoint(x: body.c.x + lx * cos(a) - ly * sin(a),
                            y: body.c.y + lx * sin(a) + ly * cos(a))
            let span = rng.range(3.2, 5.4)
            let tilt: CGFloat = isUpright ? rng.range(-0.5, 0.5) : rng.range(-0.6, 0.35)
            let s = CGPoint(x: p.x - cos(tilt) * span * 0.5, y: p.y - sin(tilt) * span * 0.5)
            let e = CGPoint(x: p.x + cos(tilt) * span * 0.5, y: p.y + sin(tilt) * span * 0.5)
            let c = CGPoint(x: p.x, y: p.y - rng.range(1.2, 2.2))
            ctx.setStrokeColor(L.furShade.withAlphaComponent(rng.range(0.10, 0.17)).cgColor)
            ctx.setLineWidth(rng.range(0.65, 0.95))
            ctx.move(to: s); ctx.addQuadCurve(to: e, control: c); ctx.strokePath()
            ctx.setStrokeColor(L.furLight.withAlphaComponent(0.58).cgColor)
            ctx.setLineWidth(0.75)
            ctx.move(to: CGPoint(x: s.x, y: s.y + 0.85))
            ctx.addQuadCurve(to: CGPoint(x: e.x, y: e.y + 0.85), control: CGPoint(x: c.x, y: c.y + 0.85))
            ctx.strokePath()
        }
        _ = haunch
    }

    private static func drawAngoraFinish(_ r: BunnyRig, _ L: BunnyLook, _ ctx: CGContext) {
        let wisp = L.wisp ?? L.furLight
        let tasselBase = L.tassel ?? L.furShade
        let smoky = L.earTip ?? L.furShade
        let a = r.head.angle

        let puffCenter = rotated(r.head.c, a, -r.head.rx * 0.08, -r.head.ry * 0.52)
        radialOval(Oval(puffCenter.x, puffCenter.y, 7.6, 5.4, a - 10), L.furShade, 0.18, ctx)
        radialOval(Oval(puffCenter.x + 0.4, puffCenter.y + 0.7, 7.2, 5.0, a - 10), wisp, 0.90, ctx)
        let cheekBase = rotated(r.head.c, a, r.head.rx * 0.06, -r.head.ry * 0.30)
        let cheekTufts: [(angOff: CGFloat, len: CGFloat, w: CGFloat, col: NSColor)] = [
            (176, 6.8, 2.7, wisp),
            (194, 7.8, 3.0, L.fur),
            (212, 7.4, 2.8, wisp),
            (230, 6.2, 2.4, L.headFur),
        ]
        for ct in cheekTufts {
            let ang = (a + ct.angOff) * .pi / 180
            let s = CGPoint(x: cheekBase.x + cos(ang) * 0.5, y: cheekBase.y + sin(ang) * 0.5)
            let e = CGPoint(x: s.x + cos(ang) * ct.len, y: s.y + sin(ang) * ct.len - 0.9)
            let c = CGPoint(x: (s.x + e.x) * 0.5, y: (s.y + e.y) * 0.5 + 1.1)
            drawTaperedHair(from: CGPoint(x: s.x, y: s.y - 0.6), control: CGPoint(x: c.x, y: c.y - 0.7),
                            to: CGPoint(x: e.x, y: e.y - 0.5), width: ct.w * 0.9,
                            color: L.furShade.withAlphaComponent(0.18), ctx)
            drawTaperedHair(from: s, control: c, to: e, width: ct.w, color: ct.col.withAlphaComponent(0.92), ctx)
        }

        let bangMid = L.crownTint ?? L.headFur
        let bangDark = L.faceTint ?? L.furShade
        let bangs: [(dx: CGFloat, dy: CGFloat, endDx: CGFloat, endDy: CGFloat, col: NSColor, w: CGFloat)] = [
            (-5.4, 5.8, -1.2, 3.0, L.headFur, 2.3),
            (-3.6, 7.0,  0.9, 3.1, bangMid, 2.1),
            (-1.5, 7.0,  2.8, 2.6, bangDark, 1.8),
            ( 0.4, 6.2,  4.0, 2.0, L.headFur, 1.5),
            (-2.4, 6.4,  1.8, 2.8, wisp, 1.15),
        ]
        for b in bangs {
            let s = rotated(r.eye, a, b.dx, b.dy)
            let e = rotated(r.eye, a, b.endDx, b.endDy)
            let c = rotated(r.eye, a, (b.dx + b.endDx) * 0.5 + 1.0, max(b.dy, b.endDy) + 0.9)
            drawTaperedHair(from: s, control: c, to: e, width: b.w, color: b.col.withAlphaComponent(0.90), ctx)
        }

        for (idx, ear) in [r.backEar, r.frontEar].enumerated() {
            drawSilkyEarTassels(ear, seed: idx == 0 ? 31 : 32, isFront: idx == 1,
                                light: wisp, mid: tasselBase, dark: smoky, outline: L.outline, ctx)
        }
    }

    private static func drawSilkyEarTassels(_ ear: Ear, seed: UInt64, isFront: Bool,
                                            light: NSColor, mid: NSColor, dark: NSColor, outline: NSColor, _ ctx: CGContext) {
        var rng = PropArt.Seeded(state: seed &* 104_729 &+ 17)
        let a = ear.angle * .pi / 180

        for i in 0..<4 {
            let t = 0.42 + CGFloat(i) * 0.13
            let side: CGFloat = i % 2 == 0 ? 1 : -1
            let start = ear.point(along: t, offset: side * ear.width * 0.42)
            let outAng = a + side * 0.54 + 0.28 + rng.range(-0.08, 0.08)
            let len = rng.range(3.0, 5.0)
            let end = CGPoint(x: start.x + cos(outAng) * len, y: start.y + sin(outAng) * len - 0.9)
            let ctrl = CGPoint(x: (start.x + end.x) * 0.5 + cos(a) * 1.1, y: (start.y + end.y) * 0.5 + sin(a) * 1.1)
            drawTaperedHair(from: start, control: ctrl, to: end, width: 1.4,
                            color: (i % 2 == 0 ? light : mid).withAlphaComponent(isFront ? 0.88 : 0.76), ctx)
        }

        let tip = ear.point(along: 0.90)
        let softSmoky = dark.blended(withFraction: 0.62, of: mid) ?? mid
        let plumeColors = [softSmoky, mid, light, mid.blended(withFraction: 0.55, of: light) ?? light, light]
        for i in 0..<5 {
            let spread = (CGFloat(i) / 4.0 - 0.5) * 0.42
            let ang = a + 0.56 + spread
            let len = rng.range(7.2, 10.8) * (1.0 - abs(spread) * 0.15)
            let start = ear.point(along: 0.85 + rng.range(-0.03, 0.07), offset: spread * ear.width * 0.30)
            let end = CGPoint(x: tip.x + cos(ang) * len, y: tip.y + sin(ang) * len - 1.9)
            let ctrl = CGPoint(x: (start.x + end.x) * 0.5 + cos(a) * 2.1,
                               y: (start.y + end.y) * 0.5 + sin(a) * 2.1 + 1.0)
            drawTaperedHair(from: start, control: ctrl, to: end, width: 2.25,
                            color: outline.withAlphaComponent(isFront ? 0.15 : 0.10), ctx)
            drawTaperedHair(from: start, control: ctrl, to: end, width: rng.range(1.6, 2.1),
                            color: plumeColors[i % plumeColors.count].withAlphaComponent(isFront ? 0.94 : 0.84), ctx)
        }
    }

    // MARK: - Organic Shape Builders

    private static func smoothClosedPath(_ pts: [CGPoint], tension: CGFloat = 0.5) -> CGPath {
        let p = CGMutablePath()
        let n = pts.count
        guard n >= 3 else { return p }
        p.move(to: pts[0])
        for i in 0..<n {
            let p0 = pts[(i - 1 + n) % n]
            let p1 = pts[i]
            let p2 = pts[(i + 1) % n]
            let p3 = pts[(i + 2) % n]
            let c1 = CGPoint(x: p1.x + (p2.x - p0.x) * tension / 3.0,
                             y: p1.y + (p2.y - p0.y) * tension / 3.0)
            let c2 = CGPoint(x: p2.x - (p3.x - p1.x) * tension / 3.0,
                             y: p2.y - (p3.y - p1.y) * tension / 3.0)
            p.addCurve(to: p2, control1: c1, control2: c2)
        }
        p.closeSubpath()
        return p
    }

    private static func woollyContour(points: [CGPoint], puff: CGFloat, seed: UInt64, groundFloor: CGFloat) -> CGPath {
        var samples: [CGPoint] = []
        let n = points.count
        guard n >= 3 else { return CGMutablePath() }
        let subSteps = 4
        for i in 0..<n {
            let p0 = points[(i - 1 + n) % n]
            let p1 = points[i]
            let p2 = points[(i + 1) % n]
            let p3 = points[(i + 2) % n]
            let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6.0, y: p1.y + (p2.y - p0.y) / 6.0)
            let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6.0, y: p2.y - (p3.y - p1.y) / 6.0)
            for s in 0..<subSteps {
                let t = CGFloat(s) / CGFloat(subSteps)
                let mt = 1 - t
                let x = mt*mt*mt*p1.x + 3*mt*mt*t*c1.x + 3*mt*t*t*c2.x + t*t*t*p2.x
                let y = mt*mt*mt*p1.y + 3*mt*mt*t*c1.y + 3*mt*t*t*c2.y + t*t*t*p2.y
                samples.append(CGPoint(x: x, y: y))
            }
        }

        let m = samples.count
        var anchors: [(pt: CGPoint, n: CGVector)] = []
        for i in 0..<m {
            let prev = samples[(i - 1 + m) % m]
            let next = samples[(i + 1) % m]
            let dx = next.x - prev.x, dy = next.y - prev.y
            let len = max(hypot(dx, dy), 0.001)
            let nx = -dy / len, ny = dx / len
            let localPuff = ny < -0.45 ? puff * 0.35 : puff
            let pt = CGPoint(x: samples[i].x + nx * localPuff,
                             y: max(groundFloor, samples[i].y + ny * localPuff))
            anchors.append((pt, CGVector(dx: nx, dy: ny)))
        }

        var rng = PropArt.Seeded(state: seed &* 2_654_435_761 &+ 29)
        let path = CGMutablePath()
        let stride = 2
        let count = m / stride
        var ring: [(pt: CGPoint, n: CGVector)] = []
        for k in 0..<count { ring.append(anchors[k * stride]) }

        path.move(to: ring[0].pt)
        for k in 0..<ring.count {
            let a0 = ring[k]
            let a1 = ring[(k + 1) % ring.count]
            let midX = (a0.pt.x + a1.pt.x) * 0.5
            let midY = (a0.pt.y + a1.pt.y) * 0.5
            let nx = (a0.n.dx + a1.n.dx) * 0.5
            let ny = (a0.n.dy + a1.n.dy) * 0.5
            let isBottom = ny < -0.5
            let lift = isBottom ? rng.range(0.5, 1.2) : rng.range(1.9, 3.8)
            let sweep = isBottom ? 0 : rng.range(-0.7, 0.7)
            let ctrl = CGPoint(x: midX + nx * lift + sweep,
                               y: max(groundFloor, midY + ny * lift - (isBottom ? 0 : 0.25)))
            path.addQuadCurve(to: a1.pt, control: ctrl)
        }
        path.closeSubpath()
        return path
    }

    private static func sculptedHeadPath(_ o: Oval, snoutLength: CGFloat = 1.0) -> CGPath {
        let rx = o.rx, ry = o.ry
        let pts: [CGPoint] = [
            CGPoint(x: -0.95 * rx, y:  0.18 * ry),
            CGPoint(x: -0.58 * rx, y:  0.88 * ry),
            CGPoint(x:  0.14 * rx, y:  0.96 * ry),
            CGPoint(x:  0.74 * rx, y:  0.54 * ry),
            CGPoint(x:  1.04 * rx * snoutLength, y: -0.02 * ry),
            CGPoint(x:  0.82 * rx, y: -0.56 * ry),
            CGPoint(x:  0.22 * rx, y: -0.95 * ry),
            CGPoint(x: -0.52 * rx, y: -0.82 * ry),
        ]
        var t = CGAffineTransform(translationX: o.c.x, y: o.c.y).rotated(by: o.angle * .pi / 180)
        let local = smoothClosedPath(pts, tension: 0.54)
        return local.copy(using: &t) ?? local
    }

    private static func angoraHeadPath(_ o: Oval, puff: CGFloat, seed: UInt64) -> CGPath {
        let rx = o.rx, ry = o.ry
        let a = o.angle * .pi / 180
        func world(_ lx: CGFloat, _ ly: CGFloat) -> CGPoint {
            CGPoint(x: o.c.x + lx * cos(a) - ly * sin(a), y: o.c.y + lx * sin(a) + ly * cos(a))
        }
        let basePts: [CGPoint] = [
            world(-0.98 * rx,  0.24 * ry),
            world(-0.54 * rx,  1.02 * ry),
            world( 0.20 * rx,  1.02 * ry),
            world( 0.72 * rx,  0.52 * ry),
            world( 0.92 * rx, -0.04 * ry),
            world( 0.76 * rx, -0.62 * ry),
            world( 0.14 * rx, -1.08 * ry),
            world(-0.60 * rx, -0.92 * ry),
        ]
        return woollyContour(points: basePts, puff: puff * 0.52, seed: seed, groundFloor: groundY + 0.4)
    }

    private static func fluffyTailPath(_ o: Oval, seed: UInt64) -> CGPath {
        var rng = PropArt.Seeded(state: seed &* 8_191 &+ 3)
        let n = 10
        let a = o.angle * .pi / 180
        var pts: [CGPoint] = []
        for i in 0..<n {
            let th = CGFloat(i) / CGFloat(n) * 2 * .pi
            let wobble = rng.range(0.88, 1.12)
            let lx = cos(th) * o.rx * wobble
            let ly = sin(th) * o.ry * wobble
            pts.append(CGPoint(x: o.c.x + lx * cos(a) - ly * sin(a),
                               y: o.c.y + lx * sin(a) + ly * cos(a)))
        }
        return smoothClosedPath(pts, tension: 0.58)
    }

    private static func woollyOvalPath(_ o: Oval, puff: CGFloat, seed: UInt64) -> CGPath {
        let n = 8
        let a = o.angle * .pi / 180
        var pts: [CGPoint] = []
        for i in 0..<n {
            let th = -CGFloat(i) / CGFloat(n) * 2 * .pi
            let lx = cos(th) * o.rx
            let ly = sin(th) * o.ry
            pts.append(CGPoint(x: o.c.x + lx * cos(a) - ly * sin(a),
                               y: o.c.y + lx * sin(a) + ly * cos(a)))
        }
        return woollyContour(points: pts, puff: puff * 0.55, seed: seed, groundFloor: groundY + 0.4)
    }

    // MARK: - Painterly Primitives

    private static func drawTaperedHair(from s: CGPoint, control c: CGPoint, to e: CGPoint,
                                        width: CGFloat, color: NSColor, _ ctx: CGContext) {
        let dx = c.x - s.x, dy = c.y - s.y
        let len = max(hypot(dx, dy), 0.01)
        let nx = -dy / len * width * 0.5
        let ny = dx / len * width * 0.5
        let p = CGMutablePath()
        p.move(to: CGPoint(x: s.x + nx, y: s.y + ny))
        p.addQuadCurve(to: e, control: CGPoint(x: c.x + nx * 0.45, y: c.y + ny * 0.45))
        p.addQuadCurve(to: CGPoint(x: s.x - nx, y: s.y - ny), control: CGPoint(x: c.x - nx * 0.45, y: c.y - ny * 0.45))
        p.closeSubpath()
        ctx.addPath(p)
        ctx.setFillColor(color.cgColor)
        ctx.fillPath()
    }

    private static func rotated(_ p: CGPoint, _ degrees: CGFloat, _ dx: CGFloat, _ dy: CGFloat) -> CGPoint {
        let a = degrees * .pi / 180
        return CGPoint(x: p.x + dx * cos(a) - dy * sin(a), y: p.y + dx * sin(a) + dy * cos(a))
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
                                                       color.withAlphaComponent(alpha * 0.58).cgColor,
                                                       color.withAlphaComponent(0).cgColor] as CFArray,
                           locations: [0, 0.55, 1])!
        ctx.drawRadialGradient(g, startCenter: c, startRadius: 0, endCenter: c, endRadius: r, options: [])
    }

    private static func radialOval(_ o: Oval, _ color: NSColor, _ alpha: CGFloat, _ ctx: CGContext) {
        ctx.saveGState()
        ctx.translateBy(x: o.c.x, y: o.c.y)
        ctx.rotate(by: o.angle * .pi / 180)
        ctx.scaleBy(x: o.rx, y: o.ry)
        let g = CGGradient(colorsSpace: sRGB, colors: [color.withAlphaComponent(alpha).cgColor,
                                                       color.withAlphaComponent(alpha * 0.82).cgColor,
                                                       color.withAlphaComponent(alpha * 0.32).cgColor,
                                                       color.withAlphaComponent(0).cgColor] as CFArray,
                           locations: [0, 0.52, 0.80, 1.0])!
        ctx.drawRadialGradient(g, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: 1, options: [])
        ctx.restoreGState()
    }
}

/// Caches one SpriteKit texture per (bunny, pose).
@MainActor
final class BunnyTextures {
    private var cache: [Pose: SKTexture] = [:]
    let look: BunnyLook
    let style: ArtStyle

    init(look: BunnyLook, style: ArtStyle) { self.look = look; self.style = style }

    func texture(_ pose: Pose) -> SKTexture {
        if let t = cache[pose] { return t }
        let t: SKTexture
        if let img = BunnyArtist.image(look, pose, style: style) {
            t = SKTexture(cgImage: img)
        } else {
            t = SKTexture()
        }
        t.filteringMode = .linear
        cache[pose] = t
        return t
    }
}

/// `--render-art <folder> [--art drawn|realistic]`: writes every pose as PNG plus a contact sheet.
enum ArtRenderer {
    static func renderAll(to dir: URL, style: ArtStyle = .drawn) {
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
                guard let img = BunnyArtist.image(look, pose, style: style) else { continue }
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
        print("Wrote \(looks.count * poses.count) \(style.rawValue) poses to \(dir.path)")
    }
}
