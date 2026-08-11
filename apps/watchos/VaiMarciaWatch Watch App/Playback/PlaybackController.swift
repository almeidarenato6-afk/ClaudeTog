import Combine
import Foundation

/// Único ponto de entrada que a camada de apresentação chama ao tocar em um botão. Guarda a
/// estratégia já resolvida (definida na inicialização / mudança de pareamento, veja
/// `PlaybackStrategyResolver`) e roteia para o engine correspondente — sem cálculo de
/// estratégia a cada toque.
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
