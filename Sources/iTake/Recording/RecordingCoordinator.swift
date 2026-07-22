import AVFoundation
import AppKit

@MainActor
final class RecordingCoordinator: ObservableObject {
    private let appState: AppState
    private let service = ScreenRecordingService()
    private let sourcePicker = RecordingSourcePickerController()
    private var elapsedTimer: Task<Void, Never>?
    private var startDate: Date?
    private var isPaused = false
    private var pauseBeganAt: Date?

    init(appState: AppState) {
        self.appState = appState
    }

    func toggleRecording() {
        if appState.isRecording {
            stop()
        } else {
            start()
        }
    }

    private func start() {
        guard ScreenCaptureService.ensurePermission() else {
            DebugLog.log("Screen Recording permission not granted, aborting recording")
            return
        }
        sourcePicker.present(
            onSelect: { [weak self] source in
                self?.beginRecording(source: source)
            },
            onCancel: {}
        )
    }

    private func beginRecording(source: RecordingSource) {
        isPaused = false
        pauseBeganAt = nil

        // Show the HUD before starting the stream so its window exists and we can tell
        // ScreenCaptureKit to exclude it from a display-based capture
        RecordingHUDWindowController.shared.show(
            onStop: { [weak self] in self?.stop() },
            onTogglePause: { [weak self] in self?.togglePause() }
        )
        let hudWindowNumber = RecordingHUDWindowController.shared.currentWindowNumber

        Task {
            do {
                try await service.start(
                    source: source,
                    format: RecordingSettings.format,
                    excludingWindowNumbers: hudWindowNumber.map { [$0] } ?? [],
                    includeSystemAudio: RecordingSettings.includeSystemAudio
                )
                appState.isRecording = true
                startDate = Date()
                startElapsedTimer()
            } catch {
                DebugLog.log("failed to start recording: \(error)")
                RecordingHUDWindowController.shared.hide()
            }
        }
    }

    private func togglePause() {
        isPaused.toggle()

        if isPaused {
            pauseBeganAt = Date()
        } else if let pausedAt = pauseBeganAt {
            startDate = startDate?.addingTimeInterval(Date().timeIntervalSince(pausedAt))
            pauseBeganAt = nil
        }

        service.setPaused(isPaused)
        RecordingHUDWindowController.shared.setPaused(isPaused)
    }

    private func stop() {
        guard appState.isRecording else { return }

        elapsedTimer?.cancel()
        elapsedTimer = nil
        RecordingHUDWindowController.shared.hide()
        appState.isRecording = false
        isPaused = false
        pauseBeganAt = nil

        Task {
            do {
                let url = try await service.stop()
                showPreview(for: url)
            } catch {
                DebugLog.log("recording discarded: \(error)")
            }
        }
    }

    private func startElapsedTimer() {
        elapsedTimer = Task { [weak self] in
            while let self, !Task.isCancelled {
                guard let start = self.startDate else { break }
                if !self.isPaused {
                    let totalSeconds = max(0, Int(Date().timeIntervalSince(start)))
                    RecordingHUDWindowController.shared.updateElapsed(
                        Self.formatElapsed(totalSeconds))
                }
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }

    private static func formatElapsed(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let minutesText = minutes < 10 ? "0\(minutes)" : "\(minutes)"
        let secondsText = seconds < 10 ? "0\(seconds)" : "\(seconds)"
        return "\(minutesText):\(secondsText)"
    }

    private func showPreview(for url: URL) {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        do {
            let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
            let thumbnail = NSImage(cgImage: cgImage, size: .zero)
            CapturePreviewWindowController.shared.show(image: thumbnail, fileURL: url)
            CaptureHistoryStore.shared.add(fileURL: url, kind: .recording)
            UploadCoordinator.shared.handleCaptureCompletion(fileURL: url)
        } catch {
            DebugLog.log("failed to generate recording thumbnail: \(error)")
        }
    }
}
