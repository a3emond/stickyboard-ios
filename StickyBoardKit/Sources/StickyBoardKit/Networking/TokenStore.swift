import Foundation
import Security

/// Abstract token storage
public protocol TokenStore: Sendable {
    func load() -> (access: String?, refresh: String?)
    func save(access: String?, refresh: String?)
    func clear()
}

/// Keychain-backed tokens
public final class KeychainTokenStore: TokenStore {
    private let service = "pro.aedev.stickyboard"
    private let accountAccess = "accessToken"
    private let accountRefresh = "refreshToken"

    public init() {}

    public func load() -> (access: String?, refresh: String?) {
        (read(account: accountAccess), read(account: accountRefresh))
    }

    public func save(access: String?, refresh: String?) {
        write(account: accountAccess, value: access)
        write(account: accountRefresh, value: refresh)
    }

    public func clear() { save(access: nil, refresh: nil) }

    private func read(account: String) -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func write(account: String, value: String?) {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(base as CFDictionary)
        guard let value else { return }

        var attrs = base
        attrs[kSecValueData as String] = value.data(using: .utf8)
        attrs[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock // accessible after first unlock
        attrs[kSecAttrSynchronizable as String] = false // no cloud sync

        _ = SecItemAdd(attrs as CFDictionary, nil)
    }
}
