import AppKit
import SwiftUI

@MainActor
final class RecordingHUDWindowController {
    static let shared = RecordingHUDWindowController()

    private var panel: NSPanel?
    private var model: RecordingHUDModel?
    private var onStop: (() -> Void)?
    private var onTogglePause: (() -> Void)?

    private init() {}

    var currentWindowNumber: Int? {
        panel?.windowNumber
    }

    func show(onStop: @escaping () -> Void, onTogglePause: @escaping () -> Void) {
        self.onStop = onStop
        self.onTogglePause = onTogglePause

        guard let screen = NSScreen.main else { return }

        let hudModel = RecordingHUDModel()
        let view = RecordingHUDView(
            model: hudModel,
            onStop: { [weak self] in self?.onStop?() },
            onTogglePause: { [weak self] in self?.onTogglePause?() }
        )
        let hostingView = NSHostingView(rootView: view)
        hostingView.layoutSubtreeIfNeeded()
        let fitted = hostingView.fittingSize
        let size = CGSize(width: max(fitted.width, 100), height: max(fitted.height, 32))
        hostingView.frame = CGRect(origin: .zero, size: size)

        let origin = CGPoint(
            x: screen.visibleFrame.midX - size.width / 2,
            y: screen.visibleFrame.maxY - size.height - 12)

        let newPanel = NSPanel(
            contentRect: CGRect(origin: origin, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.level = .floating
        newPanel.hasShadow = true
        newPanel.isMovableByWindowBackground = true
        newPanel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        newPanel.contentView = hostingView
        newPanel.orderFrontRegardless()

        panel = newPanel
        model = hudModel
    }

    func updateElapsed(_ text: String) {
        model?.elapsed = text
    }

    func setPaused(_ paused: Bool) {
        model?.isPaused = paused
    }

    func hide() {
        panel?.orderOut(nil)
        panel = nil
        model = nil
        onStop = nil
        onTogglePause = nil
    }
}
