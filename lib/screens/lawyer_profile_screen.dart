import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lawyer_model.dart';
import '../services/auth_service.dart';
import 'chat_thread_screen.dart';

class LawyerProfileScreen extends StatefulWidget {
  final LawyerModel lawyer;
  const LawyerProfileScreen({super.key, required this.lawyer});

  @override
  State<LawyerProfileScreen> createState() => _LawyerProfileScreenState();
}

class _LawyerProfileScreenState extends State<LawyerProfileScreen> {
  static const Color _primary = Color(0xFF1565C0);

  bool _submittingRating = false;
  double _userRating = 0;
  bool _hasRated = false;
  bool _checkingRating = true;

  @override
  void initState() {
    super.initState();
    _checkIfRated();
  }

  Future<void> _checkIfRated() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { setState(() => _checkingRating = false); return; }
    final doc = await FirebaseFirestore.instance
        .collection('ratings')
        .doc('${widget.lawyer.uid}_$uid')
        .get();
    if (mounted) {
      setState(() {
        _hasRated = doc.exists;
        _userRating = (doc.data()?['rating'] ?? 0).toDouble();
        _checkingRating = false;
      });
    }
  }

  Future<void> _submitRating(double rating) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _submittingRating = true);

    final ratingDocRef = FirebaseFirestore.instance
        .collection('ratings')
        .doc('${widget.lawyer.uid}_$uid');
    final lawyerRef = FirebaseFirestore.instance
        .collection('lawyers')
        .doc(widget.lawyer.uid);

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
      final newScore = _calcScore(newRating, newCount, d['experience'] ?? 0);

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
        content: Text('Merci pour votre évaluation (${rating.toStringAsFixed(1)}★)'),
        backgroundColor: Colors.green,
      ));
    }
  }

  double _calcScore(double rating, int reviewCount, int experience) {
    double ratingScore = (rating / 5.0) * 35;
    double expScore = (experience.clamp(0, 20) / 20.0) * 25;
    double reviewScore = (reviewCount.clamp(0, 50) / 50.0) * 10;
    return ratingScore + expScore + reviewScore;
  }

  Future<void> _startChat() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    // نبحث عن محادثة مباشرة بين المستخدم والمحامي
    final existing = await FirebaseFirestore.instance
        .collection('conversations')
        .where('userId', isEqualTo: currentUid)
        .where('lawyerId', isEqualTo: widget.lawyer.uid)
        .where('requestId', isEqualTo: 'direct')
        .limit(1)
        .get();

    String convId;
    if (existing.docs.isNotEmpty) {
      convId = existing.docs.first.id;
    } else {
      final doc = await FirebaseFirestore.instance.collection('conversations').add({
        'requestId': 'direct',
        'userId': currentUid,
        'lawyerId': widget.lawyer.uid,
        'lawyerName': widget.lawyer.name,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageAt': null,
        'lastMessageText': null,
      });
      convId = doc.id;
    }

    if (mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChatThreadScreen(conversationId: convId),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lawyer = widget.lawyer;
    final imageUrl = (lawyer.photoUrl != null && lawyer.photoUrl!.isNotEmpty)
        ? lawyer.photoUrl!
        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(lawyer.name)}&background=1565C0&color=ffffff&size=200';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // ── App Bar avec photo ──────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: _primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            image: DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          lawyer.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lawyer.speciality,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Stats Row ──────────────────────────────
                  Row(
                    children: [
                      _statBox('${lawyer.rating.toStringAsFixed(1)}★',
                          '${lawyer.reviewCount} avis', Colors.amber),
                      const SizedBox(width: 12),
                      _statBox('${lawyer.experience ?? 0} ans',
                          'Expérience', _primary),
                      const SizedBox(width: 12),
                      _statBox(
                        lawyer.wilaya ?? '-',
                        'Wilaya',
                        Colors.teal,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Boutons d'action ───────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _startChat,
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                          label: const Text('Envoyer un message'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (lawyer.phone != null) ...[
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.phone_outlined, size: 18),
                          label: const Text('Appeler'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primary,
                            side: const BorderSide(color: _primary),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Informations ───────────────────────────
                  _sectionTitle('Informations'),
                  const SizedBox(height: 12),
                  _infoCard([
                    if (lawyer.email.isNotEmpty)
                      _infoRow(Icons.email_outlined, lawyer.email),
                    if (lawyer.phone != null)
                      _infoRow(Icons.phone_outlined, lawyer.phone!),
                    if (lawyer.wilaya != null)
                      _infoRow(Icons.location_on_outlined,
                          [lawyer.wilaya, lawyer.daira, lawyer.commune]
                              .where((s) => s != null && s.isNotEmpty)
                              .join(', ')),
                    if (lawyer.city != null)
                      _infoRow(Icons.business_outlined, lawyer.city!),
                  ]),

                  // ── Biographie ────────────────────────────
                  if (lawyer.bio != null && lawyer.bio!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionTitle('À propos'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Text(
                        lawyer.bio!,
                        style: const TextStyle(
                          color: Color(0xFF455A64),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],

                  // ── Évaluation ────────────────────────────
                  const SizedBox(height: 24),
                  _sectionTitle('Évaluer cet avocat'),
                  const SizedBox(height: 12),
                  _ratingCard(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(
              color: color, fontSize: 18, fontWeight: FontWeight.w800,
            )),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(
              color: Colors.grey, fontSize: 11,
            )),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
    style: const TextStyle(
      fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF263238),
    ),
  );

  Widget _infoCard(List<Widget> rows) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.grey.shade100),
    ),
    child: Column(children: rows),
  );

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Icon(icon, size: 18, color: _primary),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(
          fontSize: 14, color: Color(0xFF37474F),
        ))),
      ],
    ),
  );

  Widget _ratingCard() {
    if (_checkingRating) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          if (_hasRated) ...[
            const Icon(Icons.check_circle_outline_rounded,
                color: Colors.green, size: 36),
            const SizedBox(height: 8),
            Text(
              'Vous avez donné ${_userRating.toStringAsFixed(1)}★',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text('Modifier votre évaluation :',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
          ] else
            const Text(
              'Partagez votre expérience avec cet avocat',
              style: TextStyle(color: Color(0xFF607D8B), fontSize: 13),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: _submittingRating ? null : () => _submitRating(star.toDouble()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    star <= _userRating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 36,
                  ),
                ),
              );
            }),
          ),
          if (_submittingRating) ...[
            const SizedBox(height: 12),
            const CircularProgressIndicator(strokeWidth: 2),
          ],
        ],
      ),
    );
  }
}
