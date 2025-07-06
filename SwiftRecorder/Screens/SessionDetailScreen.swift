//
//  SessionDetailView.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/2/25.
//

import SwiftUI

struct SessionDetailScreen: View {
    @Bindable var session: RecordingSession
    @Environment(AppManager.self) private var appManager: AppManager
    
    var body: some View {
        List {
            Section("Details") {
                Text("Recorded on \(session.createdAt.formatted())")
                Text("Duration: \(String(format: "%.1f", session.duration))s")
                
                // Playback Button
                PlaybackButton(session: session, isPlaying: appManager.playbackService.isPlaying) {
                    appManager.togglePlayback(for: session)
                }
                
                // Use LoadingStateView for processing state
                if session.isProcessing {
                    LoadingStateView(state: .loading, message: "Processing audio segments...")
                }
                
                // Use LoadingStateView for playback errors
                if let errorMessage = appManager.playbackService.errorMessage {
                    LoadingStateView(state: .error, message: errorMessage)
                }
            }
            
            Section("Transcription Segments") {
                if session.sortedSegments.isEmpty && !session.isProcessing {
                    Text("No transcription segments available.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(session.sortedSegments, id: \.id) { segment in
                        SegmentRowView(segment: segment, segmentIndex: session.sortedSegments.firstIndex(where: { $0.id == segment.id }) ?? 0)
                    }
                    
                    // Overall progress indicator using LoadingStateView
                    if session.isProcessing {
                        ProcessingProgressView(session: session)
                    }
                }
            }
        }
        .navigationTitle("Recording Details")
        .onDisappear {
            appManager.playbackService.stop()
        }
    }
}




#Preview {
    let container = PreviewContainer.shared
    let appManager = AppManager(modelContainer: container)
    
    // Create a sample session with proper parameters
    let sampleSession = PreviewContainer.sampleSession()
    
    return NavigationStack {
        SessionDetailScreen(session: sampleSession)
            .environment(appManager)
            .modelContainer(container)
    }
}
