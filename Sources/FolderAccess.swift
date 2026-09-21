import AppKit

enum FolderAccess {
    static let bookmarkKey = "engineer.badry.pasteshot.folderBookmark"

    static var hasBookmark: Bool {
        UserDefaults.standard.data(forKey: bookmarkKey) != nil
    }

    static func activateSavedBookmark() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else {
            return nil
        }
        var stale = false
        let url: URL
        do {
            url = try URL(
                resolvingBookmarkData: data,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            )
        } catch {
            return nil
        }
        if stale {
            do {
                let refreshed = try url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                UserDefaults.standard.set(refreshed, forKey: bookmarkKey)
            } catch {
                return nil
            }
        }
        guard url.startAccessingSecurityScopedResource() else {
            return nil
        }
        return url
    }

    static func saveBookmark(for url: URL) throws {
        let data = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        UserDefaults.standard.set(data, forKey: bookmarkKey)
    }

    static func promptForFolder(defaultDirectory: URL) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.directoryURL = defaultDirectory
        panel.message = "Allow Paste Shot to read this screenshot folder. macOS asks only this once."
        panel.prompt = "Allow"
        NSApp.activate(ignoringOtherApps: true)
        let response = panel.runModal()
        guard response == .OK, let url = panel.url else {
            return nil
        }
        do {
            try saveBookmark(for: url)
        } catch {
            return nil
        }
        guard url.startAccessingSecurityScopedResource() else {
            return nil
        }
        return url
    }
}
