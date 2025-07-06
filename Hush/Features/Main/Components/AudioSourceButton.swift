import SwiftUI

/// Button for toggling audio recording with source from settings
struct AudioSourceButton: View {
    // MARK: - Properties
    
    @ObservedObject private var appState: AppState
    @ObservedObject private var systemAudioRecorder: SystemAudioRecorder
    
    let action: () -> Void
    
    // MARK: - Initialization
    
    init(appState: AppState = .shared, action: @escaping () -> Void) {
        self.appState = appState
        self.systemAudioRecorder = SystemAudioRecorder.shared
        self.action = action
    }
    
    // MARK: - Computed Properties
    
    /// Determines if any recording is active
    private var isRecording: Bool {
        switch appState.audioSource {
        case .microphone:
            return appState.isLiveMode
        case .systemAudio:
            return systemAudioRecorder.isRecording
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                // Icon based on source
                Image(systemName: appState.audioSource == .microphone ? 
                      "dot.radiowaves.left.and.right" : "speaker.wave.3")
                    .font(.system(size: 12))
                    .frame(width: 16)
                    .foregroundColor(isRecording ? .red : .green.opacity(0.6))
                
                // Button title
                Text(appState.audioSource == .microphone ? "LIVE MIC" : "LIVE SYS")
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                // Shortcut indicator
                ShortcutKey(key: "L")
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        AudioSourceButton(appState: AppState.shared) {}
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
#endif 