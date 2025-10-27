import SwiftUI

struct ContentView: View {
    @StateObject private var fileManager = MarkdownFileManager()
    @StateObject private var bridge = EditorBridge()
    @State private var previewRefreshId = UUID()

    var body: some View {
        NavigationSplitView {
            // MARK: - Sidebar (Column 1): File Browser
            FileBrowserView(fileManager: fileManager, bridge: bridge)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)

        } detail: {
            // MARK: - Detail: Three-column layout showing content
            HStack(spacing: 0) {
                // Editor Column
                if bridge.isEditorColumnVisible {
                    VStack(spacing: 0) {
                        MilkdownEditorView(bridge: bridge)
                    }
                    .frame(minWidth: 300, maxWidth: .infinity)

                    if bridge.isRawColumnVisible || bridge.isPreviewColumnVisible {
                        Divider()
                    }
                }

                // Raw Editor Column
                if bridge.isRawColumnVisible {
                    VStack(spacing: 0) {
                        RawEditorView(bridge: bridge)
                    }
                    .frame(minWidth: 300, maxWidth: .infinity)

                    if bridge.isPreviewColumnVisible {
                        Divider()
                    }
                }

                // Preview Column
                if bridge.isPreviewColumnVisible {
                    VStack(spacing: 0) {
                        PreviewView(bridge: bridge)
                            .id(previewRefreshId)
                            .onAppear {
                                // Force update when the view appears
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    let content = bridge.markdownContent
                                    bridge.markdownContent = content
                                }
                            }
                    }
                    .frame(minWidth: 300, maxWidth: .infinity)
                    .onChange(of: bridge.isPreviewColumnVisible) { oldValue, newValue in
                        if newValue {
                            // Refresh the preview when toggled back on by generating a new ID
                            previewRefreshId = UUID()
                        }
                    }
                }
            }
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                HStack(spacing: 16) {
                    // Status indicator on the left
                    if bridge.hasUnsavedChanges {
                        Text("Unsaved")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }

                    Spacer()

                    // Button-styled toggle controls for each column
                    HStack(spacing: 8) {
                        Button(action: { toggleColumn(.editor) }) {
                            Text("Editor")
                                .font(.body)
                        }
                        .buttonStyle(ToggleButtonStyle(isOn: bridge.isEditorColumnVisible, position: .first))

                        Button(action: { toggleColumn(.raw) }) {
                            Text("Markdown")
                                .font(.body)
                        }
                        .buttonStyle(ToggleButtonStyle(isOn: bridge.isRawColumnVisible, position: .middle))

                        Button(action: { toggleColumn(.preview) }) {
                            Text("Preview")
                                .font(.body)
                        }
                        .buttonStyle(ToggleButtonStyle(isOn: bridge.isPreviewColumnVisible, position: .last))
                    }

                    // Save button with text label, larger and on the right
                    Button(action: saveFile) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save")
                                .font(.body)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .help("Save (⌘S)")
                    .keyboardShortcut("s", modifiers: .command)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .newMarkdownFile)) { _ in
            bridge.createNewFile()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openMarkdownFile)) { _ in
            fileManager.showFilePicker()
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveMarkdownFile)) { _ in
            saveFile()
        }
        .onReceive(NotificationCenter.default.publisher(for: .markdownFileSelected)) { notification in
            if let url = notification.object as? URL {
                do {
                    let file = try MarkdownFile.read(from: url)
                    bridge.currentFile = file
                    bridge.loadContent(file.content)
                    print("🟢 [ContentView] Loaded file: \(file.name)")
                } catch {
                    print("❌ [ContentView] Error loading file: \(error.localizedDescription)")
                }
            }
        }
        .onChange(of: bridge.currentFile) { oldValue, newValue in
            print("🟠 [ContentView] currentFile changed")
            print("🟠 [ContentView] Old file: \(oldValue?.name ?? "nil")")
            print("🟠 [ContentView] New file: \(newValue?.name ?? "nil")")
        }
        .onChange(of: bridge.markdownContent) { oldValue, newValue in
            print("🟠 [ContentView] markdownContent changed in bridge")
            print("🟠 [ContentView] Old length: \(oldValue.count), New length: \(newValue.count)")
        }
        .onChange(of: bridge.isEditorReady) { oldValue, newValue in
            print("🟠 [ContentView] isEditorReady changed: \(oldValue) -> \(newValue)")
        }
    }

    // MARK: - Methods

    private func saveFile() {
        bridge.saveFile()
    }

    private func toggleColumn(_ column: ColumnType) {
        // Count how many columns are currently visible
        let visibleCount = [bridge.isEditorColumnVisible, bridge.isRawColumnVisible, bridge.isPreviewColumnVisible]
            .filter { $0 }
            .count

        // Determine if toggling this column would result in zero visible columns
        let isLastVisibleColumn = visibleCount == 1 && {
            switch column {
            case .editor:
                return bridge.isEditorColumnVisible
            case .raw:
                return bridge.isRawColumnVisible
            case .preview:
                return bridge.isPreviewColumnVisible
            }
        }()

        // Allow toggle only if it won't leave us with zero columns
        if !isLastVisibleColumn {
            switch column {
            case .editor:
                bridge.isEditorColumnVisible.toggle()
            case .raw:
                bridge.isRawColumnVisible.toggle()
            case .preview:
                bridge.isPreviewColumnVisible.toggle()
            }
        }
    }
}

enum ColumnType {
    case editor
    case raw
    case preview
}

// MARK: - Toggle Button Style

enum ButtonPosition {
    case first
    case middle
    case last
}

struct ToggleButtonStyle: ButtonStyle {
    let isOn: Bool
    let position: ButtonPosition

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isOn
                    ? Color(.controlBackgroundColor)
                    : Color.accentColor.opacity(0.5)
            )
            .foregroundColor(
                isOn
                    ? .primary
                    : .accentColor
            )
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray, lineWidth: 0.5)
            )
            .opacity(configuration.isPressed ? 1.0 : 0.75)
    }
}
