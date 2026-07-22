import AVFoundation
import AppKit
import CoreMedia
import ScreenCaptureKit

enum RecordingError: Error {
    case alreadyRecording
    case notRecording
    case writerSetupFailed
    case noFramesCaptured
}

/// All mutable state here is confined to `recordingQueue`, which is also the queue
/// ScreenCaptureKit delivers sample buffers on (passed as sampleHandlerQueue in start()).
/// An earlier version delivered frames on the main queue to sidestep actor isolation, which
/// caused intermittent broken/empty recordings whenever the main thread was busy with UI work.
final class ScreenRecordingService: NSObject, @unchecked Sendable {
    private let recordingQueue = DispatchQueue(label: "com.SerStars.iTake.recording")

    private var stream: SCStream?
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var audioInput: AVAssetWriterInput?
    private var sessionStarted = false
    private var isPaused = false
    private var outputURL: URL?
    private var frameCount = 0

    // Pause/resume timeline remapping: paused spans are cut out of the output entirely
    // (rather than freeze-holding the last frame for that real-world duration) by shifting
    // every subsequent frame's presentation time backwards by the accumulated paused time.
    // Applied to both video and audio so the two tracks stay in sync across a pause.
    private var pausedAccumulatedDuration: CMTime = .zero
    private var lastRawPresentationTime: CMTime?
    private var pendingResyncAfterPause = false

