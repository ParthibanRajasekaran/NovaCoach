import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

enum FileEncryptionError: Error {
    case encryptionFailed
    case decryptionFailed
    case noCryptoKitSupport
}

protocol FileEncrypting {
    func encryptAndSave(_ text: String, identifier: String) throws -> String
    func loadAndDecrypt(path: String) throws -> String
}

final class FileEncryptionService: FileEncrypting {
    private let encryptionKeyProvider: EncryptionKeyProviding
    
    init(encryptionKeyProvider: EncryptionKeyProviding) {
        self.encryptionKeyProvider = encryptionKeyProvider
    }
    
    func encryptAndSave(_ text: String, identifier: String) throws -> String {
        #if canImport(CryptoKit)
        guard let textData = text.data(using: .utf8) else {
            throw FileEncryptionError.encryptionFailed
        }
        
        let key = try encryptionKeyProvider.loadOrCreateKey(identifier: "NovaCoach.FileEncryption")
        let symmetricKey = SymmetricKey(data: key.prefix(32))
        
        let sealedBox = try AES.GCM.seal(textData, using: symmetricKey)
        guard let combined = sealedBox.combined else {
            throw FileEncryptionError.encryptionFailed
        }
        
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent(identifier + ".encrypted")
        try combined.write(to: url, options: .completeFileProtection)
        
        return url.path
        #else
        throw FileEncryptionError.noCryptoKitSupport
        #endif
    }
    
    func loadAndDecrypt(path: String) throws -> String {
        #if canImport(CryptoKit)
        let url = URL(fileURLWithPath: path)
        let encryptedData = try Data(contentsOf: url)
        
        let key = try encryptionKeyProvider.loadOrCreateKey(identifier: "NovaCoach.FileEncryption")
        let symmetricKey = SymmetricKey(data: key.prefix(32))
        
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
        
        guard let text = String(data: decryptedData, encoding: .utf8) else {
            throw FileEncryptionError.decryptionFailed
        }
        
        return text
        #else
        throw FileEncryptionError.noCryptoKitSupport
        #endif
    }
}
