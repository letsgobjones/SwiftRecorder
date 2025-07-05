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
            .foregroundColor(.gray)
        } else {
          ForEach(session.sortedSegments, id: \.id) { segment in
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Text("Segment \(session.sortedSegments.firstIndex(where: { $0.id == segment.id }) ?? 0)")
                  .font(.headline)
                  .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(String(format: "%.1f", segment.startTime))s")
                  .font(.caption)
                  .foregroundColor(.secondary)
                
                // Status indicator
                Group {
                  switch segment.status {
                  case .completed:
                    Image(systemName: "checkmark.circle.fill")
                      .foregroundColor(.green)
                  case .processing:
                    ProgressView()
                      .scaleEffect(0.8)
                  case .failed:
                    Image(systemName: "xmark.circle.fill")
                      .foregroundColor(.red)
                  case .queued:
                    Image(systemName: "clock.fill")
                      .foregroundColor(.orange)
                  default:
                    Image(systemName: "circle")
                      .foregroundColor(.gray)
                  }
                }
              }
              
              // Transcription text
              switch segment.status {
              case .completed:
                Text(segment.transcriptionText.isEmpty ? "No transcription available" : segment.transcriptionText)
                  .font(.body)
                  .padding(.top, 4)
              case .processing:
                HStack {
                  ProgressView()
                    .scaleEffect(0.8)
                  Text("Transcribing...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
              case .failed:
                Text(segment.transcriptionText)
                  .font(.caption)
                  .foregroundColor(.red)
              case .queued:
                Text("Queued for transcription")
                  .font(.caption)
                  .foregroundColor(.orange)
              default:
                Text("Pending transcription")
                  .font(.caption)
                  .foregroundColor(.gray)
              }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
          }
          
          // Overall progress indicator
          if session.isProcessing {
            let completedCount = session.segments.filter { $0.status == .completed }.count
            let totalCount = session.segments.count
            
            VStack(alignment: .leading, spacing: 4) {
              Text("Processing Progress")
                .font(.headline)
              
              ProgressView(value: Double(completedCount), total: Double(totalCount))
                .progressViewStyle(LinearProgressViewStyle())
              
              Text("\(completedCount)/\(totalCount) segments completed")
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.top, 8)
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