import SwiftUI

/// A generic toolbar header for content columns
/// Provides consistent height and styling across all three columns
/// Used as empty placeholder for now, can be populated with UI buttons later
struct ColumnToolbar: View {
    var body: some View {
        VStack(spacing: 0) {
            // Empty toolbar placeholder with consistent height and styling
            HStack(spacing: 8) {
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.controlBackgroundColor).opacity(0.5))

            Divider()
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        ColumnToolbar()
        ColumnToolbar()
        ColumnToolbar()
    }
}
