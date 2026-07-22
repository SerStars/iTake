import AppKit
import ScreenCaptureKit

private final class KeyableBorderlessWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class RegionSelectionOverlayController {
    private var windows: [NSWindow] = []
    private var displays: [SCDisplay] = []
    private var completion: ((SCDisplay, CGRect)?) -> Void = { _ in }

    func present(displays: [SCDisplay], completion: @escaping ((SCDisplay, CGRect)?) -> Void) {
        self.displays = displays
        self.completion = completion

        var newWindows: [NSWindow] = []
        for screen in NSScreen.screens {
            let window = KeyableBorderlessWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            window.isOpaque = false
            window.backgroundColor = .clear
            window.level = .screenSaver
            window.ignoresMouseEvents = false
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
            window.isReleasedWhenClosed = false

            let view = RegionSelectionOverlayView(
                frame: NSRect(origin: .zero, size: screen.frame.size))
            view.onComplete = { [weak self] cocoaRect in
                self?.finish(screen: screen, cocoaRect: cocoaRect)
            }
            view.onCancel = { [weak self] in
                self?.finish(screen: nil, cocoaRect: nil)
            }
            window.contentView = view
            window.makeKeyAndOrderFront(nil)
            newWindows.append(window)
        }

        windows = newWindows
        NSApp.activate(ignoringOtherApps: true)
    }

    private func finish(screen: NSScreen?, cocoaRect: NSRect?) {
        for window in windows {
            window.orderOut(nil)
        }
        windows = []

        guard let screen, let cocoaRect else {
            completion(nil)
            return
        }

        guard
            let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")]
                as? NSNumber,
            let display = displays.first(where: {
                $0.displayID == CGDirectDisplayID(displayID.uint32Value)
            })
        else {
            DebugLog.log("region selection: couldn't match NSScreen to an SCDisplay")
            completion(nil)
            return
        }

        // AppKit's coordinate space is bottom-left-origin (y up); SCStreamConfiguration.sourceRect
        // is top-left-origin (y down), local to the display flip before handing it off.
        let flippedY = screen.frame.height - cocoaRect.origin.y - cocoaRect.height
        let sourceRect = CGRect(
            x: cocoaRect.origin.x, y: flippedY, width: cocoaRect.width, height: cocoaRect.height)

        completion((display, sourceRect))
    }
}
