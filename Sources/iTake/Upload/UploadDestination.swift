import Foundation

/// Header *values* never live here, only the header *names*.
/// The actual secret values are stored in the Keychain (see KeychainHelper).
/// Kept flat internally for simplicity even though the external .itup file
/// format groups fields into sections. See fromExternalFile()/exportData() for the mapping.
struct UploadDestination: Codable, Identifiable, Hashable {
    enum BodyType: String, Codable {
        case multipart
        case binary
    }

    var id: UUID
    var name: String
    var requestURL: String
    var httpMethod: String
    var headerKeys: [String]
    var formData: [String: String]
    var fileFormName: String
    var bodyType: BodyType
    /// Dot-path into the JSON upload response.
    var responseLinkPath: String

    init(
        id: UUID = UUID(),
        name: String,
        requestURL: String,
        httpMethod: String = "POST",
        headerKeys: [String] = [],
        formData: [String: String] = [:],
        fileFormName: String = "file",
        bodyType: BodyType = .multipart,
        responseLinkPath: String
    ) {
        self.id = id
        self.name = name
        self.requestURL = requestURL
        self.httpMethod = httpMethod
        self.headerKeys = headerKeys
        self.formData = formData
        self.fileFormName = fileFormName
        self.bodyType = bodyType
        self.responseLinkPath = responseLinkPath
    }
}

extension UploadDestination {
    /// Converts an imported .itup file into our internal model, moving header values (API keys
    /// etc) straight into the Keychain rather than keeping them in the struct.
    static func fromExternalFile(_ file: ExternalUploaderFile) -> UploadDestination {
        let id = UUID()
        let headers = file.request.headers ?? [:]
        KeychainHelper.setHeaders(headers, destinationID: id)

        return UploadDestination(
            id: id,
            name: file.name,
            requestURL: file.request.url,
            httpMethod: file.request.method.isEmpty ? "POST" : file.request.method,
            headerKeys: Array(headers.keys),
            formData: file.body.fields ?? [:],
            fileFormName: file.body.fileField ?? "file",
            bodyType: BodyType(rawValue: file.body.type) ?? .multipart,
            responseLinkPath: file.response.linkPath
        )
    }

    /// Reconstructs the same portable JSON shape (pulling header values back out of the
    /// Keychain) so a destination can be exported/shared as a .itup file.
    func exportData() -> Data? {
        let headers = KeychainHelper.headers(destinationID: id, expectedKeys: headerKeys)

        let file = ExternalUploaderFile(
            name: name,
            request: .init(
                url: requestURL, method: httpMethod, headers: headers.isEmpty ? nil : headers),
            body: .init(
                type: bodyType.rawValue, fileField: fileFormName,
                fields: formData.isEmpty ? nil : formData),
            response: .init(linkPath: responseLinkPath)
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(file)
    }
}
