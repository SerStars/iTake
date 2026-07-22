import SwiftUI

struct HistoryWindowView: View {
    @ObservedObject private var historyStore = CaptureHistoryStore.shared

    var body: some View {
        Group {
            if historyStore.records.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("No Captures Yet")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(historyStore.records) { record in
                        HistoryRow(record: record)
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .frame(minWidth: 460, idealWidth: 520, minHeight: 320, idealHeight: 420)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Clear All", role: .destructive) {
                    historyStore.clearAll()
                }
                .disabled(historyStore.records.isEmpty)
            }
        }
    }
}

private struct HistoryRow: View {
    @ObservedObject private var historyStore = CaptureHistoryStore.shared
    let record: CaptureRecord

    private var fileExists: Bool {
        FileManager.default.fileExists(atPath: record.fileURL.path)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(record.fileURL.deletingPathExtension().lastPathComponent)
                    .lineLimit(1)
                Text(Self.dateFormatter.string(from: record.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 14) {
                if fileExists {
                    Button {
                        NSWorkspace.shared.activateFileViewerSelecting([record.fileURL])
                    } label: {
                        Image(systemName: "folder")
                    }
                    .help("Reveal in Finder")

                    Button {
                        RecentCaptureActions.copy(record)
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .help("Copy")
                }

                if let uploadedURL = record.uploadedURL {
                    Button {
                        RecentCaptureActions.copyLink(uploadedURL)
                    } label: {
                        Image(systemName: "link")
                    }
                    .help("Copy Link")
                } else if fileExists {
                    Button {
                        UploadCoordinator.shared.uploadFile(at: record.fileURL)
                    } label: {
                        Image(systemName: "icloud.and.arrow.up")
                    }
                    .help("Upload")
                }

                Button(role: .destructive) {
                    RecentCaptureActions.delete(record)
                } label: {
                    Image(systemName: fileExists ? "trash" : "xmark.circle")
                }
                .help(fileExists ? "Delete" : "Remove")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let image = historyStore.thumbnail(for: record) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Rectangle()
                .fill(.quaternary)
                .overlay(Image(systemName: record.kind == .recording ? "video" : "photo"))
        }
    }
}
