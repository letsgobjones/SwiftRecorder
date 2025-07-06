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
        EmptySessionsView()
      } else {
        List {
          ForEach(sessions) { session in
            NavigationLink {
              SessionDetailScreen(session: session)
                .environment(appManager)
            } label: {
              SessionRowView(session: session)
            }
          }
          .onDelete { offsets in
            appManager.deleteSession(at: offsets, sessions: sessions)
          }
        }.listStyle(PlainListStyle())
      }
      
      Spacer()
      
      RecordingControlsView(appManager: appManager)
      
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
