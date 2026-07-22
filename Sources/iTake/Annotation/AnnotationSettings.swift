import Foundation

enum AnnotationSettings {
    static let openEditorAfterCaptureKey = "iTake.openEditorAfterCapture"

    static var openEditorAfterCapture: Bool {
        get { UserDefaults.standard.bool(forKey: openEditorAfterCaptureKey) }
        set { UserDefaults.standard.set(newValue, forKey: openEditorAfterCaptureKey) }
    }
}
