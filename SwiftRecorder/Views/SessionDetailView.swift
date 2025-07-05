//
//  SessionDetailView.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/2/25.
//

import SwiftUI

struct SessionDetailView: View {
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
        
        
  
        
        if session.isProcessing {
          HStack {
            Text("Processing...")
            ProgressView()
          }
        }
        
        if let errorMessage = appManager.playbackService.errorMessage {
          Text(errorMessage)
            .foregroundColor(.red)
        }
      }
      
      Section("Transcription Segments") {
        if session.sortedSegments.isEmpty && !session.isProcessing {
          Text("No transcription segments available.")
        } else {
          ForEach(session.sortedSegments, id: \.startTime) { segment in
            VStack(alignment: .leading, spacing: 5) {
              Text("Segment @ \(String(format: "%.1f", segment.startTime))s")
                .font(.headline)
              
              switch segment.status {
              case .completed:
                Text(segment.transcriptionText)
              case .processing:
                ProgressView()
              case .failed:
                Text("Transcription failed.")
                  .foregroundColor(.red)
              default:
                Text("Pending..")
                  .foregroundColor(.gray)
              }
            }
            .padding(.vertical, 5)
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
    SessionDetailView(session: sampleSession)
      .environment(appManager)
      .modelContainer(container)
  }
}
