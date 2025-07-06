import SwiftUI
import SwiftData
import AVFoundation

@Observable
class ProcessingCoordinator {
  
  // MARK: - Dependencies
  private let transcriptionService: TranscriptionService
  private let segmentDuration: TimeInterval = 30.0 // 30 seconds
  
  // MARK: - Initialization
  init(transcriptionService: TranscriptionService) {
    self.transcriptionService = transcriptionService
    print("ProcessingCoordinator: Initialized with injected TranscriptionService")
  }
  
  // MARK: - Sendable Data Structures (Internal Data Transfer Objects - DTOs)
  
  
  // Sendable struct for passing individual segment data between contexts.
  struct SegmentData: Sendable {
    let index: Int
    let startTime: TimeInterval
    let transcription: String?
    let status: TranscriptionStatus
    let errorMessage: String?
    
    init(index: Int, startTime: TimeInterval, transcription: String? = nil, status: TranscriptionStatus, errorMessage: String? = nil) {
      self.index = index
      self.startTime = startTime
      self.transcription = transcription
      self.status = status
      self.errorMessage = errorMessage
    }
  }
  
  /// Sendable struct for passing the overall processing result back to the main actor.
  struct ProcessingResult: Sendable {
    let sessionId: UUID
    let segmentResults: [SegmentData]
    let totalDuration: TimeInterval
    let success: Bool
    let errorMessage: String?
  }
  
  // MARK: - Public Interface
  // Processes a recording session by splitting its audio into segments and transcribing each.
  
  // This function orchestrates the entire transcription workflow:
  // 1. Updates the session's processing status in the database (on MainActor).
  // 2. Performs the intensive audio processing and transcription (off-MainActor for performance).
  // 3. Updates the database with the final results (back on MainActor for safety).
  /// - Parameters:
  ///   - session: The `RecordingSession` object to be processed.
  ///   - modelContext: The `ModelContext` used for database operations.
  
  
  
  
  
  @MainActor
  func process(session: RecordingSession, modelContext: ModelContext) async {
    print("ProcessingCoordinator: Starting segmented processing for session: \(session.id)")
    
    // Safety check: Skip mock data to prevent API calls
    if AudioFileHelpers.isMockFile(path: session.audioFilePath) {
      print("ProcessingCoordinator: Skipping mock data: \(session.audioFilePath)")
      session.isProcessing = false
      
      if session.segments.isEmpty {
        let mockSegment = TranscriptionSegment(
          startTime: 0.0,
          transcriptionText: "Mock preview data - no transcription performed",
          status: .completed
        )
        mockSegment.session = session
        session.segments.append(mockSegment)
        modelContext.insert(mockSegment)
        try? modelContext.save()
      }
      return
    }
    
    // Extract session data to avoid Sendable issues
    let sessionId = session.id
    let audioFilePath = session.audioFilePath
    
    // Update UI (and database) to show immediate processing state - do this synchronously to avoid Sendable issues
    session.isProcessing = true
    do {
      try modelContext.save()
      print("ProcessingCoordinator: Session marked as processing")
    } catch {
      print("ProcessingCoordinator: Failed to save processing state: \(error.localizedDescription)")
    }
    
    //    Perform audio processing and transcription off the MainActor.
    let result = await processAudioWithoutModelContext(
      audioFilePath: audioFilePath,
      sessionId: sessionId
    )
    
    // Update the database with results (back on MainActor).
    // Once the background processing is done, we switch back to the MainActor
    // to safely update the SwiftData models with the results.
    await updateSessionWithResult(result, modelContext: modelContext)
  }
  
  // MARK: - Audio Processing (Off-MainActor Compatible)
  
