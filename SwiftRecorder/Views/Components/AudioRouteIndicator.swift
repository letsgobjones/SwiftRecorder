//
//  AudioRouteIndicator.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI

struct AudioRouteIndicator: View {
    let currentRoute: AudioRoute
  
  
  private var audioRouteIcon: String {
      switch currentRoute {
      case .builtInMicrophone: return "iphone"
      case .headphones: return "headphones"
      case .bluetoothHFP: return "bluetooth"
      case .usbAudio: return "cable.connector"
      case .airPlay: return "airplayaudio"
      case .none: return "speaker.slash"
      case .other: return "questionmark.circle"
      }
  }
    
    var body: some View {
        HStack {
            Image(systemName: audioRouteIcon)
                .foregroundColor(.blue)
            Text(currentRoute.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 4)
    }

}

#Preview {
    VStack(spacing: 10) {
        AudioRouteIndicator(currentRoute: .builtInMicrophone)
        AudioRouteIndicator(currentRoute: .headphones)
        AudioRouteIndicator(currentRoute: .bluetoothHFP)
        AudioRouteIndicator(currentRoute: .none)
    }
    .padding()
}
