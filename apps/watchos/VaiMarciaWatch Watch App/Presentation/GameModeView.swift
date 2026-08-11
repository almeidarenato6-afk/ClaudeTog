import SwiftUI

/// "Modo Jogo" — um punhado de botões enormes e de leitura rápida. Um toque inicia a reprodução
/// imediatamente; sem diálogos de confirmação, sem navegação aninhada, chrome mínimo para
/// continuar utilizável no meio de uma partida.
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
        // A resolução de catálogo de "qual audioId dentro desta categoria toca agora"
        // (rodízio/aleatório/favorito mais recente) fica em um caso de uso apoiado em
        // CatalogStore; omitido aqui para manter este esqueleto focado no contrato de
        // roteamento de reprodução, conectado da mesma forma que o caso de uso
        // equivalente do app mobile.
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
