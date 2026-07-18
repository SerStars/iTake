import SwiftUI

struct RecordingSourcePickerView: View {
    let sources: [RecordingSource]
    let onSelect: (RecordingSource) -> Void
    let onCancel: () -> Void

    @AppStorage(RecordingSettings.formatKey) private var formatRaw: String = RecordingFormat.mov
        .rawValue
    @AppStorage(RecordingSettings.includeSystemAudioKey) private var includeSystemAudio: Bool =
        false

    var body: some View {
        VStack(spacing: 0) {
            Text("Record Screen")
                .font(.headline)
                .padding(.top, 16)
                .padding(.bottom, 8)

            Picker("Format", selection: $formatRaw) {
                ForEach(RecordingFormat.allCases) { format in
                    Text(format.label).tag(format.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            Toggle("Include System Audio", isOn: $includeSystemAudio)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            List(sources) { source in
                Button {
                    onSelect(source)
                } label: {
                    HStack(spacing: 10) {
                        Group {
                            if let icon = source.icon {
                                Image(nsImage: icon).resizable()
                            } else {
                                Image(systemName: "display").resizable().padding(3)
                            }
                        }
                        .frame(width: 22, height: 22)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(source.title)
                                .lineLimit(1)
                            if let subtitle = source.subtitle {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)

            Divider()

            HStack {
                Spacer()
                Button("Cancel", role: .cancel, action: onCancel)
                    .keyboardShortcut(.cancelAction)
            }
            .padding(10)
        }
        .frame(width: 320, height: 380)
    }
}
