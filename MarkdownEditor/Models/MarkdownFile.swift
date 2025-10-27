import Foundation

struct MarkdownFile: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var url: URL?
    var content: String

    // Custom equality based on URL (or name if no URL)
    static func == (lhs: MarkdownFile, rhs: MarkdownFile) -> Bool {
        if let lhsUrl = lhs.url, let rhsUrl = rhs.url {
            return lhsUrl == rhsUrl
        }
        return lhs.name == rhs.name && lhs.content == rhs.content
    }

    /// Safely write file with proper error handling and sandbox permissions
    func write() throws {
        guard let url = url else {
            throw MarkdownFileError.noURLProvided
        }

        // Create security-scoped access if needed
        let accessGranted = url.startAccessingSecurityScopedResource()
        defer {
            if accessGranted {
                url.stopAccessingSecurityScopedResource()
            }
        }

        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Safely read file with proper error handling and sandbox permissions
    static func read(from url: URL) throws -> MarkdownFile {
        let accessGranted = url.startAccessingSecurityScopedResource()
        defer {
            if accessGranted {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let content = try String(contentsOf: url, encoding: .utf8)
        return MarkdownFile(
            name: url.lastPathComponent,
            url: url,
            content: content
        )
    }
}

enum MarkdownFileError: LocalizedError {
    case noURLProvided
    case failedToWrite
    case failedToRead

    var errorDescription: String? {
        switch self {
        case .noURLProvided:
            return "File has no URL. Please save to a location first."
        case .failedToWrite:
            return "Failed to write file. Please check permissions."
        case .failedToRead:
            return "Failed to read file. Please check permissions."
        }
    }
}

extension URL {
    var creationDate: Date {
        (try? resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date()
    }
}

extension Notification.Name {
    static let newMarkdownFile = Notification.Name("newMarkdownFile")
    static let openMarkdownFile = Notification.Name("openMarkdownFile")
    static let saveMarkdownFile = Notification.Name("saveMarkdownFile")
    static let markdownFileSelected = Notification.Name("markdownFileSelected")
    static let fileSaved = Notification.Name("fileSaved")
}