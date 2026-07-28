import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var captureCoordinator: CaptureCoordinator
    @EnvironmentObject private var recordingCoordinator: RecordingCoordinator
    @EnvironmentObject private var ocrCoordinator: OCRCoordinator
    @EnvironmentObject private var uploadDestinationStore: UploadDestinationStore
    @ObservedObject private var hotKeyBindingsObserver = HotKeyBindingsObserver.shared
    @ObservedObject private var pinCoordinator = PinCoordinator.shared

    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button {
            captureCoordinator.captureArea()
        } label: {
            Label("Capture Region", systemImage: "crop")
        }
        .applyingShortcut(for: .captureRegion)

        Button {
            captureCoordinator.captureAreaWithEditor()
        } label: {
            Label("Capture Region (Edit)", systemImage: "crop.rotate")
        }
        .applyingShortcut(for: .captureRegionEdit)

        Button {
            captureCoordinator.captureFullScreen()
        } label: {
            Label("Capture Full Screen", systemImage: "display")
        }
        .applyingShortcut(for: .captureFullScreen)

        Button {
            captureCoordinator.captureWindow()
        } label: {
            Label("Capture Window", systemImage: "macwindow")
        }
        .applyingShortcut(for: .captureWindow)

        Button {
            ocrCoordinator.captureText()
        } label: {
            Label("Capture Text", systemImage: "text.viewfinder")
        }
        .applyingShortcut(for: .captureText)

        Button {
            ocrCoordinator.captureTextWithTranslation()
        } label: {
            Label("Capture Text (Translate)", systemImage: "globe")
        }
        .applyingShortcut(for: .captureTextTranslate)

        Button {
            pinCoordinator.pinRegion()
        } label: {
            Label("Pin Region", systemImage: "pin")
        }
        .applyingShortcut(for: .pinRegion)

        if !pinCoordinator.pins.isEmpty {
            Menu {
                PinnedCapturesMenu()
            } label: {
                Label("Pinned Captures", systemImage: "pin.fill")
            }
        }

        Divider()

        Button {
            recordingCoordinator.toggleRecording()
        } label: {
            Label(
                appState.isRecording ? "Stop Recording" : "Record Screen",
                systemImage: appState.isRecording ? "stop.circle" : "record.circle"
            )
        }
        .applyingShortcut(for: .toggleRecording)

        Button {
            UploaderFileActions.presentUploadFilePanel()
        } label: {
            Label("Upload File...", systemImage: "square.and.arrow.up")
        }

        Menu {
            RecentCapturesMenu()
        } label: {
            Label("Recent Captures", systemImage: "clock.arrow.circlepath")
        }

        if !uploadDestinationStore.destinations.isEmpty {
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

        Divider()

        Button {
            AboutPanelController.show()
        } label: {
            Label("About iTake", systemImage: "info.circle")
        }

        Button {
            NSApp.activate(ignoringOtherApps: true)
            openSettings()
        } label: {
            Label("Preferences", systemImage: "gearshape")
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Label("Quit iTake", systemImage: "power")
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
