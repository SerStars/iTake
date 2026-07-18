import AppKit
import Carbon.HIToolbox
import SwiftUI

final class HotKeyRecorderField: NSTextField {
    var onCapture: ((UInt32, UInt32) -> Void)?

    var displayString: String = "" {
        didSet {
            if !isRecording { stringValue = displayString }
        }
    }

    private var isRecording = false {
        didSet {
            stringValue = isRecording ? "Press keys…" : displayString
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        isEditable = false
        isSelectable = false
        isBezeled = true
        bezelStyle = .roundedBezel
        alignment = .center
        font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        isRecording = true
        GlobalHotKeyManager.shared.suspendAll()
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else { return }

        if Int(event.keyCode) == kVK_Escape {
            isRecording = false
            window?.makeFirstResponder(nil)
            GlobalHotKeyManager.shared.reapplyAllBindings()
            return
        }

        let modifiers = Self.carbonModifiers(from: event.modifierFlags)
        guard modifiers != 0 else { return }  // keep waiting -- a modifier is required

        let keyCode = UInt32(event.keyCode)
        isRecording = false
        window?.makeFirstResponder(nil)
        onCapture?(keyCode, modifiers)
    }

    override func resignFirstResponder() -> Bool {
        if isRecording {
            isRecording = false
            GlobalHotKeyManager.shared.reapplyAllBindings()
        }
        return super.resignFirstResponder()
    }

    private static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.command) { result |= UInt32(cmdKey) }
        if flags.contains(.shift) { result |= UInt32(shiftKey) }
        if flags.contains(.option) { result |= UInt32(optionKey) }
        if flags.contains(.control) { result |= UInt32(controlKey) }
        return result
    }
}

struct HotKeyRecorderView: NSViewRepresentable {
    let displayString: String
    let onCapture: (UInt32, UInt32) -> Void

    func makeNSView(context: Context) -> HotKeyRecorderField {
        let field = HotKeyRecorderField(frame: .zero)
        field.displayString = displayString
        field.onCapture = onCapture
        return field
    }

    func updateNSView(_ nsView: HotKeyRecorderField, context: Context) {
        nsView.displayString = displayString
        nsView.onCapture = onCapture
    }
}
