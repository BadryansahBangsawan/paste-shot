import Combine
import Foundation

@MainActor
final class PasteShotStore: ObservableObject {
    @Published var menuTitle = "Paste Shot"
    @Published var isEnabled = true
    @Published var errorMessage: String?

    private var watcher: ScreenshotWatcher?
    private var watchedPath: String?
    private var lastCopiedPath: String?
    private var lastCopiedModificationDate: Date?
    private var titleGeneration = 0
    private var titleResetTask: Task<Void, Never>?
    private static let enabledKey = "engineer.badry.pasteshot.enabled"


    init() {
        if UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool == false {
            isEnabled = false
            menuTitle = "Off"
            return
        }
        start()
    }

    func setEnabled(_ on: Bool) {
        isEnabled = on
        UserDefaults.standard.set(on, forKey: Self.enabledKey)
        if on {
            watchedPath = nil
            start()
        } else {
            stopWatcher()
            errorMessage = nil
            menuTitle = "Off"
            titleResetTask?.cancel()
        }
    }


    func start() {
        guard isEnabled else { return }
        let folder = ScreenshotFolder.resolve()
        let path = folder.standardizedFileURL.path

        if !FileManager.default.fileExists(atPath: folder.path) {
            errorMessage = "Screenshot folder missing."
            stopWatcher()
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
    private func stopWatcher() {
        watcher?.stop()
        watcher = nil
        watchedPath = nil
    }


    private func handleFile(_ url: URL) {
        guard isEnabled else { return }
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
        var sawScreenshot = false
        for attempt in 0..<8 {
            if ScreenshotFile.isScreenshot(url) {
                sawScreenshot = true
                do {
                    try PasteboardImage.copyFile(url)
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
                }
            }
            if attempt < 7 {
                do {
                    try await Task.sleep(for: .milliseconds(50))
                } catch {
                    return
                }
            }
        }
        if sawScreenshot, let lastError {
            errorMessage = lastError.localizedDescription
        }
    }



}
