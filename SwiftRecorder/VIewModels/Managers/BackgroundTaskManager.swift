//
//  BackgroundTaskManager.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import UIKit
import SwiftUI

@Observable
class BackgroundTaskManager {
    
    // MARK: - Properties
    var isInBackground: Bool = false
    var backgroundTimeRemaining: TimeInterval = 0
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    
    // Tasks for modern concurrency
    private var notificationListenerTask: Task<Void, Never>?
    private var timeRemainingMonitorTask: Task<Void, Never>?
    
    // MARK: - Callbacks
    var onBackgroundTimeExpiring: (() -> Void)?
    var onAppDidEnterBackground: (() -> Void)?
    var onAppWillEnterForeground: (() -> Void)?
    
    // MARK: - Initialization
    init() {
        setupNotificationListeners()
        print("BackgroundTaskManager: Initialized with modern async listeners")
    }
    
    deinit {
        endBackgroundTask()
        notificationListenerTask?.cancel()
        print("BackgroundTaskManager: Deinitialized and tasks cancelled")
    }
    
    // MARK: - Public Interface
    
    /// Begins a background task to allow recording to continue when the app goes to the background.
    func beginBackgroundTask(name: String = "Audio Recording") {
        print("BackgroundTaskManager: Beginning background task: \(name)")
        
        // End any existing background task first.
        endBackgroundTask()
        
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in
            print("BackgroundTaskManager: Background task is about to expire.")
            self?.onBackgroundTimeExpiring?()
            self?.endBackgroundTask()
        }
        
        if backgroundTaskIdentifier == .invalid {
            print("BackgroundTaskManager: Failed to begin background task.")
        } else {
            print("BackgroundTaskManager: Background task began successfully with ID: \(backgroundTaskIdentifier.rawValue)")
            startBackgroundTimeMonitor()
        }
    }
    
    /// Ends the current background task.
    func endBackgroundTask() {
        guard backgroundTaskIdentifier != .invalid else { return }
        
        print("BackgroundTaskManager: Ending background task ID: \(backgroundTaskIdentifier.rawValue)")
        
        UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
        backgroundTaskIdentifier = .invalid
        stopBackgroundTimeMonitor()
    }
    
    /// A computed property to check if a background task is currently active.
    var hasActiveBackgroundTask: Bool {
        return backgroundTaskIdentifier != .invalid
    }
    
    // MARK: - Modern Notification & Timer Handling
    
    /// Sets up listeners for app lifecycle notifications using async streams.
    private func setupNotificationListeners() {
        notificationListenerTask = Task {
            // Listen for app entering background
            for await _ in NotificationCenter.default.notifications(named: UIApplication.didEnterBackgroundNotification) {
                await MainActor.run {
                    print("BackgroundTaskManager: App entered background.")
                    self.isInBackground = true
                    self.onAppDidEnterBackground?()
                }
            }
            
            // Listen for app entering foreground
            for await _ in NotificationCenter.default.notifications(named: UIApplication.willEnterForegroundNotification) {
                await MainActor.run {
                    print("BackgroundTaskManager: App will enter foreground.")
                    self.isInBackground = false
                    self.onAppWillEnterForeground?()
                }
            }
        }
    }
    
    /// Starts a task to periodically update the remaining background time.
    private func startBackgroundTimeMonitor() {
        // Cancel any existing monitor task.
        stopBackgroundTimeMonitor()
        
        timeRemainingMonitorTask = Task {
            while !Task.isCancelled && hasActiveBackgroundTask {
                await MainActor.run {
                    self.backgroundTimeRemaining = UIApplication.shared.backgroundTimeRemaining
                }
                
                // Warn when getting close to expiration (e.g., 30 seconds left)
                if self.backgroundTimeRemaining <= 30 && self.backgroundTimeRemaining > 29 {
                    print("BackgroundTaskManager: Warning - Background time running low: \(self.backgroundTimeRemaining)s")
                }
                
                // Sleep for 1 second before the next update.
                try? await Task.sleep(for: .seconds(1))
            }
        }
        print("BackgroundTaskManager: Background time monitor started.")
    }
    
    /// Stops the background time monitoring task.
    private func stopBackgroundTimeMonitor() {
        timeRemainingMonitorTask?.cancel()
        timeRemainingMonitorTask = nil
        backgroundTimeRemaining = 0
        print("BackgroundTaskManager: Background time monitor stopped.")
    }
}
