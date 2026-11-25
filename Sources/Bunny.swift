import AppKit
import SpriteKit

/// One bunny: its sprite, its needs, and what it decides to do next.
@MainActor
final class Bunny: SKNode {
    enum Activity: String {
        case idle, wander, sit, periscope, loaf, sleep, flop, eat, drink, groom, litter
        case binky, zoomies, waitForHay, waitForWater, visitPartner, petted, accident
        case held, sulk           // picked up with the mouse, then put down
    }

    struct HopStyle {
        var length: CGFloat = 30
        var height: CGFloat = 9
        var duration = 0.26
        var pause: ClosedRange<Double> = 0.08...0.45
        var poops = true
        static let calm = HopStyle()
        static let zoom = HopStyle(length: 64, height: 15, duration: 0.24, pause: 0.0...0.03, poops: false)
    }

    let look: BunnyLook
    let spotIndex: Int
    weak var pen: PenScene?
    weak var partner: Bunny?

    // Needs, 0…1. Higher hunger/thirst/potty = more urgent; energy 1 = full of beans.
    var hunger = Double.random(in: 0.1...0.4)
    var thirst = Double.random(in: 0.05...0.3)
    var potty = Double.random(in: 0.0...0.5)
    var energy = Double.random(in: 0.5...0.9)

    private(set) var activity: Activity = .idle
    private var lastActivity: Activity = .idle
    private var consuming: String?          // "hay" / "water" while actually eating/drinking
    private var steps: [() -> SKAction] = []
    private var facingRight = true
    private var textures: BunnyTextures
    private var shownPose: Pose = .sit
    private let s: CGFloat                  // display scale
    let sprite = SKSpriteNode()
    private let shadow: SKShapeNode
    private let nameTag: SKNode

    init(look: BunnyLook, spotIndex: Int, style: ArtStyle) {
        self.look = look
        self.spotIndex = spotIndex
        textures = BunnyTextures(look: look, style: style)
        s = 0.95 * look.scale
        shadow = SKShapeNode(ellipseOf: CGSize(width: 56 * s, height: 10 * s))
        nameTag = Bubble.pill(look.name, fontSize: 10)
        super.init()

        shadow.fillColor = NSColor(white: 0, alpha: 0.13)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: -3 * s, y: 1)
        shadow.name = "shadow"
        shadow.zPosition = -1
        addChild(shadow)

        sprite.texture = textures.texture(.sit)
        sprite.size = CGSize(width: BunnyArtist.canvas.width * s, height: BunnyArtist.canvas.height * s)
        sprite.anchorPoint = CGPoint(x: 0.5, y: BunnyArtist.groundY / BunnyArtist.canvas.height)
        sprite.name = "body"
        addChild(sprite)

        nameTag.position = CGPoint(x: 0, y: -9)
        nameTag.zPosition = 1
        nameTag.alpha = look.isStandIn ? 0.85 : 0
        addChild(nameTag)
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    var isAsleep: Bool { activity == .sleep || activity == .flop }
    var isResting: Bool { isAsleep || activity == .loaf }
    var isEatingOrDrinking: Bool { consuming != nil }

    // MARK: - Clicks and hover

    func hitTest(_ p: CGPoint) -> Bool {
        CGRect(x: position.x - 34 * s, y: position.y - 4, width: 68 * s, height: 54 * s).contains(p)
    }

    func setHover(_ on: Bool) {
        guard !look.isStandIn else { return }
        nameTag.removeAllActions()
        nameTag.run(.fadeAlpha(to: on ? 1 : 0, duration: 0.15))
    }

    // MARK: - Being picked up

    private(set) var isHeld = false

    /// Lifted with the mouse: stretched out, legs dangling, kicking a little.
    func pickUp() {
        stopEverything()
        steps = []
        lastActivity = activity
        activity = .held
        isHeld = true
        show(.hop)
        sprite.position = CGPoint(x: 0, y: 4)
        sprite.run(.repeatForever(.sequence([.rotate(toAngle: 0.12, duration: 0.18),
                                             .rotate(toAngle: -0.08, duration: 0.18)])), withKey: "kick")
        shadow.isHidden = true
    }

