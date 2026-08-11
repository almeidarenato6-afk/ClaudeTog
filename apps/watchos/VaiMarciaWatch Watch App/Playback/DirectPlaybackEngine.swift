import AVFoundation
import Foundation

/// Cenário A: reproduz um clipe em cache localmente direto pelo `AVAudioPlayer`, roteado pelo
/// SO para qualquer saída Bluetooth Classic / LE Audio atualmente conectada ao relógio.
/// Uma única categoria de longa duração do `AVAudioSession` é configurada uma vez
/// (docs/ARCHITECTURE.md §4 — evita o custo de negociação de sessão a cada toque).
final class DirectPlaybackEngine: PlaybackEngine {
    private var player: AVAudioPlayer?
    private let session = AVAudioSession.sharedInstance()

    init() {
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setActive(true)
    }

    func play(audioId: String, completion: @escaping (PlaybackResult) -> Void) {
        Task {
            guard let clip = await CatalogStore.shared.clip(id: audioId) else {
                completion(.failed(reason: "unknown_audio_id"))
                return
            }

            let fileURL: URL
            if let localFileName = clip.localFileName, !localFileName.isEmpty {
                fileURL = AudioCacheManager.shared.fileURL(for: audioId)
            } else if AudioCacheManager.shared.isCached(audioId) {
                fileURL = AudioCacheManager.shared.fileURL(for: audioId)
            } else {
                completion(.failed(reason: "not_cached_locally"))
                return
            }

            do {
                // Interrompe o que estiver tocando no momento — um clipe motivacional por
                // vez, nunca enfileirado, para manter a sensação de resposta instantânea aos toques.
                player?.stop()
                let newPlayer = try AVAudioPlayer(contentsOf: fileURL)
                newPlayer.prepareToPlay()
                newPlayer.play()
                player = newPlayer
                completion(.started)
            } catch {
                completion(.failed(reason: "player_error"))
            }
        }
    }
}
