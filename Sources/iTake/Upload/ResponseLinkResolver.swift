import Foundation

/// Resolves a plain dot-path (example "files.0.url") into a string value from a JSON object.
enum ResponseLinkResolver {
    static func resolve(path: String, against jsonObject: Any) -> String? {
        var current: Any? = jsonObject

        for component in path.components(separatedBy: ".") {
            if let index = Int(component) {
                guard let array = current as? [Any], array.indices.contains(index) else {
                    return nil
                }
                current = array[index]
            } else {
                guard let dict = current as? [String: Any] else { return nil }
                current = dict[component]
            }
        }

        switch current {
        case let string as String: return string
        case let number as NSNumber: return number.stringValue
        default: return nil
        }
    }
}
