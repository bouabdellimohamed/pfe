import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/lawyer_model.dart';
import 'user_preference_builder.dart';

/// Logs lightweight events (search / profile view) — no duplicate of consultations or favorites.
class InteractionTrackingService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _profileBuilder = UserPreferenceBuilder();

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _interactionsRef =>
      _db.collection('users').doc(_uid).collection('interactions');

  Future<void> logInteraction({
    required String type,
    String? speciality,
    String? wilaya,
    String? lawyerId,
    String? source,
  }) async {
    if (_uid == null) return;

    await _interactionsRef.add({
      'type': type,
      if (speciality != null && speciality.isNotEmpty) 'speciality': speciality,
      if (wilaya != null && wilaya.isNotEmpty) 'wilaya': wilaya,
      if (lawyerId != null && lawyerId.isNotEmpty) 'lawyerId': lawyerId,
      if (source != null && source.isNotEmpty) 'source': source,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> recordSearch({required String speciality, required String wilaya}) async {
    await logInteraction(
      type: 'search',
      speciality: speciality,
      wilaya: wilaya,
      source: 'direct_search',
    );
    await _refreshPreferredFields();
  }

  Future<void> recordProfileView({
    required String lawyerId,
    String? speciality,
    String? wilaya,
    String source = 'profile',
  }) async {
    await logInteraction(
      type: 'profile_view',
      lawyerId: lawyerId,
      speciality: speciality,
      wilaya: wilaya,
      source: source,
    );
    // Profile views are weak signals — do not sync preferred fields on every view.
  }

  Future<void> _refreshPreferredFields() async {
    final uid = _uid;
    if (uid == null) return;

    final lawyersSnap = await _db.collection('lawyers').get();
    final lawyersById = <String, LawyerModel>{};
    for (final doc in lawyersSnap.docs) {
      if (!UserPreferenceBuilder.isApprovedLawyer(doc.data())) continue;
      lawyersById[doc.id] = LawyerModel.fromMap({...doc.data(), 'uid': doc.id});
    }

    final profile = await _profileBuilder.build(uid, lawyersById: lawyersById);
    await _profileBuilder.syncPreferredFields(uid, profile);
  }
}
