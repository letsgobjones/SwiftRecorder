//
//  StorageStatus.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import Foundation

// MARK: - Supporting Types

enum StorageStatus {
    case low, medium, high, critical
    
    var displayName: String {
        switch self {
        case .low: return "Low Usage"
        case .medium: return "Medium Usage"
        case .high: return "High Usage"
        case .critical: return "Critical Usage"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

private struct FileInfo {
    let size: Int64
    let creationDate: Date
}

private struct StorageInfo {
    let totalSize: Int64
    let fileCount: Int
    let oldestDate: Date?
    let newestDate: Date?
}
