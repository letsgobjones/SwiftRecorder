//
//  AppManager.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/2/25.
//

import SwiftData
import SwiftUI


@MainActor
@Observable
final class AppManager {
  
  let audioService: AudioService
  
  
  
  private var modelContainer: ModelContainer
  var modelContext: ModelContext
  
  
  
  init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
    
    let context = modelContainer.mainContext
    self.modelContext = context
    
    self.audioService = AudioService(modelContext: context)
    
    print("AppManager initialized")
    
  }
  
}
