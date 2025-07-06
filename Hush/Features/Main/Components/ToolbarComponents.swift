import SwiftUI

// MARK: - Recording circle animation

/// Animated recording indicator that pulsates when recording is active
struct RecordingCircle: View {
    @State private var isPulsating = false
    
    var body: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 12, height: 12)
            .scaleEffect(isPulsating ? 1.2 : 1.0)
            .opacity(isPulsating ? 0.7 : 1.0)
            .animation(
                Animation.easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true),
                value: isPulsating
            )
            .onAppear {
                isPulsating = true
            }
    }
}

// MARK: - Status indicators

/// Green status dot indicating available/ready state
struct GreenStatusDot: View {
    var body: some View {
        Circle()
            .fill(Color.green)
            .frame(width: 12, height: 12)
    }
}

// MARK: - Shortcut key indicators

/// Visual indicator for keyboard shortcuts
struct ShortcutKey: View {
    let key: String
    let showCommandSymbol: Bool
    
    init(key: String, showCommandSymbol: Bool = true) {
        self.key = key
        self.showCommandSymbol = showCommandSymbol
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if showCommandSymbol {
                // Command symbol
                Text("⌘")
                    .font(.system(size: 10, weight: .medium))
                    .frame(width: 15, height: 15)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
            }
            
            // Key symbol
            Text(key)
                .font(.system(size: 10, weight: .medium))
                .frame(width: 15, height: 15)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
        }
    }
}

// MARK: - Button components

/// Standard toolbar button with shortcut indicator
struct ToolbarButton: View {
    // Properties
    let title: String
    let shortcutKey: String
    let systemImage: String?
    let action: () -> Void
    let showTitle: Bool
    let fixedWidth: CGFloat?
    
    // Initialization
    init(title: String, 
         shortcutKey: String, 
         systemImage: String? = nil,
         showTitle: Bool = true, 
         fixedWidth: CGFloat? = nil, 
         action: @escaping () -> Void) {
        self.title = title
        self.shortcutKey = shortcutKey
        self.systemImage = systemImage
        self.showTitle = showTitle
        self.fixedWidth = fixedWidth
        self.action = action
    }
    
    // View body
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                // System image if provided
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 12))
                        .frame(width: 16)
                }
                
                // Only show title if showTitle is true
                if showTitle {
                    Text(title)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                // For settings (comma shortcut), don't show command symbol
                if shortcutKey == "," {
                    ShortcutKey(key: shortcutKey, showCommandSymbol: false)
                } else {
                    ShortcutKey(key: shortcutKey)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .frame(width: fixedWidth)
            .background(Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Separators

/// Visual divider for toolbar sections
struct ToolbarDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.3))
            .frame(width: 1, height: 20)
            .padding(.horizontal, 2)
    }
}

// MARK: - Section dividers

/// Divider between major UI sections
struct SectionDivider: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
        }
        .frame(height: Constants.UI.dividerHeight)
        .background(Color.clear)
    }
}

// MARK: - Text input components

/// Custom borderless text field with placeholder
struct BorderlessTextField: View {
    @Binding var text: String
    let placeholder: String
    let onSubmit: () -> Void
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Placeholder text (shown when text is empty)
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(Color.gray.opacity(0.7))
                    .padding(.leading, 4)
            }
            
            // Actual text field
            TextField("", text: $text, onCommit: onSubmit)
                .padding(.leading, 4)
                .textFieldStyle(PlainTextFieldStyle())
                .frame(maxWidth: .infinity)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Auto-scroll components

/// Indicator and toggle for auto-scroll functionality
struct AutoScrollIndicator: View {
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 2) {
                Text("A")
                    .font(.system(size: 12, weight: .bold))
                
                // Up/down arrows
                VStack(spacing: 0) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 8))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isEnabled ? Color.gray.opacity(0.25) : Color.clear)
            .foregroundColor(isEnabled ? .primary : .gray)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 
