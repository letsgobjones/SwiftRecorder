//
//  AudioSessionManager.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/5/25.
//

import SwiftUI
import AVFoundation

@Observable
class AudioSessionManager {
    
    // MARK: - Observable Properties
    var isInterrupted: Bool = false
    var shouldResumeAfterInterruption: Bool = false
    var currentRoute: AudioRoute = .builtInMicrophone
    var isHeadphonesConnected: Bool = false
    var isBluetoothConnected: Bool = false
    var sessionError: String?
    
    // MARK: - Private Properties
  // These tokens are used to manage NotificationCenter observers.
    private var interruptionObserver: NSObjectProtocol?
    private var routeChangeObserver: NSObjectProtocol?
  
    private let audioSession = AVAudioSession.sharedInstance()
    
    // MARK: - Callbacks
  var onInterruptionBegan: (() -> Void)?             // Called when an audio interruption starts.
      var onInterruptionEnded: ((Bool) -> Void)?         // Called when an audio interruption ends. The Bool indicates if system recommends resume.
      var onRouteChanged: ((AudioRoute) -> Void)?       // Called when the audio route changes, providing the new input route.
    
    // MARK: - Initialization
  /// Initializes the AudioSessionManager and sets up observers for audio session events.
      init() {
          print("AudioSessionManager: Initializing")
          setupAudioSessionObservers() // Register for system audio notifications.
          updateCurrentRoute()         // Immediately determine the initial audio route.
      }
    
  /// Cleans up observers when the manager is deallocated to prevent memory leaks.
    deinit {
        print("AudioSessionManager: Deinitializing")
        removeObservers() // Remove notification observers.
    }
    
    // MARK: - Public Interface
    
    /// Configures audio session for recording
    func configureForRecording() throws {
        print("AudioSessionManager: Configuring session for recording")
        
        try audioSession.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
        )
        
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Update route information after activation
        updateCurrentRoute()
        
