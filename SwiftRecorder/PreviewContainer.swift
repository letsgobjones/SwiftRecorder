//
//  PreviewContainer.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/2/25.
//

import SwiftData
import SwiftUI

@MainActor
struct PreviewContainer {
  static var shared: ModelContainer = {
    let schema = Schema([RecordingSession.self, TranscriptionSegment.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    do {
      let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
      insertSampleData(context: container.mainContext)
      return container
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()
  
  static func insertSampleData(context: ModelContext) {
    // Sessions with mock file paths to prevent API calls
    let sessions = [
      RecordingSession(
        createdAt: Date().addingTimeInterval(-86400),
        duration: 45.2,
        audioFilePath: "PREVIEW_MOCK_recording_1.m4a",
        isProcessing: false
      ),
      RecordingSession(
        createdAt: Date().addingTimeInterval(-3600),
        duration: 120.5,
        audioFilePath: "PREVIEW_MOCK_recording_2.m4a",
        isProcessing: false
      ),
      RecordingSession(
        createdAt: Date().addingTimeInterval(-300),
        duration: 30.0,
        audioFilePath: "PREVIEW_MOCK_recording_3.m4a",
        isProcessing: false
      )
    ]
    
    // Sample segments for UI testing
    let segments = [
      TranscriptionSegment(startTime: 0.0, transcriptionText: "Hello world, this is a test transcription.", status: .completed),
      TranscriptionSegment(startTime: 15.5, transcriptionText: "Another completed segment for UI testing.", status: .completed),
      TranscriptionSegment(startTime: 30.0, transcriptionText: "", status: .processing),
      TranscriptionSegment(startTime: 45.0, transcriptionText: "Transcription failed", status: .failed),
      TranscriptionSegment(startTime: 60.0, transcriptionText: "", status: .queued)
    ]
    
    // Link segments to sessions
    sessions[0].segments = [segments[0], segments[1]]
    sessions[1].segments = [segments[2], segments[3], segments[4]]
    
    segments[0].session = sessions[0]
    segments[1].session = sessions[0]
    segments[2].session = sessions[1]
    segments[3].session = sessions[1]
    segments[4].session = sessions[1]
    
    // Insert and save
    sessions.forEach { context.insert($0) }
    segments.forEach { context.insert($0) }
    
    try? context.save()
  }
  
  static func sampleSession() -> RecordingSession {
    let session = RecordingSession(
      createdAt: Date(),
      duration: 45.2,
      audioFilePath: "PREVIEW_MOCK_sample.m4a",
      isProcessing: false
    )
    
    let segment = TranscriptionSegment(
      startTime: 0.0,
      transcriptionText: "Sample transcription for preview.",
      status: .completed
    )
    
    segment.session = session
    session.segments = [segment]
    return session
  }
}