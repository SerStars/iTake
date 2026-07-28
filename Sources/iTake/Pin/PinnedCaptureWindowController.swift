import AppKit
import SwiftUI

@MainActor
final class PinnedCaptureWindowController {
    private static let maxDimension: CGFloat = 420
    private static var cascadeStep = 0
    private static let clickThroughHoverAlpha: CGFloat = 0.2

    private var panel: NSPanel?
    private let displayState = PinDisplayState()
    private var globalMouseMonitor: Any?
    private var isHoveringWhileClickThrough = false

    init(
        image: NSImage, anchorPoint: CGPoint?, onClose: @escaping () -> Void,
        onRequestClickThrough: @escaping () -> Void
    ) {
        let scale = min(1, Self.maxDimension / max(image.size.width, image.size.height, 1))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let newPanel = NSPanel(
            contentRect: CGRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.level = .floating
        newPanel.hasShadow = true
        newPanel.isReleasedWhenClosed = false
        newPanel.isMovableByWindowBackground = true
        newPanel.hidesOnDeactivate = false
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let view = PinnedCaptureView(
            image: image, displayState: displayState, onClose: onClose,
            onRequestClickThrough: onRequestClickThrough)
        newPanel.contentView = NSHostingView(rootView: view)

        newPanel.setFrameOrigin(Self.origin(for: size, anchorPoint: anchorPoint))

        panel = newPanel
    }

    private static func origin(for size: CGSize, anchorPoint: CGPoint?) -> CGPoint {
        if let anchorPoint {
            let screen = NSScreen.screens.first { $0.frame.contains(anchorPoint) } ?? NSScreen.main
            let raw = CGPoint(x: anchorPoint.x - size.width / 2, y: anchorPoint.y - size.height / 2)
            guard let visibleFrame = screen?.visibleFrame else { return raw }
            return CGPoint(
                x: min(max(raw.x, visibleFrame.minX), visibleFrame.maxX - size.width),
                y: min(max(raw.y, visibleFrame.minY), visibleFrame.maxY - size.height))
        }

        guard let screen = NSScreen.main else { return .zero }
        let offset = CGFloat(cascadeStep % 10) * 24
        cascadeStep += 1
        return CGPoint(
            x: screen.visibleFrame.midX - size.width / 2 + offset,
            y: screen.visibleFrame.midY - size.height / 2 - offset)
    }

    func show() {
        panel?.orderFrontRegardless()
    }

    func close() {
        panel?.orderOut(nil)
        panel = nil
        stopGlobalHoverMonitor()
    }

    func bringToFront() {
        panel?.orderFrontRegardless()
    }

    func setClickThrough(_ enabled: Bool) {
        panel?.ignoresMouseEvents = enabled
        displayState.isClickThrough = enabled

        if enabled {
            startGlobalHoverMonitor()
        } else {
            stopGlobalHoverMonitor()
            isHoveringWhileClickThrough = false
            panel?.animator().alphaValue = 1
        }
    }

    private func startGlobalHoverMonitor() {
        stopGlobalHoverMonitor()
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) {
            [weak self] _ in
            guard let self else { return }
            let isInside = self.panel?.frame.contains(NSEvent.mouseLocation) ?? false
            Task { @MainActor in
                self.updateHoverWhileClickThrough(isInside)
            }
        }
    }

    private func updateHoverWhileClickThrough(_ isInside: Bool) {
        guard isHoveringWhileClickThrough != isInside else { return }
        isHoveringWhileClickThrough = isInside
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            panel?.animator().alphaValue = isInside ? Self.clickThroughHoverAlpha : 1
        }
    }

    private func stopGlobalHoverMonitor() {
        if let globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
        }
        globalMouseMonitor = nil
    }
}
