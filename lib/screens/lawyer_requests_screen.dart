import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/consultation_model.dart';
import 'chat_thread_screen.dart';

class LawyerRequestsScreen extends StatefulWidget {
  const LawyerRequestsScreen({super.key});
  @override
  State<LawyerRequestsScreen> createState() => _LawyerRequestsScreenState();
}

class _LawyerRequestsScreenState extends State<LawyerRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _auth = AuthService();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  List<String> _mySpecialities = []; // ✅ تخصصات المحامي الحالي

  static const _navy = Color(0xFF0D1B2A);
  static const _navyLight = Color(0xFF1B2D42);
  static const _gold = Color(0xFFC9A84C);
  static const _textPrimary = Color(0xFFF0EDE8);
  static const _textSecondary = Color(0xFF8A9BB0);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadMySpecialities();
  }

  Future<void> _loadMySpecialities() async {
    // ✅ جلب تخصصات المحامي من Firestore
    final profile = await _auth.getLawyerProfile(_uid);
    if (profile != null && mounted) {
      setState(() {
        _mySpecialities = profile.speciality
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navyLight,
        automaticallyImplyLeading: false,
        title: const Text('Publications & Consultations',
            style: TextStyle(color: _textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: _gold,
          unselectedLabelColor: _textSecondary,
          indicatorColor: _gold,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(icon: Icon(Icons.inbox_outlined, size: 20), text: 'Publications'),
            Tab(icon: Icon(Icons.chat_bubble_outline, size: 20), text: 'Consultations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _RequestsTab(uid: _uid, auth: _auth, specialities: _mySpecialities),
          _ConsultationsTab(uid: _uid, auth: _auth),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ONGLET 1 : Publications (Requests)
// ═══════════════════════════════════════════════════════════════
class _RequestsTab extends StatelessWidget {
  final String uid;
  final AuthService auth;
  final List<String> specialities;
  const _RequestsTab({required this.uid, required this.auth, required this.specialities});

  static const _navy = Color(0xFF0D1B2A);
  static const _textSecondary = Color(0xFF8A9BB0);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RequestModel>>(
      stream: auth.getOpenRequests(lawyerSpecialities: specialities),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFC9A84C)));
        }
        if (snap.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Erreur:\n${snap.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _textSecondary, height: 1.5)),
          ));
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.inbox_outlined, size: 56, color: Color(0xFF8A9BB0)),
            SizedBox(height: 14),
            Text('Aucune publication disponible',
                style: TextStyle(color: Color(0xFF8A9BB0), fontSize: 15,
                    decoration: TextDecoration.none)),
          ]));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _RequestCard(r: list[i], uid: uid, auth: auth),
        );
      },
    );
  }
}

class _RequestCard extends StatefulWidget {
  final RequestModel r;
  final String uid;
  final AuthService auth;
  const _RequestCard({required this.r, required this.uid, required this.auth});
  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _expanded = false;
  bool _openingChat = false;

  static const _navyCard = Color(0xFF162233);
  static const _gold = Color(0xFFC9A84C);
  static const _textPrimary = Color(0xFFF0EDE8);
  static const _textSecondary = Color(0xFF8A9BB0);

  bool get _responded => widget.r.respondedLawyerIds.contains(widget.uid);

  @override
  Widget build(BuildContext context) {
    final r = widget.r;
    return Container(
      decoration: BoxDecoration(
        color: _navyCard, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(r.title,
                  style: const TextStyle(fontWeight: FontWeight.w700,
                      fontSize: 14, color: _textPrimary))),
              Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: _textSecondary),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(r.type, style: const TextStyle(color: _gold, fontSize: 11)),
              ),
              const Spacer(),
              const Icon(Icons.person_outline_rounded, size: 12, color: Color(0xFF8A9BB0)),
              const SizedBox(width: 4),
              Text(r.userFullName,
                  style: const TextStyle(color: Color(0xFF8A9BB0), fontSize: 11)),
            ]),
            const SizedBox(height: 8),
            Text(r.description,
                maxLines: _expanded ? null : 2,
                overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: TextStyle(color: _textSecondary.withOpacity(0.85), fontSize: 12, height: 1.4)),
            if (_expanded) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 44,
                child: ElevatedButton.icon(
                  onPressed: _openingChat ? null : _openChat,
                  icon: Icon(
                    _openingChat ? Icons.hourglass_bottom_rounded
                        : _responded ? Icons.check_circle_rounded : Icons.reply_rounded,
                    size: 16),
                  label: Text(_openingChat ? 'Ouverture...'
                      : _responded ? 'Continuer le chat' : 'Répondre'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _responded ? const Color(0xFF2E7D32) : _gold,
                    foregroundColor: const Color(0xFF0D1B2A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.people_outline_rounded, size: 11, color: Color(0xFF8A9BB0)),
              const SizedBox(width: 4),
              Text('${r.respondedLawyerIds.length} réponse(s)',
                  style: const TextStyle(color: Color(0xFF8A9BB0), fontSize: 11)),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _openChat() async {
    setState(() => _openingChat = true);
    try {
      await widget.auth.respondToRequest(widget.r.id, widget.uid);
      final convId = await widget.auth.getOrCreateConversationIdForRequest(
        requestId: widget.r.id,
        userId: widget.r.userId,
        lawyerId: widget.uid,
      );
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => ChatThreadScreen(conversationId: convId)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// ONGLET 2 : Consultations
// ═══════════════════════════════════════════════════════════════
class _ConsultationsTab extends StatelessWidget {
  final String uid;
  final AuthService auth;
  const _ConsultationsTab({required this.uid, required this.auth});

  static const _textSecondary = Color(0xFF8A9BB0);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConsultationModel>>(
      stream: auth.getAllConsultations(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFC9A84C)));
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.chat_bubble_outline, size: 56, color: Color(0xFF8A9BB0)),
            SizedBox(height: 14),
            Text('Aucune consultation',
                style: TextStyle(color: Color(0xFF8A9BB0), fontSize: 15,
                    decoration: TextDecoration.none)),
          ]));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _ConsultCard(c: list[i], lawyerId: uid, auth: auth),
        );
      },
    );
  }
}

