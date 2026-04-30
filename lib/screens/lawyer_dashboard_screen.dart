import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../models/lawyer_model.dart';
import '../widgets/profile_avatar.dart';
import 'lawyer_edit_profile_screen.dart';

class LawyerDashboardScreen extends StatefulWidget {
  const LawyerDashboardScreen({super.key});
  @override
  State<LawyerDashboardScreen> createState() => _LawyerDashboardScreenState();
}

class _LawyerDashboardScreenState extends State<LawyerDashboardScreen> with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  LawyerModel? _lawyer;
  bool _loading = true;

  int _openRequests = 0;
  int _myConsultations = 0;
  int _myConversations = 0;

  static const _gold = Color(0xFFC9A84C);
  static const _goldLight = Color(0xFFE2C47A);

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _loadAll();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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
    _animController.forward(from: 0);
  }

  Future<void> _loadStats() async {
    try {
      final openSnap = await FirebaseFirestore.instance
          .collection('requests').where('status', isEqualTo: 'open').get();
      final consult = await FirebaseFirestore.instance
          .collection('consultations').where('lawyerId', isEqualTo: _uid).get();
      final convs = await FirebaseFirestore.instance
          .collection('conversations').where('lawyerId', isEqualTo: _uid).get();

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _gold, strokeWidth: 2.5))
            : RefreshIndicator(
                onRefresh: _loadAll, color: _gold, backgroundColor: const Color(0xFF1B2D42),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      _buildAppBar(),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        sliver: SliverList(delegate: SliverChildListDelegate([
                          const SizedBox(height: 20),
                          _buildProfileCard(),
                          const SizedBox(height: 32),
                          _buildSectionLabel('Tableau de Bord'),
                          const SizedBox(height: 16),
                          _buildStatsGrid(),
                          if (_lawyer?.bio != null && _lawyer!.bio!.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            _buildSectionLabel('À propos de vous'),
                            const SizedBox(height: 16),
                            _buildBioCard(),
                          ],
                          const SizedBox(height: 40),
                        ])),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAppBar() => SliverAppBar(
    backgroundColor: Colors.transparent,
    floating: true, pinned: true, expandedHeight: 0, elevation: 0,
    automaticallyImplyLeading: false,
    flexibleSpace: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(color: Colors.black.withOpacity(0.2)),
      ),
    ),
    title: Row(children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle, 
          gradient: const LinearGradient(
            colors: [_goldLight, _gold],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: _gold.withOpacity(0.4), blurRadius: 8, spreadRadius: 1),
          ],
        ),
        child: const Icon(Icons.balance_rounded, color: Colors.white, size: 20),
      ),
      const SizedBox(width: 12),
      Text('Espace Avocat', style: GoogleFonts.outfit(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
    ]),
    actions: [
      Container(
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
          tooltip: 'Déconnexion',
          onPressed: _confirmSignOut,
        ),
      ),
    ],
  );

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, spreadRadius: -5),
        ],
      ),
      child: Column(children: [
        ProfileAvatar(
          imageBase64: _lawyer?.profileImageBase64,
          name: _lawyer?.name,
          size: 100,
          borderColor: _gold,
          borderWidth: 2.5,
          backgroundColor: const Color(0xFF1B2D42),
          badge: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50), shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF203A43), width: 3),
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 14),
          ),
        ),
        const SizedBox(height: 18),
        Text(_lawyer?.name ?? 'Avocat', style: GoogleFonts.outfit(
            color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        if (_lawyer?.speciality != null)
          Wrap(
            spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
            children: _lawyer!.speciality.split(', ').map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _gold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _gold.withOpacity(0.3)),
              ),
              child: Text(s, style: GoogleFonts.poppins(color: _goldLight, fontSize: 12, fontWeight: FontWeight.w500)),
            )).toList(),
          ),
        const SizedBox(height: 24),
        Container(height: 1, color: Colors.white.withOpacity(0.1)),
        const SizedBox(height: 20),
        _infoRow(Icons.mail_outline_rounded, _lawyer?.email ?? ''),
        if (_lawyer?.phone != null) _infoRow(Icons.phone_outlined, _lawyer!.phone!),
        if (_lawyer?.wilaya != null)
          _infoRow(Icons.location_on_outlined,
              [_lawyer!.wilaya, _lawyer!.daira, _lawyer!.commune]
                  .where((s) => s != null && s.isNotEmpty)
                  .join(', ')),
        if (_lawyer?.experience != null)
          _infoRow(Icons.work_outline_rounded, "${_lawyer!.experience} ans d'expérience"),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              if (_lawyer == null) return;
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => LawyerEditProfileScreen(lawyer: _lawyer),
              )).then((v) { if (v == true) _loadAll(); });
            },
            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.black87),
            label: Text('Modifier le profil', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black87)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              elevation: 8,
              shadowColor: _gold.withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: _goldLight),
      ),
      const SizedBox(width: 14),
      Expanded(child: Text(text, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          overflow: TextOverflow.ellipsis)),
    ]),
  );

  Widget _buildSectionLabel(String t) => Row(children: [
    Container(width: 4, height: 20,
        decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(4))),
    const SizedBox(width: 12),
    Text(t.toUpperCase(), style: GoogleFonts.outfit(
        color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
  ]);

  Widget _buildStatsGrid() {
    final stats = [
      _Stat('Demandes', '$_openRequests',
          Icons.inbox_outlined, const Color(0xFF4CAF50)),
      _Stat('Consultations', '$_myConsultations',
          Icons.chat_bubble_outline_rounded, const Color(0xFF42A5F5)),
      _Stat('Messages', '$_myConversations',
          Icons.forum_outlined, const Color(0xFFFF9800)),
      _Stat('Note', '${(_lawyer?.rating ?? 0.0).toStringAsFixed(1)}',
          Icons.star_rounded, _gold),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.3),
      itemCount: stats.length,
      itemBuilder: (_, i) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: stats[i].color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(stats[i].icon, color: stats[i].color, size: 24),
                ),
                Text(stats[i].value, style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              ],
            ),
            Text(stats[i].label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
          ]
        ),
      ),
    );
  }

  Widget _buildBioCard() => Container(
    width: double.infinity, padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        children: [
          Icon(Icons.format_quote_rounded, color: _gold.withOpacity(0.5), size: 32),
        ],
      ),
      const SizedBox(height: 10),
      Text(_lawyer!.bio!, style: GoogleFonts.poppins(
          color: Colors.white.withOpacity(0.85), fontSize: 15, fontStyle: FontStyle.italic, height: 1.6)),
    ]),
  );

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1B2D42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.1))),
        title: Text('Déconnexion',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        content: Text('Voulez-vous vraiment vous déconnecter ?',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Annuler', style: GoogleFonts.poppins(color: Colors.white70))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _auth.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Déconnecter', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Stat {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Stat(this.label, this.value, this.icon, this.color);
}

