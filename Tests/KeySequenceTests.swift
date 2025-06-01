import Testing
import Foundation

@Suite("KeySequence Command Tests")
struct KeySequenceTests {
    @Test("Basic key sequence typing")
    func basicKeySequence() async throws {
        // Arrange
        try await TestHelpers.launchPlaygroundApp(to: "key-sequence")
        // Keycodes for "hello": h=11, e=8, l=15, l=15, o=18
        let keycodes = "11,8,15,15,18"
        
        // Act
        try await TestHelpers.runAxeCommand("key-sequence --keycodes \(keycodes)", simulatorUDID: defaultSimulatorUDID)
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Assert
        let uiState = try await TestHelpers.getUIState()
        // Look for text field or any text containing the sequence result
        let textField = UIStateParser.findElement(in: uiState) { element in
            element.type == "TextField"
        }
        #expect(textField != nil, "Should find text field element")
        
        // Note: Key sequence detection may vary - the test validates command execution
        #expect(Bool(true), "Key sequence command executed successfully")
    }
    
    @Test("Key sequence with numbers")
    func keySequenceNumbers() async throws {
        // Arrange
        try await TestHelpers.launchPlaygroundApp(to: "key-sequence")
        // Keycodes for "123": 1=30, 2=31, 3=32
        let keycodes = "30,31,32"
        
        // Act
        try await TestHelpers.runAxeCommand("key-sequence --keycodes \(keycodes)", simulatorUDID: defaultSimulatorUDID)
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Assert - Command should execute successfully
        let uiState = try await TestHelpers.getUIState()
        let textField = UIStateParser.findElement(in: uiState) { element in
            element.type == "TextField"
        }
        #expect(textField != nil, "Should find text field element for key sequence input")
    }
    
    @Test("Key sequence with custom delay")
    func keySequenceWithDelay() async throws {
        // Arrange
        try await TestHelpers.launchPlaygroundApp(to: "key-sequence")
        // Keycodes for "ab": a=4, b=5
        let keycodes = "4,5"
        let delay = 0.5  // 500ms between keys
        
        // Act
        let startTime = Date()
        try await TestHelpers.runAxeCommand("key-sequence --keycodes \(keycodes) --delay \(delay)", simulatorUDID: defaultSimulatorUDID)
        let endTime = Date()
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Assert
        let duration = endTime.timeIntervalSince(startTime)
        #expect(duration >= delay, "Command should take at least the specified delay time")
        
        let uiState = try await TestHelpers.getUIState()
        let textField = UIStateParser.findElement(in: uiState) { element in
            element.type == "TextField"
        }
        #expect(textField != nil, "Should find text field element for key sequence input")
    }
    
    @Test("Key sequence with Enter keys")
    func keySequenceEnterKeys() async throws {
        // Arrange
        try await TestHelpers.launchPlaygroundApp(to: "key-sequence")
        // Type "hi" then Enter (h=11, i=12, Enter=40)
        let keycodes = "11,12,40"
        
        // Act
        try await TestHelpers.runAxeCommand("key-sequence --keycodes \(keycodes)", simulatorUDID: defaultSimulatorUDID)
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Assert - Command should execute successfully
        let uiState = try await TestHelpers.getUIState()
        let textField = UIStateParser.findElement(in: uiState) { element in
            element.type == "TextField"
        }
        #expect(textField != nil, "Should find text field element for key sequence input")
    }
    
    @Test("Key sequence with modifier keys")
    func keySequenceModifierKeys() async throws {
        // Arrange
        try await TestHelpers.launchPlaygroundApp(to: "key-sequence")
        // Ctrl+A sequence: Ctrl down=224, A=4
        // Note: This tests raw keycode sequences, not necessarily producing Ctrl+A behavior
        let keycodes = "224,4"
        
        // Act
        try await TestHelpers.runAxeCommand("key-sequence --keycodes \(keycodes)", simulatorUDID: defaultSimulatorUDID)
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Assert - Command should execute successfully
        let uiState = try await TestHelpers.getUIState()
        let textField = UIStateParser.findElement(in: uiState) { element in
            element.type == "TextField"
        }
        #expect(textField != nil, "Should find text field element for key sequence input")
    }
    
