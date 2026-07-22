import AVFoundation
import AppKit

@MainActor
final class CaptureHistoryStore: ObservableObject {
    static let shared = CaptureHistoryStore()

    @Published private(set) var records: [CaptureRecord] = []

    private let maxRecords = 25
    private let indexURL: URL
    private let thumbnailsDirectory: URL

    private init() {
        let baseDir = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("iTake", isDirectory: true)
        try? FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)

        indexURL = baseDir.appendingPathComponent("history.json")
        thumbnailsDirectory = baseDir.appendingPathComponent("Thumbnails", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: thumbnailsDirectory, withIntermediateDirectories: true)

        load()
    }

    func add(fileURL: URL, kind: CaptureRecord.Kind) {
        let id = UUID()
        let thumbnailFileName = "\(id.uuidString).png"
        if let thumbnail = Self.makeThumbnail(for: fileURL, kind: kind),
            let data = Self.pngData(for: thumbnail)
        {
            try? data.write(to: thumbnailsDirectory.appendingPathComponent(thumbnailFileName))
        }

        records.insert(
            CaptureRecord(
                id: id, fileURL: fileURL, thumbnailFileName: thumbnailFileName, kind: kind),
            at: 0)
        trimIfNeeded()
        persist()
    }

    func attachUploadedURL(_ url: URL, forFileAt fileURL: URL) {
        guard let index = records.firstIndex(where: { $0.fileURL == fileURL }) else { return }
        records[index].uploadedURL = url
        persist()
    }

    func thumbnail(for record: CaptureRecord) -> NSImage? {
        NSImage(contentsOf: thumbnailsDirectory.appendingPathComponent(record.thumbnailFileName))
    }

    func remove(_ record: CaptureRecord) {
        try? FileManager.default.removeItem(at: record.fileURL)
        try? FileManager.default.removeItem(
            at: thumbnailsDirectory.appendingPathComponent(record.thumbnailFileName))
        records.removeAll { $0.id == record.id }
        persist()
    }

    func clearAll() {
        records.removeAll()
        try? FileManager.default.removeItem(at: thumbnailsDirectory)
        try? FileManager.default.createDirectory(
            at: thumbnailsDirectory, withIntermediateDirectories: true)
        persist()
    }

    private func trimIfNeeded() {
        while records.count > maxRecords {
            guard let last = records.popLast() else { break }
            try? FileManager.default.removeItem(
                at: thumbnailsDirectory.appendingPathComponent(last.thumbnailFileName))
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(records) {
            try? data.write(to: indexURL)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: indexURL),
            let decoded = try? JSONDecoder().decode([CaptureRecord].self, from: data)
        else { return }
        records = decoded.filter { FileManager.default.fileExists(atPath: $0.fileURL.path) }
    }

    private static func makeThumbnail(for fileURL: URL, kind: CaptureRecord.Kind) -> NSImage? {
        switch kind {
        case .screenshot:
            return NSImage(contentsOf: fileURL).map { resized($0, maxDimension: 160) }
        case .recording:
            let generator = AVAssetImageGenerator(asset: AVURLAsset(url: fileURL))
            generator.appliesPreferredTrackTransform = true
            guard let cgImage = try? generator.copyCGImage(at: .zero, actualTime: nil) else {
                return nil
            }
            return resized(NSImage(cgImage: cgImage, size: .zero), maxDimension: 160)
        }
    }

    private static func resized(_ image: NSImage, maxDimension: CGFloat) -> NSImage {
        let scale = min(1, maxDimension / max(image.size.width, image.size.height))
        let newSize = NSSize(width: image.size.width * scale, height: image.size.height * scale)
        let resized = NSImage(size: newSize)
        resized.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize))
        resized.unlockFocus()
        return resized
    }

    private static func pngData(for image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData)
        else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}
