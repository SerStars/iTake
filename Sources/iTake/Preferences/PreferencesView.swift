import SwiftUI

struct PreferencesView: View {
    var body: some View {
        TabView {
            GeneralPreferencesView()
                .tabItem { Label("General", systemImage: "gearshape") }

            UploaderPreferencesView()
                .tabItem { Label("Uploader", systemImage: "arrow.up.circle") }

            ShortcutsPreferencesView()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
        }
        .frame(width: 460, height: 480)
    }
}
