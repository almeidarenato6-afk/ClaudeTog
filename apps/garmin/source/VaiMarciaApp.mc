import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class VaiMarciaApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    // Retorna a view inicial do app — a grade equivalente a botões grandes do "Modo Jogo".
    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new GameModeView();
        var delegate = new GameModeDelegate(view);
        return [view, delegate];
    }
}

function getApp() as VaiMarciaApp {
    return Application.getApp() as VaiMarciaApp;
}
