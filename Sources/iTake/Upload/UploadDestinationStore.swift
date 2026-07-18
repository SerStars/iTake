import Foundation

@MainActor
final class UploadDestinationStore: ObservableObject {
    static let shared = UploadDestinationStore()

    @Published private(set) var destinations: [UploadDestination] = []
    @Published private(set) var activeDestinationID: UUID?

    private let destinationsKey = "iTake.uploadDestinations"
    private let activeKey = "iTake.activeUploadDestinationID"

    private init() {
        load()
    }

    var active: UploadDestination? {
        destinations.first { $0.id == activeDestinationID }
    }

    func add(_ destination: UploadDestination) {
        destinations.append(destination)
        if activeDestinationID == nil {
            activeDestinationID = destination.id
        }
        save()
    }

    func remove(_ destination: UploadDestination) {
        for key in destination.headerKeys {
            KeychainHelper.deleteValue(forHeaderKey: key, destinationID: destination.id)
        }
        destinations.removeAll { $0.id == destination.id }
        if activeDestinationID == destination.id {
            activeDestinationID = destinations.first?.id
        }
        save()
    }

    func setActive(id: UUID?) {
        activeDestinationID = id
        save()
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: destinationsKey),
            let decoded = try? JSONDecoder().decode([UploadDestination].self, from: data)
        {
            destinations = decoded
        }
        if let idString = UserDefaults.standard.string(forKey: activeKey) {
            activeDestinationID = UUID(uuidString: idString)
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(destinations) {
            UserDefaults.standard.set(data, forKey: destinationsKey)
        }
        UserDefaults.standard.set(activeDestinationID?.uuidString, forKey: activeKey)
    }
}
