import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/constants/app_constants.dart';

abstract interface class RecordingRemoteDataSource {
  Future<String> uploadAndCreateClip({
    required String localFilePath,
    required String title,
    required String categoryId,
    required int durationMs,
  });
}

@LazySingleton(as: RecordingRemoteDataSource)
class RecordingRemoteDataSourceImpl implements RecordingRemoteDataSource {
  RecordingRemoteDataSourceImpl(this._firestore, this._storage, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  @override
  Future<String> uploadAndCreateClip({
    required String localFilePath,
    required String title,
    required String categoryId,
    required int durationMs,
  }) async {
    final String ownerId = _auth.currentUser?.uid ?? 'anonymous';
    final String clipId = _firestore.collection(AppConstants.firestoreCollectionAudios).doc().id;
    final Reference ref = _storage.ref('${AppConstants.storageBucketRecordingsPath}/$ownerId/$clipId.m4a');

    // Gravações são privadas por padrão (regras de Storage/Firestore
    // apenas para o dono — veja ARCHITECTURE.md §10), diferente do áudio
    // do catálogo, que é de leitura pública.
    await ref.putFile(
      File(localFilePath),
      SettableMetadata(customMetadata: <String, String>{'ownerUserId': ownerId}),
    );
    final String downloadUrl = await ref.getDownloadURL();

    await _firestore.collection(AppConstants.firestoreCollectionAudios).doc(clipId).set(<String, dynamic>{
      'title': title,
      'categoryId': categoryId,
      'remoteUrl': downloadUrl,
      'durationMs': durationMs,
      'isCustomRecording': true,
      'ownerUserId': ownerId,
      'tags': <String>[],
      'playCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return clipId;
  }
}
