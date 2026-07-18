import AppKit
import ScreenCaptureKit
import SwiftUI

@MainActor
final class RecordingSourcePickerController {
    private var window: NSWindow?

    func present(onSelect: @escaping (RecordingSource) -> Void, onCancel: @escaping () -> Void) {
        Task {
            do {
                let sources = try await Self.loadSources()
                guard !sources.isEmpty else {
                    DebugLog.log("no recordable displays or windows found")
                    onCancel()
                    return
                }
                self.show(sources: sources, onSelect: onSelect, onCancel: onCancel)
            } catch {
                DebugLog.log("failed to load recording sources: \(error)")
                onCancel()
            }
        }
    }

    private static func loadSources() async throws -> [RecordingSource] {
        let content = try await SCShareableContent.excludingDesktopWindows(
            true, onScreenWindowsOnly: false)

        var sources: [RecordingSource] = []

        for (index, display) in content.displays.enumerated() {
            sources.append(
                RecordingSource(
                    id: "display-\(display.displayID)",
                    kind: .display(display),
                    title: content.displays.count > 1 ? "Display \(index + 1)" : "Entire Screen",
                    subtitle: "\(display.width) × \(display.height)",
                    icon: nil
                ))
        }

        let ownBundleID = Bundle.main.bundleIdentifier
        for window in content.windows where window.windowLayer == 0 {
            guard let app = window.owningApplication, app.bundleIdentifier != ownBundleID else {
                continue
            }
            guard let title = window.title, !title.isEmpty else { continue }

            let icon = NSRunningApplication(processIdentifier: app.processID)?.icon
            sources.append(
                RecordingSource(
                    id: "window-\(window.windowID)",
                    kind: .window(window),
                    title: title,
                    subtitle: app.applicationName,
                    icon: icon
                ))
        }

        return sources
    }

    private func show(
        sources: [RecordingSource], onSelect: @escaping (RecordingSource) -> Void,
        onCancel: @escaping () -> Void
    ) {
        let panel = NSPanel(
            contentRect: CGRect(x: 0, y: 0, width: 320, height: 380),
            styleMask: [.titled, .closable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "Record Screen"
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.center()

        let view = RecordingSourcePickerView(
            sources: sources,
            onSelect: { [weak self] source in
                self?.close()
                onSelect(source)
            },
            onCancel: { [weak self] in
                self?.close()
                onCancel()
            }
        )
        panel.contentView = NSHostingView(rootView: view)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        window = panel
    }

    private func close() {
        window?.orderOut(nil)
        window = nil
    }
}
