import Foundation

@MainActor
enum HotKeyBindingStore {
    private static func storageKey(for action: HotKeyAction) -> String {
        "iTake.hotkey.\(action.rawValue)"
    }

    static func binding(for action: HotKeyAction) -> HotKeyBinding {
        if let data = UserDefaults.standard.data(forKey: storageKey(for: action)),
            let decoded = try? JSONDecoder().decode(HotKeyBinding.self, from: data)
        {
            return decoded
        }
        let fallback =
            HotKeyLayoutSettings.useMacDefaultShortcuts
            ? action.macDefaultBinding : action.customDefaultBinding
        setBinding(fallback, for: action)
        return fallback
    }

    static func setBinding(_ binding: HotKeyBinding, for action: HotKeyAction) {
        if let data = try? JSONEncoder().encode(binding) {
            UserDefaults.standard.set(data, forKey: storageKey(for: action))
        }
        HotKeyBindingsObserver.shared.notifyChanged()
    }

    static func resetAll(useMacDefaults: Bool) {
        for action in HotKeyAction.allCases {
            setBinding(
                useMacDefaults ? action.macDefaultBinding : action.customDefaultBinding, for: action
            )
        }
    }
}
