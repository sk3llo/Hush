import Foundation
import Combine
import AppKit

/// Service for interacting with the OpenAI API (powering ChatGPT)
final class ChatGPTService: NSObject {
    // MARK: - Properties

    /// Base URL for the OpenAI API
    private let baseURL = "https://api.openai.com/v1"

    /// API key from user preferences
    private var apiKey: String? {
        return AppPreferences.shared.openAIApiKey
    }

    /// Model to use for requests
    private var model: String {
        return AppPreferences.shared.model
    }

    /// The current data task for streaming
    private var streamingTask: URLSessionDataTask?

    /// The session for streaming requests
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60  // 60 seconds for each chunk
        configuration.timeoutIntervalForResource = 300 // 5 minutes total
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()

    /// Buffer for storing partial SSE events
    private var dataBuffer = Data()

    /// Callback when new text chunks arrive
    private var onUpdateCallback: ((String) -> Void)?

    /// Callback when streaming is complete
    private var onCompleteCallback: ((String) -> Void)?

    /// Callback for structured content updates
    private var onStructuredUpdateCallback: ((StreamContent) -> Void)?

    /// Callback when an error occurs
    private var onErrorCallback: ((Error) -> Void)?

    /// Accumulated text from all events
    private var fullText = ""

    /// Content builder for processing the streaming content
    private var contentBuilder = StreamContentBuilder()

    /// Flag to indicate if we're currently streaming
    private var isStreamActive = false

    // MARK: - Singleton

    /// Shared singleton instance
    static let shared = ChatGPTService()

    /// Private initializer to enforce singleton pattern
    private override init() {
        super.init()
    }

    // MARK: - Public Properties

    /// Whether the service is configured with a valid API key
    var isConfigured: Bool {
        return apiKey != nil && !apiKey!.isEmpty
    }

    // MARK: - Public Methods

    /// Generate a completion with streaming support and structured content processing
    /// - Parameters:
    ///   - prompt: The text prompt to send to the model
    ///   - onUpdate: Callback that receives structured content updates
    ///   - onError: Callback if an error occurs
    func generateStructuredStreamingContent(
        prompt: String,
        images: [NSImage],
        onUpdate: @escaping (StreamContent) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            onError(ChatGPTError.missingAPIKey)
            return
        }

        // Store callbacks
        self.onStructuredUpdateCallback = onUpdate
        self.onErrorCallback = onError

        // Reset state for new request
        self.dataBuffer = Data()
        self.fullText = ""
        self.contentBuilder = StreamContentBuilder()
        self.isStreamActive = true

        // Cancel any ongoing streaming task
        streamingTask?.cancel()

        // Create URL for chat completions
        guard let url = URL(string: "\(baseURL)/responses") else {
            onError(ChatGPTError.invalidURL)
            return
        }

        // Prepare request
        let requestBody = generateRequestBodyWithImages(prompt: prompt, images: images)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData

            // Debug the request
            print("🔵 ChatGPT streaming request initiated")

