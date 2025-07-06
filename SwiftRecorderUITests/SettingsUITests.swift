//
//  SettingsUITests.swift
//  SwiftRecorderUITests
//
//  Created by Brandon Jones on 7/6/25.
//

import XCTest

final class SettingsUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        // Navigate to settings
        app.buttons["Settings"].tap()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    func testProviderSelection() {
        // Look for provider selection elements
        let appleProvider = app.buttons["Apple Speech Recognition"]
        let googleProvider = app.buttons["Google Speech-to-Text"]
        let openAIProvider = app.buttons["OpenAI Whisper"]
        
        // At least one provider should be selectable
        XCTAssertTrue(appleProvider.exists || googleProvider.exists || openAIProvider.exists)
        
        // Test selecting Apple provider (should always be available)
        if appleProvider.exists {
            appleProvider.tap()
            // Apple provider should be selected (you'd check for selection indicator)
        }
    }
    
    func testAPIKeyEntry() {
        // Look for API key text fields
        let apiKeyFields = app.textFields.matching(identifier: "API Key")
        
        if apiKeyFields.count > 0 {
            let firstField = apiKeyFields.firstMatch
            
            // When
            firstField.tap()
            firstField.typeText("test-api-key-12345")
            
            // Then
            XCTAssertEqual(firstField.value as? String, "test-api-key-12345")
            
            // Look for save button
            let saveButton = app.buttons["Save"]
            if saveButton.exists {
                XCTAssertTrue(saveButton.isEnabled)
            }
        }
    }
    
    func testAPIKeyValidation() {
        let apiKeyFields = app.textFields.matching(identifier: "API Key")
        
        if apiKeyFields.count > 0 {
            let firstField = apiKeyFields.firstMatch
            
            // Test empty key validation
            firstField.tap()
            firstField.clearAndEnterText("")
            
            let saveButton = app.buttons["Save"]
            if saveButton.exists {
                // Save button should be disabled for empty key
                XCTAssertFalse(saveButton.isEnabled)
            }
        }
    }
    
    func testNavigationBackToMain() {
        // When
        let backButton = app.navigationBars.buttons.firstMatch
        backButton.tap()
        
        // Then
        XCTAssertTrue(app.navigationBars["Recordings"].exists)
    }
}

// MARK: - XCUIElement Extension for Better Testing
extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard self.value != nil else {
            XCTFail("Tried to clear and enter text into a non-text element")
            return
        }
        
        self.tap()
        self.press(forDuration: 1.0)
        
        let selectAll = XCUIApplication().menuItems["Select All"]
        if selectAll.exists {
            selectAll.tap()
        }
        
        self.typeText(text)
    }
}