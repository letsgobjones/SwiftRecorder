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
        
        print("GoogleSpeechToTextService: Input format - Sample Rate: \(inputFormat.sampleRate), Channels: \(inputFormat.channelCount)")
        
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
        
        // Create output buffer with the correct format
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: bufferSize) else {
            throw GoogleSpeechError.audioProcessingError("Failed to create output buffer.")
        }
        
        var inputBuffer: AVAudioPCMBuffer?
        
        audioFile.framePosition = 0 // Reset to beginning
        
        while true {
            // Create input buffer for this chunk
            guard let currentInputBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: bufferSize) else {
                throw GoogleSpeechError.audioProcessingError("Failed to create input buffer.")
            }
            
            // Read a chunk from the original audio file
            do {
                try audioFile.read(into: currentInputBuffer, frameCount: bufferSize)
                
                // Check if we actually read any frames
                if currentInputBuffer.frameLength == 0 {
                    print("GoogleSpeechToTextService: Reached end of audio file")
                    break
                }
                
                inputBuffer = currentInputBuffer
                
            } catch {
                print("GoogleSpeechToTextService: Finished reading audio file")
                break
            }
            
            // Convert the chunk
            var conversionError: NSError?
            let status = converter.convert(to: outputBuffer, error: &conversionError) { inNumPackets, outStatus in
                outStatus.pointee = .haveData
                return inputBuffer
            }
            
            if let error = conversionError {
                throw GoogleSpeechError.audioProcessingError("Audio conversion failed: \(error.localizedDescription)")
            }
            
            if status == .error {
                throw GoogleSpeechError.audioProcessingError("Audio conversion failed with unknown error")
            }
            
            // Append the converted data if we have frames
            if outputBuffer.frameLength > 0 {
                let chunkData = try bufferToData(buffer: outputBuffer)
                convertedData.append(chunkData)
                print("GoogleSpeechToTextService: Converted chunk - \(outputBuffer.frameLength) frames, \(chunkData.count) bytes")
            }
            
            // Reset the output buffer for the next chunk
            outputBuffer.frameLength = 0
            
            // If we didn't fill the input buffer, we're done
            if currentInputBuffer.frameLength < bufferSize {
                break
            }
        }
        
        print("GoogleSpeechToTextService: Audio conversion successful - Total size: \(convertedData.count) bytes")
        return convertedData
    }

    /// Helper function to extract raw audio bytes from an AVAudioPCMBuffer.
    private func bufferToData(buffer: AVAudioPCMBuffer) throws -> Data {
        // Validate that we have int16 channel data
        guard let channelData = buffer.int16ChannelData else {
            throw GoogleSpeechError.audioProcessingError("Buffer does not contain int16 channel data")
        }
        
        guard buffer.frameLength > 0 else {
            throw GoogleSpeechError.audioProcessingError("Buffer is empty")
        }
        
        let frames = buffer.frameLength
        var data = Data()
        
        print("GoogleSpeechToTextService: Converting \(frames) frames to data")
        
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
        print("GoogleSpeechToTextService: Sending request with \(audioData.count) bytes of audio data")
        
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
        
        print("GoogleSpeechToTextService: Received HTTP \(httpResponse.statusCode)")
        
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
        
        print("GoogleSpeechToTextService: Transcription successful")
        return transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}