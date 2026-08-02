import SwiftUI

/// Minimal watch-side mirror of the phone's "Vamos configurar seu equipamento" wizard
/// (docs/DEVICE_DETECTION.md). The watch never asks the user anything detectable — it just
/// shows live status while the phone (source of truth for pairing) does the real work.
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
