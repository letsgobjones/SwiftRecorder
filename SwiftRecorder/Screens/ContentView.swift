//
//  ContentView.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/2/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
  @Environment(AppManager.self) private var appManager: AppManager
  @Query(sort: \RecordingSession.createdAt, order: .reverse)
  private var sessions: [RecordingSession]
  
  var body: some View {
    VStack {
      if sessions.isEmpty {
        ContentUnavailableView("No Recordings Yet", systemImage: "mic.fill")
          .padding()
      } else {
        List {
          ForEach(sessions) { session in
            NavigationLink {
              SessionDetailScreen(session: session)
                .environment(appManager)
            } label: {
              VStack(alignment: .leading) {
                Text(session.createdAt.formatted(.dateTime.day().month().year().hour().minute()))
                  .font(.headline)
                
                Text("Duration: \(String(format: "%.1f", session.duration))s")
                  .font(.caption)
                  .foregroundColor(.gray)
                
                if session.isProcessing {
                  ProgressView("Processing...").padding(.top, 2)
                    .font(.caption2)
                }
              }
              .accessibilityElement(children: .combine)
              .accessibilityLabel("Recording from \(session.createdAt, style: .date), lasting \(String(format: "%.1f", session.duration)) seconds.")
            }
          }
          .onDelete { offsets in
            appManager.deleteSession(at: offsets, sessions: sessions)
          }
        }
      }
      
      Spacer()
      
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
    .navigationTitle("Recordings")
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        NavigationLink {
          SettingsScreen()
            .environment(appManager)
        } label: {
          Image(systemName: "gear")
            .accessibilityLabel("Settings")
        }
      }
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
  return NavigationStack {
    ContentView()
      .environment(appManager)
      .modelContainer(container)
  }
}