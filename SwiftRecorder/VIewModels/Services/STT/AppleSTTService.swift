//
//  AppleSTTService.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI
import Speech

// MARK: - Apple On-Device Transcription

/// Apple on-device speech recognition service
class AppleSTTService {
  
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
   func transcribe(audioURL: URL) async throws -> String {
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
    
    // Enable additional features for better transcription quality
    if #available(iOS 16.0, *) {
      request.addsPunctuation = true // Add punctuation automatically
    }
    
    // Perform the recognition task using continuation to make it async
    let rawTranscription = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
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
    
    // For iOS versions before 16.0, add basic punctuation manually
    if #available(iOS 16.0, *) {
      return rawTranscription
    } else {
      return addBasicPunctuation(to: rawTranscription)
    }
  }
  
  /// Adds basic punctuation to transcription text for iOS versions before 16.0
  private func addBasicPunctuation(to text: String) -> String {
    var result = text
    
    // Add periods at the end of sentences (basic heuristic)
    result = result.replacingOccurrences(of: "\\b(yes|no|okay|ok|well|so|now|then|next|finally|however|therefore|meanwhile|also|furthermore|moreover|additionally|consequently|thus|hence|afterwards|later|earlier|before|after|during)\\b", with: ". $1", options: [.regularExpression, .caseInsensitive])
    
    // Add commas for natural pauses (basic heuristic)
    result = result.replacingOccurrences(of: "\\b(and|but|or|yet|for|nor|so|however|nevertheless|furthermore|moreover|therefore|thus|hence|consequently|meanwhile|otherwise|instead|besides|additionally)\\b", with: ", $1", options: [.regularExpression, .caseInsensitive])
    
    // Add question marks for questions
    result = result.replacingOccurrences(of: "\\b(what|when|where|who|why|how|is|are|was|were|will|would|could|should|can|do|does|did)\\b([^.!?]*?)\\b(right|correct|true|sure)\\s*$", with: "$1$2$3?", options: [.regularExpression, .caseInsensitive])
    
    // Capitalize first letter
    if !result.isEmpty {
      result = result.prefix(1).capitalized + result.dropFirst()
    }
    
    // Add final period if missing punctuation
    if !result.isEmpty && ![".", "!", "?"].contains(result.last) {
      result += "."
    }
    
    print("TranscriptionService: Added basic punctuation to Apple transcription")
    return result
  }
}