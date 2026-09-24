import AppKit

enum PasteboardImage {
    static let copyPathKey = "engineer.badry.pasteshot.copyPath"

    private static let ignoredBundleIDs: Set<String> = [
        "engineer.badry.pasteshot",
        "com.apple.loginwindow",
        "com.apple.screencaptureui",
        "com.apple.Screenshot",
        "com.apple.screenshot.launcher",
    ]

    private static let terminalBundleIDs: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "net.kovidgoyal.kitty",
        "io.alacritty",
        "org.alacritty",
        "com.github.wez.wezterm",
        "dev.warp.Warp-Stable",
        "dev.warp.Warp",
        "com.mitchellh.ghostty",
        "com.raggi.ghostty",
        "co.zeit.hyper",
    ]

    private static var observing = false
    private static var lastChangeCount = 0
    private static var lastClientBundleID: String?

    static func startFrontmostObserver() {
        guard !observing else { return }
        observing = true
        rememberClient(NSWorkspace.shared.frontmostApplication)
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            rememberClient(app)
            syncPathFlavor()
        }
    }

    static func copyFile(_ url: URL) throws {
        startFrontmostObserver()
        rememberClient(NSWorkspace.shared.frontmostApplication)
        let png = try pngData(from: url)
        let dest = try persistLastPNG(png)
        write(png: png, dest: dest, includePath: wantsPath())
    }

    private static func syncPathFlavor() {
        let pb = NSPasteboard.general
        guard lastChangeCount != 0, pb.changeCount == lastChangeCount else { return }
        let dest = lastPNGURL()
        guard FileManager.default.fileExists(atPath: dest.path) else { return }
        let want = wantsPath()
        let hasString = pb.string(forType: .string) != nil
        guard hasString != want else { return }
        guard let png = try? Data(contentsOf: dest) else { return }
        write(png: png, dest: dest, includePath: want)
    }

    private static func write(png: Data, dest: URL, includePath: Bool) {
        let item = NSPasteboardItem()
        item.setData(png, forType: .png)
        if let tiff = NSImage(data: png)?.tiffRepresentation {
            item.setData(tiff, forType: .tiff)
        }
        item.setString(dest.absoluteString, forType: .fileURL)
        if includePath {
            item.setString(shellQuoted(dest.path), forType: .string)
        }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([item])
        lastChangeCount = pb.changeCount
    }

    private static func wantsPath() -> Bool {
        if UserDefaults.standard.bool(forKey: copyPathKey) { return true }
        if let id = NSWorkspace.shared.frontmostApplication?.bundleIdentifier {
            if isTerminal(id) { return true }
            if !isIgnored(id) { return false }
        }
        if let id = lastClientBundleID { return isTerminal(id) }
        return false
    }

    private static func rememberClient(_ app: NSRunningApplication?) {
        guard let id = app?.bundleIdentifier, !isIgnored(id) else { return }
        lastClientBundleID = id
    }

    private static func isIgnored(_ id: String) -> Bool {
        if ignoredBundleIDs.contains(id) { return true }
        if id.hasPrefix("com.apple.screencapture") { return true }
        if id.hasPrefix("com.apple.Screenshot") { return true }
        return false
    }

    private static func isTerminal(_ id: String) -> Bool {
        terminalBundleIDs.contains(id)
    }

    private static func lastPNGURL() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/PasteShot", isDirectory: true)
            .appendingPathComponent("last.png")
    }

    private static func pngData(from url: URL) throws -> Data {
        if url.pathExtension.lowercased() == "png" {
            return try Data(contentsOf: url)
        }
        guard let image = NSImage(contentsOf: url),
              let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:])
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return png
    }

    private static func persistLastPNG(_ data: Data) throws -> URL {
        let dest = lastPNGURL()
        try FileManager.default.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: dest, options: .atomic)
        return dest
    }

    private static func shellQuoted(_ path: String) -> String {
        "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
