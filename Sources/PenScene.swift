import AppKit
import SpriteKit

/// The whole bunny world: it covers the usable screen area, with the litter
/// box corner at the lower left.
@MainActor
final class PenScene: SKScene {
    let options: LaunchOptions
    var model = PenModel()
    var onChange: (() -> Void)?
    var onMenuRequest: ((CGPoint) -> Void)?
    /// Where poops ended up this session (for checking litter habits).
    private(set) var tally = (box: 0, floor: 0, hops: 0)
    private var clock: Timer?
    private var lastClockTick = Date()

    private let store: PenStore
    private let corner = CornerNode()
    private let reminders = Reminders()
    private(set) var bunnies: [Bunny] = []
    private var floorPoops: [SKSpriteNode] = []
    private var peeSpots: [SKSpriteNode] = []
    private let poopTexture = PropArt.poop()
    private let peeTexture = PropArt.pee()
    private var didSetUp = false
    private var lastFrameTime: TimeInterval = 0
    private var lastSave = Date()
    private var lastAttention = false
    private var hoveredKey: ObjectIdentifier?
    private var awayHours: Double = 0

    init(size: CGSize, options: LaunchOptions) {
        self.options = options
        self.store = PenStore(directory: options.stateDir)
        super.init(size: size)
        anchorPoint = .zero
        backgroundColor = .clear
        if let saved = store.load() {
            model = saved
            let away = Date().timeIntervalSince(saved.lastUpdate)
            if away > 20 * 60 { awayHours = away / 3600 }
        }
        model.advance(to: Date())
        if let art = options.artStyle { model.artStyle = art }     // test runs
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    // MARK: - Setup

    override func didMove(to view: SKView) {
        guard !didSetUp else { return }
        didSetUp = true
        addChild(corner)
        sortPlatformItems()

        let snoopy = Bunny(look: .snoopy, spotIndex: 0, style: artStyle)
        let bambi = Bunny(look: .bambi, spotIndex: 1, style: artStyle)
        snoopy.partner = bambi
        bambi.partner = snoopy
        let fp = corner.footprint, f = floorRect
        let startLeft = fp.minX - f.minX >= f.maxX - fp.maxX      // whichever side of the platform has more room
        for (i, b) in [snoopy, bambi].enumerated() {
            b.pen = self
            let x = startLeft ? fp.minX - 60 - CGFloat(i) * 70 : fp.maxX + 60 + CGFloat(i) * 70
            b.position = clampToFloor(CGPoint(x: x, y: 30 + CGFloat(i) * 26))
            b.face(right: i == 1 ? false : true)
            addChild(b)
            bunnies.append(b)
        }

        for spot in model.floorPoops { addPoopSprite(at: fromSpot(spot)) }
        for spot in model.peeSpots { addPeeSprite(at: fromSpot(spot)) }
        catchUpOnAwayTime()
        corner.sync(with: model, now: Date())
        if model.notificationsOn { reminders.attach() }

        // Stagger their first decisions a little.
        for (i, b) in bunnies.enumerated() {
            b.run(.sequence([.wait(forDuration: 0.5 + Double(i) * 1.2), .run { MainActor.assumeIsolated { b.decideNext() } }]))
        }
        lastAttention = model.needsAttention()
        onChange?()
        save()

        // Test runs can fast-forward the bunnies' movements too.
        speed = CGFloat(options.speed)
        // Needs, hay, water and reminders tick on a plain timer, so they keep
        // going while the bunnies are hidden or the screen is asleep.
        lastClockTick = Date()
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                let now = Date()
                self.secondTick(min(now.timeIntervalSince(self.lastClockTick), 5))
                self.lastClockTick = now
            }
        }
        RunLoop.main.add(t, forMode: .common)
        clock = t
        if let dir = options.tourDir { runTour(snapshotsTo: dir) }
    }

    private func catchUpOnAwayTime() {
        guard awayHours > 0 else { return }
        let inBox = min(Int(awayHours * 8), 120)
        let escaped = min(Int(awayHours * 0.5), 8)
        model.litterPoops += inBox
        for _ in 0..<escaped {
            let p = randomFloorPoint(near: nil)
            for _ in 0..<Int.random(in: 1...2) { addPoop(at: p + CGPoint(x: .random(in: -5...5), y: .random(in: -4...4))) }
        }
        let hours = awayHours < 1.5 ? "\(Int(awayHours * 60)) min" : "\(Int(awayHours.rounded())) h"
        var text = "While you were away (\(hours)):"
        text += escaped > 0 ? " a few poops escaped the litter box." : " all poops made it to the litter box!"
        Log.info(text)
        toast(text)
    }

    /// Depth from how far down the screen something stands (lower = nearer).
    func depth(atY y: CGFloat) -> CGFloat { 100 + (1 - y / max(size.height, 1)) * 100 }

    private func sortPlatformItems() {
        corner.layout(width: size.width, shift: CGFloat(model.platformShift))
        model.platformShift = Double(corner.shift)
        for (node, y) in corner.depthSorted { node.zPosition = depth(atY: y) }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard didSetUp else { return }
        sortPlatformItems()
        // New area: everyone back inside it, and rethink any trip that's now out of bounds.
        for b in bunnies { b.position = clampToFloor(b.position); b.decideNext() }
        for p in floorPoops { p.position = clampToFloor(p.position) }
    }

    // MARK: - Geometry helpers used by the bunnies

    var floorRect: CGRect {
        // Along the bottom: feet stay in a band ~90 pt deep, so there's still
        // room to be in front of, beside, or behind the platform.
        let depth: CGFloat = model.bottomOnly ? min(88, max(40, size.height - 160)) : max(100, size.height - 90)
        return CGRect(x: 40, y: 18, width: max(100, size.width - 80), height: depth)
    }

    func clampToFloor(_ p: CGPoint) -> CGPoint {
        let f = floorRect
        return CGPoint(x: min(max(p.x, f.minX), f.maxX), y: min(max(p.y, f.minY), f.maxY))
    }

    func randomFloorPoint(near: CGPoint?) -> CGPoint {
        let f = floorRect
        let avoid = corner.footprint.insetBy(dx: -12, dy: -12)
        for _ in 0..<25 {
            var p: CGPoint
            if let near, model.bottomOnly {
                // Mostly left and right along the strip.
                let dx = CGFloat.random(in: 100...560) * (Bool.random() ? 1 : -1)
                p = CGPoint(x: near.x + dx, y: .random(in: f.minY...f.maxY))
            } else if let near {
                let a = CGFloat.random(in: 0..<(2 * .pi))
                let d = CGFloat.random(in: 120...480)
                p = near + CGPoint(x: cos(a) * d, y: sin(a) * d * 0.7)
            } else {
                p = CGPoint(x: .random(in: f.minX...f.maxX), y: .random(in: f.minY...f.maxY))
            }
            p = clampToFloor(p)
            if !avoid.contains(p) { return p }
        }
        let roomLeft = avoid.minX - f.minX >= f.maxX - avoid.maxX
        return clampToFloor(CGPoint(x: roomLeft ? avoid.minX - 40 : avoid.maxX + 40, y: 30))
    }

    func hayEatSpot(_ i: Int) -> (CGPoint, Bool) { corner.hayEatSpots[i % corner.hayEatSpots.count] }
    func drinkSpot(_ i: Int) -> (CGPoint, Bool) { corner.drinkSpots[i % corner.drinkSpots.count] }
    func litterSpot(_ i: Int) -> CGPoint { corner.litterSpots[i % corner.litterSpots.count] }

    var liveliness: Double {
        // Rabbits are most active around dawn and dusk.
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<9, 17..<22: return 1.0
        case 9..<12, 14..<17: return 0.6
        case 12..<14: return 0.45
        default: return 0.35
        }
    }

    // MARK: - Things bunnies do to the world

    func countHop() { tally.hops += 1 }

    func bunnyAteHay(_ amount: Double) { model.hay = max(0, model.hay - amount) }
    func bunnyDrank(_ amount: Double) { model.water = max(0, model.water - amount) }

    func litterUsed(poops: Int, pee: Bool) {
        tally.box += poops
        model.litterPoops += poops
        if pee { model.litterPee += 1 }
        corner.sync(with: model, now: Date())
    }

    func dropPoops(at p: CGPoint, count: Int) {
        if corner.litterArea.contains(p) {
            litterUsed(poops: count, pee: false)
            return
        }
        tally.floor += count
        for _ in 0..<count {
            addPoop(at: p + CGPoint(x: .random(in: -5...5), y: .random(in: -3...3)))
        }
    }

    func dropPee(at p: CGPoint) {
        guard peeSpots.count < PenModel.maxPeeSpots else { return }
        addPeeSprite(at: clampToFloor(p))
        syncFloorToModel()
    }

    private func addPoop(at p: CGPoint) {
        guard floorPoops.count < PenModel.maxFloorPoops else { return }
        addPoopSprite(at: clampToFloor(p))
        syncFloorToModel()
    }

    private func addPoopSprite(at p: CGPoint) {
        let n = SKSpriteNode(texture: poopTexture)
        n.size = CGSize(width: 9, height: 9)
        n.position = p
        n.zPosition = 20
        addChild(n)
        floorPoops.append(n)
    }

    private func addPeeSprite(at p: CGPoint) {
        let n = SKSpriteNode(texture: peeTexture)
        n.size = CGSize(width: 26, height: 14)
        n.position = p
        n.zPosition = 15
        addChild(n)
        peeSpots.append(n)
    }

    private func toSpot(_ p: CGPoint) -> Spot { Spot(x: Double(p.x / max(size.width, 1)), y: Double(p.y / max(size.height, 1))) }
    private func fromSpot(_ s: Spot) -> CGPoint { clampToFloor(CGPoint(x: CGFloat(s.x) * size.width, y: CGFloat(s.y) * size.height)) }

    private func syncFloorToModel() {
        model.floorPoops = floorPoops.map { toSpot($0.position) }
        model.peeSpots = peeSpots.map { toSpot($0.position) }
    }

    // MARK: - Your buttons

    func addHay() {
        model.refillHay()
        corner.feedbackRefillHay()
        for b in bunnies where Double.random(in: 0...1) < 0.75 { b.noticeRefill(hay: true) }
        afterCare("Added hay.")
    }

    func freshWater() {
        model.refreshWater()
        corner.feedbackFreshWater()
        for b in bunnies where Double.random(in: 0...1) < 0.4 { b.noticeRefill(hay: false) }
        afterCare("Fresh water.")
    }

    func cleanUpEverything() {
        for (i, p) in (floorPoops + peeSpots).enumerated() {
            p.run(.sequence([.wait(forDuration: Double(i) * 0.04), .group([.scale(to: 0.1, duration: 0.2), .fadeOut(withDuration: 0.2)]),
                             .removeFromParent()]))
            if i % 3 == 0 { sparkle(at: p.position) }
        }
        floorPoops.removeAll()
        peeSpots.removeAll()
        if model.litterPoops > 0 {
            sparkle(at: corner.litterArea.origin + CGPoint(x: 45, y: 34))
            sparkle(at: corner.litterArea.origin + CGPoint(x: 95, y: 30))
        }
        model.litterPoops = 0
        model.litterPee = 0
        syncFloorToModel()
        afterCare("Cleaned up.")
    }

    private func afterCare(_ what: String) {
        Log.info(what)
        corner.sync(with: model, now: Date())
        checkAttention()
        save()
    }

    /// The art the bunnies are wearing right now.
    var artStyle: ArtStyle { ArtStyle.resolve(model.artStyle) }

    func setArtStyle(_ style: ArtStyle) {
        model.artStyle = style.rawValue
        for b in bunnies { b.setArtStyle(artStyle) }
        save()
        Log.info("Art style: \(artStyle.rawValue).")
    }

    func setNotifications(_ on: Bool) {
        if on {
            reminders.enable { [weak self] granted in
                guard let self else { return }
                self.model.notificationsOn = granted
                Log.info(granted ? "Reminder notifications on." : "Notifications weren't allowed; in-app reminders only.")
                if !granted { self.toast("Notifications are off in System Settings, so reminders stay in the pen.") }
                self.save()
            }
        } else {
            model.notificationsOn = false
            save()
        }
    }

    // MARK: - Status for the menu bar

    var needsAttention: Bool { model.needsAttention() }

    func statusLines() -> [String] {
        let now = Date()
        func pct(_ v: Double) -> String { "\(Int((v * 100).rounded()))%" }
        var lines = [
            "🌾 Hay: \(pct(model.hay)), added \(Ago.describe(now.timeIntervalSince(model.lastHayRefill)))"
                + (model.hayLow ? " · running low" : ""),
            "💧 Water: \(pct(model.water)), changed \(Ago.describe(now.timeIntervalSince(model.lastWaterRefill)))"
                + (model.needsWaterAttention(at: now) ? " · time for fresh water" : ""),
            "💩 On the floor: \(floorPoops.count) · in the litter box: \(model.litterPoops)"
                + (model.litterNeedsCleaning ? " · needs a clean" : ""),
        ]
        for b in bunnies { lines.append("\(b.look.name) is \(describe(b))") }
        return lines
    }

    private func describe(_ b: Bunny) -> String {
        switch b.activity {
        case .idle, .sit: return "sitting"
        case .wander: return "hopping around"
        case .periscope: return "standing tall, looking around"
        case .loaf: return "loafing"
        case .sleep: return "sleeping"
        case .flop: return "flopped over, very relaxed"
        case .eat: return "eating hay"
        case .drink: return "drinking"
        case .groom: return "grooming"
        case .litter: return "in the litter box"
        case .binky: return "doing binkies!"
        case .zoomies: return "doing zoomies!"
        case .waitForHay: return "waiting for hay"
        case .waitForWater: return "waiting by the water bowl"
        case .visitPartner: return "snuggling \(b.partner?.look.name ?? "a friend")"
        case .petted: return "enjoying pets"
        case .accident: return "having a little accident"
        case .held: return "being carried (not a fan)"
        case .sulk: return "sulking after being picked up"
        }
    }

    // MARK: - Clock

    override func update(_ currentTime: TimeInterval) {
        lastFrameTime = currentTime
        // Nearer the bottom of the screen = in front.
        for b in bunnies { b.zPosition = b.isHeld ? 450 : depth(atY: b.position.y) }
    }

    private func secondTick(_ seconds: TimeInterval) {
        let now = Date()
        model.advance(to: now, speed: options.speed)
        for b in bunnies { b.tick(seconds * options.speed) }
        corner.sync(with: model, now: now)
        reminders.check(&model, now: now)
        checkAttention()
        if now.timeIntervalSince(lastSave) > 30 { save() }
        // Save battery: fewer frames while everyone is resting.
        let calm = bunnies.allSatisfy { $0.isResting }
        let fps = calm ? 15 : 30
        if let view, view.preferredFramesPerSecond != fps { view.preferredFramesPerSecond = fps }
    }

    private func checkAttention() {
        let a = model.needsAttention()
        if a != lastAttention {
            lastAttention = a
            onChange?()
        }
    }

    func save() {
        syncFloorToModel()
        store.save(model)
        lastSave = Date()
    }

    // MARK: - Mouse

    private enum Target {
        case button(PenButton), poop(Int), pee(Int), bunny(Bunny), platform

        var key: ObjectIdentifier? {
            switch self {
            case .button(let b): return ObjectIdentifier(b)
            case .bunny(let b): return ObjectIdentifier(b)
            case .poop, .pee, .platform: return nil
            }
        }
    }

    private func target(at p: CGPoint) -> Target? {
        for b in corner.buttons where b.contains(scenePoint: p) { return .button(b) }
        var best: (Int, CGFloat)?
        for (i, poop) in floorPoops.enumerated() {
            let d = poop.position.distance(to: p)
            if d <= 7, d < (best?.1 ?? .infinity) { best = (i, d) }
        }
        if let best { return .poop(best.0) }
        for b in bunnies.sorted(by: { $0.zPosition > $1.zPosition }) where b.hitTest(p) { return .bunny(b) }
        if let i = peeSpots.firstIndex(where: { $0.frame.insetBy(dx: 2, dy: 1).contains(p) }) { return .pee(i) }
        if corner.grabContains(p) { return .platform }
        return nil
    }

    /// While a bunny or the platform is being dragged, keep catching the mouse
    /// even if the cursor slips off it for a moment.
    func isInteractive(at p: CGPoint) -> Bool {
        draggedBunny != nil || pressedBunny != nil || platformPress != nil || target(at: p) != nil
    }

    func hover(at p: CGPoint?) {
        let key = p.flatMap { target(at: $0)?.key }
        guard key != hoveredKey else { return }
        for b in corner.buttons { b.setHover(ObjectIdentifier(b) == key) }
        for b in bunnies { b.setHover(ObjectIdentifier(b) == key) }
        hoveredKey = key
    }

    // A press on a bunny becomes a pet (click) or a pick-up (drag).
    private var pressedBunny: Bunny?
    private var pressPoint = CGPoint.zero
    private var grabOffset = CGPoint.zero
    private var draggedBunny: Bunny?

    // A press on the platform slides it left and right once the mouse moves.
    private var platformPress: (point: CGPoint, shift: CGFloat)?
    private var platformDragging = false
    private var platformRiders: [SKNode] = []

    override func mouseDragged(with event: NSEvent) {
        let p = event.location(in: self)
        if let press = platformPress {
            if !platformDragging, abs(p.x - press.point.x) > 3 { beginPlatformDrag() }
            if platformDragging { movePlatform(toShift: press.shift - (p.x - press.point.x)) }
            return
        }
        if draggedBunny == nil, let b = pressedBunny, p.distance(to: pressPoint) > 4 {
            draggedBunny = b
            b.pickUp()
            Log.info("Picked up \(b.look.name).")
        }
        guard let b = draggedBunny else { return }
        let feet = p + grabOffset
        b.position = CGPoint(x: min(max(feet.x, 20), size.width - 20), y: min(max(feet.y, 0), size.height - 70))
    }

    override func mouseUp(with event: NSEvent) {
        defer { pressedBunny = nil; draggedBunny = nil; platformPress = nil }
        if platformDragging {
            endPlatformDrag()
        } else if let b = draggedBunny {
            let spot = clampToFloor(b.position)
            Log.info("Put \(b.look.name) down at (\(Int(spot.x)), \(Int(spot.y))).")
            b.putDown(at: spot)
        } else if let b = pressedBunny {
            Log.info("Petted \(b.look.name).")
            b.petted()
        }
    }

    override func mouseDown(with event: NSEvent) {
        let p = event.location(in: self)
        let front = NSWorkspace.shared.frontmostApplication?.localizedName ?? "?"
        guard let t = target(at: p) else {
            Log.info("Click at (\(Int(p.x)), \(Int(p.y))) hit nothing (front app: \(front))")
            return
        }
        switch t {
        case .button(let b):
            Log.info("Clicked the \(b.id) button (front app stays: \(front))")
            b.pressed()
            switch b.id {
            case "hay": addHay()
            case "water": freshWater()
            case "menu": onMenuRequest?(b.position)
            default: cleanUpEverything()
            }
        case .poop(let i):
            let n = floorPoops.remove(at: i)
            sparkle(at: n.position)
            n.run(.sequence([.group([.scale(to: 0.1, duration: 0.15), .fadeOut(withDuration: 0.15)]), .removeFromParent()]))
            syncFloorToModel()
            Log.info("Cleaned a poop (front app stays: \(front)). \(floorPoops.count) left on the floor.")
            save()
        case .pee(let i):
            let n = peeSpots.remove(at: i)
            sparkle(at: n.position)
            n.run(.sequence([.fadeOut(withDuration: 0.2), .removeFromParent()]))
            syncFloorToModel()
            Log.info("Wiped up a pee spot.")
            save()
        case .bunny(let b):
            // Wait for mouse-up: a click pets, a drag picks the bunny up.
            pressedBunny = b
            pressPoint = p
            grabOffset = b.position - p
        case .platform:
            // Wait for the mouse to move: then it slides.
            platformPress = (p, corner.shift)
        }
    }

    // MARK: - Moving the platform

    /// Bunnies, poops and pee on the boards come along for the ride.
    func beginPlatformDrag() {
        platformDragging = true
        let area = corner.surface
        let riders: [SKNode] = bunnies.filter { !$0.isHeld && area.contains($0.position) }
        platformRiders = riders + (floorPoops + peeSpots).filter { area.contains($0.position) }
        Log.info("Sliding the platform (\(riders.count) bunnies and \(platformRiders.count - riders.count) messes on it).")
    }

    func movePlatform(toShift newShift: CGFloat) {
        let old = corner.shift
        corner.layout(width: size.width, shift: newShift)
        // Move riders by how far the platform actually went (it stops at the screen edges).
        let dx = old - corner.shift
        guard dx != 0 else { return }
        for n in platformRiders { n.position.x += dx }
    }

    func endPlatformDrag() {
        platformDragging = false
        platformRiders = []
        model.platformShift = Double(corner.shift)
        // Anyone on the way to the hay, water or litter box heads for where it is now.
        for b in bunnies { b.platformMoved() }
        syncFloorToModel()
        save()
        Log.info("Put the platform down \(Int(corner.shift)) pt from the right edge.")
    }

    /// 🐰 menu → "Put the platform back in the corner".
    func resetPlatform() {
        beginPlatformDrag()
        movePlatform(toShift: 0)
        endPlatformDrag()
    }

    // MARK: - Test helpers

    func writeSnapshot(to path: String) -> Bool {
        guard let view else { return false }
        guard let texture = view.texture(from: self, crop: CGRect(origin: .zero, size: size)),
              let image = PNG.onBackdrop(texture.cgImage(), color: CGColor(red: 0.42, green: 0.50, blue: 0.58, alpha: 1)) else { return false }
        return PNG.write(image, to: URL(fileURLWithPath: path))
    }

    /// `--tour DIR`: makes both bunnies go through every activity, with a
    /// snapshot of each, and shows the low-hay / old-water reminders.
    private func runTour(snapshotsTo dir: String) {
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        if options.tourActs == nil {          // the full tour also shows the reminders
            model.hay = 0.1
            model.lastWaterRefill = Date().addingTimeInterval(-30 * 3600)
        }
        let defaultActs: [Bunny.Activity] = [.sleep, .flop, .loaf, .groom, .periscope, .litter, .eat, .drink,
                                             .zoomies, .visitPartner, .binky, .waitForHay, .accident, .petted]
        let acts = options.tourActs?.compactMap(Bunny.Activity.init(rawValue:)) ?? defaultActs
        let offset = acts.count > 5 ? 5 : 1
        // Short tours put the bunnies right where they're going, to check the layering.
        func place(_ bunny: Bunny, for a: Bunny.Activity) {
            guard options.tourActs != nil else { return }
            switch a {
            case .litter: bunny.position = litterSpot(bunny.spotIndex)
            case .eat: bunny.position = hayEatSpot(bunny.spotIndex).0
            case .drink: bunny.position = drinkSpot(bunny.spotIndex).0
            case .petted: bunny.position = randomFloorPoint(near: nil)
            default: break
            }
        }
        let stepSeconds = 7.0
        let snapAt = options.tourActs == nil ? 5.5 : 1.2
        if options.tourActs?.contains("switchart") == true {
            // Flip the art style mid-activity, then snapshot.
            run(.sequence([.wait(forDuration: 3.0 * Double(speed)), .run { MainActor.assumeIsolated { [weak self] in
                guard let self else { return }
                self.setArtStyle(self.artStyle == .drawn ? .realistic : .drawn)
            } }, .wait(forDuration: 0.5 * Double(speed)), .run { MainActor.assumeIsolated { [weak self] in
                _ = self?.writeSnapshot(to: "\(dir)/switched-art.png")
            } }]))
        }
        if options.tourActs?.contains("platform") == true {
            // Simulated drag of the platform, 650 pt to the left, in the first act
            // (after the bunnies have settled on it), with snapshots during and after.
            let grab = corner.surface.origin + CGPoint(x: 200, y: 30)
            let s = Double(speed)
            run(.sequence([.wait(forDuration: 2.5 * s), .run { MainActor.assumeIsolated { [weak self] in
                guard let self else { return }
                self.platformPress = (grab, self.corner.shift)
                self.beginPlatformDrag()
            } }]))
            for k in 1...12 {
                run(.sequence([.wait(forDuration: (2.5 + Double(k) * 0.1) * s), .run { MainActor.assumeIsolated { [weak self] in
                    guard let self, let press = self.platformPress else { return }
                    self.movePlatform(toShift: press.shift + 650 * CGFloat(k) / 12)
                } }]))
            }
            run(.sequence([.wait(forDuration: 3.2 * s), .run { MainActor.assumeIsolated { [weak self] in
                _ = self?.writeSnapshot(to: "\(dir)/platform-mid.png")
            } }]))
            run(.sequence([.wait(forDuration: 3.9 * s), .run { MainActor.assumeIsolated { [weak self] in
                guard let self else { return }
                self.platformPress = nil
                self.endPlatformDrag()
            } }]))
            run(.sequence([.wait(forDuration: 6.5 * s), .run { MainActor.assumeIsolated { [weak self] in
                _ = self?.writeSnapshot(to: "\(dir)/platform-after.png")
            } }]))
        }
        for i in 0...acts.count {
            run(.sequence([.wait(forDuration: 1 + Double(i) * stepSeconds * Double(speed)), .run { MainActor.assumeIsolated { [weak self] in
                guard let self, self.bunnies.count == 2 else { return }
                if i == acts.count {
                    self.bunnies.forEach { $0.force(.sleep) }
                    Log.info("Tour: both asleep now (for a CPU reading).")
                    return
                }
                let a = acts[i], b = acts[(i + offset) % acts.count]
                place(self.bunnies[0], for: a)
                place(self.bunnies[1], for: b)
                for (bunny, act) in [(self.bunnies[0], a), (self.bunnies[1], b)] {
                    if act == .held {
                        // Simulated drag: lift it up, hold it, put it down.
                        bunny.pickUp()
                        bunny.position.y += 90
                        bunny.run(.sequence([.wait(forDuration: 1.6 * Double(self.speed)), .run { MainActor.assumeIsolated {
                            bunny.putDown(at: self.clampToFloor(CGPoint(x: bunny.position.x, y: 40)))
                        } }]))
                    } else {
                        bunny.force(act)
                    }
                }
                Log.info("Tour \(i): Snoopy → \(a.rawValue), Bambi → \(b.rawValue)")
            } }]))
            if i < acts.count {
                run(.sequence([.wait(forDuration: 1 + (Double(i) * stepSeconds + snapAt) * Double(speed)), .run { MainActor.assumeIsolated { [weak self] in
                    guard let self else { return }
                    let name = String(format: "%@/tour-%02d.png", dir, i)
                    _ = self.writeSnapshot(to: name)
                    Log.info("Tour \(i): Snoopy is \(self.bunnies[0].activity.rawValue), Bambi is \(self.bunnies[1].activity.rawValue)")
                } }]))
            }
        }
    }

    // MARK: - Little effects

    func hearts(at p: CGPoint) {
        for i in 0..<3 {
            let h = SKLabelNode(text: "♥")
            h.fontName = "HelveticaNeue-Bold"
            h.fontSize = CGFloat.random(in: 11...15)
            h.fontColor = NSColor(hex: 0xF07C9A)
            h.position = p + CGPoint(x: CGFloat(i - 1) * 9, y: 0)
            h.zPosition = 350
            h.setScale(0.4)
            addChild(h)
            h.run(.sequence([.wait(forDuration: Double(i) * 0.12),
                             .group([.scale(to: 1, duration: 0.25), .moveBy(x: .random(in: -6...6), y: 28, duration: 1.1),
                                     .sequence([.wait(forDuration: 0.6), .fadeOut(withDuration: 0.5)])]),
                             .removeFromParent()]))
        }
    }

    func zzz(at p: CGPoint) {
        let z = SKLabelNode(text: "z")
        z.fontName = "HelveticaNeue-Bold"
        z.fontSize = 10
        z.fontColor = NSColor(hex: 0x7C8FB0)
        z.position = p
        z.zPosition = 350
        z.alpha = 0
        addChild(z)
        z.run(.sequence([.group([.fadeIn(withDuration: 0.3), .scale(to: 1.6, duration: 2), .moveBy(x: 10, y: 22, duration: 2),
                                 .sequence([.wait(forDuration: 1.3), .fadeOut(withDuration: 0.7)])]),
                         .removeFromParent()]))
    }

    func puff(at p: CGPoint) {
        for i in 0..<4 {
            let c = SKShapeNode(circleOfRadius: 2.5)
            c.fillColor = NSColor(white: 0.85, alpha: 0.8)
            c.strokeColor = .clear
            c.position = p
            c.zPosition = 300
            addChild(c)
            let dx = CGFloat(i - 2) * 5 + 2
            c.run(.sequence([.group([.moveBy(x: dx, y: .random(in: 3...7), duration: 0.35), .scale(to: 2, duration: 0.35),
                                     .fadeOut(withDuration: 0.35)]),
                             .removeFromParent()]))
        }
    }

    func sparkle(at p: CGPoint) {
        let s = SKLabelNode(text: "✨")
        s.fontSize = 14
        s.position = p + CGPoint(x: 0, y: 2)
        s.zPosition = 350
        s.setScale(0.3)
        addChild(s)
        s.run(.sequence([.group([.scale(to: 1.2, duration: 0.25), .moveBy(x: 0, y: 10, duration: 0.6)]),
                         .fadeOut(withDuration: 0.3), .removeFromParent()]))
    }

    func toast(_ text: String) {
        let t = Bubble.pill(text, fontSize: 11, color: NSColor(hex: 0xFFF8E8))
        let w = t.calculateAccumulatedFrame().width
        let x = min(size.width - 14 - w / 2, corner.footprint.maxX - 14 - w / 2)
        t.position = CGPoint(x: max(14 + w / 2, x), y: corner.footprint.maxY + 18)
        t.zPosition = 420
        t.alpha = 0
        addChild(t)
        t.run(.sequence([.fadeIn(withDuration: 0.3), .wait(forDuration: 9), .fadeOut(withDuration: 0.6), .removeFromParent()]))
    }
}
