import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

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
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return days[time.weekday - 1];
    } else {
      return '${time.day}/${time.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final chat = ChatService();

    // Theme Colors
    final Color bgColor = isLawyer ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final Color textColor = isLawyer ? Colors.white : const Color(0xFF1E293B);
    final Color subTextColor = isLawyer ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final Color cardColor = isLawyer ? const Color(0xFF1E293B) : Colors.white;
    final Color primaryColor = isLawyer ? const Color(0xFFC5A059) : const Color(0xFF2563EB);

    if (uid.isEmpty) {
      return Center(
        child: Text('Veuillez vous connecter.', style: GoogleFonts.poppins(color: subTextColor, fontSize: 16)),
      );
    }

    final stream = isLawyer ? chat.streamLawyerConversations(uid) : chat.streamUserConversations(uid);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(bgColor, textColor, primaryColor),
          StreamBuilder<List<ConversationModel>>(
            stream: stream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: primaryColor)));
              }
              if (snap.hasError) {
                return SliverFillRemaining(child: Center(child: Text('Erreur: ${snap.error}', style: GoogleFonts.poppins(color: subTextColor))));
              }
              final list = snap.data ?? [];
              if (list.isEmpty) {
                return _buildEmptyState(primaryColor, textColor, subTextColor);
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildConversationItem(ctx, list[i], uid, chat, isLawyer, primaryColor, cardColor, textColor, subTextColor),
                    childCount: list.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(Color bgColor, Color textColor, Color primaryColor) {
    return SliverAppBar(
      backgroundColor: bgColor,
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        centerTitle: false,
        title: Text(
          'Messagerie',
          style: GoogleFonts.outfit(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search_rounded, color: textColor.withOpacity(0.6)),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildConversationItem(
    BuildContext context,
    ConversationModel c,
    String uid,
    ChatService chat,
    bool isLawyer,
    Color primaryColor,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    final isUnread = !c.isRead && c.lastMessageSenderId != uid;
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
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Dismissible(
            key: Key(c.id),
            direction: DismissDirection.endToStart,
            background: _buildDismissBackground(),
            confirmDismiss: (_) => _confirmDelete(context, otherPersonName),
            onDismissed: (_) => _deleteConversation(context, c.id),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatThreadScreen(conversationId: c.id)),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isUnread ? primaryColor.withOpacity(isLawyer ? 0.08 : 0.05) : cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isUnread ? primaryColor.withOpacity(0.3) : textColor.withOpacity(0.05),
                    width: isUnread ? 1.5 : 1,
                  ),
                  boxShadow: [
                    if (!isLawyer)
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    _buildAvatar(otherPersonName, primaryColor, isUnread),
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
                                  style: GoogleFonts.outfit(
                                    fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 16,
                                    color: isUnread ? primaryColor : textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (timeStr.isNotEmpty)
                                Text(
                                  timeStr,
                                  style: GoogleFonts.poppins(
                                    color: isUnread ? primaryColor.withOpacity(0.8) : subTextColor,
                                    fontSize: 11,
                                    fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: isUnread ? textColor.withOpacity(0.8) : subTextColor,
                                    fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (isUnread)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 4, spreadRadius: 1),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String name, Color primaryColor, bool isUnread) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(isUnread ? 0.9 : 0.2),
            primaryColor.withOpacity(isUnread ? 0.7 : 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: primaryColor.withOpacity(isUnread ? 0.5 : 0.1), width: 1),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.outfit(
            color: isUnread ? Colors.white : primaryColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 28),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text('Supprimer', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    HapticFeedback.mediumImpact();
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Supprimer ?', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Voulez-vous supprimer la conversation avec "$name" ?', style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Annuler', style: GoogleFonts.poppins(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildEmptyState(Color primaryColor, Color textColor, Color subTextColor) {
    return SliverFillRemaining(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline_rounded, size: 80, color: primaryColor.withOpacity(0.3)),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune conversation',
            style: GoogleFonts.outfit(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos messages apparaîtront ici.',
            style: GoogleFonts.poppins(color: subTextColor, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
