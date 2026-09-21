import CoreServices
import Foundation

final class ScreenshotWatcher {
    private var stream: FSEventStreamRef?
    private let onFile: (URL) -> Void
    private let queue = DispatchQueue(label: "engineer.badry.pasteshot.fs")

    init(
        directory: URL,
        onFile: @escaping (URL) -> Void,
        onStartError: @escaping (String) -> Void
    ) {
        self.onFile = onFile
        start(directory: directory, onStartError: onStartError)
    }

    private func start(directory: URL, onStartError: @escaping (String) -> Void) {
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        let callback: FSEventStreamCallback = { _, info, numEvents, eventPaths, eventFlags, _ in
            guard let info else { return }
            let watcher = Unmanaged<ScreenshotWatcher>.fromOpaque(info).takeUnretainedValue()
            let pathArray = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue() as NSArray
            for index in 0..<numEvents {
                let flags = eventFlags[index]
                if flags & UInt32(kFSEventStreamEventFlagItemRemoved) != 0 {
                    continue
                }
                guard let path = pathArray[index] as? String else { continue }
                let hasFileFlag = flags & UInt32(kFSEventStreamEventFlagItemIsFile) != 0
                if !hasFileFlag {
                    var isDirectory: ObjCBool = false
                    let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
                    if !exists || isDirectory.boolValue {
                        continue
                    }
                }
                watcher.deliver(URL(fileURLWithPath: path))
            }
        }
        let paths = [directory.path] as CFArray
        let flags = UInt32(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.2,
            flags
        )
        if let stream {
            FSEventStreamSetDispatchQueue(stream, queue)
            FSEventStreamStart(stream)
        } else {
            onStartError("Could not watch the screenshot folder.")
        }
    }

    private func deliver(_ url: URL) {
        DispatchQueue.main.async { [onFile] in
            onFile(url)
        }
    }

    func stop() {
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
        stream = nil
    }

    deinit {
        stop()
    }
}
