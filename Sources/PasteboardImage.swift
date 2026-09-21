import AppKit

enum PasteboardImage {
    static func copyFile(_ url: URL) throws {
        let ext = url.pathExtension.lowercased()
        let pb = NSPasteboard.general
        if ext == "png" {
            let data = try Data(contentsOf: url)
            pb.clearContents()
            pb.setData(data, forType: .png)
            return
        }
        guard let image = NSImage(contentsOf: url),
              let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:])
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        pb.clearContents()
        pb.setData(png, forType: .png)
    }
}
