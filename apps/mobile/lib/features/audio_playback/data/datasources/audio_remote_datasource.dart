import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/constants/app_constants.dart';
import 'package:vai_marcia/features/audio_playback/data/models/audio_clip_model.dart';

abstract interface class AudioRemoteDataSource {
  /// Real-time listener on `audios` filtered by category — content updates
  /// (new clips, edits) land without an app release (ARCHITECTURE.md §7).
  Stream<List<AudioClipModel>> watchClipsByCategory(String categoryId);

  Future<AudioClipModel> getClipById(String clipId);

  Future<List<int>> downloadClipBytes(String storagePath);

  Future<void> incrementPlayCount(String clipId);
}

@LazySingleton(as: AudioRemoteDataSource)
class AudioRemoteDataSourceImpl implements AudioRemoteDataSource {
  AudioRemoteDataSourceImpl(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _audiosCollection =>
      _firestore.collection(AppConstants.firestoreCollectionAudios);

  @override
  Stream<List<AudioClipModel>> watchClipsByCategory(String categoryId) {
    return _audiosCollection
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('title')
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => AudioClipModel.fromJson(<String, dynamic>{
                    'id': doc.id,
                    ...doc.data(),
                  }))
              .toList(growable: false),
        );
  }

  @override
  Future<AudioClipModel> getClipById(String clipId) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _audiosCollection.doc(clipId).get();
    final Map<String, dynamic>? data = doc.data();
    if (data == null) {
      throw StateError('Audio clip $clipId not found');
    }
    return AudioClipModel.fromJson(<String, dynamic>{'id': doc.id, ...data});
  }

  @override
  Future<List<int>> downloadClipBytes(String storagePath) async {
    final Reference ref = _storage.ref(storagePath);
    final List<int>? bytes = await ref.getData(20 * 1024 * 1024);
    if (bytes == null) {
      throw StateError('Failed to download audio at $storagePath');
    }
    return bytes;
  }

  @override
  Future<void> incrementPlayCount(String clipId) {
    return _audiosCollection.doc(clipId).update(<String, dynamic>{
      'playCount': FieldValue.increment(1),
    });
  }
}
