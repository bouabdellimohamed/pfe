import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'screens/welcome_screen.dart';
import 'screens/lawyer_main_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/admin_home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 🔄 تحميل
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ غير مسجل
        if (!snapshot.hasData) {
          return const WelcomeScreen();
        }

        // ✅ مسجل → نجيب role
        return FutureBuilder(
          future: _getUserRole(),
          builder: (context, roleSnapshot) {
            if (!roleSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            String role = roleSnapshot.data!;

            if (role == 'admin') {
              return const AdminHomeScreen();
            }
            if (role == 'lawyer') {
              return const LawyerMainScreen(); // أو Dashboard الجديد
            } else {
              return const FeedHomeScreen();
            }
          },
        );
      },
    );
  }

  Future<String> _getUserRole() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'user';

    // Admin users are in a dedicated collection
    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();
      if (adminDoc.exists) return 'admin';
    } catch (_) {}

    // ✅ افصل الحسابات: المحامي موجود في collection lawyers
    try {
      final lawyerDoc = await FirebaseFirestore.instance
          .collection('lawyers')
          .doc(user.uid)
          .get();
      if (lawyerDoc.exists) return 'lawyer';
    } catch (_) {}

    // المستخدم العادي موجود في users (وفيه role = user)
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) return (userDoc.data()?['role'] ?? 'user') as String;
    } catch (_) {}

    // fallback
    return 'user';
  }
}
