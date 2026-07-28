import SwiftUI

struct AnnotationToolbar: View {
    @Binding var selectedTool: AnnotationTool
    @Binding var selectedColor: Color
    @Binding var lineWidth: CGFloat
    @Binding var zoomLevel: CGFloat
    let canUndo: Bool
    let canRedo: Bool
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onCancel: () -> Void
    let onSave: () -> Void

    private static let colors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .white, .black,
    ]
    private static let zoomRange: ClosedRange<CGFloat> = 0.25...4
    private static let zoomStep: CGFloat = 0.25

    var body: some View {
        HStack(spacing: 14) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(AnnotationTool.allCases) { tool in
                        Button {
                            selectedTool = tool
                        } label: {
                            Image(systemName: tool.systemImage)
                                .frame(width: 28, height: 28)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            tool == selectedTool
                                                ? Color.accentColor.opacity(0.25) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                        .help(tool.label)
                    }
                }
            }

            Divider().frame(height: 20)

            HStack(spacing: 5) {
                ForEach(Self.colors, id: \.self) { color in
                    Button {
                        selectedColor = color
                    } label: {
                        Circle()
                            .fill(color)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle().stroke(
                                    Color.primary.opacity(color == selectedColor ? 0.9 : 0.15),
                                    lineWidth: color == selectedColor ? 2 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    ColorPanelController.shared.show(initialColor: selectedColor) { newColor in
                        selectedColor = newColor
                    }
                } label: {
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: [.red, .yellow, .green, .blue, .purple, .red],
                                center: .center)
                        )
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(Color.primary.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help("Custom Color…")
            }

            Divider().frame(height: 20)

            Slider(value: $lineWidth, in: 1...12)
                .frame(width: 90)
                .help("Size (stroke width, brush width, text size, badge size)")

            Spacer()

            HStack(spacing: 2) {
                Button {
                    zoomLevel = max(Self.zoomRange.lowerBound, zoomLevel - Self.zoomStep)
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                }
                .disabled(zoomLevel <= Self.zoomRange.lowerBound)
                .keyboardShortcut("-", modifiers: .command)
                .help("Zoom Out (⌘-)")

                Button {
                    zoomLevel = 1
                } label: {
                    Text(String(Int((zoomLevel * 100).rounded())) + "%")
                        .font(.system(size: 11))
                        .frame(width: 38)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("0", modifiers: .command)
                .help("Reset Zoom (⌘0)")

                Button {
                    zoomLevel = min(Self.zoomRange.upperBound, zoomLevel + Self.zoomStep)
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                }
                .disabled(zoomLevel >= Self.zoomRange.upperBound)
                .keyboardShortcut("=", modifiers: .command)
                .help("Zoom In (⌘+)")
            }

            Divider().frame(height: 20)

            Button {
                onUndo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!canUndo)
            .keyboardShortcut("z", modifiers: .command)
            .help("Undo (⌘Z)")

            Button {
                onRedo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!canRedo)
            .keyboardShortcut("z", modifiers: [.command, .shift])
            .help("Redo (⌘⇧Z)")

            Button("Cancel", role: .cancel, action: onCancel)

            Button("Save", action: onSave)
                .keyboardShortcut(.defaultAction)
        }
        .padding(10)
    }
}
