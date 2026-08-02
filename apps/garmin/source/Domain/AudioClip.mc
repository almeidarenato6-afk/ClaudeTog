import Toybox.Lang;

// Mirrors the mobile app's `AudioClip` domain entity conceptually (see
// apps/mobile/lib/features/audio_playback/domain). Monkey C has no formal access
// modifiers for immutability, so fields are treated as read-only by convention.
class AudioClip {
    var id as String;
    var categoryId as String;
    var title as String;
    var isFavorite as Boolean;

    function initialize(id as String, categoryId as String, title as String, isFavorite as Boolean) {
        self.id = id;
        self.categoryId = categoryId;
        self.title = title;
        self.isFavorite = isFavorite;
    }
}

// The five "Modo Jogo" categories — fixed set for the button-grid-equivalent UI.
class Category {
    static const ENERGIA = "energia";
    static const BORA = "bora";
    static const PALMAS = "palmas";
    static const HUMOR = "humor";
    static const FAVORITOS = "favoritos";

    static function all() as Array<String> {
        return [ENERGIA, BORA, PALMAS, HUMOR, FAVORITOS];
    }

    static function emoji(categoryId as String) as String {
        switch (categoryId) {
            case ENERGIA: return "🔥";
            case BORA: return "💪";
            case PALMAS: return "👏";
            case HUMOR: return "😂";
            case FAVORITOS: return "❤️";
            default: return "";
        }
    }

}
