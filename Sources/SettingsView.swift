import AppKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: PasteShotStore
    @State private var loginEnabled = SMAppService.mainApp.status == .enabled
    @State private var loginStatusText: String?

    var body: some View {
        Form {
            Toggle("Open at Login", isOn: loginBinding)
            if let loginStatusText {
                Label(loginStatusText, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button("Allow screenshot folder…") {
                store.allowScreenshotFolder()
            }
            Text(store.folderAllowed
                 ? "Allowed. New screenshots will not ask again."
                 : "macOS asks once for this folder, not for every screenshot.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
        .frame(width: FunTheme.panelWidth)
        .padding(12)
        .onAppear {
            loginEnabled = SMAppService.mainApp.status == .enabled
        }
    }


    private var loginBinding: Binding<Bool> {
        Binding(
            get: { loginEnabled },
            set: { newValue in
                do {
                    if newValue {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                    loginEnabled = SMAppService.mainApp.status == .enabled
                    loginStatusText = nil
                } catch {
                    loginEnabled = SMAppService.mainApp.status == .enabled
                    loginStatusText = error.localizedDescription
                }
            }
        )
    }
}
