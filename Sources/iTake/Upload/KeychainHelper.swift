import Foundation
import Security

/// Header values (API keys, tokens, etc) live only in the Keychain, never in the UserDefaults-
/// backed UploadDestination that gets persisted to disk. All of a destination's headers are
/// stored together as one JSON-encoded Keychain item (keyed by destination id).

enum KeychainHelper {
    private static let service = "com.SerStars.iTake.uploader-header"

    static func headers(destinationID: UUID, expectedKeys: [String]) -> [String: String] {
        var result = storedHeaders(destinationID: destinationID)
        var recoveredAny = false

        for key in expectedKeys where result[key] == nil {
            if let legacyValue = legacyValue(forHeaderKey: key, destinationID: destinationID) {
                result[key] = legacyValue
                recoveredAny = true
            }
        }

        if recoveredAny {
            setHeaders(result, destinationID: destinationID)
        }

        return result
    }

    @discardableResult
    static func setHeaders(_ headers: [String: String], destinationID: UUID) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: destinationID.uuidString,
        ]
        SecItemDelete(query as CFDictionary)

        guard !headers.isEmpty, let data = try? JSONEncoder().encode(headers) else { return true }

        var attributes = query
        attributes[kSecValueData as String] = data
        let status = SecItemAdd(attributes as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func deleteHeaders(destinationID: UUID) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: destinationID.uuidString,
        ]
        SecItemDelete(query as CFDictionary)
    }

    private static func storedHeaders(destinationID: UUID) -> [String: String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: destinationID.uuidString,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data,
            let decoded = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return decoded
    }

    private static func legacyValue(forHeaderKey headerKey: String, destinationID: UUID) -> String?
    {
        let account = "\(destinationID.uuidString).\(headerKey)"
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
