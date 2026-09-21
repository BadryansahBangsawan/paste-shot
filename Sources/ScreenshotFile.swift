import CoreServices
import Foundation

enum ScreenshotFile {
    private static let allowedExtensions: Set<String> = [
        "png", "jpg", "jpeg", "heic", "tif", "tiff", "pdf",
    ]

    private static let namePrefixes = [
        "Screenshot ",
        "Screen Shot ",
        "Tangkapan Layar ",
    ]

    static func isScreenshot(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              !isDirectory.boolValue
        else {
            return false
        }

        let ext = url.pathExtension.lowercased()
        guard allowedExtensions.contains(ext) else {
            return false
        }
        let stem = url.deletingPathExtension().lastPathComponent
        for prefix in namePrefixes {
            if stem.hasPrefix(prefix) {
                return true
            }
        }
        return isSpotlightScreenCapture(url)
    }

    private static func isSpotlightScreenCapture(_ url: URL) -> Bool {
        guard let item = MDItemCreate(kCFAllocatorDefault, url.path as CFString) else {
            return false
        }
        guard let raw = MDItemCopyAttribute(item, "kMDItemIsScreenCapture" as CFString) else {
            return false
        }
        if let flag = raw as? Bool {
            return flag
        }
        if let number = raw as? NSNumber {
            return number.boolValue
        }
        return false
    }
}
