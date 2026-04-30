import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_models.dart';
import '../services/chat_service.dart';
import 'chat_thread_screen.dart';

class ChatInboxScreen extends StatelessWidget {
  final bool isLawyer;
  const ChatInboxScreen({super.key, required this.isLawyer});

  Future<void> _deleteConversation(BuildContext context, String convId) async {
    try {
      final msgs = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(convId)
          .collection('messages')
          .get();
      for (final m in msgs.docs) {
        await m.reference.delete();
      }
      await FirebaseFirestore.instance.collection('conversations').doc(convId).delete();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final chat = ChatService();

    final Color bgColor = isLawyer ? const Color(0xFF0D1B2A) : const Color(0xFFF8FAFC);
    final Color textColor = isLawyer ? const Color(0xFFF0EDE8) : const Color(0xFF1E293B);
    final Color subTextColor = isLawyer ? const Color(0xFF8A9BB0) : const Color(0xFF64748B);
    final Color cardColor = isLawyer ? const Color(0xFF1B2D42) : Colors.white;
    final Color primaryColor = isLawyer ? const Color(0xFFC9A84C) : const Color(0xFF0052D4);

    if (uid.isEmpty) {
      return Center(
        child: Text('Veuillez vous connecter.', style: TextStyle(color: subTextColor, fontSize: 16)),
      );
    }

    final stream = isLawyer ? chat.streamLawyerConversations(uid) : chat.streamUserConversations(uid);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Text(
          'Messagerie',
          style: TextStyle(
            color: textColor,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: StreamBuilder<List<ConversationModel>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snap.hasError) {
            return Center(child: Text('Erreur: ${snap.error}', style: TextStyle(color: subTextColor)));
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.chat_bubble_outline_rounded, size: 60, color: primaryColor.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Aucune conversation',
                    style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vos messages apparaîtront ici.',
                    style: TextStyle(color: subTextColor, fontSize: 14),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final c = list[i];
              final subtitle = c.lastMessageText ?? 'Nouvelle conversation...';
              final timeStr = c.lastMessageAt != null ? _formatTime(c.lastMessageAt!) : '';

              return FutureBuilder<String>(
                future: chat.getOtherPersonName(
                  currentUserId: uid,
                  userId: c.userId,
                  lawyerId: c.lawyerId,
                  lawyerName: c.lawyerName,
                  userName: c.userName,
                ),
                builder: (context, nameSnap) {
                  final otherPersonName = nameSnap.data ?? 'Chargement...';
                  return Dismissible(
                    key: Key(c.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 28),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
                          SizedBox(height: 4),
                          Text('Supprimer', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    confirmDismiss: (_) async {
                      HapticFeedback.mediumImpact();
                      return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text('Supprimer ?', style: TextStyle(fontWeight: FontWeight.bold)),
                          content: Text('Voulez-vous supprimer la conversation avec "$otherPersonName" ?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler', style: TextStyle(color: Colors.grey))),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ) ?? false;
                    },
                    onDismissed: (_) {
                      _deleteConversation(context, c.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Conversation supprimée', style: const TextStyle(fontWeight: FontWeight.bold)),
                          backgroundColor: const Color(0xFF1E293B),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ChatThreadScreen(conversationId: c.id)),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isLawyer ? Colors.white.withOpacity(0.05) : Colors.grey.shade200),
                          boxShadow: [
                            if (!isLawyer)
                              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  otherPersonName.isNotEmpty ? otherPersonName[0].toUpperCase() : '?',
                                  style: TextStyle(color: primaryColor, fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          otherPersonName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: textColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (timeStr.isNotEmpty)
                                        Text(
                                          timeStr,
                                          style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.w600),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: subTextColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
