//
//  ProcessingProgressView.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI


struct ProcessingProgressView: View {
    let session: RecordingSession
    
    private var completedCount: Int {
        session.segments.filter { $0.status == .completed || $0.status == .completedLocal }.count
    }
    
    private var totalCount: Int {
        session.segments.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Processing Progress")
                .font(.headline)
            
            ProgressView(value: Double(completedCount), total: Double(totalCount))
                .progressViewStyle(LinearProgressViewStyle())
            
            LoadingStateView(
                state: .loading,
                message: "\(completedCount)/\(totalCount) segments completed"
            )
        }
        .padding(.top, 8)
    }
}

#Preview {
    let container = PreviewContainer.shared
    let sampleSession = PreviewContainer.sampleSession()
    
    return ProcessingProgressView(session: sampleSession)
        .padding()
        .modelContainer(container)
}

