//
//  PlaybackButton.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/3/25.
//

import SwiftUI

struct PlaybackButton: View {
    let session: RecordingSession
    let isPlaying: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                Text(isPlaying ? "Stop" : "Play")
            }
        }
        .foregroundColor(.accentColor)
    }
}

#Preview {
    let container = PreviewContainer.shared
    let appManager = AppManager(modelContainer: container)
    let sampleSession = PreviewContainer.sampleSession()
    
    return NavigationStack {
        VStack(spacing: 20) {
            PlaybackButton(
                session: sampleSession,
                isPlaying: false,
                action: { print("Play button tapped") }
            )
            
            PlaybackButton(
                session: sampleSession,
                isPlaying: true,
                action: { print("Stop button tapped") }
            )
        }
        .padding()
        .environment(appManager)
        .modelContainer(container)
    }
}