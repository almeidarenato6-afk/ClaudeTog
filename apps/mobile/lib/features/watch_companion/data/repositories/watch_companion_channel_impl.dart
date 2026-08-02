import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/error/failure.dart';
import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/watch_companion/data/datasources/watch_companion_platform_datasource.dart';
import 'package:vai_marcia/features/watch_companion/domain/entities/watch_command.dart';
import 'package:vai_marcia/features/watch_companion/domain/repositories/watch_companion_channel.dart';

@LazySingleton(as: WatchCompanionChannel)
class WatchCompanionChannelImpl implements WatchCompanionChannel {
  WatchCompanionChannelImpl(this._platform);

  final WatchCompanionPlatformDataSource _platform;

  @override
  Future<Result<bool>> isWatchPaired() async {
    try {
      return Result<bool>.ok(await _platform.isWatchPaired());
    } on Object catch (e) {
      return Result<bool>.err(WatchCompanionFailure('Falha ao verificar relógio pareado', cause: e));
    }
  }

  @override
  Future<Result<bool>> isCompanionAppInstalled() async {
    try {
      return Result<bool>.ok(await _platform.isCompanionAppInstalled());
    } on Object catch (e) {
      return Result<bool>.err(WatchCompanionFailure('Falha ao verificar app do relógio', cause: e));
    }
  }

  @override
  Stream<WatchCommand> watchIncomingCommands() {
    return _platform.incomingCommands().map(WatchCommand.fromMap);
  }

  @override
  Future<Result<void>> sendCommand(WatchCommand command) async {
    try {
      await _platform.sendCommand(command.toMap());
      return const Result<void>.ok(null);
    } on Object catch (e) {
      return Result<void>.err(WatchCompanionFailure('Falha ao enviar comando ao relógio', cause: e));
    }
  }
}
