import Foundation
import FBControlCore
import FBSimulatorControl

// MARK: - Accessibility Fetcher
@MainActor
struct AccessibilityFetcher {
    static func fetchAccessibilityInfo(for simulatorUDID: String, logger: AxeLogger) async throws {
        logger.info().log("Accessibility Info Fetcher started for simulator UDID: \(simulatorUDID)")

        let simulatorSet = try await getSimulatorSet(deviceSetPath: nil, logger: logger, reporter: EmptyEventReporter.shared)
        logger.info().log("FBSimulatorSet obtained.")

        guard let target = simulatorSet.allSimulators.first(where: { $0.udid == simulatorUDID }) else {
            throw CLIError(errorDescription: "Simulator with UDID \(simulatorUDID) not found in set.")
        }
        logger.info().log("Target (FBSimulator) obtained: \(target.udid) - \(target.name), State: \(FBiOSTargetStateStringFromState(target.state))")

        logger.info().log("Fetching accessibility info directly from FBSimulator...")
        // FBSimulator conforms to FBAccessibilityCommands, which has accessibilityElementsWithNestedFormat:
        // It returns FBFuture<id> which becomes FBFuture<AnyObject> in Swift.
        let accessibilityInfoFuture: FBFuture<AnyObject> = target.accessibilityElements(withNestedFormat: true)
        
        let infoAnyObject: AnyObject = try await FutureBridge.value(accessibilityInfoFuture)
        logger.info().log("Accessibility info raw object (AnyObject) received.")

        // Check if it's NSDictionary or NSArray, as both are valid top-level JSON structures.
        let jsonData: Data
        if let nsDict = infoAnyObject as? NSDictionary {
            logger.info().log("Successfully cast to NSDictionary.")
            jsonData = try JSONSerialization.data(withJSONObject: nsDict, options: [.prettyPrinted])
        } else if let nsArray = infoAnyObject as? NSArray {
            logger.info().log("Successfully cast to NSArray.")
            jsonData = try JSONSerialization.data(withJSONObject: nsArray, options: [.prettyPrinted])
        } else {
            logger.error().log("Accessibility info was not an NSDictionary or NSArray as expected. Type: \(type(of: infoAnyObject))")
            throw CLIError(errorDescription: "Accessibility info was not a dictionary or array as expected.")
        }

        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("\nAccessibility Information (JSON):\n")
            print(jsonString)
        } else {
            logger.error().log("Failed to convert accessibility info to JSON string.")
            throw CLIError(errorDescription: "Failed to convert accessibility info to JSON string.")
        }

        logger.info().log("Accessibility Info Fetcher finished successfully.")
    }
} 
