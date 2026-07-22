import AppKit
import SwiftUI

struct RecentCapturesMenu: View {
    @ObservedObject private var historyStore = CaptureHistoryStore.shared

    var body: some View {
        if historyStore.records.isEmpty {
            Text("No Recent Captures")
        } else {
            ForEach(historyStore.records) { record in
                let hasFile = RecentCaptureActions.hasLocalFile(record)
                Menu {
                    if hasFile {
                        Button("Reveal in Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([record.fileURL])
                        }
                        Button("Copy") {
                            RecentCaptureActions.copy(record)
                        }
                        if record.uploadedURL == nil {
                            Button("Upload") {
                                UploadCoordinator.shared.uploadFile(at: record.fileURL)
                            }
                        }
                    }
                    if let uploadedURL = record.uploadedURL {
                        Button("Copy Link") {
                            RecentCaptureActions.copyLink(uploadedURL)
                        }
                    }
                    Divider()
                    Button(hasFile ? "Delete" : "Remove", role: .destructive) {
                        RecentCaptureActions.delete(record)
                    }
                } label: {
                    label(for: record)
                }
            }

            Divider()

            Button("Show All Captures...") {
                HistoryWindowController.show()
            }
            Button("Clear All", role: .destructive) {
                historyStore.clearAll()
            }
        }
    }

    @ViewBuilder
    private func label(for record: CaptureRecord) -> some View {
        let title = record.fileURL.deletingPathExtension().lastPathComponent
        if let thumbnail = historyStore.thumbnail(for: record) {
            Label {
                Text(title)
            } icon: {
                Image(nsImage: thumbnail)
            }
        } else {
            Text(title)
        }
    }
}
