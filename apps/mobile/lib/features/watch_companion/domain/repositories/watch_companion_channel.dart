import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/watch_companion/domain/entities/watch_command.dart';

/// Abstração sobre o canal companion telefone <-> smartwatch.
///
/// Contrapartes nativas (NÃO implementáveis apenas em Dart):
/// - Android: Data Layer API do Wear OS
///   (`MessageClient`/`CapabilityClient`) — veja o stub TODO em
///   android/app/src/main/kotlin.
/// - iOS: `WatchConnectivity` (`WCSession`) — veja o stub TODO em
///   ios/Runner.
///
/// Conforme ARCHITECTURE.md §4, a sessão subjacente precisa ser mantida
/// viva de forma persistente (nunca reconectada por comando) — esse
/// ciclo de vida fica inteiramente do lado nativo; esta interface Dart
/// apenas expõe o stream de comandos resultante e um método de envio.
abstract interface class WatchCompanionChannel {
  Future<Result<bool>> isWatchPaired();

  Future<Result<bool>> isCompanionAppInstalled();

  /// Comandos vindos do smartwatch — principalmente `playAudio` no
  /// Cenário B.
  Stream<WatchCommand> watchIncomingCommands();

  Future<Result<void>> sendCommand(WatchCommand command);
}
