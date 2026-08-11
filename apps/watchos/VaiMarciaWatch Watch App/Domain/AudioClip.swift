import Foundation

/// Espelha conceitualmente a entidade de domínio `AudioClip` do app mobile (veja
/// apps/mobile/lib/features/audio_playback/domain). Swift puro — sem imports de SDK de plataforma.
struct AudioClip: Identifiable, Equatable, Codable {
    let id: String
    let categoryId: String
    let title: String
    let localFileName: String?
    let durationMs: Int
    var isFavorite: Bool = false

    var isCachedLocally: Bool { localFileName != nil && !(localFileName?.isEmpty ?? true) }
}
