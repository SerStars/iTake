import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var isRecording: Bool = false
}
