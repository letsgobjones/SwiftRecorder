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
}
