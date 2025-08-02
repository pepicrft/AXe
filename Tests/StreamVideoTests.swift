import Testing
import Foundation

@Suite("Stream Video Command Tests")
struct StreamVideoTests {
    @Test("Stream video outputs data to stdout for BGRA format")
    func streamVideoBGRA() async throws {
        // Arrange
        try await TestHelpers.launchPlaygroundApp(to: "tap-test") // Any screen is fine for video streaming
        
        // Act - Stream for 2 seconds
        let result = try await streamVideoForDuration(format: "bgra", duration: 2.0)
        
        // Assert
        #expect(result.exitCode == 0, "Command should exit successfully")
        #expect(!result.output.isEmpty, "Should have output messages")
        #expect(result.dataSize > 0, "Should have received raw video data bytes")
        #expect(result.output.contains("Starting video stream"), "Should show startup message")
        #expect(result.output.contains("Format: bgra"), "Should show format")
        // BGRA should produce roughly width*height*4 bytes per frame
        #expect(result.dataSize > 1_000_000, "Should have substantial raw video data for 2 seconds")
    }
    
    @Test("Stream video shows warning for H264 format")
    func streamVideoH264Warning() async throws {
        // Arrange  
        try await TestHelpers.launchPlaygroundApp(to: "tap-test")
        
        // Act
        let result = try await streamVideoForDuration(format: "h264", duration: 1.0)
        
        // Assert
        #expect(result.exitCode == 0, "Command should exit successfully")
        #expect(result.output.contains("WARNING: Only BGRA format currently works"), "Should show warning about H264")
        #expect(result.output.contains("Format: h264"), "Should show format")
        // H264 currently doesn't produce data due to FBSimulatorControl issues
        #expect(result.dataSize == 0, "H264 format currently produces no data")
    }
    
    @Test("Stream video shows warning for MJPEG format")
    func streamVideoMJPEGWarning() async throws {
        // Arrange
        try await TestHelpers.launchPlaygroundApp(to: "tap-test")
        
        // Act
        let result = try await streamVideoForDuration(format: "mjpeg", duration: 1.0)
        
        // Assert
        #expect(result.exitCode == 0, "Command should exit successfully")
        #expect(result.output.contains("WARNING: Only BGRA format currently works"), "Should show warning about MJPEG")
        #expect(result.output.contains("Format: mjpeg"), "Should show format")
        // MJPEG currently doesn't produce data due to FBSimulatorControl issues
        #expect(result.dataSize == 0, "MJPEG format currently produces no data")
    }
    
    @Test("Stream BGRA video with custom FPS")
    func streamBGRAVideoWithFPS() async throws {
        // Arrange
        try await TestHelpers.launchPlaygroundApp(to: "tap-test")
        
        // Act
        let result = try await streamVideoForDuration(format: "bgra", fps: 5, duration: 1.0)
        
        // Assert
        #expect(result.exitCode == 0, "Command should exit successfully")
        #expect(result.output.contains("FPS: 5"), "Should show custom FPS")
        #expect(result.dataSize > 0, "Should have received video data")
        // With 5 FPS for 1 second, we expect roughly 5 frames worth of data
        let expectedMinSize = 393 * 852 * 4 * 3 // At least 3 frames (allowing for timing)
        #expect(result.dataSize > expectedMinSize, "Should have received multiple frames")
    }
    
    @Test("Stream BGRA video with quality and scale settings")
    func streamBGRAVideoWithQualityAndScale() async throws {
        // Arrange
        try await TestHelpers.launchPlaygroundApp(to: "tap-test")
        
        // Act
        let result = try await streamVideoForDuration(
            format: "bgra",
            fps: 5,
            quality: 0.5,
            scale: 0.5,
            duration: 1.0
        )
        
        // Assert
        #expect(result.exitCode == 0, "Command should exit successfully")
        #expect(result.output.contains("Quality: 0.5"), "Should show quality setting")
        #expect(result.output.contains("Scale: 0.5"), "Should show scale setting")
        #expect(result.dataSize > 0, "Should have received video data")
        // Note: Scale might not affect BGRA raw output in current implementation
    }
    
    @Test("Stream video can be cancelled gracefully")
    func streamVideoCancellation() async throws {
        // Arrange
        try await TestHelpers.launchPlaygroundApp(to: "tap-test")
        
        // Act - Start streaming and cancel quickly
        let task = Task {
            try await TestHelpers.runAxeCommand(
                "stream-video --format bgra --fps 30",
                simulatorUDID: defaultSimulatorUDID
            )
        }
        
        // Wait a bit then cancel
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        task.cancel()
        
        // Assert - Task should complete without throwing
        do {
            _ = try await task.value
        } catch {
            // Cancellation is expected
            #expect(error is CancellationError || String(describing: error).contains("cancel"))
        }
    }
    
    // MARK: - Helper Methods
    
    private func streamVideoForDuration(
        format: String = "h264",
        fps: Int? = nil,
        quality: Double = 0.2,
        scale: Double = 1.0,
        bitrate: Int? = nil,
        keyFrameInterval: Int = 10,
        duration: TimeInterval = 2.0
    ) async throws -> (output: String, dataSize: Int, firstBytes: [UInt8], exitCode: Int32) {
        // Build command
        var command = "stream-video --format \(format)"
        if let fps = fps {
            command += " --fps \(fps)"
        }
        command += " --quality \(quality) --scale \(scale)"
        if let bitrate = bitrate {
            command += " --bitrate \(bitrate)"
        }
        command += " --key-frame-interval \(keyFrameInterval)"
        
        // Run command with timeout
        let task = Task {
            try await TestHelpers.runAxeCommand(command, simulatorUDID: defaultSimulatorUDID)
        }
        
        // Wait for duration
        try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        
        // Cancel the streaming
        task.cancel()
        
        // Get the result
        do {
            let result = try await task.value
            
            // Parse stdout (video data) and stderr (messages)
            let videoData = result.stdout
            let output = result.stderr
            
            // Get first few bytes for format verification
            let firstBytes = Array(videoData.prefix(10))
            
            return (
                output: output,
                dataSize: videoData.count,
                firstBytes: firstBytes,
                exitCode: result.exitCode
            )
        } catch {
            // If cancelled, still try to get output
            if let commandError = error as? CommandRunner.RunError,
               case .nonZeroExitCode(let code, let stdout, let stderr) = commandError {
                let firstBytes = Array(stdout.prefix(10))
                return (
                    output: stderr,
                    dataSize: stdout.count,
                    firstBytes: firstBytes,
                    exitCode: code
                )
            }
            // For cancellation, return empty result
            return (output: "", dataSize: 0, firstBytes: [], exitCode: 0)
        }
    }
}