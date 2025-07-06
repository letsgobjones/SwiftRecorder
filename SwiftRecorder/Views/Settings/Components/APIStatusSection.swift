//
//  APIStatusSection.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI

struct APIStatusSection: View {
    let errorMessage: String?
    let successMessage: String?
    
    var body: some View {
        if let errorMessage = errorMessage {
            Section {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .foregroundColor(.red)
            }
        }
        
        if let successMessage = successMessage {
            Section {
                Label(successMessage, systemImage: "checkmark.circle")
                    .foregroundColor(.green)
            }
        }
    }
}

#Preview {
  APIStatusSection(errorMessage: "error", successMessage: "success")
}
