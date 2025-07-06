import SwiftUI

/// A view that displays live audio transcription
struct TranscriptView: View {
    /// The transcription text to display
    let transcript: String
    
    /// Whether recording is currently active
    let isRecording: Bool
    
    /// Whether screenshots are available
    let hasScreenshots: Bool
    
    var body: some View {
        ZStack {
            // Glass background for transcript
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
            
            // Transcript content
            if transcript.isEmpty {
                Text(isRecording ? "Listening..." : "No transcript available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            Text(transcript)
                                .font(.body)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                                .id("transcriptText")
                        }
                        .onChange(of: transcript) {
                            withAnimation {
                                proxy.scrollTo("transcriptText", anchor: .bottom)
                            }
                        }
                    }
                    
                    // Hint text for non-empty transcripts
                    if !transcript.isEmpty && !isRecording {
                        HStack(spacing: 0) {
                            Text("Press ")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("⌘↩S")
                                .font(.caption.bold())
                                .foregroundColor(.blue)
                            
                            Text(" to process transcript")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                
                            if hasScreenshots {
                                Text(" with screenshots")
                                    .font(.caption.bold())
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.bottom, 4)
                    }
                }
            }
        }
        .frame(height: Constants.UI.transcriptViewHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Transcript")
        .accessibilityValue(transcript.isEmpty ? "No transcript available" : transcript)
        .accessibilityHint(isRecording ? "Currently recording audio" : "Recording paused")
    }
}

#Preview {
    TranscriptView(
        transcript: "This is a sample transcript of what the speech recognition might capture. It demonstrates how the text would appear in the transcript view.",
        isRecording: true,
        hasScreenshots: true
    )
} 
 
