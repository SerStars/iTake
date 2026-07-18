import SwiftUI

@main
struct iTakeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState: AppState
    @StateObject private var captureCoordinator: CaptureCoordinator
    @StateObject private var recordingCoordinator: RecordingCoordinator
    @StateObject private var ocrCoordinator: OCRCoordinator

    init() {
        let state = AppState()
        let capture = CaptureCoordinator()
        let recording = RecordingCoordinator(appState: state)
        let ocr = OCRCoordinator()

        _appState = StateObject(wrappedValue: state)
        _captureCoordinator = StateObject(wrappedValue: capture)
        _recordingCoordinator = StateObject(wrappedValue: recording)
        _ocrCoordinator = StateObject(wrappedValue: ocr)

        GlobalHotKeyManager.shared.registerDefaults(
            capture: capture, recording: recording, ocr: ocr)
    }

    var body: some Scene {
        MenuBarExtra("iTake", systemImage: "camera.viewfinder") {
            MenuBarContentView()
                .environmentObject(appState)
                .environmentObject(captureCoordinator)
                .environmentObject(recordingCoordinator)
                .environmentObject(ocrCoordinator)
                .environmentObject(UploadDestinationStore.shared)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            PreferencesView()
                .environmentObject(appState)
                .environmentObject(UploadDestinationStore.shared)
        }
    }
}
