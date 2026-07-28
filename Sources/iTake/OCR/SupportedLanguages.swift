import Foundation

enum SupportedLanguages {
    static let all: [(code: String, name: String)] = {
        guard let url = Bundle.module.url(forResource: "languages", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [] }
        return dict.map { (code: $0.key, name: $0.value) }
            .sorted { $0.name < $1.name }
    }()
}
