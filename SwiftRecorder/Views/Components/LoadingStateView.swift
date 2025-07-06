//
//  LoadingStateView.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI

struct LoadingStateView: View {
    let state: LoadingState
    let message: String?
  
  enum LoadingState {
      case idle
      case loading
      case success
      case error
  }

    
    var body: some View {
        Group {
            switch state {
            case .idle:
                EmptyView()
                
            case .loading:
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    
                    if let message = message {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Loading: \(message ?? "Please wait")")
                
            case .success:
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    if let message = message {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .accessibilityLabel("Success: \(message ?? "Operation completed")")
                
            case .error:
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    
                    if let message = message {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .accessibilityLabel("Error: \(message ?? "An error occurred")")
            }
        }
        .animation(.easeInOut(duration: 0.3), value: state)
    }
}


#Preview {
    VStack(spacing: 20) {
        LoadingStateView(state: .loading, message: "Processing audio...")
        LoadingStateView(state: .success, message: "Transcription completed")
        LoadingStateView(state: .error, message: "Failed to process")
    }
    .padding()
}
