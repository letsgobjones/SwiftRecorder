//
//  StatusMessageView.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI

struct StatusMessageView: View {
  let message: String?
  let isInterrupted: Bool
  let backgroundTimeRemaining: TimeInterval
  let isInBackground: Bool
  
  private var statusColor: Color {
    if isInterrupted {
      return .orange
    }
    return .red
  }
  
  private func formatTime(_ timeInterval: TimeInterval) -> String {
    let minutes = Int(timeInterval) / 60
    let seconds = Int(timeInterval) % 60
    return String(format: "%d:%02d", minutes, seconds)
  }
  
  var body: some View {
    VStack(spacing: 4) {
      // Background time indicator
      if isInBackground && backgroundTimeRemaining > 0 {
        HStack {
          Image(systemName: "clock")
            .foregroundColor(.orange)
          Text("Background: \(formatTime(backgroundTimeRemaining))")
            .font(.caption)
            .foregroundColor(.orange)
        }
      }
      
      // Status message
      if let message = message {
        Text(message)
          .foregroundColor(statusColor)
          .font(.footnote)
          .multilineTextAlignment(.center)
          .padding(.horizontal)
      }
    }
  }
  

}

#Preview {
  VStack(spacing: 10) {
    StatusMessageView(
      message: "Recording in background",
      isInterrupted: false,
      backgroundTimeRemaining: 145,
      isInBackground: true
    )
    
    StatusMessageView(
      message: "Recording paused due to interruption",
      isInterrupted: true,
      backgroundTimeRemaining: 0,
      isInBackground: false
    )
  }
  .padding()
}
