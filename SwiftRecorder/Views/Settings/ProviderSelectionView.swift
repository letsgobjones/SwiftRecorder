//
//  ProviderSelectionView.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI

struct ProviderSelectionView: View {
  
  @Environment(AppManager.self) private var appManager: AppManager
  
  var body: some View {
    Section {
      VStack(alignment: .leading, spacing: 12) {
        // Provider Picker - Now using simplified binding syntax
        Picker("Transcription Provider", selection: Binding(
          get: { appManager.settingsViewModel.selectedProvider },
          set: { appManager.settingsViewModel.selectedProvider = $0 }
        )) {
          ForEach(TranscriptionProvider.allCases, id: \.self) { provider in
            HStack {
              VStack(alignment: .leading, spacing: 2) {
                Text(provider.displayName)
                  .font(.body)
                
                Text(provider.isCloudBased ? "Cloud-based" : "On-device")
                  .font(.caption2)
                  .foregroundColor(.secondary)
              }
              
              Spacer()
              
              // Status indicator
              if provider.requiresAPIKey {
                let isConfigured = (provider == .googleSpeechToText && appManager.settingsViewModel.isGoogleAPIKeyStored) ||
                (provider == .openAIWhisper && appManager.settingsViewModel.isOpenAIAPIKeyStored)
                
                Image(systemName: isConfigured ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                  .foregroundColor(isConfigured ? .green : .orange)
                  .font(.caption)
              } else {
                Image(systemName: "checkmark.circle.fill")
                  .foregroundColor(.green)
                  .font(.caption)
              }
            }
            .tag(provider)
          }
        }
        .pickerStyle(.navigationLink)
        
        // Current selection info
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text("Selected:")
              .font(.caption)
              .foregroundColor(.secondary)
            
            Text(appManager.settingsViewModel.selectedProvider.displayName)
              .font(.caption)
              .fontWeight(.medium)
          }
          
          // Warning message if provider is not configured
          if let warningMessage = appManager.settingsViewModel.getProviderWarningMessage() {
            Text(warningMessage)
              .font(.caption2)
              .foregroundColor(.orange)
          }
        }
      }
    } header: {
      Label("Transcription Service", systemImage: "mic.badge.plus")
    } footer: {
      Text("Choose your preferred transcription service. Cloud-based services require API keys and internet connection but may provide better accuracy.")
        .font(.caption2)
    }
  }
  
}


#Preview {
  let container = PreviewContainer.shared
  let appManager = AppManager(modelContainer: container)

    ProviderSelectionView()
    .environment(appManager)
    .modelContainer(container)
    .padding()
}
