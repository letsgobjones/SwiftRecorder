//
//  SwiftRecorderUITests.swift
//  SwiftRecorderUITests
//
//  Created by Brandon Jones on 7/6/25.
//

import XCTest

final class SwiftRecorderUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    func testMainScreenElements() {
        // Test that main screen loads properly
        XCTAssertTrue(app.navigationBars["Recordings"].exists)
        
        // Check for settings button
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.exists)
        
        // Check for recording button (might be in different states)
        let recordingButtons = app.buttons.matching(identifier: "Start Recording")
        XCTAssertTrue(recordingButtons.count > 0 || app.buttons["Stop Recording"].exists)
    }
    
    func testNavigationToSettings() {
        // When
        app.buttons["Settings"].tap()
        
        // Then
        XCTAssertTrue(app.navigationBars["Settings"].exists)
        
        // Check for provider selection
        XCTAssertTrue(app.staticTexts["Transcription Provider"].exists)
        
        // Check for API key sections
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Google'")).count > 0)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'OpenAI'")).count > 0)
    }
    
    func testRecordingFlow() {
        // Note: This test requires microphone permissions
        // You might want to handle permission prompts in setup
        
        let recordButton = app.buttons["Start Recording"]
        
        if recordButton.exists {
            // When
            recordButton.tap()
            
            // Then - button should change to stop recording
            let stopButton = app.buttons["Stop Recording"]
            XCTAssertTrue(stopButton.waitForExistence(timeout: 2.0))
            
            // Stop recording after a short time
            stopButton.tap()
            
            // Should return to start recording state
            XCTAssertTrue(recordButton.waitForExistence(timeout: 2.0))
        }
    }
    
    func testSessionDetailNavigation() {
        // This test assumes there are existing sessions
        // You might need to create test data first
        
        let sessionCells = app.cells
        
        if sessionCells.count > 0 {
            // When
            sessionCells.firstMatch.tap()
            
            // Then
            XCTAssertTrue(app.navigationBars["Recording Details"].exists)
            
            // Check for session details
            XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Duration'")).count > 0)
            
            // Check for transcription section
            XCTAssertTrue(app.staticTexts["Transcription Segments"].exists ||
                         app.staticTexts["No transcription segments available."].exists)
        }
    }
    
    func testEmptyStateDisplay() {
        // This test works when there are no recordings
        let emptyStateText = app.staticTexts["No Recordings Yet"]
        
        if emptyStateText.exists {
            XCTAssertTrue(emptyStateText.exists)
            XCTAssertTrue(app.images.count > 0) // Should have an icon
        }
    }
}