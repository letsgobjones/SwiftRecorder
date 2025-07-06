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
      
      // Recording Button: Toggles recording on/off.
      Button(action: appManager.toggleRecording) { // Calls the toggleRecording method on AppManager.
        Image(systemName: appManager.audioService.isRecording ? "stop.circle.fill" : "record.circle")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 70, height: 70)
          .foregroundColor(appManager.audioService.isRecording ? .red : .blue)
          .accessibilityLabel(appManager.audioService.isRecording ? "Stop Recording" : "Start Recording")
      }
      .padding(.bottom)
      
      // Display error messages from the audio service if any.
      if let errorMessage = appManager.audioService.errorMessage {
        Text(errorMessage)
          .foregroundColor(.red)
          .font(.footnote)
          .multilineTextAlignment(.center)
          .padding()
      }
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
