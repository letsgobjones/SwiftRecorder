//
//  SessionRowView.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI

struct SessionRowView: View {

let session: RecordingSession
 
 var body: some View {
     VStack(alignment: .leading, spacing: 4) {
         Text(session.createdAt.formatted(.dateTime.day().month().year().hour().minute()))
             .font(.headline)
         
         Text("Duration: \(String(format: "%.1f", session.duration))s")
             .font(.caption)
             .foregroundColor(.gray)
         
         if session.isProcessing {
             LoadingStateView(state: .loading, message: "Processing...")
                 .padding(.top, 2)
         }
     }
     .accessibilityElement(children: .combine)
     .accessibilityLabel("Recording from \(session.createdAt, style: .date), lasting \(String(format: "%.1f", session.duration)) seconds.")
 }
}


#Preview {
  SessionRowView(session: RecordingSession(createdAt: Date(), duration: 10.5, audioFilePath: String(), isProcessing: false))
}
