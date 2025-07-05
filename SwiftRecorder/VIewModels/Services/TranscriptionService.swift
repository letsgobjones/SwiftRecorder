//
//  TranscriptionService.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/5/25.
//

import SwiftUI
import Speech


// Defines the available transcription services
enum TranscriptionProvider {
    case appleOnDevice
    // case google
    // case whisper
}



class TranscriptionService {
  
  // MARK: - Error Handling
  enum TranscriptionError: Error {
    case authorizationDenied(String)
    case recognizerUnavailable(String)
    case recognitionFailed(String)
    case noTranscriptionFound
  }
  
  // MARK: - Public Interface
  /// The main transcription function that routes to the correct provider.
  func transcribe(audioURL: URL, with provider: TranscriptionProvider) async throws -> String {
    switch provider {
    case .appleOnDevice:
      return try await transcribeWithApple(audioURL: audioURL)
    }
  }
  
  
  // MARK: - Apple On-Device Transcription
  
  /// Asynchronously requests permission for speech recognition.
  private func requestSFSpeechAuthorization() async throws {
    let authStatus = await withCheckedContinuation { continuation in
      SFSpeechRecognizer.requestAuthorization { status in
        continuation.resume(returning: status)
      }
    }
    
    switch authStatus {
    case .authorized:
      print("TranscriptionService: Speech recognition authorized")
    case .denied:
      throw TranscriptionError.authorizationDenied("Speech recognition access was denied. Please grant access in Settings.")
    case .restricted:
      throw TranscriptionError.authorizationDenied("Speech recognition is restricted on this device.")
    case .notDetermined:
      throw TranscriptionError.authorizationDenied("Speech recognition authorization is not determined.")
    @unknown default:
      throw TranscriptionError.authorizationDenied("Unknown speech recognition authorization status.")
    }
  }
  
  /// Transcribes audio using Apple's SFSpeechRecognizer.
  private func transcribeWithApple(audioURL: URL) async throws -> String {
    print("TranscriptionService: Starting Apple transcription for: \(audioURL.lastPathComponent)")
    
    // Request user authorization.
    try await requestSFSpeechAuthorization()
    
    // Get the speech recognizer and check availability.
    guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
      throw TranscriptionError.recognizerUnavailable("Speech recognizer is not available.")
    }
    
    // Create a recognition request for the audio file.
    let request = SFSpeechURLRecognitionRequest(url: audioURL)
    
    // Force on-device recognition for privacy and offline use.
    request.requiresOnDeviceRecognition = true
    
    // Perform the recognition task using continuation to make it async
    return try await withCheckedThrowingContinuation { continuation in
      print("TranscriptionService: Starting recognition task...")
      
      let task = recognizer.recognitionTask(with: request) { result, error in
        if let error = error {
          print("TranscriptionService: Recognition failed with error: \(error.localizedDescription)")
          continuation.resume(throwing: TranscriptionError.recognitionFailed("Apple's recognition task failed: \(error.localizedDescription)"))
          return
        }
        
        guard let result = result else {
          print("TranscriptionService: No result received from recognition task")
          continuation.resume(throwing: TranscriptionError.noTranscriptionFound)
          return
        }
        
        // Check if the result is final (transcription is complete)
        if result.isFinal {
          let transcription = result.bestTranscription.formattedString
          print("TranscriptionService: Final transcription received: \(transcription)")
          
          if transcription.isEmpty {
            continuation.resume(throwing: TranscriptionError.noTranscriptionFound)
          } else {
            continuation.resume(returning: transcription)
          }
        }
      }
      
      // Keep a reference to the task to prevent it from being deallocated
      // The task will be automatically cancelled when the continuation completes
      _ = task
    }
  }
}
