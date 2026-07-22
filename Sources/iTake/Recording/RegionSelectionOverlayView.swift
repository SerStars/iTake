import AppKit

final class RegionSelectionOverlayView: NSView {
    var onComplete: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private var dragStart: NSPoint?
    private var currentRect: NSRect = .zero
    private var isConfirming = false

    private let startButton = NSButton(title: "Start Recording", target: nil, action: nil)
    private let cancelButton = NSButton(title: "Cancel", target: nil, action: nil)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        startButton.bezelStyle = .rounded
        startButton.controlSize = .large
        startButton.bezelColor = .controlAccentColor
        startButton.keyEquivalent = "\r"
        startButton.target = self
        startButton.action = #selector(confirmTapped)
        startButton.isHidden = true

        cancelButton.bezelStyle = .rounded
        cancelButton.controlSize = .large
        cancelButton.keyEquivalent = "\u{1b}"
        cancelButton.target = self
        cancelButton.action = #selector(cancelTapped)
        cancelButton.isHidden = true

        addSubview(startButton)
        addSubview(cancelButton)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func mouseDown(with event: NSEvent) {
        isConfirming = false
        startButton.isHidden = true
        cancelButton.isHidden = true
        dragStart = convert(event.locationInWindow, from: nil)
        currentRect = .zero
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let dragStart else { return }
        let point = convert(event.locationInWindow, from: nil)
        currentRect = NSRect(
            x: min(dragStart.x, point.x),
            y: min(dragStart.y, point.y),
            width: abs(point.x - dragStart.x),
            height: abs(point.y - dragStart.y)
        )
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        dragStart = nil
        guard currentRect.width > 4, currentRect.height > 4 else {
            currentRect = .zero
            needsDisplay = true
            return
        }
        isConfirming = true
        positionControls()
        startButton.isHidden = false
        cancelButton.isHidden = false
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53:  // esc
            onCancel?()
        case 36:  // return
            if isConfirming { confirmTapped() }
        default:
            super.keyDown(with: event)
        }
    }

    @objc private func confirmTapped() {
        guard isConfirming else { return }
        onComplete?(currentRect)
    }

    @objc private func cancelTapped() {
        onCancel?()
    }

    private func positionControls() {
        startButton.sizeToFit()
        cancelButton.sizeToFit()

        let spacing: CGFloat = 10
        let totalWidth = startButton.frame.width + cancelButton.frame.width + spacing
        let barHeight = max(startButton.frame.height, cancelButton.frame.height)

        var barY = currentRect.minY - barHeight - 12
        if barY < 0 {
            barY = min(currentRect.maxY + 12, bounds.maxY - barHeight)
        }
        let barX = min(max(0, currentRect.midX - totalWidth / 2), bounds.maxX - totalWidth)

        cancelButton.setFrameOrigin(NSPoint(x: barX, y: barY))
        startButton.setFrameOrigin(
            NSPoint(x: barX + cancelButton.frame.width + spacing, y: barY))
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.2).setFill()
        bounds.fill()

        guard currentRect.width > 0, currentRect.height > 0 else { return }

        NSColor.clear.setFill()
        currentRect.fill(using: .copy)

        NSColor.white.setStroke()
        let border = NSBezierPath(rect: currentRect)
        border.lineWidth = 1.5
        border.stroke()

        let label =
            isConfirming
            ? "\(Int(currentRect.width)) × \(Int(currentRect.height)) — Enter to start, Esc to cancel"
            : "\(Int(currentRect.width)) × \(Int(currentRect.height))"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white,
        ]
        let textSize = label.size(withAttributes: attributes)
        let labelOrigin = NSPoint(
            x: currentRect.minX,
            y: min(currentRect.maxY + 4, bounds.maxY - textSize.height)
        )
        let labelRect = NSRect(origin: labelOrigin, size: textSize).insetBy(dx: -4, dy: -2)
        NSColor.black.withAlphaComponent(0.6).setFill()
        NSBezierPath(roundedRect: labelRect, xRadius: 3, yRadius: 3).fill()
        label.draw(at: labelOrigin, withAttributes: attributes)
    }
}
