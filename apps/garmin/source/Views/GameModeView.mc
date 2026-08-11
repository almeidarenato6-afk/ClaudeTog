import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Graphics;

// O modelo de UI da Garmin é mais restrito do que uma grade touch de celular/outro relógio:
// muitos dispositivos (fēnix, Forerunner) são orientados a botão físico em vez de touchscreen,
// então o "Modo Jogo" é implementado como um WatchUi.Menu2 — uma lista, um toque ou pressão
// por ação, com rótulos rápidos de ler usando o mesmo emoji de categoria usado em todas as
// outras plataformas para consistência visual.
class GameModeView extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({:title => WatchUi.loadResource(Rez.Strings.AppName) as String});

        var categories = Category.all();
        for (var i = 0; i < categories.size(); i += 1) {
            var categoryId = categories[i];
            addItem(
                new WatchUi.IconMenuItem(
                    Category.emoji(categoryId) + " " + (WatchUi.loadResource(categoryLabelResource(categoryId)) as String),
                    null,
                    categoryId, // o id do item também serve como categoryId para o delegate
                    null,
                    {}
                )
            );
        }
    }

    // Responsabilidade da camada de apresentação: mapear um categoryId de domínio para sua
    // referência de recurso Rez.Strings localizada. Mantido fora de Domain/AudioClip.mc para
    // que a camada de domínio continue livre de imports de WatchUi/Rez.
    private function categoryLabelResource(categoryId as String) as ResourceId {
        switch (categoryId) {
            case Category.ENERGIA: return Rez.Strings.CategoryEnergia;
            case Category.BORA: return Rez.Strings.CategoryBora;
            case Category.PALMAS: return Rez.Strings.CategoryPalmas;
            case Category.HUMOR: return Rez.Strings.CategoryHumor;
            case Category.FAVORITOS: return Rez.Strings.CategoryFavoritos;
            default: return Rez.Strings.CategoryEnergia;
        }
    }
}

// Exibido brevemente após um toque enquanto o comando RELAY está em trânsito, e novamente
// com o resultado — dispositivos Garmin não dão nenhum feedback implícito de "está tocando"
// como um alto-falante local dá, então um toast de status explícito importa mais aqui do
// que no Wear OS/watchOS.
class PlaybackStatusView extends WatchUi.View {
    private var _statusText as String;

    function initialize(statusText as String) {
        View.initialize();
        _statusText = statusText;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        View.onUpdate(dc);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2,
            Graphics.FONT_MEDIUM,
            _statusText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
}