    /// Put down: drops to the floor, thumps in protest a few times, then turns
    /// away and sulks in a loaf right there for a while.
    func putDown(at floorPoint: CGPoint) {
        isHeld = false
        sprite.removeAction(forKey: "kick")
        sprite.zRotation = 0
        sprite.position = .zero
        shadow.isHidden = false
        let fall = position.distance(to: floorPoint)
        let drop: () -> SKAction = { [unowned self] in
            let move = SKAction.move(to: floorPoint, duration: max(0.08, Double(fall) / 700))
            move.timingMode = .easeIn
            return .group([self.pose(.hop), move])
        }
        var thumps: [() -> SKAction] = []
        for _ in 0..<Int.random(in: 2...3) {
            thumps.append({ [unowned self] in
                .sequence([.wait(forDuration: 0.28), self.pose(.thump),
                           self.now { [weak self] in
                               guard let self else { return }
                               self.pen?.puff(at: self.position + CGPoint(x: (self.facingRight ? -14 : 14) * self.s, y: 2))
                           },
                           .wait(forDuration: 0.12), self.pose(.sit)])
            })
        }
        let sulk: [() -> SKAction] = [hold(.sit, 0.4),
                                      call { [weak self] in
                                          guard let self else { return }
                                          self.face(right: !self.facingRight)     // turns away from you
                                      },
                                      loafFor(Double.random(in: 20...45))]
        begin(.sulk, [drop, hold(.land, 0.1), hold(.sit, 0.35)] + thumps + sulk)
    }

    func petted() {
        pen?.hearts(at: CGPoint(x: position.x, y: position.y + 44 * s))
        guard !isAsleep else { return }          // let sleeping bunnies lie
        if activity == .binky || activity == .zoomies { return }
        if Double.random(in: 0...1) < 0.3 {
            begin(.binky, binkySteps(count: 1) + fidgetSteps(2...4))
        } else if !isEatingOrDrinking {
            begin(.petted, [hold(.sitNose, 0.15), hold(.sit, 0.3), hold(.sitNose, 0.15)] + fidgetSteps(2...4))
        }
    }

    /// Called when hay or water is refilled.
    func noticeRefill(hay: Bool) {
        if isAsleep && Bool.random() { return }
        // Already on the way (or eating): don't restart the trip.
        if activity == (hay ? .eat : .drink) || activity == .binky { return }
        let delay = Double.random(in: 0.2...1.5)
        begin(hay ? .eat : .drink, [{ .wait(forDuration: delay) }] + binkySteps(count: Int.random(in: 1...2))
              + (hay ? eatSteps() : drinkSteps()))
    }

    // MARK: - Needs over time

    /// `dt` is in (possibly sped-up) seconds.
    func tick(_ dt: Double) {
        hunger = min(1, hunger + dt / (35 * 60))
        thirst = min(1, thirst + dt / (80 * 60))
        potty = min(1, potty + dt / (40 * 60))
        switch activity {
        case .sleep, .flop: energy = min(1, energy + dt / (8 * 60))
        case .loaf, .sit, .groom, .eat, .drink, .litter: energy = min(1, energy + dt / (60 * 60))
        default: energy = max(0, energy - dt / (15 * 60))
        }
        if consuming == "hay" {
            hunger = max(0, hunger - dt / 30)
            pen?.bunnyAteHay(dt * 0.0005)
        } else if consuming == "water" {
            thirst = max(0, thirst - dt / 5)
            pen?.bunnyDrank(dt * 0.0008)
        }
    }

    // MARK: - Deciding

