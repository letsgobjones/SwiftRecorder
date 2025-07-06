//
//  EmptySessionsView.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI

struct EmptySessionsView: View {
    var body: some View {
        ContentUnavailableView("No Recordings Yet", systemImage: "mic.fill")
            .padding()
    }
}


#Preview {
    EmptySessionsView()
}
