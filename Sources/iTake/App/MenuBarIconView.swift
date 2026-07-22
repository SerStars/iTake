import SwiftUI

struct MenuBarIconView: View {
    @AppStorage(MenuBarIconSettings.iconKey) private var selectedIcon: String =
        MenuBarIconSettings.defaultIcon

    var body: some View {
        Image(systemName: selectedIcon)
    }
}
