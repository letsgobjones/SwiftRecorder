//
//  TranscriptionService.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/5/25.
//

import SwiftUI
import Speech


class TranscriptionService {
  
  // MARK: - Properties
  private let appleService = AppleSTTService()
  private let googleService = GoogleSTTService()
  private var consecutiveFailures: Int = 0
  private let maxConsecutiveFailures = 5
  
  
  
  
  // MARK: - Public Interface
  /// The main transcription function that routes to the correct provider.
  func transcribe(audioURL: URL, with provider: TranscriptionProvider) async throws -> String {
    
    // Safety check: Block mock data transcription
    guard !AudioFileHelpers.isMockFile(url: audioURL) else {
      throw TranscriptionError.serviceUnavailable("Cannot transcribe mock data")
    }
    
    print("TranscriptionService: Transcribing with provider: \(provider.displayName)")
    
    switch provider {
    case .appleOnDevice:
      return try await appleService.transcribe(audioURL: audioURL)
      
    case .openAIWhisper:
      return try await transcribeWithOpenAI(audioURL: audioURL)
      
    case .googleSpeechToText:
      // Check if we should fallback due to consecutive failures
      if consecutiveFailures >= maxConsecutiveFailures {
        print("TranscriptionService: Too many failures (\(consecutiveFailures)), falling back to Apple")
        return try await appleService.transcribe(audioURL: audioURL)
      }
      
      do {
        let result = try await googleService.transcribe(audioURL: audioURL)
        consecutiveFailures = 0 // Reset on success
        return result
      } catch {
        consecutiveFailures += 1
        print("TranscriptionService: Google failed (attempt \(consecutiveFailures)/\(maxConsecutiveFailures))")
        
        // Fallback after max failures
        if consecutiveFailures >= maxConsecutiveFailures {
          print("TranscriptionService: Falling back to Apple after \(maxConsecutiveFailures) failures")
          return try await appleService.transcribe(audioURL: audioURL)
        }
        
        throw error
      }
      return try await googleService.transcribe(audioURL: audioURL)
    }
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  // MARK: - OpenAI Whisper Transcription
  //TODO: Implement OpenAI Whisper transcription service.
  
  private func transcribeWithOpenAI(audioURL: URL)  async throws -> String {
    return "OPEN AI"
  }
  
  
}
