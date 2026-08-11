import SwiftUI

/// Espelho mínimo, do lado do relógio, do assistente "Vamos configurar seu equipamento" do
/// celular (docs/DEVICE_DETECTION.md). O relógio nunca pergunta nada perceptível ao usuário —
/// apenas mostra o status ao vivo enquanto o celular (fonte da verdade para o pareamento) faz
/// o trabalho de fato.
struct FirstRunSetupView: View {
    @ObservedObject private var playbackController = PlaybackController.shared
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Vamos configurar seu equipamento")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(statusLine)
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Continuar", action: onDone)
                .buttonStyle(.borderedProminent)
                .tint(TogPlayColor.coral)
        }
        .padding()
        .onAppear { playbackController.refreshStrategy() }
    }

    private var statusLine: String {
        switch playbackController.strategy {
        case .direct:
            return "Prontinho! Seu relógio vai tocar direto na sua caixa."
        case .relay:
            return "Prontinho! Seu relógio vai avisar seu celular, que toca na caixa."
        case .phoneOnly:
            return "Abra o app no celular para tocar os áudios."
        }
    }
}

#Preview {
    FirstRunSetupView(onDone: {})
}
