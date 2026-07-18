import SwiftUI

struct GeneralPreferencesView: View {
    @AppStorage(CaptureOutputSettings.saveToDiskKey) private var saveToDisk: Bool = true
    @State private var saveDirectoryPath: String = CaptureOutputSettings.saveDirectory.path
    @State private var launchAtLogin: Bool = LoginItemSettings.isEnabled

    var body: some View {
        Form {
            Section {
                Toggle("Save to Disk", isOn: $saveToDisk)

                HStack {
                    Text(saveDirectoryPath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Choose...") {
                        CaptureOutputActions.presentChooseSaveLocationPanel()
                        saveDirectoryPath = CaptureOutputSettings.saveDirectory.path
                    }
                }
            } header: {
                Text("Captures")
            }

            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        LoginItemSettings.setEnabled(newValue)
                    }
            } header: {
                Text("Startup")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
