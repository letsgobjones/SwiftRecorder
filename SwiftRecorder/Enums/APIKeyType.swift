//
//  APIKeyType.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI

enum APIKeyType: String, CaseIterable {
    case googleSpeechToText
    case openAIWhisper
    // Add other key types here in the future
    
    /// The unique account name for this key in the Keychain.
    var accountName: String {
        switch self {
        case .googleSpeechToText:
            return "google_speech_to_text_api_key"
        case .openAIWhisper:
            return "openai_whisper_api_key"
        }
    }
    
    /// A user-friendly name for display in the UI.
    var displayName: String {
        switch self {
        case .googleSpeechToText:
            return "Google Speech-to-Text"
        case .openAIWhisper:
            return "OpenAI Whisper"
        }
    }
  
  
  /// The SFSymbol icon name for the section header.
  var iconName: String {
          switch self {
          case .googleSpeechToText: "cloud"
          case .openAIWhisper: "brain"
          }
      }
      
      /// The instructional text for the section footer.
      var instructions: [String] {
          switch self {
          case .googleSpeechToText:
              return [
                  "1. Go to console.cloud.google.com",
                  "2. Enable Speech-to-Text API",
                  "3. Create credentials → API Key",
                  "4. Restrict key to Speech-to-Text API"
              ]
          case .openAIWhisper:
              return [
                  "1. Go to platform.openai.com",
                  "2. Sign in to your account",
                  "3. Go to API Keys section",
                  "4. Create new secret key"
              ]
          }
      }
}
