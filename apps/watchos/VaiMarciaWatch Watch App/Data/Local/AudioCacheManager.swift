import Foundation

/// Gerencia os arquivos de áudio em cache no diretório `Documents/AudioCache` do container
/// do app. O armazenamento de apps watchOS é pequeno, então é esperado que haja expurgo dos
/// clipes reproduzidos há mais tempo fora do pacote inicial aqui (não implementado — veja a
/// lista de TODOs do README).
final class AudioCacheManager {
    static let shared = AudioCacheManager()

    private let cacheDirectory: URL

    private init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDirectory = documents.appendingPathComponent("AudioCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func fileURL(for audioId: String) -> URL {
        cacheDirectory.appendingPathComponent("\(audioId).m4a")
    }

    func isCached(_ audioId: String) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(for: audioId).path)
    }

    @discardableResult
    func write(_ data: Data, for audioId: String) -> URL {
        let url = fileURL(for: audioId)
        try? data.write(to: url, options: .atomic)
        return url
    }

    func evict(_ audioId: String) {
        try? FileManager.default.removeItem(at: fileURL(for: audioId))
    }
}
