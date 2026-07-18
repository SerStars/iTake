import Foundation

enum HotKeyLayoutSettings {
    static let useMacDefaultShortcutsKey = "iTake.useMacDefaultShortcuts"

    static var useMacDefaultShortcuts: Bool {
        get { UserDefaults.standard.bool(forKey: useMacDefaultShortcutsKey) }
        set { UserDefaults.standard.set(newValue, forKey: useMacDefaultShortcutsKey) }
    }
}
