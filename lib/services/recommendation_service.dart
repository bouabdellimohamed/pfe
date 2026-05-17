import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' show Color;
import '../models/lawyer_model.dart';
import '../models/user_preference_profile.dart';
import '../utils/legal_text_normalize.dart';
import '../utils/recency_weight.dart';
import 'user_preference_builder.dart';

enum RecommendationReason {
  matchSearch,
  similarUsers,
  inYourArea,
  highRating,
}

class LawyerRecommendation {
  final LawyerModel lawyer;
  final double totalScore;
  final double contentScore;
  final double collaborativeScore;
  final double qualityScore;
  final RecommendationReason primaryReason;

  const LawyerRecommendation({
    required this.lawyer,
    required this.totalScore,
    required this.contentScore,
    required this.collaborativeScore,
    required this.qualityScore,
    required this.primaryReason,
  });

  /// Relevance score 0–100 (content + collaborative + capped quality contribution).
  int get matchPercent => totalScore.round().clamp(0, 100);
}

class RecommendationService {
  final _db = FirebaseFirestore.instance;
  final _profileBuilder = UserPreferenceBuilder();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static const double _minSimilarUserOverlap = 4.0;

  Future<Map<String, LawyerModel>> _loadLawyersMap() async {
    final snap = await _db.collection('lawyers').get();
    final map = <String, LawyerModel>{};
    for (final doc in snap.docs) {
      if (!UserPreferenceBuilder.isApprovedLawyer(doc.data())) continue;
      map[doc.id] = LawyerModel.fromMap({...doc.data(), 'uid': doc.id});
    }
    return map;
  }

  double _rawSpecialityAffinity(LawyerModel lawyer, Map<String, double> interests) {
    if (interests.isEmpty) return 0;
    final tokens = LegalTextNormalize.splitSpecialities(lawyer.speciality);
    var best = 0.0;
    for (final token in tokens) {
      for (final e in interests.entries) {
        if (LegalTextNormalize.specialityMatches(e.key, token)) {
          best = math.max(best, e.value);
        }
      }
    }
    return best;
  }

  double _rawWilayaAffinity(LawyerModel lawyer, Map<String, double> interests) {
    if (lawyer.wilaya == null || interests.isEmpty) return 0;
    var best = 0.0;
    for (final e in interests.entries) {
      if (LegalTextNormalize.wilayaMatches(e.key, lawyer.wilaya)) {
        best = math.max(best, e.value);
      }
    }
    return best;
  }

  bool _lawyerMatchesUserInterests(
    LawyerModel lawyer,
    UserPreferenceProfile profile, {
    bool strictForCollaborative = false,
  }) {
    if (!profile.hasPersonalization) return true;

    final specAffinity = _rawSpecialityAffinity(lawyer, profile.specialityScores);
    final wilayaAffinity = _rawWilayaAffinity(lawyer, profile.wilayaScores);

    final hasSpecInterest = profile.specialityScores.isNotEmpty;
    final hasWilayaInterest = profile.wilayaScores.isNotEmpty;

    if (hasSpecInterest && hasWilayaInterest) {
      if (strictForCollaborative) {
        return specAffinity > 0 && wilayaAffinity > 0;
      }
      return specAffinity > 0 || wilayaAffinity > 0;
    }
    if (hasSpecInterest) return specAffinity > 0;
    if (hasWilayaInterest) return wilayaAffinity > 0;
    return true;
  }

  Map<String, double> _profileFromUserDoc(Map<String, dynamic> data) {
    final specs = <String, double>{};
    final wilayas = <String, double>{};

    final prefSpecs = data['preferredSpecialities'];
    if (prefSpecs is List) {
      for (var i = 0; i < prefSpecs.length; i++) {
        final key = UserPreferenceBuilder.norm(prefSpecs[i].toString());
        if (key.isNotEmpty) specs[key] = 2.0 - i * 0.15;
      }
    }

    final prefWilayas = data['preferredWilayas'];
    if (prefWilayas is List) {
      for (var i = 0; i < prefWilayas.length; i++) {
        final key = UserPreferenceBuilder.norm(prefWilayas[i].toString());
        if (key.isNotEmpty) wilayas[key] = 1.5 - i * 0.1;
      }
    }

    return specs;
  }

