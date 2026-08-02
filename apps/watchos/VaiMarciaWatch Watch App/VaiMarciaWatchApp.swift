import SwiftUI

@main
struct VaiMarciaWatchApp: App {
    @AppStorage("setupComplete") private var setupComplete = false

    // Force WatchConnectivity session activation at launch (docs/ARCHITECTURE.md §4 —
    // persistent companion channel, not reconnected per tap).
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
