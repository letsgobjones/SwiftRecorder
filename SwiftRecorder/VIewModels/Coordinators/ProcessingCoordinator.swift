//
//  ProcessingCoordinator.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/5/25.
//

import Foundation
import SwiftData

@Observable
class ProcessingCoordinator {
  
  private let transcriptionService: TranscriptionService
  
  init() {
    self.transcriptionService = TranscriptionService()
    print("ProcessingCoordinator initialized")
  }
  
  
  /// Processes a given recording session to generate a transcription.
  
  /// This function performs the following steps:
  /// 1. Constructs the full URL to the recorded audio file.
  /// 2. Calls the `transcriptionService` to get the transcribed text using Apple's on-device model.
  /// 3. Creates a `TranscriptionSegment` with the result.
  /// 4. Associates the new segment with the `RecordingSession`.
  /// 5. Updates the session's processing status and saves the changes to SwiftData.
  
  @MainActor
  func process(session: RecordingSession, modelContext: ModelContext) async {
    print("ProcessingCoordinator: Processing session: \(session.id)")
    
    // Construct the full URL to the audio file
    guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      print("ERROR: Could not find the documents directory.")
      session.isProcessing = false
      return
    }
    let audioFileURL = documentsPath.appendingPathComponent(session.audioFilePath)
    
    do {
      // Perform transcription using the specified provider
      let transcriptionText = try await transcriptionService.transcribe(
        audioURL: audioFileURL,
        with: .appleOnDevice // Specify Apple's on-device service
      )
      
      // Create and populate the new transcription segment
      let segment = TranscriptionSegment(
        startTime: 0, transcriptionText: transcriptionText, // For now, we assume a single segment starting at 0
        status: .completed
      )
      
      // Add the new segment to the session
      session.segments.append(segment)
      print("ProcessingCoordinator: Successfully transcribed and added segment.")
      
    } catch {
      // If any error occurs during transcription, mark the segment as failed.
      let failedSegment = TranscriptionSegment(
        startTime: 0, transcriptionText: "Transcription failed: \(error.localizedDescription)",
        status: .failed
      )
      session.segments.append(failedSegment)
      print("ERROR: Processing failed for session \(session.id): \(error.localizedDescription)")
    }
    
    // Finalize the process
    session.isProcessing = false
    
    // Save the updated session and new segment to SwiftData
    do {
      try modelContext.save()
      print("ProcessingCoordinator: SwiftData context saved successfully.")
    } catch {
      print("ERROR: Failed to save context after processing: \(error.localizedDescription)")
    }
  }
}
