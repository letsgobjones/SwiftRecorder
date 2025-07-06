//
//  APIKeySectionView.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI

struct APIKeySectionView: View {
    let keyType: APIKeyType
    @Binding var apiKey: String
    @Binding var isStored: Bool
    
    let onSave: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                APIKeyTextField(keyType: keyType, apiKey: $apiKey)
                APIKeyStatusIndicator(isStored: $isStored)
                APIKeyActionButtons(apiKey: $apiKey, isStored: $isStored, onSave: onSave, onRemove: onRemove)
            }
        } header: {
            Label(keyType.displayName, systemImage: keyType.iconName)
        } footer: {
            APIKeyInstructionsView(keyType: keyType)
        }
    }
}

#Preview {
  APIKeySectionView(keyType: .googleSpeechToText, apiKey: .constant("ABC13"), isStored: .constant(true), onSave: { print("Preview: Save Tapped") },
                    onRemove: { print("Preview: Remove Tapped") })
  .padding()
}
