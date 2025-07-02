//
//  AudioService.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/2/25.
//

import SwiftUI
import AVFoundation

@Observable
class AudioService: NSObject {
  var isRecording: Bool = false
  var hasMicrophoneAccess: Bool = false
  var errorMessage: String?
  
  
  private var engine: AVAudioEngine?
  private var audioFile: AVAudioFile?
  private var recordingStartTime: Date?
  
  override init() {
    super.init()
    checkMicrophonePermission()
  }
  
  
  private func checkMicrophonePermission() {
    print("🎤 Checking microphone permission...")
    
    switch AVAudioApplication.shared.recordPermission {
    case .granted:
      print(" Microphone access granted")
      Task { @MainActor [weak self] in
        self?.hasMicrophoneAccess = true
        self?.errorMessage = nil
      }
    case .denied:
      print("Microphone access denied")
      Task { @MainActor [weak self] in
        self?.hasMicrophoneAccess = false
        self?.errorMessage = "Microphone access was denied. Please grant access in Settings."
      }
      //  If permission has not been asked yet (undetermined state):
      // Request permission from the user. This will present the system's permission dialog.
    case .undetermined:
      print("Microphone access undetermined, requesting permission...")
      AVAudioApplication.requestRecordPermission { [weak self] granted in
        print("Permission request result: \(granted)")
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
      print("Unknown microphone permission state")
      Task { @MainActor [weak self] in
        self?.hasMicrophoneAccess = false
        self?.errorMessage = "Unable to determine microphone access status."
      }
    }
  }
  
  
  func startRecording() -> RecordingSession? {
    // Pre-check: Microphone Access
    guard hasMicrophoneAccess else {
      errorMessage = "Cannot start recording without microphone access."
      return nil
    }
    
    //  Audio Engine Setup
    engine = AVAudioEngine()
    
    // Audio Session Configuration (AVAudioSession)
    let audioSession = AVAudioSession.sharedInstance()
    do {
      // Set category for Play and Record: allows recording and playback
      // Mode .default: Standard audio behavior
      // Options:
      //   .defaultToSpeaker: Audio output goes to the main speaker by default
      //   .allowBluetooth: Allows audio routing to Bluetooth devices
      try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
      // Activate the audio session. notifyOthersOnDeactivation is crucial for handling interruptions gracefully.
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      errorMessage = "Failed to set up audio session: \(error)"
      return nil
    }
    
    // Input Node and Format
    
    guard let currentEngine = engine else { //  Guard let to unwrap engine
            errorMessage = "Audio engine was not initialized properly."
            return nil
        }
    
    
    
    let inputNode = currentEngine.inputNode     // Get the microphone input node from the engine
    let inputFormat = inputNode.inputFormat(forBus: 0)  // Get the default audio format for the input
    
    
    // Generate Unique Filename (Combined UUID & Timestamp)
    let timestamp = String(format: "%.0f", Date().timeIntervalSince1970) // Get integer seconds since 1970
    let uuid = UUID().uuidString
    let fileName = "rec_\(timestamp)_\(uuid).m4a"
    
    
    // Determine File URL (FileManager)
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let audioFileURL = documentsPath.appendingPathComponent(fileName)
    
    do {
      // Create an AVAudioFile instance for writing to the specified URL
      // Use the inputFormat.settings to define the audio quality (sample rate, bit depth, format)
      audioFile = try AVAudioFile(forWriting: audioFileURL, settings: inputFormat.settings)
    } catch {
      errorMessage = "Could not create audio file: \(error.localizedDescription)"
      return nil
    }
    // Install Tap on Input Node (Real-time Audio Processing)
    // This sets up a connection to capture audio buffers as they come from the microphone.
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] (buffer, when) in
      // This closure is called repeatedly with audio data
      do {
        // Write the incoming audio buffer directly to the audio file
        try self?.audioFile?.write(from: buffer)
      } catch {
        print("Error writing buffer to file: \(error)")
        
      }
    }
    
    // Start the Audio Engine
    do {
       currentEngine.prepare() // Prepares the engine to start (allocates resources)
      try currentEngine.start() // Starts the audio flow through the engine
      isRecording = true
      recordingStartTime = Date() // Record the start time for duration calculation/segmentation
      
      //  Create and Return New Recording Session
      let newSession = RecordingSession(audioFilePath: fileName) // Create a new data model object
      return newSession // Return the new session for persistence
    } catch {
      errorMessage = "Could not start engine: \(error.localizedDescription)"
      isRecording = false
      return nil
    }
  }
  
  
  func stopRecording() -> TimeInterval {
    guard let engine = engine else { return 0 }
    
    engine.stop()
    //Remove the Input Node Tap
    engine.inputNode.removeTap(onBus: 0)
    
    // Calculate Recording Duration
    let duration = recordingStartTime != nil ? Date().timeIntervalSince(recordingStartTime!) : 0
    
    audioFile = nil // Releases the strong reference to the AVAudioFile. This implicitly closes the file and flushes any pending data to disk.
    self.engine = nil // Releases the strong reference to the AVAudioEngine. This allows the engine and its associated nodes to be deallocated.
    recordingStartTime = nil
    isRecording = false
    
    
    do {
      try AVAudioSession.sharedInstance().setActive(false) // Deactivates the app's audio session.
    } catch {
      print("Failed to deactivate audio session: \(error.localizedDescription)")
      
    }
    return duration
  }
  
  
  
}
