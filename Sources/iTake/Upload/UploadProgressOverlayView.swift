import SwiftUI

final class UploadProgressModel: ObservableObject {
    @Published var progress: Double = 0
}

struct UploadProgressOverlayView: View {
    @ObservedObject var model: UploadProgressModel

    var body: some View {
        HStack(spacing: 10) {
            ProgressView(value: model.progress)
                .progressViewStyle(.circular)
                .controlSize(.small)
                .tint(.white)

            Text("Uploading... \(Int(model.progress * 100))%")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color.black.opacity(0.8), in: Capsule())
        .fixedSize()
    }
}
