import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vai_marcia/core/constants/app_constants.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/playback_strategy.dart';

abstract interface class DevicePairingLocalDataSource {
  Future<void> saveStrategy(PlaybackStrategy strategy);
  Future<PlaybackStrategy?> loadStrategy();
}

@LazySingleton(as: DevicePairingLocalDataSource)
class DevicePairingLocalDataSourceImpl implements DevicePairingLocalDataSource {
  @override
  Future<void> saveStrategy(PlaybackStrategy strategy) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefsKeyPlaybackStrategy, strategy.name);
  }

  @override
  Future<PlaybackStrategy?> loadStrategy() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(AppConstants.prefsKeyPlaybackStrategy);
    if (raw == null) {
      return null;
    }
    return PlaybackStrategy.values.firstWhere(
      (PlaybackStrategy s) => s.name == raw,
      orElse: () => PlaybackStrategy.phoneOnly,
    );
  }
}
