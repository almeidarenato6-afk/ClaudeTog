/// Constantes numéricas/de string transversais. Valores que codificam um
/// requisito de produto (como [maxTapToAudioLatencyMs]) são mantidos como
/// constantes nomeadas, não números mágicos, para que sua origem
/// (ARCHITECTURE.md §4) seja rastreável.
abstract final class AppConstants {
  /// Orçamento de latência a nível de produto: toque até som audível,
  /// conforme ARCHITECTURE.md §4.
  static const Duration maxTapToAudioLatency = Duration(milliseconds: 150);

  /// Número de players [just_audio] mantidos aquecidos no pool por
  /// categoria ativa, para que toques rápidos e repetidos em clipes
  /// diferentes nunca esperem um player ser liberado.
  static const int audioPlayerPoolSize = 4;

  /// Tamanho do pacote offline inicial — áudios embutidos no binário do
  /// app para que ele seja utilizável sem rede nenhuma na primeira
  /// abertura.
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

  /// Nomes de method-channel compartilhados entre as implementações Dart e
  /// nativas (Android/iOS) — veja features/bluetooth e
  /// features/watch_companion.
  static const String methodChannelBluetoothTransport = 'br.com.togplay.vaimarcia/bluetooth_transport';
  static const String methodChannelWatchCompanion = 'br.com.togplay.vaimarcia/watch_companion';
  static const String eventChannelWatchCompanionEvents = 'br.com.togplay.vaimarcia/watch_companion_events';
  static const String eventChannelBluetoothEvents = 'br.com.togplay.vaimarcia/bluetooth_events';

  static const String storeUrlHost = 'www.lojatogplay.com.br';
}
