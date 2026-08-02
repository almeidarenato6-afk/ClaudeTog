import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;

// Wraps Toybox.Communications.transmit()/registerForPhoneAppMessages for the RELAY command
// channel to the phone. Garmin is RELAY-only by default (see ../../README.md and
// resources/garmin_capability_table.json) — the Connect IQ Mobile SDK's transmit channel to
// the paired phone app is kept "listening" for the app's lifetime via
// registerForPhoneAppMessages, mirroring the persistent-channel latency guidance in
// docs/ARCHITECTURE.md §4 (avoids renegotiating the phone-app bridge per tap).
class CompanionChannel {

    private var _onAck as (Method(success as Boolean) as Void)?;

    function initialize() {
        Communications.registerForPhoneAppMessages(method(:onPhoneMessage));
    }

    // Sends only the audioId (a few bytes) — the phone already has the audio cached
    // locally and plays it immediately to the paired Bluetooth speaker.
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

    // Phone -> watch messages are limited to acks/catalog notifications today; playback
    // commands only ever flow watch -> phone.
    function onPhoneMessage(message as Communications.PhoneAppMessage) as Void {
        System.println("CompanionChannel: received phone message");
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
