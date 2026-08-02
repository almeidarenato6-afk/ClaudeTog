/// Abstract analytics contract. Domain-safe (no Firebase import) so use
/// cases/controllers across features can log events without depending on
/// `firebase_analytics` directly.
abstract interface class AnalyticsService {
  Future<void> logAudioPlayed({required String clipId, required String strategy});

  Future<void> logFavoriteToggled({required String clipId, required bool isFavorite});

  Future<void> logSessionStart();

  Future<void> logSessionEnd({required Duration sessionDuration});

  /// Captures device context useful for support/analytics: watch model
  /// (when applicable), phone model, paired speaker brand (when known),
  /// and which [PlaybackStrategy] is active — see docs/DEVICE_DETECTION.md.
  Future<void> logDeviceContext({
    String? watchModel,
    required String phoneModel,
    String? bluetoothSpeakerBrand,
    required String playbackStrategy,
  });

  Future<void> setUserId(String? userId);
}
