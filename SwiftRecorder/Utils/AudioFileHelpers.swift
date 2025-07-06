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
}