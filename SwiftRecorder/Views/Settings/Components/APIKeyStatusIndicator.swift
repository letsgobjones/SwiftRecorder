//
//  APIKeyStatusIndicator.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI

struct APIKeyStatusIndicator: View {
    @Binding var isStored: Bool
    
    var body: some View {
        Group {
            if isStored {
                Label("API Key configured", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Label("No API Key configured", systemImage: "xmark.circle")
                    .foregroundColor(.orange)
            }
        }
        .font(.caption)
    }
}
#Preview {
  APIKeyStatusIndicator(isStored: .constant(true))
}
