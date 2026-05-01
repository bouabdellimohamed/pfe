import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../models/consultation_model.dart';
import '../models/lawyer_model.dart';
import '../widgets/profile_avatar.dart';
import 'chat_thread_screen.dart';

class UserMyRequestsScreen extends StatelessWidget {
  final String uid;
  const UserMyRequestsScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // ── CUSTOM HEADER ──
          Container(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 24,
                right: 24,
                bottom: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0052D4), Color(0xFF4364F7), Color(0xFF6FB1FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF0052D4),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                  spreadRadius: -10,
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.mark_email_unread_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mes Demandes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Suivez vos publications et réponses',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // ── CONTENT ──
          Expanded(
            child: StreamBuilder<List<RequestModel>>(
              stream: auth.getUserRequests(uid),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF0052D4)));
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Erreur:\n${snap.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
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
                            color: const Color(0xFF0052D4).withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.inbox_rounded, size: 64, color: Color(0xFF0052D4)),
                        ),
                        const SizedBox(height: 24),
                        const Text('Aucune demande',
                            style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        const Text('Vos demandes publiées apparaîtront ici',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, i) => Dismissible(
                    key: Key(list[i].id),
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
                          content: Text('Supprimer "${list[i].title}" ?\nCette action est irréversible.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Annuler', style: TextStyle(color: Colors.grey))),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ) ?? false;
                    },
                    onDismissed: (_) {
                      FirebaseFirestore.instance.collection('requests').doc(list[i].id).delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"${list[i].title}" supprimée', style: const TextStyle(fontWeight: FontWeight.bold)),
                          backgroundColor: const Color(0xFF1E293B),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    child: _RequestCard(r: list[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  final RequestModel r;
  const _RequestCard({required this.r});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _showLawyers = false;

  @override
  Widget build(BuildContext context) {
    final open = widget.r.status == 'open';
    final hasResponses = widget.r.respondedLawyerIds.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: open ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      widget.r.type,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    open ? Icons.check_circle_rounded : Icons.lock_rounded,
                    size: 16,
                    color: open ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    open ? 'Ouvert' : 'Fermé',
                    style: TextStyle(
                      color: open ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            
            // ── CONTENT ──
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.r.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.r.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── RÉPONSES BUTTON ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0052D4).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.people_alt_rounded, size: 14, color: Color(0xFF0052D4)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.r.respondedLawyerIds.length} réponse(s)',
                        style: const TextStyle(
                          color: Color(0xFF0052D4),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      if (hasResponses)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _showLawyers = !_showLawyers);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _showLawyers ? const Color(0xFF0052D4) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _showLawyers ? const Color(0xFF0052D4) : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _showLawyers ? 'Masquer' : 'Voir les avocats',
                                  style: TextStyle(
                                    color: _showLawyers ? Colors.white : const Color(0xFF334155),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  _showLawyers ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                  color: _showLawyers ? Colors.white : const Color(0xFF334155),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  // ── LISTE DES AVOCATS ──
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity, height: 0),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 12),
                        ...widget.r.respondedLawyerIds.map((lawyerId) =>
                          _LawyerResponseTile(
                            lawyerId: lawyerId,
                            requestId: widget.r.id,
                            userId: widget.r.userId,
                          ),
                        ),
                      ],
                    ),
                    crossFadeState: _showLawyers && hasResponses ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                    sizeCurve: Curves.easeOutCubic,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LawyerResponseTile extends StatefulWidget {
  final String lawyerId;
  final String requestId;
  final String userId;
  const _LawyerResponseTile({
    required this.lawyerId,
    required this.requestId,
    required this.userId,
  });

  @override
  State<_LawyerResponseTile> createState() => _LawyerResponseTileState();
}

class _LawyerResponseTileState extends State<_LawyerResponseTile> {
  LawyerModel? _lawyer;
  bool _loading = true;
  bool _openingChat = false;

  @override
  void initState() {
    super.initState();
    _loadLawyer();
  }

  Future<void> _loadLawyer() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('lawyers').doc(widget.lawyerId).get();
      if (doc.exists && mounted) {
        setState(() {
          _lawyer = LawyerModel.fromMap(doc.data()!);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openChat() async {
    if (_openingChat) return;
    HapticFeedback.mediumImpact();
    setState(() => _openingChat = true);
    try {
      final existing = await FirebaseFirestore.instance
          .collection('conversations')
          .where('userId', isEqualTo: widget.userId)
          .where('lawyerId', isEqualTo: widget.lawyerId)
          .limit(1)
          .get();

      String convId;
      if (existing.docs.isNotEmpty) {
        convId = existing.docs.first.id;
      } else {
        final doc = await FirebaseFirestore.instance.collection('conversations').add({
          'requestId': widget.requestId,
          'userId': widget.userId,
          'lawyerId': widget.lawyerId,
          'lawyerName': _lawyer?.name ?? '',
          'userName': '',
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessageAt': null,
          'lastMessageText': null,
        });
        convId = doc.id;
      }

      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatThreadScreen(conversationId: convId)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(minHeight: 2, color: Color(0xFFBFDBFE)),
      );
    }
    if (_lawyer == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          ProfileAvatar(
            imageBase64: _lawyer!.profileImageBase64,
            name: _lawyer!.name,
            size: 42,
            borderColor: Colors.white,
            borderWidth: 2,
            backgroundColor: const Color(0xFF0052D4),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lawyer!.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _lawyer!.speciality.split(',').first.trim(),
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
              ],
            ),
          ),
          _openingChat
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF0052D4)))
              : GestureDetector(
                  onTap: _openChat,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0052D4),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0052D4).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text('Contacter', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
