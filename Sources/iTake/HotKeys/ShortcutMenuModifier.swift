import SwiftUI

extension View {
    @MainActor
    func applyingShortcut(for action: HotKeyAction) -> some View {
        let binding = HotKeyBindingStore.binding(for: action)
        if let key = HotKeyFormatter.keyEquivalent(for: binding) {
            return AnyView(self.keyboardShortcut(key, modifiers: HotKeyFormatter.eventModifiers(for: binding)))
        }
        return AnyView(self)
    }
}
