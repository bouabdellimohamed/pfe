import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
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

  static const _gold = Color(0xFFC9A84C);
  static const _goldLight = Color(0xFFE2C47A);

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ),
        title: Text('Publications & Consultations',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: _gold,
          unselectedLabelColor: Colors.white54,
          indicatorColor: _gold,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.inbox_outlined, size: 22), text: 'Publications'),
            Tab(icon: Icon(Icons.chat_bubble_outline, size: 22), text: 'Consultations'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: TabBarView(
            controller: _tabs,
            children: [
              _RequestsTab(uid: _uid, auth: _auth, specialities: _mySpecialities),
              _ConsultationsTab(uid: _uid, auth: _auth),
            ],
          ),
        ),
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

  static const _gold = Color(0xFFC9A84C);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RequestModel>>(
      stream: auth.getOpenRequests(lawyerSpecialities: specialities),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _gold));
        }
        if (snap.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Erreur:\n${snap.error}',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white70, height: 1.5)),
          ));
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.inbox_outlined, size: 56, color: Colors.white54),
            const SizedBox(height: 14),
            Text('Aucune publication disponible',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 15)),
          ]));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
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

  static const _gold = Color(0xFFC9A84C);
  static const _goldLight = Color(0xFFE2C47A);

  bool get _responded => widget.r.respondedLawyerIds.contains(widget.uid);

  @override
  Widget build(BuildContext context) {
    final r = widget.r;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
        ]
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(r.title,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold,
                      fontSize: 16, color: Colors.white))),
              Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white54),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _gold.withOpacity(0.3)),
                ),
                child: Text(r.type, style: GoogleFonts.poppins(color: _goldLight, fontSize: 11, fontWeight: FontWeight.w500)),
              ),
              const Spacer(),
              const Icon(Icons.person_outline_rounded, size: 14, color: Colors.white54),
              const SizedBox(width: 4),
              Text(r.userFullName,
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
            ]),
            const SizedBox(height: 12),
            Text(r.description,
                maxLines: _expanded ? null : 2,
                overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.5)),
            if (_expanded) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton.icon(
                  onPressed: _openingChat ? null : _openChat,
                  icon: Icon(
                    _openingChat ? Icons.hourglass_bottom_rounded
                        : _responded ? Icons.check_circle_rounded : Icons.reply_rounded,
                    size: 18),
                  label: Text(_openingChat ? 'Ouverture...'
                      : _responded ? 'Continuer le chat' : 'Répondre',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _responded ? const Color(0xFF4CAF50) : _gold,
                    foregroundColor: Colors.black87,
                    elevation: 4,
                    shadowColor: (_responded ? const Color(0xFF4CAF50) : _gold).withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.people_outline_rounded, size: 14, color: Colors.white54),
              const SizedBox(width: 4),
              Text('${r.respondedLawyerIds.length} réponse(s)',
                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
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

  static const _gold = Color(0xFFC9A84C);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConsultationModel>>(
      stream: auth.getAllConsultations(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _gold));
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.chat_bubble_outline, size: 56, color: Colors.white54),
            const SizedBox(height: 14),
            Text('Aucune consultation',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 15)),
          ]));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
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

  static const _gold = Color(0xFFC9A84C);
  static const _goldLight = Color(0xFFE2C47A);

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
            content: Text('Réponse envoyée !'), backgroundColor: Color(0xFF4CAF50)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.redAccent));
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
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
        ]
      ),
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 20, backgroundColor: _gold.withOpacity(0.15),
            child: Text(name[0].toUpperCase(),
                style: GoogleFonts.outfit(color: _gold, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white)),
            Text(c.type, style: GoogleFonts.poppins(color: _goldLight, fontSize: 12)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: answered ? const Color(0xFF4CAF50).withOpacity(0.15) : const Color(0xFFFF9800).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: answered ? const Color(0xFF4CAF50).withOpacity(0.3) : const Color(0xFFFF9800).withOpacity(0.3)),
            ),
            child: Text(answered ? 'Répondu' : 'En attente',
                style: GoogleFonts.poppins(
                  color: answered ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                  fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
          child: Text(c.question,
              style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.5)),
        ),
        if (answered && c.answer != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Votre réponse :',
                  style: GoogleFonts.poppins(color: const Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(c.answer!, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, height: 1.5)),
            ]),
          ),
        ],
        if (!answered) ...[
          const SizedBox(height: 16),
          if (_showReply) ...[
            TextField(
              controller: _answerCtrl, maxLines: 4,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Rédigez votre réponse juridique...',
                hintStyle: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
                filled: true, fillColor: Colors.black.withOpacity(0.2),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _gold)),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => setState(() => _showReply = false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Annuler', style: GoogleFonts.poppins()),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: _loading ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold, foregroundColor: Colors.black87,
                  elevation: 4,
                  shadowColor: _gold.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _loading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.black87)))
                    : Text('Envoyer', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              )),
            ]),
          ] else SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _showReply = true),
              icon: const Icon(Icons.reply_rounded, size: 18),
              label: Text('Répondre', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold, foregroundColor: Colors.black87,
                elevation: 4,
                shadowColor: _gold.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}
