#!/bin/bash

# Example script demonstrating video streaming with AXe

# Get simulator UDID (use first booted iPhone)
UDID=$(xcrun simctl list devices | grep "iPhone.*Booted" | head -1 | grep -o "[A-F0-9-]\{36\}")

if [ -z "$UDID" ]; then
    echo "No booted iPhone simulator found. Please boot a simulator first."
    exit 1
fi

echo "Using simulator: $UDID"

# Example 1: Stream H264 video to file
echo "Example 1: Streaming H264 video to file for 5 seconds..."
swift run axe stream-video --udid "$UDID" --format h264 --fps 30 > recording.h264 &
PID=$!
sleep 5
kill -INT $PID
wait $PID 2>/dev/null
echo "Video saved to recording.h264"
echo "You can play it with: ffplay -f h264 recording.h264"
echo ""

# Example 2: Stream MJPEG to stdout and pipe to ffplay (if available)
if command -v ffplay &> /dev/null; then
    echo "Example 2: Streaming MJPEG video to ffplay for real-time viewing..."
    echo "Press Ctrl+C to stop"
    swift run axe stream-video --udid "$UDID" --format mjpeg --fps 15 --quality 0.5 | ffplay -f mjpeg -i - 2>/dev/null
else
    echo "Example 2: ffplay not found. Install ffmpeg to view video in real-time."
    echo "You can install it with: brew install ffmpeg"
fi

# Example 3: Stream with scaling
echo ""
echo "Example 3: Streaming scaled video (50% size) to file..."
swift run axe stream-video --udid "$UDID" --format h264 --scale 0.5 --fps 20 > recording_scaled.h264 &
PID=$!
sleep 3
kill -INT $PID
wait $PID 2>/dev/null
echo "Scaled video saved to recording_scaled.h264"

# Cleanup
rm -f recording.h264 recording_scaled.h264

echo ""
echo "Video streaming examples completed!"