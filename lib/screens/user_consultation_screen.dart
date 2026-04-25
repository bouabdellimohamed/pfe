import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/consultation_model.dart';

class UserConsultationScreen extends StatefulWidget {
  final String uid;
  const UserConsultationScreen({super.key, required this.uid});
  @override
  State<UserConsultationScreen> createState() => _UserConsultationScreenState();
}

class _UserConsultationScreenState extends State<UserConsultationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultations'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(icon: Icon(Icons.add_comment_outlined), text: 'Nouvelle'),
            Tab(icon: Icon(Icons.history_rounded), text: 'Historique'),
            Tab(icon: Icon(Icons.people_outlined), text: 'Partages'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _NewConsultationForm(uid: widget.uid, auth: _auth),
          _ConsultationHistory(uid: widget.uid, auth: _auth),
          _SharedConsultations(uid: widget.uid, auth: _auth),
        ],
      ),
    );
  }
}

// ── FORMULAIRE NOUVELLE CONSULTATION ─────────────────────────────
class _NewConsultationForm extends StatefulWidget {
  final String uid;
  final AuthService auth;
  const _NewConsultationForm({required this.uid, required this.auth});
  @override
  State<_NewConsultationForm> createState() => _NewConsultationFormState();
}

class _NewConsultationFormState extends State<_NewConsultationForm> {
  final _questionCtrl = TextEditingController();
  String? _type;
  bool _loading = false;

  static const _types = [
    ('Droit familial', Icons.family_restroom_rounded, Color(0xFFE91E63)),
    ('Droit pénal', Icons.gavel_rounded, Color(0xFF9C27B0)),
    ('Droit commercial', Icons.business_center_rounded, Color(0xFF2196F3)),
    ('Droit du travail', Icons.work_rounded, Color(0xFF009688)),
    ('Droit immobilier', Icons.home_work_rounded, Color(0xFFFF9800)),
    ('Droit civil', Icons.balance_rounded, Color(0xFF607D8B)),
  ];

  @override
  void dispose() {
    _questionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_type == null || _questionCtrl.text.trim().length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Choisissez un type et écrivez au moins 20 caractères'),
          backgroundColor: Colors.orange));
      return;
    }
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final profile = await widget.auth.getUserProfile(widget.uid);
      await widget.auth.createConsultation(
        userId: widget.uid,
        userFullName: profile?.fullName ?? user?.displayName ?? 'Utilisateur',
        type: _type!,
        question: _questionCtrl.text.trim(),
      );
      if (!mounted) return;
      _questionCtrl.clear();
      setState(() => _type = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Consultation envoyée ! Un avocat vous répondra bientôt.'),
          backgroundColor: Color(0xFF2E7D32)));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            const Icon(Icons.chat_bubble_outline_rounded,
                color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Consultation juridique',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                Text('Posez votre question à nos avocats',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ],
            )),
          ]),
        ),
        const SizedBox(height: 22),
        const Text('Type de consultation *',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF263238))),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.2,
          children: _types.map((t) {
            final sel = _type == t.$1;
            return GestureDetector(
              onTap: () => setState(() => _type = t.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: sel ? t.$3 : t.$3.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: sel ? t.$3 : t.$3.withOpacity(0.3),
                      width: sel ? 2 : 1),
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(t.$2, color: sel ? Colors.white : t.$3, size: 24),
                      const SizedBox(height: 5),
                      Text(t.$1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: sel ? Colors.white : t.$3,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ]),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text('Votre question *',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF263238))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: _questionCtrl,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Décrivez votre situation juridique en détail...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(_loading ? 'Envoi...' : 'Envoyer la consultation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── HISTORIQUE CONSULTATIONS ──────────────────────────────────────
class _ConsultationHistory extends StatelessWidget {
  final String uid;
  final AuthService auth;
  const _ConsultationHistory({required this.uid, required this.auth});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConsultationModel>>(
      stream: auth.getUserConsultations(uid),
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
          return const Center(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 60, color: Colors.grey),
              SizedBox(height: 14),
              Text('Aucune consultation pour l\'instant',
                  style: TextStyle(color: Colors.grey, fontSize: 15)),
            ],
          ));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _ConsultCard(c: list[i]),
        );
      },
    );
  }
}

class _ConsultCard extends StatelessWidget {
  final ConsultationModel c;
  const _ConsultCard({required this.c});

  @override
  Widget build(BuildContext context) {
    final answered = c.status == 'answered';
    final lawyerName = (c.lawyerName != null && c.lawyerName!.trim().isNotEmpty)
        ? c.lawyerName!
        : 'Avocat';
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(c.type,
                  style: const TextStyle(
                      color: Color(0xFF1565C0),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: answered
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  answered ? Icons.check_circle_outline : Icons.hourglass_empty,
                  size: 11,
                  color: answered ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(answered ? 'Répondu' : 'En attente',
                    style: TextStyle(
                        color: answered ? Colors.green : Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Question :',
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(c.question,
                  style: const TextStyle(
                      color: Color(0xFF263238), fontSize: 13, height: 1.4)),
            ]),
          ),
          if (answered && c.answer != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.gavel_rounded,
                          size: 13, color: Colors.green),
                      const SizedBox(width: 5),
                      Text(lawyerName,
                          style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 5),
                    Text(c.answer!,
                        style: const TextStyle(
                            color: Color(0xFF263238),
                            fontSize: 13,
                            height: 1.4)),
                  ]),
            ),
          ],
        ]),
      ),
    );
  }
}

