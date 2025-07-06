//
//  TranscriptionError.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import Foundation

// MARK: - Error Handling

/// Unified error type for all transcription services
enum TranscriptionError: LocalizedError {
    // Apple Speech Recognition Errors
    case authorizationDenied(String)
    case recognizerUnavailable(String)
    case recognitionFailed(String)
    case noTranscriptionFound
    
    // Google Speech-to-Text Errors
    case audioProcessingError(String)
    case authenticationError(String)
    case rateLimitError(String)
    case serverError(String)
    case networkError(String)
    case apiKeyMissing(String)
    
    // General Service Errors
    case serviceUnavailable(String)
    case allRetriesFailed(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        // Apple errors
        case .authorizationDenied(let message): return "Authorization Denied: \(message)"
        case .recognizerUnavailable(let message): return "Recognizer Unavailable: \(message)"
        case .recognitionFailed(let message): return "Recognition Failed: \(message)"
        case .noTranscriptionFound: return "No Transcription Found"
        
        // Google errors
        case .audioProcessingError(let message): return "Audio Error: \(message)"
        case .authenticationError(let message): return "Auth Error: \(message)"
        case .rateLimitError(let message): return "Rate Limit: \(message)"
        case .serverError(let message): return "Server Error: \(message)"
        case .networkError(let message): return "Network Error: \(message)"
        case .apiKeyMissing(let message): return "API Key Missing: \(message)"
        
        // General errors
        case .serviceUnavailable(let message): return "Service Unavailable: \(message)"
        case .allRetriesFailed(let message): return "All Retries Failed: \(message)"
        case .unknownError(let message): return "Unknown Error: \(message)"
        }
    }
    
    /// Determines if the error is retryable (for Google Speech-to-Text)
    var isRetryable: Bool {
        switch self {
        case .networkError, .serverError, .rateLimitError:
            return true
        default:
            return false
        }
    }
}
