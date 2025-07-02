//
//  SwiftRecorderApp.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/2/25.
//

import SwiftUI
import SwiftData

@main
struct SwiftRecorderApp: App {
  
  
  // Define the persistent ModelContainer (SHARED INSTANCE)
 var sharedModelContainer: ModelContainer
  
  // Create the AppManager container instance as State
  @State private var appManager: AppManager
  
  @MainActor  // ADD this attribute
  init() {
    print("SwiftRecrorder init() called...")
    let schema = Schema([
      RecordingSession.self, TranscriptionSegment.self,

    ])

    do {
      #if !targetEnvironment(simulator)
        // Configure for persistent storage (on-disk)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
      #else
        // Use the PreviewContainer in the simulator, in memory only
        sharedModelContainer = PreviewContainer.shared
      #endif
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }

    _appManager = State(initialValue: AppManager(modelContainer: sharedModelContainer))
    print("SwiftRecrorder init finished.")
  }

    var body: some Scene {
        WindowGroup {
            ContentView()
            .environment(appManager)
            .modelContainer(sharedModelContainer)
        }
    }
}
