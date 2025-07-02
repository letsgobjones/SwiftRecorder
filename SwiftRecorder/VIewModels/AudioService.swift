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
  
  
  
  
  
}
