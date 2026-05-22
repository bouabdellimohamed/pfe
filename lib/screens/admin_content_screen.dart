import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});
  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(String collection, String docId, String label) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Supprimer "$label" ?', style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _firestore.collection(collection).doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Supprimé avec succès'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tab,
          indicatorColor: AppColors.primary,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.campaign_rounded), text: 'Publications'),
            Tab(icon: Icon(Icons.question_answer_rounded), text: 'Consultations'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [_buildPubsTab(), _buildConsultationsTab()],
          ),
        ),
      ],
    );
  }

  Widget _buildPubsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('requests').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allDocs = snap.data?.docs ?? [];
        final docs = allDocs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data.containsKey('title') || data.containsKey('description') || data.containsKey('affaireType');
        }).toList();
        
        if (docs.isEmpty) {
          return _emptyState(Icons.campaign_outlined, 'Aucune publication');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final id = docs[i].id;
            final title = d['title'] ?? d['affaireType'] ?? 'Publication';
            final desc = d['description'] ?? '';
            final userName = d['userName'] ?? d['clientName'] ?? 'Inconnu';
            final createdAt = (d['createdAt'] as Timestamp?)?.toDate();
            final domain = d['domain'] ?? d['speciality'] ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('Par: $userName',
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                      ]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                      onPressed: () => _confirmDelete('requests', id, title),
                      tooltip: 'Supprimer',
                    ),
                  ]),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(desc,
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    if (domain.isNotEmpty) _chip(Icons.category_outlined, domain, Colors.indigo),
                    if (createdAt != null)
                      _chip(Icons.calendar_today_outlined,
                          '${createdAt.day}/${createdAt.month}/${createdAt.year}', Colors.grey),
                  ]),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConsultationsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('consultations').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allDocs = snap.data?.docs ?? [];
        final docs = allDocs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data.containsKey('question');
        }).toList();
        
        if (docs.isEmpty) {
          return _emptyState(Icons.question_answer_outlined, 'Aucune consultation');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final id = docs[i].id;
            final question = d['question'] ?? d['title'] ?? 'Consultation';
            final userName = d['userName'] ?? d['clientName'] ?? 'Inconnu';
            final createdAt = (d['createdAt'] as Timestamp?)?.toDate();
            final domain = d['domain'] ?? d['speciality'] ?? '';
            final status = d['status'] ?? 'open';

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.question_answer_rounded, color: Colors.teal, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(question,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        Text('Par: $userName',
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                      ]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                      onPressed: () => _confirmDelete('consultations', id, question),
                      tooltip: 'Supprimer',
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    if (domain.isNotEmpty) _chip(Icons.category_outlined, domain, Colors.teal),
                    _chip(
                      status == 'answered' ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                      status == 'answered' ? 'Répondu' : 'En attente',
                      status == 'answered' ? Colors.green : Colors.orange,
                    ),
                    if (createdAt != null)
                      _chip(Icons.calendar_today_outlined,
                          '${createdAt.day}/${createdAt.month}/${createdAt.year}', Colors.grey),
                  ]),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyState(IconData icon, String msg) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(msg, style: GoogleFonts.poppins(color: AppColors.textSecondary)),
        ]),
      );

  Widget _chip(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ]),
      );
}
