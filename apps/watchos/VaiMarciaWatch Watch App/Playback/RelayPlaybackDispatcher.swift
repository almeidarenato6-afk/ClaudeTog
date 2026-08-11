import Foundation

/// Cenário B: envia o comando de reprodução para o celular pela sessão persistente do
/// `WatchConnectivity`. O celular já tem o áudio em cache e o reproduz na caixa Bluetooth
/// pareada — da perspectiva do usuário, isso é indistinguível do Cenário A.
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
