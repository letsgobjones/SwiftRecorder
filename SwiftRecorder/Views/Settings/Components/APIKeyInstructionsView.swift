//
//  APIKeyInstructionsView.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI

struct APIKeyInstructionsView: View {
    let keyType: APIKeyType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Get your API key from \(keyType.displayName):")
            ForEach(keyType.instructions, id: \.self) { step in
                Text(step)
            }
        }
        .font(.caption2)
        .foregroundColor(.secondary)
    }
}

#Preview {
  APIKeyInstructionsView(keyType: .googleSpeechToText)
}
