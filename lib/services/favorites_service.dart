import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/lawyer_model.dart';

/// Manages saved/favorite lawyers for each user in Firestore.
class FavoritesService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference get _favRef =>
      _db.collection('users').doc(_uid).collection('favorites');

  /// Returns a real-time stream of the user's favorite lawyers.
  Stream<List<LawyerModel>> watchFavorites() {
    if (_uid == null) return const Stream.empty();
    return _favRef.snapshots().asyncMap((snap) async {
      final futures = snap.docs.map((doc) async {
        final lawyerId = doc.id;
        final lawyerDoc =
            await _db.collection('lawyers').doc(lawyerId).get();
        if (!lawyerDoc.exists) return null;
        return LawyerModel.fromMap(lawyerDoc.data()!);
      });
      final results = await Future.wait(futures);
      return results.whereType<LawyerModel>().toList();
    });
  }

  /// Returns true if the given lawyer is already saved.
  Future<bool> isFavorite(String lawyerId) async {
    if (_uid == null) return false;
    final doc = await _favRef.doc(lawyerId).get();
    return doc.exists;
  }

  /// Add a lawyer to favorites.
  Future<void> addFavorite(String lawyerId) async {
    if (_uid == null) return;
    await _favRef.doc(lawyerId).set({
      'lawyerId': lawyerId,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove a lawyer from favorites.
  Future<void> removeFavorite(String lawyerId) async {
    if (_uid == null) return;
    await _favRef.doc(lawyerId).delete();
  }

  /// Toggle favorite status.
  Future<bool> toggleFavorite(String lawyerId) async {
    final alreadySaved = await isFavorite(lawyerId);
    if (alreadySaved) {
      await removeFavorite(lawyerId);
      return false;
    } else {
      await addFavorite(lawyerId);
      return true;
    }
  }
}
