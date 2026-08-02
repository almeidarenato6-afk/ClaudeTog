import 'package:flutter_test/flutter_test.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/audio_codec.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/device_capability_profile.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/playback_strategy.dart';
import 'package:vai_marcia/features/device_pairing/domain/usecases/decide_playback_strategy_usecase.dart';

DeviceCapabilityProfile _profile({
  bool hasBluetoothClassicAudio = false,
  bool hasBleAudioSupport = false,
  bool canPlayArbitraryLocalAudio = false,
  bool hasPersistentCompanionChannel = false,
}) {
  return DeviceCapabilityProfile(
    manufacturer: 'Samsung',
    model: 'Galaxy Watch 6',
    osFamily: 'wearos',
    osVersion: '4',
    hasBluetoothClassicAudio: hasBluetoothClassicAudio,
    hasBleAudioSupport: hasBleAudioSupport,
    supportedCodecs: const <AudioCodec>{AudioCodec.sbc},
    canPlayArbitraryLocalAudio: canPlayArbitraryLocalAudio,
    hasPersistentCompanionChannel: hasPersistentCompanionChannel,
    estimatedLatencyMs: 50,
  );
}

void main() {
  const DecidePlaybackStrategyUseCase decide = DecidePlaybackStrategyUseCase();

  group('DecidePlaybackStrategyUseCase', () {
    test('no watch paired -> phoneOnly', () {
      expect(decide(null), PlaybackStrategy.phoneOnly);
    });

    test('classic BT audio + arbitrary local playback -> direct (Galaxy Watch case)', () {
      final DeviceCapabilityProfile profile = _profile(
        hasBluetoothClassicAudio: true,
        canPlayArbitraryLocalAudio: true,
      );
      expect(decide(profile), PlaybackStrategy.direct);
    });

    test('BLE audio + arbitrary local playback -> direct', () {
      final DeviceCapabilityProfile profile = _profile(
        hasBleAudioSupport: true,
        canPlayArbitraryLocalAudio: true,
      );
      expect(decide(profile), PlaybackStrategy.direct);
    });

    test('has radio but cannot play arbitrary local audio -> relay', () {
      final DeviceCapabilityProfile profile = _profile(
        hasBluetoothClassicAudio: true,
      );
      expect(decide(profile), PlaybackStrategy.relay);
    });

    test('no BT audio radio but has persistent companion channel -> relay (typical Apple Watch SE)', () {
      final DeviceCapabilityProfile profile = _profile(
        hasPersistentCompanionChannel: true,
      );
      expect(decide(profile), PlaybackStrategy.relay);
    });

    test('no BT audio radio and no companion channel -> phoneOnly (Garmin without arbitrary audio)', () {
      final DeviceCapabilityProfile profile = _profile();
      expect(decide(profile), PlaybackStrategy.phoneOnly);
    });
  });
}
