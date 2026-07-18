import AppKit
import SwiftUI

@MainActor
final class CapturePreviewWindowController {
    static let shared = CapturePreviewWindowController()

    private static let maxSize = CGSize(width: 500, height: 367)
    private static let minSize = CGSize(width: 220, height: 160)
    private static let margin: CGFloat = 12
    private static let autoDismissDelay: UInt64 = 5_000_000_000

    private var panel: NSPanel?
    private var dismissTask: Task<Void, Never>?

    private init() {}

    /// Sizes the card to the screenshot's own aspect ratio (scaled to fit within maxSize), rather than a fixed square.
    private func cardSize(for image: NSImage) -> CGSize {
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return Self.maxSize }

        let scale = min(
            Self.maxSize.width / imageSize.width, Self.maxSize.height / imageSize.height, 1)
        let fitted = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)

        return CGSize(
            width: max(fitted.width, Self.minSize.width),
            height: max(fitted.height, Self.minSize.height))
    }

    func show(image: NSImage, fileURL: URL) {
        dismissTask?.cancel()
        panel?.orderOut(nil)

        guard let screen = NSScreen.main else { return }
        let size = cardSize(for: image)
        let origin = CGPoint(
            x: screen.visibleFrame.maxX - size.width - Self.margin,
            y: screen.visibleFrame.maxY - size.height - Self.margin
        )

        let newPanel = NSPanel(
            contentRect: CGRect(origin: origin, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.level = .floating
        newPanel.hasShadow = false
        newPanel.ignoresMouseEvents = false
        newPanel.collectionBehavior = [.canJoinAllSpaces, .stationary]

        let view = CapturePreviewView(
            image: image,
            size: size,
            onOpen: { [weak self] in
                NSWorkspace.shared.open(fileURL)
                self?.dismiss(newPanel)
            },
            onDismiss: { [weak self] in
                self?.dismiss(newPanel)
            }
        )
        newPanel.contentView = NSHostingView(rootView: view)
        newPanel.alphaValue = 0
        newPanel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            newPanel.animator().alphaValue = 1
        }

        panel = newPanel

        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: Self.autoDismissDelay)
            guard !Task.isCancelled else { return }
            self?.dismiss(newPanel)
        }
    }

    private func dismiss(_ target: NSPanel) {
        dismissTask?.cancel()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            target.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            target.orderOut(nil)
            Task { @MainActor in
                if self?.panel === target {
                    self?.panel = nil
                }
            }
        }
    }
}
