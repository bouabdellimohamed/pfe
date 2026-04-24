import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final String requestId;
  final String userId;
  final String lawyerId;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String? lastMessageText;

  ConversationModel({
    required this.id,
    required this.requestId,
    required this.userId,
    required this.lawyerId,
    required this.createdAt,
    this.lastMessageAt,
    this.lastMessageText,
  });

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      id: doc.id,
      requestId: (d['requestId'] ?? '').toString(),
      userId: (d['userId'] ?? '').toString(),
      lawyerId: (d['lawyerId'] ?? '').toString(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageAt: (d['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessageText: d['lastMessageText']?.toString(),
    );
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: (d['senderId'] ?? '').toString(),
      text: (d['text'] ?? '').toString(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

