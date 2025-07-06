//
//  APIKeyActionButtons.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI

struct APIKeyActionButtons: View {
    @Binding var apiKey: String
    @Binding var isStored: Bool
    
    let onSave: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Button("Save", action: onSave)
                .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            
            if isStored {
                Button("Remove", role: .destructive, action: onRemove)
            }
        }
    }
}

#Preview {
  APIKeyActionButtons(apiKey: .constant("ABC123"), isStored: .constant(true), onSave: { print("Preview: Save Tapped") },
                      onRemove: { print("Preview: Remove Tapped") })
}
