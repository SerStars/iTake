import AppKit

@MainActor
enum CaptureOutputActions {
    static func presentChooseSaveLocationPanel() {
        let panel = NSOpenPanel()
        panel.title = "Choose Save Location"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = CaptureOutputSettings.saveDirectory

        guard panel.runModal() == .OK, let url = panel.url else { return }
        CaptureOutputSettings.saveDirectory = url
    }
}
