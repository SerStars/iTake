import Carbon.HIToolbox

enum HotKeyAction: String, CaseIterable, Identifiable {
    case captureRegion
    case captureRegionEdit
    case captureFullScreen
    case captureWindow
    case captureText
    case captureTextTranslate
    case pinRegion
    case toggleRecording

    var id: String { rawValue }

    var label: String {
        switch self {
        case .captureRegion: return "Capture Region"
        case .captureRegionEdit: return "Capture Region (Edit)"
        case .captureFullScreen: return "Capture Full Screen"
        case .captureWindow: return "Capture Window"
        case .captureText: return "Capture Text"
        case .captureTextTranslate: return "Capture Text (Translate)"
        case .pinRegion: return "Pin Region"
        case .toggleRecording: return "Toggle Recording"
        }
    }

    private var defaultKeyCode: UInt32 {
        switch self {
        case .captureRegion: return UInt32(kVK_ANSI_2)
        case .captureRegionEdit: return UInt32(kVK_ANSI_1)
        case .captureFullScreen: return UInt32(kVK_ANSI_3)
        case .captureWindow: return UInt32(kVK_ANSI_4)
        case .captureText: return UInt32(kVK_ANSI_5)
        case .captureTextTranslate: return UInt32(kVK_ANSI_6)
        case .pinRegion: return UInt32(kVK_ANSI_7)
        case .toggleRecording: return UInt32(kVK_ANSI_R)
        }
    }

    /// Cmd+Ctrl+Shift+<key> never collides with any macOS default.
    var customDefaultBinding: HotKeyBinding {
        HotKeyBinding(keyCode: defaultKeyCode, modifiers: UInt32(cmdKey | controlKey | shiftKey))
    }

    /// Cmd+Shift+<key> matches macOS's own screenshot shortcuts; requires
    /// SystemScreenshotShortcuts to disable the system ones first.
    var macDefaultBinding: HotKeyBinding {
        HotKeyBinding(keyCode: defaultKeyCode, modifiers: UInt32(cmdKey | shiftKey))
    }
}
