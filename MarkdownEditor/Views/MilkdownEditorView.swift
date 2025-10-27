import SwiftUI
import WebKit
import Combine

struct MilkdownEditorView: View {
    @ObservedObject var bridge: EditorBridge

    var body: some View {
        VStack(spacing: 0) {
            FormattingToolbar(bridge: bridge)
            MilkdownWebView(bridge: bridge)
        }
    }
}

struct MilkdownWebView: NSViewRepresentable {
    @ObservedObject var bridge: EditorBridge

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // Configure preferences for better compatibility
        if #available(macOS 11.0, *) {
            config.defaultWebpagePreferences.allowsContentJavaScript = true
        }

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        // Setup the bridge message handler
        let controller = webView.configuration.userContentController
        controller.add(context.coordinator, name: "editorBridge")
        controller.add(context.coordinator, name: "consoleLog")

        // Add console logger to capture JavaScript logs and pipe to Swift
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

        // Inject Swift bridge
        let bridgeScript = WKUserScript(
            source: """
            window.swiftBridge = {
                setContent: function(html) {
                    if (window.editorAPI?.setContent) {
                        window.editorAPI.setContent(html);
                    }
                    return undefined;
                },
                getContent: function() {
                    return window.editorAPI?.getContent() || '';
                }
            };
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        controller.addUserScript(bridgeScript)

        // Inject system appearance detection script
        let appearanceScript = WKUserScript(
            source: """
            (function() {
                // Detect current system appearance
                function detectAppearance() {
                    // Check if dark mode is preferred
                    const isDarkMode = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
                    return isDarkMode ? 'dark' : 'light';
                }

                // Set initial appearance
                window.systemAppearance = detectAppearance();
                document.documentElement.setAttribute('data-theme', window.systemAppearance);
                console.log('🎨 [JS] System appearance:', window.systemAppearance);

                // Listen for appearance changes
                if (window.matchMedia) {
                    const darkModeQuery = window.matchMedia('(prefers-color-scheme: dark)');
                    darkModeQuery.addEventListener('change', (e) => {
                        window.systemAppearance = e.matches ? 'dark' : 'light';
                        document.documentElement.setAttribute('data-theme', window.systemAppearance);
                        console.log('🎨 [JS] System appearance changed to:', window.systemAppearance);
                    });
                }
            })();
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        controller.addUserScript(appearanceScript)

        // Load the WYSIWYG editor HTML
        // The shell script copies files from Resources/Web directly to Resources
        if let bundleURL = Bundle.main.url(forResource: "wysiwyg-editor", withExtension: "html") {
            webView.loadFileURL(bundleURL, allowingReadAccessTo: bundleURL.deletingLastPathComponent())
            print("📝 Using custom WYSIWYG editor from: \(bundleURL.path)")
        } else {
            print("⚠️ Could not find wysiwyg-editor.html in bundle")
            webView.loadHTMLString("<html><body><h1>Error</h1><p>Editor HTML not found</p></body></html>", baseURL: nil)
        }

        // Listen for sync requests from the UI
        context.coordinator.webView = webView
        bridge.webView = webView
        print("🔴 [MilkdownEditorView] Setting up notification observer for SyncEditorContent")
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.syncEditorContent),
            name: NSNotification.Name("SyncEditorContent"),
            object: nil
        )
        print("🔴 [MilkdownEditorView] ✓ Notification observer registered")
        print("🔴 [MilkdownEditorView] ✓ WebView reference set on bridge")

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        print("🔴 [MilkdownWebView.updateNSView] Called")
        print("🔴 [MilkdownWebView.updateNSView] isEditorReady: \(bridge.isEditorReady)")
        print("🔴 [MilkdownWebView.updateNSView] markdownContent length: \(bridge.markdownContent.count)")
        print("🔴 [MilkdownWebView.updateNSView] markdownContent empty?: \(bridge.markdownContent.isEmpty)")

        // Only update if editor is ready and we have content
        guard bridge.isEditorReady else {
            print("🔴 [MilkdownWebView.updateNSView] ⚠️ Editor not ready, skipping update")
            return
        }

        guard !bridge.markdownContent.isEmpty else {
            print("🔴 [MilkdownWebView.updateNSView] ⚠️ No content to load, skipping update")
            return
        }

        print("🔴 [MilkdownWebView.updateNSView] ✓ Conditions met, proceeding with content load")

        // Convert markdown to HTML for the editor
        let html = markdownToHTML(bridge.markdownContent)
        print("🔴 [MilkdownWebView.updateNSView] Converted to HTML, length: \(html.count)")
        print("🔴 [MilkdownWebView.updateNSView] HTML preview: \(html.prefix(150))")

        // Escape the HTML for safe JavaScript embedding
        let escapedHTML = html
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")

        print("🔴 [MilkdownWebView.updateNSView] Escaped HTML length: \(escapedHTML.count)")

        // Call the editor API to set content
        let jsCode = """
        if (window.editorAPI && window.editorAPI.setContent) {
            console.log('📝 [JS] Setting editor content via editorAPI');
            window.editorAPI.setContent("\(escapedHTML)");
        } else {
            console.warn('⚠️ [JS] editorAPI not available');
        }
        """

        print("🔴 [MilkdownWebView.updateNSView] About to call evaluateJavaScript")

        webView.evaluateJavaScript(jsCode) { result, error in
            if let error = error {
                print("❌ [MilkdownWebView] Error updating editor: \(error)")
            } else {
                print("✅ [MilkdownWebView] Editor content update JavaScript executed")
            }
        }
    }

    // Helper function to convert markdown to HTML using marked.js via JavaScript
    private func markdownToHTML(_ markdown: String) -> String {
        // Instead of doing regex conversion in Swift, we'll use the global marked.js parser
        // that's already working in the preview column.
        // This ensures consistent markdown parsing across all columns.
        return markdown  // Return raw markdown, let JavaScript handle conversion with marked.js
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: MilkdownWebView
        var webView: WKWebView?

        init(_ parent: MilkdownWebView) {
            self.parent = parent
            super.init()
            print("🔴 [Coordinator] Initialized")
        }

        deinit {
            print("🔴 [Coordinator] Deinitializing, removing notification observer")
            NotificationCenter.default.removeObserver(self)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ [Coordinator] WYSIWYG editor HTML loaded")
            print("✅ [Coordinator] Waiting 0.5s for scripts to initialize...")
            // Trigger update after a short delay to allow scripts to initialize
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("✅ [Coordinator] 0.5s delay complete, checking state...")
                // Force view update by triggering SwiftUI state change
                DispatchQueue.main.async {
                    print("✅ [Coordinator] Dispatched to main thread")
                    // This will cause updateNSView to be called
                }
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ Failed to load: \(error)")
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            // Handle console log messages
            if message.name == "consoleLog" {
                guard let data = message.body as? [String: Any],
                      let level = data["level"] as? String,
                      let logMessage = data["message"] as? String else {
                    return
                }

                let prefix: String
                switch level {
                case "warn":
                    prefix = "⚠️ [JS]"
                case "error":
                    prefix = "❌ [JS]"
                default:
                    prefix = "📝 [JS]"
                }
                print("\(prefix) \(logMessage)")
                return
            }

            // Handle editor bridge messages
            print("📨 [Coordinator] Received message from JavaScript: \(message.body)")

            guard let data = message.body as? [String: Any],
                  let action = data["action"] as? String else {
                print("⚠️ [Coordinator] Could not parse message data")
                return
            }

            print("📨 [Coordinator] Action: \(action)")

            switch action {
            case "contentChanged":
                print("📝 [Coordinator] ========== CONTENT CHANGED ==========")
                if let content = data["content"] as? String {
                    print("📝 [Coordinator] New content length: \(content.count)")
                    print("📝 [Coordinator] Content preview: \(content.prefix(100))")
                    print("📝 [Coordinator] Current bridge.markdownContent length: \(self.parent.bridge.markdownContent.count)")

                    DispatchQueue.main.async {
                        print("📝 [Coordinator] Updating bridge.markdownContent...")
                        self.parent.bridge.markdownContent = content
                        self.parent.bridge.hasUnsavedChanges = true
                        print("📝 [Coordinator] ✓ Updated bridge.markdownContent")
                        print("📝 [Coordinator] New bridge.markdownContent length: \(self.parent.bridge.markdownContent.count)")
                        print("📝 [Coordinator] ========== CONTENT CHANGED COMPLETE ==========")
                    }
                }

            case "editorReady":
                print("✅ [Coordinator] Editor ready event received!")
                DispatchQueue.main.async {
                    print("✅ [Coordinator] Setting isEditorReady = true")
                    self.parent.bridge.isEditorReady = true

                    // Now that editor is ready, load any pending content
                    print("✅ [Coordinator] Checking for pending content...")
                    print("✅ [Coordinator] bridge.markdownContent length: \(self.parent.bridge.markdownContent.count)")
                    print("✅ [Coordinator] bridge.markdownContent preview: \(self.parent.bridge.markdownContent.prefix(100))")

                    if !self.parent.bridge.markdownContent.isEmpty {
                        print("✅ [Coordinator] ✓ Content exists, triggering objectWillChange")
                        // This will trigger updateNSView which will load the content
                        self.parent.bridge.objectWillChange.send()
                    } else {
                        print("✅ [Coordinator] ⚠️ No pending content to load")
                    }
                }

            case "error":
                print("❌ [Coordinator] Error event received")
                if let error = data["error"] as? String {
                    print("❌ [Coordinator] Error: \(error)")
                }

            case "syncRequested":
                print("🔄 [Coordinator] Sync requested event received")
                if let content = data["content"] as? String {
                    print("🔄 [Coordinator] Synced content length: \(content.count)")
                    DispatchQueue.main.async {
                        self.parent.bridge.markdownContent = content
                        self.parent.bridge.hasUnsavedChanges = true
                        print("🔄 [Coordinator] ✓ Updated bridge.markdownContent from sync")
                    }
                }

            default:
                print("⚠️ [Coordinator] Unknown action: \(action)")
                break
            }
        }

        @objc func syncEditorContent() {
            print("🔄 [Coordinator] syncEditorContent() called from notification")

            guard let webView = webView else {
                print("⚠️ [Coordinator] WebView not available, cannot sync")
                return
            }

            print("🔄 [Coordinator] WebView available, calling JavaScript syncContent()")

            let jsCode = """
            if (window.editorAPI && window.editorAPI.syncContent) {
                console.log('🔄 [JS] syncContent() called');
                window.editorAPI.syncContent();
            } else {
                console.warn('⚠️ [JS] editorAPI.syncContent not available');
            }
            """

            webView.evaluateJavaScript(jsCode) { result, error in
                if let error = error {
                    print("❌ [Coordinator] Error calling syncContent: \(error)")
                } else {
                    print("✅ [Coordinator] syncContent JavaScript executed successfully")
                }
            }
        }
    }
}