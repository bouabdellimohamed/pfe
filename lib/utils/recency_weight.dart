import 'package:cloud_firestore/cloud_firestore.dart';

/// Applies time decay so recent user actions weigh more than old ones.
class RecencyWeight {
  RecencyWeight._();

  static DateTime? parseTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  /// Multiplier in ]0, 1] based on how many days ago the event occurred.
  static double decayFactor(DateTime? eventTime, {DateTime? reference}) {
    final now = reference ?? DateTime.now();
    if (eventTime == null) return 0.45;

    final days = now.difference(eventTime).inDays;
    if (days <= 0) return 1.0;
    if (days <= 7) return 1.0;
    if (days <= 30) return 0.85;
    if (days <= 90) return 0.55;
    if (days <= 180) return 0.3;
    return 0.12;
  }

  static double apply(double baseWeight, DateTime? eventTime, {DateTime? reference}) {
    if (baseWeight <= 0) return 0;
    return baseWeight * decayFactor(eventTime, reference: reference);
  }
}
