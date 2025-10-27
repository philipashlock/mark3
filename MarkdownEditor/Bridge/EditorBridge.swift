import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers
import WebKit

class EditorBridge: NSObject, ObservableObject {
    @Published var currentFile: MarkdownFile?
    @Published var markdownContent: String = ""
    @Published var hasUnsavedChanges: Bool = false
    @Published var isEditorReady: Bool = false

    // Column visibility state
    @Published var isEditorColumnVisible: Bool = true
    @Published var isRawColumnVisible: Bool = true
    @Published var isPreviewColumnVisible: Bool = true

    private var lastSavedContent: String = ""

    override init() {
        super.init()
    }

    func loadContent(_ markdown: String) {
        print("🟢 [EditorBridge.loadContent] Called with \(markdown.count) characters")
        print("🟢 [EditorBridge.loadContent] Content preview: \(markdown.prefix(100))")

        // Store raw markdown
        markdownContent = markdown
        print("🟢 [EditorBridge.loadContent] ✓ Set markdownContent")
        print("🟢 [EditorBridge.loadContent] markdownContent is now: \(markdownContent.prefix(100))")

        lastSavedContent = markdown
        print("🟢 [EditorBridge.loadContent] ✓ Set lastSavedContent")
    }

    private func markdownToHTML(_ markdown: String) -> String {
        // Simple markdown to HTML conversion
        var html = markdown

        // Convert markdown headings to HTML (process in order from h6 to h1 to avoid conflicts)
        html = html.replacingOccurrences(of: "^###### (.+)$", with: "<h6>$1</h6>", options: .regularExpression)
        html = html.replacingOccurrences(of: "^##### (.+)$", with: "<h5>$1</h5>", options: .regularExpression)
        html = html.replacingOccurrences(of: "^#### (.+)$", with: "<h4>$1</h4>", options: .regularExpression)
        html = html.replacingOccurrences(of: "^### (.+)$", with: "<h3>$1</h3>", options: .regularExpression)
        html = html.replacingOccurrences(of: "^## (.+)$", with: "<h2>$1</h2>", options: .regularExpression)
        html = html.replacingOccurrences(of: "^# (.+)$", with: "<h1>$1</h1>", options: .regularExpression)

        // Convert **bold** to <strong>
        html = html.replacingOccurrences(of: "\\*\\*(.+?)\\*\\*", with: "<strong>$1</strong>", options: .regularExpression)

        // Convert *italic* to <em>
        html = html.replacingOccurrences(of: "\\*(.+?)\\*", with: "<em>$1</em>", options: .regularExpression)

        // Convert `code` to <code>
        html = html.replacingOccurrences(of: "`(.+?)`", with: "<code>$1</code>", options: .regularExpression)

        // Handle paragraphs - split by double newlines
        let paragraphs = html.components(separatedBy: "\n\n")
        html = paragraphs.map { para in
            let trimmed = para.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                return ""
            }
            // Check if it's already an HTML block element
            if trimmed.hasPrefix("<h") || trimmed.hasPrefix("<ul") || trimmed.hasPrefix("<ol") || trimmed.hasPrefix("<blockquote") || trimmed.hasPrefix("<pre") {
                return trimmed
            }
            // It's a regular paragraph
            return "<p>\(trimmed)</p>"
        }.joined(separator: "\n")

        return html
    }

    func saveFile() {
        guard var file = currentFile else { return }

        if let url = file.url {
            // Existing file - update it
            file.content = markdownContent
            do {
                try file.write()
                lastSavedContent = markdownContent
                hasUnsavedChanges = false
                currentFile = file
                NotificationCenter.default.post(name: .fileSaved, object: url)
            } catch {
                print("Error saving file: \(error.localizedDescription)")
            }
        } else {
            // New file - show save panel
            showSavePanel()
        }
    }

    private func showSavePanel() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: "md")!]
        panel.nameFieldStringValue = currentFile?.name ?? "Untitled.md"

        // Start in Documents directory if available
        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            panel.directoryURL = documentsURL
        }

        panel.begin { [weak self] response in
            guard let self = self else { return }
            if response == .OK, let url = panel.url {
                var file = self.currentFile ?? MarkdownFile(name: url.lastPathComponent, url: url, content: self.markdownContent)
                file.url = url
                file.name = url.lastPathComponent
                file.content = self.markdownContent

                do {
                    try file.write()
                    self.currentFile = file
                    self.lastSavedContent = self.markdownContent
                    self.hasUnsavedChanges = false
                    NotificationCenter.default.post(name: .fileSaved, object: url)
                } catch {
                    print("Error saving file: \(error.localizedDescription)")
                }
            }
        }
    }

    func createNewFile() {
        print("🟢 [EditorBridge.createNewFile] Creating new document")
        let newContent = "# New Document\n\nStart writing here...\n"
        let newFile = MarkdownFile(
            name: "Untitled.md",
            url: nil,
            content: newContent
        )
        print("🟢 [EditorBridge.createNewFile] ✓ Created MarkdownFile object")

        currentFile = newFile
        print("🟢 [EditorBridge.createNewFile] ✓ Set currentFile")

        loadContent(newFile.content)
        print("🟢 [EditorBridge.createNewFile] ✓ Called loadContent")

        lastSavedContent = newFile.content
        print("🟢 [EditorBridge.createNewFile] ✓ File ready for editing")
    }

    // MARK: - Formatting Commands

    var webView: WKWebView?

    func executeFormattingCommand(_ command: String) {
        guard let webView = webView else {
            print("❌ [EditorBridge] WebView not available for command: \(command)")
            return
        }

        let jsCode = """
        if (window.editorAPI && window.editorAPI.executeCommand) {
            window.editorAPI.executeCommand('\(command)');
        } else {
            console.warn('⚠️ editorAPI.executeCommand not available for: \(command)');
        }
        """

        webView.evaluateJavaScript(jsCode) { result, error in
            if let error = error {
                print("❌ [EditorBridge] Error executing command '\(command)': \(error)")
            } else {
                print("✅ [EditorBridge] Executed formatting command: \(command)")
            }
        }
    }

    func getActiveFormats(_ completion: @escaping ([String]) -> Void) {
        guard let webView = webView else {
            print("❌ [EditorBridge] WebView not available for getActiveFormats")
            completion([])
            return
        }

        let jsCode = """
        (function() {
            if (window.editorAPI && window.editorAPI.getActiveMarks) {
                const marks = window.editorAPI.getActiveMarks();
                return JSON.stringify(marks || []);
            }
            return JSON.stringify([]);
        })();
        """

        webView.evaluateJavaScript(jsCode) { result, error in
            if let error = error {
                print("❌ [EditorBridge] Error getting active formats: \(error)")
                completion([])
                return
            }

            if let jsonString = result as? String {
                do {
                    if let jsonData = jsonString.data(using: .utf8),
                       let marks = try JSONSerialization.jsonObject(with: jsonData) as? [String] {
                        print("✅ [EditorBridge] Active formats: \(marks)")
                        completion(marks)
                        return
                    }
                } catch {
                    print("⚠️ [EditorBridge] Error parsing active formats: \(error)")
                }
            }

            completion([])
        }
    }
}