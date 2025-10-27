import SwiftUI

struct FileBrowserView: View {
    @ObservedObject var fileManager: MarkdownFileManager
    @ObservedObject var bridge: EditorBridge
    @State private var selectedFileId: UUID?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Files")
                    .font(.headline)
                Spacer()
                Button(action: fileManager.changeDirectory) {
                    Image(systemName: "folder")
                }
                .buttonStyle(.borderless)
                .help("Change Directory")
                
                Button(action: fileManager.loadFiles) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh")
            }
            .padding()
            
            Divider()
            
            List(fileManager.files, id: \.id, selection: $selectedFileId) { file in
                HStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .foregroundColor(.accentColor)
                    Text(file.name)
                        .fontWeight(file.id == bridge.currentFile?.id ? .semibold : .regular)
                    Spacer()
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .contentShape(Rectangle())
                .background(
                    file.id == bridge.currentFile?.id
                        ? Color.accentColor.opacity(0.15)
                        : Color.clear
                )
                .cornerRadius(4)
                .onTapGesture {
                    openFile(file)
                }
                .tag(file.id)
            }
            .onChange(of: selectedFileId) { oldId, newId in
                // When selection changes, open the selected file
                if let selectedId = newId, let selectedFile = fileManager.files.first(where: { $0.id == selectedId }) {
                    openFile(selectedFile)
                }
            }
            .onKeyPress(.upArrow) {
                navigateFiles(direction: .up)
                return .handled
            }
            .onKeyPress(.downArrow) {
                navigateFiles(direction: .down)
                return .handled
            }
            .onKeyPress(.return) {
                if let selectedId = selectedFileId, let selectedFile = fileManager.files.first(where: { $0.id == selectedId }) {
                    openFile(selectedFile)
                }
                return .handled
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { bridge.createNewFile() }) {
                    Image(systemName: "plus")
                }
                .help("New File")
            }
        }
        .onAppear {
            // Initialize selection to current file if available
            if let currentId = bridge.currentFile?.id {
                selectedFileId = currentId
            }
        }
    }

    // MARK: - Helper Methods

    private func openFile(_ file: MarkdownFile) {
        print("🔵 [FileBrowserView] User selected file: \(file.name)")
        print("🔵 [FileBrowserView] File URL: \(file.url?.path ?? "No URL")")
        print("🔵 [FileBrowserView] Content length: \(file.content.count) characters")
        print("🔵 [FileBrowserView] Content preview: \(file.content.prefix(100))")

        // Update bridge
        bridge.currentFile = file
        print("🔵 [FileBrowserView] ✓ Set currentFile on bridge")

        bridge.loadContent(file.content)
        print("🔵 [FileBrowserView] ✓ Called loadContent on bridge")
    }

    private func navigateFiles(direction: NavigationDirection) {
        guard !fileManager.files.isEmpty else { return }

        let currentIndex: Int
        if let selectedId = selectedFileId, let index = fileManager.files.firstIndex(where: { $0.id == selectedId }) {
            currentIndex = index
        } else {
            // No selection, start from beginning
            currentIndex = direction == .down ? -1 : fileManager.files.count
        }

        let nextIndex: Int
        switch direction {
        case .up:
            nextIndex = max(0, currentIndex - 1)
        case .down:
            nextIndex = min(fileManager.files.count - 1, currentIndex + 1)
        }

        guard nextIndex >= 0 && nextIndex < fileManager.files.count else { return }
        selectedFileId = fileManager.files[nextIndex].id
    }

    enum NavigationDirection {
        case up
        case down
    }
}