    func decideNext() {
        guard let pen else { return }
        var next = chooseActivity(pen)
        // Every litter trip has a small chance of not quite making it.
        if next == .litter && Double.random(in: 0...1) < PenModel.litterMissRate { next = .accident }
        begin(next, steps(for: next, pen))
    }

    private func chooseActivity(_ pen: PenScene) -> Activity {
        let m = pen.model
        if potty > 0.85 { return .litter }
        if hunger > 0.6 { return m.hayEmpty ? .waitForHay : .eat }
        if thirst > 0.65 { return m.waterEmpty ? .waitForWater : .drink }
        if energy < 0.25 { return Double.random(in: 0...1) < 0.35 ? .flop : .sleep }
        // Gentle reminders: sometimes go and wait by a low pile or an old bowl.
        if m.hayLow && Double.random(in: 0...1) < 0.15 { return .waitForHay }
        if m.needsWaterAttention() && Double.random(in: 0...1) < 0.12 { return .waitForWater }

        let lively = pen.liveliness
        var options: [(Activity, Double)] = [
            (.wander, 26 * lively),
            (.sit, 14),
            (.periscope, 4),
            (.loaf, 16 * (1.4 - lively)),
            (.groom, 9),
            (.eat, m.hayEmpty ? 0 : 3 + 10 * hunger),
            (.drink, m.waterEmpty ? 0 : 1 + 6 * thirst),
            (.flop, energy < 0.7 ? 5 : 1),
            (.sleep, 2 + (1 - energy) * 14 * (1.4 - lively)),
            (.binky, 4 * lively * energy),
            (.zoomies, 2 * lively * energy),
            (.visitPartner, partner == nil ? 0 : 7),
            (.litter, potty > 0.4 ? 6 * potty : 0),
        ]
        // Don't do the same calm thing twice in a row.
        options = options.map { $0.0 == lastActivity && $0.0 != .wander ? ($0.0, $0.1 * 0.2) : $0 }
        let total = options.reduce(0) { $0 + $1.1 }
        var r = Double.random(in: 0..<max(total, 0.001))
        for (a, w) in options {
            r -= w
            if r <= 0 { return a }
        }
        return .sit
    }

    private func steps(for a: Activity, _ pen: PenScene) -> [() -> SKAction] {
        switch a {
        case .wander:
            return [go(pen.randomFloorPoint(near: position))] + fidgetSteps(1...4)
        case .sit, .idle, .petted, .held, .sulk:
            return fidgetSteps(4...12)
        case .periscope:
            return [hold(.periscope, Double.random(in: 1.5...4)), hold(.sit, 0.4)] + fidgetSteps(1...3)
        case .loaf:
            return [loafFor(Double.random(in: 20...80))]
        case .sleep:
            var st: [() -> SKAction] = []
            if let spot = sleepSpot(pen) { st.append(go(spot.0)); st.append(faceStep(spot.1)) }
            return st + [hold(.loaf, 2), sleepFor(Double.random(in: 60...240), flopped: false)]
        case .flop:
            return [hold(.loaf, Double.random(in: 1...3)), flopDown(), sleepFor(Double.random(in: 60...200), flopped: true)]
        case .eat:
            return eatSteps()
        case .drink:
            return drinkSteps()
        case .groom:
            return [groomFor(Double.random(in: 4...9))] + fidgetSteps(1...2)
        case .litter:
            return [go(pen.litterSpot(spotIndex)), faceStep(Bool.random()), litterFor(Double.random(in: 15...35))]
        case .accident:
            // Didn't make it to the box. It happens.
            return [hold(.loaf, 3), call { [weak self] in
                guard let self else { return }
                let tail = self.position + CGPoint(x: (self.facingRight ? -26 : 26) * self.s, y: 0)
                self.pen?.dropPoops(at: tail, count: Int.random(in: 2...4))
                if Double.random(in: 0...1) < 0.25 {
                    self.pen?.dropPee(at: self.position + CGPoint(x: (self.facingRight ? -16 : 16) * self.s, y: 2))
                }
                self.potty = 0
            }] + fidgetSteps(2...4)
        case .binky:
            return binkySteps(count: Int.random(in: 1...3)) + fidgetSteps(1...3)
        case .zoomies:
            var st: [() -> SKAction] = []
            for _ in 0..<Int.random(in: 3...5) { st.append(go(pen.randomFloorPoint(near: nil), .zoom)) }
            return st + binkySteps(count: 1) + fidgetSteps(2...4)
        case .waitForHay:
            let (spot, right) = pen.hayEatSpot(spotIndex)
            return [go(spot), faceStep(right), waitAndThump(Double.random(in: 12...25))]
        case .waitForWater:
            let (spot, right) = pen.drinkSpot(spotIndex)
            return [go(spot), faceStep(right), waitAndThump(Double.random(in: 12...25))]
        case .visitPartner:
            guard let partner else { return fidgetSteps(3...6) }
            let side: CGFloat = partner.position.x > pen.size.width / 2 ? -1 : 1
            let target = pen.clampToFloor(partner.position + CGPoint(x: side * 46 * s, y: CGFloat.random(in: -6...6)))
            return [go(target), call { [weak self] in
                guard let self, let p = self.partner else { return }
                self.face(right: p.position.x > self.position.x)
            }, groomFor(Double.random(in: 4...8), withHearts: true)] + fidgetSteps(1...3)
        }
    }

