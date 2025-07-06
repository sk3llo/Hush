import Foundation
import Speech
import AVFoundation
import SwiftUI
import Combine

/// Service for transcribing speech from audio recordings
final class TranscriptionService: NSObject, ObservableObject {
    // MARK: - Published Properties
    
    /// Current transcription text
    @Published var transcript: String = ""
    
    /// Whether recording is currently active
    @Published var isRecording: Bool = false
    
    /// Whether transcription is available on this device
    @Published var isTranscriptionAvailable: Bool = false
    
    // MARK: - Private Properties
    
    /// Speech recognizer for transcribing audio
    private var speechRecognizer: SFSpeechRecognizer?
    
    /// Recognition request for the current session
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    /// Recognition task for the current session
    private var recognitionTask: SFSpeechRecognitionTask?
    
    /// Audio engine for capturing microphone input
    private let audioEngine = AVAudioEngine()
    
    /// Audio format for system audio processing
    private var systemAudioFormat: AVAudioFormat?
    
    /// Shared instance for singleton pattern
    static let shared = TranscriptionService()
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        
        // Check availability
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.isTranscriptionAvailable = status == .authorized
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Starts recording and transcribing audio from the microphone
    func startRecording() throws {
        // Create and configure the speech recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "TranscriptionServiceErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to create a speech recognition request"])
        }
        
        // Configure request
        recognitionRequest.shouldReportPartialResults = true
        
        // Keep audio recording for analysis
        recognitionRequest.requiresOnDeviceRecognition = false
        
        // Create a recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                // Update the transcript with the recognition results
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
                isFinal = result.isFinal
            }
            
            // Handle errors or end of speech
            if error != nil || isFinal {
                self.stopRecording()
            }
        }
        
        // Configure audio input node
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Install tap on the audio input
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // Start the audio engine
        audioEngine.prepare()
        try audioEngine.start()
        
        // Update recording state
        isRecording = true
    }
    
    /// Starts transcription directly from system audio without using the microphone
    func startSystemAudioTranscription(with streamDescription: AudioStreamBasicDescription) throws {
        // Create audio format from stream description
        var streamDescCopy = streamDescription
        guard let format = AVAudioFormat(streamDescription: &streamDescCopy) else {
            throw NSError(domain: "TranscriptionServiceErrorDomain", code: 2, 
                          userInfo: [NSLocalizedDescriptionKey: "Unable to create audio format from stream description"])
        }
        
        // Store format for later use
        self.systemAudioFormat = format
        
        // Create and configure the speech recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "TranscriptionServiceErrorDomain", code: 0, 
                          userInfo: [NSLocalizedDescriptionKey: "Unable to create a speech recognition request"])
        }
        
        // Configure request
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        
        // Create a recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                // Update the transcript with the recognition results
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
                isFinal = result.isFinal
            }
            
            // Handle errors or end of speech
            if error != nil || isFinal {
                self.stopRecording()
            }
        }
        
        // Update recording state
        isRecording = true
    }
    
    /// Process an audio buffer for transcription
    func processAudioBuffer(_ bufferList: UnsafePointer<AudioBufferList>, bufferTimeStamp: UnsafePointer<AudioTimeStamp>) {
        guard isRecording, let systemAudioFormat = systemAudioFormat, let recognitionRequest = recognitionRequest else { return }
        
        // Create AVAudioPCMBuffer from the buffer list
        guard let buffer = AVAudioPCMBuffer(pcmFormat: systemAudioFormat, bufferListNoCopy: bufferList, deallocator: nil) else {
            NSLog("Failed to create PCM buffer for transcription")
            return
        }
        
        // Ensure the buffer has valid sample data
        guard buffer.frameLength > 0 else {
            return // Skip empty buffers
        }
        
        // Append the buffer to the recognition request
        recognitionRequest.append(buffer)
    }
    
    /// Stops recording and transcribing
    func stopRecording() {
        // Stop audio engine and remove tap if using microphone
        if audioEngine.isRunning {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        // End recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // Cancel recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Reset system audio format
        systemAudioFormat = nil
        
        // Update recording state
        isRecording = false
        
        // Hide transcript view - always hide when stopping regardless of preference
        DispatchQueue.main.async {
            AppState.shared.showTranscript = false
        }
    }
    
    /// Resets the transcript
    func resetTranscript() {
        transcript = ""
    }
    
    /// Request authorization for speech recognition
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.isTranscriptionAvailable = status == .authorized
            }
        }
    }
} 