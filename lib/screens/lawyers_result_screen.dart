import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/lawyer_model.dart';
import '../widgets/profile_avatar.dart';
import 'lawyer_profile_screen.dart';

class LawyersResultScreen extends StatelessWidget {
  final String speciality;
  final String? wilaya;

  const LawyersResultScreen({
    super.key,
    required this.speciality,
    this.wilaya,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF263238), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Experts Disponibles",
              style: TextStyle(color: Color(0xFF263238), fontSize: 20, fontWeight: FontWeight.w900),
            ),
            Text(
              "$speciality • $wilaya",
              style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ✅ جلب كل المحامين بدون فلتر Firestore (لأن التخصص محفوظ كـ "A, B, C")
        stream: FirebaseFirestore.instance.collection('lawyers').snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Erreur: ${snap.error}', textAlign: TextAlign.center),
              ),
            );
          }

          final docs = snap.data?.docs ?? [];
          var lawyers = docs
              .map((d) => LawyerModel.fromMap(d.data() as Map<String, dynamic>))
              .toList();

          // ✅ فلتر التخصص: يبحث إذا كان speciality موجود داخل الـ string (contains)
          lawyers = lawyers.where((l) {
            final lawyerSpec = l.speciality.toLowerCase();
            final searchSpec = speciality.toLowerCase();
            return lawyerSpec.contains(searchSpec);
          }).toList();

          // ✅ فلتر الولاية (case-insensitive)
          if (wilaya != null && wilaya!.trim().isNotEmpty) {
            lawyers = lawyers.where((l) =>
              (l.wilaya ?? '').toLowerCase() == wilaya!.trim().toLowerCase()
            ).toList();
          }

          lawyers.sort((a, b) => b.finalScore.compareTo(a.finalScore));

          if (lawyers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun avocat trouvé',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pas encore d\'avocats enregistrés\npour "$speciality" à $wilaya.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: lawyers.length,
            itemBuilder: (context, index) => _buildPremiumLawyerCard(context, lawyers[index]),
          );
        },
      ),
    );
  }

  Widget _buildPremiumLawyerCard(BuildContext context, LawyerModel lawyer) {
    const Color primaryBlue = Color(0xFF1565C0);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // صورة المحامي
                Stack(
                  children: [
                    ProfileAvatar(
                      imageBase64: lawyer.profileImageBase64,
                      name: lawyer.name,
                      size: 72,
                      borderColor: const Color(0xFFF1F1F1),
                      borderWidth: 1.5,
                      backgroundColor: const Color(0xFF1565C0),
                    ),
                    Positioned(
                      right: 4, top: 4,
                      child: Container(
                        width: 13, height: 13,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // المعلومات
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lawyer.name,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF263238)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lawyer.isVerified)
                            const Padding(
                              padding: EdgeInsets.only(left: 4.0),
                              child: Icon(Icons.verified_rounded, color: Colors.blue, size: 18),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      // ✅ عرض التخصصات كـ chips صغيرة
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: lawyer.speciality.split(',').map((s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryBlue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            s.trim(),
                            style: const TextStyle(color: primaryBlue, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 3),
                          Text(
                            lawyer.rating > 0 ? lawyer.rating.toStringAsFixed(1) : "Nouveau",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          if (lawyer.reviewCount > 0)
                            Text(
                              " (${lawyer.reviewCount} avis)",
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _buildInfoTag(Icons.work_history_outlined, "${lawyer.experience ?? 0} ans"),
                const SizedBox(width: 8),
                _buildInfoTag(Icons.location_on_outlined, lawyer.wilaya ?? '-'),
                const Spacer(),
                // ✅ زر الملف الشخصي يفتح LawyerProfileScreen
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LawyerProfileScreen(lawyer: lawyer)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text("Voir profil", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blueGrey),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
        ],
      ),
    );
  }
}
