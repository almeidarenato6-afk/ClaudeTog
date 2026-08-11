/// Contrato abstrato de analytics. Seguro para o domínio (sem import do
/// Firebase) para que use cases/controllers de diversas features possam
/// registrar eventos sem depender diretamente de `firebase_analytics`.
abstract interface class AnalyticsService {
  Future<void> logAudioPlayed({required String clipId, required String strategy});

  Future<void> logFavoriteToggled({required String clipId, required bool isFavorite});

  Future<void> logSessionStart();

  Future<void> logSessionEnd({required Duration sessionDuration});

  /// Captura o contexto do dispositivo útil para suporte/analytics: modelo
  /// do relógio (quando aplicável), modelo do celular, marca da caixa de
  /// som pareada (quando conhecida), e qual [PlaybackStrategy] está ativa
  /// — veja docs/DEVICE_DETECTION.md.
  Future<void> logDeviceContext({
    String? watchModel,
    required String phoneModel,
    String? bluetoothSpeakerBrand,
    required String playbackStrategy,
  });

  Future<void> setUserId(String? userId);
}