    private func sleepSpot(_ pen: PenScene) -> (CGPoint, Bool)? {
        // Cuddle up next to a resting partner most of the time.
        if let p = partner, p.isResting, Double.random(in: 0...1) < 0.7 {
            let side: CGFloat = p.position.x > pen.size.width / 2 ? -1 : 1
            return (pen.clampToFloor(p.position + CGPoint(x: side * 44 * s, y: -4)), side < 0)
        }
        if Double.random(in: 0...1) < 0.4 { return (pen.randomFloorPoint(near: nil), Bool.random()) }
        return nil
    }

    // MARK: - Running steps

    private func begin(_ a: Activity, _ newSteps: [() -> SKAction]) {
        stopEverything()
        lastActivity = activity
        activity = a
        Log.debug("\(look.name) → \(a.rawValue)  (hunger \(fmt(hunger)) thirst \(fmt(thirst)) potty \(fmt(potty)) energy \(fmt(energy)))")
        steps = newSteps
        advance()
    }

    private func fmt(_ v: Double) -> String { String(format: "%.2f", v) }

    private func advance() {
        guard !steps.isEmpty else {
            decideNext()
            return
        }
        let make = steps.removeFirst()
        run(.sequence([make(), now { [weak self] in self?.advance() }]), withKey: "activity")
    }

    private func stopEverything() {
        removeAction(forKey: "activity")
        sprite.removeAllActions()
        sprite.position = .zero
        sprite.zRotation = 0
        sprite.yScale = 1
        sprite.xScale = facingRight ? 1 : -1
        shadow.removeAllActions()
        shadow.setScale(1)
        consuming = nil
    }

    // MARK: - Step builders

    private func call(_ f: @escaping @MainActor () -> Void) -> () -> SKAction {
        { .run { MainActor.assumeIsolated { f() } } }
    }

    private func now(_ f: @escaping @MainActor () -> Void) -> SKAction {
        .run { MainActor.assumeIsolated { f() } }
    }

    /// Looks the texture up when it's shown, so switching art style takes effect right away.
    private func pose(_ p: Pose) -> SKAction {
        now { [weak self] in self?.show(p) }
    }

    private func show(_ p: Pose) {
        shownPose = p
        sprite.texture = textures.texture(p)
    }

    /// Drawn or realistic artwork, swapped in place.
    func setArtStyle(_ style: ArtStyle) {
        guard style != textures.style else { return }
        textures = BunnyTextures(look: look, style: style)
        show(shownPose)
    }

