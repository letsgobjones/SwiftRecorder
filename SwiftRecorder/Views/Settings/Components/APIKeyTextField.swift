//
//  APIKeyTextField.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI

struct APIKeyTextField: View {
    let keyType: APIKeyType
    @Binding var apiKey: String
    
    @State private var showAPIKey: Bool = false
    
    var body: some View {
        HStack {
            Group {
                if showAPIKey {
                    TextField("Enter \(keyType.displayName) API Key", text: $apiKey)
                } else {
                    SecureField("Enter \(keyType.displayName) API Key", text: $apiKey)
                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button(action: { showAPIKey.toggle() }) {
                Image(systemName: showAPIKey ? "eye.slash" : "eye")
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
  APIKeyTextField(keyType: .googleSpeechToText, apiKey: .constant("ABC123"))
    .padding()
}
