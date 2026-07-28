import SwiftUI

@MainActor
final class PinDisplayState: ObservableObject {
    @Published var isClickThrough = false
}

struct PinnedCaptureView: View {
    let image: NSImage
    @ObservedObject var displayState: PinDisplayState
    let onClose: () -> Void
    let onRequestClickThrough: () -> Void

    @State private var isHovering = false

    var body: some View {
        ZStack(alignment: .top) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)

            if isHovering && !displayState.isClickThrough {
                HStack(spacing: 6) {
                    Button(action: onRequestClickThrough) {
                        Image(systemName: "cursorarrow.click.2")
                    }
                    .help("Make Click-Through (use the menu bar's Pinned Captures menu to undo)")

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                    }
                    .help("Unpin")
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.black.opacity(0.55), in: Capsule())
                .padding(.top, 6)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
        .onHover { hovering in
            guard !displayState.isClickThrough else { return }
            isHovering = hovering
        }
    }
}
