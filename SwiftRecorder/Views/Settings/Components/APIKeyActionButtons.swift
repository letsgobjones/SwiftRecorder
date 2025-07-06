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
    @Binding var isValidating: Bool
    
    let onSave: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button("Save", action: onSave)
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isValidating)
                
                if isStored {
                    Button("Remove", role: .destructive, action: onRemove)
                        .disabled(isValidating)
                }
            }
            
            if isValidating {
                LoadingStateView(state: .loading, message: "Validating API key...")
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        APIKeyActionButtons(
            apiKey: .constant("ABC123"), 
            isStored: .constant(true), 
            isValidating: .constant(false),
            onSave: { print("Preview: Save Tapped") },
            onRemove: { print("Preview: Remove Tapped") }
        )
        
        APIKeyActionButtons(
            apiKey: .constant("ABC123"), 
            isStored: .constant(false), 
            isValidating: .constant(true),
            onSave: { print("Preview: Save Tapped") },
            onRemove: { print("Preview: Remove Tapped") }
        )
    }
    .padding()
}