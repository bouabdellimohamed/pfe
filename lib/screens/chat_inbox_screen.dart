import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_models.dart';
import '../services/chat_service.dart';
import 'chat_thread_screen.dart';

class ChatInboxScreen extends StatelessWidget {
  final bool isLawyer;
  const ChatInboxScreen({super.key, required this.isLawyer});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final chat = ChatService();

    if (uid.isEmpty) {
      return const Center(child: Text('Veuillez vous connecter.'));
    }

    final stream = isLawyer
        ? chat.streamLawyerConversations(uid)
        : chat.streamUserConversations(uid);

    return StreamBuilder<List<ConversationModel>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Erreur: ${snap.error}'));
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const Center(child: Text('Aucune conversation.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final c = list[i];
            final subtitle = c.lastMessageText ?? 'Conversation démarrée';
            return ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              title: Text('Demande: ${c.requestId}'),
              subtitle: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatThreadScreen(conversationId: c.id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

