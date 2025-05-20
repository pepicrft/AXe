//
//  ContentView.swift
//  AxePlayground
//
//  Created by Cameron on 23/05/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var navigationManager = NavigationManager.shared
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            MainMenuView()
                .navigationDestination(for: String.self) { screen in
                    destinationView(for: screen)
                }
        }
        .onAppear {
            // Handle direct launch to specific screen
            if let directScreen = navigationManager.directLaunchScreen {
                navigationPath.append(directScreen)
            }
        }
        .onChange(of: navigationManager.directLaunchScreen) { _, newValue in
            if let screen = newValue {
                navigationPath.append(screen)
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for screen: String) -> some View {
        switch screen {
        // Touch & Gestures
        case "tap-test":
            TapTestView()
        case "swipe-test":
            SwipeTestView()
        case "touch-control":
            TouchControlView()
        case "gesture-presets":
            GesturePresetsView()
            
        // Input & Text
        case "text-input":
            TextInputView()
        case "key-press":
            KeyPressView()
        case "key-sequence":
            KeySequenceView()
            
        default:
            MainMenuView()
        }
    }
}

struct MainMenuView: View {
    private let menuSections: [(String, [(String, String, String)])] = [
        ("Touch & Gestures", [
            ("tap-test", "Tap Test", "Displays coordinates of CLI taps"),
            ("touch-control", "Touch Control", "Touch down/up events"),
            ("swipe-test", "Swipe Test", "Shows CLI swipe paths"),
            ("gesture-presets", "Gesture Presets", "Multi-touch gesture display")
        ]),
        ("Input & Text", [
            ("text-input", "Text Input", "Text typed by CLI commands"),
            ("key-press", "Key Press", "Detects CLI key events"),
            ("key-sequence", "Key Sequence", "Detects CLI key sequences")
        ])
    ]
    
    var body: some View {
        List {            
            ForEach(menuSections, id: \.0) { section in
                Section(section.0) {
                    ForEach(section.1, id: \.0) { item in
                        NavigationLink(value: item.0) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.1)
                                    .font(.headline)
                                Text(item.2)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            

        }
        .navigationTitle("AXe Playground")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    ContentView()
}
