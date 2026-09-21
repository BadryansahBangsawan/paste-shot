import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: PasteShotStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let errorMessage = store.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(store.isEnabled
                              ? Color.accentColor.opacity(0.18)
                              : Color(nsColor: .controlBackgroundColor))
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(store.isEnabled ? Color.accentColor : Color.secondary)
                }
                .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Paste Shot")
                        .font(.system(size: 13, weight: .semibold))
                    Text(store.isEnabled ? "On" : "Off")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                Toggle("Copy screenshots", isOn: enabledBinding)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .controlSize(.regular)
            }
            .accessibilityElement(children: .combine)
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
