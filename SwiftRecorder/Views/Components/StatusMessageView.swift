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
  
  
  private var statusColor: Color {
    if isInterrupted {
      return .orange
    }
    return .red
  }
  
  var body: some View {
    if let message = message {
      Text(message)
        .foregroundColor(statusColor)
        .font(.footnote)
        .multilineTextAlignment(.center)
        .padding()
    }
  }
}

#Preview {
  VStack(spacing: 10) {
    StatusMessageView(
      message: "Recording paused due to interruption",
      isInterrupted: true
    )
    
    StatusMessageView(
      message: "Failed to start recording",
      isInterrupted: false
    )
  }
  .padding()
}
