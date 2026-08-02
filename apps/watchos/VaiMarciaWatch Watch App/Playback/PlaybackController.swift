import Combine
import Foundation

/// Single entry point the presentation layer calls on button tap. Holds the
/// already-resolved strategy (set at launch / pairing-change, see `PlaybackStrategyResolver`)
/// and routes to the matching engine — no per-tap strategy computation.
final class PlaybackController: ObservableObject {
    static let shared = PlaybackController()

    @Published private(set) var strategy: PlaybackStrategy = .phoneOnly

    private let resolver: PlaybackStrategyResolver
    private let directEngine: PlaybackEngine
    private let relayDispatcher: PlaybackEngine

    init(
        resolver: PlaybackStrategyResolver = PlaybackStrategyResolver(),
        directEngine: PlaybackEngine = DirectPlaybackEngine(),
        relayDispatcher: PlaybackEngine = RelayPlaybackDispatcher(),
    ) {
        self.resolver = resolver
        self.directEngine = directEngine
        self.relayDispatcher = relayDispatcher
        refreshStrategy()
    }

    func refreshStrategy() {
        strategy = resolver.resolve()
    }

    func play(audioId: String, completion: @escaping (PlaybackResult) -> Void = { _ in }) {
        switch strategy {
        case .direct:
            directEngine.play(audioId: audioId, completion: completion)
        case .relay:
            relayDispatcher.play(audioId: audioId, completion: completion)
        case .phoneOnly:
            completion(.failed(reason: "phone_only_no_watch_output"))
        }
    }
}
