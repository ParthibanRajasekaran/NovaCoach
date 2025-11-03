import Foundation

@MainActor
protocol EncryptionKeyProviding: AnyObject {
    func loadOrCreateKey(identifier: String) throws -> Data
}
