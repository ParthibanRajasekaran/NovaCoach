import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

protocol FileEncrypting {
    func encryptAndSave(_ data: Data, filename: String) throws -> URL
    func decryptData(at url: URL) throws -> Data
}

enum FileEncryptionError: Error {
    case encryptionFailed
    case decryptionFailed
    case invalidData
    case fileAccessError
}

final class FileEncryptionService: FileEncrypting {
    private let keyProvider: EncryptionKeyProviding
    private let fileManager = FileManager.default
    
    init(keyProvider: EncryptionKeyProviding) {
        self.keyProvider = keyProvider
    }
    
    func encryptAndSave(_ data: Data, filename: String) throws -> URL {
        #if canImport(CryptoKit)
        // Get encryption key from keychain
        let keyData = try keyProvider.loadOrCreateKey(identifier: "NovaCoach.FileEncryptionKey")
        let symmetricKey = SymmetricKey(data: keyData.prefix(32)) // Use first 32 bytes for AES-256
        
        // Encrypt the data
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
        guard let encryptedData = sealedBox.combined else {
            throw FileEncryptionError.encryptionFailed
        }
        
        // Save to documents directory
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(filename)
        
        try encryptedData.write(to: fileURL, options: .atomic)
        
        // Exclude from backup
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var mutableURL = fileURL
        try mutableURL.setResourceValues(resourceValues)
        
        return fileURL
        #else
        // Fallback for non-Apple platforms (Linux build)
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(filename)
        try data.write(to: fileURL, options: .atomic)
        return fileURL
        #endif
    }
    
    func decryptData(at url: URL) throws -> Data {
        #if canImport(CryptoKit)
        // Get encryption key from keychain
        let keyData = try keyProvider.loadOrCreateKey(identifier: "NovaCoach.FileEncryptionKey")
        let symmetricKey = SymmetricKey(data: keyData.prefix(32))
        
        // Read encrypted data
        let encryptedData = try Data(contentsOf: url)
        
        // Decrypt the data
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
        
        return decryptedData
        #else
        // Fallback for non-Apple platforms
        return try Data(contentsOf: url)
        #endif
    }
}
