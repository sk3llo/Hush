import SwiftUI
import Combine
import AppKit

/// Service responsible for capturing screenshots
final class ScreenshotService {
    // MARK: - Types
    
    /// Enum for different screenshot types
    enum ScreenshotType {
        case full       // Full screen
        case window     // Focused window
        case area       // Selected area
        
        /// Arguments for the screencapture command
        var processArguments: [String] {
            switch self {
            case .full:
                ["-c", "-x"]
            case .window:
                ["-cw", "-x"]
            case .area:
                ["-cs", "-x"]
            }
        }
    }
    
    // MARK: - Singleton
    
    /// Shared singleton instance
    static let shared = ScreenshotService()
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    // MARK: - Public Methods
    
    /// Capture a screenshot of the specified type
    /// - Parameters:
    ///   - type: The type of screenshot to capture
    ///   - completion: Callback with the captured image or error
    func captureScreenshot(type: ScreenshotType = .full, completion: @escaping (Result<NSImage, Error>) -> Void) {
        // Create a process to run the screencapture command
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        task.arguments = type.processArguments
        
        do {
            // Run the process
            try task.run()
            task.waitUntilExit()
            
            // Get the image from the pasteboard
            getImageFromPasteboard { result in
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        } catch {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Extract the captured image from the pasteboard
    /// - Parameter completion: Callback with the result
    private func getImageFromPasteboard(completion: @escaping (Result<NSImage, Error>) -> Void) {
        // Check if the pasteboard contains an image
        guard NSPasteboard.general.canReadItem(withDataConformingToTypes: NSImage.imageTypes) else {
            completion(.failure(ScreenshotError.noPasteboardImage))
            return
        }
        
        // Get the image from the pasteboard
        guard let image = NSImage(pasteboard: NSPasteboard.general) else {
            completion(.failure(ScreenshotError.invalidPasteboardImage))
            return
        }
        
        completion(.success(image))
    }
}

// MARK: - Errors

/// Custom errors for the screenshot service
enum ScreenshotError: Error, LocalizedError {
    /// No image found in pasteboard
    case noPasteboardImage
    
    /// Could not create a valid image from pasteboard data
    case invalidPasteboardImage
    
    /// Human-readable error descriptions
    var errorDescription: String? {
        switch self {
        case .noPasteboardImage:
            return "No image found in pasteboard after screenshot capture."
        case .invalidPasteboardImage:
            return "Could not create a valid image from pasteboard data."
        }
    }
} 