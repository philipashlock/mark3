import SwiftUI

@main
struct MarkdownEditorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Markdown File") {
                    NotificationCenter.default.post(name: .newMarkdownFile, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(after: .newItem) {
                Button("Open File...") {
                    NotificationCenter.default.post(name: .openMarkdownFile, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            CommandGroup(before: .saveItem) {
                Button("Save") {
                    NotificationCenter.default.post(name: .saveMarkdownFile, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)
            }
        }
        .defaultSize(width: 1400, height: 900)
    }
}
