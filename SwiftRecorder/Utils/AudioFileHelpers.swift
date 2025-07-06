//
//  AudioFileHelpers.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import Foundation

/// Utility for audio file operations and mock data detection
struct AudioFileHelpers {
    
    // MARK: - Mock File Detection
    
    private static let mockPrefixes = ["PREVIEW_MOCK", "SAFE_PREVIEW_MOCK", "MOCK"]
    
    /// Checks if the audio file is mock/preview data to prevent API calls
    static func isMockFile(url: URL) -> Bool {
        let fileName = url.lastPathComponent.uppercased()
        return mockPrefixes.contains { fileName.contains($0) }
    }
    
    /// Checks if the audio file path is mock/preview data
    static func isMockFile(path: String) -> Bool {
        let fileName = path.uppercased()
        return mockPrefixes.contains { fileName.contains($0) }
    }
    
    // MARK: - File Name Generation
    
    /// Generates a unique filename for audio recordings
    static func generateUniqueFileName() -> String {
        let timestamp = Date().formatted(.dateTime.year().month().day().hour().minute().second())
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: ",", with: "")
        
        let uuid = UUID().uuidString.prefix(8)
        return "recording_\(timestamp)_\(uuid).m4a"
    }
    
    // MARK: - File Validation
    
    /// Validates if the file extension is supported for audio recording
    static func isValidAudioFile(_ fileName: String) -> Bool {
        let validExtensions = ["m4a", "M4A"]
        let fileExtension = URL(fileURLWithPath: fileName).pathExtension
        return validExtensions.contains(fileExtension)
    }
    
    /// Gets the file size in bytes for an audio file
    static func getFileSize(at url: URL) throws -> Int64 {
        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(resourceValues.fileSize ?? 0)
    }
    
    /// Formats file size for display (e.g., "1.2 MB")
    static func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useBytes]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}