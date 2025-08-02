import Testing
import Foundation

@Suite("Stream Video Command Tests")
struct StreamVideoTests {
    @Test("Stream video outputs data to stdout for BGRA format")
    func streamVideoBGRA() async throws {
        // No need to launch app for video streaming - it captures the simulator screen
        // Act - Stream for 2 seconds
        let result = try await streamVideoForDuration(format: "bgra", duration: 2.0)
        
        // Assert - SIGTERM (15) is expected since we're terminating the process
        #expect(result.exitCode == 15 || result.exitCode == 0, "Command should exit with SIGTERM or success")
        #expect(!result.output.isEmpty, "Should have output messages")
        #expect(result.dataSize > 0, "Should have received raw video data bytes")
        #expect(result.output.contains("Starting video stream"), "Should show startup message")
        #expect(result.output.contains("Format: bgra"), "Should show format")
        // BGRA should produce roughly width*height*4 bytes per frame
        // Note: Due to buffering, we might not get all data, so be lenient
        #expect(result.dataSize > 10_000, "Should have received some video data for 2 seconds")
    }
    
    @Test("Stream video shows warning for H264 format")
    func streamVideoH264Warning() async throws {
        // Act
        let result = try await streamVideoForDuration(format: "h264", duration: 1.0)
        
        // Assert - SIGTERM (15) is expected since we're terminating the process
        #expect(result.exitCode == 15 || result.exitCode == 0, "Command should exit with SIGTERM or success")
        #expect(result.output.contains("WARNING: Only BGRA format currently works"), "Should show warning about H264")
        #expect(result.output.contains("Format: h264"), "Should show format")
        // H264 currently doesn't produce data due to FBSimulatorControl issues
        #expect(result.dataSize == 0, "H264 format currently produces no data")
    }
    
    @Test("Stream video shows warning for MJPEG format")
    func streamVideoMJPEGWarning() async throws {
        // Act
        let result = try await streamVideoForDuration(format: "mjpeg", duration: 1.0)
        
        // Assert - SIGTERM (15) is expected since we're terminating the process
        #expect(result.exitCode == 15 || result.exitCode == 0, "Command should exit with SIGTERM or success")
        #expect(result.output.contains("WARNING: Only BGRA format currently works"), "Should show warning about MJPEG")
        #expect(result.output.contains("Format: mjpeg"), "Should show format")
        // MJPEG currently doesn't produce data due to FBSimulatorControl issues
        #expect(result.dataSize == 0, "MJPEG format currently produces no data")
    }
    
    @Test("Stream BGRA video with custom FPS")
    func streamBGRAVideoWithFPS() async throws {
        // Act
        let result = try await streamVideoForDuration(format: "bgra", fps: 5, duration: 1.0)
        
        // Assert - SIGTERM (15) is expected since we're terminating the process
        #expect(result.exitCode == 15 || result.exitCode == 0, "Command should exit with SIGTERM or success")
        #expect(result.output.contains("FPS: 5"), "Should show custom FPS")
        #expect(result.dataSize > 0, "Should have received video data")
        // Due to buffering and timing, be more lenient with data size expectations
        #expect(result.dataSize > 10_000, "Should have received video data")
    }
    
    @Test("Stream BGRA video with quality and scale settings")
    func streamBGRAVideoWithQualityAndScale() async throws {
        // Act
        let result = try await streamVideoForDuration(
            format: "bgra",
            fps: 5,
            quality: 0.5,
            scale: 0.5,
            duration: 1.0
        )
        
        // Assert - SIGTERM (15) is expected since we're terminating the process
        #expect(result.exitCode == 15 || result.exitCode == 0, "Command should exit with SIGTERM or success")
        #expect(result.output.contains("Quality: 0.5"), "Should show quality setting")
        #expect(result.output.contains("Scale: 0.5"), "Should show scale setting")
        #expect(result.dataSize > 0, "Should have received video data")
        // Note: Scale might not affect BGRA raw output in current implementation
    }
    
    @Test("Stream video can be cancelled gracefully")
    func streamVideoCancellation() async throws {
        // Act - Start streaming and cancel quickly
        let task = Task {
            try await streamVideoForDuration(format: "bgra", fps: 30, duration: 60.0)
        }
        
        // Wait a bit then cancel
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        task.cancel()
        
        // Wait for task to complete
        let _ = await task.result
        
        // Test passes if no crash occurs
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
    ) async throws -> (output: String, dataSize: Int, exitCode: Int32) {
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
        
        // Run command directly with timeout since stream-video outputs to stdout
        // and TestHelpers.runAxeCommand doesn't separate stdout/stderr
        let axePath = try TestHelpers.getAxePath()
        let fullCommand = "\(axePath) \(command) --udid \(defaultSimulatorUDID ?? "")"
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", fullCommand]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        
        // Let it run for duration
        try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        
        // Terminate the process
        process.terminate()
        process.waitUntilExit()
        
        // Read the data
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
        
        return (
            output: errorOutput,
            dataSize: outputData.count,
            exitCode: process.terminationStatus
        )
    }
}