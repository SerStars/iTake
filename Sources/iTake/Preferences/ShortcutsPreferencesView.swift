import SwiftUI

struct ShortcutsPreferencesView: View {
    @AppStorage(HotKeyLayoutSettings.useMacDefaultShortcutsKey) private
        var useMacDefaultShortcutsStored: Bool = false
    @State private var bindings: [HotKeyAction: HotKeyBinding] = Dictionary(
        uniqueKeysWithValues: HotKeyAction.allCases.map {
            ($0, HotKeyBindingStore.binding(for: $0))
        }
    )

    var body: some View {
        Form {
            Section {
                Toggle(
                    "Use macOS Default Shortcuts (⌘⇧3/4/5)",
                    isOn: Binding(
                        get: { useMacDefaultShortcutsStored },
                        set: { newValue in
                            guard HotKeyLayoutActions.confirmLayoutChange(useMacDefaults: newValue)
                            else { return }
                            HotKeyLayoutActions.applyLayoutChange(useMacDefaults: newValue)
                            useMacDefaultShortcutsStored = newValue
                            reloadBindings()
                        }
                    )
                )
                Text(
                    useMacDefaultShortcutsStored
                        ? "Resets all shortcuts below to macOS's own screenshot keys and disables the built-in Screenshot app for them."
                        : "Resets all shortcuts below to iTake's own, non-conflicting keys."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            } header: {
                Text("Quick Setup")
            }

            Section {
                ForEach(HotKeyAction.allCases) { action in
                    HStack {
                        Text(action.label)
                        Spacer()
                        HotKeyRecorderView(
                            displayString: HotKeyFormatter.string(
                                for: bindings[action] ?? action.customDefaultBinding),
                            onCapture: { keyCode, modifiers in
                                let newBinding = HotKeyBinding(
                                    keyCode: keyCode, modifiers: modifiers)

                                if HotKeyConflictActions.applyBinding(newBinding, to: action) {
                                    reloadBindings()
                                }
                            }
                        )
                        .frame(width: 110, height: 22)
                    }
                }
            } header: {
                Text("Individual Shortcuts")
            } footer: {
                Text(
                    "Click a shortcut and press a new key combination to change just that one. Esc cancels."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func reloadBindings() {
        bindings = Dictionary(
            uniqueKeysWithValues: HotKeyAction.allCases.map {
                ($0, HotKeyBindingStore.binding(for: $0))
            })
    }
}
