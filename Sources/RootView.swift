import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: PasteShotStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: FunTheme.sectionSpacing) {
            if let errorMessage = store.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(store.statusText)

            if store.lastCopiedName == nil, store.errorMessage == nil {
                ExtraEmptyState(
                    title: "No screenshot yet",
                    detail: "Press ⌘⇧3 or ⌘⇧4. The image is copied for ⌘V.",
                    actionTitle: "OK",
                    action: {}
                )
            }

            if let lastCopiedName = store.lastCopiedName {
                Text(lastCopiedName)
                    .extraRowSurface()
            }

            ExtraSettingsFooter()
        }
        .animation(reduceMotion ? nil : FunTheme.spring, value: store.errorMessage)
        .animation(reduceMotion ? nil : FunTheme.spring, value: store.lastCopiedName)
        .animation(reduceMotion ? nil : FunTheme.spring, value: store.statusText)
        .funPanel()
        .onAppear { store.start() }
    }
}
