import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_models.dart';
import '../services/chat_service.dart';

class ChatThreadScreen extends StatefulWidget {
  final String conversationId;
  const ChatThreadScreen({super.key, required this.conversationId});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _chat = ChatService();
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  String _otherPersonName = 'المحاور';

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadOtherPersonName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final conversation = await _chat.getConversation(widget.conversationId);
    if (conversation == null) return;

    final bool iAmTheLawyer = conversation.lawyerId == uid;
    String otherName = '';

    print('=== DEBUG CHAT NAME ===');
    print('My UID: $uid');
    print('lawyerId: ${conversation.lawyerId}');
    print('userId: ${conversation.userId}');
    print('iAmTheLawyer: $iAmTheLawyer');
    print('stored lawyerName: ${conversation.lawyerName}');
    print('stored userName: ${conversation.userName}');

    try {
      if (iAmTheLawyer) {
        // أنا المحامي — أجلب اسم العميل من users
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(conversation.userId)
            .get();

        print('users doc exists: ${userDoc.exists}');
        if (userDoc.exists) {
          print('users doc data: ${userDoc.data()}');
          final data = userDoc.data() ?? {};
          otherName = (data['fullName'] ?? data['full_name'] ??
              data['name'] ?? data['displayName'] ?? '').toString().trim();
        }

        // fallback: اسم محفوظ في المحادثة
        if (otherName.isEmpty && conversation.userName != null) {
          otherName = conversation.userName!.trim();
        }
        if (otherName.isEmpty) otherName = 'مستخدم';

      } else {
        // أنا العميل — أجلب اسم المحامي من lawyers
        final lawyerDoc = await FirebaseFirestore.instance
            .collection('lawyers')
            .doc(conversation.lawyerId)
            .get();

        print('lawyers doc exists: ${lawyerDoc.exists}');
        if (lawyerDoc.exists) {
          print('lawyers doc data: ${lawyerDoc.data()}');
          final data = lawyerDoc.data() ?? {};
          otherName = (data['name'] ?? data['fullName'] ??
              data['full_name'] ?? '').toString().trim();
        }

        // fallback: اسم محفوظ في المحادثة
        if (otherName.isEmpty && conversation.lawyerName != null) {
          otherName = conversation.lawyerName!.trim();
        }
        if (otherName.isEmpty) otherName = 'محامي';
      }
    } catch (e) {
      print('Error loading name: $e');
      otherName = iAmTheLawyer ? 'مستخدم' : 'محامي';
    }

    print('Final otherName: $otherName');

    if (mounted) setState(() => _otherPersonName = otherName);
  }

  @override
  void initState() {
    super.initState();
    _loadOtherPersonName();
  }

  Future<void> _send() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final text = _ctrl.text;
    _ctrl.clear();
    await _chat.sendMessage(
      conversationId: widget.conversationId,
      senderId: uid,
      text: text,
    );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(_otherPersonName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chat.streamMessages(widget.conversationId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Erreur: ${snap.error}'));
                }
                final list = snap.data ?? [];
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });
                if (list.isEmpty) {
                  return const Center(
                    child: Text('Dites bonjour et démarrez la conversation.'),
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final m = list[i];
                    final mine = m.senderId == uid;
                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        constraints: const BoxConstraints(maxWidth: 320),
                        decoration: BoxDecoration(
                          color: mine
                              ? const Color(0xFF1565C0)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          m.text,
                          style: TextStyle(
                            color: mine ? Colors.white : Colors.black87,
                            height: 1.25,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Écrivez un message...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
