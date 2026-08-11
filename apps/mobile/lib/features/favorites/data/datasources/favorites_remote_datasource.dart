import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/constants/app_constants.dart';

/// Espelha os favoritos no Firestore para que sobrevivam a reinstalações
/// / sincronizem entre os dispositivos do usuário. O armazenamento local
/// (Drift) continua sendo a fonte de verdade para leituras no caminho
/// crítico da UI; isso é sincronização em segundo plano de melhor
/// esforço.
abstract interface class FavoritesRemoteDataSource {
  Future<void> setFavorite(String clipId, bool isFavorite);
}

@LazySingleton(as: FavoritesRemoteDataSource)
class FavoritesRemoteDataSourceImpl implements FavoritesRemoteDataSource {
  FavoritesRemoteDataSourceImpl(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Future<void> setFavorite(String clipId, bool isFavorite) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      return;
    }
    final DocumentReference<Map<String, dynamic>> doc = _firestore
        .collection(AppConstants.firestoreCollectionUsers)
        .doc(user.uid)
        .collection(AppConstants.firestoreSubcollectionFavorites)
        .doc(clipId);

    if (isFavorite) {
      await doc.set(<String, dynamic>{'addedAt': FieldValue.serverTimestamp()});
    } else {
      await doc.delete();
    }
  }
}
