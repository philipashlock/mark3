import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers

class MarkdownFileManager: ObservableObject {
    @Published var files: [MarkdownFile] = []
    @Published var currentDirectory: URL

    private let userDefaults = UserDefaults.standard
    private let bookmarkKey = "DocumentsDirectoryBookmark"

    init() {
        // Get the Documents folder
        let documentsDir = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.homeDirectoryForCurrentUser
        currentDirectory = documentsDir

        // Try to restore from bookmark first (for sandbox permission preservation)
        if let bookmarkData = userDefaults.data(forKey: bookmarkKey) {
            do {
                var isStale = false
                let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)

                // Start accessing the security-scoped URL
                _ = url.startAccessingSecurityScopedResource()

                currentDirectory = url
                if isStale {
                    // Update the bookmark if it became stale
                    saveDirectoryBookmark(url)
                }
            } catch {
                print("Error restoring bookmark: \(error)")
                // Fall back to Documents folder
                currentDirectory = documentsDir
            }
        } else {
            // First launch: save bookmark for Documents folder
            saveDirectoryBookmark(documentsDir)
        }

        loadFiles()
    }

    private func getDefaultDocumentsDirectory() -> URL {
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.homeDirectoryForCurrentUser
    }

    private func saveDirectoryBookmark(_ url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            userDefaults.set(bookmarkData, forKey: bookmarkKey)
        } catch {
            print("Error saving directory bookmark: \(error)")
        }
    }

    func loadFiles() {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: currentDirectory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )

            files = fileURLs
                .filter { $0.pathExtension == "md" || $0.pathExtension == "markdown" }
                .compactMap { url -> MarkdownFile? in
                    guard let content = try? String(contentsOf: url, encoding: .utf8) else {
                        return nil
                    }
                    return MarkdownFile(
                        name: url.lastPathComponent,
                        url: url,
                        content: content
                    )
                }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            print("Error loading files: \(error)")
        }
    }

    func showFilePicker() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.init(filenameExtension: "md")!]
        panel.message = "Open a markdown file"
        panel.directoryURL = currentDirectory

        if panel.runModal() == .OK, let url = panel.url {
            // Update directory to the file's directory and save bookmark
            let fileDirectory = url.deletingLastPathComponent()
            currentDirectory = fileDirectory
            saveDirectoryBookmark(fileDirectory)
            loadFiles()

            // Post notification to load the opened file
            NotificationCenter.default.post(name: .markdownFileSelected, object: url)
        }
    }

    func changeDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose a directory containing markdown files"
        panel.directoryURL = currentDirectory

        if panel.runModal() == .OK, let url = panel.url {
            currentDirectory = url
            saveDirectoryBookmark(url)
            loadFiles()
        }
    }

    deinit {
        // Stop accessing security-scoped resource when done
        currentDirectory.stopAccessingSecurityScopedResource()
    }
}