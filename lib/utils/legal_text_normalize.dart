/// Normalizes legal domain / wilaya strings for reliable matching.
class LegalTextNormalize {
  LegalTextNormalize._();

  static String norm(String? value) {
    var s = (value ?? '').trim().toLowerCase();
    const accents = {
      'à': 'a', 'â': 'a', 'ä': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'î': 'i', 'ï': 'i',
      'ô': 'o', 'ö': 'o',
      'ù': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c',
    };
    accents.forEach((k, v) => s = s.replaceAll(k, v));
    return s.replaceAll(RegExp(r'\s+'), ' ');
  }

  static List<String> splitSpecialities(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    return raw
        .split(',')
        .map(norm)
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// True if interest and lawyer speciality token refer to the same domain.
  static bool specialityMatches(String interestKey, String lawyerToken) {
    final a = norm(interestKey);
    final b = norm(lawyerToken);
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    if (a.contains(b) || b.contains(a)) return true;

    final stripDroit = (String s) => s.replaceFirst(RegExp(r'^droit\s+'), '').trim();
    final ca = stripDroit(a);
    final cb = stripDroit(b);
    if (ca.isNotEmpty && cb.isNotEmpty && (ca == cb || ca.contains(cb) || cb.contains(ca))) {
      return true;
    }
    return false;
  }

  static bool wilayaMatches(String? userWilayaKey, String? lawyerWilaya) {
    return norm(userWilayaKey) == norm(lawyerWilaya) && norm(lawyerWilaya).isNotEmpty;
  }

  static double mapOverlap(
    Map<String, double> a,
    Map<String, double> b, {
    required bool Function(String left, String right) keyMatches,
  }) {
    if (a.isEmpty || b.isEmpty) return 0;
    var overlap = 0.0;
    for (final ea in a.entries) {
      for (final eb in b.entries) {
        if (keyMatches(ea.key, eb.key)) {
          overlap += ea.value * eb.value;
        }
      }
    }
    return overlap;
  }
}
