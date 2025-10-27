import SwiftUI
import SwiftDown

/// SwiftDownHighlighterView provides native syntax highlighting for Markdown using the SwiftDown library.
/// This replaces the web-based highlight.js approach with a pure SwiftUI component, offering:
/// - Better performance (no WKWebView overhead)
/// - Native theme support with light/dark mode integration
/// - Real-time updates as content changes
/// - Full bidirectional editing support integrated with EditorBridge
///
/// The view is fully editable and syncs with the EditorBridge's markdownContent property.
/// Changes made here are reflected in real-time across all three columns (WYSIWYG, Raw Highlight, Preview).
struct SwiftDownHighlighterView: View {
    @ObservedObject var bridge: EditorBridge
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            SwiftDownEditor(text: $bridge.markdownContent)
                .theme(currentTheme)
                .insetsSize(20)
                .isEditable(true)  // Fully editable with syntax highlighting
                .onAppear {
                    print("🎨 [SwiftDownHighlighterView] View appeared (editable) with markdown length: \(bridge.markdownContent.count)")
                }
                .onChange(of: bridge.markdownContent) { oldValue, newValue in
                    print("🎨 [SwiftDownHighlighterView] Content synced - old: \(oldValue.count) chars, new: \(newValue.count) chars")
                }
        }
        .background(Color(.controlBackgroundColor))
    }

    /// Select theme based on system color scheme preference
    /// - Light mode: Uses SwiftDown's default light theme with clear syntax highlighting
    /// - Dark mode: Uses SwiftDown's default dark theme optimized for low-light viewing
    private var currentTheme: Theme {
        if colorScheme == .dark {
            return Theme.BuiltIn.defaultDark.theme()
        } else {
            return Theme.BuiltIn.defaultLight.theme()
        }
    }
}
