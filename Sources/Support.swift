import AppKit

/// Command-line switches. Normal launches use none of them; they exist so the
/// app can be test-run (auto-quit, snapshot, separate save folder).
struct LaunchOptions {
    var testSeconds: Double?
    var snapshotPath: String?
    var renderArtDir: String?
    var tourDir: String?
    var tourActs: [String]?
    /// `--art drawn|realistic`: which artwork to use (for --render-art and test runs).
    var artStyle: String?
    var stateDir: URL
    var verbose = false
    /// Multiplies how fast bunny needs change (for testing behaviors quickly).
    var speed: Double = 1

    init(arguments: [String]) {
        stateDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/SnoopyAndBambi", isDirectory: true)
        var i = 1
        func next() -> String? {
            i += 1
            return i < arguments.count ? arguments[i] : nil
        }
        while i < arguments.count {
            switch arguments[i] {
            case "--test-seconds": testSeconds = next().flatMap(Double.init)
            case "--snapshot": snapshotPath = next()
            case "--render-art": renderArtDir = next()
            case "--tour": tourDir = next()
            case "--tour-acts": tourActs = next()?.split(separator: ",").map(String.init)
            case "--state-dir": if let p = next() { stateDir = URL(fileURLWithPath: p, isDirectory: true) }
            case "--art": artStyle = next()
            case "--verbose": verbose = true
            case "--speed": speed = next().flatMap(Double.init) ?? 1
            default: break
            }
            i += 1
        }
    }
}

enum Log {
    nonisolated(unsafe) private static var handle: FileHandle?
    nonisolated(unsafe) private static var verbose = false

    static func setup(directory: URL, verbose: Bool) {
        self.verbose = verbose
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("bunnies.log")
        // Keep the log small: start fresh when it passes ~1 MB.
        if let size = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? Int, size > 1_000_000 {
            try? FileManager.default.removeItem(at: url)
        }
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
        handle = try? FileHandle(forWritingTo: url)
        _ = try? handle?.seekToEnd()
    }

    static func info(_ message: String) { write("INFO", message) }
    static func debug(_ message: String) { if verbose { write("DEBUG", message) } }

    private static func write(_ level: String, _ message: String) {
        let stamp = ISO8601DateFormatter().string(from: Date())
        let line = "\(stamp) [\(level)] \(message)\n"
        FileHandle.standardError.write(line.data(using: .utf8)!)
        handle?.write(line.data(using: .utf8)!)
    }
}

enum PNG {
    @discardableResult
    static func write(_ image: CGImage, to url: URL) -> Bool {
        let rep = NSBitmapImageRep(cgImage: image)
        guard let data = rep.representation(using: .png, properties: [:]) else { return false }
        do { try data.write(to: url); return true } catch { return false }
    }

    /// Puts a transparent image on a plain backdrop so it can be looked at.
    static func onBackdrop(_ image: CGImage, color: CGColor) -> CGImage? {
        let w = image.width, h = image.height
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.setFillColor(color)
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        return ctx.makeImage()
    }
}

extension CGPoint {
    func distance(to p: CGPoint) -> CGFloat { hypot(x - p.x, y - p.y) }
    static func + (a: CGPoint, b: CGPoint) -> CGPoint { CGPoint(x: a.x + b.x, y: a.y + b.y) }
    static func - (a: CGPoint, b: CGPoint) -> CGPoint { CGPoint(x: a.x - b.x, y: a.y - b.y) }
}

extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(srgbRed: CGFloat((hex >> 16) & 0xff) / 255,
                  green: CGFloat((hex >> 8) & 0xff) / 255,
                  blue: CGFloat(hex & 0xff) / 255,
                  alpha: alpha)
    }
}
