import Foundation

/// Common contract implemented by both DIRECT and RELAY engines so the UI layer never
/// branches on strategy — it just asks the resolver-selected engine to play.
protocol PlaybackEngine {
    func play(audioId: String, completion: @escaping (PlaybackResult) -> Void)
}

enum PlaybackResult {
    case started
    case failed(reason: String)
}
