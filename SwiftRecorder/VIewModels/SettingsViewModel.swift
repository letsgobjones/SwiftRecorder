//
//  SettingsViewModel.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI

@Observable
class SettingsViewModel {
  
  // MARK: - Published Properties
  
  var apiKeyInputs: [APIKeyType: String] = [
    .googleSpeechToText: "",
    .openAIWhisper: ""
  ]
  
  var isGoogleAPIKeyStored: Bool = false
  var isOpenAIAPIKeyStored: Bool = false
  
  var errorMessage: String?
  var successMessage: String?
  
  
  // MARK: - Private Properties
  private let apiKeyManager = APIKeyManager.shared
  
  init() {
    checkAllAPIKeyStatuses()
  }
  
  
  
  // MARK: - Public Actions
  /// Saves the API key for the given service type to the Keychain.
  func saveAPIKey(for keyType: APIKeyType) {
    guard let keyToSave = apiKeyInputs[keyType] else { return }
    let trimmedKey = keyToSave.trimmingCharacters(in: .whitespacesAndNewlines)
    
    guard !trimmedKey.isEmpty else {
      showError("Please enter a valid \(keyType.displayName) API key.")
      return
    }
    
    do {
      try apiKeyManager.storeAPIKey(trimmedKey, for: keyType)
      updateKeyStatus(for: keyType, isStored: true)
      clearAPIKeyField(for: keyType)
      showSuccess("\(keyType.displayName) API key saved successfully.")
    } catch {
      showError("Failed to save \(keyType.displayName) API key: \(error.localizedDescription)")
    }
  }
  
  /// Removes the API key for the given service type from the Keychain.
  func removeAPIKey(for keyType: APIKeyType) {
    do {
      try apiKeyManager.removeAPIKey(for: keyType)
      updateKeyStatus(for: keyType, isStored: false)
      clearAPIKeyField(for: keyType)
      showSuccess("\(keyType.displayName) API key removed successfully.")
    } catch {
      showError("Failed to remove \(keyType.displayName) API key: \(error.localizedDescription)")
    }
  }
  
  // MARK: - Private Helpers
  
  private func checkAllAPIKeyStatuses() {
    isGoogleAPIKeyStored = apiKeyManager.hasAPIKey(for: .googleSpeechToText)
    isOpenAIAPIKeyStored = apiKeyManager.hasAPIKey(for: .openAIWhisper)
  }
  
  private func updateKeyStatus(for keyType: APIKeyType, isStored: Bool) {
    switch keyType {
    case .googleSpeechToText:
      isGoogleAPIKeyStored = isStored
    case .openAIWhisper:
      isOpenAIAPIKeyStored = isStored
    }
  }
  
  private func clearAPIKeyField(for keyType: APIKeyType) {
    apiKeyInputs[keyType] = ""
  }
  
  private func showError(_ message: String) {
    errorMessage = message
    successMessage = nil
    
    Task {
      try? await Task.sleep(for: .seconds(3))
      self.errorMessage = nil
    }
  }
  
  private func showSuccess(_ message: String) {
    successMessage = message
    errorMessage = nil
    
    Task {
      try? await Task.sleep(for: .seconds(3))
      self.successMessage = nil
    }
  }
}









