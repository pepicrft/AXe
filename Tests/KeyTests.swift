import Testing
import Foundation

@Suite("Key Command Tests")
struct KeyTests {
    @Test("Basic key press", arguments: [
        (code: 4, key: "a"),
        (code: 22, key: "s"),
        (code: 7, key: "d"),
        (code: 9, key: "f")
    ])
    func basicKeyPress(_ key: (code: Int, key: String)) async throws {
        // Arrange
        try await TestHelpers.launchPlaygroundApp(to: "key-press")
        
        // Act
        try await TestHelpers.runAxeCommand("key \(key.code)", simulatorUDID: defaultSimulatorUDID)
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Assert
        let uiState = try await TestHelpers.getUIState()
        let keyPressElement = UIStateParser.findElementContainingLabel(in: uiState, containing: "Last Key:")
        #expect(keyPressElement?.label == "Last Key: \(key.key) (\(key.code))")
    }

    @Test(
        "Special keys",
        arguments: [
            (code: 43, key: "Tab"),
            (code: 44, key: "Space"),
            (code: 42, key: "Backspace"),
            (code: 40, key: "Return")
        ]
    )
    func specialKeys(_ key: (code: Int, key: String)) async throws {        
        // Arrange
        try await TestHelpers.launchPlaygroundApp(to: "key-press")
        
        // Act
        try await TestHelpers.runAxeCommand("key \(key.code)", simulatorUDID: defaultSimulatorUDID)
        try await Task.sleep(nanoseconds: 1_000_000_000)    

        // Assert
        let uiState = try await TestHelpers.getUIState()
        let keyPressElement = UIStateParser.findElementContainingLabel(in: uiState, containing: "Last Key:")
        #expect(keyPressElement?.label == "Last Key: \(key.key) (\(key.code))")
    }

    @Test(
        "Number keys",
        arguments: [
            (code: 30, key: "1"),
            (code: 31, key: "2"),
            (code: 32, key: "3"),
            (code: 33, key: "4"),
            (code: 34, key: "5"),
            (code: 35, key: "6"),
            (code: 36, key: "7"),
            (code: 37, key: "8"),
            (code: 38, key: "9"),
            (code: 39, key: "0")
        ]
    )
    func numberKey(_ key: (code: Int, key: String)) async throws {
        // Arrange
        try await TestHelpers.launchPlaygroundApp(to: "key-press")
        
        // Act
        try await TestHelpers.runAxeCommand("key \(key.code)", simulatorUDID: defaultSimulatorUDID)
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Assert
        let uiState = try await TestHelpers.getUIState()
        let keyPressElement = UIStateParser.findElementContainingLabel(in: uiState, containing: "Last Key:")
        #expect(keyPressElement?.label == "Last Key: \(key.key) (\(key.code))")
    }
    
    @Test("Arrow keys", arguments: [
        (code: 80, key: "Left Arrow"),
        (code: 79, key: "Right Arrow"),
        (code: 81, key: "Down Arrow"),
        (code: 82, key: "Up Arrow")
    ])
    func arrowKeys(_ key: (code: Int, key: String)) async throws {
        // Arrange
        try await TestHelpers.launchPlaygroundApp(to: "key-press")
        
        // Act
        try await TestHelpers.runAxeCommand("key \(key.code)", simulatorUDID: defaultSimulatorUDID)
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Assert
        let uiState = try await TestHelpers.getUIState()
        let keyPressElement = UIStateParser.findElementContainingLabel(in: uiState, containing: "Last Key:")
        #expect(keyPressElement?.label == "Last Key: \(key.key) (\(key.code))")
    }       
    
    @Test("Function keys", arguments: [
        (code: 58, key: "F1"),
        (code: 59, key: "F2"),
        (code: 60, key: "F3"),
        (code: 61, key: "F4")
    ])
    func functionKeys(_ key: (code: Int, key: String)) async throws {
        // Arrange
        try await TestHelpers.launchPlaygroundApp(to: "key-press")
        
        // Act
        try await TestHelpers.runAxeCommand("key \(key.code)", simulatorUDID: defaultSimulatorUDID)
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Assert
        let uiState = try await TestHelpers.getUIState()
        let keyPressElement = UIStateParser.findElementContainingLabel(in: uiState, containing: "Last Key:")
        #expect(keyPressElement?.label == "Last Key: \(key.key) (\(key.code))")
    }
    
    @Test("Key press with duration")
    func keyPressWithDelays() async throws {
        // Arrange
        try await TestHelpers.launchPlaygroundApp(to: "key-press")
        
        // Act
        let startTime = Date()
        try await TestHelpers.runAxeCommand("key 4 --duration 2", simulatorUDID: defaultSimulatorUDID)
        let endTime = Date()
        
        // Assert
        let duration = endTime.timeIntervalSince(startTime)
        #expect(duration >= 2.0, "Command should take at least 2 seconds with delays")
        
        let uiState = try await TestHelpers.getUIState()
        let keyPressElement = UIStateParser.findElementContainingLabel(in: uiState, containing: "Last Key:")
        #expect(keyPressElement?.label == "Last Key: a (4)")
    }
}
