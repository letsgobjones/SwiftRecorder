//
//  StorageManager.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI
import SwiftData
import Foundation

@Observable
class StorageManager {
    
    // MARK: - Storage Properties
    var totalStorageUsed: Int64 = 0 // Bytes
    var totalFiles: Int = 0
    var oldestFileDate: Date?
    var newestFileDate: Date?
    var storageWarningThreshold: Int64 = 1_000_000_000 // 1GB in bytes
    var isCleaningUp: Bool = false
    
    // MARK: - Computed Properties
    var storageUsedMB: Double {
        return Double(totalStorageUsed) / (1024 * 1024)
    }
    
    var storageUsedGB: Double {
        return Double(totalStorageUsed) / (1024 * 1024 * 1024)
    }
    
    var isNearStorageLimit: Bool {
        return totalStorageUsed > storageWarningThreshold
    }
    
    var storageStatus: StorageStatus {
        let usedGB = storageUsedGB
        if usedGB < 0.1 { return .low }
        else if usedGB < 0.5 { return .medium }
        else if usedGB < 1.0 { return .high }
        else { return .critical }
    }
    
    // MARK: - Private Properties
    private let documentsDirectory: URL
    private let fileManager = FileManager.default
    
    // MARK: - Initialization
    init() {
        self.documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print("StorageManager: Initialized")
        
        // Calculate initial storage usage
        Task {
            await calculateStorageUsage()
        }
    }
    
    // MARK: - Public Interface
    