  double _similarityScore(
    UserPreferenceProfile me,
    Map<String, double> otherSpecs,
    Map<String, double> otherWilayas,
  ) {
    var score = LegalTextNormalize.mapOverlap(
      me.specialityScores,
      otherSpecs,
      keyMatches: LegalTextNormalize.specialityMatches,
    );
    score += LegalTextNormalize.mapOverlap(
      me.wilayaScores,
      otherWilayas,
      keyMatches: LegalTextNormalize.wilayaMatches,
    );
    return score;
  }

  /// Finds users with overlapping interests, then their relevant lawyers.
  Future<Set<String>> _findCollaborativeLawyerIds({
    required String uid,
    required UserPreferenceProfile profile,
    required Set<String> excludeIds,
    required Map<String, LawyerModel> lawyersById,
  }) async {
    final candidates = <String>{};
    if (!profile.hasPersonalization) return candidates;

    final similarUsers = <String, double>{};

    // A) Overlap via stored preferences on other user documents.
    final usersSnap = await _db.collection('users').limit(300).get();
    for (final doc in usersSnap.docs) {
      if (doc.id == uid) continue;
      final data = doc.data();
      final otherSpecs = <String, double>{..._profileFromUserDoc(data)};
      final otherWilayas = <String, double>{};
      final pw = data['preferredWilayas'];
      if (pw is List) {
        for (var i = 0; i < pw.length; i++) {
          final key = UserPreferenceBuilder.norm(pw[i].toString());
          if (key.isNotEmpty) otherWilayas[key] = 1.5 - i * 0.1;
        }
      }

      final sim = _similarityScore(profile, otherSpecs, otherWilayas);
      if (sim >= _minSimilarUserOverlap) {
        similarUsers[doc.id] = math.max(similarUsers[doc.id] ?? 0, sim);
      }
    }

    // B) Users who posted consultations/requests in the same case types (exact Firestore labels).
    final topSpecs = profile.topSpecialities(3);
    if (topSpecs.isNotEmpty) {
      try {
        final cons = await _db
            .collection('consultations')
            .where('type', whereIn: topSpecs.length > 10 ? topSpecs.sublist(0, 10) : topSpecs)
            .limit(80)
            .get();
        for (final doc in cons.docs) {
          final otherUid = doc.data()['userId'] as String?;
          if (otherUid == null || otherUid == uid) continue;
          final at = RecencyWeight.parseTime(doc.data()['createdAt']);
          final w = RecencyWeight.apply(3.0, at, halfLifeDays: RecencyWeight.hlConsultation);
          similarUsers[otherUid] = (similarUsers[otherUid] ?? 0) + w;
        }

        final reqs = await _db
            .collection('requests')
            .where('type', whereIn: topSpecs.length > 10 ? topSpecs.sublist(0, 10) : topSpecs)
            .limit(80)
            .get();
        for (final doc in reqs.docs) {
          final otherUid = doc.data()['userId'] as String?;
          if (otherUid == null || otherUid == uid) continue;
          final at = RecencyWeight.parseTime(doc.data()['createdAt']);
          final w = RecencyWeight.apply(3.0, at, halfLifeDays: RecencyWeight.hlConsultation);
          similarUsers[otherUid] = (similarUsers[otherUid] ?? 0) + w;
        }
      } catch (_) {
        for (final spec in topSpecs) {
          final cons = await _db
              .collection('consultations')
              .where('type', isEqualTo: spec)
              .limit(40)
              .get();
          for (final doc in cons.docs) {
            final otherUid = doc.data()['userId'] as String?;
            if (otherUid == null || otherUid == uid) continue;
            final at = RecencyWeight.parseTime(doc.data()['createdAt']);
            final w = RecencyWeight.apply(2.0, at, halfLifeDays: RecencyWeight.hlConsultation);
            similarUsers[otherUid] = (similarUsers[otherUid] ?? 0) + w;
          }
        }
      }
    }

    similarUsers.removeWhere((_, score) => score < _minSimilarUserOverlap);
    if (similarUsers.isEmpty) return candidates;

    final ranked = similarUsers.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in ranked.take(20)) {
      final otherUid = entry.key;

      final favs =
          await _db.collection('users').doc(otherUid).collection('favorites').get();
      for (final f in favs.docs) {
        final id = f.id;
        if (excludeIds.contains(id)) continue;
        final lawyer = lawyersById[id];
        if (lawyer != null &&
            _lawyerMatchesUserInterests(lawyer, profile, strictForCollaborative: true)) {
          candidates.add(id);
        }
      }

      final chats = await _db
          .collection('conversations')
          .where('userId', isEqualTo: otherUid)
          .limit(30)
          .get();
      for (final c in chats.docs) {
        final lid = c.data()['lawyerId'] as String?;
        if (lid == null || excludeIds.contains(lid)) continue;
        final lawyer = lawyersById[lid];
        if (lawyer != null &&
            _lawyerMatchesUserInterests(lawyer, profile, strictForCollaborative: true)) {
          candidates.add(lid);
        }
      }
    }

