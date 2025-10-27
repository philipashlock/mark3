import SwiftUI
import WebKit

struct MarkdownHighlighterView: NSViewRepresentable {
    @ObservedObject var bridge: EditorBridge

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        if #available(macOS 11.0, *) {
            config.defaultWebpagePreferences.allowsContentJavaScript = true
        }

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        // Setup the bridge message handler for console logs
        let controller = webView.configuration.userContentController
        controller.add(context.coordinator, name: "consoleLog")

        // Add console logger
        let consoleLogScript = WKUserScript(
            source: """
            (function() {
                const originalLog = console.log;
                const originalWarn = console.warn;
                const originalError = console.error;

                console.log = function(...args) {
                    let message = args.map(arg => {
                        if (typeof arg === 'object') {
                            try {
                                return JSON.stringify(arg);
                            } catch (e) {
                                return String(arg);
                            }
                        }
                        return String(arg);
                    }).join(' ');

                    window.webkit?.messageHandlers?.consoleLog?.postMessage({
                        level: 'log',
                        message: message
                    });

                    originalLog.apply(console, args);
                };

                console.warn = function(...args) {
                    let message = args.map(arg => String(arg)).join(' ');
                    window.webkit?.messageHandlers?.consoleLog?.postMessage({
                        level: 'warn',
                        message: message
                    });
                    originalWarn.apply(console, args);
                };

                console.error = function(...args) {
                    let message = args.map(arg => String(arg)).join(' ');
                    window.webkit?.messageHandlers?.consoleLog?.postMessage({
                        level: 'error',
                        message: message
                    });
                    originalError.apply(console, args);
                };
            })();
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        controller.addUserScript(consoleLogScript)

        // Load the HTML with syntax highlighting
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.8.0/build/styles/atom-one-light.min.css">
            <script src="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.8.0/build/highlight.min.js"></script>
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
                    font-family: -apple-system, BlinkMacSystemFont, 'Menlo', 'Monaco', 'Courier New', monospace;
                    font-size: 13px;
                    line-height: 1.5;
                    padding: 20px;
                    color: #24292e;
                    background: #ffffff;
                    overflow-y: auto;
                    overflow-x: auto;
                }

                pre {
                    background: transparent;
                    border: none;
                    padding: 0;
                    margin: 0;
                    border-radius: 0;
                }

                code {
                    font-family: -apple-system, BlinkMacSystemFont, 'Menlo', 'Monaco', 'Courier New', monospace;
                    font-size: 13px;
                    color: inherit;
                    background: transparent;
                    padding: 0;
                }

                .hljs {
                    background: transparent;
                    color: #24292e;
                    padding: 0;
                }

                ::-webkit-scrollbar {
                    width: 15px;
                    height: 15px;
                }

                ::-webkit-scrollbar-track {
                    background: transparent;
                }

                ::-webkit-scrollbar-thumb {
                    background: #c1c1c1;
                    background-clip: padding-box;
                    border-radius: 10px;
                }

                ::-webkit-scrollbar-thumb:hover {
                    background: #a6a6a6;
                    background-clip: padding-box;
                }

                /* Dark mode support */
                @media (prefers-color-scheme: dark) {
                    body {
                        color: #d4d4d4;
                        background: #1e1e1e;
                    }

                    .hljs {
                        color: #d4d4d4;
                    }

                    ::-webkit-scrollbar-thumb {
                        background: #515151;
                        background-clip: padding-box;
                    }

                    ::-webkit-scrollbar-thumb:hover {
                        background: #6a6a6a;
                        background-clip: padding-box;
                    }
                }
            </style>
        </head>
        <body>
            <pre><code id="content" class="language-markdown"></code></pre>
            <script>
                window.highlighter = {
                    isReady: false,
                    pendingContent: null,

                    updateContent: function(markdown) {
                        const contentElement = document.getElementById('content');
                        if (contentElement && window.hljs) {
                            contentElement.textContent = markdown;
                            // Highlight the content
                            hljs.highlightElement(contentElement);
                            console.log('🎨 [Highlighter JS] Content updated and highlighted, length: ' + markdown.length);
                        } else {
                            console.error('🎨 [Highlighter JS] Content element or hljs not found');
                        }
                    }
                };

                // Wait for Highlight.js to load before marking as ready
                function checkHighlightReady() {
                    if (typeof hljs !== 'undefined') {
                        window.highlighter.isReady = true;
                        console.log('🎨 [Highlighter JS] Ready with Highlight.js');

                        // If there's pending content, update it now
                        if (window.highlighter.pendingContent) {
                            window.highlighter.updateContent(window.highlighter.pendingContent);
                            window.highlighter.pendingContent = null;
                        }
                    } else {
                        setTimeout(checkHighlightReady, 100);
                    }
                }

                checkHighlightReady();
            </script>
        </body>
        </html>
        """

        webView.loadHTMLString(html, baseURL: nil)
        context.coordinator.webView = webView
        print("🎨 [MarkdownHighlighterView.makeNSView] WebView created and HTML loaded")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        print("🎨 [MarkdownHighlighterView.updateNSView] Called")
        print("🎨 [MarkdownHighlighterView.updateNSView] markdownContent length: \(bridge.markdownContent.count)")

        let markdown = bridge.markdownContent

        print("🎨 [MarkdownHighlighterView.updateNSView] Executing JavaScript after 0.5s delay")

        // Give highlight.js more time to load
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Escape the markdown string for safe JavaScript embedding
            let escapedMarkdown = markdown
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "`", with: "\\`")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "\\r")

            // Use template literals with backticks to handle the content safely
            let setupCode = """
            window.pendingMarkdownContent = `\(escapedMarkdown)`;
            console.log('🎨 [JS] Stored pending content, length: ' + window.pendingMarkdownContent.length);
            """

            webView.evaluateJavaScript(setupCode) { result, error in
                if let error = error {
                    print("❌ [MarkdownHighlighterView] Error storing content: \(error)")
                    return
                }
                print("✅ [MarkdownHighlighterView] Content stored successfully")

                // Now update with the stored content
                let updateCode = """
                (function() {
                    console.log('🎨 [JS] Checking if highlighter is ready...');
                    const markdown = window.pendingMarkdownContent;
                    console.log('🎨 [JS] Retrieved markdown length: ' + (markdown ? markdown.length : 'undefined'));

                    if (window.highlighter) {
                        console.log('🎨 [JS] window.highlighter exists');
                        if (window.highlighter.isReady && window.hljs && markdown) {
                            console.log('🎨 [JS] Highlighter is ready, updating content');
                            window.highlighter.updateContent(markdown);
                        } else {
                            console.log('🎨 [JS] Highlighter not ready yet, storing pending content');
                            window.highlighter.pendingContent = markdown;
                        }
                    } else {
                        console.error('🎨 [JS] window.highlighter not available');
                    }
                })();
                """

                webView.evaluateJavaScript(updateCode) { result, error in
                    if let error = error {
                        print("❌ [MarkdownHighlighterView] Error updating content: \(error)")
                    } else {
                        print("✅ [MarkdownHighlighterView] Content update JavaScript executed")
                    }
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: MarkdownHighlighterView
        var webView: WKWebView?

        init(_ parent: MarkdownHighlighterView) {
            self.parent = parent
            super.init()
            print("🎨 [Highlighter Coordinator] Initialized")
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ [Highlighter Coordinator] HTML loaded")
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ [Highlighter Coordinator] Failed to load: \(error)")
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let data = message.body as? [String: Any],
                  let level = data["level"] as? String,
                  let logMessage = data["message"] as? String else {
                return
            }

            let prefix: String
            switch level {
            case "warn":
                prefix = "⚠️ [Highlighter JS]"
            case "error":
                prefix = "❌ [Highlighter JS]"
            default:
                prefix = "📝 [Highlighter JS]"
            }
            print("\(prefix) \(logMessage)")
        }
    }
}
