import SwiftUI

extension View {
    /// Replaces a list's default white background with Hacker News' off-white.
    func hackerNewsListBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Color(.hnBackground))
    }

    /// Tighter than the system's default row padding, so more fits on screen.
    func compactListRow() -> some View {
        listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
    }

    /// Plain list rows draw their own white background, so they need the colour too.
    func hackerNewsRowBackground() -> some View {
        listRowBackground(Color(.hnBackground))
    }
}
