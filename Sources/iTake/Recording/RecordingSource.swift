import AppKit
import ScreenCaptureKit

struct RecordingSource: Identifiable {
    enum Kind {
        case display(SCDisplay)
        case window(SCWindow)
        case region(SCDisplay, CGRect)
    }

    let id: String
    let kind: Kind
    let title: String
    let subtitle: String?
    let icon: NSImage?
}
