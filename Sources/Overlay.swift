import AppKit
import SpriteKit

/// A borderless, see-through panel covering the usable part of the main
/// screen (above the Dock, below the menu bar). It never takes keyboard
/// focus, so clicking a poop doesn't pull you out of the app you're in.
final class OverlayPanel: NSPanel {
    init(frame: NSRect) {
        super.init(contentRect: frame,
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        isMovable = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        becomesKeyOnlyIfNeeded = true
        // Every normal desktop Space, but not over full-screen apps
        // (so the bunnies stay out of presentations and full-screen video).
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// How tall the bunnies' strip is when they stay along the bottom.
    static let stripHeight: CGFloat = 250

    /// The usable area of the screen that has the menu bar (above the Dock,
    /// below the menu bar), or just a strip along its bottom.
    static func targetFrame(bottomOnly: Bool) -> NSRect {
        let visible = (NSScreen.screens.first ?? NSScreen.main)?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        guard bottomOnly else { return visible }
        return NSRect(x: visible.minX, y: visible.minY, width: visible.width, height: min(visible.height, stripHeight))
    }

    func setOnTop(_ onTop: Bool) {
        if onTop {
            level = .floating
        } else {
            // Just above the desktop icons, under every normal window.
            level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        }
    }
}

final class PenView: SKView {
    // Deliver the very first click even though the panel is never "key".
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

/// Makes the overlay click-through everywhere except over things you can
/// click (poops, bunnies, buttons). It checks the mouse position ~30 times a
/// second; this needs no special permissions.
@MainActor
final class PassthroughController {
    private weak var panel: OverlayPanel?
    private weak var view: SKView?
    private weak var scene: PenScene?
    private var timer: Timer?
    private var ticks = 0
    var onScreenAreaCheck: (() -> Void)?

    init(panel: OverlayPanel, view: SKView, scene: PenScene) {
        self.panel = panel
        self.view = view
        self.scene = scene
    }

    func start() {
        let t = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        ticks += 1
        if ticks % 60 == 0 { onScreenAreaCheck?() }   // every ~2 s: Dock moved or resized?
        guard let panel, let view, let scene else { return }
        guard panel.isVisible else {
            if !panel.ignoresMouseEvents { panel.ignoresMouseEvents = true }
            return
        }
        let mouse = NSEvent.mouseLocation
        var interactive = false
        if panel.frame.contains(mouse) {
            let inWindow = panel.convertPoint(fromScreen: mouse)
            let inView = view.convert(inWindow, from: nil)
            let inScene = scene.convertPoint(fromView: inView)
            scene.hover(at: inScene)
            interactive = scene.isInteractive(at: inScene)
        } else {
            scene.hover(at: nil)
        }
        if panel.ignoresMouseEvents == interactive {
            panel.ignoresMouseEvents = !interactive
            Log.debug(interactive ? "mouse over something clickable: catching clicks"
                                  : "mouse over empty space: clicks pass through")
        }
    }
}
