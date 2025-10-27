import SwiftUI

struct FormattingToolbar: View {
    @ObservedObject var bridge: EditorBridge

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar header with formatting controls
            FormattingToolbarContent(bridge: bridge)
                .frame(minHeight: 44, idealHeight: 44)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color(.controlBackgroundColor).opacity(0.5))

            Divider()
        }
    }
}

struct FormattingToolbarContent: View {
    @ObservedObject var bridge: EditorBridge
    @State private var activeMarks: [String] = []

    var body: some View {
        HStack(spacing: 4) {
            // Heading buttons
            HStack(spacing: 2) {
                FormatButton(
                    title: "H1",
                    icon: nil,
                    action: { bridge.executeFormattingCommand("toggleHeading1") },
                    isActive: activeMarks.contains("heading") && bridge.getCurrentHeadingLevel() == 1
                )

                FormatButton(
                    title: "H2",
                    icon: nil,
                    action: { bridge.executeFormattingCommand("toggleHeading2") },
                    isActive: activeMarks.contains("heading") && bridge.getCurrentHeadingLevel() == 2
                )

                FormatButton(
                    title: "H3",
                    icon: nil,
                    action: { bridge.executeFormattingCommand("toggleHeading3") },
                    isActive: activeMarks.contains("heading") && bridge.getCurrentHeadingLevel() == 3
                )
            }
            .padding(4)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(4)

            Divider()
                .frame(height: 24)

            // Text formatting buttons
            HStack(spacing: 2) {
                FormatButton(
                    icon: "bold",
                    action: { bridge.executeFormattingCommand("toggleBold") },
                    isActive: activeMarks.contains("strong")
                )

                FormatButton(
                    icon: "italic",
                    action: { bridge.executeFormattingCommand("toggleItalic") },
                    isActive: activeMarks.contains("em")
                )

                FormatButton(
                    icon: "underline",
                    action: { bridge.executeFormattingCommand("toggleUnderline") },
                    isActive: activeMarks.contains("u")
                )

                FormatButton(
                    icon: "code",
                    action: { bridge.executeFormattingCommand("toggleCode") },
                    isActive: activeMarks.contains("code")
                )
            }
            .padding(4)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(4)

            Divider()
                .frame(height: 24)

            // List and block buttons
            HStack(spacing: 2) {
                FormatButton(
                    icon: "list.bullet",
                    action: { bridge.executeFormattingCommand("toggleBulletList") },
                    isActive: activeMarks.contains("bulletList")
                )

                FormatButton(
                    icon: "list.number",
                    action: { bridge.executeFormattingCommand("toggleOrderedList") },
                    isActive: activeMarks.contains("orderedList")
                )

                FormatButton(
                    icon: "quote.opening",
                    action: { bridge.executeFormattingCommand("toggleBlockquote") },
                    isActive: activeMarks.contains("blockquote")
                )

                FormatButton(
                    title: "Code",
                    icon: "chevron.right.2",
                    action: { bridge.executeFormattingCommand("toggleCodeBlock") },
                    isActive: activeMarks.contains("codeBlock")
                )
            }
            .padding(4)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(4)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .onAppear {
            startPollingActiveMarks()
        }
    }

    private func startPollingActiveMarks() {
        // Poll every 100ms to update active mark state
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            bridge.getActiveFormats { marks in
                DispatchQueue.main.async {
                    self.activeMarks = marks
                }
            }
        }
    }
}

// MARK: - Individual Format Button

struct FormatButton: View {
    let title: String?
    let icon: String?
    let action: () -> Void
    let isActive: Bool

    init(title: String? = nil, icon: String? = nil, action: @escaping () -> Void, isActive: Bool = false) {
        self.title = title
        self.icon = icon
        self.action = action
        self.isActive = isActive
    }

    var body: some View {
        Button(action: action) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
            } else if let title = title {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
        }
        .buttonStyle(FormatButtonStyle(isActive: isActive))
        .frame(height: 28)
        .frame(minWidth: 32)
    }
}

// MARK: - Format Button Style

struct FormatButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isActive ? .accentColor : .primary)
            .padding(.horizontal, 8)
            .background(
                isActive
                    ? Color.accentColor.opacity(0.2)
                    : Color.clear
            )
            .cornerRadius(3)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

// MARK: - Extension for EditorBridge helper

extension EditorBridge {
    func getCurrentHeadingLevel() -> Int {
        // This would need to be implemented with a separate JavaScript call
        // For now, returning a placeholder
        return 0
    }
}
