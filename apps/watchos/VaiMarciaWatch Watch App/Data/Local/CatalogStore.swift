import Foundation

/// Persistência leve baseada em arquivo para o subconjunto local do catálogo (pacote inicial
/// + deltas sincronizados a partir do celular). Deliberadamente não usa SwiftData: o piso de
/// implantação deste target é o watchOS 9 (para cobrir dispositivos Series 4+ ainda elegíveis
/// para o modo RELAY, não apenas o piso do watchOS 10+ exigido pelo SwiftData), então um
/// armazenamento simples baseado em JSON é usado em vez disso.
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
