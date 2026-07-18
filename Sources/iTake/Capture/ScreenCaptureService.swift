import AppKit
import CoreGraphics

enum ScreenCaptureError: Error {
    case encodingFailed
}

enum ScreenCaptureMode {
    case interactiveArea
    case interactiveWindow
    case fullScreen

    /// Flags for screencapture. -i is interactive (the same picker as Cmd+Shift+4),
    /// -s/-w pin that picker to rectangle-select or window-select mode.
    var arguments: [String] {
        switch self {
        case .interactiveArea: return ["-i", "-s"]
        case .interactiveWindow: return ["-i", "-w"]
        case .fullScreen: return ["-m"]
        }
    }
}

enum ScreenCaptureService {
    static func ensurePermission() -> Bool {
        if CGPreflightScreenCaptureAccess() {
            return true
        }
        return CGRequestScreenCaptureAccess()
    }

    /// Runs screencapture for the given mode, writing a PNG to `url`.
    /// Returns nil if the user cancelled an interactive capture (Esc).
    static func capture(_ mode: ScreenCaptureMode, to url: URL) async throws -> URL? {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = mode.arguments + [url.path]

            let stderrPipe = Pipe()
            process.standardError = stderrPipe

            process.terminationHandler = { proc in
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrText = String(data: stderrData, encoding: .utf8) ?? ""
                DebugLog.log(
                    "screencapture exited status=\(proc.terminationStatus) stderr=\(stderrText)")

                if FileManager.default.fileExists(atPath: url.path) {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
