import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/lawyer_model.dart';
import '../services/favorites_service.dart';
import '../widgets/profile_avatar.dart';
import 'chat_thread_screen.dart';

class LawyerProfileScreen extends StatefulWidget {
  final LawyerModel lawyer;
  const LawyerProfileScreen({super.key, required this.lawyer});

  @override
  State<LawyerProfileScreen> createState() => _LawyerProfileScreenState();
}

class _LawyerProfileScreenState extends State<LawyerProfileScreen> {
  static const Color _primary = Color(0xFF0052D4);

  bool _submittingRating = false;
  double _userRating = 0;
  bool _hasRated = false;
  bool _checkingRating = true;

  // Favorites
  final _favService = FavoritesService();
  bool _isFavorite = false;
  bool _loadingFav = true;

  @override
  void initState() {
    super.initState();
    _checkIfRated();
    _checkFavorite();
  }

  Future<void> _checkIfRated() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _checkingRating = false);
      return;
    }
    final doc = await FirebaseFirestore.instance.collection('ratings').doc('${widget.lawyer.uid}_$uid').get();
    if (mounted) {
      setState(() {
        _hasRated = doc.exists;
        _userRating = (doc.data()?['rating'] ?? 0).toDouble();
        _checkingRating = false;
      });
    }
  }

  Future<void> _checkFavorite() async {
    final fav = await _favService.isFavorite(widget.lawyer.uid);
    if (mounted) {
      setState(() {
        _isFavorite = fav;
        _loadingFav = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    HapticFeedback.lightImpact();
    final result = await _favService.toggleFavorite(widget.lawyer.uid);
    if (mounted) {
      setState(() => _isFavorite = result);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result ? 'added_to_favorites'.tr() : 'removed_from_favorites'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Future<void> _submitRating(double rating) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _submittingRating = true);
    HapticFeedback.mediumImpact();

    final ratingDocRef = FirebaseFirestore.instance.collection('ratings').doc('${widget.lawyer.uid}_$uid');
    final lawyerRef = FirebaseFirestore.instance.collection('lawyers').doc(widget.lawyer.uid);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final lawyerSnap = await tx.get(lawyerRef);
      final d = lawyerSnap.data() as Map<String, dynamic>;
      final oldCount = (d['reviewCount'] ?? 0) as int;
      final oldRating = (d['rating'] ?? 0.0).toDouble();

      double newRating;
      int newCount;

      final existingRatingSnap = await tx.get(ratingDocRef);
      if (existingRatingSnap.exists) {
        final oldUserRating = (existingRatingSnap.data()?['rating'] ?? 0).toDouble();
        final totalPoints = oldRating * oldCount - oldUserRating + rating;
        newCount = oldCount;
        newRating = oldCount > 0 ? totalPoints / oldCount : rating;
      } else {
        final totalPoints = oldRating * oldCount + rating;
        newCount = oldCount + 1;
        newRating = totalPoints / newCount;
      }

      newRating = double.parse(newRating.toStringAsFixed(1));
      final newScore = _calcScore(
        newRating,
        newCount,
        d['experience'] ?? 0,
        activityPoints: d['activityPoints'] ?? 0,
        responseRate: (d['responseRate'] ?? 0.0).toDouble(),
      );

      tx.set(ratingDocRef, {'rating': rating, 'userId': uid, 'lawyerId': widget.lawyer.uid});
      tx.update(lawyerRef, {
        'rating': newRating,
        'reviewCount': newCount,
        'finalScore': newScore,
      });
    });

    if (mounted) {
      setState(() {
        _userRating = rating;
        _hasRated = true;
        _submittingRating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('rating_thanks'.tr(namedArgs: {'rating': rating.toStringAsFixed(1)}), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  double _calcScore(double rating, int reviewCount, int experience, {int activityPoints = 0, double responseRate = 0.0}) {
    double ratingScore = (rating / 5.0) * 35;
    double expScore = (experience.clamp(0, 20) / 20.0) * 25;
    double reviewScore = (reviewCount.clamp(0, 50) / 50.0) * 10;
    double activityScore = (activityPoints.clamp(0, 100) / 100.0) * 20;
    double responseScore = (responseRate.clamp(0.0, 1.0)) * 10;
    final total = ratingScore + expScore + reviewScore + activityScore + responseScore;
    return double.parse(total.toStringAsFixed(1));
  }

  Future<void> _startChat() async {
    HapticFeedback.lightImpact();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    final existing = await FirebaseFirestore.instance
        .collection('conversations')
        .where('userId', isEqualTo: currentUid)
        .where('lawyerId', isEqualTo: widget.lawyer.uid)
        .limit(1)
        .get();

    String convId;
    if (existing.docs.isNotEmpty) {
      convId = existing.docs.first.id;
    } else {
      String userName = '';
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUid).get();
        if (userDoc.exists) {
          final data = userDoc.data() ?? {};
          userName = (data['fullName'] ?? data['name'] ?? '').toString();
        }
      } catch (_) {}

      final doc = await FirebaseFirestore.instance.collection('conversations').add({
        'requestId': 'direct',
        'userId': currentUid,
        'lawyerId': widget.lawyer.uid,
        'lawyerName': widget.lawyer.name,
        'userName': userName,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageAt': null,
        'lastMessageText': null,
      });
      convId = doc.id;
    }

    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatThreadScreen(conversationId: convId)));
    }
  }

  Future<void> _openMap(String? locationUrl) async {
    HapticFeedback.lightImpact();
    if (locationUrl == null || locationUrl.isEmpty) return;
    final Uri url = Uri.parse(locationUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('map_open_err'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lawyer = widget.lawyer;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, -4)),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _loadingFav ? null : _toggleFavorite,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _isFavorite ? const Color(0xFFFFFBEB) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _isFavorite ? const Color(0xFFFBBF24) : Colors.grey.shade200, width: 2),
                ),
                child: Center(
                  child: Icon(
                    _isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: _isFavorite ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
                    size: 26,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _startChat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  shadowColor: _primary.withOpacity(0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_rounded, size: 20),
                    const SizedBox(width: 10),
                    Text('contact_lawyer_btn'.tr(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0052D4), Color(0xFF4364F7), Color(0xFF6FB1FC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
                      ),
                    ),
                    Positioned(
                      bottom: -100,
                      left: -50,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: ProfileAvatar(
                          imageBase64: lawyer.profileImageBase64,
                          name: lawyer.name,
                          size: 130,
                          borderColor: Colors.white,
                          borderWidth: 4,
                          backgroundColor: _primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              lawyer.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5),
                            ),
                          ),
                          if (lawyer.isVerified) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 24),
                          ]
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _primary.withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.balance_rounded, color: _primary, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              lawyer.speciality.split(', ').map((s) => s.tr()).join(', '),
                              style: const TextStyle(color: _primary, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Stats Grid
                      Row(
                        children: [
                          _buildStatCard(
                            icon: Icons.star_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            bgColor: const Color(0xFFFFFBEB),
                            title: lawyer.rating.toStringAsFixed(1),
                            subtitle: '${lawyer.reviewCount} ' + 'reviews_stat'.tr(),
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            icon: Icons.work_history_rounded,
                            iconColor: _primary,
                            bgColor: _primary.withOpacity(0.05),
                            title: '${lawyer.experience ?? 0} ' + 'years_suffix'.tr(),
                            subtitle: 'experience_stat'.tr(),
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            icon: Icons.location_on_rounded,
                            iconColor: const Color(0xFF10B981),
                            bgColor: const Color(0xFFECFDF5),
                            title: lawyer.wilaya ?? '-',
                            subtitle: 'wilaya_stat'.tr(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Bio Section
                      if (lawyer.bio != null && lawyer.bio!.isNotEmpty) ...[
                        _buildSectionTitle('about_lawyer_section'.tr()),
                        const SizedBox(height: 16),
                        Text(
                          lawyer.bio!,
                          style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Contact Info Section
                      _buildSectionTitle('coordinates_section'.tr()),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade100, width: 1.5),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          children: [
                            if (lawyer.email.isNotEmpty)
                              _buildInfoTile(Icons.alternate_email_rounded, 'email_address'.tr(), lawyer.email),
                            if (lawyer.phone != null)
                              _buildInfoTile(Icons.phone_rounded, 'phone_label'.tr(), lawyer.phone!),
                            if (lawyer.wilaya != null)
                              _buildInfoTile(
                                Icons.map_rounded,
                                'address'.tr(),
                                [lawyer.wilaya, lawyer.daira, lawyer.commune].where((s) => s != null && s.isNotEmpty).join(', '),
                              ),
                            if (lawyer.locationUrl != null && lawyer.locationUrl!.isNotEmpty)
                              _buildMapTile(lawyer.locationUrl!),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Rating Section
                      _buildSectionTitle('rate_lawyer_section'.tr()),
                      const SizedBox(height: 16),
                      _ratingCard(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Floating Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required Color iconColor, required Color bgColor, required String title, required String subtitle}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 18, color: const Color(0xFF475569)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTile(String url) {
    return InkWell(
      onTap: () => _openMap(url),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.map_rounded, size: 18, color: _primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text('view_on_map'.tr(), style: const TextStyle(fontSize: 14, color: _primary, fontWeight: FontWeight.w800)),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _primary),
          ],
        ),
      ),
    );
  }

  Widget _ratingCard() {
    if (_checkingRating) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          if (_hasRated) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'you_gave_rating'.tr(namedArgs: {'rating': _userRating.toStringAsFixed(1)}),
              style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text('edit_rating'.tr(), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFFBEB), shape: BoxShape.circle),
              child: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'share_experience'.tr(),
              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'help_others_choose'.tr(),
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 20),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: _submittingRating ? null : () => _submitRating(star.toDouble()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    star <= _userRating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: star <= _userRating ? const Color(0xFFF59E0B) : Colors.grey.shade300,
                    size: 40,
                  ),
                ),
              );
            }),
          ),
          if (_submittingRating) ...[
            const SizedBox(height: 20),
            const CircularProgressIndicator(strokeWidth: 2, color: _primary),
          ],
        ],
      ),
    );
  }
}
