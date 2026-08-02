import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Graphics;

// Garmin's UI model is more constrained than a phone/other-watch touch grid: many devices
// (fēnix, Forerunner) are physical-button-driven rather than touchscreen, so "Modo Jogo" is
// implemented as a WatchUi.Menu2 — one list, one press-or-tap per action, glanceable labels
// with the same category emoji used on every other platform for visual consistency.
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
                    categoryId, // item id doubles as the categoryId for the delegate
                    null,
                    {}
                )
            );
        }
    }

    // Presentation-layer concern: mapping a domain categoryId to its localized Rez.Strings
    // resource reference. Kept out of Domain/AudioClip.mc so the domain layer stays free of
    // WatchUi/Rez imports.
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

// Shown briefly after a tap while the RELAY command is in flight, and again with the
// result — Garmin devices give no implicit "it's playing" feedback like a speaker does
// locally, so an explicit status toast matters more here than on Wear OS/watchOS.
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
