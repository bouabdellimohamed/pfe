import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

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
      return Center(
        child: Text(
          'Veuillez vous connecter.',
          style: GoogleFonts.poppins(color: isLawyer ? Colors.white70 : Colors.black54)
        )
      );
    }

    final stream = isLawyer
        ? chat.streamLawyerConversations(uid)
        : chat.streamUserConversations(uid);

    return StreamBuilder<List<ConversationModel>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: isLawyer ? const Color(0xFFC9A84C) : const Color(0xFF1565C0)));
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'Erreur: ${snap.error}',
              style: GoogleFonts.poppins(color: isLawyer ? Colors.white70 : Colors.black54)
            )
          );
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return Center(
            child: Text(
              'Aucune conversation.',
              style: GoogleFonts.poppins(color: isLawyer ? Colors.white70 : Colors.black54)
            )
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final c = list[i];
            final subtitle = c.lastMessageText ?? 'Conversation démarrée';
            return FutureBuilder<String>(
              future: chat.getOtherPersonName(
                currentUserId: uid,
                userId: c.userId,
                lawyerId: c.lawyerId,
                lawyerName: c.lawyerName,
                userName: c.userName,
              ),
              builder: (context, nameSnap) {
                final otherPersonName = nameSnap.data ?? 'المحاور';
                return Container(
                  decoration: BoxDecoration(
                    color: isLawyer ? Colors.white.withOpacity(0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isLawyer ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
                    boxShadow: isLawyer ? [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
                    ] : [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text(
                      otherPersonName,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isLawyer ? Colors.white : Colors.black87
                      )
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isLawyer ? Colors.white70 : Colors.black54
                        )
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: isLawyer ? const Color(0xFFC9A84C) : Colors.grey.shade400,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatThreadScreen(conversationId: c.id),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
