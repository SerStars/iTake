import AppKit
import SwiftUI

/// Only ever shown if UploadCoordinator decides an upload is taking long enough to be worth
/// showing (2 seconds delay), fast uploads never trigger this at all.
@MainActor
final class UploadProgressOverlayController {
    static let shared = UploadProgressOverlayController()

    private static let margin: CGFloat = 12

    private var panel: NSPanel?
    private var model: UploadProgressModel?

    private init() {}

    func show() {
        guard panel == nil else { return }
        guard let screen = NSScreen.main else { return }

        let progressModel = UploadProgressModel()
        let view = UploadProgressOverlayView(model: progressModel)
        let hostingView = NSHostingView(rootView: view)
        hostingView.layoutSubtreeIfNeeded()
        let fitted = hostingView.fittingSize
        let size = CGSize(width: max(fitted.width, 200), height: max(fitted.height, 52))
        hostingView.frame = CGRect(origin: .zero, size: size)

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
        newPanel.hasShadow = true
        newPanel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        newPanel.contentView = hostingView
        newPanel.alphaValue = 0
        newPanel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            newPanel.animator().alphaValue = 1
        }

        panel = newPanel
        model = progressModel
    }

    func update(progress: Double) {
        model?.progress = progress
    }

    func hide() {
        guard let target = panel else { return }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            target.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            target.orderOut(nil)
            Task { @MainActor in
                if self?.panel === target {
                    self?.panel = nil
                    self?.model = nil
                }
            }
        }
    }
}