// ── الاستشارات المشتركة (من المستخدمين الآخرين) ──────────────
class _SharedConsultations extends StatefulWidget {
  final String uid;
  final AuthService auth;
  const _SharedConsultations({required this.uid, required this.auth});
  @override
  State<_SharedConsultations> createState() => _SharedConsultationsState();
}

class _SharedConsultationsState extends State<_SharedConsultations> {
  late Future<String> _userRoleFuture;

  @override
  void initState() {
    super.initState();
    _userRoleFuture = widget.auth.getUserRole(widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _userRoleFuture,
      builder: (ctx, roleSnap) {
        if (roleSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final userRole = roleSnap.data ?? 'user';
        return StreamBuilder<List<ConsultationModel>>(
          stream: widget.auth.getOtherUsersConsultations(widget.uid),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Erreur:\n${snap.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final list = snap.data ?? [];
            if (list.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 60, color: Colors.grey),
                    SizedBox(height: 14),
                    Text('Aucune consultation partagée pour l\'instant',
                        style: TextStyle(color: Colors.grey, fontSize: 15)),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _SharedConsultCard(
                consultation: list[i],
                userRole: userRole,
                auth: widget.auth,
                currentUserId: widget.uid,
              ),
            );
          },
        );
      },
    );
  }
}

class _SharedConsultCard extends StatefulWidget {
  final ConsultationModel consultation;
  final String userRole;
  final AuthService auth;
  final String currentUserId;

  const _SharedConsultCard({
    required this.consultation,
    required this.userRole,
    required this.auth,
    required this.currentUserId,
  });

  @override
  State<_SharedConsultCard> createState() => _SharedConsultCardState();
}

class _SharedConsultCardState extends State<_SharedConsultCard> {
  bool _isAnswering = false;
  final _answerCtrl = TextEditingController();

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer() async {
    if (_answerCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez écrire votre réponse'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isAnswering = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final profile = await widget.auth.getUserProfile(widget.currentUserId);

      await widget.auth.answerConsultation(
        consultationId: widget.consultation.id,
        lawyerId: widget.currentUserId,
        lawyerName: profile?.fullName ?? user?.displayName ?? 'Avocat',
        answer: _answerCtrl.text.trim(),
      );

      if (!mounted) return;
      _answerCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Réponse envoyée avec succès!'),
        backgroundColor: Color(0xFF2E7D32),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _isAnswering = false);
  }

  @override
  Widget build(BuildContext context) {
    final isLawyer = widget.userRole == 'lawyer';
    final answered = widget.consultation.status == 'answered';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── رأس البطاقة ──
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.consultation.type,
                    style: const TextStyle(
                      color: Color(0xFF1565C0),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: answered
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        answered
                            ? Icons.check_circle_outline
                            : Icons.hourglass_empty,
                        size: 11,
                        color: answered ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        answered ? 'Répondu' : 'En attente',
                        style: TextStyle(
                          color: answered ? Colors.green : Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // ── اسم المستخدم ──
            Row(
              children: [
                const Icon(Icons.person_outline, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  widget.consultation.userFullName,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ── السؤال ──
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Question:',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.consultation.question,
                    style: const TextStyle(
                      color: Color(0xFF263238),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            // ── الرد إن وجد ──
            if (answered && widget.consultation.answer != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.gavel_rounded,
                            size: 13, color: Colors.green),
                        const SizedBox(width: 5),
                        Text(
                          widget.consultation.lawyerName ?? 'Avocat',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.consultation.answer!,
                      style: const TextStyle(
                        color: Color(0xFF263238),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // ── زر الرد (فقط للمحامين والاستشارة بدون رد) ──
            if (!answered && isLawyer) ...[
              const SizedBox(height: 12),
              if (!_isAnswering)
                ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      builder: (_) => Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                          top: 20,
                          left: 16,
                          right: 16,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Votre réponse',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: TextField(
                                controller: _answerCtrl,
                                maxLines: 5,
                                decoration: InputDecoration(
                                  hintText:
                                      'Écrivez votre réponse juridique...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () {
                                      _answerCtrl.clear();
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Annuler'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _submitAnswer();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1565C0),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Envoyer'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.reply_rounded, size: 16),
                  label: const Text('Répondre'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                  ),
                ),
              // ── رسالة للمستخدمين العاديين ──
              if (!isLawyer)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Seuls les avocats peuvent répondre aux consultations',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
