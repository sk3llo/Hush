import SwiftUI

/// Extension to handle window configuration
extension View {
    /// Configures window appearance and behavior
    /// - Parameters:
    ///   - isChatActive: Binding to chat activity state
    ///   - showResults: Binding to results visibility state
    /// - Returns: Modified view with window configuration
    func configureWindow(isChatActive: Binding<Bool>, showResults: Binding<Bool>) -> some View {
        self.background(WindowConfigurator(isChatActive: isChatActive, showResults: showResults))
    }
}

/// Internal view to configure NSWindow properties
struct WindowConfigurator: NSViewRepresentable {
    // MARK: - Properties
    
    /// Whether chat input is active
    @Binding var isChatActive: Bool
    
    /// Whether results view is visible
    @Binding var showResults: Bool
    
    // MARK: - NSViewRepresentable
    
    /// Creates the NSView for window configuration
    /// - Parameter context: The context for creating the view
    /// - Returns: A simple NSView for accessing the window
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        // Get parent window after view is added to hierarchy
        DispatchQueue.main.async {
            if let window = view.window {
                // We don't need to configure the window properties here anymore
                // as they're set in AppDelegate, just update size if needed
                updateWindowSize(window)
            }
        }
        
        return view
    }
    
    /// Updates the NSView when state changes
    /// - Parameters:
    ///   - nsView: The view to update
    ///   - context: Update context
    func updateNSView(_ nsView: NSView, context: Context) {
        // Update window size based on state changes
        guard let window = nsView.window else { return }
        updateWindowSize(window)
    }
    
    // MARK: - Private Methods
    
    /// Updates the window size based on current state
    /// - Parameter window: The window to resize
    private func updateWindowSize(_ window: NSWindow) {
            let currentHeight = window.frame.height
        let currentWidth = window.frame.width
        var newHeight: CGFloat = Constants.UI.toolbarHeight
            
            // Add height for chat area if active
            if isChatActive {
            newHeight += Constants.UI.chatInputHeight
            }
            
            // Add height for results area if showing
            if showResults {
            newHeight += Constants.UI.resultsViewHeight
            }
            
        // Check if height or width needs to be changed
        if currentHeight != newHeight || currentWidth != Constants.UI.windowWidth {
                let currentFrame = window.frame
                
            // Maintain the window's top position when resizing by adjusting 
                // the y-coordinate based on the height difference to expand downward
                let newFrame = NSRect(
                    x: currentFrame.origin.x,
                y: currentFrame.origin.y + (currentHeight - newHeight),
                width: Constants.UI.windowWidth, // Always use the constant width
                height: newHeight
                )
                
                // Simple smooth animation for window resizing
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = Constants.Animation.standard
                    context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                    window.animator().setFrame(newFrame, display: true)
                }
            }
    }
} 
 