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
    guard hasMicrophoneAccess else {
      errorMessage = "Cannot start recording without microphone access."
      return nil
    }
    
    engine = AVAudioEngine()
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      errorMessage = "Failed to set up audio session: \(error)"
      return nil
    }
    
    let inputNode = engine!.inputNode
    let inputFormat = inputNode.inputFormat(forBus: 0)
    
    
    let timestamp = String(format: "%.0f", Date().timeIntervalSince1970) // Get integer seconds since 1970
    let uuid = UUID().uuidString
    let fileName = "rec_\(timestamp)_\(uuid).m4a"
    
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let audioFileURL = documentsPath.appendingPathComponent(fileName)
    
    do {
      audioFile = try AVAudioFile(forWriting: audioFileURL, settings: inputFormat.settings)
    } catch {
      errorMessage = "Could not create audio file: \(error.localizedDescription)"
      return nil
  }
  
  inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] (buffer, when) in
    do {
      try self?.audioFile?.write(from: buffer)
    } catch {
      print("Error writing buffer to file: \(error)")
      
    }
  }
  
  do {
    try engine?.prepare()
    try engine?.start()
    isRecording = true
    recordingStartTime = Date()
    
    let newSession = RecordingSession(audioFilePath: fileName)
    return newSession
  } catch {
    errorMessage = "Could not start engine: \(error.localizedDescription)"
    isRecording = false
    return nil
  }
}
  
  
  
  
}
