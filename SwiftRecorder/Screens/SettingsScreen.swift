//
//  SettingsScreen.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI

struct SettingsScreen: View {
  @Environment(AppManager.self) private var appManager: AppManager
  
  var body: some View {
    //        @Bindable var appManager = appManager
    
    Form {
      AppInfoSection()
      ProviderSelectionView()

      // Google API Key Section
      APIKeySectionView(
        keyType: .googleSpeechToText,
        apiKey: Binding(
          get: { appManager.settingsViewModel.apiKeyInputs[.googleSpeechToText, default: ""] },
          set: { appManager.settingsViewModel.apiKeyInputs[.googleSpeechToText] = $0 }
        ),
        isStored: Binding(
          get: { appManager.settingsViewModel.isGoogleAPIKeyStored },
          set: { appManager.settingsViewModel.isGoogleAPIKeyStored = $0 }
        ),
        onSave: { appManager.saveAPIKey(for: .googleSpeechToText) },
        onRemove: { appManager.removeAPIKey(for: .googleSpeechToText) }
      )
      
      // OpenAI API Key Section
      APIKeySectionView(
        keyType: .openAIWhisper,
        apiKey: Binding(
          get: { appManager.settingsViewModel.apiKeyInputs[.openAIWhisper, default: ""] },
          set: { appManager.settingsViewModel.apiKeyInputs[.openAIWhisper] = $0 }
        ),
        isStored: Binding(
          get: { appManager.settingsViewModel.isOpenAIAPIKeyStored },
          set: { appManager.settingsViewModel.isOpenAIAPIKeyStored = $0 }
        ),
        onSave: { appManager.saveAPIKey(for: .openAIWhisper) },
        onRemove: { appManager.removeAPIKey(for: .openAIWhisper) }
      )
      
      APIStatusSection(
        errorMessage: appManager.settingsViewModel.errorMessage,
        successMessage: appManager.settingsViewModel.successMessage
      )
    }
    .navigationTitle("Settings")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  let container = PreviewContainer.shared
  let appManager = AppManager(modelContainer: container)
  
  return NavigationStack {
    SettingsScreen()
      .environment(appManager)
      .modelContainer(container)
  }
}