    func start(
        source: RecordingSource, format: RecordingFormat, excludingWindowNumbers: [Int] = [],
        includeSystemAudio: Bool = false
    ) async throws {
        let alreadyRecording = recordingQueue.sync { self.stream != nil }
        guard !alreadyRecording else { throw RecordingError.alreadyRecording }

        let filter: SCContentFilter
        let pointsWidth: Int
        let pointsHeight: Int
        var sourceRect: CGRect?

        switch source.kind {
        case .display(let display):
            let excluded = try await Self.resolveWindows(numbers: excludingWindowNumbers)
            filter = SCContentFilter(display: display, excludingWindows: excluded)
            pointsWidth = display.width
            pointsHeight = display.height
            DebugLog.log(
                "starting DISPLAY recording, excluding \(excluded.count)/\(excludingWindowNumbers.count) requested window(s)"
            )
        case .window(let window):
            filter = SCContentFilter(desktopIndependentWindow: window)
            pointsWidth = max(1, Int(window.frame.width))
            pointsHeight = max(1, Int(window.frame.height))
            DebugLog.log("starting WINDOW recording for windowID=\(window.windowID)")
        case .region(let display, let rect):
            let excluded = try await Self.resolveWindows(numbers: excludingWindowNumbers)
            filter = SCContentFilter(display: display, excludingWindows: excluded)
            pointsWidth = max(1, Int(rect.width))
            pointsHeight = max(1, Int(rect.height))
            sourceRect = rect
            DebugLog.log("starting REGION recording \(rect) on displayID=\(display.displayID)")
        }

        let scale = await MainActor.run { NSScreen.main?.backingScaleFactor ?? 2.0 }
        let pixelWidth = Int(CGFloat(pointsWidth) * scale)
        let pixelHeight = Int(CGFloat(pointsHeight) * scale)

        let config = SCStreamConfiguration()
        config.width = pixelWidth
        config.height = pixelHeight
        if let sourceRect {
            config.sourceRect = sourceRect
        }
        config.showsCursor = true
        config.minimumFrameInterval = CMTime(value: 1, timescale: 30)
        config.queueDepth = 6
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.capturesAudio = includeSystemAudio
        config.excludesCurrentProcessAudio = true

        let url = RecordingOutput.newFileURL(format: format)

        let writer = try AVAssetWriter(outputURL: url, fileType: format.fileType)
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: pixelWidth,
            AVVideoHeightKey: pixelHeight,
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        input.expectsMediaDataInRealTime = true

        // ScreenCaptureKit delivers raw (uncompressed) pixel buffers. Appending those directly
        // into an AVAssetWriterInput configured with compressed (H.264) output settings is not
        // actually a supported combination, it happened to accept a handful of frames before
        // AVFoundation failed the whole writer (AVFoundationErrorDomain -11800 / -16122). The
        // pixel buffer adaptor is the piece that's actually responsible for encoding raw frames
        // into the compressed track. It must be created before the input is added to the writer
        // and before startWriting() is called, doing it after (as an earlier version did)
        // throws an NSInternalInconsistencyException and crashes the app.
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: pixelWidth,
                kCVPixelBufferHeightKey as String: pixelHeight,
            ]
        )

        guard writer.canAdd(input) else {
            DebugLog.log(
                "writer cannot add video input for \(format.rawValue) (\(pixelWidth)x\(pixelHeight))"
            )
            throw RecordingError.writerSetupFailed
        }
        writer.add(input)

        // Unlike video, AVAssetWriterInput can accept raw PCM audio sample buffers directly via
        // append(_:) and encode them to AAC itself, no adaptor equivalent needed for audio.
        var newAudioInput: AVAssetWriterInput?
        if includeSystemAudio {
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 48000,
                AVNumberOfChannelsKey: 2,
                AVEncoderBitRateKey: 128_000,
            ]
            let audio = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            audio.expectsMediaDataInRealTime = true
            if writer.canAdd(audio) {
                writer.add(audio)
                newAudioInput = audio
            } else {
                DebugLog.log("writer cannot add audio input, continuing without system audio")
            }
        }

        guard writer.startWriting() else {
            DebugLog.log(
                "writer.startWriting() failed: \(writer.error?.localizedDescription ?? "unknown error")"
            )
            throw RecordingError.writerSetupFailed
        }

        recordingQueue.sync {
            self.assetWriter = writer
            self.videoInput = input
            self.pixelBufferAdaptor = adaptor
            self.audioInput = newAudioInput
            self.outputURL = url
            self.sessionStarted = false
            self.isPaused = false
            self.frameCount = 0
            self.pausedAccumulatedDuration = .zero
            self.lastRawPresentationTime = nil
            self.pendingResyncAfterPause = false
        }

        let newStream = SCStream(filter: filter, configuration: config, delegate: self)
        try newStream.addStreamOutput(self, type: .screen, sampleHandlerQueue: recordingQueue)
        if includeSystemAudio {
            try newStream.addStreamOutput(self, type: .audio, sampleHandlerQueue: recordingQueue)
        }
        try await newStream.startCapture()

        recordingQueue.sync {
            self.stream = newStream
        }
        DebugLog.log(
            "recording started, format=\(format.rawValue) size=\(pixelWidth)x\(pixelHeight) audio=\(includeSystemAudio) -> \(url.lastPathComponent)"
        )
    }

    /// Retries a few times: right after the HUD panel is ordered on screen, the window server
    /// may not have registered it yet, so SCShareableContent's enumeration can briefly miss it.
    private static func resolveWindows(numbers: [Int]) async throws -> [SCWindow] {
        guard !numbers.isEmpty else { return [] }
        let ids = Set(numbers.map { CGWindowID($0) })

        for attempt in 1...5 {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false, onScreenWindowsOnly: true)
            let matches = content.windows.filter { ids.contains($0.windowID) }
            DebugLog.log(
                "resolveWindows attempt \(attempt)/5 — want \(ids), matched \(matches.count) of \(content.windows.count) on-screen windows"
            )
            if matches.count == ids.count {
                return matches
            }
            if attempt < 5 {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }

        DebugLog.log(
            "resolveWindows giving up after retries — recording will NOT exclude window(s) \(ids)")
        return []
    }

    func setPaused(_ paused: Bool) {
        recordingQueue.sync {
            if self.isPaused && !paused {
                self.pendingResyncAfterPause = true
            }
            self.isPaused = paused
        }
    }

    @discardableResult
    func stop() async throws -> URL {
        let snapshot:
            (stream: SCStream, writer: AVAssetWriter, url: URL, hadFrames: Bool, frameCount: Int)? =
                recordingQueue.sync {
                    guard let stream, let assetWriter, let outputURL else { return nil }
                    return (stream, assetWriter, outputURL, sessionStarted, frameCount)
                }
        guard let snapshot else {
            throw RecordingError.notRecording
        }
        DebugLog.log("stopping recording, \(snapshot.frameCount) frame(s) captured so far")

        try? await snapshot.stream.stopCapture()

        recordingQueue.sync {
            self.stream = nil
            self.videoInput?.markAsFinished()
            self.audioInput?.markAsFinished()
        }

        defer {
            recordingQueue.sync {
                self.assetWriter = nil
                self.videoInput = nil
                self.pixelBufferAdaptor = nil
                self.audioInput = nil
                self.outputURL = nil
                self.sessionStarted = false
                self.isPaused = false
            }
        }

        guard snapshot.hadFrames else {
            // Stopped before a single frame arrived (example: stop pressed almost immediately
            // after start). Finishing here would just produce a broken/empty file.
            snapshot.writer.cancelWriting()
            try? FileManager.default.removeItem(at: snapshot.url)
            DebugLog.log("recording stopped before any frames were captured; discarded")
            throw RecordingError.noFramesCaptured
        }

        await snapshot.writer.finishWriting()
        if snapshot.writer.status == .failed {
            DebugLog.log(
                "writer.finishWriting() failed: \(snapshot.writer.error?.localizedDescription ?? "unknown error")"
            )
            throw snapshot.writer.error ?? RecordingError.writerSetupFailed
        }
        DebugLog.log(
            "recording finished successfully -> \(snapshot.url.lastPathComponent), status=\(snapshot.writer.status.rawValue)"
        )

        return snapshot.url
    }

    /// Audio sample buffers don't take a separate presentationTime argument to append() the way
    /// the video pixel buffer adaptor does, so keeping audio in sync with the pause-remapped
    /// video timeline means constructing a retimed copy of the buffer instead.
    private func retimedSampleBuffer(_ sampleBuffer: CMSampleBuffer, subtracting offset: CMTime)
        -> CMSampleBuffer?
    {
        guard offset.seconds != 0 else { return sampleBuffer }

        var count: CMItemCount = 0
        guard
            CMSampleBufferGetSampleTimingInfoArray(
                sampleBuffer, entryCount: 0, arrayToFill: nil, entriesNeededOut: &count) == noErr,
            count > 0
        else {
            return sampleBuffer
        }

        var timingInfos = [CMSampleTimingInfo](repeating: CMSampleTimingInfo(), count: count)
        guard
            CMSampleBufferGetSampleTimingInfoArray(
                sampleBuffer, entryCount: count, arrayToFill: &timingInfos, entriesNeededOut: nil)
                == noErr
        else {
            return sampleBuffer
        }

        for i in 0..<timingInfos.count {
            timingInfos[i].presentationTimeStamp = CMTimeSubtract(
                timingInfos[i].presentationTimeStamp, offset)
            if timingInfos[i].decodeTimeStamp.isValid {
                timingInfos[i].decodeTimeStamp = CMTimeSubtract(
                    timingInfos[i].decodeTimeStamp, offset)
            }
        }

        var newSampleBuffer: CMSampleBuffer?
        let status = CMSampleBufferCreateCopyWithNewTiming(
            allocator: kCFAllocatorDefault,
            sampleBuffer: sampleBuffer,
            sampleTimingEntryCount: timingInfos.count,
            sampleTimingArray: &timingInfos,
            sampleBufferOut: &newSampleBuffer
        )
        guard status == noErr else { return sampleBuffer }
        return newSampleBuffer
    }
}

