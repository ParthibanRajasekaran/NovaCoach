import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

enum FileEncryptionError: Error {
    case encryptionFailed
    case decryptionFailed
    case unsupportedPlatform
}

@MainActor
protocol FileEncrypting {
    func encryptAndSave(_ data: Data, to url: URL) throws
    func decryptData(from url: URL) throws -> Data
}

final class FileEncryptionService: FileEncrypting {
    private let keyProvider: EncryptionKeyProviding
    
    init(keyProvider: EncryptionKeyProviding) {
        self.keyProvider = keyProvider
    }
    
    func encryptAndSave(_ data: Data, to url: URL) throws {
        #if canImport(CryptoKit)
        let keyData = try keyProvider.loadOrCreateKey(identifier: "NovaCoach.FileEncryptionKey")
        let symmetricKey = SymmetricKey(data: keyData)
        
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
        guard let combined = sealedBox.combined else {
            throw FileEncryptionError.encryptionFailed
        }
        
        try combined.write(to: url, options: .atomic)
        #else
        // Fallback for platforms without CryptoKit: save unencrypted
        // In production, consider using a different encryption library
        try data.write(to: url, options: .atomic)
        #endif
    }
    
    func decryptData(from url: URL) throws -> Data {
        #if canImport(CryptoKit)
        let encryptedData = try Data(contentsOf: url)
        let keyData = try keyProvider.loadOrCreateKey(identifier: "NovaCoach.FileEncryptionKey")
        let symmetricKey = SymmetricKey(data: keyData)
        
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
        return decryptedData
        #else
        // Fallback for platforms without CryptoKit: read unencrypted
        return try Data(contentsOf: url)
        #endif
    }
}
