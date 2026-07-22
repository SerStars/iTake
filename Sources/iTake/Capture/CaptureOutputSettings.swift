import Foundation

enum CaptureOutputSettings {
    static let saveToDiskKey = "iTake.saveToDisk"
    static let saveDirectoryKey = "iTake.saveDirectoryPath"

    static var saveToDisk: Bool {
        get {
            if UserDefaults.standard.object(forKey: saveToDiskKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: saveToDiskKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: saveToDiskKey) }
    }

    static var saveDirectory: URL {
        get {
            if let path = UserDefaults.standard.string(forKey: saveDirectoryKey) {
                return URL(fileURLWithPath: path, isDirectory: true)
            }
            return defaultDirectory
        }
        set {
            try? FileManager.default.createDirectory(
                at: newValue, withIntermediateDirectories: true)
            UserDefaults.standard.set(newValue.path, forKey: saveDirectoryKey)
        }
    }

    static func resetSaveDirectoryToDefault() {
        UserDefaults.standard.removeObject(forKey: saveDirectoryKey)
    }

    /// Matches wherever the system screenshot tool is configured to save
    /// (`defaults read com.apple.screencapture location`), falling back to ~/Desktop
    private static let defaultDirectory: URL = {
        let dir: URL
        if let customPath = UserDefaults(suiteName: "com.apple.screencapture")?.string(
            forKey: "location"),
            !customPath.isEmpty
        {
            dir = URL(
                fileURLWithPath: (customPath as NSString).expandingTildeInPath, isDirectory: true)
        } else {
            dir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
                "Desktop", isDirectory: true)
        }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()
}
