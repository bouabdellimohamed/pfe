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
  /// Lawyers the user explicitly dismissed via "لا يهمني".
  final Set<String> dismissedLawyerIds;

  const UserPreferenceProfile({
    required this.specialityScores,
    required this.wilayaScores,
    required this.specialityLabels,
    required this.wilayaLabels,
    required this.favoriteLawyerIds,
    required this.chattedLawyerIds,
    this.dismissedLawyerIds = const {},
  });

  static const empty = UserPreferenceProfile(
    specialityScores: {},
    wilayaScores: {},
    specialityLabels: {},
    wilayaLabels: {},
    favoriteLawyerIds: {},
    chattedLawyerIds: {},
    dismissedLawyerIds: {},
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

  /// Lawyers the user already knows OR explicitly dismissed — excluded from
  /// discovery recommendations.
  Set<String> get excludedLawyerIds =>
      {...favoriteLawyerIds, ...chattedLawyerIds, ...dismissedLawyerIds};
}
