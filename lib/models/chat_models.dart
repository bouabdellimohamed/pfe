import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final String requestId;
  final String userId;
  final String lawyerId;
  final String? lawyerName;
  final String? userName;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String? lastMessageText;

  ConversationModel({
    required this.id,
    required this.requestId,
    required this.userId,
    required this.lawyerId,
    this.lawyerName,
    this.userName,
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
      lawyerName: d['lawyerName']?.toString(),
      userName: d['userName']?.toString(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageAt: (d['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessageText: d['lastMessageText']?.toString(),
    );
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;
  final String? attachedFileName;
  final String? attachedFileType;
  final String? attachedFileBase64;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
    this.attachedFileName,
    this.attachedFileType,
    this.attachedFileBase64,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: (d['senderId'] ?? '').toString(),
      senderName: (d['senderName'] ?? 'مستخدم').toString(),
      text: (d['text'] ?? '').toString(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attachedFileName: d['attachedFileName']?.toString(),
      attachedFileType: d['attachedFileType']?.toString(),
      attachedFileBase64: d['attachedFileBase64']?.toString(),
    );
  }
}
