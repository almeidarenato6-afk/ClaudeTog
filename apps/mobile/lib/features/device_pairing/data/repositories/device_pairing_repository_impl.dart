import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/constants/app_constants.dart';
import 'package:vai_marcia/core/error/failure.dart';
import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/device_pairing/data/datasources/device_capability_probe_datasource.dart';
import 'package:vai_marcia/features/device_pairing/data/datasources/device_pairing_local_datasource.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/device_capability_profile.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/paired_speaker.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/playback_strategy.dart';
import 'package:vai_marcia/features/device_pairing/domain/repositories/device_pairing_repository.dart';

@LazySingleton(as: DevicePairingRepository)
class DevicePairingRepositoryImpl implements DevicePairingRepository {
  DevicePairingRepositoryImpl(
    this._probe,
    this._local,
    this._firestore,
    this._auth,
  );

  final DeviceCapabilityProbeDataSource _probe;
  final DevicePairingLocalDataSource _local;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Future<Result<DeviceCapabilityProfile?>> discoverPairedWatch() async {
    try {
      final DeviceCapabilityProfile? profile = await _probe.probePairedWatch();
      return Result<DeviceCapabilityProfile?>.ok(profile);
    } on Object catch (e) {
      return Result<DeviceCapabilityProfile?>.err(BluetoothFailure('Falha ao detectar relógio pareado', cause: e));
    }
  }

  @override
  Future<Result<List<PairedSpeaker>>> discoverPairedSpeakers() async {
    try {
      final List<PairedSpeaker> speakers = await _probe.listPairedSpeakers();
      return Result<List<PairedSpeaker>>.ok(speakers);
    } on Object catch (e) {
      return Result<List<PairedSpeaker>>.err(BluetoothFailure('Falha ao listar caixas pareadas', cause: e));
    }
  }

  @override
  Future<Result<void>> persistStrategy(PlaybackStrategy strategy) async {
    try {
      await _local.saveStrategy(strategy);

      final User? user = _auth.currentUser;
      if (user != null) {
        final String deviceId = user.uid;
        await _firestore
            .collection(AppConstants.firestoreCollectionUsers)
            .doc(user.uid)
            .collection(AppConstants.firestoreSubcollectionDevices)
            .doc(deviceId)
            .set(<String, dynamic>{
          'playbackStrategy': strategy.name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return const Result<void>.ok(null);
    } on Object catch (e) {
      return Result<void>.err(CacheFailure('Falha ao salvar estratégia de reprodução', cause: e));
    }
  }

  @override
  Future<Result<PlaybackStrategy?>> loadPersistedStrategy() async {
    try {
      final PlaybackStrategy? strategy = await _local.loadStrategy();
      return Result<PlaybackStrategy?>.ok(strategy);
    } on Object catch (e) {
      return Result<PlaybackStrategy?>.err(CacheFailure('Falha ao carregar estratégia salva', cause: e));
    }
  }

  @override
  Future<Result<void>> openSystemBluetoothSettings() async {
    try {
      await _probe.openBluetoothSettings();
      return const Result<void>.ok(null);
    } on Object catch (e) {
      return Result<void>.err(BluetoothFailure('Falha ao abrir configurações de Bluetooth', cause: e));
    }
  }
}
