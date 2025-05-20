import ArgumentParser
import Foundation
import FBControlCore
import FBSimulatorControl

struct Type: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Type text by entering a sequence of characters.",
        discussion: """
        Input Methods:
        1. Direct text: -t "Hello World" (use single quotes for special chars: -t 'Hello!')
        2. From stdin: echo "Hello World!" | axe type --stdin --udid UDID
        3. From file: axe type --file text.txt --udid UDID
        
        Shell Escaping Tips:
        • Use single quotes for text with special characters: 'Hello!'
        • Use double quotes for simple text: "Hello World"
        • For automation, prefer --stdin or --file methods
        """
    )
    
    @Option(name: .customShort("t"), help: "The text to type. Use single quotes for special characters.")
    var text: String?
    
    @Flag(name: .customLong("stdin"), help: "Read text from standard input.")
    var useStdin: Bool = false
    
    @Option(name: .customLong("file"), help: "Read text from the specified file.")
    var inputFile: String?
    
    @Option(name: .customLong("udid"), help: "The UDID of the simulator.")
    var simulatorUDID: String

    func run() async throws {
        let logger = AxeLogger()
        try await setup(logger: logger)
        
        try await performGlobalSetup(logger: logger)
        
        // Determine input source and get text
        let inputText: String
        
        switch (text, useStdin, inputFile) {
        case (let directText?, false, nil):
            // Direct text input
            inputText = directText
            logger.info().log("Using direct text input: '\(inputText)'")
            
        case (nil, true, nil):
            // Read from stdin
            logger.info().log("Reading text from standard input...")
            inputText = readFromStdin()
            logger.info().log("Read from stdin: '\(inputText)'")
            
        case (nil, false, let file?):
            // Read from file
            logger.info().log("Reading text from file: \(file)")
            inputText = try readFromFile(file)
            logger.info().log("Read from file: '\(inputText)'")
            
        case (nil, false, nil):
            // No input provided
            throw ValidationError("No input provided. Use -t, --stdin, or --file.")
            
        default:
            // Multiple input sources provided
            throw ValidationError("Please specify only one input source: -t, --stdin, or --file.")
        }
        
        // Validate text first
        guard TextToHIDEvents.validateText(inputText) else {
            // Find unsupported characters for detailed error message
            let unsupportedChars = inputText.compactMap { char in
                let keyEvent = KeyEvent.keyCodeForString(String(char))
                return keyEvent.keyCode == 0 ? char : nil
            }
            let errorMessage = "Unsupported characters found: \(unsupportedChars.map { "'\($0)'" }.joined(separator: ", "))"
            logger.error().log(errorMessage)
            throw TextToHIDEvents.TextConversionError.unsupportedCharacter(unsupportedChars.first!)
        }
        
        // Convert text to HID events using the new utility
        let hidEvents: [FBSimulatorHIDEvent]
        do {
            hidEvents = try TextToHIDEvents.convertTextToHIDEvents(inputText)
            logger.info().log("Successfully converted text to \(hidEvents.count) HID events")
        } catch let error as TextToHIDEvents.TextConversionError {
            logger.error().log("Text conversion failed: \(error.localizedDescription)")
            throw error
        } catch {
            logger.error().log("Unexpected error during text conversion: \(error.localizedDescription)")
            throw error
        }
        
        logger.info().log("Performing HID event sequence for text typing")
        
        // Perform HID events sequentially
        for event in hidEvents {
        try await HIDInteractor
            .performHIDEvent(
                event,
                for: simulatorUDID,
                logger: logger
            )
        }
        
        logger.info().log("Text typing completed successfully")
    }
    
    // MARK: - Input Methods
    
    private func readFromStdin() -> String {
        var input = ""
        while let line = readLine() {
            if !input.isEmpty {
                input += "\n"
            }
            input += line
        }
        return input
    }
    
    private func readFromFile(_ filePath: String) throws -> String {
        do {
            return try String(contentsOfFile: filePath, encoding: .utf8)
        } catch {
            throw ValidationError("Failed to read file '\(filePath)': \(error.localizedDescription)")
        }
    }
}