    private func hold(_ p: Pose, _ seconds: Double) -> () -> SKAction {
        { [unowned self] in .sequence([self.pose(p), .wait(forDuration: seconds)]) }
    }

    private func faceStep(_ right: Bool) -> () -> SKAction {
        call { [weak self] in self?.face(right: right) }
    }

    func face(right: Bool) {
        facingRight = right
        sprite.xScale = right ? 1 : -1
        shadow.position.x = (right ? -3 : 3) * s
    }

    private func go(_ target: CGPoint, _ style: HopStyle = .calm) -> () -> SKAction {
        { [unowned self] in self.hops(to: target, style) }
    }

    private func hops(to target: CGPoint, _ style: HopStyle) -> SKAction {
        let start = position
        let dist = start.distance(to: target)
        guard dist > 3 else { return .wait(forDuration: 0.05) }
        let n = max(1, Int(ceil(dist / (style.length * s / 0.82))))
        let step = CGVector(dx: (target.x - start.x) / CGFloat(n), dy: (target.y - start.y) / CGFloat(n))
        var actions: [SKAction] = []
        if abs(target.x - start.x) > 4 { actions.append(now { [weak self] in self?.face(right: target.x > start.x) }) }
        let h = style.height * s
        let up = SKAction.moveBy(x: 0, y: h, duration: style.duration / 2)
        up.timingMode = .easeOut
        let down = SKAction.moveBy(x: 0, y: -h, duration: style.duration / 2)
        down.timingMode = .easeIn
        let arc = SKAction.run(.sequence([up, down]), onChildWithName: "body")
        let shadowPulse = SKAction.run(.sequence([.scale(to: 0.72, duration: style.duration / 2),
                                                  .scale(to: 1, duration: style.duration / 2)]),
                                       onChildWithName: "shadow")
        for _ in 0..<n {
            actions.append(pose(.crouch))
            actions.append(.wait(forDuration: 0.05))
            actions.append(.group([pose(.hop), arc, shadowPulse, .move(by: step, duration: style.duration)]))
            actions.append(pose(.land))
            actions.append(.wait(forDuration: 0.06))
            actions.append(pose(.sit))
            actions.append(now { [weak self] in self?.pen?.countHop() })
            if style.poops { actions.append(now { [weak self] in self?.maybeDropPoop() }) }
            let pause = Double.random(in: style.pause)
            if pause > 0.01 { actions.append(.wait(forDuration: pause)) }
        }
        return .sequence(actions)
    }

    /// Sitting and looking around: nose wiggles, ear twitches, the odd periscope.
    private func fidgetSteps(_ seconds: ClosedRange<Double>) -> [() -> SKAction] {
        [{ [unowned self] in
            var total = Double.random(in: seconds)
            var acts: [SKAction] = [self.pose(.sit)]
            while total > 0 {
                let wait = Double.random(in: 0.6...2.2)
                acts.append(.wait(forDuration: wait))
                total -= wait
                switch Int.random(in: 0..<10) {
                case 0..<5:
                    for _ in 0..<Int.random(in: 2...4) {
                        acts += [self.pose(.sitNose), .wait(forDuration: 0.1), self.pose(.sit), .wait(forDuration: 0.1)]
                    }
                case 5..<8:
                    acts += [self.pose(.sitEarTwitch), .wait(forDuration: 0.25), self.pose(.sit)]
                case 8:
                    acts += [self.pose(.periscope), .wait(forDuration: 1.2), self.pose(.sit)]
                default:
                    acts.append(self.now { [weak self] in
                        guard let self else { return }
                        self.face(right: !self.facingRight)
                    })
                }
            }
            return .sequence(acts)
        }]
    }

    private var startBreathing: SKAction {
        now { [weak self] in
            self?.sprite.run(.repeatForever(.sequence([.scaleY(to: 0.975, duration: 1.4), .scaleY(to: 1, duration: 1.4)])),
                             withKey: "breath")
        }
    }

