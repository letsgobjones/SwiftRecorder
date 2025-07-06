//
//  OpenAISTTService.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import Foundation
import AVFoundation

/// OpenAI Whisper API integration with retry logic
class OpenAISTTService {
    
    private let apiURL = "https://api.openai.com/v1/audio/transcriptions"
    private let maxRetries = 3
    private let baseRetryDelay: TimeInterval = 1.0
    
    func transcribe(audioURL: URL) async throws -> String {
        print("OpenAIWhisperService: Starting transcription")
        
        // Get API key
        let apiKey = try APIKeyManager.shared.getAPIKey(for: .openAIWhisper)
        
        // Attempt transcription with retry logic
        for attempt in 0..<maxRetries {
            do {
                return try await performTranscriptionRequest(audioURL: audioURL, apiKey: apiKey)
            } catch let error as TranscriptionError where error.isRetryable {
                if attempt < maxRetries - 1 {
                    let delay = baseRetryDelay * pow(2.0, Double(attempt))
                    print("OpenAIWhisperService: Retrying in \(delay) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            } catch {
                throw error
            }
        }
        
        throw TranscriptionError.allRetriesFailed("All retry attempts failed")
    }
    
    private func performTranscriptionRequest(audioURL: URL, apiKey: String) async throws -> String {
        // Create multipart form data request
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: apiURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Read audio file data
        let audioData: Data
        do {
            audioData = try Data(contentsOf: audioURL)
        } catch {
            throw TranscriptionError.audioProcessingError("Failed to read audio file: \(error.localizedDescription)")
        }
        
        // Create multipart body
        var body = Data()
        
        // Add model field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add file field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionError.networkError("Invalid response")
        }
        
        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw TranscriptionError.authenticationError("Invalid API key")
        case 429:
            throw TranscriptionError.rateLimitError("Rate limit exceeded")
        case 500...599:
            throw TranscriptionError.serverError("Server error")
        default:
            throw TranscriptionError.unknownError("HTTP \(httpResponse.statusCode)")
        }
        
        let whisperResponse = try JSONDecoder().decode(OpenAIWhisperResponse.self, from: data)
        
        guard !whisperResponse.text.isEmpty else {
            throw TranscriptionError.noTranscriptionFound
        }
        
        return whisperResponse.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
