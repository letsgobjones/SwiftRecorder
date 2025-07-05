//
//  Models.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/2/25.
//

import SwiftUI
import SwiftData


@Model
final class RecordingSession {
 @Attribute(.unique) var id: UUID
var createdAt: Date
  var duration: TimeInterval
  var audioFilePath: String // Relative path in Document directory
  var isProcessing: Bool
  
  @Relationship(deleteRule: .cascade)
  var segments: [TranscriptionSegment] = []
  
  init(id: UUID = UUID(), createdAt: Date = Date(), duration: TimeInterval = 0, audioFilePath: String, isProcessing: Bool = false) {
    self.id = id
    self.createdAt = createdAt
    self.duration = duration
    self.audioFilePath = audioFilePath
    self.isProcessing = isProcessing
  }
  
  /// Returns transcription segments sorted by start time
  var sortedSegments: [TranscriptionSegment] {
    segments.sorted { $0.startTime < $1.startTime }
  }
}



@Model
final class TranscriptionSegment {
  @Attribute(.unique) var id: UUID
  var startTime: TimeInterval
  var transcriptionText: String
  var status: TranscriptionStatus
  
  // Relationship with parent session
  var session: RecordingSession?
  init(id: UUID = UUID(), startTime: TimeInterval, transcriptionText: String = "", status: TranscriptionStatus = .pending) {
    self.id = id
    self.startTime = startTime
    self.transcriptionText = transcriptionText
    self.status = status
  }
}


// Enum for managing transcription status
enum TranscriptionStatus: String, CaseIterable, Codable {
  case pending
  case processing
  case completed
  case failed
  case queued
  case completedLocal
}