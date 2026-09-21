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

            Spacer(minLength: 0)

            Toggle(isOn: enabledBinding) {
                Text(store.isEnabled ? "On" : "Off")
                    .font(.title2.weight(.semibold))
            }
            .toggleStyle(.switch)
            .controlSize(.large)
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
            .extraRowSurface()

            Spacer(minLength: 0)

            ExtraSettingsFooter()
        }
        .animation(reduceMotion ? nil : FunTheme.spring, value: store.isEnabled)
        .animation(reduceMotion ? nil : FunTheme.spring, value: store.errorMessage)
        .funPanel()
        .onAppear { store.start() }
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { store.isEnabled },
            set: { store.setEnabled($0) }
        )
    }
}
