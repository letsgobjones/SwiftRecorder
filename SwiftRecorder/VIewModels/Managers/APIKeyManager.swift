//
//  APIKeyManager.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI
import Security


// MARK: - API Key Errors

enum APIKeyError: LocalizedError {
  case storageError(String)
  case notFound(String)
  case invalidData(String)
  case deletionError(String)
  
  var errorDescription: String? {
    switch self {
    case .storageError(let message):
      return "Storage Error: \(message)"
    case .notFound(let message):
      return "Not Found: \(message)"
    case .invalidData(let message):
      return "Invalid Data: \(message)"
    case .deletionError(let message):
      return "Deletion Error: \(message)"
    }
  }
}


/// Secure storage and retrieval of API keys using Keychain Services
class APIKeyManager {
  
  // MARK: - Keychain Constants
  private let service = "com.letsgobjones.SwiftRecorder"
  
  // MARK: - Singleton
  static let shared = APIKeyManager()
  private  init() {}
  
  
  // MARK: - Generic API Key Management
  /// Stores Google Speech-to-Text API key securely in Keychain
  
  func storeAPIKey(_ apiKey: String, for keyType: APIKeyType) throws {
    print("APIKeyManager: Storing key for \(keyType.displayName)")
    
    guard let data = apiKey.data(using: .utf8) else {
      throw APIKeyError.invalidData("Could not encode API key to data.")
    }
    
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: keyType.accountName,
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    ]
    
    // Delete any existing key first to ensure we can update it.
    SecItemDelete(query as CFDictionary)
    
    
    // Add new key
    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
      throw APIKeyError.storageError("Failed to store API key for \(keyType.displayName): OSStatus \(status)")
    }
    
    print("APIKeyManager: Key for \(keyType.displayName) stored successfully")
  }
  
  /// Retrieves an API key from the Keychain for a specific service.
  func getAPIKey(for keyType: APIKeyType) throws -> String {
    print("APIKeyManager: Retrieving key for \(keyType.displayName)")
    
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: keyType.accountName,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]
    
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    
    guard status == errSecSuccess else {
      throw APIKeyError.notFound("API key for \(keyType.displayName) not found.")
    }
    
    guard let data = result as? Data, let apiKey = String(data: data, encoding: .utf8) else {
      throw APIKeyError.invalidData("Failed to decode API key data for \(keyType.displayName).")
    }
    
    print("APIKeyManager: Key for \(keyType.displayName) retrieved successfully")
    return apiKey
  }
  
  /// Removes an API key from the Keychain for a specific service.
  func removeAPIKey(for keyType: APIKeyType) throws {
    print("APIKeyManager: Removing key for \(keyType.displayName)")
    
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: keyType.accountName
    ]
    
    let status = SecItemDelete(query as CFDictionary)
    
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw APIKeyError.deletionError("Failed to delete API key for \(keyType.displayName): OSStatus \(status)")
    }
    
    print("APIKeyManager: Key for \(keyType.displayName) removed successfully")
  }
  
  /// Checks if an API key exists in the Keychain for a specific service.
  func hasAPIKey(for keyType: APIKeyType) -> Bool {
    do {
      _ = try getAPIKey(for: keyType)
      return true
    } catch {
      return false
    }
  }
}







