import Foundation
import WatchConnectivity

private enum MessageKey {
    static let type = "type"
    static let audioId = "audioId"
    static let catalog = "catalog"
}

private enum MessageType {
    static let playCommand = "play_command"
    static let getCapabilities = "get_capabilities"
    static let catalogSync = "catalog_sync"
}

/// Envolve o `WCSession` — o canal companion usado tanto para o relay de comandos do
/// Cenário B quanto para o pareamento de primeira execução / metadados de sincronização de
/// catálogo no Cenário A.
///
/// A sessão é ativada uma única vez na inicialização do app e mantida viva durante todo o
/// ciclo de vida do processo (docs/ARCHITECTURE.md §4 — o canal companion persistente evita
/// o custo de handshake a cada toque).
final class WatchConnectivityManager: NSObject {
    static let shared = WatchConnectivityManager()

    private let session: WCSession? = WCSession.isSupported() ? .default : nil

    private override init() {
        super.init()
        session?.delegate = self
        session?.activate()
    }

    var isReachable: Bool { session?.isReachable ?? false }

    /// Caminho crítico do Cenário B: envia apenas o audioId (poucos bytes), nunca o áudio
    /// em si — o celular já tem o arquivo em cache localmente.
    ///
    /// Usa `sendMessage` (requer alcançabilidade) para o caminho feliz de baixa latência,
    /// recorrendo a `transferUserInfo` (enfileirado, entregue quando o celular reconectar)
    /// para que um toque feito enquanto o celular está momentaneamente inalcançável não seja
    /// descartado silenciosamente.
    func sendPlayCommand(audioId: String, completion: @escaping (Bool) -> Void) {
        guard let session, session.activationState == .activated else {
            completion(false)
            return
        }

        let payload: [String: Any] = [MessageKey.type: MessageType.playCommand, MessageKey.audioId: audioId]

        if session.isReachable {
            session.sendMessage(payload, replyHandler: { _ in completion(true) }, errorHandler: { _ in
                session.transferUserInfo(payload)
                completion(true) // enfileirado para entrega; não é uma falha definitiva do ponto de vista da UI
            })
        } else {
            session.transferUserInfo(payload)
            completion(true)
        }
    }

    /// docs/DEVICE_DETECTION.md passo 2 — sondagem GET_CAPABILITIES, resposta esperada < 200ms.
    func requestPhoneCapabilities(completion: @escaping (DeviceCapabilityProfile?) -> Void) {
        guard let session, session.isReachable else {
            completion(nil)
            return
        }
        session.sendMessage(
            [MessageKey.type: MessageType.getCapabilities],
            replyHandler: { reply in
                guard let data = reply[MessageKey.type] as? Data,
                      let profile = try? JSONDecoder().decode(DeviceCapabilityProfile.self, from: data)
                else {
                    completion(nil)
                    return
                }
                completion(profile)
            },
            errorHandler: { _ in completion(nil) },
        )
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Sem operação: o estado de alcançabilidade/ativação é lido sob demanda via `isReachable`.
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard message[MessageKey.type] as? String == MessageType.catalogSync,
              let data = message[MessageKey.catalog] as? Data,
              let clips = try? JSONDecoder().decode([AudioClip].self, from: data)
        else { return }

        Task {
            await CatalogStore.shared.upsertAll(clips)
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        session(session, didReceiveMessage: userInfo)
    }
}