    private var stopBreathing: SKAction {
        now { [weak self] in
            self?.sprite.removeAction(forKey: "breath")
            self?.sprite.yScale = 1
        }
    }

    private func loafFor(_ seconds: Double) -> () -> SKAction {
        { [unowned self] in .sequence([self.pose(.loaf), self.startBreathing, .wait(forDuration: seconds), self.stopBreathing]) }
    }

    private func sleepFor(_ seconds: Double, flopped: Bool) -> () -> SKAction {
        { [unowned self] in
            let zzz = SKAction.repeat(.sequence([.wait(forDuration: 2.6), self.now { [weak self] in
                guard let self else { return }
                let dx: CGFloat = (self.facingRight ? 20 : -20) * self.s
                self.pen?.zzz(at: self.position + CGPoint(x: dx, y: (flopped ? 26 : 40) * self.s))
            }]), count: max(1, Int(seconds / 2.6)))
            return .sequence([self.pose(flopped ? .flop : .sleep), self.startBreathing, zzz, self.stopBreathing,
                              self.pose(flopped ? .flop : .loaf), .wait(forDuration: 1.5)])
        }
    }

    private func flopDown() -> () -> SKAction {
        { [unowned self] in
            let tilt = SKAction.run(.sequence([.rotate(toAngle: -0.28, duration: 0.14), .rotate(toAngle: 0, duration: 0.06)]),
                                    onChildWithName: "body")
            return .sequence([self.pose(.sit), .wait(forDuration: 0.2), tilt, .wait(forDuration: 0.14), self.pose(.flop),
                              .wait(forDuration: 0.3)])
        }
    }

    private func groomFor(_ seconds: Double, withHearts: Bool = false) -> () -> SKAction {
        { [unowned self] in
            var acts: [SKAction] = []
            var t = seconds
            while t > 0 {
                acts += [self.pose(.groom), .wait(forDuration: 0.35), self.pose(.groomB), .wait(forDuration: 0.35)]
                t -= 0.7
            }
            if withHearts {
                acts.insert(self.now { [weak self] in
                    guard let self else { return }
                    self.pen?.hearts(at: self.position + CGPoint(x: 0, y: 48 * self.s))
                }, at: min(4, acts.count))
            }
            return .sequence(acts + [self.pose(.sit)])
        }
    }

    func eatSteps() -> [() -> SKAction] {
        guard let pen else { return [] }
        let (spot, right) = pen.hayEatSpot(spotIndex)
        return [go(spot), faceStep(right), chewFor(Double.random(in: 15...40), what: "hay")] + fidgetSteps(1...3)
    }

    func drinkSteps() -> [() -> SKAction] {
        guard let pen else { return [] }
        let (spot, right) = pen.drinkSpot(spotIndex)
        return [go(spot), faceStep(right), chewFor(Double.random(in: 4...9), what: "water")] + fidgetSteps(1...3)
    }

    private func chewFor(_ seconds: Double, what: String) -> () -> SKAction {
        { [unowned self] in
            guard let pen = self.pen else { return .wait(forDuration: 0.1) }
            let empty = what == "hay" ? pen.model.hayEmpty : pen.model.waterEmpty
            if empty { return self.waitAndThump(12)() }
            self.consuming = what
            let chew = SKAction.repeat(.sequence([self.pose(.eat), .wait(forDuration: 0.18),
                                                  self.pose(.eatChew), .wait(forDuration: 0.18)]),
                                       count: max(1, Int(seconds / 0.36)))
            return .sequence([chew, self.now { [weak self] in self?.consuming = nil }, self.pose(.sit)])
        }
    }

    private func litterFor(_ seconds: Double) -> () -> SKAction {
        { [unowned self] in
            .sequence([self.pose(.loaf), .wait(forDuration: seconds * 0.6),
                       self.now { [weak self] in
                           guard let self else { return }
                           self.pen?.litterUsed(poops: Int.random(in: 2...5), pee: Double.random(in: 0...1) < 0.5)
                           self.potty = 0
                       },
                       self.pose(.sit), .wait(forDuration: seconds * 0.4)])
        }
    }