    return candidates;
  }

  LawyerRecommendation? _scoreLawyer({
    required LawyerModel lawyer,
    required UserPreferenceProfile profile,
    required Set<String> collaborativeIds,
    required bool personalizedMode,
  }) {
    final maxSpec = profile.specialityScores.values.fold<double>(0, math.max);
    final maxWilaya = profile.wilayaScores.values.fold<double>(0, math.max);

    final specAffinity = _rawSpecialityAffinity(lawyer, profile.specialityScores);
    final wilayaAffinity = _rawWilayaAffinity(lawyer, profile.wilayaScores);

    final double contentSpec = personalizedMode && maxSpec > 0
        ? (specAffinity / maxSpec) * 30.0
        : 0.0;
    final double contentWilaya = personalizedMode && maxWilaya > 0
        ? (wilayaAffinity / maxWilaya) * 10.0
        : 0.0;
    final double contentScore = contentSpec + contentWilaya;

    final bool fromSimilarUsers = collaborativeIds.contains(lawyer.uid);
    final double collaborativeScore = fromSimilarUsers ? 20.0 : 0.0;

    final double qualityScore = (lawyer.finalScore.clamp(0.0, 100.0) / 100.0) * 15.0 +
        (lawyer.rating.clamp(0.0, 5.0) / 5.0) * 10.0 +
        math.min(lawyer.reviewCount / 20.0, 1.0) * 5.0;

    final double totalScore = math
        .min(contentScore + collaborativeScore + qualityScore, 100.0)
        .toDouble();

    if (personalizedMode) {
      final relevant = contentScore > 0 || collaborativeScore > 0;
      if (!relevant) return null;
    }

    final primary = _pickPrimaryReason(
      collaborativeScore: collaborativeScore,
      contentSpec: contentSpec,
      contentWilaya: contentWilaya,
    );

    return LawyerRecommendation(
      lawyer: lawyer,
      totalScore: totalScore,
      contentScore: contentScore,
      collaborativeScore: collaborativeScore,
      qualityScore: qualityScore,
      primaryReason: primary,
    );
  }

  RecommendationReason _pickPrimaryReason({
    required double collaborativeScore,
    required double contentSpec,
    required double contentWilaya,
  }) {
    if (collaborativeScore > 0 && contentSpec < 20) {
      return RecommendationReason.similarUsers;
    }
    if (contentSpec >= 12) return RecommendationReason.matchSearch;
    if (contentWilaya >= 5) return RecommendationReason.inYourArea;
    if (collaborativeScore > 0) return RecommendationReason.similarUsers;
    return RecommendationReason.highRating;
  }

  Future<List<LawyerRecommendation>> getRecommendations({int limit = 6}) async {
    final uid = _uid;
    if (uid == null) return [];

    try {
      final lawyersMap = await _loadLawyersMap();
      if (lawyersMap.isEmpty) return [];

      final profile = await _profileBuilder.build(uid, lawyersById: lawyersMap);
      await _profileBuilder.syncPreferredFields(uid, profile);

      final exclude = profile.excludedLawyerIds;
      final personalized = profile.hasPersonalization;

      final collaborativeIds = personalized
          ? await _findCollaborativeLawyerIds(
              uid: uid,
              profile: profile,
              excludeIds: exclude,
              lawyersById: lawyersMap,
            )
          : <String>{};

      final scored = <LawyerRecommendation>[];
      for (final lawyer in lawyersMap.values) {
        if (exclude.contains(lawyer.uid)) continue;

        final rec = _scoreLawyer(
          lawyer: lawyer,
          profile: profile,
          collaborativeIds: collaborativeIds,
          personalizedMode: personalized,
        );
        if (rec != null) scored.add(rec);
      }

      scored.sort((a, b) {
        if (b.totalScore != a.totalScore) {
          return b.totalScore.compareTo(a.totalScore);
        }
        return b.lawyer.finalScore.compareTo(a.lawyer.finalScore);
      });

      if (scored.isNotEmpty) return scored.take(limit).toList();

      return _qualityFallback(lawyersMap.values, exclude, limit);
    } catch (_) {
      final lawyersMap = await _loadLawyersMap();
      // إعادة بناء الـ excludedIds من الـ dismissals و favorites و chats
      // حتى لا يظهر محامٍ مرفوض أو معروف في الـ fallback.
      Set<String> safeExclude = {};
      try {
        final uid2 = _uid;
        if (uid2 != null) {
          final profile2 = await _profileBuilder.build(uid2, lawyersById: lawyersMap);
          safeExclude = profile2.excludedLawyerIds;
        }
      } catch (_) {}
      return _qualityFallback(lawyersMap.values, safeExclude, limit);
    }
  }

  List<LawyerRecommendation> _qualityFallback(
    Iterable<LawyerModel> lawyers,
    Set<String> exclude,
    int limit,
  ) {
    final pool = lawyers.where((l) => !exclude.contains(l.uid)).toList()
      ..sort((a, b) {
        if (b.finalScore != a.finalScore) return b.finalScore.compareTo(a.finalScore);
        return b.rating.compareTo(a.rating);
      });

    return pool.take(limit).map((lawyer) {
      final double q = (lawyer.finalScore.clamp(0.0, 100.0) / 100.0) * 15.0 +
          (lawyer.rating.clamp(0.0, 5.0) / 5.0) * 10.0 +
          math.min(lawyer.reviewCount / 20.0, 1.0) * 5.0;
      return LawyerRecommendation(
        lawyer: lawyer,
        totalScore: q,
        contentScore: 0,
        collaborativeScore: 0,
        qualityScore: q,
        primaryReason: RecommendationReason.highRating,
      );
    }).toList();
  }

  static String reasonTranslationKey(RecommendationReason reason) =>
      switch (reason) {
        RecommendationReason.matchSearch => 'rec_reason_match_search',
        RecommendationReason.similarUsers => 'rec_reason_similar_users',
        RecommendationReason.inYourArea => 'rec_reason_in_area',
        RecommendationReason.highRating => 'rec_reason_high_rating',
      };

  static Color reasonColor(RecommendationReason reason) => switch (reason) {
        RecommendationReason.matchSearch => const Color(0xFF0052D4),
        RecommendationReason.similarUsers => const Color(0xFF7C3AED),
        RecommendationReason.inYourArea => const Color(0xFF059669),
        RecommendationReason.highRating => const Color(0xFFF59E0B),
      };
}
