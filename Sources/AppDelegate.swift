import AppKit
import SpriteKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let options: LaunchOptions
    private var panel: OverlayPanel!
    private var penView: PenView!
    private var scene: PenScene!
    private var passthrough: PassthroughController!
    private var statusItem: NSStatusItem!
    private var hidden = false
    private var quitSignal: DispatchSourceSignal?

    init(options: LaunchOptions) {
        self.options = options
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if options.testSeconds == nil, anotherCopyIsRunning() {
            Log.info("Another copy is already running; quitting this one.")
            NSApp.terminate(nil)
            return
        }

        let bottomOnly = PenStore(directory: options.stateDir).load()?.bottomOnly ?? true
        let frame = OverlayPanel.targetFrame(bottomOnly: bottomOnly)
        panel = OverlayPanel(frame: frame)
        penView = PenView(frame: NSRect(origin: .zero, size: frame.size))
        penView.allowsTransparency = true
        penView.preferredFramesPerSecond = 30
        penView.ignoresSiblingOrder = true

        scene = PenScene(size: frame.size, options: options)
        scene.scaleMode = .resizeFill
        scene.onChange = { [weak self] in self?.refreshStatusIcon() }
        scene.onMenuRequest = { [weak self] p in self?.popUpMenu(at: p) }
        penView.presentScene(scene)
        panel.contentView = penView
        panel.setOnTop(scene.model.keepOnTop)
        panel.orderFrontRegardless()

        passthrough = PassthroughController(panel: panel, view: penView, scene: scene)
        passthrough.onScreenAreaCheck = { [weak self] in self?.fitToScreen() }
        passthrough.start()

        setUpStatusItem()
        observeSystem()
        // `killall SnoopyAndBambi` quits normally, so the bunnies' state is saved.
        signal(SIGTERM, SIG_IGN)
        let quit = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        quit.setEventHandler { MainActor.assumeIsolated { NSApp.terminate(nil) } }
        quit.resume()
        quitSignal = quit
        Log.info("Started. Bunny area: \(Int(frame.width))×\(Int(frame.height)) at (\(Int(frame.minX)), \(Int(frame.minY))). Save folder: \(options.stateDir.path)")

        if let seconds = options.testSeconds {
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                self?.finishTestRun()
            }
        }
    }

    /// Opening the app again while it's running (from Spotlight, Finder or
    /// Launchpad) hides the bunnies, or brings them back.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        Log.info("Opened again while running: toggling the bunnies.")
        toggleHidden()
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        scene?.save()
        Log.info("Quit.")
    }

    // MARK: - Test runs

    private func finishTestRun() {
        if let path = options.snapshotPath {
            Log.info(scene.writeSnapshot(to: path) ? "Snapshot saved to \(path)" : "Snapshot FAILED")
        }
        Log.info("Poops this run: \(scene.tally.box) in the litter box, \(scene.tally.floor) on the floor; \(scene.tally.hops) hops.")
        Log.info("Test run finished; quitting.")
        NSApp.terminate(nil)
    }

    private func anotherCopyIsRunning() -> Bool {
        guard let id = Bundle.main.bundleIdentifier else { return false }
        return NSRunningApplication.runningApplications(withBundleIdentifier: id)
            .contains { $0 != NSRunningApplication.current }
    }

    // MARK: - Screen changes, sleep

    private func fitToScreen() {
        let frame = OverlayPanel.targetFrame(bottomOnly: scene.model.bottomOnly)
        guard frame != panel.frame else { return }
        Log.info("Screen area changed to \(Int(frame.width))×\(Int(frame.height)); moving the pen.")
        panel.setFrame(frame, display: true)
    }

    private func observeSystem() {
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.fitToScreen() }
        }
        let ws = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.screensDidSleepNotification, NSWorkspace.sessionDidResignActiveNotification] {
            ws.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.penView.isPaused = true }
            }
        }
        for name in [NSWorkspace.screensDidWakeNotification, NSWorkspace.sessionDidBecomeActiveNotification] {
            ws.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self, !self.hidden else { return }
                    self.penView.isPaused = false
                }
            }
        }
    }

    // MARK: - Menu bar

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        refreshStatusIcon()
        // On screens with a notch, menu bar icons can end up hidden behind
        // it. Log where ours landed; the 🐰 button in the corner opens the
        // same menu either way.
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard let self, let w = self.statusItem.button?.window else {
                Log.info("Menu bar icon: no window (not shown)")
                return
            }
            let screen = NSScreen.screens.first
            let f = w.frame
            var where_ = "visible"
            if let left = screen?.auxiliaryTopLeftArea, let right = screen?.auxiliaryTopRightArea,
               !left.isEmpty || !right.isEmpty {
                let inSafeArea = right.contains(CGPoint(x: f.midX, y: f.midY)) || left.contains(CGPoint(x: f.midX, y: f.midY))
                where_ = inSafeArea ? "visible (beside the notch)" : "possibly hidden behind the notch"
            }
            Log.info("Menu bar icon at x=\(Int(f.minX))…\(Int(f.maxX)), occlusion visible: \(w.occlusionState.contains(.visible)), \(where_)")
        }
    }

    private func popUpMenu(at scenePoint: CGPoint) {
        let menu = NSMenu()
        menuNeedsUpdate(menu)
        let p = penView.convert(scenePoint, from: scene)
        menu.popUp(positioning: nil, at: CGPoint(x: p.x - 10, y: p.y + 20), in: penView)
    }

    private func refreshStatusIcon() {
        guard let button = statusItem?.button else { return }
        let alert = scene?.needsAttention ?? false
        button.title = alert ? "🐰❗" : "🐰"
        button.toolTip = alert ? "Snoopy & Bambi need something" : "Snoopy & Bambi"
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let title = NSMenuItem(title: "Snoopy & Bambi", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)
        for line in scene.statusLines() {
            let item = NSMenuItem(title: line, action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        }
        menu.addItem(.separator())
        add(menu, "Add hay", #selector(addHay))
        add(menu, "Fresh water", #selector(freshWater))
        add(menu, "Clean up poops and litter box", #selector(cleanUp))
        menu.addItem(.separator())
        add(menu, hidden ? "Show bunnies" : "Hide bunnies", #selector(toggleHidden))
        add(menu, "Stay along the bottom of the screen", #selector(toggleBottomOnly)).state = scene.model.bottomOnly ? .on : .off
        add(menu, "Keep bunnies on top of windows", #selector(toggleOnTop)).state = scene.model.keepOnTop ? .on : .off
        add(menu, "Reminder notifications", #selector(toggleNotifications)).state = scene.model.notificationsOn ? .on : .off
        menu.addItem(.separator())
        add(menu, "Quit Snoopy & Bambi", #selector(quit))
    }

    @discardableResult
    private func add(_ menu: NSMenu, _ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        menu.addItem(item)
        return item
    }

    @objc private func addHay() { scene.addHay() }
    @objc private func freshWater() { scene.freshWater() }
    @objc private func cleanUp() { scene.cleanUpEverything() }

    @objc private func toggleHidden() {
        hidden.toggle()
        if hidden {
            panel.orderOut(nil)
            penView.isPaused = true
        } else {
            penView.isPaused = false
            panel.orderFrontRegardless()
        }
        Log.info(hidden ? "Bunnies hidden." : "Bunnies shown.")
    }

    @objc private func toggleBottomOnly() {
        scene.model.bottomOnly.toggle()
        scene.save()
        Log.info(scene.model.bottomOnly ? "Bunnies stay along the bottom of the screen." : "Bunnies can roam the whole screen.")
        fitToScreen()
    }

    @objc private func toggleOnTop() {
        scene.model.keepOnTop.toggle()
        panel.setOnTop(scene.model.keepOnTop)
        scene.save()
    }

    @objc private func toggleNotifications() {
        scene.setNotifications(!scene.model.notificationsOn)
    }

    @objc private func quit() { NSApp.terminate(nil) }
}
