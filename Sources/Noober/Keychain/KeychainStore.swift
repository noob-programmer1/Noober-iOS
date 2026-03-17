import Foundation
import Security

@MainActor
final class KeychainStore: ObservableObject {

    static let shared = KeychainStore()

    @Published private(set) var entries: [KeychainEntry] = []

    private init() {}

    // MARK: - Read

    func refresh() {
        var results: [KeychainEntry] = []
        results.append(contentsOf: queryItems(itemClass: .genericPassword))
        results.append(contentsOf: queryItems(itemClass: .internetPassword))
        entries = results.sorted { ($0.service, $0.account) < ($1.service, $1.account) }
    }

    private func queryItems(itemClass: KeychainEntry.ItemClass) -> [KeychainEntry] {
        let secClass: CFString = itemClass == .genericPassword
            ? kSecClassGenericPassword
            : kSecClassInternetPassword

        let query: [String: Any] = [
            kSecClass as String: secClass,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let items = result as? [[String: Any]] else { return [] }

        return items.compactMap { attrs in
            let service: String
            if itemClass == .genericPassword {
                service = attrs[kSecAttrService as String] as? String ?? "(no service)"
            } else {
                service = attrs[kSecAttrServer as String] as? String ?? "(no server)"
            }
            let account = attrs[kSecAttrAccount as String] as? String ?? "(no account)"
            let accessGroup = attrs[kSecAttrAccessGroup as String] as? String
            let created = attrs[kSecAttrCreationDate as String] as? Date
            let modified = attrs[kSecAttrModificationDate as String] as? Date
            let label = attrs[kSecAttrLabel as String] as? String

            return KeychainEntry(
                id: "\(itemClass.rawValue):\(service):\(account)",
                itemClass: itemClass,
                service: service,
                account: account,
                accessGroup: accessGroup,
                createdAt: created,
                modifiedAt: modified,
                label: label
            )
        }
    }

    // MARK: - Lazy value retrieval

    nonisolated func retrieveValue(for entry: KeychainEntry) -> String? {
        let secClass: CFString = entry.itemClass == .genericPassword
            ? kSecClassGenericPassword
            : kSecClassInternetPassword

        var query: [String: Any] = [
            kSecClass as String: secClass,
            kSecAttrAccount as String: entry.account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        if entry.itemClass == .genericPassword {
            query[kSecAttrService as String] = entry.service
        } else {
            query[kSecAttrServer as String] = entry.service
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8) ?? "(binary, \(data.count) bytes)"
    }

    // MARK: - Add / Update

    func saveItem(
        account: String,
        value: String,
        service: String,
        itemClass: KeychainEntry.ItemClass,
        originalEntry: KeychainEntry? = nil
    ) {
        // Delete old entry if updating
        if let original = originalEntry {
            deleteEntry(original)
        }

        let secClass: CFString = itemClass == .genericPassword
            ? kSecClassGenericPassword
            : kSecClassInternetPassword

        guard let valueData = value.data(using: .utf8) else { return }

        var attrs: [String: Any] = [
            kSecClass as String: secClass,
            kSecAttrAccount as String: account,
            kSecValueData as String: valueData,
        ]

        if itemClass == .genericPassword {
            attrs[kSecAttrService as String] = service
        } else {
            attrs[kSecAttrServer as String] = service
        }

        SecItemAdd(attrs as CFDictionary, nil)
        refresh()
    }

    // MARK: - Delete

    func deleteEntry(_ entry: KeychainEntry) {
        let secClass: CFString = entry.itemClass == .genericPassword
            ? kSecClassGenericPassword
            : kSecClassInternetPassword

        var query: [String: Any] = [
            kSecClass as String: secClass,
            kSecAttrAccount as String: entry.account,
        ]

        if entry.itemClass == .genericPassword {
            query[kSecAttrService as String] = entry.service
        } else {
            query[kSecAttrServer as String] = entry.service
        }

        SecItemDelete(query as CFDictionary)
        refresh()
    }

    func clearAll() {
        SecItemDelete([kSecClass as String: kSecClassGenericPassword] as CFDictionary)
        SecItemDelete([kSecClass as String: kSecClassInternetPassword] as CFDictionary)
        refresh()
    }
}
