//
//  PlaybackService.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/3/25.
//

import SwiftUI
import AVFoundation
import SwiftData


@Observable
class PlaybackService {
  var isPlaying = false
  var errorMessage: String?
  
  private var engine: AVAudioEngine? // The central audio processing graph
  private var playerNode: AVAudioPlayerNode? // A specific node within the engine used for playing audio files
  private var audioFile: AVAudioFile? // Represents the audio file loaded from disk for playback
  
  private var  modelContext: ModelContext
  
  init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }
  
  /// Starts playback of an audio file located at the given URL.
  func play(url: URL) {
    if isPlaying { stop() }
    
    engine = AVAudioEngine()
    playerNode = AVAudioPlayerNode()
    
    let audioSession = AVAudioSession.sharedInstance()
    do {
      // Configure session for playback
      try audioSession.setCategory(.playback, mode: .default)
      // Activate the audio session: tells iOS the app is ready to play audio.
      try audioSession.setActive(true)
    } catch {
      errorMessage = "Failed to set up audio session for playback: \(error.localizedDescription)"
      return
    }
    // Ensure Engine and PlayerNode are initialized
    guard let engine = engine, let playerNode = playerNode else { return }
    
    
    do {
      // Load the audio file from the provided URL
      audioFile = try AVAudioFile(forReading: url)
      
      // Attach and connect nodes
      engine.attach(playerNode)
      
      // Connect the playerNode to the engine's mainMixerNode.
      guard let audioFile = audioFile else { return }
      engine.connect(playerNode, to: engine.mainMixerNode, format: audioFile.processingFormat)
      engine.connect(engine.mainMixerNode, to: engine.outputNode, format: nil)
      playerNode.scheduleFile(audioFile, at: nil) { [weak self] in
        Task {
          try self?.engine?.start()
          self?.isPlaying = true
        }
      }
      
      // Prepare and start the engine
      engine.prepare()
      try engine.start()
      
      playerNode.play()
      isPlaying = true
    } catch {
      errorMessage = "Playback failed: \(error.localizedDescription)"
      isPlaying = false
    }
  }
  
  
  func stop() {
    playerNode?.stop()
    engine?.stop()
    isPlaying = false
    
    // Release resources by setting the optionals to nil
    // This will deallocate the engine, playerNode, and audioFile.
    engine = nil
    playerNode = nil
    audioFile = nil
    
    do {
      try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    } catch {
      print("Failed to deactivate audio session after playback stop: \(error.localizedDescription)")
    }
    
    errorMessage = nil
  }
  
  /// Toggles playback for a specific recording session
  /// Constructs the full URL from the session's audioFilePath and toggles playback
  func togglePlayback(for session: RecordingSession) {
    print("PlaybackService: Toggling playback for session: \(session.id)")
    
    if isPlaying {
      print("PlaybackService: Stopping current playback")
      stop()
    } else {
      // Construct the full URL to the audio file
      let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      let audioFileURL = documentsPath.appendingPathComponent(session.audioFilePath)
      
      print("PlaybackService: Starting playback from URL: \(audioFileURL)")
      play(url: audioFileURL)
    }
  }
}
