import AppKit

enum PasteboardImage {
    static let copyPathKey = "engineer.badry.pasteshot.copyPath"

    static func copyFile(_ url: URL) throws {
        let png = try pngData(from: url)
        let dest = try persistLastPNG(png)
        let item = NSPasteboardItem()
        item.setData(png, forType: .png)
        if let tiff = NSImage(data: png)?.tiffRepresentation {
            item.setData(tiff, forType: .tiff)
        }
        // Do not put public.utf8-plain-text unless asked. Chromium/WebKit
        // expose it as text/plain; many sites insert that and skip image/png.
        if UserDefaults.standard.bool(forKey: copyPathKey) {
            item.setString(shellQuoted(dest.path), forType: .string)
        }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([item])
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
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/PasteShot", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let dest = dir.appendingPathComponent("last.png")
        try data.write(to: dest, options: .atomic)
        return dest
    }

    private static func shellQuoted(_ path: String) -> String {
        "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
