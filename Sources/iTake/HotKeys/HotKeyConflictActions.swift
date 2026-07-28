import AppKit

@MainActor
enum HotKeyConflictActions {
    static func applyBinding(
        _ newBinding: HotKeyBinding, to action: HotKeyAction,
        completion: @escaping (Bool) -> Void
    ) {
        guard
            let conflicting = HotKeyAction.allCases.first(where: {
                $0 != action && HotKeyBindingStore.binding(for: $0) == newBinding
            })
        else {
            HotKeyBindingStore.setBinding(newBinding, for: action)
            GlobalHotKeyManager.shared.reapplyAllBindings()
            completion(true)
            return
        }

        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Shortcut Already In Use"
            alert.informativeText =
                "\(HotKeyFormatter.string(for: newBinding)) is already assigned to \"\(conflicting.label)\". Swap the two shortcuts?"
            alert.addButton(withTitle: "Swap")
            alert.addButton(withTitle: "Cancel")
            NSApp.activate(ignoringOtherApps: true)

            let response = alert.runModal()
            defer { GlobalHotKeyManager.shared.reapplyAllBindings() }

            guard response == .alertFirstButtonReturn else {
                completion(false)
                return
            }

            let previousBinding = HotKeyBindingStore.binding(for: action)
            HotKeyBindingStore.setBinding(newBinding, for: action)
            HotKeyBindingStore.setBinding(previousBinding, for: conflicting)
            completion(true)
        }
    }
}
