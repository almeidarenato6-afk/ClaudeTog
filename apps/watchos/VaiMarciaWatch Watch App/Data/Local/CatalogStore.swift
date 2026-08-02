import Foundation

/// Lightweight file-based persistence for the local subset of the catalog (starter pack +
/// deltas synced from the phone). Deliberately not SwiftData: this target's deployment
/// floor is watchOS 9 (to cover Series 4+ devices still eligible for RELAY mode, not just
/// the watchOS 10+ SwiftData baseline), so a plain JSON-backed store is used instead.
actor CatalogStore {
    static let shared = CatalogStore()

    private let fileURL: URL
    private var cache: [String: AudioClip] = [:]

    private init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documents.appendingPathComponent("catalog.json")
        cache = Self.load(from: fileURL)
    }

    private static func load(from url: URL) -> [String: AudioClip] {
        guard let data = try? Data(contentsOf: url),
              let clips = try? JSONDecoder().decode([AudioClip].self, from: data)
        else { return [:] }
        return Dictionary(uniqueKeysWithValues: clips.map { ($0.id, $0) })
    }

    private func persist() {
        let clips = Array(cache.values)
        guard let data = try? JSONEncoder().encode(clips) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func upsertAll(_ clips: [AudioClip]) {
        for clip in clips { cache[clip.id] = clip }
        persist()
    }

    func clip(id: String) -> AudioClip? { cache[id] }

    func clips(in category: Category) -> [AudioClip] {
        cache.values.filter { $0.categoryId == category.id }.sorted { $0.title < $1.title }
    }

    func favorites() -> [AudioClip] {
        cache.values.filter(\.isFavorite).sorted { $0.title < $1.title }
    }
}
