//
//  AudioService.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/2/25.
//

import SwiftUI
import AVFoundation
import SwiftData


@Observable
class AudioService: NSObject {
  var isRecording: Bool = false
  var hasMicrophoneAccess: Bool = false
  var errorMessage: String?
  
  private var engine: AVAudioEngine?
  private var audioFile: AVAudioFile?
  private var recordingStartTime: Date?
  private var modelContext: ModelContext
  private let audioSessionManager: AudioSessionManager
  
  init(modelContext: ModelContext, audioSessionManager: AudioSessionManager) {
    self.modelContext = modelContext
    self.audioSessionManager = audioSessionManager
    super.init()
    
    checkMicrophonePermission()
    setupAudioSessionCallbacks()
  }
  
  // MARK: - Audio Session Integration
  
  private func setupAudioSessionCallbacks() {
    print("AudioService: Setting up audio session callbacks")
    
    // Handle interruption began
    audioSessionManager.onInterruptionBegan = { [weak self] in
      print("AudioService: Received interruption began callback")
      self?.handleInterruptionBegan()
    }
    
    // Handle interruption ended
    audioSessionManager.onInterruptionEnded = { [weak self] shouldResume in
      print("AudioService: Received interruption ended callback, shouldResume: \(shouldResume)")
      self?.handleInterruptionEnded(shouldResume: shouldResume)
    }
    
    // Handle route changes
    audioSessionManager.onRouteChanged = { [weak self] route in
      print("AudioService: Audio route changed to: \(route.displayName)")
      self?.handleRouteChanged(to: route)
    }
  }
  
  private func handleInterruptionBegan() {
    guard isRecording else { return }
    
    print("AudioService: Pausing recording due to interruption")
    pauseRecording()
    errorMessage = "Recording paused due to interruption"
  }
  
  private func handleInterruptionEnded(shouldResume: Bool) {
    guard audioSessionManager.isInterrupted == false else { return }
    
    if shouldResume && engine != nil {
      print("AudioService: Attempting to resume recording after interruption")
      resumeRecording()
    } else {
      print("AudioService: Not resuming recording")
      errorMessage = "Recording was interrupted and couldn't be resumed"
    }
  }
  
  private func handleRouteChanged(to route: AudioRoute) {
    guard isRecording else { return }
    
    // Check if we still have a viable input
    if audioSessionManager.hasViableInputRoute {
      print("AudioService: Route changed but input still available, continuing recording")
      errorMessage = nil
    } else {
      print("AudioService: No viable input after route change, pausing recording")
      pauseRecording()
      errorMessage = "Recording paused - no audio input available"
    }
  }
  
  // MARK: - Recording Control
  
  private func pauseRecording() {
    print("AudioService: Pausing recording")
    
    guard let engine = engine, isRecording else {
      print("AudioService: Cannot pause - no engine or not recording")
      return
    }
    
    engine.pause()
    isRecording = false
    
    print("AudioService: Recording paused successfully")
  }
  
  private func resumeRecording() {
    print("AudioService: Attempting to resume recording")
    
    guard let engine = engine, !isRecording else {
      print("AudioService: Cannot resume - no engine or already recording")
      return
    }
    
    do {
      // Reactivate session if needed
      try audioSessionManager.reactivateSession()
      
      // Restart the engine
      try engine.start()
      isRecording = true
      errorMessage = nil
      
      print("AudioService: Recording resumed successfully")
      
    } catch {
      print("AudioService: Failed to resume recording: \(error.localizedDescription)")
      errorMessage = "Failed to resume recording: \(error.localizedDescription)"
    }
  }
  
  // MARK: - Public Interface
  
  var wasInterrupted: Bool {
    return audioSessionManager.isInterrupted
  }
  
  var shouldResumeAfterInterruption: Bool {
    return audioSessionManager.shouldResumeAfterInterruption
  }
  
  // MARK: - Core Recording Methods
  
  private func checkMicrophonePermission() {
    print("AudioService: Checking microphone permission...")
    
    switch AVAudioApplication.shared.recordPermission {
    case .granted:
      print("AudioService: Microphone access granted")
      Task { @MainActor [weak self] in
        self?.hasMicrophoneAccess = true
        self?.errorMessage = nil
      }
    case .denied:
      print("AudioService: Microphone access denied")
      Task { @MainActor [weak self] in
        self?.hasMicrophoneAccess = false
        self?.errorMessage = "Microphone access was denied. Please grant access in Settings."
      }
    case .undetermined:
      print("AudioService: Microphone access undetermined, requesting permission...")
      AVAudioApplication.requestRecordPermission { [weak self] granted in
        print("AudioService: Permission request result: \(granted)")
        Task { @MainActor in
          self?.hasMicrophoneAccess = granted
          if !granted {
            self?.errorMessage = "Microphone access was not granted."
          } else {
            self?.errorMessage = nil
          }
        }
      }
    @unknown default:
      print("AudioService: Unknown microphone permission state")
      Task { @MainActor [weak self] in
        self?.hasMicrophoneAccess = false
        self?.errorMessage = "Unable to determine microphone access status."
      }
    }
  }
  
  func startRecording() -> RecordingSession? {
    guard hasMicrophoneAccess else {
      errorMessage = "Cannot start recording without microphone access."
      return nil
    }
    
    print("AudioService: Starting recording session")
    
    // Configure audio session using AudioSessionManager
    do {
      try audioSessionManager.configureForRecording()
    } catch {
      errorMessage = "Failed to configure audio session: \(error.localizedDescription)"
      return nil
    }
    
    // Setup audio engine
    engine = AVAudioEngine()
    
    guard let currentEngine = engine else {
      errorMessage = "Audio engine was not initialized properly."
      return nil
    }
    
    let inputNode = currentEngine.inputNode
    let inputFormat = inputNode.inputFormat(forBus: 0)
    
    // Generate unique filename
    let timestamp = String(format: "%.0f", Date().timeIntervalSince1970)
    let uuid = UUID().uuidString
    let fileName = "rec_\(timestamp)_\(uuid).m4a"
    
    // Create audio file
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let audioFileURL = documentsPath.appendingPathComponent(fileName)
    
    do {
      audioFile = try AVAudioFile(forWriting: audioFileURL, settings: inputFormat.settings)
    } catch {
      errorMessage = "Could not create audio file: \(error.localizedDescription)"
      return nil
    }
    
    // Install audio tap
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] (buffer, when) in
      do {
        try self?.audioFile?.write(from: buffer)
      } catch {
        print("AudioService: Error writing buffer to file: \(error)")
      }
    }
    
    // Start engine
    do {
      currentEngine.prepare()
      try currentEngine.start()
      isRecording = true
      recordingStartTime = Date()
      errorMessage = nil
      
      let newSession = RecordingSession(audioFilePath: fileName)
      print("AudioService: Recording started successfully")
      return newSession
      
    } catch {
      errorMessage = "Could not start engine: \(error.localizedDescription)"
      isRecording = false
      return nil
    }
  }
  
  func stopRecording() -> TimeInterval {
    print("AudioService: Stopping recording session")
    
    guard let engine = engine else { return 0 }
    
    engine.stop()
    engine.inputNode.removeTap(onBus: 0)
    
    let duration = recordingStartTime != nil ? Date().timeIntervalSince(recordingStartTime!) : 0
    
    // Clean up
    audioFile = nil
    self.engine = nil
    recordingStartTime = nil
    isRecording = false
    
    // Deactivate audio session
    audioSessionManager.deactivateSession()
    
    print("AudioService: Recording stopped successfully, duration: \(duration)s")
    return duration
  }
}