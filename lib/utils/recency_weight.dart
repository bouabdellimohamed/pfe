import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Applies smooth exponential time decay so recent signals outweigh older ones.
///
/// Formula: weight = baseWeight × max(floor, e^(−ln2 × days / halfLifeDays))
///
/// Each signal type has its own [halfLifeDays] constant — a strong signal like
/// a consultation decays much more slowly than a weak one like a profile view.
class RecencyWeight {
  RecencyWeight._();

  // ── Half-life constants (days) ────────────────────────────────────────────
  /// استشارة / طلب — نية حقيقية وقوية، تضمحل ببطء.
  static const double hlConsultation = 45.0;

  /// بحث مباشر — إشارة متوسطة، تضمحل بسرعة معقولة.
  static const double hlSearch = 21.0;

  /// إضافة للمفضلة — تفضيل صريح، أبطأ اضمحلالاً.
  static const double hlFavorite = 60.0;

  /// محادثة — تفاعل فعلي، اضمحلال متوسط.
  static const double hlChat = 30.0;

  /// زيارة ملف محامٍ — إشارة ضعيفة، تضمحل بسرعة.
  static const double hlProfileView = 14.0;

  /// عقوبة "لا يهمني" — تتلاشى بعد فترة لأن تفضيلات المستخدم تتغيّر.
  static const double hlDismissal = 30.0;

  /// قيمة افتراضية عند غياب السياق.
  static const double hlDefault = 30.0;

  /// الحدّ الأدنى للوزن — الإشارات القديمة جداً لا تصل إلى الصفر تماماً.
  static const double _floor = 0.05;

  // ── Core API ──────────────────────────────────────────────────────────────

  static DateTime? parseTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  /// Returns a smooth multiplier in [_floor, 1.0].
  ///
  /// [halfLifeDays] controls how fast the signal decays:
  /// - small value (e.g. 14) → decays fast (profile views).
  /// - large value (e.g. 60) → decays slowly (favorites).
  ///
  /// When [eventTime] is null (timestamp missing from Firestore), returns the
  /// value corresponding to one full half-life — a conservative middle ground.
  static double decayFactor(
    DateTime? eventTime, {
    DateTime? reference,
    double halfLifeDays = hlDefault,
  }) {
    if (eventTime == null) {
      // Unknown age → treat as one half-life old (= 0.5 before floor clamp).
      return math.max(_floor, 0.5);
    }

    final now = reference ?? DateTime.now();
    final days = now.difference(eventTime).inDays.toDouble();

    // Clamp to 0 so future timestamps (clock skew) don't inflate weight.
    final d = days.clamp(0.0, double.infinity);

    final raw = math.exp(-math.ln2 * d / halfLifeDays);
    return raw.clamp(_floor, 1.0);
  }

  /// Applies decay to [baseWeight] with a signal-specific half-life.
  ///
  /// Pass the appropriate `hl*` constant as [halfLifeDays]:
  /// ```dart
  /// RecencyWeight.apply(3.0, at, halfLifeDays: RecencyWeight.hlConsultation);
  /// ```
  static double apply(
    double baseWeight,
    DateTime? eventTime, {
    DateTime? reference,
    double halfLifeDays = hlDefault,
  }) {
    if (baseWeight <= 0) return 0;
    return baseWeight *
        decayFactor(eventTime, reference: reference, halfLifeDays: halfLifeDays);
  }
}
