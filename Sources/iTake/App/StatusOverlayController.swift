import AppKit
import SwiftUI

/// Small top-right corner confirmation.
@MainActor
final class StatusOverlayController {
    static let shared = StatusOverlayController()

    private static let margin: CGFloat = 12
    private static let autoDismissDelay: UInt64 = 2_500_000_000

    private var panel: NSPanel?
    private var dismissTask: Task<Void, Never>?

    private init() {}

    func show(title: String, systemImage: String) {
        dismissTask?.cancel()
        panel?.orderOut(nil)

        guard let screen = NSScreen.main else { return }

        let view = StatusOverlayView(
            title: title,
            systemImage: systemImage,
            onDismiss: { [weak self] in self?.dismiss() }
        )
        let hostingView = NSHostingView(rootView: view)
        hostingView.layoutSubtreeIfNeeded()
        let fitted = hostingView.fittingSize
        let size = CGSize(width: max(fitted.width, 180), height: max(fitted.height, 52))
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
            context.duration = 0.18
            newPanel.animator().alphaValue = 1
        }

        panel = newPanel

        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: Self.autoDismissDelay)
            guard !Task.isCancelled else { return }
            self?.dismiss()
        }
    }

    private func dismiss() {
        dismissTask?.cancel()
        guard let target = panel else { return }

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
