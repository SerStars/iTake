import AppKit

@MainActor
enum UpdateCheckScheduler {
    private static let lastCheckKey = "iTake.lastUpdateCheckDate"
    private static let minInterval: TimeInterval = 24 * 60 * 60

    static func checkIfNeeded() {
        if let last = UserDefaults.standard.object(forKey: lastCheckKey) as? Date,
            Date().timeIntervalSince(last) < minInterval
        {
            return
        }
        UserDefaults.standard.set(Date(), forKey: lastCheckKey)

        Task {
            guard case .updateAvailable(let version, let url) = await UpdateChecker.checkForUpdate()
            else { return }

            StatusOverlayController.shared.show(
                title: "Update Available",
                subtitle: "v\(version) — click to view on GitHub",
                systemImage: "arrow.down.circle.fill",
                autoDismissDelay: nil,
                onTap: { NSWorkspace.shared.open(url) }
            )
        }
    }
}
