//
//  TranscriptionService.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/5/25.
//

import SwiftUI
import Speech


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
  private func requestSFSpeechAuthorization() async  {
    await withCheckedContinuation { continuation in
      SFSpeechRecognizer.requestAuthorization { _ in
        continuation.resume()
      }
    }
    
  }
  
  /// Transcribes audio using Apple's SFSpeechRecognizer.
  private func transcribeWithApple(audioURL: URL) async throws -> String {
    
    // Request user authorization.
    await requestSFSpeechAuthorization()
    
    // Get the speech recognizer and check availability.
    guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
      throw TranscriptionError.recognizerUnavailable("Speech recognizer is not available.")
    }
    
    // Create a recognition request for the audio file.
    let request = SFSpeechURLRecognitionRequest(url: audioURL)
    
    // Force on-device recognition for privacy and offline use.
    request.requiresOnDeviceRecognition = true
    
    //Perform the recognition task.
    //TODO: Find out why this isn't working.
//    do {
//      let result = try await recognizer.recognitionTask(with: request)
//      guard let transcription = result?.bestTranscription.formattedString else {
//        throw TranscriptionError.noTranscriptionFound
//      }
//      return transcription
//      
//    } catch {
//      throw TranscriptionError.recognitionFailed("Apple's recognition task failed: \(error.localizedDescription)")
//    }
//
    
    //Perform the recognition task.
    return try await withCheckedThrowingContinuation { continuation in
        let task = recognizer.recognitionTask(with: request) { result, error in
            if let error = error {
                // If an error occurs, fail the async task
                continuation.resume(throwing: TranscriptionError.recognitionFailed("Apple's recognition task failed: \(error.localizedDescription)"))
            } else if let result = result, result.isFinal {
                // When the recognition is final and successful, return the text
                continuation.resume(returning: result.bestTranscription.formattedString)
            }
            // While result.isFinal is false, we do nothing and wait for the next update from the handler.
        }
        // You could store this task to cancel it later if needed.
        _ = task
    }
  }
}






