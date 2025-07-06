//
//  RecordingButton.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI

struct RecordingButton: View {
    let isRecording: Bool
    let isInterrupted: Bool
    let hasMicrophoneAccess: Bool
    let action: () -> Void
  
  
  
  private var buttonIcon: String {
      if isInterrupted {
          return "pause.circle.fill"
      } else if isRecording {
          return "stop.circle.fill"
      } else {
          return "record.circle"
      }
  }
  
  private var buttonColor: Color {
      if isInterrupted {
          return .orange
      } else if isRecording {
          return .red
      } else {
          return .blue
      }
  }
  
  private var buttonLabel: String {
      if isInterrupted {
          return "Resume or Stop Recording"
      } else if isRecording {
          return "Stop Recording"
      } else {
          return "Start Recording"
      }
  }
  
  
  
    
    var body: some View {
        Button(action: action) {
            Image(systemName: buttonIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 70, height: 70)
                .foregroundColor(buttonColor)
                .accessibilityLabel(buttonLabel)
        }
        .disabled(!hasMicrophoneAccess)
        .padding(.bottom)
    }
    

}

#Preview {
    VStack(spacing: 20) {
        RecordingButton(
            isRecording: false,
            isInterrupted: false,
            hasMicrophoneAccess: true,
            action: {}
        )
        
        RecordingButton(
            isRecording: true,
            isInterrupted: false,
            hasMicrophoneAccess: true,
            action: {}
        )
        
        RecordingButton(
            isRecording: false,
            isInterrupted: true,
            hasMicrophoneAccess: true,
            action: {}
        )
    }
    .padding()
}
