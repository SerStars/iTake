import SwiftUI

private enum UploaderEditorTarget: Identifiable {
    case add
    case edit(UploadDestination)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let destination): return destination.id.uuidString
        }
    }

    var existingDestination: UploadDestination? {
        if case .edit(let destination) = self { return destination }
        return nil
    }
}

struct UploaderPreferencesView: View {
    @EnvironmentObject private var uploadDestinationStore: UploadDestinationStore

    @AppStorage(UploadSettings.uploadAutomaticallyKey) private var uploadAutomatically: Bool = false
    @AppStorage(UploadSettings.autoCopyKey) private var autoCopyUploadedURL: Bool = true

    @State private var editorTarget: UploaderEditorTarget?

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
                    Button("Add") {
                        editorTarget = .add
                    }
                    Button("Import") {
                        UploaderFileActions.presentImportPanel()
                    }

                    if let active = uploadDestinationStore.active {
                        Button("Edit") {
                            editorTarget = .edit(active)
                        }
                        Button("Export") {
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
        .sheet(item: $editorTarget) { target in
            UploaderEditorView(
                existing: target.existingDestination,
                onSave: { destination in
                    if case .edit = target {
                        uploadDestinationStore.update(destination)
                    } else {
                        uploadDestinationStore.add(destination)
                    }
                    editorTarget = nil
                },
                onCancel: { editorTarget = nil }
            )
        }
    }
}
