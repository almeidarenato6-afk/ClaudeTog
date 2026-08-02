import Toybox.WatchUi;
import Toybox.Lang;

// Handles one-action-per-press selection from GameModeView's Menu2 and dispatches the
// RELAY play command. Garmin apps operate in RELAY mode by default (see
// resources/garmin_capability_table.json and ../../README.md) — there is no DirectPlaybackEngine
// equivalent in this app.
class GameModeDelegate extends WatchUi.Menu2InputDelegate {
    private var _view as GameModeView;
    private var _channel as CompanionChannel;

    function initialize(view as GameModeView) {
        Menu2InputDelegate.initialize();
        _view = view;
        _channel = new CompanionChannel();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var categoryId = item.getId() as String;
        // The catalog resolution of "which audioId within this category plays now" lives
        // on the phone side once RELAY delivers the categoryId-derived audioId; this
        // scaffold sends a placeholder default id, same seam as the Wear OS/watchOS apps.
        var audioId = categoryId + "_default";

        WatchUi.pushView(new PlaybackStatusView("Enviando…"), null, WatchUi.SLIDE_IMMEDIATE);

        _channel.sendPlayCommand(audioId, method(:onPlayCommandAck));
    }

    function onPlayCommandAck(success as Boolean) as Void {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        var resultText = success ? "Enviado!" : "Celular não conectado";
        WatchUi.pushView(new PlaybackStatusView(resultText), null, WatchUi.SLIDE_IMMEDIATE);
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}
