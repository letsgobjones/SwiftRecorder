//
//  PreviewContainer.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/2/25.
//


import SwiftData
import SwiftUI

@MainActor
struct PreviewContainer {
  static var shared: ModelContainer = {
    let schema = Schema([
      RecordingSession.self, TranscriptionSegment.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    do {
      print("Creating Preview ModelContainer...")
      let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
      print("Preview ModelContainer created successfully.")

      // ADD: Call insertSampleData directly and synchronously
      print("PreviewContainer: Inserting sample data synchronously...")
//      PreviewContainer.insertSampleData(context: container.mainContext)
      print("PreviewContainer: Synchronous sample data insertion complete.")

      return container
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()  // Immediately execute the closure
}
