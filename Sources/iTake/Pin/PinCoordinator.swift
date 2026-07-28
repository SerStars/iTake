import AppKit

struct PinnedCapture: Identifiable {
    let id: UUID
    let createdAt: Date
    let thumbnail: NSImage
    var isClickThrough: Bool = false
}

@MainActor
final class PinCoordinator: ObservableObject {
    static let shared = PinCoordinator()

    @Published private(set) var pins: [PinnedCapture] = []
    private var controllers: [UUID: PinnedCaptureWindowController] = [:]

    private init() {}

    func pinRegion() {
        guard ScreenCaptureService.ensurePermission() else {
            DebugLog.log("Screen Recording permission not granted, aborting pin capture")
            PermissionWarnings.showScreenRecordingDenied()
            return
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            "iTake-pin-\(UUID().uuidString).png")

        Task {
            do {
                guard
                    let savedURL = try await ScreenCaptureService.capture(
                        .interactiveArea, to: tempURL)
                else {
                    return  // user cancelled the selection
                }
                defer { try? FileManager.default.removeItem(at: savedURL) }

                let anchorPoint = NSEvent.mouseLocation

                guard let data = try? Data(contentsOf: savedURL), let image = NSImage(data: data)
                else {
                    DebugLog.log("Pin capture: could not load captured image")
                    return
                }

                pin(image: image, near: anchorPoint)
            } catch {
                DebugLog.log("Pin capture failed: \(error)")
            }
        }
    }

    func pin(image: NSImage, near anchorPoint: CGPoint? = nil) {
        let id = UUID()
        let controller = PinnedCaptureWindowController(
            image: image,
            anchorPoint: anchorPoint,
            onClose: { [weak self] in self?.unpin(id: id) },
            onRequestClickThrough: { [weak self] in self?.setClickThrough(true, id: id) }
        )
        controllers[id] = controller
        pins.append(
            PinnedCapture(id: id, createdAt: Date(), thumbnail: Self.thumbnail(from: image)))
        controller.show()
    }

    private static func thumbnail(from image: NSImage, maxDimension: CGFloat = 32) -> NSImage {
        let scale = min(1, maxDimension / max(image.size.width, image.size.height, 1))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let thumbnail = NSImage(size: size)
        thumbnail.lockFocus()
        image.draw(in: CGRect(origin: .zero, size: size))
        thumbnail.unlockFocus()
        return thumbnail
    }

    func unpin(id: UUID) {
        controllers[id]?.close()
        controllers[id] = nil
        pins.removeAll { $0.id == id }
    }

    func closeAll() {
        for id in pins.map(\.id) { unpin(id: id) }
    }

    func bringToFront(id: UUID) {
        controllers[id]?.bringToFront()
    }

    func toggleClickThrough(id: UUID) {
        guard let index = pins.firstIndex(where: { $0.id == id }) else { return }
        setClickThrough(!pins[index].isClickThrough, id: id)
    }

    private func setClickThrough(_ enabled: Bool, id: UUID) {
        guard let index = pins.firstIndex(where: { $0.id == id }) else { return }
        pins[index].isClickThrough = enabled
        controllers[id]?.setClickThrough(enabled)
    }
}
