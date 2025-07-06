//
//  MockModelContainer.swift
//  SwiftRecorderTests
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftData
import Foundation
@testable import SwiftRecorder

/// Mock model container for testing SwiftData models
class MockModelContainer {
    static func create() -> ModelContainer {
        let schema = Schema([
            RecordingSession.self,
            TranscriptionSegment.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true // Important: in-memory for tests
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create test model container: \(error)")
        }
    }
    
    static func createSampleSession() -> RecordingSession {
        let session = RecordingSession(
            createdAt: Date(),
            duration: 30.0,
            audioFilePath: "test_recording.m4a",
            isProcessing: false
        )
        
        let segment1 = TranscriptionSegment(
            startTime: 0.0,
            transcriptionText: "Hello, this is a test recording.",
            status: .completed
        )
        
        let segment2 = TranscriptionSegment(
            startTime: 15.0,
            transcriptionText: "This is the second segment.",
            status: .completed
        )
        
        segment1.session = session
        segment2.session = session
        session.segments = [segment1, segment2]
        
        return session
    }
}