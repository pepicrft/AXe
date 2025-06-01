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
    @State private var showSwipeTestModal = false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            MainMenuView(showSwipeTestModal: $showSwipeTestModal)
                .navigationDestination(for: String.self) { screen in
                    destinationView(for: screen)
                }
        }
        .fullScreenCover(isPresented: $showSwipeTestModal) {
            SwipeTestView()
        }
        .onAppear {
            // Handle direct launch to specific screen
            if let directScreen = navigationManager.directLaunchScreen {
                if directScreen == "swipe-test" {
                    showSwipeTestModal = true
                } else {
                    navigationPath.append(directScreen)
                }
            }
        }
        .onChange(of: navigationManager.directLaunchScreen) { _, newValue in
            if let screen = newValue {
                if screen == "swipe-test" {
                    showSwipeTestModal = true
                } else {
                    navigationPath.append(screen)
                }
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for screen: String) -> some View {
        switch screen {
        // Touch & Gestures
        case "tap-test":
            TapTestView()
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
            
        // Hardware
        case "button-test":
            ButtonTestView()

        default:
            Text("Screen not found")
        }
    }
}

struct MainMenuView: View {
    @Binding var showSwipeTestModal: Bool
    
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
        ]),
        ("Hardware", [
            ("button-test", "Button Test", "Hardware button press detection")
        ])
    ]
    
    var body: some View {
        List {            
            ForEach(menuSections, id: \.0) { section in
                Section(section.0) {
                    ForEach(section.1, id: \.0) { item in
                        if item.0 == "swipe-test" {
                            Button(action: {
                                showSwipeTestModal = true
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.1)
                                        .font(.headline)
                                    Text(item.2)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .foregroundColor(.primary)
                            }
                        } else {
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
            

        }
        .navigationTitle("AXe Playground")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    ContentView()
}
