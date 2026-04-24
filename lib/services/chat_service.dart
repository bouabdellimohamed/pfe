import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_models.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _conversations => _firestore.collection('conversations');

  Future<String> getOrCreateConversationIdForRequest({
    required String requestId,
    required String userId,
    required String lawyerId,
  }) async {
    final existing = await _conversations
        .where('requestId', isEqualTo: requestId)
        .where('userId', isEqualTo: userId)
        .where('lawyerId', isEqualTo: lawyerId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final doc = await _conversations.add({
      'requestId': requestId,
      'userId': userId,
      'lawyerId': lawyerId,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageAt': null,
      'lastMessageText': null,
    });
    return doc.id;
  }

  Stream<List<ConversationModel>> streamUserConversations(String userId) {
    return _conversations
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
          final list = s.docs.map(ConversationModel.fromFirestore).toList();
          list.sort((a, b) => (b.lastMessageAt ?? b.createdAt)
              .compareTo(a.lastMessageAt ?? a.createdAt));
          return list;
        });
  }

  Stream<List<ConversationModel>> streamLawyerConversations(String lawyerId) {
    return _conversations
        .where('lawyerId', isEqualTo: lawyerId)
        .snapshots()
        .map((s) {
          final list = s.docs.map(ConversationModel.fromFirestore).toList();
          list.sort((a, b) => (b.lastMessageAt ?? b.createdAt)
              .compareTo(a.lastMessageAt ?? a.createdAt));
          return list;
        });
  }

  Stream<List<MessageModel>> streamMessages(String conversationId) {
    return _conversations
        .doc(conversationId)
        .collection('messages')
        .snapshots()
        .map((s) {
          final list = s.docs.map(MessageModel.fromFirestore).toList();
          list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return list;
        });
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    await _conversations.doc(conversationId).collection('messages').add({
      'senderId': senderId,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _conversations.doc(conversationId).update({
      'lastMessageText': trimmed,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }
}

