import Foundation

/// The five "Modo Jogo" categories — fixed set for the glanceable big-button grid.
enum Category: String, CaseIterable, Identifiable, Codable {
    case energia
    case bora
    case palmas
    case humor
    case favoritos

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .energia: return "🔥"
        case .bora: return "💪"
        case .palmas: return "👏"
        case .humor: return "😂"
        case .favoritos: return "❤️"
        }
    }

    var label: String {
        switch self {
        case .energia: return "Energia"
        case .bora: return "Bora"
        case .palmas: return "Palmas"
        case .humor: return "Humor"
        case .favoritos: return "Favoritos"
        }
    }
}
