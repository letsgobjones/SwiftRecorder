//
//  GoogleSTTService.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import Foundation
import AVFoundation

/// Google Speech-to-Text API integration with retry logic and error handling.
class GoogleSTTService {
    
    private let apiURL = "https://speech.googleapis.com/v1/speech:recognize"
    private let maxRetries = 3
    private let baseRetryDelay: TimeInterval = 1.0
    
    func transcribe(audioURL: URL) async throws -> String {
        print("GoogleSpeechToTextService: Starting transcription")
        
        // Get API key using your existing APIKeyManager
        let apiKey = try APIKeyManager.shared.getAPIKey(for: .googleSpeechToText)
        
        // Convert audio to the required format (LINEAR16)
        let audioData = try await convertAudioToRequiredFormat(audioURL: audioURL)
        
        // Attempt transcription with retry logic
        for attempt in 0..<maxRetries {
            do {
                return try await performTranscriptionRequest(audioData: audioData, apiKey: apiKey)
            } catch let error as GoogleSpeechError where error.isRetryable {
                if attempt < maxRetries - 1 {
                    let delay = baseRetryDelay * pow(2.0, Double(attempt))
                    print("GoogleSpeechToTextService: Retrying in \(delay) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            } catch {
                // Non-retryable error, fail immediately
                throw error
            }
        }
        
        throw GoogleSpeechError.allRetriesFailed("All retry attempts failed")
    }
    
    // MARK: - Audio Conversion

    /// Converts an audio file to the format required by Google Speech-to-Text (16-bit PCM @ 16kHz).
    /// This version uses a loop to process the audio in chunks, making it robust for any file size.
    private func convertAudioToRequiredFormat(audioURL: URL) async throws -> Data {
        print("GoogleSpeechToTextService: Converting audio to required format")
        
        let audioFile = try AVAudioFile(forReading: audioURL)
        let inputFormat = audioFile.processingFormat
        
        // Define the target format: 16kHz, mono, 16-bit PCM
        guard let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        ) else {
            throw GoogleSpeechError.audioProcessingError("Failed to create the target audio format.")
        }

        guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            throw GoogleSpeechError.audioProcessingError("Failed to create the audio converter.")
        }
        
        var convertedData = Data()
        let bufferSize: AVAudioFrameCount = 4096 // Process in chunks of 4096 frames
        
        // Prepare buffers for conversion
        guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: bufferSize) else {
             throw GoogleSpeechError.audioProcessingError("Failed to create input buffer.")
        }
        
        while true {
            let status = converter.convert(to: inputBuffer, error: nil) { inNumPackets, outStatus in
                do {
                    // Read a chunk from the original audio file
                    try audioFile.read(into: inputBuffer, frameCount: bufferSize)
                    outStatus.pointee = .haveData
                    return inputBuffer
                } catch {
                    // This error indicates the end of the file or a read error
                    outStatus.pointee = .endOfStream
                    return nil
                }
            }
            
            // Append the converted data
            convertedData.append(bufferToData(buffer: inputBuffer))
            
            // Stop when the converter signals the end of the stream
            if status == .endOfStream {
                break
            }
        }
        
        print("GoogleSpeechToTextService: Audio conversion successful.")
        return convertedData
    }

    /// Helper function to extract raw audio bytes from an AVAudioPCMBuffer.
    private func bufferToData(buffer: AVAudioPCMBuffer) -> Data {
        let channelData = buffer.int16ChannelData!
        let frames = buffer.frameLength
        var data = Data()
        
        // Loop through each frame and append its little-endian byte representation.
        // LINEAR16 format expects little-endian byte order.
        for frame in 0..<frames {
            let sample = channelData[0][Int(frame)]
            withUnsafeBytes(of: sample.littleEndian) { bytes in
                data.append(contentsOf: bytes)
            }
        }
        
        return data
    }
    
    // MARK: - Network Request

    private func performTranscriptionRequest(audioData: Data, apiKey: String) async throws -> String {
        var request = URLRequest(url: URL(string: "\(apiURL)?key=\(apiKey)")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = GoogleSpeechRequest(
            config: GoogleSpeechConfig(
                encoding: "LINEAR16",
                sampleRateHertz: 16000,
                languageCode: "en-US",
                enableAutomaticPunctuation: true,
                model: "latest_short"
            ),
            audio: GoogleSpeechAudio(content: audioData.base64EncodedString())
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleSpeechError.networkError("Invalid response from server.")
        }
        
        switch httpResponse.statusCode {
        case 200:
            break // Success
        case 401:
            throw GoogleSpeechError.authenticationError("Invalid API key.")
        case 429:
            throw GoogleSpeechError.rateLimitError("Rate limit exceeded. Retryable.")
        case 500...599:
            throw GoogleSpeechError.serverError("Google server error. Retryable.")
        default:
            throw GoogleSpeechError.unknownError("Received HTTP \(httpResponse.statusCode).")
        }
        
        let speechResponse = try JSONDecoder().decode(GoogleSpeechResponse.self, from: data)
        
        guard let transcript = speechResponse.results?.first?.alternatives?.first?.transcript else {
            throw GoogleSpeechError.noTranscription("No transcription found in the response.")
        }
        
        return transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

