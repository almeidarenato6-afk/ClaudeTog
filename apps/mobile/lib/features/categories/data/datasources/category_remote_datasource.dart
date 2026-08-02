import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/constants/app_constants.dart';
import 'package:vai_marcia/features/categories/data/models/audio_category_model.dart';

abstract interface class CategoryRemoteDataSource {
  Stream<List<AudioCategoryModel>> watchCategories();
  Future<AudioCategoryModel> createCustomCategory(String name);
}

@LazySingleton(as: CategoryRemoteDataSource)
class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  CategoryRemoteDataSourceImpl(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.firestoreCollectionCategories);

  @override
  Stream<List<AudioCategoryModel>> watchCategories() {
    return _collection.orderBy('sortOrder').snapshots().map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    AudioCategoryModel.fromJson(<String, dynamic>{'id': doc.id, ...doc.data()}),
              )
              .toList(growable: false),
        );
  }

  @override
  Future<AudioCategoryModel> createCustomCategory(String name) async {
    final String ownerId = _auth.currentUser?.uid ?? 'anonymous';
    final DocumentReference<Map<String, dynamic>> doc = await _collection.add(<String, dynamic>{
      'name': name,
      'iconName': 'mic',
      'colorHex': '#8E97A8',
      'sortOrder': 999,
      'isUserCreated': true,
      'ownerUserId': ownerId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return AudioCategoryModel(
      id: doc.id,
      name: name,
      iconName: 'mic',
      colorHex: '#8E97A8',
      sortOrder: 999,
      isUserCreated: true,
    );
  }
}
