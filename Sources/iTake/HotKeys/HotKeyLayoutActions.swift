import AppKit

@MainActor
enum HotKeyLayoutActions {
    /// Shows a blocking confirmation before actually switching layouts, since this reaches
    /// outside the app to change a macOS system preference.
    static func confirmLayoutChange(useMacDefaults: Bool) -> Bool {
        let alert = NSAlert()
        if useMacDefaults {
            alert.messageText = "Use macOS's Default Screenshot Shortcuts?"
            alert.informativeText = """
                iTake will take over ⌘⇧3 (Full Screen), ⌘⇧4 (Window), and ⌘⇧5 (Capture Text), and \
                macOS's own Screenshot app will stop responding to them. \
                You can switch back anytime from this menu. This also \
                resets any shortcuts you've individually customized below.
                """
        } else {
            alert.messageText = "Switch Back to iTake's Own Shortcuts?"
            alert.informativeText = """
                This restores macOS's built-in screenshot shortcuts (⌘⇧3/4/5) and moves iTake back \
                to ⌃⌘⇧2/3/4/5. This also resets any shortcuts you've individually customized below.
                """
        }
        alert.addButton(withTitle: "Continue")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        return alert.runModal() == .alertFirstButtonReturn
    }

    static func applyLayoutChange(useMacDefaults: Bool) {
        HotKeyLayoutSettings.useMacDefaultShortcuts = useMacDefaults
        HotKeyBindingStore.resetAll(useMacDefaults: useMacDefaults)
        SystemScreenshotShortcuts.setEnabled(!useMacDefaults)
        SystemScreenshotShortcuts.restartSystemUIServer()
        GlobalHotKeyManager.shared.reapplyAllBindings()
    }
}
