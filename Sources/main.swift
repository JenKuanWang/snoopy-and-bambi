import AppKit

let options = LaunchOptions(arguments: CommandLine.arguments)
Log.setup(directory: options.stateDir, verbose: options.verbose)

if let dir = options.renderArtDir {
    // Draw every bunny pose to PNG files (for checking the artwork), then quit.
    ArtRenderer.renderAll(to: URL(fileURLWithPath: dir, isDirectory: true), style: ArtStyle.resolve(options.artStyle ?? "drawn"))
    exit(0)
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let appDelegate = AppDelegate(options: options)
    app.delegate = appDelegate
    app.setActivationPolicy(.accessory)
    withExtendedLifetime(appDelegate) { app.run() }
}
