import Foundation

/// Scenario B: dispatches the play command to the phone over the persistent
/// `WatchConnectivity` session. The phone already has the audio cached and plays it to the
/// paired Bluetooth speaker — from the user's perspective this is indistinguishable from
/// Scenario A.
final class RelayPlaybackDispatcher: PlaybackEngine {
    private let connectivity: WatchConnectivityManager

    init(connectivity: WatchConnectivityManager = .shared) {
        self.connectivity = connectivity
    }

    func play(audioId: String, completion: @escaping (PlaybackResult) -> Void) {
        connectivity.sendPlayCommand(audioId: audioId) { delivered in
            completion(delivered ? .started : .failed(reason: "phone_unreachable"))
        }
    }
}
