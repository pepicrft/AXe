#!/bin/bash

# Alternative video recording script for iOS Simulator
# Since streaming to stdout is no longer supported by Apple and FBSimulatorControl has issues

# Get simulator UDID (use first booted iPhone)
UDID=$(xcrun simctl list devices | grep "iPhone.*Booted" | head -1 | grep -o "[A-F0-9-]\{36\}")

if [ -z "$UDID" ]; then
    echo "No booted iPhone simulator found. Please boot a simulator first."
    exit 1
fi

echo "Using simulator: $UDID"

# Method 1: Record to file using xcrun simctl
echo "Method 1: Recording video to file using xcrun simctl..."
echo "Press Ctrl+C to stop recording"
OUTPUT_FILE="simulator-recording-$(date +%Y%m%d-%H%M%S).mp4"
xcrun simctl io "$UDID" recordVideo --codec=h264 "$OUTPUT_FILE"
echo "Video saved to: $OUTPUT_FILE"

# Method 2: Use AXe stream-video (may not produce output due to known issues)
echo ""
echo "Method 2: Attempting to stream using AXe (may not work due to FBSimulatorControl issues)..."
echo "Press Ctrl+C to stop if it hangs"
timeout 10 swift run axe stream-video --udid "$UDID" --format mjpeg > test-stream.mjpeg 2>&1 || true

if [ -s test-stream.mjpeg ]; then
    echo "Stream data saved to test-stream.mjpeg"
else
    echo "No stream data produced (expected due to known issues)"
    rm -f test-stream.mjpeg
fi

# Method 3: Screen recording recommendation
echo ""
echo "Method 3: For live streaming, consider using:"
echo "- OBS Studio (https://obsproject.com/) - Free and open source"
echo "- QuickTime Player - Built-in screen recording"
echo "- ScreenFlow or similar commercial tools"
echo ""
echo "These tools can capture the simulator window and stream/record as needed."