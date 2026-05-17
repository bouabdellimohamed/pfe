import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/lawyer_model.dart';
import 'user_preference_builder.dart';

/// Handles the "لا يهمني" (Not Interested) dismissal feature.
///
/// When a user dismisses a recommendation:
/// 1. The lawyer is stored in `users/{uid}/dismissals/{lawyerId}` and never
///    shown again.
/// 2. A **negative interaction** is recorded so the recommendation engine
///    reduces the weight of the related speciality and wilaya.
class DismissalService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _profileBuilder = UserPreferenceBuilder();

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _dismissalsRef(String uid) =>
      _db.collection('users').doc(uid).collection('dismissals');

  CollectionReference<Map<String, dynamic>> _interactionsRef(String uid) =>
      _db.collection('users').doc(uid).collection('interactions');

  /// Records a dismissal for [lawyer] and updates the user preference profile.
  ///
  /// Firestore writes:
  /// - `users/{uid}/dismissals/{lawyerId}` – permanent exclusion marker.
  /// - `users/{uid}/interactions/{auto-id}` with `type: 'not_interested'` –
  ///   negative signal consumed by [UserPreferenceBuilder].
  Future<void> dismiss(LawyerModel lawyer) async {
    final uid = _uid;
    if (uid == null) return;

    final lawyerId = lawyer.uid;
    final speciality = lawyer.speciality.trim();
    final wilaya = lawyer.wilaya?.trim();

    // ── 1. Permanent exclusion marker ────────────────────────────────────────
    await _dismissalsRef(uid).doc(lawyerId).set({
      'lawyerId': lawyerId,
      if (speciality.isNotEmpty) 'speciality': speciality,
      if (wilaya != null && wilaya.isNotEmpty) 'wilaya': wilaya,
      'dismissedAt': FieldValue.serverTimestamp(),
    });

    // ── 2. Negative interaction signal ───────────────────────────────────────
    // baseWeight is negative so UserPreferenceBuilder subtracts from scores.
    await _interactionsRef(uid).add({
      'type': 'not_interested',
      'lawyerId': lawyerId,
      if (speciality.isNotEmpty) 'speciality': speciality,
      if (wilaya != null && wilaya.isNotEmpty) 'wilaya': wilaya,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // ── 3. Refresh preferred fields so Firestore stays in sync ───────────────
    await _refreshPreferredFields(uid);
  }

  /// Loads the set of already-dismissed lawyer IDs for [uid].
  Future<Set<String>> loadDismissedIds(String uid) async {
    final snap = await _dismissalsRef(uid).get();
    return snap.docs.map((d) => d.id).toSet();
  }

  Future<void> _refreshPreferredFields(String uid) async {
    try {
      final lawyersSnap = await _db.collection('lawyers').get();
      final lawyersById = <String, LawyerModel>{};
      for (final doc in lawyersSnap.docs) {
        if (!UserPreferenceBuilder.isApprovedLawyer(doc.data())) continue;
        lawyersById[doc.id] =
            LawyerModel.fromMap({...doc.data(), 'uid': doc.id});
      }
      final profile = await _profileBuilder.build(uid, lawyersById: lawyersById);
      await _profileBuilder.syncPreferredFields(uid, profile);
    } catch (_) {
      // Non-critical — the profile will be refreshed on next app launch.
    }
  }
}
