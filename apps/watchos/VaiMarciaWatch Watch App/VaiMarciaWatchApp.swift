import SwiftUI

@main
struct VaiMarciaWatchApp: App {
    @AppStorage("setupComplete") private var setupComplete = false

    // Força a ativação da sessão WatchConnectivity na inicialização (docs/ARCHITECTURE.md §4 —
    // canal companion persistente, não reconectado a cada toque).
    private let connectivity = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            if setupComplete {
                GameModeView()
            } else {
                FirstRunSetupView(onDone: { setupComplete = true })
            }
        }
    }
}
