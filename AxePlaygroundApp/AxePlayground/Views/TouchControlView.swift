//
//  TouchControlView.swift
//  AxePlayground
//
//  Created by Cameron on 23/05/2025.
//

import SwiftUI

// MARK: - Touch Control View
struct TouchControlView: View {
    @State private var touchEvents: [TouchEvent] = []
    @State private var eventCount = 0
    @State private var lastTouchCoordinates: CGPoint?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Interactive touch area
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                addTouchEvent(at: value.location, type: .down, in: geometry)
                            }
                            .onEnded { value in
                                addTouchEvent(at: value.location, type: .up, in: geometry)
                            }
                    )
                    .accessibilityIdentifier("touch-control-area")

                VStack {
                    // Header
                    VStack(spacing: 8) {
                        Text("Touch Control Playground")
                            .font(.title2)
                            .fontWeight(.bold)
                            .accessibilityIdentifier("touch-control-title")
                        
                        Text("Drag to see touch down/up events")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("touch-control-description")
                        
                        Text("Events: \(eventCount)")
                            .font(.headline)
                            .foregroundColor(.orange)
                            .accessibilityIdentifier("touch-event-count")
                            .accessibilityValue("\(eventCount)")
                        
                        if let lastTouch = lastTouchCoordinates {
                            Text("Last touch: (\(Int(lastTouch.x)), \(Int(lastTouch.y)))")
                                .font(.headline)
                                .foregroundColor(.purple)
                                .accessibilityIdentifier("last-touch-coordinates")
                                .accessibilityValue("x:\(Int(lastTouch.x)),y:\(Int(lastTouch.y))")
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                    .shadow(radius: 4)  

                    Spacer()          
                }
                .padding()
                .allowsHitTesting(false)

                // Touch event indicators - now persistent with labels
                ForEach(touchEvents) { event in
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [colorForType(event.type).opacity(0.8), colorForType(event.type).opacity(0.6)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 90, height: 32)
                        .overlay(
                            HStack(spacing: 4) {
                                Text(event.type == .down ? "↓" : "↑")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                Text("(\(Int(event.displayX)), \(Int(event.displayY)))")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                        )
                        .position(x: event.x, y: event.y)
                        .scaleEffect(event.scale)
                        .opacity(event.opacity)
                        .shadow(color: colorForType(event.type).opacity(0.3), radius: 3, x: 0, y: 2)
                        .accessibilityIdentifier("touch-event-\(event.id.uuidString)")
                        .accessibilityValue("\(event.type == .down ? "down" : "up"):x:\(Int(event.displayX)),y:\(Int(event.displayY))")
                }
                
                // Hidden accessibility element that reports all touch history
                Text("")
                    .accessibilityIdentifier("touch-history")
                    .accessibilityValue(generateTouchHistoryString())
                    .accessibilityHidden(true)
            }
        }
        .navigationTitle("Touch Control")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("touch-control-screen")
    }
    
    private func addTouchEvent(at point: CGPoint, type: TouchEvent.TouchType, in geometry: GeometryProxy) {
        // Convert view coordinates to screen coordinates
        let globalFrame = geometry.frame(in: .global)
        let screenPoint = CGPoint(
            x: point.x + globalFrame.minX,
            y: point.y + globalFrame.minY
        )
        
        // Offset position slightly to avoid perfect overlap
        let offsetX = point.x + CGFloat.random(in: -8...8)
        let offsetY = point.y + CGFloat.random(in: -8...8)
        
        let event = TouchEvent(
            x: offsetX,
            y: offsetY,
            displayX: screenPoint.x,
            displayY: screenPoint.y,
            type: type,
            scale: 0.3,
            opacity: 0.9,
            timestamp: Date()
        )
        
        touchEvents.append(event)
        eventCount += 1
        lastTouchCoordinates = screenPoint
        
        // Animate the indicator appearing
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            if let index = touchEvents.firstIndex(where: { $0.id == event.id }) {
                touchEvents[index].scale = 1.0
                touchEvents[index].opacity = 0.9
            }
        }
    }
    
    private func colorForType(_ type: TouchEvent.TouchType) -> Color {
        switch type {
        case .down: return .red
        case .up: return .green
        }
    }
    
    private func generateTouchHistoryString() -> String {
        if eventCount == 0 {
            return "no-touch-events"
        }
        
        let recentEvents = touchEvents.suffix(10) // Last 10 events
        let eventStrings = recentEvents.map { "\($0.type == .down ? "down" : "up"):x:\(Int($0.displayX)),y:\(Int($0.displayY))" }
        return "count:\(eventCount);recent:[\(eventStrings.joined(separator: ","))]"
    }
}

struct TouchEvent: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let displayX: CGFloat  // Screen coordinates for display
    let displayY: CGFloat
    let type: TouchType
    var scale: CGFloat
    var opacity: Double
    let timestamp: Date
    
    enum TouchType {
        case down, up
    }
}

#Preview {
    NavigationStack {
        TouchControlView()
    }
} 