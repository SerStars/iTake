import AVFoundation
import Foundation

enum RecordingFormat: String, CaseIterable, Identifiable {
    case mov
    case mp4

    var id: String { rawValue }

    var label: String {
        switch self {
        case .mov: return "MOV"
        case .mp4: return "MP4"
        }
    }

    var fileType: AVFileType {
        switch self {
        case .mov: return .mov
        case .mp4: return .mp4
        }
    }
}

enum RecordingSettings {
    static let formatKey = "iTake.recordingFormat"
    static let includeSystemAudioKey = "iTake.recordingIncludeSystemAudio"

    static var format: RecordingFormat {
        get {
            guard let raw = UserDefaults.standard.string(forKey: formatKey),
                let format = RecordingFormat(rawValue: raw)
            else {
                return .mov
            }
            return format
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: formatKey)
        }
    }

    static var includeSystemAudio: Bool {
        get { UserDefaults.standard.bool(forKey: includeSystemAudioKey) }
        set { UserDefaults.standard.set(newValue, forKey: includeSystemAudioKey) }
    }
}

enum RecordingOutput {
    /// Shares CaptureOutputSettings' save-to-disk toggle and folder with screenshots.
    /// See CaptureOutput.newFileURL for why a temp location is used when that's off.
    static func newFileURL(format: RecordingFormat) -> URL {
        let directory: URL
        if CaptureOutputSettings.saveToDisk {
            directory = CaptureOutputSettings.saveDirectory
        } else {
            directory = FileManager.default.temporaryDirectory
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        return directory.appendingPathComponent(
            "Recording \(formatter.string(from: Date())).\(format.rawValue)")
    }
}
