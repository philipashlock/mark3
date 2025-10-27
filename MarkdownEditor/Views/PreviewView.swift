import SwiftUI
import WebKit

struct PreviewView: View {
    @ObservedObject var bridge: EditorBridge
    @State private var previewTheme: PreviewTheme = .systemDefault

    enum PreviewTheme: String, CaseIterable {
        case systemDefault = "System Default"
        case light = "Light Mode"
        case dark = "Dark Mode"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Spacer()

                Menu {
                    ForEach(PreviewTheme.allCases, id: \.self) { theme in
                        Button(action: { previewTheme = theme }) {
                            HStack {
                                Text(theme.rawValue)
                                if theme == previewTheme {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "paintbrush.pointed")
                            .font(.system(size: 13, weight: .medium))
                        Text("Theme")
                            .font(.system(.caption, design: .default))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(4)
                }

                Spacer()
            }
            .frame(minHeight: 44, idealHeight: 44)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.controlBackgroundColor).opacity(0.5))

            Divider()

            PreviewWebView(bridge: bridge, theme: previewTheme)
        }
    }
}

struct PreviewWebView: NSViewRepresentable {
    @ObservedObject var bridge: EditorBridge
    let theme: PreviewView.PreviewTheme

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }

                html, body {
                    height: 100%;
                    width: 100%;
                }

                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
                    line-height: 1.6;
                    padding: 20px;
                    color: #24292e;
                    background: #ffffff;
                    overflow-y: auto;
                }

                h1, h2 {
                    border-bottom: 1px solid #eaecef;
                    padding-bottom: 0.3em;
                    margin-top: 0.67em;
                    margin-bottom: 0.5em;
                }

                h3, h4, h5, h6 {
                    margin-top: 0.5em;
                    margin-bottom: 0.3em;
                }

                code {
                    background: #f6f8fa;
                    padding: 0.2em 0.4em;
                    border-radius: 3px;
                    font-family: 'SF Mono', Monaco, 'Courier New', monospace;
                }

                pre {
                    background: #f6f8fa;
                    padding: 16px;
                    border-radius: 6px;
                    overflow-x: auto;
                    margin: 1em 0;
                }

                pre code {
                    background: transparent;
                    padding: 0;
                }

                blockquote {
                    border-left: 4px solid #dfe2e5;
                    padding-left: 16px;
                    color: #6a737d;
                    margin: 1em 0;
                    font-style: italic;
                }

                a {
                    color: #0969da;
                    text-decoration: none;
                }

                a:hover {
                    text-decoration: underline;
                }

                ul, ol {
                    margin: 1em 0;
                    padding-left: 2em;
                }

                li {
                    margin: 0.25em 0;
                }

                p {
                    margin: 0.75em 0;
                }

                /* Webkit scrollbar styling for light mode */
                ::-webkit-scrollbar {
                    width: 15px;
                    height: 15px;
                }

                ::-webkit-scrollbar-track {
                    background: transparent;
                }

                ::-webkit-scrollbar-thumb {
                    background: #c1c1c1;
                    border-radius: 8px;
                    border: 3px solid transparent;
                    background-clip: padding-box;
                }

                ::-webkit-scrollbar-thumb:hover {
                    background: #a6a6a6;
                    background-clip: padding-box;
                }

                ::-webkit-scrollbar-corner {
                    background: transparent;
                }

                /* Light mode - forced */
                html[data-user-theme="light"] body {
                    background: #ffffff;
                    color: #24292e;
                }

                html[data-user-theme="light"] h1,
                html[data-user-theme="light"] h2 {
                    border-bottom-color: #eaecef;
                }

                html[data-user-theme="light"] code {
                    background: #f6f8fa;
                    color: #24292e;
                }

                html[data-user-theme="light"] pre {
                    background: #f6f8fa;
                    color: #24292e;
                }

                html[data-user-theme="light"] blockquote {
                    border-left-color: #dfe2e5;
                    color: #6a737d;
                }

                html[data-user-theme="light"] a {
                    color: #0969da;
                }

                html[data-user-theme="light"] ::-webkit-scrollbar-thumb {
                    background: #c1c1c1;
                    background-clip: padding-box;
                }

                html[data-user-theme="light"] ::-webkit-scrollbar-thumb:hover {
                    background: #a6a6a6;
                    background-clip: padding-box;
                }

                /* Dark mode - forced */
                html[data-user-theme="dark"] body {
                    background: #1e1e1e;
                    color: #d4d4d4;
                }

                html[data-user-theme="dark"] h1,
                html[data-user-theme="dark"] h2 {
                    border-bottom-color: #444444;
                }

                html[data-user-theme="dark"] code {
                    background: #2d2d2d;
                    color: #ff79c6;
                }

                html[data-user-theme="dark"] pre {
                    background: #2d2d2d;
                    color: #d4d4d4;
                }

                html[data-user-theme="dark"] blockquote {
                    border-left-color: #444444;
                    color: #9ca3af;
                }

                html[data-user-theme="dark"] a {
                    color: #60a5fa;
                }

                html[data-user-theme="dark"] ::-webkit-scrollbar-thumb {
                    background: #555555;
                    border-color: #1e1e1e;
                    background-clip: padding-box;
                }

                html[data-user-theme="dark"] ::-webkit-scrollbar-thumb:hover {
                    background: #707070;
                    background-clip: padding-box;
                }

                /* Dark mode - system default */
                @media (prefers-color-scheme: dark) {
                    body {
                        background: #1e1e1e;
                        color: #d4d4d4;
                    }

                    h1, h2 {
                        border-bottom-color: #444444;
                    }

                    code {
                        background: #2d2d2d;
                        color: #ff79c6;
                    }

                    pre {
                        background: #2d2d2d;
                        color: #d4d4d4;
                    }

                    blockquote {
                        border-left-color: #444444;
                        color: #9ca3af;
                    }

                    a {
                        color: #60a5fa;
                    }

                    /* Dark mode scrollbar styling */
                    ::-webkit-scrollbar-thumb {
                        background: #555555;
                        border-color: #1e1e1e;
                        background-clip: padding-box;
                    }

                    ::-webkit-scrollbar-thumb:hover {
                        background: #707070;
                        background-clip: padding-box;
                    }
                }
            </style>
            <script src="marked.js"></script>
            <script>
                // System appearance detection
                (function() {
                    function detectAppearance() {
                        const isDarkMode = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
                        return isDarkMode ? 'dark' : 'light';
                    }

                    window.systemAppearance = detectAppearance();
                    document.documentElement.setAttribute('data-theme', window.systemAppearance);
                    console.log('🎨 [Preview JS] System appearance:', window.systemAppearance);

                    if (window.matchMedia) {
                        const darkModeQuery = window.matchMedia('(prefers-color-scheme: dark)');
                        darkModeQuery.addEventListener('change', (e) => {
                            window.systemAppearance = e.matches ? 'dark' : 'light';
                            document.documentElement.setAttribute('data-theme', window.systemAppearance);
                            console.log('🎨 [Preview JS] System appearance changed to:', window.systemAppearance);
                        });
                    }
                })();

                window.milkdownPreview = {
                    setMarkdown: function(markdown) {
                        if (typeof marked !== 'undefined' && marked.parse) {
                            document.getElementById('preview').innerHTML = marked.parse(markdown);
                        } else {
                            console.error('marked library not loaded');
                            document.getElementById('preview').innerHTML = '<p>Error: marked library not available</p>';
                        }
                    },
                    setTheme: function(themeName) {
                        if (themeName === 'system') {
                            // Remove the attribute to use system detection via media query
                            document.documentElement.removeAttribute('data-user-theme');
                            console.log('🎨 [Preview JS] Theme set to: system (media query)');
                        } else if (themeName === 'light' || themeName === 'dark') {
                            document.documentElement.setAttribute('data-user-theme', themeName);
                            console.log('🎨 [Preview JS] Theme set to:', themeName);
                        } else {
                            console.warn('🎨 [Preview JS] Unknown theme:', themeName);
                        }
                    }
                };
            </script>
        </head>
        <body>
            <div id="preview"></div>
        </body>
        </html>
        """

        // Use the Web resources directory as base URL so lib/ can be found
        if let baseURL = Bundle.main.url(forResource: "wysiwyg-editor", withExtension: "html")?.deletingLastPathComponent() {
            webView.loadHTMLString(html, baseURL: baseURL)
        } else {
            webView.loadHTMLString(html, baseURL: nil)
        }
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        print("🟣 [PreviewView.updateNSView] Called")
        print("🟣 [PreviewView.updateNSView] markdownContent length: \(bridge.markdownContent.count)")
        print("🟣 [PreviewView.updateNSView] Content preview: \(bridge.markdownContent.prefix(100))")
        print("🟣 [PreviewView.updateNSView] Theme: \(theme.rawValue)")

        // Update preview when markdown content changes
        let markdown = bridge.markdownContent

        let escapedMarkdown = markdown
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")

        print("🟣 [PreviewView.updateNSView] Escaped markdown length: \(escapedMarkdown.count)")

        // Determine theme value
        let themeValue: String
        switch theme {
        case .systemDefault:
            themeValue = "system"
        case .light:
            themeValue = "light"
        case .dark:
            themeValue = "dark"
        }

        let jsCode = """
        if (window.milkdownPreview) {
            console.log('🟣 [JS] PreviewView calling setMarkdown');
            window.milkdownPreview.setMarkdown("\(escapedMarkdown)");
            console.log('🟣 [JS] PreviewView calling setTheme with: \(themeValue)');
            window.milkdownPreview.setTheme("\(themeValue)");
        } else {
            console.warn('🟣 [JS] window.milkdownPreview not available');
        }
        """

        print("🟣 [PreviewView.updateNSView] Executing JavaScript")

        // Use a small delay to ensure the web view is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            webView.evaluateJavaScript(jsCode) { result, error in
                if let error = error {
                    print("❌ [PreviewView] Error: \(error)")
                } else {
                    print("✅ [PreviewView] Preview updated successfully")
                }
            }
        }
    }
}