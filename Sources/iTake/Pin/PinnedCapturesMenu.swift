import SwiftUI

struct PinnedCapturesMenu: View {
    @ObservedObject private var pinCoordinator = PinCoordinator.shared

    var body: some View {
        if pinCoordinator.pins.isEmpty {
            Text("No Pinned Captures")
        } else {
            ForEach(pinCoordinator.pins) { pin in
                Menu {
                    Button("Bring to Front") {
                        pinCoordinator.bringToFront(id: pin.id)
                    }
                    Button(pin.isClickThrough ? "Disable Click-Through" : "Enable Click-Through") {
                        pinCoordinator.toggleClickThrough(id: pin.id)
                    }
                    Divider()
                    Button("Unpin", role: .destructive) {
                        pinCoordinator.unpin(id: pin.id)
                    }
                } label: {
                    Label {
                        Text(Self.timeFormatter.string(from: pin.createdAt))
                    } icon: {
                        Image(nsImage: pin.thumbnail)
                    }
                }
            }

            Divider()

            Button("Unpin All", role: .destructive) {
                pinCoordinator.closeAll()
            }
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}
