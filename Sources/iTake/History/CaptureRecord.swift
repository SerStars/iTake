import Foundation

struct CaptureRecord: Codable, Identifiable, Equatable {
    enum Kind: String, Codable {
        case screenshot
        case recording
    }

    let id: UUID
    let fileURL: URL
    let thumbnailFileName: String
    let kind: Kind
    let createdAt: Date
    var uploadedURL: URL?

    init(
        id: UUID = UUID(), fileURL: URL, thumbnailFileName: String, kind: Kind,
        createdAt: Date = Date(), uploadedURL: URL? = nil
    ) {
        self.id = id
        self.fileURL = fileURL
        self.thumbnailFileName = thumbnailFileName
        self.kind = kind
        self.createdAt = createdAt
        self.uploadedURL = uploadedURL
    }
}
