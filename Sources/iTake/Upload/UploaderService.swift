import Foundation

enum UploaderError: Error {
    case invalidDestinationURL
    case invalidResponse(statusCode: Int)
}

struct UploadResult {
    let fileURL: URL?
}

enum UploaderService {
    static func upload(
        fileURL: URL,
        to destination: UploadDestination,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> UploadResult {
        guard let url = URL(string: destination.requestURL) else {
            throw UploaderError.invalidDestinationURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = destination.httpMethod

        let headers = KeychainHelper.headers(
            destinationID: destination.id, expectedKeys: destination.headerKeys)
        for key in destination.headerKeys {
            if let value = headers[key] {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        let fileData = try Data(contentsOf: fileURL)
        let mimeType = MimeType.forPathExtension(fileURL.pathExtension)
        let body: Data

        switch destination.bodyType {
        case .multipart:
            let boundary = "iTake-\(UUID().uuidString)"
            request.setValue(
                "multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            var multipart = Data()
            for (key, value) in destination.formData {
                multipart.append("--\(boundary)\r\n".utf8Data)
                multipart.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".utf8Data)
                multipart.append("\(value)\r\n".utf8Data)
            }
            multipart.append("--\(boundary)\r\n".utf8Data)
            multipart.append(
                "Content-Disposition: form-data; name=\"\(destination.fileFormName)\"; filename=\"\(fileURL.lastPathComponent)\"\r\n"
                    .utf8Data
            )
            multipart.append("Content-Type: \(mimeType)\r\n\r\n".utf8Data)
            multipart.append(fileData)
            multipart.append("\r\n--\(boundary)--\r\n".utf8Data)
            body = multipart
        case .binary:
            request.setValue(mimeType, forHTTPHeaderField: "Content-Type")
            body = fileData
        }

        let delegate = UploadProgressDelegate(onProgress: onProgress)
        let (data, response) = try await URLSession.shared.upload(
            for: request, from: body, delegate: delegate)

        guard let httpResponse = response as? HTTPURLResponse,
            (200..<300).contains(httpResponse.statusCode)
        else {
            throw UploaderError.invalidResponse(
                statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        let jsonObject: Any = (try? JSONSerialization.jsonObject(with: data)) ?? [String: Any]()
        let resolvedFileURL = ResponseLinkResolver.resolve(
            path: destination.responseLinkPath, against: jsonObject)

        return UploadResult(fileURL: resolvedFileURL.flatMap { URL(string: $0) })
    }
}

private final class UploadProgressDelegate: NSObject, URLSessionTaskDelegate {
    let onProgress: @Sendable (Double) -> Void

    init(onProgress: @escaping @Sendable (Double) -> Void) {
        self.onProgress = onProgress
    }

    func urlSession(
        _ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64, totalBytesExpectedToSend: Int64
    ) {
        guard totalBytesExpectedToSend > 0 else { return }
        onProgress(Double(totalBytesSent) / Double(totalBytesExpectedToSend))
    }
}

extension String {
    fileprivate var utf8Data: Data { Data(utf8) }
}

enum MimeType {
    static func forPathExtension(_ ext: String) -> String {
        switch ext.lowercased() {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "pdf": return "application/pdf"
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        case "txt": return "text/plain"
        default: return "application/octet-stream"
        }
    }
}
