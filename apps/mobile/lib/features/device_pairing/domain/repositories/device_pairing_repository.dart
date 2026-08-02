import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/device_capability_profile.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/paired_speaker.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/playback_strategy.dart';

abstract interface class DevicePairingRepository {
  /// Step 1 (DEVICE_DETECTION.md): discovers a paired, compatible watch and
  /// returns its capability profile (via [GET_CAPABILITIES] probe), or
  /// `null` when none is paired/compatible.
  Future<Result<DeviceCapabilityProfile?>> discoverPairedWatch();

  /// Step 4: lists Bluetooth-paired speakers with an active A2DP profile.
  Future<Result<List<PairedSpeaker>>> discoverPairedSpeakers();

  /// Persists the decided strategy locally and mirrors it to
  /// `users/{uid}/devices/{deviceId}` for analytics/support (Step 5).
  Future<Result<void>> persistStrategy(PlaybackStrategy strategy);

  Future<Result<PlaybackStrategy?>> loadPersistedStrategy();

  /// Opens system Bluetooth settings via deep link, per the setup wizard.
  Future<Result<void>> openSystemBluetoothSettings();
}
