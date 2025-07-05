import SwiftUI
import SwiftData
import AVFoundation

@Observable
class ProcessingCoordinator {
    private let transcriptionService = TranscriptionService()
    private let segmentDuration: TimeInterval = 30.0 // 30 seconds
    
    // MARK: - Sendable Data Structures
  // Internal data transfer objects (DTOs)
  
  
    /// Sendable struct for passing segment data between contexts
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
    
    /// Sendable struct for passing processing results
    struct ProcessingResult: Sendable {
        let sessionId: UUID
        let segmentResults: [SegmentData]
        let totalDuration: TimeInterval
        let success: Bool
        let errorMessage: String?
    }
    
    // MARK: - Public Interface
    
    /// Processes a recording session by splitting audio into segments and transcribing each
    func process(session: RecordingSession, modelContext: ModelContext) async {
        print("ProcessingCoordinator: Starting segmented processing for session: \(session.id)")
        
        // Extract session data to avoid Sendable issues - Rule #6: Avoid non-Sendable captures
        let sessionId = session.id
        let audioFilePath = session.audioFilePath
        
        // Update UI to show processing state - do this synchronously to avoid Sendable issues
        session.isProcessing = true
        do {
            try modelContext.save()
            print("ProcessingCoordinator: Session marked as processing")
        } catch {
            print("ProcessingCoordinator: Failed to save processing state: \(error.localizedDescription)")
        }
        
        // Process audio without ModelContext (avoiding Sendable issues)
        let result = await processAudioWithoutModelContext(
            audioFilePath: audioFilePath,
            sessionId: sessionId
        )
        
        // Update database with results
        await updateSessionWithResult(result, modelContext: modelContext)
    }
    
    // MARK: - Audio Processing
    
    /// Processes audio file and returns results 
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
            // Load the original audio file
            let audioFile = try AVAudioFile(forReading: audioFileURL)
            let audioFormat = audioFile.processingFormat
            let frameCount = AVAudioFrameCount(audioFile.length)
            let sampleRate = audioFormat.sampleRate
            
            // Calculate number of segments
            let totalDuration = Double(frameCount) / sampleRate
            let numberOfSegments = Int(ceil(totalDuration / segmentDuration))
            
            print("ProcessingCoordinator: Audio duration: \(totalDuration)s, creating \(numberOfSegments) segments")
            
            // Process all segments sequentially
            var segmentResults: [SegmentData] = []
            
            for segmentIndex in 0..<numberOfSegments {
                print("ProcessingCoordinator: Processing segment \(segmentIndex + 1) of \(numberOfSegments)")
                
                let startTime = Double(segmentIndex) * segmentDuration
                let segmentResult = await processAudioSegmentWithoutModelContext(
                    audioFile: audioFile,
                    segmentIndex: segmentIndex,
                    sessionId: sessionId
                )
                
                let segmentData = SegmentData(
                    index: segmentIndex,
                    startTime: startTime,
                    transcription: segmentResult.transcription,
                    status: segmentResult.success ? .completed : .failed,
                    errorMessage: segmentResult.errorMessage
                )
                
                segmentResults.append(segmentData)
            }
            
            print("ProcessingCoordinator: Completed processing \(segmentResults.count) segments")
            
