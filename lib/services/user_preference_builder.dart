import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lawyer_model.dart';
import '../models/user_preference_profile.dart';
import '../utils/legal_text_normalize.dart';
import '../utils/recency_weight.dart';

/// Builds [UserPreferenceProfile] from Firestore — each signal counted once with time decay.
class UserPreferenceBuilder {
  final _db = FirebaseFirestore.instance;

  static String norm(String? value) => LegalTextNormalize.norm(value);

  static bool isApprovedLawyer(Map<String, dynamic> data) {
    final status = data['status'] as String?;
    if (status == 'rejected' || status == 'pending') return false;
    if ((data['disabled'] ?? false) == true) return false;
    return true;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortNewestFirst(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String timeField,
  ) {
    final list = [...docs];
    list.sort((a, b) {
      final ta = RecencyWeight.parseTime(a.data()[timeField]);
      final tb = RecencyWeight.parseTime(b.data()[timeField]);
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });
    return list;
  }

  void _addScore(
    Map<String, double> scores,
    Map<String, String> labels,
    String? raw,
    double weight,
  ) {
    final original = (raw ?? '').trim();
    final key = norm(original);
    if (key.isEmpty || weight <= 0) return;
    scores[key] = (scores[key] ?? 0) + weight;
    labels[key] = original;
  }

  void _addSpecialities(
    Map<String, double> scores,
    Map<String, String> labels,
    String? raw,
    double weight,
  ) {
    if (raw == null || raw.trim().isEmpty || weight <= 0) return;
    for (final part in raw.split(',')) {
      _addScore(scores, labels, part.trim(), weight);
    }
  }

  Future<void> _loadProfileViews({
    required String uid,
    required Map<String, LawyerModel> lawyersById,
    required Map<String, double> specialityScores,
    required Map<String, double> wilayaScores,
    required Map<String, String> specialityLabels,
    required Map<String, String> wilayaLabels,
    required void Function(
      LawyerModel? lawyer, {
      required double specW,
      required double wilayaW,
    }) applyLawyerSignals,
  }) async {
    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await _db
          .collection('users')
          .doc(uid)
          .collection('interactions')
          .where('type', isEqualTo: 'profile_view')
          .orderBy('timestamp', descending: true)
          .limit(40)
          .get();
    } catch (_) {
      snap = await _db
          .collection('users')
          .doc(uid)
          .collection('interactions')
          .limit(60)
          .get();
    }

    final docs = _sortNewestFirst(snap.docs, 'timestamp');
    final seenLawyers = <String>{};

    for (final doc in docs) {
      final d = doc.data();
      if (d['type'] != 'profile_view') continue;

      final at = RecencyWeight.parseTime(d['timestamp']);
      final lawyerId = d['lawyerId'] as String?;

      if (lawyerId != null && seenLawyers.contains(lawyerId)) continue;
      if (lawyerId != null) seenLawyers.add(lawyerId);

      if (lawyerId != null && lawyersById.containsKey(lawyerId)) {
        final w = RecencyWeight.apply(1.2, at, halfLifeDays: RecencyWeight.hlProfileView);
        applyLawyerSignals(lawyersById[lawyerId], specW: w, wilayaW: w);
      } else {
        final w = RecencyWeight.apply(1.0, at, halfLifeDays: RecencyWeight.hlProfileView);
        _addScore(specialityScores, specialityLabels, d['speciality'] as String?, w);
        _addScore(wilayaScores, wilayaLabels, d['wilaya'] as String?, w);
      }
    }
  }