  /// Processes the full audio file by reading it, calculating segments, and transcribing each segment.
  /// This function is designed to be compatible with execution off the `MainActor` as it
  /// explicitly avoids direct `ModelContext` or `@Model` object interaction.
  /// - Parameters:
  ///   - audioFilePath: The relative path to the audio file within the Documents directory.
  ///   - sessionId: The ID of the session this audio belongs to.
  /// - Returns: A `ProcessingResult` containing all segment data and overall status.
  ///
  private func processAudioWithoutModelContext(
    audioFilePath: String,
    sessionId: UUID
  ) async -> ProcessingResult {
    print("ProcessingCoordinator: Processing audio file without ModelContext")
    
    // Get the audio file URL
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let audioFileURL = documentsPath.appendingPathComponent(audioFilePath)
    
    // Check if audio file exists
    guard FileManager.default.fileExists(atPath: audioFileURL.path) else {
      print("ProcessingCoordinator: Audio file not found at: \(audioFileURL)")
      return ProcessingResult(
        sessionId: sessionId,
        segmentResults: [],
        totalDuration: 0,
        success: false,
        errorMessage: "Audio file not found"
      )
    }
    
    do {
      // Load the original audio file using AVAudioFile
      let audioFile = try AVAudioFile(forReading: audioFileURL)
      let audioFormat = audioFile.processingFormat
      let frameCount = AVAudioFrameCount(audioFile.length)
      let sampleRate = audioFormat.sampleRate
      
      //      Calculate number of segments based on total duration and segmentDuration.
      let totalDuration = Double(frameCount) / sampleRate
      let numberOfSegments = Int(ceil(totalDuration / segmentDuration))
      
      print("ProcessingCoordinator: Audio duration: \(totalDuration)s, creating \(numberOfSegments) segments")
      
      // Process all segments sequentially
      var segmentResults: [SegmentData] = []
      for segmentIndex in 0..<numberOfSegments {
        print("ProcessingCoordinator: Processing segment \(segmentIndex + 1) of \(numberOfSegments)")
        
        
        // Call helper function to process a single segment.
        let segmentResult = await processAudioSegmentWithoutModelContext(
          audioFile: audioFile,
          segmentIndex: segmentIndex,
          sessionId: sessionId
        )
        // Store the result of each segment.
        let segmentData = SegmentData(
          index: segmentIndex,
          startTime: Double(segmentIndex) * segmentDuration, // Calculate segment's start time.
          transcription: segmentResult.transcription,
          status: segmentResult.success ? .completed : .failed,
          errorMessage: segmentResult.errorMessage
        )
        
        segmentResults.append(segmentData)
      }
      
      print("ProcessingCoordinator: Completed processing \(segmentResults.count) segments")
      
      // Return overall processing result.
      return ProcessingResult(
        sessionId: sessionId,
        segmentResults: segmentResults,
        totalDuration: totalDuration,
        success: true,
        errorMessage: nil
      )
      
    } catch {
      // Catch any errors during file loading or general segment processing.
      print("ProcessingCoordinator: Failed to process audio: \(error.localizedDescription)")
      return ProcessingResult(
        sessionId: sessionId,
        segmentResults: [],
        totalDuration: 0,
        success: false,
        errorMessage: error.localizedDescription
      )
    }
  }
  
  
  
