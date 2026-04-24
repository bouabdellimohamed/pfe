import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/lawyer_model.dart';

class LawyersResultScreen extends StatelessWidget {
  final String speciality;
  final String? wilaya; // أضفنا علامة الاستهام هنا ليصبح اختيارياً

  const LawyersResultScreen({
    super.key,
    required this.speciality,
    this.wilaya, // الآن لن يظهر خط أحمر هنا
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF263238),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Experts Disponibles",
              style: TextStyle(
                color: Color(0xFF263238),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              "$speciality • $wilaya",
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('lawyers')
            .where('speciality', isEqualTo: speciality)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Erreur lors du chargement des avocats:\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final docs = snap.data?.docs ?? const [];
          var lawyers = docs
              .map((d) =>
                  LawyerModel.fromMap(d.data() as Map<String, dynamic>))
              .toList();

          if (wilaya != null && wilaya!.trim().isNotEmpty) {
            lawyers = lawyers
                .where((l) =>
                    (l.wilaya ?? '').toLowerCase() ==
                    wilaya!.trim().toLowerCase())
                .toList();
          }

          lawyers.sort((a, b) => (b.finalScore).compareTo(a.finalScore));

          if (lawyers.isEmpty) {
            return const Center(
              child: Text('Aucun avocat trouvé pour ces critères.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: lawyers.length,
            itemBuilder: (context, index) =>
                _buildPremiumLawyerCard(context, lawyers[index]),
          );
        },
      ),
    );
  }

  Widget _buildPremiumLawyerCard(BuildContext context, LawyerModel lawyer) {
    final Color primaryBlue = const Color(0xFF1565C0);

    final imageUrl = (lawyer.photoUrl != null && lawyer.photoUrl!.isNotEmpty)
        ? lawyer.photoUrl!
        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(lawyer.name)}&background=1565C0&color=ffffff';

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Row(
              children: [
                // 🖼️ الصورة الشخصية الحقيقية مع نقطة الحالة
                Stack(
                  children: [
                    Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(24),
                        image: DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(
                          color: const Color(0xFFF1F1F1),
                          width: 1.5,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 18),
                // معلومات الاسم والتخصص
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lawyer.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF263238),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lawyer.speciality,
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${lawyer.rating.toStringAsFixed(1)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            " (${lawyer.reviewCount} avis)",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // كبسولات المعلومات (الخبرة والموقع)
            Row(
              children: [
                _buildInfoTag(
                  Icons.work_history_outlined,
                  "${(lawyer.experience ?? 0)} ans",
                ),
                const SizedBox(width: 10),
                _buildInfoTag(
                  Icons.location_on_outlined,
                  (lawyer.wilaya ?? '-'),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    // الانتقال لملف المحامي
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.blueGrey),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }
}
