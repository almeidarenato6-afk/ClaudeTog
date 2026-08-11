import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/device_capability_profile.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/paired_speaker.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/playback_strategy.dart';

abstract interface class DevicePairingRepository {
  /// Passo 1 (DEVICE_DETECTION.md): descobre um relógio pareado e
  /// compatível e retorna seu perfil de capacidade (via sondagem
  /// [GET_CAPABILITIES]), ou `null` quando nenhum está
  /// pareado/compatível.
  Future<Result<DeviceCapabilityProfile?>> discoverPairedWatch();

  /// Passo 4: lista caixas de som pareadas via Bluetooth com um perfil
  /// A2DP ativo.
  Future<Result<List<PairedSpeaker>>> discoverPairedSpeakers();

  /// Persiste a estratégia decidida localmente e a espelha em
  /// `users/{uid}/devices/{deviceId}` para analytics/suporte (Passo 5).
  Future<Result<void>> persistStrategy(PlaybackStrategy strategy);

  Future<Result<PlaybackStrategy?>> loadPersistedStrategy();

  /// Abre os ajustes de Bluetooth do sistema via deep link, conforme o
  /// assistente de configuração.
  Future<Result<void>> openSystemBluetoothSettings();
}