  Future<UserPreferenceProfile> build(
    String uid, {
    required Map<String, LawyerModel> lawyersById,
  }) async {
    final specialityScores = <String, double>{};
    final wilayaScores = <String, double>{};
    final specialityLabels = <String, String>{};
    final wilayaLabels = <String, String>{};
    final favoriteLawyerIds = <String>{};
    final chattedLawyerIds = <String>{};

    void applyLawyerSignals(
      LawyerModel? lawyer, {
      required double specW,
      required double wilayaW,
    }) {
      if (lawyer == null) return;
      _addSpecialities(specialityScores, specialityLabels, lawyer.speciality, specW);
      _addScore(wilayaScores, wilayaLabels, lawyer.wilaya, wilayaW);
    }

    final consultations =
        await _db.collection('consultations').where('userId', isEqualTo: uid).limit(80).get();
    for (final doc in _sortNewestFirst(consultations.docs, 'createdAt')) {
      final at = RecencyWeight.parseTime(doc.data()['createdAt']);
      final w = RecencyWeight.apply(3.0, at, halfLifeDays: RecencyWeight.hlConsultation);
      _addScore(specialityScores, specialityLabels, doc.data()['type'] as String?, w);
    }

    final requests =
        await _db.collection('requests').where('userId', isEqualTo: uid).limit(80).get();
    for (final doc in _sortNewestFirst(requests.docs, 'createdAt')) {
      final at = RecencyWeight.parseTime(doc.data()['createdAt']);
      final w = RecencyWeight.apply(3.0, at, halfLifeDays: RecencyWeight.hlConsultation);
      _addScore(specialityScores, specialityLabels, doc.data()['type'] as String?, w);
    }

    final favorites =
        await _db.collection('users').doc(uid).collection('favorites').get();
    for (final doc in favorites.docs) {
      favoriteLawyerIds.add(doc.id);
      final at = RecencyWeight.parseTime(doc.data()['savedAt']);
      final w = RecencyWeight.apply(2.0, at, halfLifeDays: RecencyWeight.hlFavorite);
      applyLawyerSignals(lawyersById[doc.id], specW: w, wilayaW: w);
    }

    final conversations =
        await _db.collection('conversations').where('userId', isEqualTo: uid).limit(50).get();
    for (final doc in _sortNewestFirst(conversations.docs, 'lastMessageAt')) {
      final lawyerId = doc.data()['lawyerId'] as String?;
      if (lawyerId == null || lawyerId.isEmpty) continue;
      chattedLawyerIds.add(lawyerId);
      final at = RecencyWeight.parseTime(
        doc.data()['lastMessageAt'] ?? doc.data()['createdAt'],
      );
      final w = RecencyWeight.apply(1.5, at, halfLifeDays: RecencyWeight.hlChat);
      applyLawyerSignals(lawyersById[lawyerId], specW: w, wilayaW: w);
    }

    // ── Dismissals: subtract weight for "لا يهمني" actions ─────────────────
    final dismissedIds = <String>{};
    try {
      final dismissalsSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('dismissals')
          .get();
      for (final doc in dismissalsSnap.docs) {
        dismissedIds.add(doc.id);
        final d = doc.data();
        final at = RecencyWeight.parseTime(d['dismissedAt']);
        // Negative weights: penalise the speciality (-2.5) and wilaya (-1.2)
        // so the recommendation engine deprioritises similar lawyers.
        // We clamp scores to 0 later so they never go negative.
        final specPenalty = RecencyWeight.apply(2.5, at, halfLifeDays: RecencyWeight.hlDismissal);
        final wilayaPenalty = RecencyWeight.apply(1.2, at, halfLifeDays: RecencyWeight.hlDismissal);
        final rawSpec = d['speciality'] as String?;
        final rawWilaya = d['wilaya'] as String?;
        if (rawSpec != null && rawSpec.isNotEmpty) {
          for (final part in rawSpec.split(',')) {
            final key = norm(part.trim());
            if (key.isNotEmpty && specialityScores.containsKey(key)) {
              specialityScores[key] =
                  (specialityScores[key]! - specPenalty).clamp(0.0, double.infinity);
            }
          }
        }
        if (rawWilaya != null && rawWilaya.isNotEmpty) {
          final key = norm(rawWilaya);
          if (key.isNotEmpty && wilayaScores.containsKey(key)) {
            wilayaScores[key] =
                (wilayaScores[key]! - wilayaPenalty).clamp(0.0, double.infinity);
          }
        }
      }
    } catch (_) {
      // Dismissals are best-effort; continue without them.
    }

    try {
      final searches = await _db
          .collection('users')
          .doc(uid)
          .collection('interactions')
          .where('type', isEqualTo: 'search')
          .orderBy('timestamp', descending: true)
          .limit(30)
          .get();
      for (final doc in searches.docs) {
        final d = doc.data();
        final at = RecencyWeight.parseTime(d['timestamp']);
        final w = RecencyWeight.apply(2.5, at, halfLifeDays: RecencyWeight.hlSearch);
        _addScore(specialityScores, specialityLabels, d['speciality'] as String?, w);
        _addScore(wilayaScores, wilayaLabels, d['wilaya'] as String?, w);
      }
    } catch (_) {
      final fallback = await _db
          .collection('users')
          .doc(uid)
          .collection('interactions')
          .limit(50)
          .get();
      for (final doc in _sortNewestFirst(fallback.docs, 'timestamp')) {
        if (doc.data()['type'] != 'search') continue;
        final at = RecencyWeight.parseTime(doc.data()['timestamp']);
        final w = RecencyWeight.apply(2.5, at, halfLifeDays: RecencyWeight.hlSearch);
        _addScore(specialityScores, specialityLabels, doc.data()['type'] as String?, w);
        _addScore(wilayaScores, wilayaLabels, doc.data()['wilaya'] as String?, w);
      }
    }

    await _loadProfileViews(
      uid: uid,
      lawyersById: lawyersById,
      specialityScores: specialityScores,
      wilayaScores: wilayaScores,
      specialityLabels: specialityLabels,
      wilayaLabels: wilayaLabels,
      applyLawyerSignals: applyLawyerSignals,
    );

    return UserPreferenceProfile(
      specialityScores: specialityScores,
      wilayaScores: wilayaScores,
      specialityLabels: specialityLabels,
      wilayaLabels: wilayaLabels,
      favoriteLawyerIds: favoriteLawyerIds,
      chattedLawyerIds: chattedLawyerIds,
      dismissedLawyerIds: dismissedIds,
    );
  }

  Future<void> syncPreferredFields(String uid, UserPreferenceProfile profile) async {
    await _db.collection('users').doc(uid).set({
      'preferredSpecialities': profile.topSpecialities(5),
      'preferredWilayas': profile.topWilayas(5),
      'preferencesUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
