import Toybox.Lang;

// Espelha conceitualmente a entidade de domínio `AudioClip` do app mobile (veja
// apps/mobile/lib/features/audio_playback/domain). Monkey C não tem modificadores formais
// de acesso para imutabilidade, então os campos são tratados como somente leitura por
// convenção.
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

// As cinco categorias do "Modo Jogo" — conjunto fixo para a UI equivalente à grade de botões.
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
