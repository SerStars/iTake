import Combine

@MainActor
final class HotKeyBindingsObserver: ObservableObject {
    static let shared = HotKeyBindingsObserver()

    @Published private(set) var revision = 0

    private init() {}

    func notifyChanged() {
        revision += 1
    }
}
