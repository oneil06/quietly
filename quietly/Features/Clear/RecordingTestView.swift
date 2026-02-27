import SwiftUI
import AVFoundation
import Speech

struct RecordingTestView: View {
    @State private var isRecording = false
    @State private var inputText = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Recording Test")
                .font(.title)
                .padding()
            
            Text(inputText)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            
            Button(isRecording ? "Stop Recording" : "Start Recording") {
                isRecording.toggle()
                if isRecording {
                    startTestRecording()
                } else {
                    stopTestRecording()
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
    
    private func startTestRecording() {
        // Test recording setup
        print("Starting test recording...")
    }
    
    private func stopTestRecording() {
        // Test recording stop
        print("Stopping test recording...")
        inputText = "Test recording completed successfully!"
    }
}

#Preview {
    RecordingTestView()
}