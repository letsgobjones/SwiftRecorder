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
    private var interruptionObserver: NSObjectProtocol?
    private var routeChangeObserver: NSObjectProtocol?
    private let audioSession = AVAudioSession.sharedInstance()
    
    // MARK: - Callbacks
    var onInterruptionBegan: (() -> Void)?
    var onInterruptionEnded: ((Bool) -> Void)? // Bool indicates if should resume
    var onRouteChanged: ((AudioRoute) -> Void)?
    
    // MARK: - Initialization
    init() {
        print("AudioSessionManager: Initializing")
        setupAudioSessionObservers()
        updateCurrentRoute()
    }
    
    deinit {
        print("AudioSessionManager: Deinitializing")
        removeObservers()
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
    
    /// Deactivates audio session
    func deactivateSession() {
        print("AudioSessionManager: Deactivating session")
        
        do {
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
        let inputs = audioSession.currentRoute.inputs
        let hasInput = !inputs.isEmpty
        
        if hasInput {
            let inputTypes = inputs.compactMap { $0.portType }
            print("AudioSessionManager: Available inputs: \(inputTypes.map { $0.rawValue })")
        } else {
            print("AudioSessionManager: No audio inputs available")
        }
        
        return hasInput
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSessionObservers() {
        print("AudioSessionManager: Setting up observers")
        
        // Interruption Observer
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: audioSession,
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }
        
        // Route Change Observer
        routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: audioSession,
            queue: .main
        ) { [weak self] notification in
            self?.handleRouteChange(notification)
        }
        
        print("AudioSessionManager: Observers set up successfully")
    }
    
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
    
    private func handleInterruption(_ notification: Notification) {
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
    
    private func handleInterruptionBegan() {
        print("AudioSessionManager: Processing interruption began")
        
        isInterrupted = true
        shouldResumeAfterInterruption = true
        sessionError = "Audio interrupted"
        
        // Notify callback
        onInterruptionBegan?()
    }
    
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

