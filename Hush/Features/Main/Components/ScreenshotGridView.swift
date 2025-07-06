import SwiftUI

/// Grid view for displaying captured screenshots
struct ScreenshotGridView: View {
    // MARK: - Properties
    
    /// Array of captured images to display
    let images: [CapturedImage]
    
    /// Callback when an image is selected
    var onImageSelected: ((UUID) -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(images) { capturedImage in
                        Image(nsImage: capturedImage.image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: Constants.UI.screenshotViewHeight - 10) // Leave room for padding
                            .shadow(radius: 1)
                            .overlay(
                                RoundedRectangle(cornerRadius: 0)
                                    .stroke(Color.blue, lineWidth: capturedImage.isSelected ? 1 : 0)
                            )
                            .padding(capturedImage.isSelected ? 1 : 0)
                            .background(
                                RoundedRectangle(cornerRadius: 0)
                                    .fill(Color.blue.opacity(capturedImage.isSelected ? 0.1 : 0))
                            )
                            .id(capturedImage.id)
                            .onTapGesture {
                                onImageSelected?(capturedImage.id)
                            }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, Constants.UI.dividerHeight / 2)
            }
            .frame(height: Constants.UI.screenshotViewHeight + Constants.UI.dividerHeight) // Image height + total vertical padding
            .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
            .onChange(of: images.count) { newCount, _ in
                // Auto-scroll to the last screenshot when a new one is added
                if let lastImage = images.last {
                    scrollProxy.scrollTo(lastImage.id, anchor: .trailing)
                }
            }
            .onChange(of: images.first { $0.isSelected }?.id) { newSelectedId, _ in
                // Auto-scroll to the selected screenshot when selection changes
                if let newSelectedId = newSelectedId {
                    scrollProxy.scrollTo(newSelectedId, anchor: .center)
                }
            }
        }
    }
}

// MARK: - Preview Provider

#Preview {
    ScreenshotGridView(
        images: [
            CapturedImage(image: NSImage(named: "AppIcon")!),
            CapturedImage(image: NSImage(named: "AppIcon")!)
        ]
    )
} 
 