import SwiftUI

/// "Modo Jogo" — a handful of huge, glanceable buttons. One tap starts playback immediately;
/// no confirmation dialogs, no nested navigation, minimal chrome so it stays usable mid-match.
struct GameModeView: View {
    @ObservedObject private var playbackController = PlaybackController.shared
    @State private var lastTapFeedback: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(Category.allCases) { category in
                    CategoryButton(category: category) {
                        onCategoryTapped(category)
                    }
                }
                if let lastTapFeedback {
                    Text(lastTapFeedback)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 4)
        }
        .background(TogPlayColor.navy)
    }

    private func onCategoryTapped(_ category: Category) {
        // The catalog resolution of "which audioId within this category plays now"
        // (round-robin/random/most-recent-favorite) lives in a use case backed by
        // CatalogStore; omitted here to keep this scaffold focused on the playback
        // routing contract, wired the same way the mobile app's use case is.
        let audioId = "\(category.id)_default"
        playbackController.play(audioId: audioId) { result in
            switch result {
            case .started:
                lastTapFeedback = nil
            case .failed:
                lastTapFeedback = "Ops, tente de novo"
            }
        }
    }
}

private struct CategoryButton: View {
    let category: Category
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(category.emoji)
                    .font(.title2)
                Text(category.label)
                    .font(.headline)
                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(.horizontal, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(TogPlayColor.coral)
    }
}

#Preview {
    GameModeView()
}
