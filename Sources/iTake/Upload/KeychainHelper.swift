import Foundation
import Security

/// Header values (API keys, tokens, etc) live only in the Keychain, keyed by destination id + header
/// name, never in the UserDefaults-backed UploadDestination that gets persisted to disk.
enum KeychainHelper {
    private static let service = "com.SerStars.iTake.uploader-header"

    private static func account(destinationID: UUID, headerKey: String) -> String {
        "\(destinationID.uuidString).\(headerKey)"
    }

    static func setValue(_ value: String, forHeaderKey headerKey: String, destinationID: UUID) {
        let account = account(destinationID: destinationID, headerKey: headerKey)
        let data = Data(value.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func value(forHeaderKey headerKey: String, destinationID: UUID) -> String? {
        let account = account(destinationID: destinationID, headerKey: headerKey)
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

    static func deleteValue(forHeaderKey headerKey: String, destinationID: UUID) {
        let account = account(destinationID: destinationID, headerKey: headerKey)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