  /// Processes a single audio segment: extracts it, transcribes it, and cleans up.
  /// This function operates without direct `ModelContext` dependency.
  /// - Parameters:
  ///   - audioFile: The original `AVAudioFile` object (passed in to avoid re-loading).
  ///   - segmentIndex: The index of the current segment being processed.
  ///   - sessionId: The ID of the parent session.
  /// - Returns: A tuple indicating success, transcription, and error message.
  ///
  private func processAudioSegmentWithoutModelContext(
    audioFile: AVAudioFile,
    segmentIndex: Int,
    sessionId: UUID
  ) async -> (success: Bool, transcription: String?, errorMessage: String?) {
    print("ProcessingCoordinator: Processing segment \(segmentIndex)")
    
    do {
      // Create a temporary audio file for the current segment.
      let segmentURL = try createAudioSegmentFile(
        audioFile: audioFile,
        segmentIndex: segmentIndex,
        sessionId: sessionId
      )
      
      print("ProcessingCoordinator: Transcribing segment \(segmentIndex) from file: \(segmentURL.lastPathComponent)")
      
      // Get the selected provider from UserDefaults (since we're off MainActor and can't access AppManager)
      let selectedProviderRaw = UserDefaults.standard.string(forKey: "selectedTranscriptionProvider") ?? TranscriptionProvider.appleOnDevice.rawValue
      let selectedProvider = TranscriptionProvider(rawValue: selectedProviderRaw) ?? .appleOnDevice
      
      print("ProcessingCoordinator: Using provider: \(selectedProvider.displayName)")
      
      // Transcribe the segment using the selected provider
      let transcription = try await transcriptionService.transcribe(
        audioURL: segmentURL,
        with: selectedProvider
      )
      
      // Clean up the temporary segment file immediately after transcription.
      try? FileManager.default.removeItem(at: segmentURL)
      
      // For logging: create a short preview of the transcription.
      let preview = transcription.count > 50 ? String(transcription.prefix(50)) + "..." : transcription
      print("ProcessingCoordinator: Segment \(segmentIndex) completed with \(selectedProvider.displayName): \(preview)")
      
      return (success: true, transcription: transcription, errorMessage: nil)
      
    } catch {
      // If transcription fails for this specific segment.
      let errorMessage = error.localizedDescription
      print("ProcessingCoordinator: Segment \(segmentIndex) failed: \(errorMessage)")
      return (success: false, transcription: nil, errorMessage: errorMessage)
    }
  }
  
  /// Creates a separate temporary audio file for a specific segment of the original recording.
      /// - Parameters:
      ///   - audioFile: The original `AVAudioFile` to read from.
      ///   - segmentIndex: The index of the segment to extract.
      ///   - sessionId: The ID of the parent session (used for unique filename generation).
      /// - Returns: The URL of the newly created segment audio file.
      /// - Throws: An error if file reading/writing fails, or if the segment has no frames.
  ///
    private func createAudioSegmentFile(
    audioFile: AVAudioFile,
    segmentIndex: Int,
    sessionId: UUID
  ) throws -> URL {
    let audioFormat = audioFile.processingFormat
    let sampleRate = audioFormat.sampleRate
    let frameCount = AVAudioFrameCount(audioFile.length)
    
    // Calculate segment frame positions based on `segmentDuration`.
    let segmentFrameCount = AVAudioFrameCount(segmentDuration * sampleRate)
    let startFrame = AVAudioFramePosition(segmentIndex) * AVAudioFramePosition(segmentFrameCount)
    let endFrame = min(startFrame + AVAudioFramePosition(segmentFrameCount), AVAudioFramePosition(frameCount))
    let actualFrameCount = AVAudioFrameCount(endFrame - startFrame)
    
    // Ensure we have frames to read for this segment.
    guard actualFrameCount > 0 else {
      throw NSError(domain: "ProcessingCoordinator", code: -1, userInfo: [NSLocalizedDescriptionKey: "No audio frames to process for segment \(segmentIndex)"])
    }
    
    // Create a unique URL for the temporary segment file.
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let segmentFileName = "segment_\(segmentIndex)_\(sessionId.uuidString).m4a"
    let segmentURL = documentsPath.appendingPathComponent(segmentFileName)
    
    // Create an `AVAudioFile` for writing the segment.
    let outputFile = try AVAudioFile(forWriting: segmentURL, settings: audioFormat.settings)
    
    // Read the specific segment's frames from the original audio file.
            // Create an empty buffer with enough capacity.
    let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: actualFrameCount)!
    audioFile.framePosition = startFrame
    try audioFile.read(into: buffer, frameCount: actualFrameCount)
    try outputFile.write(from: buffer)
    
