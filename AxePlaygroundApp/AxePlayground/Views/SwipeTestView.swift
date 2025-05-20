//
//  SwipeTestView.swift
//  AxePlayground
//
//  Created by Cameron on 23/05/2025.
//

import SwiftUI

struct SwipeTestView: View {
    @State private var swipePaths: [SwipePath] = []
    @State private var currentPath: [CGPoint] = []
    @State private var swipeCount = 0
    
    var body: some View {
        ZStack {
            // Interactive swipe area
            Color.clear
                .contentShape(Rectangle())
                .accessibilityIdentifier("swipe-test-area")
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            currentPath.append(value.location)
                        }
                        .onEnded { value in
                            if currentPath.count > 1 {
                                let path = SwipePath(
                                    startPoint: currentPath.first ?? value.startLocation,
                                    endPoint: currentPath.last ?? value.location,
                                    pathPoints: currentPath,
                                    duration: 0.5
                                )
                                swipePaths.append(path)
                                swipeCount += 1
                            }
                            currentPath.removeAll()
                        }
                )
            
            VStack {
                // Header
                VStack(spacing: 8) {
                    Text("Swipe Playground")
                        .font(.title2)
                        .fontWeight(.bold)
                        .accessibilityIdentifier("swipe-test-title")
                    Text("Drag your finger to create swipe paths")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .accessibilityIdentifier("swipe-test-description")
                    Text("Swipes: \(swipeCount)")
                        .font(.headline)
                        .foregroundColor(.green)
                        .accessibilityIdentifier("swipe-count")
                        .accessibilityValue("\(swipeCount)")
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
                .shadow(radius: 4)

                Spacer()
            }
            .padding()
            
            // Current swipe path
            if !currentPath.isEmpty {
                SwipePathShape(points: currentPath)
                    .stroke(Color.blue, lineWidth: 4)
                    .opacity(0.8)
                    .accessibilityIdentifier("current-swipe-path")
            }
            
            // Completed swipe paths
            ForEach(swipePaths) { path in
                SwipePathView(path: path)
                    .accessibilityIdentifier("swipe-path-\(path.id.uuidString)")
                    .accessibilityValue("start:x\(Int(path.startPoint.x)),y\(Int(path.startPoint.y));end:x\(Int(path.endPoint.x)),y\(Int(path.endPoint.y));points:\(path.pathPoints.count)")
            }
            
            // Hidden accessibility element for last swipe
            if let lastSwipe = swipePaths.last {
                Text("")
                    .accessibilityIdentifier("last-swipe-path")
                    .accessibilityValue("start:x\(Int(lastSwipe.startPoint.x)),y\(Int(lastSwipe.startPoint.y));end:x\(Int(lastSwipe.endPoint.x)),y\(Int(lastSwipe.endPoint.y))")
                    .accessibilityHidden(true)
            }
            
            // Hidden accessibility element that reports all swipe history
            Text("")
                .accessibilityIdentifier("swipe-history")
                .accessibilityValue(generateSwipeHistoryString())
                .accessibilityHidden(true)
        }
        .navigationTitle("Swipe Test")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("swipe-test-screen")
    }
    
    private func generateSwipeHistoryString() -> String {
        if swipeCount == 0 {
            return "no-swipes"
        }
        
        let recentSwipes = swipePaths.suffix(3) // Last 3 swipes
        let swipeStrings = recentSwipes.map { 
            "start:x\(Int($0.startPoint.x)),y\(Int($0.startPoint.y));end:x\(Int($0.endPoint.x)),y\(Int($0.endPoint.y))"
        }
        return "count:\(swipeCount);recent:[\(swipeStrings.joined(separator: "|"))]"
    }
}

struct SwipePath: Identifiable {
    let id = UUID()
    let startPoint: CGPoint
    let endPoint: CGPoint
    let pathPoints: [CGPoint]
    let duration: Double
    let timestamp = Date()
}

struct SwipePathView: View {
    let path: SwipePath
    
    var body: some View {
        ZStack {
            // Path line
            SwipePathShape(points: path.pathPoints)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.green, .blue, .purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 3
                )
                .opacity(0.7)
            
            // Start point
            Circle()
                .fill(Color.green)
                .frame(width: 12, height: 12)
                .position(path.startPoint)
                .accessibilityIdentifier("swipe-start-point")
                .accessibilityValue("x:\(Int(path.startPoint.x)),y:\(Int(path.startPoint.y))")
            
            // End point
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
                .position(path.endPoint)
                .accessibilityIdentifier("swipe-end-point")
                .accessibilityValue("x:\(Int(path.endPoint.x)),y:\(Int(path.endPoint.y))")
            
            // Arrow indicating direction
            if path.pathPoints.count > 1 {
                let direction = angleFromPoints(from: path.startPoint, to: path.endPoint)
                Image(systemName: "arrow.right")
                    .foregroundColor(.white)
                    .font(.caption)
                    .rotationEffect(.radians(direction))
                    .position(
                        x: (path.startPoint.x + path.endPoint.x) / 2,
                        y: (path.startPoint.y + path.endPoint.y) / 2
                    )
                    .background(
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 20, height: 20)
                            .position(
                                x: (path.startPoint.x + path.endPoint.x) / 2,
                                y: (path.startPoint.y + path.endPoint.y) / 2
                            )
                    )
                    .accessibilityIdentifier("swipe-direction-arrow")
            }
        }
    }
    
    private func angleFromPoints(from: CGPoint, to: CGPoint) -> Double {
        return atan2(to.y - from.y, to.x - from.x)
    }
}

struct SwipePathShape: Shape {
    let points: [CGPoint]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard points.count > 1 else { return path }
        
        path.move(to: points[0])
        
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        
        return path
    }
}

#Preview {
    NavigationStack {
        SwipeTestView()
    }
} 