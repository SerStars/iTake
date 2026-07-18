import AppKit

@MainActor
enum HotKeyConflictActions {

    @discardableResult
    static func applyBinding(_ newBinding: HotKeyBinding, to action: HotKeyAction) -> Bool {
        defer { GlobalHotKeyManager.shared.reapplyAllBindings() }

        guard
            let conflicting = HotKeyAction.allCases.first(where: {
                $0 != action && HotKeyBindingStore.binding(for: $0) == newBinding
            })
        else {
            HotKeyBindingStore.setBinding(newBinding, for: action)
            return true
        }

        let alert = NSAlert()
        alert.messageText = "Shortcut Already In Use"
        alert.informativeText =
            "\(HotKeyFormatter.string(for: newBinding)) is already assigned to \"\(conflicting.label)\". Swap the two shortcuts?"
        alert.addButton(withTitle: "Swap")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)

        guard alert.runModal() == .alertFirstButtonReturn else { return false }

        let previousBinding = HotKeyBindingStore.binding(for: action)
        HotKeyBindingStore.setBinding(newBinding, for: action)
        HotKeyBindingStore.setBinding(previousBinding, for: conflicting)
        return true
    }
}
