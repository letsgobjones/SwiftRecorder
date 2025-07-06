//
//  RecordingControlsView.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI

struct RecordingControlsView: View {
    let appManager: AppManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Audio Route Indicator
            AudioRouteIndicator(currentRoute: appManager.audioSessionManager.currentRoute)
            
            // Recording Button
            RecordingButton(
                isRecording: appManager.audioService.isRecording,
                isInterrupted: appManager.audioSessionManager.isInterrupted,
                hasMicrophoneAccess: appManager.audioService.hasMicrophoneAccess,
                action: appManager.toggleRecording
            )
            
            // Status Messages with Background Time
            StatusMessageView(
                message: statusMessage,
                isInterrupted: appManager.audioSessionManager.isInterrupted,
                backgroundTimeRemaining: appManager.backgroundTaskManager.backgroundTimeRemaining,
                isInBackground: appManager.backgroundTaskManager.isInBackground
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusMessage: String? {
        // Prioritize background status when in background
        if appManager.backgroundTaskManager.isInBackground && appManager.audioService.isRecording {
            return "Recording in background"
        }
        
        if let sessionError = appManager.audioSessionManager.sessionError {
            return sessionError
        }
        return appManager.audioService.errorMessage
    }
}

#Preview {
    let container = PreviewContainer.shared
    let appManager = AppManager(modelContainer: container)
    
    return RecordingControlsView(appManager: appManager)
        .padding()
}