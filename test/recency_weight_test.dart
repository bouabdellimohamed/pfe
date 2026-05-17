import 'package:flutter_test/flutter_test.dart';
import 'package:first_app/utils/recency_weight.dart';

void main() {
  final ref = DateTime(2026, 5, 17);

  // ── helpers ──────────────────────────────────────────────────────────────
  DateTime ago(int days) => ref.subtract(Duration(days: days));

  // ── decayFactor ──────────────────────────────────────────────────────────

  group('decayFactor', () {
    test('حدث اليوم = وزن كامل 1.0', () {
      expect(
        RecencyWeight.decayFactor(ago(0), reference: ref),
        closeTo(1.0, 0.001),
      );
    });

    test('بعد نصف حياة واحد = 0.5', () {
      // بعد hlDefault=30 يوم يجب أن يكون الوزن ≈ 0.5
      final f = RecencyWeight.decayFactor(ago(30), reference: ref);
      expect(f, closeTo(0.5, 0.01));
    });

    test('كل نوع إشارة يضمحل بسرعته الخاصة', () {
      const days = 30;
      final consultation = RecencyWeight.decayFactor(
        ago(days), reference: ref, halfLifeDays: RecencyWeight.hlConsultation,
      );
      final search = RecencyWeight.decayFactor(
        ago(days), reference: ref, halfLifeDays: RecencyWeight.hlSearch,
      );
      final view = RecencyWeight.decayFactor(
        ago(days), reference: ref, halfLifeDays: RecencyWeight.hlProfileView,
      );
      // hlConsultation=45 > hlSearch=21 > hlProfileView=14
      // كلما كان نصف الحياة أكبر كلما كان الاضمحلال أبطأ
      expect(consultation, greaterThan(search));
      expect(search, greaterThan(view));
    });

    test('حدث قديم جداً لا يصل إلى الصفر (floor = 0.05)', () {
      final f = RecencyWeight.decayFactor(ago(3650), reference: ref); // 10 سنوات
      expect(f, greaterThanOrEqualTo(0.05));
    });

    test('timestamp مجهول يعيد 0.5 (نصف حياة واحد)', () {
      expect(RecencyWeight.decayFactor(null, reference: ref), closeTo(0.5, 0.001));
    });

    test('timestamp مستقبلي (clock skew) لا يتجاوز 1.0', () {
      final future = ref.add(const Duration(days: 5));
      final f = RecencyWeight.decayFactor(future, reference: ref);
      expect(f, lessThanOrEqualTo(1.0));
    });
  });

  // ── apply ─────────────────────────────────────────────────────────────────

  group('apply', () {
    test('وزن سالب أو صفر يعيد 0 مباشرة', () {
      expect(RecencyWeight.apply(0.0, ago(1), reference: ref), equals(0.0));
      expect(RecencyWeight.apply(-1.0, ago(1), reference: ref), equals(0.0));
    });

    test('الحدث الحديث يحتفظ بوزنه تقريباً', () {
      // 2 أيام مع hlConsultation=45: e^(-ln2*2/45) ≈ 0.969 → 3.0*0.969 ≈ 2.91
      final w = RecencyWeight.apply(
        3.0, ago(2),
        reference: ref,
        halfLifeDays: RecencyWeight.hlConsultation,
      );
      expect(w, greaterThan(2.8));
      expect(w, lessThanOrEqualTo(3.0));
    });

    test('الحدث القديم يزن أقل من الحديث', () {
      final recent = RecencyWeight.apply(3.0, ago(2), reference: ref,
          halfLifeDays: RecencyWeight.hlConsultation);
      final old = RecencyWeight.apply(3.0, ago(200), reference: ref,
          halfLifeDays: RecencyWeight.hlConsultation);
      expect(recent, greaterThan(old));
    });

    test('المفضّل (hlFavorite=60) يضمحل أبطأ من البحث (hlSearch=21)', () {
      const days = 21;
      final fav = RecencyWeight.apply(2.0, ago(days), reference: ref,
          halfLifeDays: RecencyWeight.hlFavorite);
      final search = RecencyWeight.apply(2.0, ago(days), reference: ref,
          halfLifeDays: RecencyWeight.hlSearch);
      // بعد 21 يوم: search ≈ 2.0*0.5=1.0  fav ≈ 2.0*0.78=1.56
      expect(fav, greaterThan(search));
    });

    test('عقوبة الرفض (hlDismissal=30) تتلاشى مع الوقت', () {
      final fresh = RecencyWeight.apply(2.5, ago(0), reference: ref,
          halfLifeDays: RecencyWeight.hlDismissal);
      final old = RecencyWeight.apply(2.5, ago(90), reference: ref,
          halfLifeDays: RecencyWeight.hlDismissal);
      // بعد 90 يوم (3 أضعاف نصف الحياة) يجب أن تكون العقوبة أقل بكثير
      expect(fresh / old, greaterThan(5.0));
    });
  });
}
