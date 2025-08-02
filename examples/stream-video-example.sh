#!/bin/bash

# Example script demonstrating video streaming with AXe
# NOTE: Currently only BGRA format works properly. H264/MJPEG formats have known issues.

# Get simulator UDID (use first booted iPhone)
UDID=$(xcrun simctl list devices | grep "iPhone.*Booted" | head -1 | grep -o "[A-F0-9-]\{36\}")

if [ -z "$UDID" ]; then
    echo "No booted iPhone simulator found. Please boot a simulator first."
    exit 1
fi

echo "Using simulator: $UDID"

# Example 1: Stream BGRA video to file (currently the only working format)
echo "Example 1: Streaming BGRA video to file for 5 seconds..."
echo "Note: BGRA outputs raw pixel data (4 bytes per pixel)"
swift run axe stream-video --udid "$UDID" --format bgra --fps 30 > recording.bgra &
PID=$!
sleep 5
kill -INT $PID
wait $PID 2>/dev/null
echo "Video saved to recording.bgra"
echo "To convert to MP4: ffmpeg -f rawvideo -pixel_format bgra -video_size 393x852 -i recording.bgra output.mp4"
echo ""

# Example 2: Show H264 format warning (currently not working)
echo "Example 2: H264 format (WARNING: Currently not functional)"
echo "Note: H264 encoding is broken in FBSimulatorControl. This will show warnings."
swift run axe stream-video --udid "$UDID" --format h264 --fps 30 > test-h264.h264 &
PID=$!
sleep 2
kill -INT $PID
wait $PID 2>/dev/null
echo "H264 test complete (expected to produce no data)"
rm -f test-h264.h264

# Example 3: Real-time BGRA to MP4 conversion with FFmpeg
echo ""
if command -v ffmpeg &> /dev/null; then
    echo "Example 3: Streaming BGRA and converting to MP4 in real-time..."
    swift run axe stream-video --udid "$UDID" --format bgra --fps 10 | \
        ffmpeg -f rawvideo -pixel_format bgra -video_size 393x852 -framerate 10 -i - \
               -c:v libx264 -pix_fmt yuv420p -preset fast \
               -y realtime.mp4 &
    PID=$!
    sleep 5
    kill -INT $PID
    wait $PID 2>/dev/null
    echo "Real-time video saved to realtime.mp4"
else
    echo "Example 3: ffmpeg not found. Install it with: brew install ffmpeg"
    echo "Skipping real-time MP4 conversion example."
fi

# Cleanup
rm -f recording.bgra

echo ""
echo "Video streaming examples completed!"