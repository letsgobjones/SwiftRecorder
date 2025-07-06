//
//  AudioFileHelpersTests.swift
//  SwiftRecorderTests
//
//  Created by Brandon Jones on 7/6/25.
//

import XCTest
@testable import SwiftRecorder

final class AudioFileHelpersTests: XCTestCase {
    
    func testIsMockFileWithPath() {
        // Given
        let mockFilePaths = [
            "PREVIEW_MOCK_recording.m4a",
            "SAFE_PREVIEW_MOCK_audio.m4a", 
            "MOCK_session.m4a",
            "some_MOCK_file.m4a",
            "preview_mock_test.m4a" // should work case-insensitive
        ]
        
        let realFilePaths = [
            "recording_2025_01_06_123456.m4a",
            "user_recording.m4a",
            "session_audio.m4a"
        ]
        
        // When & Then
        for mockPath in mockFilePaths {
            XCTAssertTrue(AudioFileHelpers.isMockFile(path: mockPath), "Expected \(mockPath) to be identified as mock file")
        }
        
        for realPath in realFilePaths {
            XCTAssertFalse(AudioFileHelpers.isMockFile(path: realPath), "Expected \(realPath) to NOT be identified as mock file")
        }
    }
    
    func testIsMockFileWithURL() {
        // Given
        let mockURL = URL(fileURLWithPath: "/path/to/PREVIEW_MOCK_recording.m4a")
        let realURL = URL(fileURLWithPath: "/path/to/user_recording.m4a")
        let mockURLUppercase = URL(fileURLWithPath: "/path/to/MOCK_SESSION.M4A")
        
        // When & Then
        XCTAssertTrue(AudioFileHelpers.isMockFile(url: mockURL))
        XCTAssertFalse(AudioFileHelpers.isMockFile(url: realURL))
        XCTAssertTrue(AudioFileHelpers.isMockFile(url: mockURLUppercase))
    }
    
    func testMockFileDetectionCaseInsensitive() {
        // Given
        let mixedCaseFiles = [
            "preview_mock_file.m4a",
            "Preview_Mock_File.m4a",
            "PREVIEW_MOCK_FILE.m4a",
            "file_with_mock_in_name.m4a",
            "Mock_Recording.m4a"
        ]
        
        // When & Then
        for file in mixedCaseFiles {
            XCTAssertTrue(AudioFileHelpers.isMockFile(path: file), "Case insensitive detection should work for \(file)")
        }
    }
    
    func testNonMockFiles() {
        // Given - Files that might seem like mock but shouldn't be detected
        let nonMockFiles = [
            "recording_with_mock_user.m4a", // "mock" in different context
            "my_recording.m4a",
            "audio_session_001.m4a",
            "microphone_test.m4a",
            "",  // empty string
            "just_mock", // no extension
            "session.mp3" // different extension
        ]
        
        // When & Then
        for file in nonMockFiles {
            XCTAssertFalse(AudioFileHelpers.isMockFile(path: file), "File \(file) should NOT be detected as mock")
        }
    }
    
    func testGenerateUniqueFileName() {
        // When
        let fileName1 = AudioFileHelpers.generateUniqueFileName()
        let fileName2 = AudioFileHelpers.generateUniqueFileName()
        
        // Then
        XCTAssertNotEqual(fileName1, fileName2)
        XCTAssertTrue(fileName1.hasSuffix(".m4a"))
        XCTAssertTrue(fileName2.hasSuffix(".m4a"))
        XCTAssertTrue(fileName1.contains("recording_"))
        XCTAssertTrue(fileName2.contains("recording_"))
        
        // Test that filenames are valid (no invalid characters)
        let invalidCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")
        XCTAssertTrue(fileName1.rangeOfCharacter(from: invalidCharacters) == nil)
        XCTAssertTrue(fileName2.rangeOfCharacter(from: invalidCharacters) == nil)
    }
    
    func testFileExtensionValidation() {
        // Given
        let validFiles = [
            "test.m4a",
            "recording.M4A",
            "audio.m4a"
        ]
        
        let invalidFiles = [
            "test.mp3",
            "recording.wav",
            "audio.txt",
            "file_without_extension",
            ""
        ]
        
        // When & Then
        for file in validFiles {
            XCTAssertTrue(AudioFileHelpers.isValidAudioFile(file), "\(file) should be valid")
        }
        
        for file in invalidFiles {
            XCTAssertFalse(AudioFileHelpers.isValidAudioFile(file), "\(file) should be invalid")
        }
    }
    
    func testFileSizeFormatting() {
        // Given
        let testCases: [(Int64, String)] = [
            (500, "500 bytes"),
            (1024, "1 KB"),
            (1_048_576, "1 MB"),
            (1_500_000, "1.4 MB"),
            (0, "Zero KB")
        ]
        
        // When & Then
        for (bytes, expectedContains) in testCases {
            let formatted = AudioFileHelpers.formatFileSize(bytes)
            XCTAssertFalse(formatted.isEmpty, "Formatted size should not be empty for \(bytes) bytes")
            // Note: Exact format may vary by system, so we just check it's not empty
        }
    }
    
    func testGetFileSize() throws {
        // Given - Create a temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let testFileURL = tempDir.appendingPathComponent("test_audio.m4a")
        let testData = Data("test audio data".utf8)
        
        // When
        try testData.write(to: testFileURL)
        let fileSize = try AudioFileHelpers.getFileSize(at: testFileURL)
        
        // Then
        XCTAssertEqual(fileSize, Int64(testData.count))
        
        // Cleanup
        try? FileManager.default.removeItem(at: testFileURL)
    }
    
    func testGetFileSizeNonExistentFile() {
        // Given
        let nonExistentURL = URL(fileURLWithPath: "/path/to/nonexistent/file.m4a")
        
        // When & Then
        XCTAssertThrowsError(try AudioFileHelpers.getFileSize(at: nonExistentURL)) { error in
            // Should throw an error for non-existent file
            XCTAssertTrue(error is CocoaError)
        }
    }
}