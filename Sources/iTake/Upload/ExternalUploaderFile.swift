import Foundation

/// iTake's own custom-uploader file format (.itup); plain JSON.
/// Fields are grouped into request/body/response sections;
/// `headers`/`fields` hold raw values (for example an API key) since they're only
/// ever touched at import/export time. UploadDestination itself never keeps header values,
/// only their names (see KeychainHelper).
struct ExternalUploaderFile: Codable {
    struct RequestSection: Codable {
        var url: String
        var method: String
        var headers: [String: String]?
    }

    struct BodySection: Codable {
        var type: String
        var fileField: String?
        var fields: [String: String]?
    }

    struct ResponseSection: Codable {
        /// Dot-path into the JSON response, example: "url" or "files.0.url".
        var linkPath: String
    }

    var name: String
    var request: RequestSection
    var body: BodySection
    var response: ResponseSection
}
