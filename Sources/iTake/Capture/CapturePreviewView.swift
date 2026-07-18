import SwiftUI

struct CapturePreviewView: View {
    let image: NSImage
    let size: CGSize
    let onOpen: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white, .black.opacity(0.4))
            }
            .buttonStyle(.plain)
            .padding(6)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture(perform: onOpen)
        .shadow(color: .black.opacity(0.35), radius: 12, y: 5)
    }
}
