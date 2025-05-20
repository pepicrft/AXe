import ArgumentParser
import Foundation
import FBControlCore
import FBSimulatorControl

struct Tap: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Tap on a specific point on the screen."
    )
    
    @Option(name: .customShort("x"), help: "The X coordinate of the point to tap.")
    var pointX: Double
    
    @Option(name: .customShort("y"), help: "The Y coordinate of the point to tap.")
    var pointY: Double
    
    @Option(name: .customLong("pre-delay"), help: "Delay before tapping in seconds.")
    var preDelay: Double?
    
    @Option(name: .customLong("post-delay"), help: "Delay after tapping in seconds.")
    var postDelay: Double?
    
    @Option(name: .customLong("udid"), help: "The UDID of the simulator.")
    var simulatorUDID: String

    func validate() throws {
        // Validate coordinates are non-negative
        guard pointX >= 0, pointY >= 0 else {
            throw ValidationError("Coordinates must be non-negative values.")
        }
        
        // Validate delays if provided
        if let preDelay = preDelay {
            guard preDelay >= 0 && preDelay <= 10.0 else {
                throw ValidationError("Pre-delay must be between 0 and 10 seconds.")
            }
        }
        
        if let postDelay = postDelay {
            guard postDelay >= 0 && postDelay <= 10.0 else {
                throw ValidationError("Post-delay must be between 0 and 10 seconds.")
            }
        }
    }

    func run() async throws {
        let logger = AxeLogger()
        try await setup(logger: logger)
        
        try await performGlobalSetup(logger: logger)

        logger.info().log("Tapping at (\(pointX), \(pointY))")
        
        // Create tap events with timing controls
        var events: [FBSimulatorHIDEvent] = []
        
        // Add pre-delay if specified
        if let preDelay = preDelay, preDelay > 0 {
            logger.info().log("Pre-delay: \(preDelay)s")
            events.append(FBSimulatorHIDEvent.delay(preDelay))
        }
        
        // Add the main tap event
        let tapEvent = FBSimulatorHIDEvent.tapAt(x: pointX, y: pointY)
        events.append(tapEvent)
        
        // Add post-delay if specified
        if let postDelay = postDelay, postDelay > 0 {
            logger.info().log("Post-delay: \(postDelay)s")
            events.append(FBSimulatorHIDEvent.delay(postDelay))
        }
        
        // Execute the tap sequence
        let finalEvent = events.count == 1 ? events[0] : FBSimulatorHIDEvent(events: events)
        
        // Perform the tap event
        try await HIDInteractor
            .performHIDEvent(
                finalEvent,
                for: simulatorUDID,
                logger: logger
            )
        
        logger.info().log("Tap completed successfully")
    }
}
