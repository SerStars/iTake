import Foundation

enum GoogleTranslateError: Error {
    case invalidResponse
}

enum GoogleTranslateService {
    struct Result {
        let text: String
        let detectedSourceLanguageCode: String?
    }

    private struct Response: Decodable {
        struct Sentence: Decodable {
            let trans: String?
        }
        let sentences: [Sentence]?
        let src: String?
    }

    static func translate(
        _ text: String, from sourceLanguageCode: String = "auto",
        to targetLanguageCode: String = Self.deviceLanguageCode
    ) async throws -> Result {
        var components = URLComponents(
            string: "https://translate.googleapis.com/translate_a/single")!
        components.queryItems = [
            URLQueryItem(name: "client", value: "gtx"),
            URLQueryItem(name: "sl", value: sourceLanguageCode),
            URLQueryItem(name: "tl", value: targetLanguageCode),
            URLQueryItem(name: "dt", value: "t"),
            URLQueryItem(name: "dj", value: "1"),
            URLQueryItem(name: "source", value: "input"),
            URLQueryItem(name: "q", value: text),
        ]
        guard let url = components.url else { throw GoogleTranslateError.invalidResponse }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GoogleTranslateError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        let translated = (decoded.sentences ?? []).compactMap(\.trans).joined()
        guard !translated.isEmpty else { throw GoogleTranslateError.invalidResponse }
        return Result(text: translated, detectedSourceLanguageCode: decoded.src)
    }

    private static var deviceLanguageCode: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }
}
