import 'package:cloud_firestore/cloud_firestore.dart';

class LawyerModel {
  final String uid;
  final String email;
  final String name;
  final String speciality;
  final String? phone;
  final String? city;
  final int? experience; // لـ 25% من السكور
  final String? photoUrl;
  final String? bio;
  final bool isGeneralist;
  final String? wilaya;
  final String? daira;
  final String? commune;

  // --- حقول الـ Scoring System الجديدة ---
  final double rating; // لـ 35% من السكور (مثلاً 4.5)
  final int reviewCount; // عدد التقييمات
  final int activityPoints; // لـ 10% (نقاط المنشورات والردود)
  final double responseRate; // لـ 10% (سرعة الرد)
  final int successfulDemands; // لـ 5% (الطلبات المقبولة)
  final double finalScore; // السكور النهائي المحسوب (0.0 إلى 100.0)

  LawyerModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.speciality,
    this.phone,
    this.city,
    this.experience,
    this.photoUrl,
    this.bio,
    required this.isGeneralist,
    this.wilaya,
    this.daira,
    this.commune,
    // قيم افتراضية للحقول الجديدة
    this.rating = 0.0,
    this.reviewCount = 0,
    this.activityPoints = 0,
    this.responseRate = 0.0,
    this.successfulDemands = 0,
    this.finalScore = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'speciality': speciality,
      'phone': phone,
      'city': city,
      'experience': experience,
      'photoUrl': photoUrl,
      'bio': bio,
      'role': 'lawyer',
      'isGeneralist': isGeneralist,
      'wilaya': wilaya,
      'daira': daira,
      'commune': commune,
      'rating': rating,
      'reviewCount': reviewCount,
      'activityPoints': activityPoints,
      'responseRate': responseRate,
      'successfulDemands': successfulDemands,
      'finalScore': finalScore,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory LawyerModel.fromMap(Map<String, dynamic> map) {
    return LawyerModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      speciality: map['speciality'] ?? '',
      phone: map['phone'],
      city: map['city'],
      experience: map['experience'] ?? 0,
      photoUrl: map['photoUrl'],
      bio: map['bio'],
      isGeneralist: map['isGeneralist'] ?? false,
      wilaya: map['wilaya'],
      daira: map['daira'],
      commune: map['commune'],
      // جلب الحقول الجديدة من Firestore
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      activityPoints: map['activityPoints'] ?? 0,
      responseRate: (map['responseRate'] ?? 0.0).toDouble(),
      successfulDemands: map['successfulDemands'] ?? 0,
      finalScore: (map['finalScore'] ?? 0.0).toDouble(),
    );
  }
}
