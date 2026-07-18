import Foundation

enum UploadSettings {
    static let uploadAutomaticallyKey = "iTake.uploadAutomatically"
    static let autoCopyKey = "iTake.autoCopyUploadedURL"

    /// Independent of CaptureOutputSettings.saveToDisk -- both, either, or neither can be on.
    static var uploadAutomatically: Bool {
        get { UserDefaults.standard.bool(forKey: uploadAutomaticallyKey) }
        set { UserDefaults.standard.set(newValue, forKey: uploadAutomaticallyKey) }
    }

    static var autoCopyUploadedURL: Bool {
        get {
            if UserDefaults.standard.object(forKey: autoCopyKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: autoCopyKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: autoCopyKey) }
    }
}
