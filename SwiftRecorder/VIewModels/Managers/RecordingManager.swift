//
//  RecordingManager.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/2/25.
//

import SwiftUI
import SwiftData
import AVFoundation


@Observable
class RecordingManager {
  private var  modelContext: ModelContext
  private var audioService: AudioService
  private let processingCoordinator: ProcessingCoordinator
  
  // Internal state
  var activeSession: RecordingSession?
  
  init(modelContext: ModelContext, audioService: AudioService, processingCoordinator: ProcessingCoordinator) {
    //TODO:  Add processor to init later
    
    self.modelContext = modelContext
    self.audioService = audioService
    self.processingCoordinator = processingCoordinator
  }
  
  func toggleRecording() {
    if audioService.isRecording {
      // Stop Recording
      let duration = audioService.stopRecording()
      
      // Create Recording Session
      if let session = activeSession {
        session.duration = duration
        session.isProcessing = true
        
        //Trigger the processing task
        Task {
          await processingCoordinator
            .process(session: session, modelContext: modelContext)
        }
      }
      activeSession = nil
    } else {
      // Start recording
      if let newSession = audioService.startRecording() {
        activeSession = newSession
        modelContext.insert(newSession)
        
        _saveContext(operation: "insert new session")
      }
      
      
    }
  }
  
  
  func deleteSessions(at offsets: IndexSet, in sessions: [RecordingSession]) {
    for index in offsets {
      let session = sessions[index]
      modelContext.delete(session)
      
      // Delete the associate audio file
      let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      let audioFileURL = documentPath.appendingPathComponent(session.audioFilePath)
      do {
        try FileManager.default.removeItem(at: audioFileURL)
      } catch {
        print("Error deleting audio file at \(audioFileURL.lastPathComponent): \(error.localizedDescription)")
      }
      // Delete from SwiftData
      modelContext.delete(session)
      _saveContext(operation: "delete single session")
      
    }
  }
  
  
  
  
  
  // MARK: - Private Helper Functions
  private func _saveContext(operation: String) {
    do {
      try modelContext.save()
      print("SwiftData context saved successfully after \(operation).")
    } catch {
      print("ERROR: Failed to save SwiftData context after \(operation): \(error.localizedDescription)")
    }
  }
}
