import Foundation
#if canImport(Security)
import Security
#else
typealias OSStatus = Int32
let errSecSuccess: Int32 = 0
#endif

enum KeychainError: Error {
    case creationFailed(OSStatus)
    case retrievalFailed(OSStatus)
    case dataEncoding
}

@MainActor
final class KeychainService: EncryptionKeyProviding {
    static let shared = KeychainService()
    private let service = "com.novacoach.keychain"
    private let accessGroup: String?

    init(accessGroup: String? = nil) {
        self.accessGroup = accessGroup
    }

    func loadOrCreateKey(identifier: String) throws -> Data {
        if let existing = try? readKey(identifier: identifier) {
            return existing
        }
        let key = randomKey()
        try storeKey(key, identifier: identifier)
        return key
    }

    private func randomKey() -> Data {
        #if canImport(Security)
        var buffer = Data(count: 64)
        let status = buffer.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 64, bytes.baseAddress!)
        }
        if status == errSecSuccess {
            return buffer
        }
        #endif
        let randomBytes = (0..<64).map { _ in UInt8.random(in: .min ... .max) }
        return Data(randomBytes)
    }

    private func readKey(identifier: String) throws -> Data {
        #if canImport(Security)
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: identifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status != errSecItemNotFound else { throw KeychainError.retrievalFailed(status) }
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.retrievalFailed(status)
        }
        return data
        #else
        let url = fallbackURL(for: identifier)
        guard let data = try? Data(contentsOf: url) else {
            throw KeychainError.retrievalFailed(-1)
        }
        return data
        #endif
    }

    private func storeKey(_ data: Data, identifier: String) throws {
        #if canImport(Security)
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: identifier,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.creationFailed(status)
        }
        #else
        let url = fallbackURL(for: identifier)
        try data.write(to: url, options: .atomic)
        #endif
    }

#if !canImport(Security)
    private func fallbackURL(for identifier: String) -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true, attributes: nil)
        return base.appendingPathComponent(identifier + ".key")
    }
#endif
}

