//
//  TranscriptionProvider.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/3/25.
//

import SwiftUI

// Defines the available transcription services
enum TranscriptionProvider: String, CaseIterable {
  case appleOnDevice = "apple_on_device"
  case googleSpeechToText = "google_speech_to_text"
  case openAIWhisper = "openai_whisper"
  
  var displayName: String {
    switch self {
    case .appleOnDevice:
      return "Apple On-Device"
    case .googleSpeechToText:
      return "Google Speech-to-Text"
    case .openAIWhisper:
      return "OpenAI Whisper"
    }
  }
  
  var isCloudBased: Bool {
    switch self {
    case .appleOnDevice:
      return false
    case .googleSpeechToText:
      return true
    case .openAIWhisper:
      return true
    }
  }
  
  var requiresAPIKey: Bool {
    switch self {
    case .appleOnDevice:
      return false
    case .googleSpeechToText:
      return true
    case .openAIWhisper:
      return true
    }
  }
}
