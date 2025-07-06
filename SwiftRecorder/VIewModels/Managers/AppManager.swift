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
  
  // MARK: - Core Services
  let audioSessionManager: AudioSessionManager
  let backgroundTaskManager: BackgroundTaskManager
  let storageManager: StorageManager
  let performanceManager: PerformanceManager
  let audioService: AudioService
  let recordingManager: RecordingManager
  let playbackService: PlaybackService
  let processingCoordinator: ProcessingCoordinator
  let transcriptionService: TranscriptionService
  let settingsViewModel: SettingsViewModel
  
  // MARK: - Data Management
  private var modelContainer: ModelContainer
  var modelContext: ModelContext
  
  
  init(modelContainer: ModelContainer) {
    print("AppManager: Starting initialization")
    
    self.modelContainer = modelContainer
    
    let context = modelContainer.mainContext
    self.modelContext = context
    
    // Initialize managers first
    self.audioSessionManager = AudioSessionManager()
    self.backgroundTaskManager = BackgroundTaskManager()
    self.storageManager = StorageManager()
    self.performanceManager = PerformanceManager()
    
    // Initialize core services with dependencies
    self.audioService = AudioService(
      modelContext: context, 
      audioSessionManager: self.audioSessionManager,
      backgroundTaskManager: self.backgroundTaskManager
    )
    self.transcriptionService = TranscriptionService()
    self.settingsViewModel = SettingsViewModel()
    
    // Initialize coordinator with transcription service and performance manager dependencies
    self.processingCoordinator = ProcessingCoordinator(
      transcriptionService: self.transcriptionService,
      performanceManager: self.performanceManager
    )
    
    // Initialize recording manager with all dependencies
    self.recordingManager = RecordingManager(
      modelContext: context,
      audioService: self.audioService,
      processingCoordinator: self.processingCoordinator
    )
    
    // Initialize playback service
    self.playbackService = PlaybackService(modelContext: context)
    
    print("AppManager: Initialization complete - all services ready")
    
  }
  
  
  // MARK: - Recording Actions
  func toggleRecording() {
    print("AppManager: Toggle recording requested")
    recordingManager.toggleRecording()
  }
  
  /// Deletes specific recording sessions based on offsets provided by a SwiftUI List.
  func deleteSession(at offsets: IndexSet, sessions: [RecordingSession]) {
    print("AppManager: Delete session requested for \(offsets.count) sessions")
    recordingManager.deleteSessions(at: offsets, in: sessions)
    
    // Recalculate storage after deletion
    Task {
      await storageManager.calculateStorageUsage()
    }
  }
  
  // MARK: - Storage Management Actions
  func cleanupOrphanedFiles() {
    Task {
      await storageManager.cleanupOrphanedFiles(modelContext: modelContext)
    }
  }
  
  func cleanupOldFiles(days: Int) {
    Task {
      await storageManager.cleanupOldFiles(olderThanDays: days, modelContext: modelContext)
    }
  }
  
  func freeUpStorage(targetMB: Double) {
    Task {
      await storageManager.freeUpStorage(targetMB: targetMB, modelContext: modelContext)
    }
  }
  
  // MARK: - Playback Actions
  /// Toggles playback for a specific recording session
  func togglePlayback(for session: RecordingSession) {
    print("AppManager: Toggling playback for session: \(session.id)")
    playbackService.togglePlayback(for: session)
  }
  
  // MARK: - Settings Actions
  /// Saves an API key through the settings view model
  func saveAPIKey(for keyType: APIKeyType) {
    print("AppManager: Save API key requested for: \(keyType.displayName)")
    settingsViewModel.saveAPIKey(for: keyType)
  }
  
  /// Removes an API key through the settings view model
  func removeAPIKey(for keyType: APIKeyType) {
    print("AppManager: Remove API key requested for: \(keyType.displayName)")
    settingsViewModel.removeAPIKey(for: keyType)
  }
}