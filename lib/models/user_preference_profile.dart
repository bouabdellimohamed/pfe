/// Aggregated user interests used by the recommendation engine.
class UserPreferenceProfile {
  /// Keys = normalized (lowercase). Values = accumulated weight.
  final Map<String, double> specialityScores;
  final Map<String, double> wilayaScores;
  /// normalized speciality → original label as stored in Firestore (`type` field).
  final Map<String, String> specialityLabels;
  /// normalized wilaya → original label.
  final Map<String, String> wilayaLabels;
  final Set<String> favoriteLawyerIds;
  final Set<String> chattedLawyerIds;

  const UserPreferenceProfile({
    required this.specialityScores,
    required this.wilayaScores,
    required this.specialityLabels,
    required this.wilayaLabels,
    required this.favoriteLawyerIds,
    required this.chattedLawyerIds,
  });

  static const empty = UserPreferenceProfile(
    specialityScores: {},
    wilayaScores: {},
    specialityLabels: {},
    wilayaLabels: {},
    favoriteLawyerIds: {},
    chattedLawyerIds: {},
  );

  bool get hasPersonalization =>
      specialityScores.isNotEmpty || wilayaScores.isNotEmpty;

  /// Original Firestore labels (correct casing) for queries.
  List<String> topSpecialities(int n) {
    final sorted = specialityScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(n)
        .map((e) => specialityLabels[e.key] ?? e.key)
        .where((s) => s.isNotEmpty)
        .toList();
  }

  List<String> topWilayas(int n) {
    final sorted = wilayaScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(n)
        .map((e) => wilayaLabels[e.key] ?? e.key)
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Lawyers the user already knows — excluded from discovery recommendations.
  Set<String> get excludedLawyerIds =>
      {...favoriteLawyerIds, ...chattedLawyerIds};
}