    print("ProcessingCoordinator: Created segment file: \(segmentFileName) (frames: \(actualFrameCount))")
    return segmentURL
  }
  
  // MARK: - Database Updates (MainActor with ModelContext)

      /// Updates the `RecordingSession` and its `TranscriptionSegment`s in the database
      /// with the results obtained from audio processing.
      /// This function must run on the `MainActor` for safe SwiftData access.
      /// - Parameters:
      ///   - result: The `ProcessingResult` containing all segment data and overall status.
      ///   - modelContext: The `ModelContext` used for data operations.
  @MainActor
  private func updateSessionWithResult(_ result: ProcessingResult, modelContext: ModelContext) async {
    print("ProcessingCoordinator: Updating session with results on MainActor")
    
//    Fetch the session by ID:
    let sessionId = result.sessionId
    let descriptor = FetchDescriptor<RecordingSession>(
      predicate: #Predicate { session in
        session.id == sessionId
      }
    )
    
    guard let session = try? modelContext.fetch(descriptor).first else {
      print("ProcessingCoordinator: Session not found for ID: \(result.sessionId)")
      return
    }
    // Apply processing results to the session.
    if result.success {
      print("ProcessingCoordinator: Processing succeeded, updating session")
      
      // If no segments exist yet, create them. This happens on first successful transcription.
      if session.segments.isEmpty {
        print("ProcessingCoordinator: Creating \(result.segmentResults.count) segments")
        
        for segmentData in result.segmentResults {
          let segment = TranscriptionSegment(
            startTime: segmentData.startTime,
            transcriptionText: segmentData.transcription ?? "",
            status: segmentData.status
          )
          
          segment.session = session // Establish the relationship back to the parent session.
                              session.segments.append(segment) // Add to the relationship array.
                              modelContext.insert(segment) // Insert the new segment into the context.
        }
      } else {
        // Update existing segments
        print("ProcessingCoordinator: Updating \(session.segments.count) existing segments")
        
        for segmentData in result.segmentResults {
          // Find the existing segment by index
          if segmentData.index < session.segments.count {
            let segment = session.segments[segmentData.index]
            segment.transcriptionText = segmentData.transcription ?? (segmentData.errorMessage ?? "Transcription failed")
            segment.status = segmentData.status
          }
        }
      }
      
      // Update the session's duration based on the actual processed audio duration.
      session.duration = result.totalDuration
      
      // Create combined transcription text for logging/preview.
      let completedSegments = session.sortedSegments.filter { $0.status == .completed }
      let combinedTranscription = completedSegments
        .compactMap { $0.transcriptionText }
        .joined(separator: " ")
      
      print("ProcessingCoordinator: Combined transcription (\(combinedTranscription.count) characters)")
      if !combinedTranscription.isEmpty {
        print("ProcessingCoordinator: Preview: \(String(combinedTranscription.prefix(100)))...")
      }
      
    } else {
      // Handle overall processing failure.
      print("ProcessingCoordinator: Processing failed: \(result.errorMessage ?? "Unknown error")")
      
      // If no segments exist, create a single error segment.
      if session.segments.isEmpty {
        let errorSegment = TranscriptionSegment(
          startTime: 0,
          transcriptionText: "Processing failed: \(result.errorMessage ?? "Unknown error")",
          status: .failed
        )
        errorSegment.session = session
        session.segments.append(errorSegment)
        modelContext.insert(errorSegment)
      } else {
        // If segments exist, mark all non-completed segments as failed.
        for segment in session.segments {
          if segment.status != .completed {
            segment.status = .failed
            segment.transcriptionText = "Processing failed: \(result.errorMessage ?? "Unknown error")"
          }
        }
      }
    }
    
//    Finalize session processing state and save all changes.
    session.isProcessing = false // Mark the session as no longer processing.
    
    // Save all changes made within this @MainActor function to the database.
    do {
      try modelContext.save()
      print("ProcessingCoordinator: Session updated and saved successfully")
    } catch {
      print("ProcessingCoordinator: Failed to save session updates: \(error.localizedDescription)")
    }
  }
}