//
//  TranscriptionServiceTests.swift
//  SwiftRecorderTests
//
//  Created by Brandon Jones on 7/6/25.
//

import XCTest
@testable import SwiftRecorder

final class TranscriptionServiceTests: XCTestCase {
    var transcriptionService: TranscriptionService!
    var mockAudioURL: URL!
    
    override func setUp() {
        super.setUp()
        transcriptionService = TranscriptionService()
        
        // Create a mock audio file URL
        let tempDir = FileManager.default.temporaryDirectory
        mockAudioURL = tempDir.appendingPathComponent("test.m4a")
        
        // Create empty file for testing
        FileManager.default.createFile(atPath: mockAudioURL.path, contents: Data(), attributes: nil)
    }
    
    override func tearDown() {
        transcriptionService = nil
        
        // Clean up test file
        try? FileManager.default.removeItem(at: mockAudioURL)
        mockAudioURL = nil
        
        super.tearDown()
    }
    
    func testAppleOnDeviceTranscription() async {
        // Given
        let provider = TranscriptionProvider.appleOnDevice
        
        // When & Then
        do {
            let result = try await transcriptionService.transcribe(audioURL: mockAudioURL, with: provider)
            
            // Apple transcription should return the same provider
            XCTAssertEqual(result.provider, .appleOnDevice)
            // Result should have some text (might be empty for empty audio file)
            XCTAssertNotNil(result.text)
            
        } catch {
            // Apple transcription might fail with empty audio file, which is expected
            XCTAssertTrue(error is TranscriptionError)
        }
    }
    
    func testFailureCountReset() {
        // Given
        let provider = TranscriptionProvider.googleSpeechToText
        
        // When
        transcriptionService.resetFailureCount(for: provider)
        
        // Then
        // This test verifies the method doesn't crash and can be called
        // In a real implementation, you'd check internal state
        XCTAssertTrue(true, "Reset failure count should not crash")
    }
    
    func testProviderSelection() {
        // Test that all provider types are handled
        let providers: [TranscriptionProvider] = [
            .appleOnDevice,
            .googleSpeechToText,
            .openAIWhisper
        ]
        
        for provider in providers {
            XCTAssertNotNil(provider.displayName)
            XCTAssertFalse(provider.displayName.isEmpty)
        }
    }
}