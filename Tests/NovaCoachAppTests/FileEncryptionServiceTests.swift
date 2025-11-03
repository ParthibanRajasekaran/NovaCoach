import XCTest
@testable import NovaCoachApp

@MainActor
final class FileEncryptionServiceTests: XCTestCase {
    
    func testEncryptAndSaveCreatesFile() async throws {
        let mockKeyProvider = MockEncryptionKeyProvider()
        let fileEncryptionService = FileEncryptionService(keyProvider: mockKeyProvider)
        let testData = "Test transcript data".data(using: .utf8)!
        let filename = "test_transcript.enc"
        
        // Ensure documents directory exists
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
        
        let fileURL = try fileEncryptionService.encryptAndSave(testData, filename: filename)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertTrue(fileURL.lastPathComponent == filename)
        
        // Cleanup
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    func testEncryptAndSaveExcludesFromBackup() async throws {
        #if canImport(CryptoKit)
        let mockKeyProvider = MockEncryptionKeyProvider()
        let fileEncryptionService = FileEncryptionService(keyProvider: mockKeyProvider)
        let testData = "Test transcript data".data(using: .utf8)!
        let filename = "test_transcript_backup.enc"
        
        // Ensure documents directory exists
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
        
        let fileURL = try fileEncryptionService.encryptAndSave(testData, filename: filename)
        
        let resourceValues = try fileURL.resourceValues(forKeys: [.isExcludedFromBackupKey])
        XCTAssertEqual(resourceValues.isExcludedFromBackup, true)
        
        // Cleanup
        try? FileManager.default.removeItem(at: fileURL)
        #endif
    }
    
    func testEncryptAndDecryptRoundTrip() async throws {
        #if canImport(CryptoKit)
        let mockKeyProvider = MockEncryptionKeyProvider()
        let fileEncryptionService = FileEncryptionService(keyProvider: mockKeyProvider)
        let originalText = "This is a sensitive transcript that should be encrypted"
        let testData = originalText.data(using: .utf8)!
        let filename = "test_transcript_roundtrip.enc"
        
        // Ensure documents directory exists
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
        
        // Encrypt and save
        let fileURL = try fileEncryptionService.encryptAndSave(testData, filename: filename)
        
        // Decrypt
        let decryptedData = try fileEncryptionService.decryptData(at: fileURL)
        let decryptedText = String(data: decryptedData, encoding: .utf8)
        
        XCTAssertEqual(decryptedText, originalText)
        
        // Cleanup
        try? FileManager.default.removeItem(at: fileURL)
        #endif
    }
    
    func testEncryptedDataIsDifferentFromOriginal() async throws {
        #if canImport(CryptoKit)
        let mockKeyProvider = MockEncryptionKeyProvider()
        let fileEncryptionService = FileEncryptionService(keyProvider: mockKeyProvider)
        let originalText = "Secret transcript"
        let testData = originalText.data(using: .utf8)!
        let filename = "test_transcript_encrypted.enc"
        
        // Ensure documents directory exists
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
        
        // Encrypt and save
        let fileURL = try fileEncryptionService.encryptAndSave(testData, filename: filename)
        
        // Read the encrypted data directly
        let encryptedData = try Data(contentsOf: fileURL)
        
        // The encrypted data should not equal the original data
        XCTAssertNotEqual(encryptedData, testData)
        
        // The encrypted data should not contain the original text in plain form
        let encryptedString = String(data: encryptedData, encoding: .utf8) ?? ""
        XCTAssertFalse(encryptedString.contains(originalText))
        
        // Cleanup
        try? FileManager.default.removeItem(at: fileURL)
        #endif
    }
}

// Mock implementation for testing
final class MockEncryptionKeyProvider: EncryptionKeyProviding {
    private var keys: [String: Data] = [:]
    
    func loadOrCreateKey(identifier: String) throws -> Data {
        if let existing = keys[identifier] {
            return existing
        }
        // Generate a random 64-byte key
        let randomBytes = (0..<64).map { _ in UInt8.random(in: .min ... .max) }
        let key = Data(randomBytes)
        keys[identifier] = key
        return key
    }
}