        sessionError = nil
        print("AudioSessionManager: Session configured successfully")
    }
    
  /// Deactivates the audio session, releasing control of audio resources back to the system.
      func deactivateSession() {
        print("AudioSessionManager: Deactivating session")
        
        do {
          // Deactivate the session.
          try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            sessionError = nil
            print("AudioSessionManager: Session deactivated successfully")
        } catch {
            let errorMessage = "Failed to deactivate session: \(error.localizedDescription)"
            sessionError = errorMessage
            print("AudioSessionManager: \(errorMessage)")
        }
    }
    
    /// Forces session reactivation (useful after interruptions)
    func reactivateSession() throws {
        print("AudioSessionManager: Reactivating session")
        
        try audioSession.setActive(false) // Deactivate first
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        updateCurrentRoute()
        sessionError = nil
        
        print("AudioSessionManager: Session reactivated successfully")
    }
    
    /// Checks if current route is suitable for recording
    var hasViableInputRoute: Bool {
      let inputs = audioSession.currentRoute.inputs // Get all currently active audio input ports.
              let hasInput = !inputs.isEmpty // Check if the array of input ports is not empty.
      
        if hasInput {
            let inputTypes = inputs.compactMap { $0.portType }
            print("AudioSessionManager: Available inputs: \(inputTypes.map { $0.rawValue })")
        } else {
            print("AudioSessionManager: No audio inputs available")
        }
        
        return hasInput // Returns true if any input device is currently active.
    }
    
  // MARK: - Private Methods (Notification Handling & Internal Logic)
  
  /// Sets up NotificationCenter observers for audio session interruptions and route changes.
    private func setupAudioSessionObservers() {
        print("AudioSessionManager: Setting up observers")
        
      // Interruption Observer: listens for changes in audio session interruption status.
      interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: audioSession,
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }
        
      // Route Change Observer: listens for changes in audio input/output routes.
      routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: audioSession,
            queue: .main
        ) { [weak self] notification in
            self?.handleRouteChange(notification)
        }
        
        print("AudioSessionManager: Observers set up successfully")
    }
    
  /// Removes all previously registered NotificationCenter observers.
      /// Crucial to call in `deinit` to prevent memory leaks and unexpected behavior.
    private func removeObservers() {
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
            interruptionObserver = nil
        }
        
        if let observer = routeChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            routeChangeObserver = nil
        }
        
        print("AudioSessionManager: Observers removed")
    }
    
  /// Handles the raw AVAudioSession.interruptionNotification.
  private func handleInterruption(_ notification: Notification) {
    // Extract interruption type from the notification's userInfo.
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            print("AudioSessionManager: Invalid interruption notification")
            return
        }
        
        print("AudioSessionManager: Interruption \(type == .began ? "began" : "ended")")
        
        switch type {
        case .began:
            handleInterruptionBegan()
        case .ended:
            handleInterruptionEnded(userInfo)
        @unknown default:
            print("AudioSessionManager: Unknown interruption type")
        }
    }
    
  /// Logic for when an audio session interruption begins.
    private func handleInterruptionBegan() {
        print("AudioSessionManager: Processing interruption began")
        
        isInterrupted = true
        shouldResumeAfterInterruption = true
        sessionError = "Audio interrupted"
        
        // Notify callback
        onInterruptionBegan?()
    }
    
  /// Logic for when an audio session interruption ends.
    private func handleInterruptionEnded(_ userInfo: [AnyHashable: Any]) {
        print("AudioSessionManager: Processing interruption ended")
        
        isInterrupted = false
        
        // Check if system recommends resuming
        let shouldResume: Bool
        if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            shouldResume = options.contains(.shouldResume) && shouldResumeAfterInterruption
        } else {
            shouldResume = false
        }
        
        if shouldResume {
            print("AudioSessionManager: System recommends resuming")
            sessionError = nil
        } else {
            print("AudioSessionManager: Not resuming")
            sessionError = "Interruption prevented resume"
        }
        
        shouldResumeAfterInterruption = false
        
        // Notify callback
        onInterruptionEnded?(shouldResume)
    }
    
  /// Handles the raw AVAudioSession.routeChangeNotification.
    private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            print("AudioSessionManager: Invalid route change notification")
            return
        }
        
        print("AudioSessionManager: Route changed - \(routeChangeDescription(reason))")
        
        updateCurrentRoute()
        
        // Handle specific route change scenarios
        switch reason {
        case .newDeviceAvailable:
            sessionError = nil // Clear errors when new device becomes available
        case .oldDeviceUnavailable:
            if !hasViableInputRoute {
                sessionError = "Audio input device disconnected"
            }
        default:
            break
        }
        
        // Notify callback
        onRouteChanged?(currentRoute)
    }
    
  /// Updates the observable route properties based on the current AVAudioSession route.
    private func updateCurrentRoute() {
        let route = audioSession.currentRoute
        
        // Determine primary input route
        if let input = route.inputs.first {
            currentRoute = AudioRoute.from(portType: input.portType)
        } else {
            currentRoute = .none
        }
        
        // Update connection status
        isHeadphonesConnected = route.outputs.contains { output in
            output.portType == .headphones || output.portType == .bluetoothHFP
        }
        
        isBluetoothConnected = route.inputs.contains { input in
            input.portType == .bluetoothHFP
        } || route.outputs.contains { output in
            output.portType == .bluetoothA2DP || output.portType == .bluetoothHFP
        }
        
        print("AudioSessionManager: Route updated - Input: \(currentRoute.displayName), Headphones: \(isHeadphonesConnected), Bluetooth: \(isBluetoothConnected)")
    }
    
  /// Helper to convert AVAudioSession.RouteChangeReason enum to a human-readable string for logging.
    private func routeChangeDescription(_ reason: AVAudioSession.RouteChangeReason) -> String {
        switch reason {
        case .unknown: return "Unknown"
        case .newDeviceAvailable: return "New Device Available"
        case .oldDeviceUnavailable: return "Old Device Unavailable"
        case .categoryChange: return "Category Change"
        case .override: return "Override"
        case .wakeFromSleep: return "Wake From Sleep"
        case .noSuitableRouteForCategory: return "No Suitable Route"
        case .routeConfigurationChange: return "Route Configuration Change"
        @unknown default: return "Unknown (\(reason.rawValue))"
        }
    }
}

