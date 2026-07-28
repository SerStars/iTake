import Foundation

/// Plain-file logging -- DEBUG builds only (SwiftPM defines DEBUG for the .debug configuration
/// automatically), so no log file or NSLog output ships in a release build. `log(_:)` compiles
/// down to a no-op there.

enum DebugLog {
    #if DEBUG
        static let fileURL: URL = {
            let dir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
                "Library/Logs/iTake", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            return dir.appendingPathComponent("debug.log")
        }()

        private static let formatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            return formatter
        }()
    #endif

    static func log(_ message: String) {
        #if DEBUG
            let line = "[\(formatter.string(from: Date()))] \(message)\n"
            NSLog("iTake: \(message)")

            guard let data = line.data(using: .utf8) else { return }
            if let handle = try? FileHandle(forWritingTo: fileURL) {
                defer { try? handle.close() }
                handle.seekToEndOfFile()
                handle.write(data)
            } else {
                try? data.write(to: fileURL)
            }
        #endif
    }
}
