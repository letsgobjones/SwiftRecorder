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
  var audioFilePath: String // Relative path in Dcocument directory
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
}



@Model
final class TranscriptionSegment {
  var startTime: TimeInterval
  var transcriptionText: String
  var status: TranscriptionStatus
  
  // Relationship with parent session
  var session: RecordingSession?
  init(startTime: TimeInterval, transcriptionText: String = "", status: TranscriptionStatus = .pending) {
    self.startTime = startTime
    self.transcriptionText = transcriptionText
    self.status = status
  }
}


// Enum for managing transcription status
enum TranscriptionStatus: String, CaseIterable {
  case pending
  case processing
  case completed
  case failed
  case queued
  case completedLocal
}
