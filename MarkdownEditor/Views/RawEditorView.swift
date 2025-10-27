import SwiftUI

struct RawEditorView: View {
    @ObservedObject var bridge: EditorBridge
    @State private var viewMode: String = "Monospace"

    enum ViewMode: String, CaseIterable {
        case monospace = "Monospace"
        case highlight = "Highlight"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Picker(selection: $viewMode, label: EmptyView()) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 280)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44, idealHeight: 44)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.controlBackgroundColor).opacity(0.5))

            Divider()

            if viewMode == ViewMode.monospace.rawValue {
                TextEditor(text: $bridge.markdownContent)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(Color(.textColor))
                    .onChange(of: bridge.markdownContent) { oldValue, newValue in
                        print("🟡 [RawEditorView] markdownContent changed")
                        print("🟡 [RawEditorView] Old length: \(oldValue.count), New length: \(newValue.count)")
                        print("🟡 [RawEditorView] New content preview: \(newValue.prefix(100))")
                    }
                    .onAppear {
                        print("🟡 [RawEditorView] View appeared, markdownContent: \(bridge.markdownContent.prefix(100))")
                    }
            } else {
                MarkdownHighlighterView(bridge: bridge)
            }
        }
    }
}