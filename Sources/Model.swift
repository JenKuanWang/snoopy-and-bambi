import Foundation

/// A spot on the floor, stored as a fraction of the screen area so it
/// survives screen size changes.
struct Spot: Codable, Equatable {
    var x: Double
    var y: Double
}

/// Everything that is remembered between launches.
struct PenModel: Codable {
    // Tunables (not saved).
    static let hayEatenPerHour = 1.0 / 12.0      // a full pile lasts ~12 h
    static let waterDrunkPerHour = 1.0 / 30.0    // a full bowl lasts ~30 h
    static let waterStaleAfter: TimeInterval = 24 * 3600
    static let lowLevel = 0.25
    static let litterFull = 150          // roughly a day's worth
    static let maxFloorPoops = 40
    static let maxPeeSpots = 4
    /// When a bunny needs to go, how often it doesn't make it to the box.
    static let litterMissRate = 0.08
    /// Chance of a stray poop on each hop (they do that). The two bunnies
    /// hop ~2000 times an hour when lively, so this is ~1 stray an hour.
    static let strayPoopChancePerHop = 0.0004

    var hay = 1.0
    var water = 1.0
    var lastHayRefill = Date()
    var lastWaterRefill = Date()
    var litterPoops = 0
    var litterPee = 0
    var floorPoops: [Spot] = []
    var peeSpots: [Spot] = []
    var lastUpdate = Date()
    var keepOnTop = true
    /// Bunnies live in a strip along the bottom of the screen (vs. the whole screen).
    var bottomOnly = true
    /// How far the platform has been dragged left from the lower-right corner (points).
    var platformShift = 0.0
    /// "realistic" (painted sprites) or "drawn" (drawn in code).
    var artStyle = "realistic"
    var notificationsOn = false
    var lastHayNotice: Date?
    var lastWaterNotice: Date?
    var lastLitterNotice: Date?

    init() {}

    // Tolerant decoding: a missing key falls back to its default, so older
    // save files keep working as features are added.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = PenModel()
        hay = try c.decodeIfPresent(Double.self, forKey: .hay) ?? d.hay
        water = try c.decodeIfPresent(Double.self, forKey: .water) ?? d.water
        lastHayRefill = try c.decodeIfPresent(Date.self, forKey: .lastHayRefill) ?? d.lastHayRefill
        lastWaterRefill = try c.decodeIfPresent(Date.self, forKey: .lastWaterRefill) ?? d.lastWaterRefill
        litterPoops = try c.decodeIfPresent(Int.self, forKey: .litterPoops) ?? 0
        litterPee = try c.decodeIfPresent(Int.self, forKey: .litterPee) ?? 0
        floorPoops = try c.decodeIfPresent([Spot].self, forKey: .floorPoops) ?? []
        peeSpots = try c.decodeIfPresent([Spot].self, forKey: .peeSpots) ?? []
        lastUpdate = try c.decodeIfPresent(Date.self, forKey: .lastUpdate) ?? Date()
        keepOnTop = try c.decodeIfPresent(Bool.self, forKey: .keepOnTop) ?? true
        bottomOnly = try c.decodeIfPresent(Bool.self, forKey: .bottomOnly) ?? true
        platformShift = try c.decodeIfPresent(Double.self, forKey: .platformShift) ?? 0
        artStyle = try c.decodeIfPresent(String.self, forKey: .artStyle) ?? d.artStyle
        notificationsOn = try c.decodeIfPresent(Bool.self, forKey: .notificationsOn) ?? false
        lastHayNotice = try c.decodeIfPresent(Date.self, forKey: .lastHayNotice)
        lastWaterNotice = try c.decodeIfPresent(Date.self, forKey: .lastWaterNotice)
        lastLitterNotice = try c.decodeIfPresent(Date.self, forKey: .lastLitterNotice)
    }

    // MARK: Derived state

    var hayLow: Bool { hay < Self.lowLevel }
    var hayEmpty: Bool { hay < 0.02 }
    var waterLow: Bool { water < Self.lowLevel }
    var waterEmpty: Bool { water < 0.02 }
    func waterStale(at now: Date = Date()) -> Bool { now.timeIntervalSince(lastWaterRefill) > Self.waterStaleAfter }
    var litterNeedsCleaning: Bool { litterPoops >= Self.litterFull }
    func needsWaterAttention(at now: Date = Date()) -> Bool { waterLow || waterStale(at: now) }
    func needsAttention(at now: Date = Date()) -> Bool { hayLow || needsWaterAttention(at: now) || litterNeedsCleaning }

    // MARK: Time passing

    /// Hay and water go down with time, whether or not the app is open.
    mutating func advance(to now: Date, speed: Double = 1) {
        let hours = max(0, now.timeIntervalSince(lastUpdate)) / 3600 * speed
        hay = max(0, hay - hours * Self.hayEatenPerHour)
        water = max(0, water - hours * Self.waterDrunkPerHour)
        lastUpdate = now
    }

    mutating func refillHay(at now: Date = Date()) {
        hay = 1
        lastHayRefill = now
        lastHayNotice = nil
    }

    mutating func refreshWater(at now: Date = Date()) {
        water = 1
        lastWaterRefill = now
        lastWaterNotice = nil
    }
}

/// Reads and writes the save file (JSON in Application Support).
struct PenStore {
    let url: URL

    init(directory: URL) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        url = directory.appendingPathComponent("state.json")
    }

    func load() -> PenModel? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(PenModel.self, from: data)
        } catch {
            Log.info("Couldn't read the save file (\(error)); starting fresh.")
            return nil
        }
    }

    func save(_ model: PenModel) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(model) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

enum Ago {
    static func describe(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        if minutes < 2 { return "just now" }
        if minutes < 60 { return "\(minutes) min ago" }
        let hours = minutes / 60
        if hours < 48 { return "\(hours) h ago" }
        return "\(hours / 24) days ago"
    }
}
