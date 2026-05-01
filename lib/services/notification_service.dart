import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      data: map['data'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'data': data,
    };
  }
}

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // إضافة إشعار جديد
  Future<void> addNotification({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'data': data,
      });
    } catch (e) {
      print('خطأ في إضافة الإشعار: $e');
    }
  }

  // الحصول على الإشعارات غير المقروءة
  Stream<List<NotificationModel>> getUnreadNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        // Removed server-side orderBy to prevent flickering with null server timestamps
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList();
          // Sort in memory instead
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return list;
        });
  }

  // الحصول على جميع الإشعارات
  Stream<List<NotificationModel>> getAllNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        // Removed server-side orderBy to handle null server timestamps correctly
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList();
          // Sort in memory
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return list;
        });
  }

  // وضع علامة على الإشعار كمقروء
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('خطأ في تحديث الإشعار: $e');
    }
  }

  // حذف إشعار
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('خطأ في حذف الإشعار: $e');
    }
  }

  // حذف جميع الإشعارات للمستخدم
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in notifications.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('خطأ في حذف الإشعارات: $e');
    }
  }
}