    /// Sit by the empty hay/bowl and thump now and then: the in-app reminder.
    private func waitAndThump(_ seconds: Double) -> () -> SKAction {
        { [unowned self] in
            var acts: [SKAction] = [self.pose(.sit)]
            var t = seconds
            while t > 0 {
                let wait = Double.random(in: 1.8...3.5)
                acts += [.wait(forDuration: wait), self.pose(.thump),
                         self.now { [weak self] in
                             guard let self else { return }
                             self.pen?.puff(at: self.position + CGPoint(x: (self.facingRight ? -14 : 14) * self.s, y: 2))
                         },
                         .wait(forDuration: 0.12), self.pose(.sit)]
                if Bool.random() { acts += [.wait(forDuration: 0.3), self.pose(.periscope), .wait(forDuration: 0.9), self.pose(.sit)] }
                t -= wait + 0.5
            }
            return .sequence(acts)
        }
    }

    private func binkySteps(count: Int) -> [() -> SKAction] {
        (0..<count).map { _ in
            { [unowned self] in
                let h = CGFloat.random(in: 26...38) * self.s
                let up = SKAction.moveBy(x: 0, y: h, duration: 0.22)
                up.timingMode = .easeOut
                let down = SKAction.moveBy(x: 0, y: -h, duration: 0.22)
                down.timingMode = .easeIn
                let twist = SKAction.sequence([.rotate(toAngle: 0.45, duration: 0.1), .rotate(toAngle: -0.45, duration: 0.14),
                                               .rotate(toAngle: 0, duration: 0.1)])
                let dir: CGFloat = self.facingRight ? 1 : -1
                let target = self.pen?.clampToFloor(self.position + CGPoint(x: dir * 22 * self.s, y: 0)) ?? self.position
                let flip = Bool.random()
                return .sequence([
                    self.pose(.crouch), .wait(forDuration: 0.08),
                    .group([self.pose(.hop),
                            .run(.sequence([up, down]), onChildWithName: "body"),
                            .run(twist, onChildWithName: "body"),
                            .run(.sequence([.scale(to: 0.6, duration: 0.22), .scale(to: 1, duration: 0.22)]), onChildWithName: "shadow"),
                            .move(to: target, duration: 0.44),
                            .sequence([.wait(forDuration: 0.2), self.now { [weak self] in
                                guard let self, flip else { return }
                                self.face(right: !self.facingRight)
                            }])]),
                    self.pose(.land), .wait(forDuration: 0.08), self.pose(.sit), .wait(forDuration: Double.random(in: 0.2...0.6)),
                ])
            }
        }
    }

    /// The odd stray poop while hopping. Doesn't count as a litter trip.
    private func maybeDropPoop() {
        guard Double.random(in: 0...1) < PenModel.strayPoopChancePerHop else { return }
        let tail = position + CGPoint(x: (facingRight ? -26 : 26) * s, y: CGFloat.random(in: -2...3))
        pen?.dropPoops(at: tail, count: Int.random(in: 1...2))
    }

    /// The platform was dragged: a trip to the hay, water or litter box was
    /// planned to where it used to be, so start that trip again.
    func platformMoved() {
        guard let pen else { return }
        let spot: CGPoint
        switch activity {
        case .eat, .waitForHay: spot = pen.hayEatSpot(spotIndex).0
        case .drink, .waitForWater: spot = pen.drinkSpot(spotIndex).0
        case .litter: spot = pen.litterSpot(spotIndex)
        default: return
        }
        if position.distance(to: spot) > 6 { begin(activity, steps(for: activity, pen)) }
    }

    /// Test runs: make the bunny do a specific thing now.
    func force(_ a: Activity) {
        guard let pen else { return }
        if a == .petted { petted(); return }
        begin(a, steps(for: a, pen))
    }
}
