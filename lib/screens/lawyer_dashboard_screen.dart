import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/lawyer_model.dart';
import 'lawyer_edit_profile_screen.dart';

class LawyerDashboardScreen extends StatefulWidget {
  const LawyerDashboardScreen({super.key});
  @override
  State<LawyerDashboardScreen> createState() => _LawyerDashboardScreenState();
}

class _LawyerDashboardScreenState extends State<LawyerDashboardScreen> {
  final _auth = AuthService();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  LawyerModel? _lawyer;
  bool _loading = true;

  // إحصاءات حقيقية
  int _openRequests = 0;
  int _myConsultations = 0;
  int _myConversations = 0;

  static const _navy = Color(0xFF0D1B2A);
  static const _navyLight = Color(0xFF1B2D42);
  static const _navyCard = Color(0xFF162233);
  static const _gold = Color(0xFFC9A84C);
  static const _goldLight = Color(0xFFE2C47A);
  static const _textPrimary = Color(0xFFF0EDE8);
  static const _textSecondary = Color(0xFF8A9BB0);

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (_uid.isEmpty) return;
    setState(() => _loading = true);

    final results = await Future.wait([
      _auth.getLawyerProfile(_uid),
      _loadStats(),
    ]);

    if (mounted) setState(() {
      _lawyer = results[0] as LawyerModel?;
      _loading = false;
    });
  }

  Future<void> _loadStats() async {
    try {
      final openSnap = await FirebaseFirestore.instance
          .collection('requests').where('status', isEqualTo: 'open').get();
      final consult = await FirebaseFirestore.instance
          .collection('consultations').where('lawyerId', isEqualTo: _uid).get();
      final convs = await FirebaseFirestore.instance
          .collection('conversations').where('lawyerId', isEqualTo: _uid).get();

      // ✅ فلترة الطلبات بتخصصات المحامي فقط
      int relevantRequests = openSnap.docs.length;
      if (_lawyer != null && _lawyer!.speciality.isNotEmpty) {
        final mySpecs = _lawyer!.speciality
            .split(',').map((s) => s.trim().toLowerCase()).toList();
        relevantRequests = openSnap.docs.where((doc) {
          final type = (doc.data()['type'] ?? '').toString().toLowerCase().trim();
          return mySpecs.any((spec) => spec == type || type.contains(spec) || spec.contains(type));
        }).length;
      }

      if (mounted) setState(() {
        _openRequests = relevantRequests;
        _myConsultations = consult.docs.length;
        _myConversations = convs.docs.length;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _gold, strokeWidth: 2.5))
          : RefreshIndicator(
              onRefresh: _loadAll, color: _gold, backgroundColor: _navyLight,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    sliver: SliverList(delegate: SliverChildListDelegate([
                      const SizedBox(height: 20),
                      _buildProfileCard(),
                      const SizedBox(height: 28),
                      _buildSectionLabel('Vue d\'ensemble'),
                      const SizedBox(height: 14),
                      _buildStatsGrid(),
                      if (_lawyer?.bio != null && _lawyer!.bio!.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        _buildSectionLabel('À propos'),
                        const SizedBox(height: 14),
                        _buildBioCard(),
                      ],
                      const SizedBox(height: 28),
                    ])),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAppBar() => SliverAppBar(
    backgroundColor: _navyLight,
    floating: true, pinned: true, expandedHeight: 0, elevation: 0,
    automaticallyImplyLeading: false,
    title: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle, color: const Color(0x1AC9A84C),
          border: Border.all(color: const Color(0x33C9A84C)),
        ),
        child: const Icon(Icons.balance_rounded, color: _gold, size: 16),
      ),
      const SizedBox(width: 10),
      const Text('Espace Avocat', style: TextStyle(
          color: _textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
    ]),
    actions: [
      IconButton(
        icon: const Icon(Icons.logout_rounded, color: _textSecondary, size: 22),
        tooltip: 'Déconnexion',
        onPressed: _confirmSignOut,
      ),
      const SizedBox(width: 4),
    ],
  );

  Widget _buildProfileCard() {
    final initials = _lawyer?.name.trim().isNotEmpty == true
        ? _lawyer!.name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'A';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _navyCard, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x26C9A84C)),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Column(children: [
        // Avatar
        Stack(alignment: Alignment.bottomRight, children: [
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: const Color(0x1AC9A84C),
              border: Border.all(color: _gold, width: 2),
              boxShadow: const [BoxShadow(color: Color(0x28C9A84C), blurRadius: 18, spreadRadius: 4)],
            ),
            child: Center(child: Text(initials,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _gold))),
          ),
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32), shape: BoxShape.circle,
              border: Border.all(color: _navyCard, width: 2),
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 12),
          ),
        ]),
        const SizedBox(height: 16),
        Text(_lawyer?.name ?? 'Avocat', style: const TextStyle(
            color: _textPrimary, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        const SizedBox(height: 8),
        if (_lawyer?.speciality != null)
          Wrap(
            spacing: 6, runSpacing: 6, alignment: WrapAlignment.center,
            children: _lawyer!.speciality.split(', ').map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x1AC9A84C), borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x33C9A84C)),
              ),
              child: Text(s, style: const TextStyle(color: _goldLight, fontSize: 12)),
            )).toList(),
          ),
        const SizedBox(height: 20),
        const Divider(color: Color(0x1AF0EDE8)),
        const SizedBox(height: 14),
        _infoRow(Icons.mail_outline_rounded, _lawyer?.email ?? ''),
        if (_lawyer?.phone != null) _infoRow(Icons.phone_outlined, _lawyer!.phone!),
        if (_lawyer?.wilaya != null)
          _infoRow(Icons.location_on_outlined,
              [_lawyer!.wilaya, _lawyer!.daira, _lawyer!.commune]
                  .where((s) => s != null && s!.isNotEmpty)
                  .join(', ')),
        if (_lawyer?.experience != null)
          _infoRow(Icons.work_outline_rounded, "${_lawyer!.experience} ans d'expérience"),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              if (_lawyer == null) return;
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => LawyerEditProfileScreen(lawyer: _lawyer),
              )).then((v) { if (v == true) _loadAll(); });
            },
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Modifier le profil'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _gold,
              side: const BorderSide(color: Color(0x66C9A84C)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Icon(icon, size: 16, color: _textSecondary),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(color: _textSecondary, fontSize: 13),
          overflow: TextOverflow.ellipsis)),
    ]),
  );

  Widget _buildSectionLabel(String t) => Row(children: [
    Container(width: 3, height: 18,
        decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(4))),
    const SizedBox(width: 10),
    Text(t.toUpperCase(), style: const TextStyle(
        color: _textPrimary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
  ]);

  Widget _buildStatsGrid() {
    final stats = [
      _Stat('Demandes ouvertes', '$_openRequests',
          Icons.inbox_outlined, const Color(0xFF4CAF50), const Color(0x1A4CAF50)),
      _Stat('Consultations', '$_myConsultations',
          Icons.chat_bubble_outline_rounded, const Color(0xFF42A5F5), const Color(0x1A42A5F5)),
      _Stat('Conversations', '$_myConversations',
          Icons.forum_outlined, const Color(0xFFFF9800), const Color(0x1AFF9800)),
      _Stat('Note', '${(_lawyer?.rating ?? 0.0).toStringAsFixed(1)}★',
          Icons.star_outline_rounded, _gold, const Color(0x1AC9A84C)),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.55),
      itemCount: stats.length,
      itemBuilder: (_, i) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _navyCard, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x14FFFFFF)),
        ),
        child: Row(children: [
          Container(width: 44, height: 44,
              decoration: BoxDecoration(color: stats[i].bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(stats[i].icon, color: stats[i].color, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(stats[i].value, style: const TextStyle(
                color: _textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            Text(stats[i].label, style: const TextStyle(color: _textSecondary, fontSize: 11),
                overflow: TextOverflow.ellipsis),
          ])),
        ]),
      ),
    );
  }

  Widget _buildBioCard() => Container(
    width: double.infinity, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _navyCard, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0x14FFFFFF)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.format_quote_rounded, color: _gold, size: 26),
      const SizedBox(height: 8),
      Text(_lawyer!.bio!, style: const TextStyle(
          color: _textSecondary, fontSize: 14, fontStyle: FontStyle.italic, height: 1.6)),
    ]),
  );

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _navyLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion',
            style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w700)),
        content: const Text('Voulez-vous vraiment vous déconnecter ?',
            style: TextStyle(color: _textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: _textSecondary))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _auth.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Déconnecter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _Stat {
  final String label, value;
  final IconData icon;
  final Color color, bg;
  const _Stat(this.label, this.value, this.icon, this.color, this.bg);
}
