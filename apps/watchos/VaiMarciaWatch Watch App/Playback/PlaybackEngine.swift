import Foundation

/// Contrato comum implementado tanto pelo engine DIRECT quanto pelo RELAY, para que a
/// camada de UI nunca precise ramificar com base na estratégia — ela apenas pede ao engine
/// selecionado pelo resolver para reproduzir.
protocol PlaybackEngine {
    func play(audioId: String, completion: @escaping (PlaybackResult) -> Void)
}

enum PlaybackResult {
    case started
    case failed(reason: String)
}
