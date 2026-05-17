import 'package:flutter_test/flutter_test.dart';
import 'package:first_app/utils/legal_text_normalize.dart';

void main() {
  test('specialityMatches handles accents and partial names', () {
    expect(
      LegalTextNormalize.specialityMatches('droit familial', 'Droit familial'),
      isTrue,
    );
    expect(
      LegalTextNormalize.specialityMatches('droit pénal', 'Droit penal'),
      isTrue,
    );
    expect(
      LegalTextNormalize.specialityMatches('droit familial', 'familial'),
      isTrue,
    );
    expect(
      LegalTextNormalize.specialityMatches('droit commercial', 'droit familial'),
      isFalse,
    );
  });

  test('wilayaMatches is case insensitive', () {
    expect(LegalTextNormalize.wilayaMatches('alger', 'Alger'), isTrue);
    expect(LegalTextNormalize.wilayaMatches('alger', 'Oran'), isFalse);
  });
}
