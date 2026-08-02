import Foundation

/// Mirrors the mobile app's `AudioClip` domain entity conceptually (see
/// apps/mobile/lib/features/audio_playback/domain). Pure Swift — no platform SDK imports.
struct AudioClip: Identifiable, Equatable, Codable {
    let id: String
    let categoryId: String
    let title: String
    let localFileName: String?
    let durationMs: Int
    var isFavorite: Bool = false

    var isCachedLocally: Bool { localFileName != nil && !(localFileName?.isEmpty ?? true) }
}
