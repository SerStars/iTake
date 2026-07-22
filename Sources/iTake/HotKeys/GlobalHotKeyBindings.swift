extension GlobalHotKeyManager {
    private static var boundCapture: CaptureCoordinator?
    private static var boundRecording: RecordingCoordinator?
    private static var boundOCR: OCRCoordinator?
    private static var registeredIDs: [UInt32] = []

    func registerDefaults(
        capture: CaptureCoordinator, recording: RecordingCoordinator, ocr: OCRCoordinator
    ) {
        Self.boundCapture = capture
        Self.boundRecording = recording
        Self.boundOCR = ocr
        reapplyAllBindings()
    }

    /// Re-registers every action's hotkey from HotKeyBindingStore. Calls after any binding changes.
    func reapplyAllBindings() {
        for id in Self.registeredIDs { unregister(id) }
        Self.registeredIDs.removeAll()

        guard let capture = Self.boundCapture, let recording = Self.boundRecording,
            let ocr = Self.boundOCR
        else { return }

        let actionHandlers: [(HotKeyAction, () -> Void)] = [
            (.captureRegion, { capture.captureArea() }),
            (.captureRegionEdit, { capture.captureAreaWithEditor() }),
            (.captureFullScreen, { capture.captureFullScreen() }),
            (.captureWindow, { capture.captureWindow() }),
            (.captureText, { ocr.captureText() }),
            (.toggleRecording, { recording.toggleRecording() }),
        ]

        for (action, handler) in actionHandlers {
            let binding = HotKeyBindingStore.binding(for: action)
            let id = register(
                keyCode: binding.keyCode, modifiers: binding.modifiers, handler: handler)
            Self.registeredIDs.append(id)
        }
    }

    /// Unregisters every hotkey without touching HotKeyBindingStore, used while the recorder field is capturing keystrokes.
    func suspendAll() {
        for id in Self.registeredIDs { unregister(id) }
        Self.registeredIDs.removeAll()
    }
}
