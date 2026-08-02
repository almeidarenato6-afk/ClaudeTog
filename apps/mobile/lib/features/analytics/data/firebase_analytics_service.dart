import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:injectable/injectable.dart';
import 'package:vai_marcia/features/analytics/domain/analytics_service.dart';

@LazySingleton(as: AnalyticsService)
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logAudioPlayed({required String clipId, required String strategy}) {
    return _analytics.logEvent(
      name: 'audio_played',
      parameters: <String, Object>{'clip_id': clipId, 'playback_strategy': strategy},
    );
  }

  @override
  Future<void> logFavoriteToggled({required String clipId, required bool isFavorite}) {
    return _analytics.logEvent(
      name: 'favorite_toggled',
      parameters: <String, Object>{'clip_id': clipId, 'is_favorite': isFavorite},
    );
  }

  @override
  Future<void> logSessionStart() {
    return _analytics.logEvent(name: 'session_start');
  }

  @override
  Future<void> logSessionEnd({required Duration sessionDuration}) {
    return _analytics.logEvent(
      name: 'session_end',
      parameters: <String, Object>{'session_seconds': sessionDuration.inSeconds},
    );
  }

  @override
  Future<void> logDeviceContext({
    String? watchModel,
    required String phoneModel,
    String? bluetoothSpeakerBrand,
    required String playbackStrategy,
  }) {
    return _analytics.logEvent(
      name: 'device_context',
      parameters: <String, Object>{
        if (watchModel != null) 'watch_model': watchModel,
        'phone_model': phoneModel,
        if (bluetoothSpeakerBrand != null) 'bluetooth_speaker_brand': bluetoothSpeakerBrand,
        'playback_strategy': playbackStrategy,
      },
    );
  }

  @override
  Future<void> setUserId(String? userId) {
    return _analytics.setUserId(id: userId);
  }
}
