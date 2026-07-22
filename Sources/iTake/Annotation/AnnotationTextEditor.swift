import AppKit
import SwiftUI

struct AnnotationTextEditor: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont
    var color: NSColor
    var onCommit: () -> Void
    var onCancel: () -> Void

    func makeNSView(context: Context) -> AnnotationTextEditingView {
        let view = AnnotationTextEditingView()
        view.text = text
        view.font = font
        view.textColor = color
        view.onCommit = onCommit
        view.onCancel = onCancel
        view.onTextChange = { text = $0 }
        DispatchQueue.main.async {
            _ = view.window?.makeFirstResponder(view.textView)
        }
        return view
    }

    func updateNSView(_ nsView: AnnotationTextEditingView, context: Context) {
        nsView.text = text
        nsView.font = font
        nsView.textColor = color
        nsView.onCommit = onCommit
        nsView.onCancel = onCancel
        nsView.onTextChange = { text = $0 }
    }
}

final class AnnotationTextEditingView: NSView {
    var onCommit: (() -> Void)?
    var onCancel: (() -> Void)?
    var onTextChange: ((String) -> Void)?

    let textView: InternalTextView

    override init(frame frameRect: NSRect) {
        textView = InternalTextView(frame: frameRect)
        super.init(frame: frameRect)

        textView.isRichText = false
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.delegate = self
        textView.autoresizingMask = [.width, .height]
        textView.frame = bounds
        addSubview(textView)

        textView.onReturn = { [weak self] shiftHeld in
            guard !shiftHeld else { return false }
            self?.onCommit?()
            return true
        }
        textView.onEscape = { [weak self] in self?.onCancel?() }
        textView.onResignFirstResponder = { [weak self] in self?.onCommit?() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var text: String {
        get { textView.string }
        set { if textView.string != newValue { textView.string = newValue } }
    }

    var font: NSFont? {
        get { textView.font }
        set {
            textView.font = newValue
            if let newValue, let textStorage = textView.textStorage, textStorage.length > 0 {
                textStorage.addAttribute(
                    .font, value: newValue, range: NSRange(location: 0, length: textStorage.length))
            }
        }
    }

    var textColor: NSColor? {
        get { textView.textColor }
        set {
            textView.textColor = newValue
            if let newValue, let textStorage = textView.textStorage, textStorage.length > 0 {
                textStorage.addAttribute(
                    .foregroundColor, value: newValue, range: NSRange(location: 0, length: textStorage.length))
            }
        }
    }
}

extension AnnotationTextEditingView: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        onTextChange?(textView.string)
    }
}

final class InternalTextView: NSTextView {
    var onReturn: ((Bool) -> Bool)?
    var onEscape: (() -> Void)?
    var onResignFirstResponder: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 {  // return
            if onReturn?(event.modifierFlags.contains(.shift)) == true {
                return
            }
        } else if event.keyCode == 53 {  // esc
            onEscape?()
            return
        }
        super.keyDown(with: event)
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result {
            onResignFirstResponder?()
        }
        return result
    }
}
