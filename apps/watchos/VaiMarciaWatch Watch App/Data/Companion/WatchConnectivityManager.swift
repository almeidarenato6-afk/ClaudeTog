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

/// Wraps `WCSession` — the companion channel used both for Scenario B command relay and for
/// first-run pairing / catalog sync metadata in Scenario A.
///
/// The session is activated once at app launch and kept alive for the process lifetime
/// (docs/ARCHITECTURE.md §4 — persistent companion channel avoids per-tap handshake cost).
final class WatchConnectivityManager: NSObject {
    static let shared = WatchConnectivityManager()

    private let session: WCSession? = WCSession.isSupported() ? .default : nil

    private override init() {
        super.init()
        session?.delegate = self
        session?.activate()
    }

    var isReachable: Bool { session?.isReachable ?? false }

    /// Scenario B critical path: sends only the audioId (a few bytes), never the audio
    /// itself — the phone already has the file cached locally.
    ///
    /// Uses `sendMessage` (requires reachability) for the low-latency happy path, falling
    /// back to `transferUserInfo` (queued, delivered when the phone reconnects) so a tap
    /// taken while the phone is briefly unreachable is not silently dropped.
    func sendPlayCommand(audioId: String, completion: @escaping (Bool) -> Void) {
        guard let session, session.activationState == .activated else {
            completion(false)
            return
        }

        let payload: [String: Any] = [MessageKey.type: MessageType.playCommand, MessageKey.audioId: audioId]

        if session.isReachable {
            session.sendMessage(payload, replyHandler: { _ in completion(true) }, errorHandler: { _ in
                session.transferUserInfo(payload)
                completion(true) // queued for delivery; not a hard failure from the UI's perspective
            })
        } else {
            session.transferUserInfo(payload)
            completion(true)
        }
    }

    /// docs/DEVICE_DETECTION.md step 2 — GET_CAPABILITIES probe, response expected < 200ms.
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
        // No-op: reachability/activation state is read on-demand via `isReachable`.
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
