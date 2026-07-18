import SwiftUI

final class RecordingHUDModel: ObservableObject {
    @Published var elapsed: String = "00:00"
    @Published var isPaused: Bool = false
}

struct RecordingHUDView: View {
    @ObservedObject var model: RecordingHUDModel
    let onStop: () -> Void
    let onTogglePause: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(model.isPaused ? Color.gray : Color.red)
                .frame(width: 8, height: 8)

            Text(model.elapsed)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)
                .fixedSize()

            Button(action: onTogglePause) {
                Image(systemName: model.isPaused ? "play.fill" : "pause.fill")
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            Button(action: onStop) {
                Image(systemName: "stop.fill")
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.8), in: Capsule())
        .fixedSize()
    }
}