            return ProcessingResult(
                sessionId: sessionId,
                segmentResults: segmentResults,
                totalDuration: totalDuration,
                success: true,
                errorMessage: nil
            )
            
        } catch {
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
    
    /// Processes a single audio segment (no ModelContext dependency)
    private func processAudioSegmentWithoutModelContext(
        audioFile: AVAudioFile,
        segmentIndex: Int,
        sessionId: UUID
    ) async -> (success: Bool, transcription: String?, errorMessage: String?) {
        print("ProcessingCoordinator: Processing segment \(segmentIndex)")
        
        do {
            // Create segment file
            let segmentURL = try createAudioSegmentFile(
                audioFile: audioFile,
                segmentIndex: segmentIndex,
                sessionId: sessionId
            )
            
            print("ProcessingCoordinator: Transcribing segment \(segmentIndex) from file: \(segmentURL.lastPathComponent)")
            
            // Transcribe the segment
            let transcription = try await transcriptionService.transcribe(
                audioURL: segmentURL,
                with: .appleOnDevice
            )
            
            // Clean up segment file
            try? FileManager.default.removeItem(at: segmentURL)
            
            let preview = transcription.count > 50 ? String(transcription.prefix(50)) + "..." : transcription
            print("ProcessingCoordinator: Segment \(segmentIndex) completed: \(preview)")
            
            return (success: true, transcription: transcription, errorMessage: nil)
            
        } catch {
            let errorMessage = error.localizedDescription
            print("ProcessingCoordinator: Segment \(segmentIndex) failed: \(errorMessage)")
            return (success: false, transcription: nil, errorMessage: errorMessage)
        }
    }
    
    /// Creates a separate audio file for a specific segment
    private func createAudioSegmentFile(
        audioFile: AVAudioFile,
        segmentIndex: Int,
        sessionId: UUID
    ) throws -> URL {
        let audioFormat = audioFile.processingFormat
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(audioFile.length)
        
        // Calculate segment frame positions
        let segmentFrameCount = AVAudioFrameCount(segmentDuration * sampleRate)
        let startFrame = AVAudioFramePosition(segmentIndex) * AVAudioFramePosition(segmentFrameCount)
        let endFrame = min(startFrame + AVAudioFramePosition(segmentFrameCount), AVAudioFramePosition(frameCount))
        let actualFrameCount = AVAudioFrameCount(endFrame - startFrame)
        
        // Ensure we have frames to read
        guard actualFrameCount > 0 else {
            throw NSError(domain: "ProcessingCoordinator", code: -1, userInfo: [NSLocalizedDescriptionKey: "No audio frames to process for segment \(segmentIndex)"])
        }
        
        // Create segment file URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let segmentFileName = "segment_\(segmentIndex)_\(sessionId.uuidString).m4a"
        let segmentURL = documentsPath.appendingPathComponent(segmentFileName)
        
        // Create output file
        let outputFile = try AVAudioFile(forWriting: segmentURL, settings: audioFormat.settings)
        
        // Read and write segment
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: actualFrameCount)!
        audioFile.framePosition = startFrame
        try audioFile.read(into: buffer, frameCount: actualFrameCount)
        try outputFile.write(from: buffer)
        
        print("ProcessingCoordinator: Created segment file: \(segmentFileName) (frames: \(actualFrameCount))")
        return segmentURL
    }
    
    // MARK: - Database Updates (MainActor with ModelContext)
    
    /// Updates session with processing results on MainActor
    @MainActor
    private func updateSessionWithResult(_ result: ProcessingResult, modelContext: ModelContext) async {
        print("ProcessingCoordinator: Updating session with results on MainActor")
        
        // Find the session by ID - Fix predicate issue
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
        
        if result.success {
            print("ProcessingCoordinator: Processing succeeded, updating session")
            
            // Create segments if they don't exist
            if session.segments.isEmpty {
                print("ProcessingCoordinator: Creating \(result.segmentResults.count) segments")
                
                for segmentData in result.segmentResults {
                    let segment = TranscriptionSegment(
                        startTime: segmentData.startTime,
                        transcriptionText: segmentData.transcription ?? "",
                        status: segmentData.status
                    )
                    
                    segment.session = session
                    session.segments.append(segment)
                    modelContext.insert(segment)
                }
            } else {
                // Update existing segments
                print("ProcessingCoordinator: Updating \(session.segments.count) existing segments")
                
                for segmentData in result.segmentResults {
                    if segmentData.index < session.segments.count {
                        let segment = session.segments[segmentData.index]
                        segment.transcriptionText = segmentData.transcription ?? (segmentData.errorMessage ?? "Transcription failed")
                        segment.status = segmentData.status
                    }
                }
            }
            
            // Update session duration
            session.duration = result.totalDuration
            
            // Create combined transcription text for logging
            let completedSegments = session.sortedSegments.filter { $0.status == .completed }
            let combinedTranscription = completedSegments
                .compactMap { $0.transcriptionText }
                .joined(separator: " ")
            
            print("ProcessingCoordinator: Combined transcription (\(combinedTranscription.count) characters)")
            if !combinedTranscription.isEmpty {
                print("ProcessingCoordinator: Preview: \(String(combinedTranscription.prefix(100)))...")
            }
            
        } else {
            // Handle error case
            print("ProcessingCoordinator: Processing failed: \(result.errorMessage ?? "Unknown error")")
            
            // Create error segments if none exist
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
                // Mark existing segments as failed
                for segment in session.segments {
                    if segment.status != .completed {
                        segment.status = .failed
                        segment.transcriptionText = "Processing failed: \(result.errorMessage ?? "Unknown error")"
                    }
                }
            }
        }
        
        // Update session processing state
        session.isProcessing = false
        
        // Save all changes
        do {
            try modelContext.save()
            print("ProcessingCoordinator: Session updated and saved successfully")
        } catch {
            print("ProcessingCoordinator: Failed to save session updates: \(error.localizedDescription)")
        }
    }
}
