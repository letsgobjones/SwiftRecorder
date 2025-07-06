//
//  RecordingSessionTests.swift
//  SwiftRecorderTests
//
//  Created by Brandon Jones on 7/6/25.
//

import XCTest
import SwiftData
@testable import SwiftRecorder

@MainActor
final class RecordingSessionTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        modelContainer = MockModelContainer.create()
        modelContext = modelContainer.mainContext
    }
    
    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }
    
    func testRecordingSessionCreation() {
        // Given
        let session = RecordingSession(
            createdAt: Date(),
            duration: 30.0,
            audioFilePath: "test.m4a"
        )
        
        // When
        modelContext.insert(session)
        try? modelContext.save()
        
        // Then
        XCTAssertNotNil(session.id)
        XCTAssertEqual(session.duration, 30.0)
        XCTAssertEqual(session.audioFilePath, "test.m4a")
        XCTAssertFalse(session.isProcessing)
        XCTAssertTrue(session.segments.isEmpty)
    }
    
    func testSortedSegments() {
        // Given
        let session = RecordingSession(
            createdAt: Date(),
            duration: 60.0,
            audioFilePath: "test.m4a"
        )
        
        let segment1 = TranscriptionSegment(startTime: 30.0, transcriptionText: "Second", status: .completed)
        let segment2 = TranscriptionSegment(startTime: 0.0, transcriptionText: "First", status: .completed)
        let segment3 = TranscriptionSegment(startTime: 45.0, transcriptionText: "Third", status: .completed)
        
        segment1.session = session
        segment2.session = session
        segment3.session = session
        session.segments = [segment1, segment2, segment3]
        
        // When
        let sortedSegments = session.sortedSegments
        
        // Then
        XCTAssertEqual(sortedSegments.count, 3)
        XCTAssertEqual(sortedSegments[0].startTime, 0.0)
        XCTAssertEqual(sortedSegments[1].startTime, 30.0)
        XCTAssertEqual(sortedSegments[2].startTime, 45.0)
        XCTAssertEqual(sortedSegments[0].transcriptionText, "First")
        XCTAssertEqual(sortedSegments[1].transcriptionText, "Second")
        XCTAssertEqual(sortedSegments[2].transcriptionText, "Third")
    }
    
    func testSessionWithSegmentRelationship() {
        // Given
        let session = RecordingSession(
            createdAt: Date(),
            duration: 30.0,
            audioFilePath: "test.m4a"
        )
        
        let segment = TranscriptionSegment(
            startTime: 0.0,
            transcriptionText: "Test transcription",
            status: .completed
        )
        
        // When
        segment.session = session
        session.segments.append(segment)
        
        modelContext.insert(session)
        modelContext.insert(segment)
        try? modelContext.save()
        
        // Then
        XCTAssertEqual(session.segments.count, 1)
        XCTAssertEqual(session.segments.first?.transcriptionText, "Test transcription")
        XCTAssertEqual(segment.session?.id, session.id)
    }
}