import SwiftUI

struct GeneralPreferencesView: View {
    @AppStorage(CaptureOutputSettings.saveToDiskKey) private var saveToDisk: Bool = true
    @State private var saveDirectoryPath: String = CaptureOutputSettings.saveDirectory.path
    @State private var launchAtLogin: Bool = LoginItemSettings.isEnabled
    @AppStorage(MenuBarIconSettings.iconKey) private var selectedMenuBarIcon: String =
        MenuBarIconSettings.defaultIcon
    @AppStorage(AnnotationSettings.openEditorAfterCaptureKey) private var openEditorAfterCapture =
        false
    @AppStorage(OCRTranslationSettings.autoCopyTranslationKey) private var autoCopyTranslation =
        false

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
                    Button("Reset to Default") {
                        CaptureOutputSettings.resetSaveDirectoryToDefault()
                        saveDirectoryPath = CaptureOutputSettings.saveDirectory.path
                    }
                    Button("Choose...") {
                        CaptureOutputActions.presentChooseSaveLocationPanel()
                        saveDirectoryPath = CaptureOutputSettings.saveDirectory.path
                    }
                }

                Toggle("Open Editor After Capture", isOn: $openEditorAfterCapture)
                Text(
                    "When off, use \"Capture Region (Edit)\" (Preferences -> Shortcuts) to mark up just one capture."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            } header: {
                Text("Captures")
            }

            Section {
                HStack(spacing: 10) {
                    ForEach(MenuBarIconSettings.choices, id: \.self) { icon in
                        Button {
                            selectedMenuBarIcon = icon
                        } label: {
                            Image(systemName: icon)
                                .font(.system(size: 16))
                                .frame(width: 32, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            icon == selectedMenuBarIcon
                                                ? Color.accentColor.opacity(0.2) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(
                                            icon == selectedMenuBarIcon
                                                ? Color.accentColor : Color.clear, lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
            } header: {
                Text("Menu Bar Icon")
            }

            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        LoginItemSettings.setEnabled(newValue)
                    }
            } header: {
                Text("Startup")
            }

            Section {
                Toggle("Auto-Copy Translation", isOn: $autoCopyTranslation)
            } header: {
                Text("OCR Translation")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
