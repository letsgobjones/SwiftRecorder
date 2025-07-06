//
//  PerformanceManager.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import SwiftUI
import Foundation
import UIKit // Needed for memory warning notification

@Observable
class PerformanceManager {
    
    // MARK: - Performance Metrics
    var memoryUsageMB: Double = 0
    var isMemoryWarning: Bool = false
    
    // This now acts as a configuration setting that other parts of the app can read.
    var maxConcurrentOperations: Int = 3
    
    // MARK: - Private Properties
    private var memoryMonitorTask: Task<Void, Never>?
    private var memoryWarningTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init() {
        startMemoryMonitoring()
        setupMemoryWarningListener()
        print("PerformanceManager: Initialized with modern async monitoring.")
    }
    
    deinit {
        memoryMonitorTask?.cancel()
        memoryWarningTask?.cancel()
        print("PerformanceManager: Deinitialized and tasks cancelled.")
    }
    
    // MARK: - Public Interface
    
    /// Adjusts performance settings based on current memory usage.
    /// The manager now adjusts its own state, and other services can react to it.
    @MainActor
    func optimizeForMemoryPressure() {
        print("PerformanceManager: Optimizing for memory pressure.")
        
        if isMemoryWarning {
            // Reduce the recommended number of concurrent operations.
            maxConcurrentOperations = 1
            print("PerformanceManager: Recommended concurrent operations reduced to 1 due to memory pressure.")
        } else {
            // Restore normal operations.
            maxConcurrentOperations = 3 // Or a user-configurable value
            print("PerformanceManager: Restored normal concurrent operations: \(maxConcurrentOperations)")
        }
    }
    
    // MARK: - Private Methods
    
    /// Starts a task to periodically update the app's memory usage.
    private func startMemoryMonitoring() {
        memoryMonitorTask = Task(priority: .background) {
            while !Task.isCancelled {
                let usage = getMemoryUsage()
                
                await MainActor.run {
                    self.memoryUsageMB = usage
                    
                    // Check against a custom threshold (e.g., 200MB)
                    let wasWarning = self.isMemoryWarning
                    self.isMemoryWarning = usage > 200
                    
                    if self.isMemoryWarning && !wasWarning {
                        print("PerformanceManager: Memory warning triggered at \(usage) MB")
                        self.optimizeForMemoryPressure()
                    } else if !self.isMemoryWarning && wasWarning {
                        print("PerformanceManager: Memory pressure relieved")
                        self.optimizeForMemoryPressure()
                    }
                }
                
                // Check memory usage every 5 seconds.
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }
    
    /// Sets up a modern async listener for system memory warnings.
    private func setupMemoryWarningListener() {
        memoryWarningTask = Task {
            for await _ in NotificationCenter.default.notifications(named: UIApplication.didReceiveMemoryWarningNotification) {
                print("PerformanceManager: System memory warning received")
                await handleSystemMemoryWarning()
            }
        }
    }
    
    @MainActor
    private func handleSystemMemoryWarning() {
        isMemoryWarning = true
        optimizeForMemoryPressure()
    }
    
    /// Uses low-level APIs to get the app's current memory usage in megabytes.
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            return Double(info.resident_size) / (1024 * 1024) // Convert to MB
        } else {
            return 0
        }
    }
}
