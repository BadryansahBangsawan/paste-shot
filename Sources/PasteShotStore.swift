import Combine
import Foundation

@MainActor
final class PasteShotStore: ObservableObject {
    @Published var menuTitle = "Paste Shot"
    @Published var statusText = "Watching ~/Desktop"
    @Published var lastCopiedName: String?
    @Published var errorMessage: String?

    private var watcher: ScreenshotWatcher?
    private var watchedPath: String?
    private var lastCopiedPath: String?
    private var lastCopiedModificationDate: Date?
    private var titleGeneration = 0
    private var titleResetTask: Task<Void, Never>?

    func start() {
        let folder = ScreenshotFolder.resolve()
        let path = folder.standardizedFileURL.path
        statusText = "Watching " + abbreviate(folder.path)

        if !FileManager.default.fileExists(atPath: folder.path) {
            errorMessage = "Screenshot folder missing."
            watcher?.stop()
            watcher = nil
            watchedPath = path
            return
        }

        if errorMessage == "Screenshot folder missing." {
            errorMessage = nil
        }

        if watchedPath == path, watcher != nil {
            return
        }

        watcher?.stop()
        watcher = nil
        watchedPath = path
        watcher = ScreenshotWatcher(
            directory: folder,
            onFile: { [weak self] url in
                Task { @MainActor in
                    self?.handleFile(url)
                }
            },
            onStartError: { [weak self] message in
                Task { @MainActor in
                    self?.errorMessage = message
                }
            }
        )
    }

    private func handleFile(_ url: URL) {
        guard ScreenshotFile.isScreenshot(url) else { return }

        let fileURL = url.standardizedFileURL
        let values: URLResourceValues?
        do {
            values = try fileURL.resourceValues(forKeys: [.contentModificationDateKey, .creationDateKey])
        } catch {
            values = nil
        }

        let mtime = values?.contentModificationDate
        let birth = values?.creationDate

        if let lastCopiedPath, lastCopiedPath == fileURL.path,
           let lastCopiedModificationDate, let mtime,
           lastCopiedModificationDate == mtime {
            return
        }

        let dates = [birth, mtime].compactMap { $0 }
        if let newest = dates.max(), Date().timeIntervalSince(newest) > 30 {
            return
        }

        Task {
            await copyWhenReadable(fileURL)
        }
    }

    private func copyWhenReadable(_ url: URL) async {
        var lastError: Error?
        for attempt in 0..<8 {
            do {
                try PasteboardImage.copyFile(url)
                lastCopiedName = url.lastPathComponent
                errorMessage = nil
                menuTitle = "Copied"
                lastCopiedPath = url.standardizedFileURL.path
                do {
                    lastCopiedModificationDate = try url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                } catch {
                    lastCopiedModificationDate = nil
                }
                titleResetTask?.cancel()
                titleGeneration += 1
                let generation = titleGeneration
                titleResetTask = Task { @MainActor in
                    do {
                        try await Task.sleep(for: .seconds(2))
                    } catch {
                        return
                    }
                    guard generation == titleGeneration else { return }
                    if menuTitle == "Copied" {
                        menuTitle = "Paste Shot"
                    }
                }
                return
            } catch {
                lastError = error
                if attempt < 7 {
                    do {
                        try await Task.sleep(for: .milliseconds(50))
                    } catch {
                        return
                    }
                }
            }
        }
        if let lastError {
            errorMessage = lastError.localizedDescription
        }
    }

    private func abbreviate(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path == home { return "~" }
        if path.hasPrefix(home + "/") {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}
