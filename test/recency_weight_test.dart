import 'package:flutter_test/flutter_test.dart';
import 'package:first_app/utils/recency_weight.dart';

void main() {
  test('recent events keep full weight, old events decay', () {
    final now = DateTime(2026, 5, 17);
    final recent = RecencyWeight.apply(3.0, now.subtract(const Duration(days: 2)), reference: now);
    final old = RecencyWeight.apply(3.0, now.subtract(const Duration(days: 200)), reference: now);

    expect(recent, greaterThan(old));
    expect(recent, closeTo(3.0, 0.01));
    expect(old, lessThan(1.0));
  });
}
