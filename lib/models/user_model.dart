import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String? phone;
  final int? age;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phone,
    this.age,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'age': age,
    'role': 'user',
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
    uid: m['uid'] ?? '',
    fullName: m['fullName'] ?? '',
    email: m['email'] ?? '',
    phone: m['phone'],
    age: m['age'],
    createdAt: m['createdAt'] is Timestamp
        ? (m['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
  );
}
