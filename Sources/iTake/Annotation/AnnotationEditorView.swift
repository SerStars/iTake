import SwiftUI

struct AnnotationEditorView: View {
    let image: NSImage
    let onSave: (NSImage) -> Void
    let onCancel: () -> Void

    @State private var annotations: [Annotation] = []
    @State private var undoStack: [[Annotation]] = []
    @State private var redoStack: [[Annotation]] = []
    @State private var selectedTool: AnnotationTool = .arrow
    @State private var selectedColor: Color = .red
    @State private var lineWidth: CGFloat = 4
    @State private var zoomLevel: CGFloat = 1
    @State private var selectedAnnotationID: UUID?
    @State private var editingAnnotationID: UUID?

    private var editingAnnotation: Annotation? {
        annotations.first { $0.id == editingAnnotationID }
    }

    var body: some View {
        VStack(spacing: 0) {
            AnnotationToolbar(
                selectedTool: $selectedTool,
                selectedColor: $selectedColor,
                lineWidth: $lineWidth,
                zoomLevel: $zoomLevel,
                canUndo: !undoStack.isEmpty,
                canRedo: !redoStack.isEmpty,
                onUndo: undo,
                onRedo: redo,
                onCancel: onCancel,
                onSave: save
            )

            Divider()

            AnnotationCanvasView(
                image: image,
                annotations: annotations,
                selectedTool: selectedTool,
                selectedColor: selectedColor,
                lineWidth: lineWidth,
                zoomLevel: $zoomLevel,
                selectedAnnotationID: $selectedAnnotationID,
                editingAnnotation: editingAnnotation,
                onAnnotationAdded: { annotation in
                    pushUndoSnapshot()
                    annotations.append(annotation)
                },
                onAnnotationMoved: { id, delta in
                    guard let index = annotations.firstIndex(where: { $0.id == id }) else { return }
                    annotations[index].shape = annotations[index].shape.translated(by: delta)
                },
                onAnnotationEdited: { id, newShape, newColor, newLineWidth in
                    guard let index = annotations.firstIndex(where: { $0.id == id }) else { return }
                    pushUndoSnapshot()
                    annotations[index].shape = newShape
                    annotations[index].color = newColor
                    annotations[index].lineWidth = newLineWidth
                    editingAnnotationID = nil
                },
                onAnnotationDeleted: { id in
                    pushUndoSnapshot()
                    annotations.removeAll { $0.id == id }
                },
                onEraseGestureBegan: {
                    pushUndoSnapshot()
                },
                onAnnotationErased: { id in
                    annotations.removeAll { $0.id == id }
                },
                onPathAnnotationErased: { id, newShapes in
                    guard let index = annotations.firstIndex(where: { $0.id == id }) else { return }
                    let original = annotations[index]
                    let replacements = newShapes.map { shape in
                        Annotation(
                            shape: shape, color: original.color, lineWidth: original.lineWidth)
                    }
                    annotations.replaceSubrange(index...index, with: replacements)
                },
                onTextEditRequested: { annotation in
                    editingAnnotationID = annotation.id
                    selectedColor = annotation.color
                    lineWidth = annotation.lineWidth
                },
                onEditCancelled: {
                    editingAnnotationID = nil
                }
            )
            .background(Color(nsColor: .textBackgroundColor))
        }
        .frame(minWidth: 480, minHeight: 360)
        .onChange(of: selectedAnnotationID) { _, _ in
            syncToolbarFromSelection()
        }
        .onChange(of: lineWidth) { _, _ in
            applyStyleToSelection()
        }
        .onChange(of: selectedColor) { _, _ in
            applyStyleToSelection()
        }
    }

    /// Reflects the just-selected annotation's own size/color in the toolbar
    private func syncToolbarFromSelection() {
        guard let selectedAnnotationID,
            let annotation = annotations.first(where: { $0.id == selectedAnnotationID })
        else { return }
        selectedColor = annotation.color
        lineWidth = annotation.lineWidth
    }

    private func applyStyleToSelection() {
        guard let selectedAnnotationID,
            let index = annotations.firstIndex(where: { $0.id == selectedAnnotationID })
        else { return }
        annotations[index].color = selectedColor
        annotations[index].lineWidth = lineWidth
    }

    private func pushUndoSnapshot() {
        undoStack.append(annotations)
        redoStack.removeAll()
    }

    private func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(annotations)
        annotations = previous
    }

    private func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(annotations)
        annotations = next
    }

    private func save() {
        onSave(AnnotationFlattener.flatten(image: image, annotations: annotations))
    }
}
