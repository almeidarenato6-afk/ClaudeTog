import Toybox.WatchUi;
import Toybox.Lang;

// Trata a seleção de uma-ação-por-toque do Menu2 do GameModeView e despacha o comando
// de reprodução RELAY. Os apps Garmin operam em modo RELAY por padrão (veja
// resources/garmin_capability_table.json e ../../README.md) — não existe um equivalente a
// DirectPlaybackEngine neste app.
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
        // A resolução no catálogo de "qual audioId dentro desta categoria toca agora" fica
        // do lado do celular assim que o RELAY entrega o audioId derivado da categoryId;
        // este esqueleto envia um id padrão provisório, mesmo ponto de extensão dos apps
        // Wear OS/watchOS.
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
