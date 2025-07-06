//
//  SegmentTranscriptionView.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI

struct SegmentTranscriptionView: View {
    let segment: TranscriptionSegment
    
    var body: some View {
        switch segment.status {
        case .completed, .completedLocal:
            Text(segment.transcriptionText.isEmpty ? "No transcription available" : segment.transcriptionText)
                .font(.body)
                .padding(.top, 4)
        case .processing:
            LoadingStateView(state: .loading, message: "Transcribing...")
        case .failed:
            LoadingStateView(state: .error, message: segment.transcriptionText)
        case .queued:
            LoadingStateView(state: .idle, message: "Queued for transcription")
        case .pending:
            Text("Pending transcription")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
  SegmentTranscriptionView(segment: TranscriptionSegment(startTime: 0.0, transcriptionText: "Completed segment", status: .completed))
}
