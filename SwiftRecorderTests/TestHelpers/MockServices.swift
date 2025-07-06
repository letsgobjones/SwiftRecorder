//
//  MockServices.swift
//  SwiftRecorderTests
//
//  Created by Brandon Jones on 7/6/25.
//

import Foundation
import AVFoundation
import SwiftData
@testable import SwiftRecorder

// MARK: - Mock Audio Service
@Observable
class MockAudioService {
    var isRecording = false
    var hasMicrophoneAccess = true
    var errorMessage: String?
    
    var startRecordingCalled = false
    var stopRecordingCalled = false
    
    func startRecording() {
        startRecordingCalled = true
        isRecording = true
    }
    
    func stopRecording() {
        stopRecordingCalled = true
        isRecording = false
    }
    
    func simulateError(_ message: String) {
        errorMessage = message
    }
}

// MARK: - Mock Transcription Service
class MockTranscriptionService {
    var transcribeCallCount = 0
    var shouldFail = false
    var mockResult = "Mock transcription result"
    var mockProvider = TranscriptionProvider.appleOnDevice
    
    func transcribe(audioURL: URL, with provider: TranscriptionProvider) async throws -> (text: String, provider: TranscriptionProvider) {
        transcribeCallCount += 1
        
        if shouldFail {
            throw TranscriptionError.recognitionFailed("Mock transcription error")
        }
        
        // Simulate processing time
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        return (mockResult, mockProvider)
    }
    
    func resetFailureCount(for provider: TranscriptionProvider) {
        // Mock implementation
    }
}

// MARK: - Mock Storage Manager
@Observable
class MockStorageManager {
    var totalStorageUsed: Int64 = 0
    var totalFiles: Int = 0
    var isCleaningUp = false
    
    var calculateStorageUsageCalled = false
    var cleanupOrphanedFilesCalled = false
    
    func calculateStorageUsage() async {
        calculateStorageUsageCalled = true
        totalStorageUsed = 1024 * 1024 // 1MB mock
        totalFiles = 5
    }
    
    func cleanupOrphanedFiles(modelContext: ModelContext) async {
        cleanupOrphanedFilesCalled = true
        isCleaningUp = true
        
        // Simulate cleanup
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        isCleaningUp = false
    }
}

// MARK: - Mock Performance Manager
@Observable
class MockPerformanceManager {
    var memoryUsageMB: Double = 50.0
    var isMemoryWarning: Bool = false
    var maxConcurrentOperations: Int = 3
    
    func simulateMemoryPressure() {
        isMemoryWarning = true
        maxConcurrentOperations = 1
        memoryUsageMB = 250.0
    }
    
    func simulateNormalMemory() {
        isMemoryWarning = false
        maxConcurrentOperations = 3
        memoryUsageMB = 50.0
    }
}