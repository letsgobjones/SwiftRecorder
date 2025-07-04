//
//  AppManager.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/2/25.
//

import SwiftData
import SwiftUI


@MainActor
@Observable
final class AppManager {
  
  let audioService: AudioService
  let recordingManager: RecordingManager
  let playbackService: PlaybackService
  //  let processingCoordinator: ProcessingCoordinator
  
  private var modelContainer: ModelContainer
  var modelContext: ModelContext
  
  
  init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
    
    let context = modelContainer.mainContext
    self.modelContext = context
    
    self.audioService = AudioService(modelContext: context)
//    self.processingCoordinator = ProcessingCoordinator()
    self.recordingManager = RecordingManager(modelContext: context, audioService: self.audioService)
    self.playbackService = PlaybackService(modelContext: context)
    
    print("AppManager initialized")
    
  }
  
  
  func toggleRecording() {
    recordingManager.toggleRecording()
  }
  
  /// Deletes specific recording sessions based on offsets provided by a SwiftUI List.
  func deleteSession(at offsets: IndexSet, sessions: [RecordingSession]) {
    recordingManager.deleteSessions(at: offsets, in: sessions)
  }
  
  /// Toggles playback for a specific recording session
  func togglePlayback(for session: RecordingSession) {
    print("AppManager: Toggling playback for session: \(session.id)")
    playbackService.togglePlayback(for: session)
  }
  
}
