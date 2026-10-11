import Foundation
import Security

/// Shared Keychain helpers for host app ↔ keyboard (no Full Access / App Groups).
enum SharedKeychain {
    static let accessGroup = "QCZ38FF75B.com.esqer.uyghurlatin.shared"
    static let prefsService = "com.esqer.uyghurlatin.prefs"

    static func readString(service: String, account: String) -> String? {
        guard let data = readData(service: service, account: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func writeString(service: String, account: String, value: String) -> Bool {
        writeData(service: service, account: account, data: Data(value.utf8))
    }

    static func readData(service: String, account: String) -> Data? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccessGroup as String: accessGroup,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess, let data = item as? Data {
            return data
        }
        // Legacy items written without access group (pre-shared).
        query.removeValue(forKey: kSecAttrAccessGroup as String)
        item = nil
        let legacy = SecItemCopyMatching(query as CFDictionary, &item)
        if legacy == errSecSuccess, let data = item as? Data {
            _ = writeData(service: service, account: account, data: data)
            return data
        }
        return nil
    }

    @discardableResult
    static func writeData(service: String, account: String, data: Data) -> Bool {
        var base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: accessGroup,
        ]
        SecItemDelete(base as CFDictionary)
        // Also clear legacy non-group item to avoid split brains.
        var legacy = base
        legacy.removeValue(forKey: kSecAttrAccessGroup as String)
        SecItemDelete(legacy as CFDictionary)

        var add = base
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
    }
}