class _ConsultCard extends StatefulWidget {
  final ConsultationModel c;
  final String lawyerId;
  final AuthService auth;
  const _ConsultCard({required this.c, required this.lawyerId, required this.auth});
  @override
  State<_ConsultCard> createState() => _ConsultCardState();
}

class _ConsultCardState extends State<_ConsultCard> {
  bool _showReply = false;
  final _answerCtrl = TextEditingController();
  bool _loading = false;

  static const _navyCard = Color(0xFF162233);
  static const _navyLight = Color(0xFF1B2D42);
  static const _navy = Color(0xFF0D1B2A);
  static const _gold = Color(0xFFC9A84C);
  static const _textPrimary = Color(0xFFF0EDE8);
  static const _textSecondary = Color(0xFF8A9BB0);

  @override
  void dispose() { _answerCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (_answerCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final profile = await widget.auth.getLawyerProfile(widget.lawyerId);
      await widget.auth.answerConsultation(
        consultationId: widget.c.id,
        lawyerId: widget.lawyerId,
        lawyerName: profile?.name ?? 'Maître',
        answer: _answerCtrl.text.trim(),
      );
      if (mounted) {
        setState(() => _showReply = false);
        _answerCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Réponse envoyée !'), backgroundColor: Color(0xFF2E7D32)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final answered = c.status == 'answered';
    final name = c.userFullName.trim().isNotEmpty ? c.userFullName : 'Utilisateur';

    return Container(
      decoration: BoxDecoration(
        color: _navyCard, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 18, backgroundColor: _gold.withOpacity(0.12),
            child: Text(name[0].toUpperCase(),
                style: const TextStyle(color: _gold, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14, color: _textPrimary)),
            Text(c.type, style: const TextStyle(color: _gold, fontSize: 11)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: answered ? const Color(0x1A4CAF50) : const Color(0x1AFF9800),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(answered ? 'Répondu' : 'En attente',
                style: TextStyle(
                  color: answered ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                  fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(8)),
          child: Text(c.question,
              style: TextStyle(color: _textSecondary, fontSize: 13, height: 1.4)),
        ),
        if (answered && c.answer != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0x1A4CAF50), borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x334CAF50)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Votre réponse :',
                  style: TextStyle(color: Color(0xFF4CAF50), fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(c.answer!, style: const TextStyle(color: _textPrimary, fontSize: 13, height: 1.4)),
            ]),
          ),
        ],
        if (!answered) ...[
          const SizedBox(height: 10),
          if (_showReply) ...[
            TextField(
              controller: _answerCtrl, maxLines: 4,
              style: const TextStyle(color: _textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Rédigez votre réponse juridique...',
                hintStyle: TextStyle(color: _textSecondary.withOpacity(0.5), fontSize: 13),
                filled: true, fillColor: _navyLight,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _gold)),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => setState(() => _showReply = false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textSecondary,
                  side: BorderSide(color: _textSecondary.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Annuler'),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(
                onPressed: _loading ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold, foregroundColor: const Color(0xFF0D1B2A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _loading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Color(0xFF0D1B2A))))
                    : const Text('Envoyer', style: TextStyle(fontWeight: FontWeight.w700)),
              )),
            ]),
          ] else SizedBox(
            width: double.infinity, height: 44,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _showReply = true),
              icon: const Icon(Icons.reply_rounded, size: 16),
              label: const Text('Répondre'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold, foregroundColor: const Color(0xFF0D1B2A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}
