//
//  KeyPressView.swift
//  AxePlayground
//
//  Created by Cameron on 23/05/2025.
//

import SwiftUI

// MARK: - Key Press View
struct KeyPressView: View {
    @State private var detectedKeys: [KeyEvent] = []
    @State private var isListening = true
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Key Press Detection")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Detects individual keys sent by CLI")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Circle()
                        .fill(isListening ? .green : .red)
                        .frame(width: 12, height: 12)
                    Text(isListening ? "Listening for key events" : "Not listening")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(12)
            .shadow(radius: 4)
            
            // Text field to capture key events
            TextField("Focus here to detect CLI key events", text: .constant(""))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.title2)
                .focused($isTextFieldFocused)
                .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification)) { notification in
                    if let textField = notification.object as? UITextField,
                       let text = textField.text,
                       let lastChar = text.last {
                        let keyEvent = KeyEvent(key: String(lastChar), timestamp: Date())
                        detectedKeys.append(keyEvent)
                        textField.text = "" // Clear to detect next key
                    }
                }
            
            if !detectedKeys.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Detected Key Events:")
                        .font(.headline)
                    ScrollView {
                        LazyVStack(alignment: .leading) {
                            ForEach(Array(detectedKeys.suffix(10).enumerated()), id: \.offset) { index, keyEvent in
                                let timeString = keyEvent.timestamp.formatted(date: .omitted, time: .standard)
                                Text("\(keyEvent.key) - \(timeString)")
                                    .font(.caption)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Key Press")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

struct KeyEvent: Identifiable {
    let id = UUID()
    let key: String
    let timestamp: Date
} 