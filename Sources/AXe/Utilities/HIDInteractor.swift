import Foundation
import FBControlCore
import FBSimulatorControl

// MARK: - HID Interactor
@MainActor
struct HIDInteractor {
    static func performHIDEvent(_ event: FBSimulatorHIDEvent, for simulatorUDID: String, logger: AxeLogger) async throws {

        let simulatorSet = try await getSimulatorSet(deviceSetPath: nil, logger: logger, reporter: EmptyEventReporter.shared)
        logger.info().log("FBSimulatorSet obtained.")

        guard let target = simulatorSet.allSimulators.first(where: { $0.udid == simulatorUDID }) else {
            throw CLIError(errorDescription: "Simulator with UDID \(simulatorUDID) not found in set.")
        }
        logger.info().log("Target (FBSimulator) obtained: \(target.udid)")

        logger.info().log("Attempting to connect to HID...")
        
        // Use the target's workQueue for HID operations, similar to CompanionLib
        let hidFuture = target.connectToHID().onQueue(target.workQueue) { hid in
            logger.info().log("HID connection successful, performing event...")
            return event.perform(on: hid)
        }
        
        try await FutureBridge.value(hidFuture)
        logger.info().log("HID event performed successfully.")

        /*
        let storageManager: FBIDBStorageManager // Type not available from core frameworks
        do  {
            storageManager = try FBIDBStorageManager(for: target, logger: logger) // Type not available
            logger.info().log("FBIDBStorageManager initialized.")
        } catch {
            logger.error().log("Failed to initialize FBIDBStorageManager: \(error.localizedDescription)")
            throw error
        }

        let commandExecutor = FBIDBCommandExecutor( // Type not available
            for: target,
            storageManager: storageManager,
            debugserverPort: 0
        )
        logger.info().log("FBIDBCommandExecutor initialized.")

        let future = commandExecutor.hid(event)
        try await FutureBridge.value(future)

        logger.info().log("HID event performed successfully.")
        */
    }
} 
