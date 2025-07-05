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
    let schema = Schema([
      RecordingSession.self, TranscriptionSegment.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    do {
      print("Creating Preview ModelContainer...")
      let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
      print("Preview ModelContainer created successfully.")

      // Insert sample data for previews
      print("PreviewContainer: Inserting sample data...")
      insertSampleData(context: container.mainContext)
      print("PreviewContainer: Sample data insertion complete.")

      return container
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()
  
  /// Inserts sample data into the preview container for testing
  static func insertSampleData(context: ModelContext) {
    // Create sample sessions
    let session1 = RecordingSession(
      createdAt: Date().addingTimeInterval(-86400), // 1 day ago
      duration: 45.2,
      audioFilePath: "sample_recording.m4a",
      isProcessing: false
    )
    
    let session2 = RecordingSession(
      createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
      duration: 120.5,
      audioFilePath: "sample_recording_2.m4a",
      isProcessing: true
    )
    
    let session3 = RecordingSession(
      createdAt: Date().addingTimeInterval(-300), // 5 minutes ago
      duration: 30.0,
      audioFilePath: "sample_recording_3.m4a",
      isProcessing: false
    )
    
    // Create sample transcription segments
    let segment1 = TranscriptionSegment(
      startTime: 0.0,
      transcriptionText: "Hello world, this is a test transcription segment.",
      status: .completed
    )
    
    let segment2 = TranscriptionSegment(
      startTime: 15.5,
      transcriptionText: "This is another completed segment with more content.",
      status: .completed
    )
    
    let segment3 = TranscriptionSegment(
      startTime: 30.2,
      transcriptionText: "",
      status: .processing
    )
    
    let segment4 = TranscriptionSegment(
      startTime: 45.0,
      transcriptionText: "",
      status: .failed
    )
    
    let segment5 = TranscriptionSegment(
      startTime: 60.0,
      transcriptionText: "",
      status: .pending
    )
    
    // Add segments to sessions
    session1.segments = [segment1, segment2]
    session2.segments = [segment3, segment4, segment5]
    // session3 has no segments
    
    // Insert into context
    context.insert(session1)
    context.insert(session2)
    context.insert(session3)
    
    context.insert(segment1)
    context.insert(segment2)
    context.insert(segment3)
    context.insert(segment4)
    context.insert(segment5)
    
    // Save the context
    do {
      try context.save()
      print("PreviewContainer: Sample data saved successfully")
    } catch {
      print("PreviewContainer: Failed to save sample data: \(error)")
    }
  }
  
  /// Gets a sample session for individual component previews
  static func sampleSession() -> RecordingSession {
    RecordingSession(
      createdAt: Date(),
      duration: 45.2,
      audioFilePath: "sample_recording.m4a",
      isProcessing: false
    )
  }
}