    /// Calculates total storage usage for audio files
    @MainActor
    func calculateStorageUsage() async {
        print("StorageManager: Calculating storage usage")
        
        let usage = await withTaskGroup(of: FileInfo?.self) { group in
            do {
                let audioFiles = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey])
                    .filter { $0.pathExtension.lowercased() == "m4a" }
                
                for fileURL in audioFiles {
                    group.addTask {
                        return await self.getFileInfo(url: fileURL)
                    }
                }
                
                var totalSize: Int64 = 0
                var fileCount: Int = 0
                var dates: [Date] = []
                
                for await fileInfo in group {
                    if let info = fileInfo {
                        totalSize += info.size
                        fileCount += 1
                        dates.append(info.creationDate)
                    }
                }
                
                return StorageInfo(
                    totalSize: totalSize,
                    fileCount: fileCount,
                    oldestDate: dates.min(),
                    newestDate: dates.max()
                )
                
            } catch {
                print("StorageManager: Error calculating storage: \(error.localizedDescription)")
                return StorageInfo(totalSize: 0, fileCount: 0, oldestDate: nil, newestDate: nil)
            }
        }
        
        // Update properties on main actor
        totalStorageUsed = usage.totalSize
        totalFiles = usage.fileCount
        oldestFileDate = usage.oldestDate
        newestFileDate = usage.newestDate
        
        print("StorageManager: Storage calculated - \(storageUsedMB) MB across \(totalFiles) files")
    }
    
    /// Cleans up orphaned audio files that don't have corresponding database entries
    @MainActor
    func cleanupOrphanedFiles(modelContext: ModelContext) async {
        guard !isCleaningUp else {
            print("StorageManager: Cleanup already in progress")
            return
        }
        
        isCleaningUp = true
        print("StorageManager: Starting orphaned file cleanup")
        
        do {
            // Get all audio files in documents directory
            let audioFiles = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension.lowercased() == "m4a" }
            
            // Get all audio file paths from database
            let descriptor = FetchDescriptor<RecordingSession>()
            let sessions = try modelContext.fetch(descriptor)
            let databasePaths = Set(sessions.map { $0.audioFilePath })
            
            var cleanedCount = 0
            var cleanedSize: Int64 = 0
            
            for fileURL in audioFiles {
                let fileName = fileURL.lastPathComponent
                
                // Check if this file exists in database
                if !databasePaths.contains(fileName) {
                    // This is an orphaned file
                    do {
                        let fileSize = try getFileSize(url: fileURL)
                        try fileManager.removeItem(at: fileURL)
                        cleanedCount += 1
                        cleanedSize += fileSize
                        print("StorageManager: Removed orphaned file: \(fileName) (\(fileSize) bytes)")
                    } catch {
                        print("StorageManager: Failed to remove orphaned file \(fileName): \(error.localizedDescription)")
                    }
                }
            }
            
            print("StorageManager: Cleanup complete - removed \(cleanedCount) files, freed \(Double(cleanedSize) / (1024 * 1024)) MB")
            
            // Recalculate storage after cleanup
            await calculateStorageUsage()
            
        } catch {
            print("StorageManager: Cleanup failed: \(error.localizedDescription)")
        }
        
        isCleaningUp = false
    }
    
    /// Removes old files based on age (keeps files newer than specified days)
    @MainActor
    func cleanupOldFiles(olderThanDays days: Int, modelContext: ModelContext) async {
        guard !isCleaningUp else {
            print("StorageManager: Cleanup already in progress")
            return
        }
        
        isCleaningUp = true
        print("StorageManager: Starting cleanup of files older than \(days) days")
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        do {
            let descriptor = FetchDescriptor<RecordingSession>(
                predicate: #Predicate { session in
                    session.createdAt < cutoffDate
                },
                sortBy: [SortDescriptor(\.createdAt)]
            )
            
            let oldSessions = try modelContext.fetch(descriptor)
            var cleanedCount = 0
            var cleanedSize: Int64 = 0
            
            for session in oldSessions {
                do {
                    let fileURL = documentsDirectory.appendingPathComponent(session.audioFilePath)
                    let fileSize = try getFileSize(url: fileURL)
                    
                    // Remove file
                    try fileManager.removeItem(at: fileURL)
                    
                    // Remove from database
                    modelContext.delete(session)
                    
                    cleanedCount += 1
                    cleanedSize += fileSize
                    
                    print("StorageManager: Removed old session: \(session.audioFilePath)")
                    
                } catch {
                    print("StorageManager: Failed to remove old session \(session.audioFilePath): \(error.localizedDescription)")
                }
            }
            
            // Save database changes
            try modelContext.save()
            
            print("StorageManager: Old file cleanup complete - removed \(cleanedCount) sessions, freed \(Double(cleanedSize) / (1024 * 1024)) MB")
            
            // Recalculate storage after cleanup
            await calculateStorageUsage()
            
        } catch {
            print("StorageManager: Old file cleanup failed: \(error.localizedDescription)")
        }
        
        isCleaningUp = false
    }
    
    /// Removes files to free up a specific amount of storage (removes oldest first)
    @MainActor
    func freeUpStorage(targetMB: Double, modelContext: ModelContext) async {
        guard !isCleaningUp else {
            print("StorageManager: Cleanup already in progress")
            return
        }
        
        isCleaningUp = true
        let targetBytes = Int64(targetMB * 1024 * 1024)
        print("StorageManager: Attempting to free up \(targetMB) MB of storage")
        
        do {
            let descriptor = FetchDescriptor<RecordingSession>(
                sortBy: [SortDescriptor(\.createdAt)] // Oldest first
            )
            
            let sessions = try modelContext.fetch(descriptor)
            var freedBytes: Int64 = 0
            var removedCount = 0
            
            for session in sessions {
                guard freedBytes < targetBytes else { break }
                
                do {
                    let fileURL = documentsDirectory.appendingPathComponent(session.audioFilePath)
                    let fileSize = try getFileSize(url: fileURL)
                    
                    // Remove file
                    try fileManager.removeItem(at: fileURL)
                    
                    // Remove from database
                    modelContext.delete(session)
                    
                    freedBytes += fileSize
                    removedCount += 1
                    
                    print("StorageManager: Removed session to free space: \(session.audioFilePath)")
                    
                } catch {
                    print("StorageManager: Failed to remove session \(session.audioFilePath): \(error.localizedDescription)")
                }
            }
            
            // Save database changes
            try modelContext.save()
            
            print("StorageManager: Storage cleanup complete - removed \(removedCount) sessions, freed \(Double(freedBytes) / (1024 * 1024)) MB")
            
            // Recalculate storage after cleanup
            await calculateStorageUsage()
            
        } catch {
            print("StorageManager: Storage cleanup failed: \(error.localizedDescription)")
        }
        
        isCleaningUp = false
    }
    
    // MARK: - Private Methods
    
    private func getFileInfo(url: URL) async -> FileInfo? {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
            let size = Int64(resourceValues.fileSize ?? 0)
            let creationDate = resourceValues.creationDate ?? Date()
            
            return FileInfo(size: size, creationDate: creationDate)
        } catch {
            print("StorageManager: Failed to get file info for \(url.lastPathComponent): \(error.localizedDescription)")
            return nil
        }
    }
    
    private func getFileSize(url: URL) throws -> Int64 {
        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(resourceValues.fileSize ?? 0)
    }
}

