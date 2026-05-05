import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/signalement_service.dart';

/// شاشة عرض الملف الشخصي الكامل للعميل (مرئي من طرف المحامي)
class ClientProfileScreen extends StatefulWidget {
  final String clientId;
  const ClientProfileScreen({super.key, required this.clientId});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen>
    with SingleTickerProviderStateMixin {
  UserModel? _client;
  bool _isLoading = true;
  int _consultationCount = 0;
  int _requestCount = 0;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const _primary = Color(0xFF0052D4);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _loadClient();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadClient() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.clientId)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _client = UserModel.fromMap(doc.data()!);
          _isLoading = false;
        });
        _animCtrl.forward();
      } else {
        if (mounted) setState(() => _isLoading = false);
      }

      // Count consultations
      final consultSnap = await FirebaseFirestore.instance
          .collection('consultations')
          .where('userId', isEqualTo: widget.clientId)
          .get();
      // Count requests
      final requestSnap = await FirebaseFirestore.instance
          .collection('requests')
          .where('userId', isEqualTo: widget.clientId)
          .get();

      if (mounted) {
        setState(() {
          _consultationCount = consultSnap.docs.length;
          _requestCount = requestSnap.docs.length;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showReportDialog() {
    SignalementService.showReportDialog(
      context: context,
      reportedUserId: widget.clientId,
      reportedUserName: _client?.fullName ?? '',
      reportedUserRole: 'user',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: _primary,
          elevation: 0,
          leading: const BackButton(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: _primary),
        ),
      );
    }

    if (_client == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: _primary,
          elevation: 0,
          leading: const BackButton(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_rounded, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('client_not_found'.tr(),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    final c = _client!;
    final hasImage = c.profileImageBase64 != null && c.profileImageBase64!.isNotEmpty;
    final joinDate = DateFormat('dd/MM/yyyy').format(c.createdAt);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              elevation: 0,
              backgroundColor: _primary,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: Material(
                  color: Colors.white.withOpacity(0.2),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              actions: [
                // Report button
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Material(
                    color: Colors.white.withOpacity(0.2),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.flag_rounded,
                          color: Colors.white, size: 20),
                      tooltip: 'report'.tr(),
                      onPressed: _showReportDialog,
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0052D4), Color(0xFF4364F7), Color(0xFF6FB1FC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -40,
                        top: -20,
                        child: Icon(Icons.person_rounded,
                            size: 200, color: Colors.white.withOpacity(0.08)),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 30,
                        child: Column(
                          children: [
                            // Avatar
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 48,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                backgroundImage: hasImage
                                    ? MemoryImage(base64Decode(c.profileImageBase64!))
                                    : null,
                                child: !hasImage
                                    ? Text(
                                        c.fullName.isNotEmpty
                                            ? c.fullName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              c.fullName,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'client_label'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Stats ──
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(
                        icon: Icons.gavel_rounded,
                        value: _consultationCount.toString(),
                        label: 'consultations_stat'.tr(),
                        color: _primary,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade200,
                      ),
                      _StatItem(
                        icon: Icons.campaign_rounded,
                        value: _requestCount.toString(),
                        label: 'requests_stat'.tr(),
                        color: const Color(0xFFF59E0B),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade200,
                      ),
                      _StatItem(
                        icon: Icons.calendar_month_rounded,
                        value: joinDate,
                        label: 'member_since'.tr(),
                        color: const Color(0xFF0F766E),
                        isSmallValue: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Info Section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Section title
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: _primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'client_info_section'.tr(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Info cards
                    _InfoCard(
                      icon: Icons.person_rounded,
                      label: 'full_name'.tr(),
                      value: c.fullName,
                      color: _primary,
                    ),
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: Icons.email_rounded,
                      label: 'email_address'.tr(),
                      value: c.email,
                      color: const Color(0xFF7C3AED),
                    ),
                    if (c.phone != null && c.phone!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _InfoCard(
                        icon: Icons.phone_rounded,
                        label: 'phone_label'.tr(),
                        value: c.phone!,
                        color: const Color(0xFF0F766E),
                      ),
                    ],
                    if (c.age != null) ...[
                      const SizedBox(height: 12),
                      _InfoCard(
                        icon: Icons.cake_rounded,
                        label: 'age'.tr(),
                        value: '${c.age} ${'years_suffix'.tr()}',
                        color: const Color(0xFFF59E0B),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: Icons.calendar_today_rounded,
                      label: 'member_since'.tr(),
                      value: joinDate,
                      color: const Color(0xFF059669),
                    ),

                    const SizedBox(height: 32),

                    // Report button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _showReportDialog,
                        icon: const Icon(Icons.flag_rounded, size: 20),
                        label: Text('report_user'.tr(),
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isSmallValue;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.isSmallValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFF1E293B),
            fontSize: isSmallValue ? 12 : 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
