import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/watch_companion/domain/entities/watch_command.dart';

/// Abstraction over the phone <-> watch companion channel.
///
/// Native counterparts (NOT implementable purely in Dart):
/// - Android: Wear OS Data Layer API (`MessageClient`/`CapabilityClient`) —
///   see android/app/src/main/kotlin TODO stub.
/// - iOS: `WatchConnectivity` (`WCSession`) — see ios/Runner TODO stub.
///
/// Per ARCHITECTURE.md §4, the underlying session must be kept persistently
/// alive (never reconnected per command) — that lifecycle lives entirely
/// on the native side; this Dart interface only exposes the resulting
/// command stream and a send method.
abstract interface class WatchCompanionChannel {
  Future<Result<bool>> isWatchPaired();

  Future<Result<bool>> isCompanionAppInstalled();

  /// Commands arriving from the watch — primarily `playAudio` in Cenário B.
  Stream<WatchCommand> watchIncomingCommands();

  Future<Result<void>> sendCommand(WatchCommand command);
}