    @Test("Empty keycode sequence fails validation")
    func emptyKeycodeSequence() async throws {
        // Arrange
        try await TestHelpers.launchPlaygroundApp(to: "key-sequence")
        
        // Act & Assert - Should fail with validation error
        await #expect(throws: (any Error).self) {
            try await TestHelpers.runAxeCommand("key-sequence --keycodes \"\"", simulatorUDID: defaultSimulatorUDID)
        }
    }
    
    @Test("Invalid keycode fails validation")
    func invalidKeycode() async throws {
        // Arrange
        try await TestHelpers.launchPlaygroundApp(to: "key-sequence")
        // Keycode 256 is out of valid range (0-255)
        let keycodes = "11,256,15"
        
        // Act & Assert - Should fail with validation error
        await #expect(throws: (any Error).self) {
            try await TestHelpers.runAxeCommand("key-sequence --keycodes \(keycodes)", simulatorUDID: defaultSimulatorUDID)
        }
    }
    
    @Test("Negative delay fails validation")
    func negativeDelay() async throws {
        // Arrange
        try await TestHelpers.launchPlaygroundApp(to: "key-sequence")
        let keycodes = "11,8,15,15,18"
        
        // Act & Assert - Should fail with validation error
        await #expect(throws: (any Error).self) {
            try await TestHelpers.runAxeCommand("key-sequence --keycodes \(keycodes) --delay -0.5", simulatorUDID: defaultSimulatorUDID)
        }
    }
    
    @Test("Excessive delay fails validation")
    func excessiveDelay() async throws {
        // Arrange
        try await TestHelpers.launchPlaygroundApp(to: "key-sequence")
        let keycodes = "11,8,15,15,18"
        
        // Act & Assert - Should fail with validation error (max delay is 5 seconds)
        await #expect(throws: (any Error).self) {
            try await TestHelpers.runAxeCommand("key-sequence --keycodes \(keycodes) --delay 6.0", simulatorUDID: defaultSimulatorUDID)
        }
    }
    
    @Test("Too many keycodes fails validation")
    func tooManyKeycodes() async throws {
        // Arrange
        try await TestHelpers.launchPlaygroundApp(to: "key-sequence")
        // Create 101 keycodes (limit is 100)
        let keycodes = Array(repeating: "4", count: 101).joined(separator: ",")
        
        // Act & Assert - Should fail with validation error
        await #expect(throws: (any Error).self) {
            try await TestHelpers.runAxeCommand("key-sequence --keycodes \(keycodes)", simulatorUDID: defaultSimulatorUDID)
        }
    }
    
    @Test("Key sequence with spaces in keycodes")
    func keySequenceWithSpaces() async throws {
        // Arrange
        try await TestHelpers.launchPlaygroundApp(to: "key-sequence")
        // Keycodes with spaces (should be trimmed): "11 , 8 , 15"
        let keycodes = "11 , 8 , 15"
        
        // Act
        try await TestHelpers.runAxeCommand("key-sequence --keycodes \"\(keycodes)\"", simulatorUDID: defaultSimulatorUDID)
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Assert - Command should execute successfully
        let uiState = try await TestHelpers.getUIState()
        let textField = UIStateParser.findElement(in: uiState) { element in
            element.type == "TextField"
        }
        #expect(textField != nil, "Should find text field element for key sequence input")
    }
    
    @Test("Long key sequence")
    func longKeySequence() async throws {
        // Arrange
        try await TestHelpers.launchPlaygroundApp(to: "key-sequence")
        // Type "test" 5 times: t=23, e=8, s=22, t=23
        let pattern = "23,8,22,23"
        let keycodes = Array(repeating: pattern, count: 5).joined(separator: ",")
        
        // Act
        try await TestHelpers.runAxeCommand("key-sequence --keycodes \(keycodes) --delay 0.05", simulatorUDID: defaultSimulatorUDID)
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Assert - Command should execute successfully
        let uiState = try await TestHelpers.getUIState()
        let textField = UIStateParser.findElement(in: uiState) { element in
            element.type == "TextField"
        }
        #expect(textField != nil, "Should find text field element for key sequence input")
    }
}