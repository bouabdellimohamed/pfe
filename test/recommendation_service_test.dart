import 'package:flutter_test/flutter_test.dart';
import 'package:first_app/models/user_preference_profile.dart';

void main() {
  test('topSpecialities returns original Firestore labels', () {
    const profile = UserPreferenceProfile(
      specialityScores: {
        'droit familial': 9.0,
        'droit pénal': 3.0,
      },
      wilayaScores: {'alger': 2.0},
      specialityLabels: {
        'droit familial': 'Droit familial',
        'droit pénal': 'Droit pénal',
      },
      wilayaLabels: {'alger': 'Alger'},
      favoriteLawyerIds: {},
      chattedLawyerIds: {},
    );

    expect(profile.topSpecialities(1), ['Droit familial']);
    expect(profile.topWilayas(1), ['Alger']);
    expect(profile.hasPersonalization, isTrue);
    expect(profile.excludedLawyerIds, isEmpty);
  });
}
