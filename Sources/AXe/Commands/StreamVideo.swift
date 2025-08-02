import ArgumentParser
import Foundation
import FBSimulatorControl
@preconcurrency import FBControlCore

struct StreamVideo: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "stream-video",
        abstract: "Stream video from a simulator to stdout",
        discussion: """
        Streams the simulator's screen as video data to stdout. Supports multiple formats including H264, MJPEG, and raw BGRA.
        
        CURRENT STATUS:
        - BGRA format: WORKING - Outputs raw uncompressed pixel data (4 bytes per pixel)
        - H264 format: NOT WORKING - No output due to FBSimulatorControl issues
        - MJPEG format: NOT WORKING - No output due to FBSimulatorControl issues
        - Minicap format: NOT WORKING - No output due to FBSimulatorControl issues
        
        For BGRA format, the output is raw pixel data that can be processed with tools like FFmpeg:
        axe stream-video --format bgra --udid <UDID> | ffmpeg -f rawvideo -pixel_format bgra -video_size 393x852 -i - output.mp4
        
        Known issues:
        - Apple removed support for streaming to stdout in xcrun simctl io recordVideo
        - FBSimulatorControl's video compression (H264/MJPEG) has unresolved issues (see facebook/idb#787, #841)
        
        Alternative approaches:
        - Use xcrun simctl io recordVideo to record to a file: xcrun simctl io <UDID> recordVideo output.mp4
        - Use screen recording software like OBS to capture the simulator window
        """
    )
    
    @Option(name: .customLong("udid"), help: "The UDID of the simulator.")
    var simulatorUDID: String
    
    @Option(help: "Video format: h264, mjpeg, bgra, minicap")
    var format: String = "h264"
    
    @Option(help: "Frames per second (omit for lazy/on-damage streaming)")
    var fps: Int?
    
    @Option(help: "Compression quality (0.0-1.0, default: 0.2)")
    var quality: Double = 0.2
    
    @Option(help: "Scale factor (0.0-1.0, default: 1.0)")
    var scale: Double = 1.0
    
    @Option(help: "Average bitrate in bits per second (H264 only)")
    var bitrate: Int?
    
    @Option(help: "Key frame interval in seconds (H264 only, default: 10.0)")
    var keyFrameInterval: Double = 10.0
    
    func validate() throws {
        // Validate format
        let validFormats = ["h264", "mjpeg", "bgra", "minicap"]
        guard validFormats.contains(format.lowercased()) else {
            throw ValidationError("Invalid format. Must be one of: \(validFormats.joined(separator: ", "))")
        }
        
        // Validate quality
        guard quality >= 0.0 && quality <= 1.0 else {
            throw ValidationError("Quality must be between 0.0 and 1.0")
        }
        
        // Validate scale
        guard scale > 0.0 && scale <= 1.0 else {
            throw ValidationError("Scale must be between 0.0 and 1.0")
        }
        
        // Validate FPS if provided
        if let fps = fps {
            guard fps > 0 && fps <= 60 else {
                throw ValidationError("FPS must be between 1 and 60")
            }
        }
        
        // Validate key frame interval
        guard keyFrameInterval > 0 else {
            throw ValidationError("Key frame interval must be greater than 0")
        }
    }
    
    func run() async throws {
        let logger = AxeLogger()
        try await setup(logger: logger)
        try await performGlobalSetup(logger: logger)
        
        // Get simulator set
        let simulatorSet = try await getSimulatorSet(deviceSetPath: nil, logger: logger, reporter: EmptyEventReporter.shared)
        
        // Find target simulator
        guard let targetSimulator = simulatorSet.allSimulators.first(where: { $0.udid == simulatorUDID }) else {
            throw CLIError(errorDescription: "Simulator with UDID \(simulatorUDID) not found.")
        }
        
        // Ensure simulator is booted
        guard targetSimulator.state == .booted else {
            throw CLIError(errorDescription: "Simulator \(simulatorUDID) is not booted. Current state: \(FBiOSTargetStateStringFromState(targetSimulator.state))")
        }
        
        // Create video stream configuration
        let encoding: FBVideoStreamEncoding = switch format.lowercased() {
        case "h264": .H264
        case "mjpeg": .MJPEG
        case "bgra": .BGRA
        case "minicap": .minicap
        default: .H264
        }
        
        let config = FBVideoStreamConfiguration(
            encoding: encoding,
            framesPerSecond: fps.map { NSNumber(value: $0) },
            compressionQuality: NSNumber(value: quality),
            scaleFactor: NSNumber(value: scale),
            avgBitrate: (encoding == .H264 && bitrate != nil) ? NSNumber(value: bitrate!) : nil,
            keyFrameRate: encoding == .H264 ? NSNumber(value: keyFrameInterval) : nil
        )
        
        // Log to stderr so it doesn't mix with video data on stdout
        FileHandle.standardError.write(Data("Starting video stream from simulator \(targetSimulator.udid)...\n".utf8))
        FileHandle.standardError.write(Data("Format: \(format), FPS: \(fps.map { String($0) } ?? "lazy"), Quality: \(quality), Scale: \(scale)\n".utf8))
        if format.lowercased() != "bgra" {
            FileHandle.standardError.write(Data("\nWARNING: Only BGRA format currently works. H264/MJPEG formats have known issues.\n".utf8))
            FileHandle.standardError.write(Data("Consider using --format bgra or 'xcrun simctl io \(targetSimulator.udid) recordVideo output.mp4'\n".utf8))
        }
        FileHandle.standardError.write(Data("Press Ctrl+C to stop streaming\n".utf8))
        
        do {
            // Note: We don't need to explicitly connect to framebuffer because
            // targetSimulator.createStream will do it internally
            
            // Create consumer that writes to stdout
            let stdoutConsumer = FBFileWriter.syncWriter(withFileDescriptor: STDOUT_FILENO, closeOnEndOfFile: false)
            
            // Create video stream using the simulator's createStream method
            let videoStreamFuture = targetSimulator.createStream(with: config)
            let videoStream = try await FutureBridge.value(videoStreamFuture)
            
            // Start streaming to stdout
            let startFuture = videoStream.startStreaming(stdoutConsumer)
            
            // Note: FBSimulatorControl's startStreaming often doesn't complete its future
            // but the stream may still work. We'll continue without waiting.
            startFuture.onQueue(BridgeQueues.videoStreamQueue, notifyOfCompletion: { future in
                if let error = future.error {
                    FileHandle.standardError.write(Data("Stream initialization error: \(error)\n".utf8))
                }
            })
            
            // Give the stream time to start
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            FileHandle.standardError.write(Data("Stream is now running...\n".utf8))
            
            // Set up cancellation handler
            await withTaskCancellationHandler {
                // Keep the stream running until cancelled
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                }
            } onCancel: {
                Task {
                    FileHandle.standardError.write(Data("\nStopping video stream...\n".utf8))
                    
                    // Stop the video stream on the same queue
                    do {
                        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                            BridgeQueues.videoStreamQueue.async {
                                let stopFuture = videoStream.stopStreaming()
                                
                                stopFuture.onQueue(BridgeQueues.videoStreamQueue, notifyOfCompletion: { future in
                                    if let error = future.error {
                                        FileHandle.standardError.write(Data("Stream stop error: \(error)\n".utf8))
                                        continuation.resume(throwing: error)
                                    } else {
                                        FileHandle.standardError.write(Data("Stream stopped successfully\n".utf8))
                                        continuation.resume()
                                    }
                                })
                            }
                        }
                    } catch {
                        FileHandle.standardError.write(Data("Error stopping stream: \(error)\n".utf8))
                    }
                }
            }
            
        } catch {
            throw CLIError(errorDescription: "Failed to stream video: \(error.localizedDescription)")
        }
    }
}