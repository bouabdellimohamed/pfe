import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'screens/welcome_screen.dart';
import 'screens/lawyer_main_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'services/notification_service.dart';
import 'dart:async';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // نحتفظ بـ Future لتجنب إعادة استدعاء Firestore في كل rebuild
  Future<String>? _roleFuture;
  String? _lastUid;
  
  StreamSubscription? _notifSub;
  final _notifService = NotificationService();
  Set<String> _notifiedIds = {};

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  void _setupNotificationListener(String uid) {
    _notifSub?.cancel();
    // Reset notified IDs when user changes
    _notifiedIds = {};
    
    _notifSub = _notifService.getUnreadNotifications(uid).listen((notifs) {
      if (notifs.isEmpty) return;
      
      final newNotif = notifs.first;
      // Only notify if we haven't shown this one before and it's very recent (e.g., within last 10 seconds)
      // to avoid showing old unread notifications on app start.
      final isRecent = DateTime.now().difference(newNotif.timestamp).inSeconds < 10;
      
      if (!_notifiedIds.contains(newNotif.id) && isRecent) {
        _notifiedIds.add(newNotif.id);
        _showInAppNotification(newNotif);
      }
    });
  }

  void _showInAppNotification(NotificationModel notif) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2D42),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF1565C0).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF1565C0), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notif.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(notif.message, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _getUserRole() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'user';
    
    // Setup listener when we have a user
    _setupNotificationListener(user.uid);

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