extension ScreenRecordingService: SCStreamOutput {
    func stream(
        _ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of outputType: SCStreamOutputType
    ) {
        // Always invoked on recordingQueue (passed as sampleHandlerQueue above), so touching
        // this state directly here is safe without any extra locking.
        guard sampleBuffer.isValid, !isPaused else { return }
        guard let writer = assetWriter, writer.status == .writing else { return }

        let rawPresentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        if pendingResyncAfterPause, let lastTime = lastRawPresentationTime {
            let pausedGap = CMTimeSubtract(rawPresentationTime, lastTime)
            if pausedGap.isValid && pausedGap.seconds > 0 {
                pausedAccumulatedDuration = CMTimeAdd(pausedAccumulatedDuration, pausedGap)
            }
            pendingResyncAfterPause = false
        }

        switch outputType {
        case .screen:
            guard let input = videoInput,
                let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            else { return }
            let presentationTime = CMTimeSubtract(rawPresentationTime, pausedAccumulatedDuration)

            if !sessionStarted {
                writer.startSession(atSourceTime: presentationTime)
                sessionStarted = true
            }

            if input.isReadyForMoreMediaData {
                if pixelBufferAdaptor?.append(pixelBuffer, withPresentationTime: presentationTime)
                    == true
                {
                    frameCount += 1
                    lastRawPresentationTime = rawPresentationTime
                } else {
                    DebugLog.log(
                        "pixelBufferAdaptor.append failed, writer.status=\(writer.status.rawValue) error=\(writer.error?.localizedDescription ?? "none")"
                    )
                }
            }
        case .audio:
            guard sessionStarted, let input = audioInput, input.isReadyForMoreMediaData else {
                return
            }
            guard
                let retimed = retimedSampleBuffer(
                    sampleBuffer, subtracting: pausedAccumulatedDuration)
            else { return }
            if input.append(retimed) {
                lastRawPresentationTime = rawPresentationTime
            }
        @unknown default:
            break
        }
    }
}

extension ScreenRecordingService: SCStreamDelegate {
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        DebugLog.log("recording stream stopped with error: \(error)")
    }
}
