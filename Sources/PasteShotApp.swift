import AppKit
import ServiceManagement
import SwiftUI

@main
struct PasteShotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = PasteShotStore()

    var body: some Scene {
        MenuBarExtra(store.menuTitle, systemImage: "doc.on.clipboard") {
            RootView()
                .environmentObject(store)
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        if SMAppService.mainApp.status != .enabled {
            do {
                try SMAppService.mainApp.register()
            } catch {
                NSLog("Paste Shot Open at Login: \(error.localizedDescription)")
            }
        }
    }
}
