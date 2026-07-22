import SwiftUI

struct AnnotationToolbar: View {
    @Binding var selectedTool: AnnotationTool
    @Binding var selectedColor: Color
    @Binding var lineWidth: CGFloat
    let canUndo: Bool
    let canRedo: Bool
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onCancel: () -> Void
    let onSave: () -> Void

    private static let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .white, .black]

    var body: some View {
        HStack(spacing: 14) {
            HStack(spacing: 4) {
                ForEach(AnnotationTool.allCases) { tool in
                    Button {
                        selectedTool = tool
                    } label: {
                        Image(systemName: tool.systemImage)
                            .frame(width: 28, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(tool == selectedTool ? Color.accentColor.opacity(0.25) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .help(tool.label)
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
                                colors: [.red, .yellow, .green, .blue, .purple, .red], center: .center)
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
                .help("Size (stroke width, text size, badge size)")

            Spacer()

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
