import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_models.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, String> _nameCache = {}; // cache لأسماء المستخدمين

  CollectionReference get _conversations =>
      _firestore.collection('conversations');

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

  Future<ConversationModel?> getConversation(String conversationId) async {
    try {
      final doc = await _conversations.doc(conversationId).get();
      if (doc.exists) {
        return ConversationModel.fromFirestore(doc);
      }
    } catch (e) {
      print('Error getting conversation: $e');
    }
    return null;
  }

  Future<String> getOtherPersonName({
    required String currentUserId,
    required String userId,
    required String lawyerId,
    String? lawyerName,
    String? userName,
  }) async {
    final isCurrentUserLawyer = lawyerId == currentUserId;
    String result = '';

    try {
      if (isCurrentUserLawyer) {
        // أنا المحامي — أجلب اسم العميل
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>? ?? {};
          result = (data['fullName'] ?? data['full_name'] ??
              data['name'] ?? data['displayName'] ?? '').toString().trim();
        }
        if (result.isEmpty && userName != null) result = userName.trim();
        if (result.isEmpty) result = 'مستخدم';
      } else {
        // أنا العميل — أجلب اسم المحامي
        final lawyerDoc = await _firestore.collection('lawyers').doc(lawyerId).get();
        if (lawyerDoc.exists) {
          final data = lawyerDoc.data() as Map<String, dynamic>? ?? {};
          result = (data['name'] ?? data['fullName'] ??
              data['full_name'] ?? '').toString().trim();
        }
        if (result.isEmpty && lawyerName != null) result = lawyerName.trim();
        if (result.isEmpty) result = 'محامي';
      }
    } catch (e) {
      print('Error getting other person name: $e');
      result = isCurrentUserLawyer ? 'مستخدم' : 'محامي';
    }
    return result;
  }

  // ✅ دمج المحادثات: محادثة واحدة لكل (userId, lawyerId) مهما كان requestId
  Stream<List<ConversationModel>> streamUserConversations(String userId) {
    return _conversations
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
      final all = s.docs.map(ConversationModel.fromFirestore).toList();

      // نجمع حسب lawyerId ونأخذ الأحدث فقط
      final Map<String, ConversationModel> merged = {};
      for (final conv in all) {
        final key = conv.lawyerId;
        final existing = merged[key];
        final convTime = conv.lastMessageAt ?? conv.createdAt;
        if (existing == null) {
          merged[key] = conv;
        } else {
          final existTime = existing.lastMessageAt ?? existing.createdAt;
          if (convTime.isAfter(existTime)) merged[key] = conv;
        }
      }

      final list = merged.values.toList();
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
      final all = s.docs.map(ConversationModel.fromFirestore).toList();

      // نجمع حسب userId ونأخذ الأحدث فقط
      final Map<String, ConversationModel> merged = {};
      for (final conv in all) {
        final key = conv.userId;
        final existing = merged[key];
        final convTime = conv.lastMessageAt ?? conv.createdAt;
        if (existing == null) {
          merged[key] = conv;
        } else {
          final existTime = existing.lastMessageAt ?? existing.createdAt;
          if (convTime.isAfter(existTime)) merged[key] = conv;
        }
      }

      final list = merged.values.toList();
      list.sort((a, b) => (b.lastMessageAt ?? b.createdAt)
          .compareTo(a.lastMessageAt ?? a.createdAt));
      return list;
    });
  }

  Future<String> _getSenderName(String senderId) async {
    // تحقق من الـ cache أولاً
    if (_nameCache.containsKey(senderId)) {
      return _nameCache[senderId]!;
    }

    String senderName = 'مستخدم';
    try {
      // محاولة البحث عن المستخدم أولاً
      final userDoc = await _firestore.collection('users').doc(senderId).get();
      if (userDoc.exists) {
        senderName = userDoc['fullName'] ?? 'مستخدم';
      } else {
        // محاولة البحث عن المحامي
        final lawyerDoc =
            await _firestore.collection('lawyers').doc(senderId).get();
        if (lawyerDoc.exists) {
          senderName = lawyerDoc['name'] ?? 'محامي';
        }
      }
    } catch (e) {
      print('Error fetching sender name: $e');
    }

    // احفظ في الـ cache
    _nameCache[senderId] = senderName;
    return senderName;
  }

  Stream<List<MessageModel>> streamMessages(String conversationId) {
    // ✅ الاستماع مباشرةً على subcollection الرسائل — يضمن التحديث الفوري
    return _conversations
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      final messages = <MessageModel>[];

      for (final doc in snapshot.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final senderId = (d['senderId'] ?? '').toString();
        var senderName = (d['senderName'] ?? '').toString();

        // إذا لم يكن هناك senderName مخزَّن، نجلبه من Firestore (مع cache)
        if (senderName.isEmpty) {
          senderName = await _getSenderName(senderId);
        }

        messages.add(MessageModel(
          id: doc.id,
          senderId: senderId,
          senderName: senderName.isNotEmpty ? senderName : 'مستخدم',
          text: (d['text'] ?? '').toString(),
          createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          attachedFileName: d['attachedFileName']?.toString(),
          attachedFileType: d['attachedFileType']?.toString(),
          attachedFileBase64: d['attachedFileBase64']?.toString(),
        ));
      }

      return messages;
    });
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
    String? attachedFileName,
    String? attachedFileType,
    String? attachedFileBase64,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && attachedFileBase64 == null) return;

    // الحصول على اسم المرسل
    String senderName = 'مستخدم';
    try {
      // محاولة البحث عن المستخدم أولاً
      final userDoc = await _firestore.collection('users').doc(senderId).get();
      if (userDoc.exists) {
        senderName = userDoc['fullName'] ?? 'مستخدم';
      } else {
        // محاولة البحث عن المحامي
        final lawyerDoc =
            await _firestore.collection('lawyers').doc(senderId).get();
        if (lawyerDoc.exists) {
          senderName = lawyerDoc['name'] ?? 'محامي';
        }
      }
    } catch (e) {
      // في حالة حدوث خطأ، سيتم استخدام القيمة الافتراضية
      print('Error getting sender name: $e');
    }

    final messageData = {
      'senderId': senderId,
      'senderName': senderName,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (attachedFileName != null) messageData['attachedFileName'] = attachedFileName;
    if (attachedFileType != null) messageData['attachedFileType'] = attachedFileType;
    if (attachedFileBase64 != null) messageData['attachedFileBase64'] = attachedFileBase64;

    await _conversations.doc(conversationId).collection('messages').add(messageData);

    final lastMessageText = attachedFileName != null ? '📎 Pièce jointe: $attachedFileName' : trimmed;

    await _conversations.doc(conversationId).update({
      'lastMessageText': lastMessageText,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }
}
