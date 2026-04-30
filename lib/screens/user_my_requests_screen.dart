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
      appBar: AppBar(
        title: const Text('Mes demandes'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<RequestModel>>(
        stream: auth.getUserRequests(uid),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Erreur lors du chargement de l’historique:\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined, size: 60, color: Colors.grey),
                SizedBox(height: 14),
                Text('Aucune demande publiée',
                    style: TextStyle(color: Colors.grey, fontSize: 15)),
              ],
            ));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => Dismissible(
              key: Key(list[i].id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                    SizedBox(height: 4),
                    Text('Supprimer', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              confirmDismiss: (_) async {
                HapticFeedback.mediumImpact();
                return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Supprimer la demande'),
                    content: Text('Supprimer "${list[i].title}" ?\nCette action est irréversible.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ) ?? false;
              },
              onDismissed: (_) {
                FirebaseFirestore.instance.collection('publications').doc(list[i].id).delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"${list[i].title}" supprimée')),
                );
              },
              child: _RequestCard(r: list[i]),
            ),
          );
        },
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
  static const _primary = Color(0xFF1565C0);
  bool _showLawyers = false;

  @override
  Widget build(BuildContext context) {
    final open = widget.r.status == 'open';
    final hasResponses = widget.r.respondedLawyerIds.isNotEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── العنوان والحالة ──
          Row(children: [
            Expanded(child: Text(widget.r.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14,
                    color: Color(0xFF263238)))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: open
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(open ? 'Ouvert' : 'Fermé',
                  style: TextStyle(
                      color: open ? Colors.green : Colors.grey,
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(widget.r.type,
              style: const TextStyle(color: _primary, fontSize: 12)),
          const SizedBox(height: 6),
          Text(widget.r.description,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 12, height: 1.4)),
          const SizedBox(height: 10),

          // ── زر عرض المحامين الذين ردّوا ──
          Row(children: [
            const Icon(Icons.people_outline_rounded, size: 13, color: Colors.grey),
            const SizedBox(width: 4),
            Text('${widget.r.respondedLawyerIds.length} réponse(s)',
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
            const Spacer(),
            if (hasResponses)
              GestureDetector(
                onTap: () => setState(() => _showLawyers = !_showLawyers),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _primary.withOpacity(0.2)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(_showLawyers ? 'Masquer' : 'Voir avocats',
                        style: const TextStyle(
                            color: _primary, fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Icon(_showLawyers ? Icons.expand_less : Icons.expand_more,
                        color: _primary, size: 14),
                  ]),
                ),
              ),
          ]),

          // ── قائمة المحامين الذين ردّوا ──
          if (_showLawyers && hasResponses) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...widget.r.respondedLawyerIds.map((lawyerId) =>
              _LawyerResponseTile(
                lawyerId: lawyerId,
                requestId: widget.r.id,
                userId: widget.r.userId,
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

// ── بطاقة محامي ردّ على الطلب ──────────────────────────────────
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
  static const _primary = Color(0xFF1565C0);
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
      final doc = await FirebaseFirestore.instance
          .collection('lawyers').doc(widget.lawyerId).get();
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
    setState(() => _openingChat = true);
    try {
      // ✅ نتحقق أولاً إذا كان هناك محادثة موجودة
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
        final doc = await FirebaseFirestore.instance
            .collection('conversations').add({
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
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => ChatThreadScreen(conversationId: convId)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    if (_lawyer == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        // صورة المحامي
        ProfileAvatar(
          imageBase64: _lawyer!.profileImageBase64,
          name: _lawyer!.name,
          size: 38,
          borderColor: Colors.grey.shade200,
          borderWidth: 1,
          backgroundColor: const Color(0xFF1565C0),
        ),
        const SizedBox(width: 10),
        // اسم المحامي والتخصص
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_lawyer!.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13,
                    color: Color(0xFF263238))),
            Text(_lawyer!.speciality.split(',').first.trim(),
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        )),
        // زر المراسلة
        _openingChat
            ? const SizedBox(width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: _primary))
            : GestureDetector(
                onTap: _openChat,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        color: Colors.white, size: 13),
                    SizedBox(width: 5),
                    Text('Contacter',
                        style: TextStyle(color: Colors.white,
                            fontSize: 11, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
      ]),
    );
  }
}
