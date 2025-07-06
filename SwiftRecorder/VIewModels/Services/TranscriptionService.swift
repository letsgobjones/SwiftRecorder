//
//  TranscriptionService.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/5/25.
//

import Foundation

/// The main transcription service that orchestrates different providers and handles fallbacks.
class TranscriptionService {
    
    // MARK: - Properties
    private let appleService = AppleSTTService()
    private let googleService = GoogleSTTService()
    private let openAIService = OpenAISTTService()
    
    // Use a dictionary to track failures for each cloud provider independently.
    private var consecutiveFailures: [TranscriptionProvider: Int] = [:]
    private let maxConsecutiveFailures = 5
    
    // MARK: - Public Interface
    
    /// The main transcription function that routes to the correct provider.
    /// It now returns a tuple containing the transcribed text and the provider that succeeded.
    func transcribe(audioURL: URL, with provider: TranscriptionProvider) async throws -> (text: String, provider: TranscriptionProvider) {
        
        // Safety check: Block mock data transcription if you have such a helper
        // guard !AudioFileHelpers.isMockFile(url: audioURL) else {
        //     throw TranscriptionError.serviceUnavailable("Cannot transcribe mock data")
        // }
        
        print("TranscriptionService: Attempting to transcribe with provider: \(provider.displayName)")
        
        switch provider {
        case .appleOnDevice:
            let text = try await appleService.transcribe(audioURL: audioURL)
            return (text, .appleOnDevice)
            
        case .googleSpeechToText:
            return try await transcribeWithFallback(
                provider: .googleSpeechToText,
                audioURL: audioURL,
                transcriptionTask: { try await self.googleService.transcribe(audioURL: audioURL) }
            )
            
        case .openAIWhisper:
            return try await transcribeWithFallback(
                provider: .openAIWhisper,
                audioURL: audioURL,
                transcriptionTask: { try await self.openAIService.transcribe(audioURL: audioURL) }
            )
        }
    }
    
    /// Resets the failure count for a specific provider, allowing it to be tried again immediately.
    func resetFailureCount(for provider: TranscriptionProvider) {
        consecutiveFailures[provider] = 0
        print("TranscriptionService: Failure count for \(provider.displayName) has been reset.")
    }
    
    // MARK: - Private Helper for Fallback Logic
    
    /// A generic helper to handle transcription attempts with fallback to Apple's on-device service.
    private func transcribeWithFallback(
        provider: TranscriptionProvider,
        audioURL: URL,
        transcriptionTask: () async throws -> String
    ) async throws -> (text: String, provider: TranscriptionProvider) {
        
        let currentFailures = consecutiveFailures[provider, default: 0]
        
        // Check if we should immediately fall back before even trying.
        if currentFailures >= maxConsecutiveFailures {
            print("TranscriptionService: Too many failures for \(provider.displayName) (\(currentFailures)). Falling back to Apple immediately.")
            let fallbackText = try await appleService.transcribe(audioURL: audioURL)
            return (fallbackText, .appleOnDevice)
        }
        
        do {
            // Attempt the transcription with the specified cloud provider.
            let result = try await transcriptionTask()
            
            // On success, reset the failure count for this provider and return the result.
            consecutiveFailures[provider] = 0
            return (result, provider)
            
        } catch {
            // On failure, increment the failure count for this provider.
            consecutiveFailures[provider, default: 0] += 1
            let newFailureCount = consecutiveFailures[provider, default: 0]
            print("TranscriptionService: \(provider.displayName) failed (attempt \(newFailureCount)/\(maxConsecutiveFailures)). Error: \(error.localizedDescription)")
            
            // If we've now hit the max failures, perform the fallback.
            if newFailureCount >= maxConsecutiveFailures {
                print("TranscriptionService: Falling back to Apple after reaching max failures.")
                let fallbackText = try await appleService.transcribe(audioURL: audioURL)
                return (fallbackText, .appleOnDevice)
            }
            
            // If we haven't hit the max failures yet, re-throw the original error
            // so the caller knows this specific attempt failed.
            throw error
        }
    }
}
