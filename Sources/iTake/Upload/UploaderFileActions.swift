import AppKit
import UniformTypeIdentifiers

@MainActor
enum UploaderFileActions {
    static func presentImportPanel() {
        let panel = NSOpenPanel()
        panel.title = "Import Uploader"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = itupTypes()

        guard panel.runModal() == .OK, let url = panel.url else { return }
        importFile(at: url, promptConfirmation: false)
    }

    /// Used both by the panel above and by double-clicking a .itup file in Finder (see
    /// AppDelegate.application(_:open:)).
    static func importFile(at url: URL, promptConfirmation: Bool) {
        do {
            let data = try Data(contentsOf: url)
            let file = try JSONDecoder().decode(ExternalUploaderFile.self, from: data)

            if promptConfirmation {
                let alert = NSAlert()
                alert.messageText = "Import Uploader “\(file.name)”?"
                alert.informativeText =
                    "Captures uploaded with this destination will be sent to:\n\(file.request.url)"
                alert.addButton(withTitle: "Import")
                alert.addButton(withTitle: "Cancel")
                NSApp.activate(ignoringOtherApps: true)
                guard alert.runModal() == .alertFirstButtonReturn else { return }
            }

            let destination = UploadDestination.fromExternalFile(file)
            UploadDestinationStore.shared.add(destination)
            StatusOverlayController.shared.show(
                title: "Imported \"\(destination.name)\"", systemImage: "checkmark.circle.fill")
        } catch {
            DebugLog.log("uploader import failed: \(error)")
            StatusOverlayController.shared.show(title: "Import Failed", systemImage: "xmark.circle")
        }
    }

    static func presentExportPanel(for destination: UploadDestination) {
        guard let data = destination.exportData() else {
            StatusOverlayController.shared.show(title: "Export Failed", systemImage: "xmark.circle")
            return
        }

        let panel = NSSavePanel()
        panel.title = "Export Uploader"
        panel.allowedContentTypes = itupTypes()
        panel.nameFieldStringValue = "\(destination.name).itup"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try data.write(to: url)
            StatusOverlayController.shared.show(
                title: "Exported \"\(destination.name)\"", systemImage: "checkmark.circle.fill")
        } catch {
            DebugLog.log("uploader export failed: \(error)")
            StatusOverlayController.shared.show(title: "Export Failed", systemImage: "xmark.circle")
        }
    }

    static func presentUploadFilePanel() {
        guard UploadDestinationStore.shared.active != nil else {
            StatusOverlayController.shared.show(
                title: "No Uploader Selected", systemImage: "xmark.circle")
            return
        }

        let panel = NSOpenPanel()
        panel.title = "Upload File"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
        UploadCoordinator.shared.uploadFile(at: url)
    }

    private static func itupTypes() -> [UTType] {
        if let itup = UTType("com.serstars.itake.itup") {
            return [itup]
        }
        if let itup = UTType(filenameExtension: "itup") {
            return [itup]
        }
        return [.json]
    }
}
