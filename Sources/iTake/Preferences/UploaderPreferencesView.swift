import SwiftUI

struct UploaderPreferencesView: View {
    @EnvironmentObject private var uploadDestinationStore: UploadDestinationStore

    @AppStorage(UploadSettings.uploadAutomaticallyKey) private var uploadAutomatically: Bool = false
    @AppStorage(UploadSettings.autoCopyKey) private var autoCopyUploadedURL: Bool = true

    var body: some View {
        Form {
            Section {
                Toggle("Upload Automatically", isOn: $uploadAutomatically)
                Toggle("Auto Copy Link", isOn: $autoCopyUploadedURL)
            } header: {
                Text("On Capture")
            }

            Section {
                if uploadDestinationStore.destinations.isEmpty {
                    Text("No uploaders imported")
                        .foregroundStyle(.secondary)
                } else {
                    Picker(
                        "Active Uploader",
                        selection: Binding(
                            get: { uploadDestinationStore.activeDestinationID },
                            set: { uploadDestinationStore.setActive(id: $0) }
                        )
                    ) {
                        ForEach(uploadDestinationStore.destinations) { destination in
                            Text(destination.name).tag(Optional(destination.id))
                        }
                    }
                }

                HStack {
                    Button("Import Uploader...") {
                        UploaderFileActions.presentImportPanel()
                    }

                    if let active = uploadDestinationStore.active {
                        Button("Export...") {
                            UploaderFileActions.presentExportPanel(for: active)
                        }
                        Button("Remove", role: .destructive) {
                            uploadDestinationStore.remove(active)
                        }
                    }
                }
            } header: {
                Text("Destinations")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
