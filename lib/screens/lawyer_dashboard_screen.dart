import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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

  int _availableRequests = 0;
  int _answeredRequests = 0;
  int _answeredConsultations = 0;
  int _myConversations = 0;

  // Premium Color Palette
  static const _navyDark = Color(0xFF0F172A);
  static const _navyLight = Color(0xFF1E293B);
  static const _gold = Color(0xFFC5A059);
  static const _goldAccent = Color(0xFFD4AF37);
  static const _surface = Color(0xFF1E293B);

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _loadAll();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (_uid.isEmpty) return;
    if (mounted) setState(() => _loading = true);

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
      
      final answeredReqSnap = await FirebaseFirestore.instance
          .collection('requests').where('respondedLawyerIds', arrayContains: _uid).get();

      final consultNewSnap = await FirebaseFirestore.instance
          .collection('consultations').where('respondedLawyerIds', arrayContains: _uid).get();
      final consultOldSnap = await FirebaseFirestore.instance
          .collection('consultations').where('lawyerId', isEqualTo: _uid).get();
      
      final answeredConsultIds = {
        ...consultNewSnap.docs.map((d) => d.id),
        ...consultOldSnap.docs.map((d) => d.id),
      };

      final convs = await FirebaseFirestore.instance
          .collection('conversations').where('lawyerId', isEqualTo: _uid).get();

      int availableRequests = 0;
      if (_lawyer != null && _lawyer!.speciality.isNotEmpty) {
        final mySpecs = _lawyer!.speciality
            .split(',').map((s) => s.trim().toLowerCase()).toList();
        
        availableRequests = openSnap.docs.where((doc) {
          final data = doc.data();
          final type = (data['type'] ?? '').toString().toLowerCase().trim();
          final respondedIds = List<String>.from(data['respondedLawyerIds'] ?? []);
          
          bool matchesSpec = mySpecs.any((spec) => spec == type || type.contains(spec) || spec.contains(type));
          bool notResponded = !respondedIds.contains(_uid);
          
          return matchesSpec && notResponded;
        }).length;
      }

      if (mounted) setState(() {
        _availableRequests = availableRequests;
        _answeredRequests = answeredReqSnap.docs.length;
        _answeredConsultations = answeredConsultIds.length;
        _myConversations = convs.docs.length;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navyDark,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _gold, strokeWidth: 2))
          : RefreshIndicator(
              onRefresh: _loadAll,
              color: _gold,
              backgroundColor: _navyLight,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    _buildAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            _buildProfileHeader(),
                            const SizedBox(height: 32),
                            _buildDashboardHeader(),
                            const SizedBox(height: 20),
                            _buildStatsGrid(),
                            if (_lawyer?.bio != null && _lawyer!.bio!.isNotEmpty) ...[
                              const SizedBox(height: 32),
                              _buildBioSection(),
                            ],
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAppBar() => SliverAppBar(
    backgroundColor: _navyDark.withOpacity(0.8),
    floating: true, pinned: true, elevation: 0,
    automaticallyImplyLeading: false,
    flexibleSpace: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(color: Colors.transparent),
      ),
    ),
    title: Text('lawyer_portal'.tr(), style: GoogleFonts.outfit(
        color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
    actions: [
      _buildActionCircle(
        icon: Icons.language_rounded,
        onTap: () {
          if (context.locale.languageCode == 'ar') {
            context.setLocale(const Locale('fr'));
          } else {
            context.setLocale(const Locale('ar'));
          }
        },
      ),
      const SizedBox(width: 8),
      _buildActionCircle(
        icon: Icons.logout_rounded,
        color: Colors.redAccent.withOpacity(0.1),
        iconColor: Colors.redAccent,
        onTap: _confirmSignOut,
      ),
      const SizedBox(width: 16),
    ],
  );

  Widget _buildActionCircle({required IconData icon, required VoidCallback onTap, Color? color, Color? iconColor}) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: iconColor ?? Colors.white, size: 20),
    ),
  );

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_navyLight, _navyDark.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      child: Column(children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            ProfileAvatar(
              imageBase64: _lawyer?.profileImageBase64,
              name: _lawyer?.name,
              size: 110,
              borderColor: _gold,
              borderWidth: 3,
              backgroundColor: _navyDark,
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
              child: const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(_lawyer?.name ?? 'lawyer'.tr(), textAlign: TextAlign.center, style: GoogleFonts.outfit(
            color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        if (_lawyer?.speciality != null)
          Wrap(
            spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
            children: _lawyer!.speciality.split(', ').map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _gold.withOpacity(0.2)),
              ),
              child: Text(s.tr(), style: GoogleFonts.poppins(color: _gold, fontSize: 11, fontWeight: FontWeight.w600)),
            )).toList(),
          ),
        const SizedBox(height: 28),
        _buildQuickInfo(),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              if (_lawyer == null) return;
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => LawyerEditProfileScreen(lawyer: _lawyer),
              )).then((v) { if (v == true) _loadAll(); });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.edit_note_rounded, size: 20),
                const SizedBox(width: 10),
                Text('edit_profile'.tr(), style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildQuickInfo() {
    return Column(children: [
      _infoItem(Icons.email_rounded, _lawyer?.email ?? ''),
      if (_lawyer?.phone != null) _infoItem(Icons.phone_rounded, _lawyer!.phone!),
      if (_lawyer?.wilaya != null)
        _infoItem(Icons.location_on_rounded,
            [_lawyer!.wilaya, _lawyer!.daira, _lawyer!.commune]
                .where((s) => s != null && s.isNotEmpty).join(', ')),
    ]);
  }

  Widget _infoItem(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: Colors.white38),
        const SizedBox(width: 10),
        Flexible(child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis)),
      ],
    ),
  );

  Widget _buildDashboardHeader() => Row(
    children: [
      Container(width: 3, height: 24, decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 12),
      Text('dashboard'.tr().toUpperCase(), style: GoogleFonts.outfit(
          color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      const Spacer(),
      Text(DateFormat('MMM dd, yyyy').format(DateTime.now()), style: GoogleFonts.poppins(color: Colors.white24, fontSize: 12)),
    ],
  );

  Widget _buildStatsGrid() {
    final items = [
      _StatItem('requests_answered'.tr(), '$_answeredRequests', Icons.task_alt_rounded, const Color(0xFF34D399)),
      _StatItem('consultations_answered'.tr(), '$_answeredConsultations', Icons.forum_rounded, const Color(0xFF60A5FA)),
      _StatItem('new_requests_available'.tr(), '$_availableRequests', Icons.auto_awesome_rounded, const Color(0xFFFB923C)),
      _StatItem('rating_stat'.tr(), '${(_lawyer?.rating ?? 0.0).toStringAsFixed(1)}', Icons.star_rounded, _gold),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.2,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildStatCard(items[i]),
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _navyLight.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: item.color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: item.color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const Spacer(),
          Text(item.value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(item.label, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBioSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildDashboardHeader(), // Reuse same header style
      const SizedBox(height: 16),
      Container(
        width: double.infinity, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _navyLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Text(_lawyer!.bio!, style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.7, fontStyle: FontStyle.italic)),
      ),
    ],
  );

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: _navyLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('logout_confirm_title'.tr(), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text('confirm_logout'.tr(), style: GoogleFonts.poppins(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr(), style: GoogleFonts.poppins(color: Colors.white38))),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _auth.signOut();
                if (mounted) Navigator.pushReplacementNamed(context, '/');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('logout'.tr(), style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  final String label, value;
  final IconData icon;
  final Color color;
  _StatItem(this.label, this.value, this.icon, this.color);
}
