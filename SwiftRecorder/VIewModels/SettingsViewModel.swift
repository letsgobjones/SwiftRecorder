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
  
  // MARK: - Transcription Provider Selection
  var selectedProvider: TranscriptionProvider = .appleOnDevice {
    didSet {
      // Save to UserDefaults whenever the selection changes
      UserDefaults.standard.set(selectedProvider.rawValue, forKey: "selectedTranscriptionProvider")
      print("SettingsViewModel: Selected provider changed to: \(selectedProvider.displayName)")
    }
  }
  
  // MARK: - Private Properties
  private let apiKeyManager = APIKeyManager.shared
  
  init() {
    loadSelectedProvider()
    checkAllAPIKeyStatuses()
    print("SettingsViewModel: Initialized with provider: \(selectedProvider.displayName)")
  }
  
  // MARK: - Private Setup Methods
  
  private func loadSelectedProvider() {
    if let savedProvider = UserDefaults.standard.string(forKey: "selectedTranscriptionProvider"),
       let provider = TranscriptionProvider(rawValue: savedProvider) {
      selectedProvider = provider
    } else {
      selectedProvider = .appleOnDevice // Default to Apple On-Device
    }
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
  
  // MARK: - Provider Selection Validation
  /// Checks if the selected provider is properly configured (has required API keys)
  func isSelectedProviderConfigured() -> Bool {
    switch selectedProvider {
    case .appleOnDevice:
      return true // Always available
    case .googleSpeechToText:
      return isGoogleAPIKeyStored
    case .openAIWhisper:
      return isOpenAIAPIKeyStored
    }
  }
  
  /// Returns a warning message if the selected provider is not properly configured
  func getProviderWarningMessage() -> String? {
    if !isSelectedProviderConfigured() {
      return "⚠️ \(selectedProvider.displayName) requires an API key to function."
    }
    return nil
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