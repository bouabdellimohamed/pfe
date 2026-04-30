import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/lawyer_model.dart';
import '../data/algeria_data.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'welcome_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _random = Random();

  // ── بيانات واقعية ومتنوعة ──────────────────────────────────────────────────

  static const List<String> _firstNames = [
    'Ahmed',
    'Mohamed',
    'Karim',
    'Samir',
    'Amine',
    'Omar',
    'Walid',
    'Hichem',
    'Sofiane',
    'Faycal',
    'Riad',
    'Zaki',
    'Yacine',
    'Nabil',
    'Fatima',
    'Yasmine',
    'Lina',
    'Sonia',
    'Myriam',
    'Nadia',
    'Meriem',
    'Ines',
    'Djamila',
    'Amina',
    'Houda',
    'Samira',
    'Abdelkader',
    'Mourad',
    'Hamza',
    'Khaled',
    'Rachid',
    'Tarek',
  ];

  static const List<String> _lastNames = [
    'Benali',
    'Bouzid',
    'Brahimi',
    'Mansouri',
    'Haddad',
    'Belkacem',
    'Toumi',
    'Khelifi',
    'Saidi',
    'Laribi',
    'Hamidi',
    'Merabet',
    'Rahmani',
    'Ghezali',
    'Oudina',
    'Slimani',
    'Bacha',
    'Lamine',
    'Kasmi',
    'Boudiaf',
    'Zeroual',
    'Cherif',
    'Messaoud',
    'Ferhat',
    'Aouadi',
    'Bouazza',
    'Nouri',
    'Taleb',
    'Hadj',
    'Benhamou',
  ];

  static const List<String> _specialities = [
    'Droit familial',
    'Droit pénal',
    'Droit commercial',
    'Droit civil',
    'Droit immobilier',
    'Droit administratif',
    'Droit du travail',
    'Droit des sociétés',
    'Droit fiscal',
    'Propriété Intellectuelle',
  ];

  // ولايات رئيسية بمحاكم كبيرة — أكثر واقعية للتوزيع
  static const List<String> _mainWilayas = [
    'Alger',
    'Oran',
    'Constantine',
    'Annaba',
    'Blida',
    'Batna',
    'Sétif',
    'Biskra',
    'Tlemcen',
    'Béjaïa',
    'Skikda',
    'Médéa',
    'Mostaganem',
    'M\'Sila',
    'Chlef',
    'Guelma',
    'Jijel',
    'Tiaret',
    'Bouira',
    'Boumerdès',
    'Tipaza',
    'Tébessa',
    'Djelfa',
    'Ouargla',
  ];

  static const List<String> _bios = [
    'Avocat inscrit au barreau depuis plus de {exp} ans, spécialisé en {spec}. J\'accompagne mes clients avec rigueur et professionnalisme dans toutes leurs démarches juridiques.',
    'Fort de {exp} années d\'expérience en {spec}, je mets mon expertise au service de mes clients pour défendre leurs droits et intérêts.',
    'Diplômé de la faculté de droit, j\'exerce depuis {exp} ans avec une expertise reconnue en {spec}. Je m\'engage à fournir des conseils juridiques clairs et adaptés.',
    'Avocat engagé avec {exp} ans de pratique en {spec}. Ma priorité est d\'offrir à chaque client un accompagnement personnalisé et efficace.',
    'Spécialiste en {spec} depuis {exp} ans, j\'interviens auprès des particuliers et des entreprises pour la résolution amiable et judiciaire de leurs litiges.',
  ];

  // ── توليد بيانات واقعية ───────────────────────────────────────────────────

  String _randomName() {
    final first = _firstNames[_random.nextInt(_firstNames.length)];
    final last = _lastNames[_random.nextInt(_lastNames.length)];
    return '$first $last';
  }

  String _randomPhone() {
    final prefixes = ['05', '06', '07'];
    final prefix = prefixes[_random.nextInt(prefixes.length)];
    final number = 10000000 + _random.nextInt(89999999);
    return '$prefix$number';
  }

  // rating موزّع بشكل واقعي: غالبية بين 3.5 و 4.8
  double _randomRating() {
    final val = 3.0 + _random.nextDouble() * 2.0;
    return double.parse(val.toStringAsFixed(1)).clamp(1.0, 5.0);
  }

  // finalScore محسوب حقيقياً من المعطيات وليس عشوائياً
  double _calcFinalScore({
    required double rating,
    required int reviewCount,
    required int experience,
    required int activityPoints,
    required double responseRate,
  }) {
    final ratingScore = (rating / 5.0) * 35;
    final expScore = (experience.clamp(0, 20) / 20.0) * 25;
    final reviewScore = (reviewCount.clamp(0, 50) / 50.0) * 10;
    final activityScore = (activityPoints.clamp(0, 100) / 100.0) * 20;
    final responseScore = responseRate.clamp(0.0, 1.0) * 10;
    return double.parse(
      (ratingScore + expScore + reviewScore + activityScore + responseScore)
          .toStringAsFixed(1),
    );
  }

  String _buildBio(String name, int exp, String spec) {
    final template = _bios[_random.nextInt(_bios.length)];
    return template
        .replaceAll('{exp}', exp.toString())
        .replaceAll('{spec}', spec);
  }

  Map<String, dynamic> _buildLawyerData(String docId) {
    final name = _randomName();
    final wilaya = _mainWilayas[_random.nextInt(_mainWilayas.length)];
    final dairas = AlgeriaData.wilayaDairas[wilaya] ?? [wilaya];
    final daira = dairas[_random.nextInt(dairas.length)];
    final communes = AlgeriaData.dairaCommunes[daira] ?? [daira];
    final commune = communes[_random.nextInt(communes.length)];

    // تخصص واحد أو أكثر (20% فرصة لتخصصين)
    final isGeneralist = _random.nextDouble() < 0.15; // 15% عموميون
    String speciality;
    if (isGeneralist) {
      speciality = 'Généraliste';
    } else if (_random.nextDouble() < 0.2) {
      // 20% لديهم تخصصان
      final s1 = _specialities[_random.nextInt(_specialities.length)];
      String s2;
      do {
        s2 = _specialities[_random.nextInt(_specialities.length)];
      } while (s2 == s1);
      speciality = '$s1, $s2';
    } else {
      speciality = _specialities[_random.nextInt(_specialities.length)];
    }

    final experience = 1 + _random.nextInt(30); // 1–30 سنة
    final reviewCount = _random.nextInt(120);
    final activityPoints = _random.nextInt(101); // 0–100
    final responseRate =
        double.parse((_random.nextDouble()).toStringAsFixed(3));
    final rating = _randomRating();

    final finalScore = _calcFinalScore(
      rating: rating,
      reviewCount: reviewCount,
      experience: experience,
      activityPoints: activityPoints,
      responseRate: responseRate,
    );

    final nameParts = name.split(' ');
    final email =
        '${nameParts.last.toLowerCase().replaceAll(RegExp(r"[^a-z]"), "")}.'
        '${nameParts.first.toLowerCase().replaceAll(RegExp(r"[^a-z]"), "")}'
        '@jurisdz.com';

    return {
      'uid': docId,
      'email': email,
      'name': 'Maître $name',
      'speciality': speciality,
      'phone': _randomPhone(),
      'city': 'Centre Ville',
      'experience': experience,
      'isGeneralist': isGeneralist,
      'wilaya': wilaya,
      'daira': daira,
      'commune': commune,
      'rating': rating,
      'reviewCount': reviewCount,
      'activityPoints': activityPoints,
      'responseRate': responseRate,
      'successfulDemands': _random.nextInt(50),
      'finalScore': finalScore,
      'isVerified': _random.nextDouble() < 0.4, // 40% موثّقون
      'bio': _buildBio(name, experience, speciality.split(',').first.trim()),
      'photoUrl': null,
      'role': 'lawyer',
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // ── دالة الإنشاء الرئيسية ─────────────────────────────────────────────────

  Future<void> _seedFakeLawyers() async {
    // نسأل الأدمين كم محامياً يريد
    final count = await _showCountDialog();
    if (count == null || !mounted) return;

    final scaffoldMsg = ScaffoldMessenger.of(context);
    try {
      HapticFeedback.heavyImpact();

      // Firestore batch يقبل 500 عملية كحد أقصى
      const batchLimit = 500;
      int created = 0;

      while (created < count) {
        final batch = _firestore.batch();
        final chunkSize = min(batchLimit, count - created);

        for (int i = 0; i < chunkSize; i++) {
          final docRef = _firestore.collection('lawyers').doc();
          batch.set(docRef, _buildLawyerData(docRef.id));
        }

        await batch.commit();
        created += chunkSize;
      }

      if (mounted) {
        scaffoldMsg.showSnackBar(SnackBar(
          content: Text('$count avocats générés avec succès !'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        scaffoldMsg.showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<int?> _showCountDialog() async {
    final ctrl = TextEditingController(text: '20');
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Générer des avocats',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Combien d\'avocats voulez-vous générer ?',
                style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Nombre (max 500)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final n = int.tryParse(ctrl.text.trim()) ?? 0;
              if (n <= 0 || n > 500) return;
              Navigator.pop(ctx, n);
            },
            child: Text('Générer',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── حذف جميع المحامين الوهميين ───────────────────────────────────────────

  Future<void> _deleteAllFakeLawyers() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer tous les avocats',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
            'Cette action supprimera tous les avocats sans compte Firebase Auth (avocats générés). Êtes-vous sûr ?',
            style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      HapticFeedback.heavyImpact();
      final snap = await _firestore.collection('lawyers').get();

      // نحذف على دفعات من 500
      const batchLimit = 500;
      int deleted = 0;
      final docs = snap.docs;

      while (deleted < docs.length) {
        final batch = _firestore.batch();
        final end = min(deleted + batchLimit, docs.length);
        for (int i = deleted; i < end; i++) {
          batch.delete(docs[i].reference);
        }
        await batch.commit();
        deleted = end;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$deleted avocats supprimés.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  // ── التحقق من المحامي ─────────────────────────────────────────────────────

  Future<void> _toggleVerification(String lawyerId, bool currentStatus) async {
    try {
      HapticFeedback.mediumImpact();
      await _firestore.collection('lawyers').doc(lawyerId).update({
        'isVerified': !currentStatus,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(!currentStatus
              ? 'Avocat vérifié avec succès'
              : 'Vérification révoquée'),
          backgroundColor: !currentStatus ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  // ── موافقة / رفض المحامي ─────────────────────────────────────────────────

  Future<void> _approveLawyer(String lawyerId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Approuver la demande',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Voulez-vous approuver la demande de $name ?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Approuver',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      HapticFeedback.mediumImpact();
      await _firestore.collection('lawyers').doc(lawyerId).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Avocat approuvé avec succès !'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating),
        );
    }
  }

  Future<void> _rejectLawyer(String lawyerId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Refuser la demande',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Voulez-vous refuser la demande de $name ?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Refuser',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      HapticFeedback.mediumImpact();
      await _firestore
          .collection('lawyers')
          .doc(lawyerId)
          .update({'status': 'rejected'});
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Demande refusée.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating),
        );
    }
  }

  // ── الواجهة ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.grey50,
        appBar: AppBar(
          title: Text('Administration',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelStyle:
                GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.people_rounded), text: 'Avocats'),
              Tab(
                  icon: Icon(Icons.pending_actions_rounded),
                  text: 'En attente'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
              tooltip: 'Supprimer tous',
              onPressed: _deleteAllFakeLawyers,
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Déconnexion',
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
        body: TabBarView(children: [_buildApprovedTab(), _buildPendingTab()]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _seedFakeLawyers,
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.person_add_rounded, color: Colors.white),
          label: Text('Générer Avocats',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // ── تبويب المحامين المقبولين ─────────────────────────────────────────────
  Widget _buildApprovedTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('lawyers')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allDocs = snapshot.data?.docs ?? [];
        // backward compat: إذا لا يوجد حقل status → هو محامي وهمي (مقبول تلقائياً)
        final lawyerDocs = allDocs.where((d) {
          final s = (d.data() as Map)['status'];
          return s == 'approved' || s == null;
        }).toList();
        if (lawyerDocs.isEmpty) {
          return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text('Aucun avocat approuvé',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('Appuyez sur + pour en générer',
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary, fontSize: 13)),
          ]));
        }
        return Column(children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12)),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statChip(Icons.people_rounded,
                      '${lawyerDocs.length} avocats', AppColors.primary),
                  _statChip(
                      Icons.verified_rounded,
                      '${lawyerDocs.where((d) => (d.data() as Map)['isVerified'] == true).length} vérifiés',
                      Colors.green),
                ]),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lawyerDocs.length,
              itemBuilder: (context, index) {
                final data = lawyerDocs[index].data() as Map<String, dynamic>;
                final docId = lawyerDocs[index].id;
                final lawyer = LawyerModel.fromMap({...data, 'uid': docId});
                final isVerified = lawyer.isVerified;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.1),
                              backgroundImage: lawyer.photoUrl != null
                                  ? CachedNetworkImageProvider(lawyer.photoUrl!)
                                      as ImageProvider
                                  : null,
                              child: lawyer.photoUrl == null
                                  ? const Icon(Icons.person,
                                      color: AppColors.primary)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Row(children: [
                                    Expanded(
                                        child: Text(lawyer.name,
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis)),
                                    if (isVerified)
                                      const Icon(Icons.verified_rounded,
                                          color: Colors.blue, size: 20),
                                  ]),
                                  Text(
                                      lawyer.speciality.isEmpty
                                          ? 'Avocat Généraliste'
                                          : lawyer.speciality,
                                      style: GoogleFonts.poppins(
                                          color: AppColors.textSecondary,
                                          fontSize: 13)),
                                ])),
                          ]),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 4, children: [
                            _chip(Icons.location_on_outlined,
                                lawyer.wilaya ?? '-'),
                            _chip(Icons.star_rounded,
                                '${lawyer.rating.toStringAsFixed(1)} (${lawyer.reviewCount})'),
                            _chip(Icons.work_outline_rounded,
                                '${lawyer.experience ?? 0} ans'),
                            _chip(Icons.leaderboard_rounded,
                                'Score: ${lawyer.finalScore.toStringAsFixed(0)}'),
                          ]),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(children: [
                            const Icon(Icons.email_outlined,
                                size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(lawyer.email,
                                    style: GoogleFonts.poppins(fontSize: 13))),
                          ]),
                          if (lawyer.phone != null &&
                              lawyer.phone!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(children: [
                              const Icon(Icons.phone_outlined,
                                  size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(lawyer.phone!,
                                  style: GoogleFonts.poppins(fontSize: 13)),
                            ]),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _toggleVerification(docId, isVerified),
                              icon: Icon(isVerified
                                  ? Icons.cancel_outlined
                                  : Icons.check_circle_outline_rounded),
                              label: Text(isVerified
                                  ? 'Révoquer Vérification'
                                  : 'Vérifier l\'avocat'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isVerified
                                    ? Colors.orange.shade50
                                    : Colors.green.shade50,
                                foregroundColor: isVerified
                                    ? Colors.orange.shade800
                                    : Colors.green.shade800,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: isVerified
                                          ? Colors.orange.shade200
                                          : Colors.green.shade200),
                                ),
                              ),
                            ),
                          ),
                        ]),
                  ),
                );
              },
            ),
          ),
        ]);
      },
    );
  }

  // ── تبويب الطلبات المعلّقة ───────────────────────────────────────────────
  Widget _buildPendingTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('lawyers')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_outline_rounded,
                size: 64, color: Colors.green),
            const SizedBox(height: 12),
            Text('Aucune demande en attente',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ]));
        }
        return Column(children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _statChip(Icons.pending_actions_rounded,
                  '${docs.length} demande(s) en attente', Colors.orange),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final docId = docs[index].id;
                final name = data['name'] ?? 'N/A';
                final email = data['email'] ?? '';
                final speciality = data['speciality'] ?? '';
                final wilaya = data['wilaya'] ?? '-';
                final experience = data['experience'] ?? 0;
                final documentUrl = data['documentUrl'] as String?;
                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.orange.withOpacity(0.35)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.orange.withOpacity(0.1),
                                child: const Icon(Icons.person,
                                    color: Colors.orange)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(name,
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  Text(
                                      speciality.isEmpty
                                          ? 'Généraliste'
                                          : speciality,
                                      style: GoogleFonts.poppins(
                                          color: AppColors.textSecondary,
                                          fontSize: 13)),
                                ])),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: Colors.orange.shade200),
                              ),
                              child: Text('En attente',
                                  style: GoogleFonts.poppins(
                                      color: Colors.orange.shade800,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          Wrap(spacing: 8, runSpacing: 4, children: [
                            _chip(Icons.location_on_outlined, wilaya),
                            _chip(
                                Icons.work_outline_rounded, '$experience ans'),
                            _chip(Icons.email_outlined, email),
                          ]),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          if (documentUrl != null) ...[
                            // ── زر فتح الوثيقة ──
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  String finalUrl = documentUrl;

                                  // ✅ 1. تجميع الأجزاء (Chunks) إذا كان الملف كبيراً
                                  if (documentUrl.startsWith('chunked:')) {
                                    try {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (_) => const Center(
                                            child: CircularProgressIndicator(
                                                color: Colors.white)),
                                      );

                                      final parts = documentUrl.split(':');
                                      final mimeType = parts[1];
                                      final totalChunks = int.parse(parts[2]);

                                      StringBuffer sb = StringBuffer();
                                      for (int i = 0; i < totalChunks; i++) {
                                        final chunkDoc = await FirebaseFirestore
                                            .instance
                                            .collection('lawyers')
                                            .doc(docId)
                                            .collection('document_chunks')
                                            .doc('chunk_$i')
                                            .get();
                                        if (chunkDoc.exists) {
                                          sb.write(
                                              chunkDoc.data()?['data'] ?? '');
                                        }
                                      }

                                      if (context.mounted)
                                        Navigator.pop(context); // Close loading
                                      finalUrl =
                                          'data:$mimeType;base64,${sb.toString()}';
                                    } catch (e) {
                                      if (context.mounted)
                                        Navigator.pop(context); // Close loading
                                      debugPrint('Error loading chunks: $e');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    'Erreur lors du chargement du fichier volumineux')));
                                      }
                                      return;
                                    }
                                  }

                                  // ✅ 2. عرض الصورة إذا كانت بترميز Base64
                                  if (finalUrl.startsWith('data:image')) {
                                    try {
                                      final base64Str =
                                          finalUrl.split(',').last;
                                      final bytes = base64Decode(base64Str);
                                      if (context.mounted) {
                                        showDialog(
                                          context: context,
                                          builder: (_) => Dialog(
                                            clipBehavior: Clip.antiAlias,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16)),
                                            child: Stack(
                                              children: [
                                                InteractiveViewer(
                                                    child: Image.memory(bytes,
                                                        fit: BoxFit.contain)),
                                                Positioned(
                                                  top: 10,
                                                  right: 10,
                                                  child: CircleAvatar(
                                                    backgroundColor: Colors
                                                        .white
                                                        .withOpacity(0.8),
                                                    child: IconButton(
                                                      icon: const Icon(
                                                          Icons.close,
                                                          color: Colors.black),
                                                      onPressed: () =>
                                                          Navigator.pop(_),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                      return;
                                    } catch (e) {
                                      debugPrint(
                                          'Error decoding base64 image: $e');
                                    }
                                  }

                                  // ✅ 3. محاولة فتح الروابط الأخرى (مثل PDF كـ Data URI أو روابط عادية)
                                  final uri = Uri.tryParse(finalUrl);
                                  if (uri != null) {
                                    try {
                                      await launchUrl(uri,
                                          mode: LaunchMode.externalApplication);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                              'Impossible d\'ouvrir le document: $e'),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                        ));
                                      }
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content:
                                            Text('Lien du document invalide'),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                      ));
                                    }
                                  }
                                },
                                icon: const Icon(Icons.open_in_new_rounded,
                                    size: 16),
                                label: Text('Voir le document',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppColors.primary.withOpacity(0.1),
                                  foregroundColor: AppColors.primary,
                                  elevation: 0,
                                  side: BorderSide(
                                      color:
                                          AppColors.primary.withOpacity(0.35)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // ── زر نسخ الرابط ──
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: documentUrl));
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text(
                                        'Lien copié dans le presse-papiers'),
                                    backgroundColor: Colors.blueGrey,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                },
                                icon: const Icon(Icons.copy_rounded, size: 14),
                                label: Text('Copier le lien',
                                    style: GoogleFonts.poppins(fontSize: 12)),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ] else
                            Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    size: 14, color: Colors.red.shade400),
                                const SizedBox(width: 6),
                                Text('Aucun document joint',
                                    style: GoogleFonts.poppins(
                                        color: Colors.red.shade400,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic)),
                              ],
                            ),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _rejectLawyer(docId, name),
                                icon: const Icon(Icons.close_rounded, size: 16),
                                label: Text('Refuser',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade700,
                                  side: BorderSide(color: Colors.red.shade300),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _approveLawyer(docId, name),
                                icon: const Icon(Icons.check_rounded, size: 16),
                                label: Text('Approuver',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ]),
                        ]),
                  ),
                );
              },
            ),
          ),
        ]);
      },
    );
  }

  Widget _statChip(IconData icon, String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      );

  Widget _chip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade700)),
          ],
        ),
      );
}
