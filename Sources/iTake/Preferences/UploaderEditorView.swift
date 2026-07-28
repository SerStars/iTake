import SwiftUI

struct UploaderEditorView: View {
    private struct KeyValuePair: Identifiable {
        let id = UUID()
        var key: String = ""
        var value: String = ""
    }

    private let existingID: UUID?
    let onSave: (UploadDestination) -> Void
    let onCancel: () -> Void

    @State private var name: String
    @State private var url: String
    @State private var method: String
    @State private var bodyType: UploadDestination.BodyType
    @State private var fileFormName: String
    @State private var responseLinkPath: String
    @State private var headerPairs: [KeyValuePair]
    @State private var fieldPairs: [KeyValuePair]

    init(
        existing: UploadDestination?,
        onSave: @escaping (UploadDestination) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.existingID = existing?.id
        self.onSave = onSave
        self.onCancel = onCancel

        _name = State(initialValue: existing?.name ?? "")
        _url = State(initialValue: existing?.requestURL ?? "")
        _method = State(initialValue: existing?.httpMethod ?? "POST")
        _bodyType = State(initialValue: existing?.bodyType ?? .multipart)
        _fileFormName = State(initialValue: existing?.fileFormName ?? "file")
        _responseLinkPath = State(initialValue: existing?.responseLinkPath ?? "")

        if let existing {
            let storedHeaders = KeychainHelper.headers(
                destinationID: existing.id, expectedKeys: existing.headerKeys)
            _headerPairs = State(
                initialValue: existing.headerKeys.map { key in
                    KeyValuePair(key: key, value: storedHeaders[key] ?? "")
                })
            _fieldPairs = State(
                initialValue: existing.formData.map { KeyValuePair(key: $0.key, value: $0.value) })
        } else {
            _headerPairs = State(initialValue: [])
            _fieldPairs = State(initialValue: [])
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && URL(string: url) != nil
            && !responseLinkPath.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Destination") {
                    TextField("Name", text: $name)
                    TextField("URL", text: $url)
                    Picker("Method", selection: $method) {
                        Text("POST").tag("POST")
                        Text("PUT").tag("PUT")
                    }
                }

                Section("Request Body") {
                    Picker("Type", selection: $bodyType) {
                        Text("Multipart Form").tag(UploadDestination.BodyType.multipart)
                        Text("Raw Body").tag(UploadDestination.BodyType.binary)
                    }
                    if bodyType == .multipart {
                        TextField("File Field Name", text: $fileFormName)
                    }
                }

                Section {
                    keyValueEditor(
                        pairs: $headerPairs,
                        keyPlaceholder: "Header Name",
                        valuePlaceholder: "Header Value",
                        addLabel: "Add Header",
                        emptyText: "No headers added.",
                        isSecret: true)
                } header: {
                    Text("Headers")
                } footer: {
                    Text(
                        "Values are stored in the macOS Keychain, never in the config file itself."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if bodyType == .multipart {
                    Section {
                        keyValueEditor(
                            pairs: $fieldPairs,
                            keyPlaceholder: "Field Name",
                            valuePlaceholder: "Field Value",
                            addLabel: "Add Field",
                            emptyText: "No extra fields.",
                            isSecret: false)
                    } header: {
                        Text("Extra Form Fields")
                    } footer: {
                        Text(
                            "Static fields sent alongside the file, e.g. a webhook's \"username\"."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                Section {
                    TextField("Response Link Path", text: $responseLinkPath)
                } header: {
                    Text("Response")
                } footer: {
                    Text(
                        "Dot-path into the JSON response pointing at the resulting URL, e.g. \"url\" or \"files.0.url\"."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { onCancel() }
                Button(existingID == nil ? "Add" : "Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid)
            }
            .padding()
        }
        .frame(width: 420, height: 560)
    }

    private func keyValueEditor(
        pairs: Binding<[KeyValuePair]>,
        keyPlaceholder: String,
        valuePlaceholder: String,
        addLabel: String,
        emptyText: String,
        isSecret: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if pairs.wrappedValue.isEmpty {
                Text(emptyText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 6) {
                    ForEach(pairs) { $pair in
                        HStack(spacing: 8) {
                            TextField(keyPlaceholder, text: $pair.key)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 130)
                            if isSecret {
                                SecureField(valuePlaceholder, text: $pair.value)
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                TextField(valuePlaceholder, text: $pair.value)
                                    .textFieldStyle(.roundedBorder)
                            }
                            Button(role: .destructive) {
                                pairs.wrappedValue.removeAll { $0.id == pair.id }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 6).fill(.quaternary.opacity(0.5)))
                    }
                }
            }

            Button {
                pairs.wrappedValue.append(KeyValuePair())
            } label: {
                Label(addLabel, systemImage: "plus")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private func save() {
        let id = existingID ?? UUID()

        var headers: [String: String] = [:]
        var headerKeys: [String] = []
        for pair in headerPairs {
            let key = pair.key.trimmingCharacters(in: .whitespaces)
            guard !key.isEmpty else { continue }
            headers[key] = pair.value
            headerKeys.append(key)
        }
        if !KeychainHelper.setHeaders(headers, destinationID: id) {
            PermissionWarnings.showKeychainWriteFailed()
        }

        var formData: [String: String] = [:]
        for pair in fieldPairs {
            let key = pair.key.trimmingCharacters(in: .whitespaces)
            guard !key.isEmpty else { continue }
            formData[key] = pair.value
        }

        let destination = UploadDestination(
            id: id,
            name: name.trimmingCharacters(in: .whitespaces),
            requestURL: url.trimmingCharacters(in: .whitespaces),
            httpMethod: method,
            headerKeys: headerKeys,
            formData: formData,
            fileFormName: fileFormName.trimmingCharacters(in: .whitespaces).isEmpty
                ? "file" : fileFormName,
            bodyType: bodyType,
            responseLinkPath: responseLinkPath.trimmingCharacters(in: .whitespaces)
        )

        onSave(destination)
    }
}
