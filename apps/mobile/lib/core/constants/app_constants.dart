/// Cross-cutting numeric/string constants. Values that encode a product
/// requirement (like [maxTapToAudioLatencyMs]) are kept as named constants,
/// not magic numbers, so their provenance (ARCHITECTURE.md §4) is traceable.
abstract final class AppConstants {
  /// Product-level latency budget: tap-to-audible-sound, per ARCHITECTURE.md §4.
  static const Duration maxTapToAudioLatency = Duration(milliseconds: 150);

  /// Number of pooled [just_audio] players kept warm per active category so
  /// rapid re-taps of different clips never wait on a player being freed.
  static const int audioPlayerPoolSize = 4;

  /// Starter offline bundle size — audios embedded in the app binary so the
  /// app is usable with zero network on first launch.
  static const int starterBundleClipCount = 12;

  static const String firestoreCollectionAudios = 'audios';
  static const String firestoreCollectionCategories = 'categories';
  static const String firestoreCollectionUsers = 'users';
  static const String firestoreSubcollectionFavorites = 'favorites';
  static const String firestoreSubcollectionDevices = 'devices';
  static const String firestoreCollectionAnalyticsEvents = 'analytics_events';
  static const String firestoreCollectionStoreConfig = 'store_config';
  static const String firestoreCollectionNotifications = 'notifications';

  static const String storageBucketAudioPath = 'audios';
  static const String storageBucketRecordingsPath = 'recordings';

  static const String prefsKeyPlaybackStrategy = 'playback_strategy';
  static const String prefsKeyDeviceCapabilityProfile = 'device_capability_profile';
  static const String prefsKeyOnboardingComplete = 'onboarding_complete';
  static const String prefsKeyDeviceId = 'device_id';

  /// Method-channel names shared between Dart and native (Android/iOS)
  /// implementations — see features/bluetooth and features/watch_companion.
  static const String methodChannelBluetoothTransport = 'br.com.togplay.vaimarcia/bluetooth_transport';
  static const String methodChannelWatchCompanion = 'br.com.togplay.vaimarcia/watch_companion';
  static const String eventChannelWatchCompanionEvents = 'br.com.togplay.vaimarcia/watch_companion_events';
  static const String eventChannelBluetoothEvents = 'br.com.togplay.vaimarcia/bluetooth_events';

  static const String storeUrlHost = 'www.lojatogplay.com.br';
}
