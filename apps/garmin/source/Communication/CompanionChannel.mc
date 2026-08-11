import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;

// Envolve Toybox.Communications.transmit()/registerForPhoneAppMessages para o canal de
// comando RELAY até o celular. A Garmin é RELAY-only por padrão (veja ../../README.md e
// resources/garmin_capability_table.json) — o canal de transmissão do Connect IQ Mobile SDK
// até o app companion pareado é mantido "escutando" durante todo o ciclo de vida do app via
// registerForPhoneAppMessages, seguindo a orientação de latência do canal persistente em
// docs/ARCHITECTURE.md §4 (evita renegociar a ponte app-celular a cada toque).
class CompanionChannel {

    private var _onAck as (Method(success as Boolean) as Void)?;

    function initialize() {
        Communications.registerForPhoneAppMessages(method(:onPhoneMessage));
    }

    // Envia apenas o audioId (alguns bytes) — o celular já tem o áudio em cache
    // localmente e o reproduz imediatamente na caixa Bluetooth pareada.
    function sendPlayCommand(audioId as String, onAck as (Method(success as Boolean) as Void)?) as Void {
        _onAck = onAck;
        var payload = {
            "type" => "play_command",
            "audioId" => audioId,
        };
        Communications.transmit(payload, null, new CompanionTransmitListener(self));
    }

    function onTransmitComplete(success as Boolean) as Void {
        if (_onAck != null) {
            _onAck.invoke(success);
        }
    }

    // Mensagens celular -> relógio hoje se limitam a confirmações/notificações de catálogo;
    // comandos de reprodução só fluem no sentido relógio -> celular.
    function onPhoneMessage(message as Communications.PhoneAppMessage) as Void {
        System.println("CompanionChannel: mensagem do celular recebida");
    }
}

class CompanionTransmitListener extends Communications.ConnectionListener {
    private var _channel as CompanionChannel;

    function initialize(channel as CompanionChannel) {
        ConnectionListener.initialize();
        _channel = channel;
    }

    function onComplete() as Void {
        _channel.onTransmitComplete(true);
    }

    function onError() as Void {
        _channel.onTransmitComplete(false);
    }
}
