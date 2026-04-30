import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'screens/welcome_screen.dart';
import 'screens/lawyer_main_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/admin_dashboard_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // نحتفظ بـ Future لتجنب إعادة استدعاء Firestore في كل rebuild
  Future<String>? _roleFuture;
  String? _lastUid;

  Future<String> _getUserRole() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'user';

    // Admin
    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();
      if (adminDoc.exists) return 'admin';
    } catch (_) {}

    // Lawyer
    try {
      final lawyerDoc = await FirebaseFirestore.instance
          .collection('lawyers')
          .doc(user.uid)
          .get();
      if (lawyerDoc.exists) return 'lawyer';
    } catch (_) {}

    // User
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) return (userDoc.data()?['role'] ?? 'user') as String;
    } catch (_) {}

    return 'user';
  }

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
          _roleFuture = null;
          _lastUid = null;
          return const WelcomeScreen();
        }

        // ✅ مسجل → نجيب role مع تجنب إعادة الاستدعاء إذا لم يتغير المستخدم
        final currentUid = snapshot.data!.uid;
        if (_roleFuture == null || _lastUid != currentUid) {
          _lastUid = currentUid;
          _roleFuture = _getUserRole();
        }

        return FutureBuilder<String>(
          future: _roleFuture,
          builder: (context, roleSnapshot) {
            if (!roleSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = roleSnapshot.data!;

            // ✅ إصلاح خطأ #1: إضافة مسار الأدمن
            if (role == 'admin') {
              return const AdminDashboardScreen();
            } else if (role == 'lawyer') {
              return const LawyerMainScreen();
            } else {
              return const FeedHomeScreen();
            }
          },
        );
      },
    );
  }
}
