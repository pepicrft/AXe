#!/bin/bash

# Example: Working video streaming from iOS Simulator using BGRA format
# This demonstrates how to use the stream-video command with raw BGRA output

# Get simulator UDID (use first booted iPhone)
UDID=$(xcrun simctl list devices | grep "iPhone.*Booted" | head -1 | grep -o "[A-F0-9-]\{36\}")

if [ -z "$UDID" ]; then
    echo "No booted iPhone simulator found. Please boot a simulator first."
    exit 1
fi

echo "Using simulator: $UDID"

# Get simulator dimensions (common iPhone sizes)
# You may need to adjust these based on your simulator model
WIDTH=393   # iPhone 15 Pro width
HEIGHT=852  # iPhone 15 Pro height

echo "Assuming dimensions: ${WIDTH}x${HEIGHT}"

# Example 1: Stream BGRA to a raw file
echo ""
echo "Example 1: Streaming raw BGRA video to file..."
echo "Press Ctrl+C to stop recording"
swift run axe stream-video --udid "$UDID" --format bgra --fps 10 > raw-video.bgra

echo "Raw video saved to: raw-video.bgra"
echo "File size: $(ls -lh raw-video.bgra | awk '{print $5}')"

# Example 2: Stream and convert to MP4 in real-time (requires ffmpeg)
if command -v ffmpeg &> /dev/null; then
    echo ""
    echo "Example 2: Streaming and converting to MP4 in real-time..."
    echo "Press Ctrl+C to stop recording"
    
    swift run axe stream-video --udid "$UDID" --format bgra --fps 10 | \
        ffmpeg -f rawvideo -pixel_format bgra -video_size ${WIDTH}x${HEIGHT} -framerate 10 -i - \
               -c:v libx264 -pix_fmt yuv420p -preset fast \
               -y realtime-capture.mp4
    
    echo "Video saved to: realtime-capture.mp4"
else
    echo ""
    echo "FFmpeg not installed. To convert BGRA to MP4:"
    echo "brew install ffmpeg"
    echo "Then run:"
    echo "ffmpeg -f rawvideo -pixel_format bgra -video_size ${WIDTH}x${HEIGHT} -i raw-video.bgra -c:v libx264 -pix_fmt yuv420p output.mp4"
fi

# Example 3: Extract frames from raw BGRA
echo ""
echo "Example 3: Extracting first frame as PNG..."
if command -v ffmpeg &> /dev/null && [ -f raw-video.bgra ]; then
    BYTES_PER_FRAME=$((WIDTH * HEIGHT * 4))
    dd if=raw-video.bgra of=first-frame.raw bs=$BYTES_PER_FRAME count=1 2>/dev/null
    ffmpeg -f rawvideo -pixel_format bgra -video_size ${WIDTH}x${HEIGHT} -i first-frame.raw -frames:v 1 first-frame.png -y 2>/dev/null
    rm -f first-frame.raw
    echo "First frame saved to: first-frame.png"
fi

echo ""
echo "Note: H264 and MJPEG formats are currently not working due to FBSimulatorControl issues."
echo "Use BGRA format for raw pixel data or 'xcrun simctl io recordVideo' for compressed video."