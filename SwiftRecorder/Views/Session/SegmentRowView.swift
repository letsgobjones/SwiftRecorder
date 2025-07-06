//
//  SegmentRowView.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI

struct SegmentRowView: View {
    let segment: TranscriptionSegment
    let segmentIndex: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Segment \(segmentIndex)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(String(format: "%.1f", segment.startTime))s")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Status indicator using LoadingStateView
                SegmentStatusView(segment: segment)
            }
            
            // Transcription text with LoadingStateView
            SegmentTranscriptionView(segment: segment)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
  
  SegmentRowView(segment: TranscriptionSegment(startTime: 0.0, transcriptionText: "Completed segment", status: .completed), segmentIndex: 0)
}
