//
//  SegmentStatusView.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI

struct SegmentStatusView: View {
    let segment: TranscriptionSegment
    
    var body: some View {
        Group {
            switch segment.status {
            case .completed, .completedLocal:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .processing:
                LoadingStateView(state: .loading, message: nil)
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            case .queued:
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
            case .pending:
                Image(systemName: "circle")
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
  SegmentStatusView(segment: TranscriptionSegment(startTime: 0.0, transcriptionText: "Completed segment", status: .completed))

}
