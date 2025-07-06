//
//  AppInfoSection.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI

struct AppInfoSection: View {
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text("SwiftRecorder")
                    .font(.headline)
                Text("Configure cloud transcription services.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } header: {
            Label("App Info", systemImage: "gear")
        }
    }
}
#Preview {
    AppInfoSection()
}
