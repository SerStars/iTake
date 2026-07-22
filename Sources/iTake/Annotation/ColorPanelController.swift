import AppKit
import SwiftUI

@MainActor
final class ColorPanelController: NSObject {
    static let shared = ColorPanelController()

    private var onColorChange: ((Color) -> Void)?

    private override init() {
        super.init()
    }

    func show(initialColor: Color, onChange: @escaping (Color) -> Void) {
        onColorChange = onChange
        let panel = NSColorPanel.shared
        panel.setTarget(self)
        panel.setAction(#selector(colorChanged(_:)))
        panel.color = NSColor(initialColor)
        panel.isContinuous = true
        panel.orderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func colorChanged(_ sender: NSColorPanel) {
        onColorChange?(Color(sender.color))
    }
}
