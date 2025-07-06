//
//  Google.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import Foundation


// MARK: - Data Models
// (These are correct and remain unchanged)
struct GoogleSpeechRequest: Codable {
    let config: GoogleSpeechConfig
    let audio: GoogleSpeechAudio
}

struct GoogleSpeechConfig: Codable {
    let encoding: String
    let sampleRateHertz: Int
    let languageCode: String
    let enableAutomaticPunctuation: Bool
    let model: String
}

struct GoogleSpeechAudio: Codable {
    let content: String
}

struct GoogleSpeechResponse: Codable {
    let results: [GoogleSpeechResult]?
}

struct GoogleSpeechResult: Codable {
    let alternatives: [GoogleSpeechAlternative]?
}

struct GoogleSpeechAlternative: Codable {
    let transcript: String
    let confidence: Float?
}

// MARK: - Errors
// (This is well-designed and remains unchanged)
enum GoogleSpeechError: LocalizedError {
    case audioProcessingError(String)
    case authenticationError(String)
    case rateLimitError(String)
    case serverError(String)
    case networkError(String)
    case noTranscription(String)
    case unknownError(String)
    case allRetriesFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .audioProcessingError(let msg): return "Audio Error: \(msg)"
        case .authenticationError(let msg): return "Auth Error: \(msg)"
        case .rateLimitError(let msg): return "Rate Limit: \(msg)"
        case .serverError(let msg): return "Server Error: \(msg)"
        case .networkError(let msg): return "Network Error: \(msg)"
        case .noTranscription(let msg): return "No Transcription: \(msg)"
        case .unknownError(let msg): return "Unknown Error: \(msg)"
        case .allRetriesFailed(let msg): return "All Retries Failed: \(msg)"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .networkError, .serverError, .rateLimitError:
            return true
        default:
            return false
        }
    }
}
