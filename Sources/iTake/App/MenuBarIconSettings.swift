import Foundation

enum MenuBarIconSettings {
    static let iconKey = "iTake.menuBarIcon"
    static let defaultIcon = "camera.viewfinder"

    static let choices = [
        "camera.viewfinder",
        "viewfinder",
        "camera.aperture",
        "photo.on.rectangle.angled",
        "rectangle.stack",
        "video",
    ]

    static var selectedIcon: String {
        get { UserDefaults.standard.string(forKey: iconKey) ?? defaultIcon }
        set { UserDefaults.standard.set(newValue, forKey: iconKey) }
    }
}