            // Create a streaming data task
            streamingTask = session.dataTask(with: request)
            streamingTask?.resume()
        } catch {
            onError(error)
        }
    }

    /// Generate a completion from text input with streaming support
    /// - Parameters:
    ///   - prompt: The text prompt to send to the model
    ///   - onUpdate: Callback that receives text updates as they stream in
    ///   - onComplete: Callback when the streaming is complete with final text
    ///   - onError: Callback if an error occurs
    func generateStreamingCompletion(
        prompt: String,
        onUpdate: @escaping (String) -> Void,
        onComplete: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            onError(ChatGPTError.missingAPIKey)
            return
        }

        // Store callbacks
        self.onUpdateCallback = onUpdate
        self.onCompleteCallback = onComplete
        self.onErrorCallback = onError

        // Reset state for new request
        self.dataBuffer = Data()
        self.fullText = ""
        self.isStreamActive = true

        // Cancel any ongoing streaming task
        streamingTask?.cancel()

        // Create URL for chat completions
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            onError(ChatGPTError.invalidURL)
            return
        }

        // Prepare request
        let requestBody = generateRequestBody(prompt: prompt)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData

            // Debug the request
            print("🔵 ChatGPT streaming request initiated")

            // Create a streaming data task
            streamingTask = session.dataTask(with: request)
            streamingTask?.resume()
        } catch {
            onError(error)
        }
    }

    // MARK: - Private Methods

    /// Generate the request body for the OpenAI API
    /// - Parameters:
    ///   - prompt: The user's prompt
    ///   - stream: Whether to stream the response
    /// - Returns: Dictionary representing the request body
    private func generateRequestBody(prompt: String) -> [String: Any] {
        return [
            "input": [
                "role": "user",
                "content": [
                ["type": "input_text", "text": prompt],
                ]
            ]
        ]
    }
    
    /// Generate the request body for the API call with text and images
    /// - Parameters:
    ///   - prompt: The user's text prompt
    ///   - images: Array of images to include
    /// - Returns: Request body as dictionary
    private func generateRequestBodyWithImages(prompt: String, images: [NSImage]) -> [String: Any] {
        // 1. Create the text input item using the supported type "message"
        let textItem: [String: Any] = [
            "type": "input_text",
            "text": prompt
        ]

        // 2. Create an array to hold all the input item dictionaries
        var inputItems: [Any] = [textItem]

        // 3. Create a separate input item dictionary for each image
        for image in images {
            if let base64Image = convertImageToBase64(image) {
                let imageItem: [String: Any] = [
                    "type": "input_image",
                    "image_url": "data:image/jpeg;base64,\(base64Image)"
                ]
                inputItems.append(imageItem)
            }
        }
        
        // 4. Return the corrected request body
        return [
            "model": model,
            "input": [[
                "role": "user",
                "content": inputItems
            ]]
        ]
    }
    
    /// Convert an NSImage to a Base64 encoded string
    /// - Parameter image: The image to convert
    /// - Returns: Base64 encoded string or nil if conversion fails
    private func convertImageToBase64(_ image: NSImage) -> String? {
        // Create a JPEG representation of the image
        guard let imageData = image.jpegRepresentation(compressionFactor: 0.8) else {
            return nil
        }
        
        // Convert the data to Base64
        return imageData.base64EncodedString()
    }

    /// Process a server-sent event
    /// - Parameter eventData: The raw event data string
    private func processEvent(_ eventData: String) {

        // Parse the JSON response
        guard let data = eventData.data(using: .utf8) else {
            print("❌ Failed to convert event data to UTF-8")
            return
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["output"] as? [[String: Any]],
               let content = choices.first?["content"] as? [[String: Any]],
               let text = content.first?["text"] as? String {

                // Update the full text
                self.fullText += text

                // Call the appropriate callbacks
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.onUpdateCallback?(text)

                    // Update structured content if needed
                    if let onStructuredUpdate = self.onStructuredUpdateCallback {
                        self.contentBuilder = StreamContentBuilder(buffer: self.fullText)
                        var content = self.contentBuilder.build()
                        content.finished = true
                        onStructuredUpdate(content)
                    }
                }
            }
            
            // Check for the completed marker that indicates end of stream
            if eventData.contains("\"status\": \"completed\"") {
                print("✅ Received stream completion marker")
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.onCompleteCallback?(self.fullText)
                    self.cleanup()
                }
                return
            }
        } catch {
            print("❌ Failed to parse event JSON: \(error.localizedDescription)")
        }
    }

    /// Clean up resources after streaming is complete or failed
    private func cleanup() {
        isStreamActive = false
        streamingTask = nil
        onUpdateCallback = nil
        onCompleteCallback = nil
        onErrorCallback = nil
        onStructuredUpdateCallback = nil
        dataBuffer = Data()
    }
}

// MARK: - URLSession Delegate

extension ChatGPTService: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // Append the new data to our buffer
        dataBuffer.append(data)

        // Process the buffer line by line
        guard let stringData = String(data: dataBuffer, encoding: .utf8) else {
            print("❌ Failed to decode data as UTF-8")
            return
        }

        
        processEvent(stringData)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            // Only call error callback if it's not due to explicit cancellation
            if (error as NSError).code != NSURLErrorCancelled {
                print("🔴 ChatGPT stream error: \(error.localizedDescription)")
                DispatchQueue.main.async { [weak self] in
                    self?.onErrorCallback?(error)
                    self?.cleanup()
                }
            }
        } else if isStreamActive {
            // If we get here without an error but streaming is still active,
            // it means the connection was closed by the server
            print("🟠 Stream completed by server")
            DispatchQueue.main.async { [weak self] in
                self?.cleanup()
                self?.cancelStreaming()
                self?.onCompleteCallback?(self!.fullText)
            }
        }
    }
    
    /// Cancel any ongoing streaming request
    func cancelStreaming() {
        // Cancel the streaming task if it exists
        streamingTask?.cancel()
        streamingTask = nil
        
        // Mark the stream as inactive
        isStreamActive = false
        
        // Clear buffers and state
        dataBuffer = Data()
        fullText = ""
        
        // Clear callbacks to prevent execution after cancellation
        clearCallbacks()
        
        print("🔵 Streaming request cancelled")
    }
    
    /// Clear all callbacks after completion or error
    private func clearCallbacks() {
        self.onUpdateCallback = nil
        self.onCompleteCallback = nil
        self.onStructuredUpdateCallback = nil
        self.onErrorCallback = nil
    }
}

// MARK: - Error Handling

/// Custom errors for the ChatGPT service
enum ChatGPTError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case noDataReceived
    case invalidResponse
    case streamingNotSupported

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "ChatGPT API key is missing. Please set it in preferences."
        case .invalidURL:
            return "Invalid ChatGPT API URL."
        case .noDataReceived:
            return "No data received from ChatGPT API."
        case .invalidResponse:
            return "Received an invalid response from ChatGPT API."
        case .streamingNotSupported:
            return "Streaming is not supported with the current configuration."
        }
    }
}
