import AVFoundation
import Foundation

/// Scenario A: plays a locally cached clip directly through `AVAudioPlayer`, routed by the
/// OS to whatever Bluetooth Classic / LE Audio output is currently connected to the watch.
/// A single long-lived `AVAudioSession` category is configured once (docs/ARCHITECTURE.md
/// §4 — avoids per-tap session negotiation cost).
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
                // Interrupts whatever is currently playing — one motivational clip at a
                // time, never queued, to keep taps feeling instantaneous.
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
