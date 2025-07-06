//
//  SettingsViewModelTests.swift
//  SwiftRecorderTests
//
//  Created by Brandon Jones on 7/6/25.
//

import XCTest
@testable import SwiftRecorder

@MainActor
final class SettingsViewModelTests: XCTestCase {
    var settingsViewModel: SettingsViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        settingsViewModel = SettingsViewModel()
    }
    
    override func tearDown() async throws {
        settingsViewModel = nil
        try await super.tearDown()
    }
    
    func testInitialState() {
        // Then
        XCTAssertFalse(settingsViewModel.isGoogleAPIKeyStored)
        XCTAssertFalse(settingsViewModel.isOpenAIAPIKeyStored)
        XCTAssertFalse(settingsViewModel.isValidatingGoogleAPI)
        XCTAssertFalse(settingsViewModel.isValidatingOpenAIAPI)
        XCTAssertNil(settingsViewModel.errorMessage)
        XCTAssertNil(settingsViewModel.successMessage)
        XCTAssertEqual(settingsViewModel.selectedProvider, .appleOnDevice)
    }
    
    func testAPIKeyInputs() {
        // When
        settingsViewModel.apiKeyInputs[.openAIWhisper] = "test-api-key"
        settingsViewModel.apiKeyInputs[.googleSpeechToText] = "google-api-key"
        
        // Then
        XCTAssertEqual(settingsViewModel.apiKeyInputs[.openAIWhisper], "test-api-key")
        XCTAssertEqual(settingsViewModel.apiKeyInputs[.googleSpeechToText], "google-api-key")
    }
    
    func testProviderSelection() {
        // When
        settingsViewModel.selectedProvider = .openAIWhisper
        
        // Then
        XCTAssertEqual(settingsViewModel.selectedProvider, .openAIWhisper)
        
        // Check UserDefaults persistence
        let savedProvider = UserDefaults.standard.string(forKey: "selectedTranscriptionProvider")
        XCTAssertEqual(savedProvider, TranscriptionProvider.openAIWhisper.rawValue)
    }
    
    func testProviderConfigurationValidation() {
        // Given - Apple provider should always be configured
        settingsViewModel.selectedProvider = .appleOnDevice
        
        // Then
        XCTAssertTrue(settingsViewModel.isSelectedProviderConfigured())
        XCTAssertNil(settingsViewModel.getProviderWarningMessage())
        
        // Given - Google provider without API key
        settingsViewModel.selectedProvider = .googleSpeechToText
        settingsViewModel.isGoogleAPIKeyStored = false
        
        // Then
        XCTAssertFalse(settingsViewModel.isSelectedProviderConfigured())
        XCTAssertNotNil(settingsViewModel.getProviderWarningMessage())
        
        // Given - Google provider with API key
        settingsViewModel.isGoogleAPIKeyStored = true
        
        // Then
        XCTAssertTrue(settingsViewModel.isSelectedProviderConfigured())
        XCTAssertNil(settingsViewModel.getProviderWarningMessage())
    }
    
    func testSaveAPIKeyValidation() {
        // Given - empty API key
        settingsViewModel.apiKeyInputs[.openAIWhisper] = "   "
        
        // When
        settingsViewModel.saveAPIKey(for: .openAIWhisper)
        
        // Then
        XCTAssertNotNil(settingsViewModel.errorMessage)
        XCTAssertTrue(settingsViewModel.errorMessage?.contains("valid") == true)
    }
}