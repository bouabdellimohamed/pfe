import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});
  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _filter = 'all'; // all | pending | reviewed | dismissed

  Future<void> _updateStatus(String docId, String status) async {
    await _firestore.collection('reports').doc(docId).update({'status': status});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Statut mis à jour: $status'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _deleteReport(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer le signalement', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Voulez-vous supprimer ce signalement ?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _firestore.collection('reports').doc(docId).delete();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'reviewed': return Colors.green;
      case 'dismissed': return Colors.grey;
      default: return Colors.orange;
    }
  }

  IconData _roleIcon(String role) => role == 'lawyer' ? Icons.gavel_rounded : Icons.person_rounded;

  @override
  Widget build(BuildContext context) {
    Query query = _firestore.collection('reports').orderBy('createdAt', descending: true);
    if (_filter != 'all') query = query.where('status', isEqualTo: _filter);

    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in ['all', 'pending', 'reviewed', 'dismissed'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        f == 'all' ? 'Tous' : f == 'pending' ? 'En attente' : f == 'reviewed' ? 'Traités' : 'Rejetés',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: AppColors.primary.withOpacity(0.15),
                      checkmarkColor: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.flag_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text('Aucun signalement', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                  ]),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final id = docs[i].id;
                  final status = d['status'] ?? 'pending';
                  final reportedRole = d['reportedUserRole'] ?? 'user';
                  final createdAt = (d['createdAt'] as Timestamp?)?.toDate();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: _statusColor(status).withOpacity(0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: (reportedRole == 'lawyer' ? Colors.indigo : Colors.teal).withOpacity(0.12),
                            child: Icon(_roleIcon(reportedRole),
                                color: reportedRole == 'lawyer' ? Colors.indigo : Colors.teal, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(d['reportedUserName'] ?? 'N/A',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
                              Text(reportedRole == 'lawyer' ? 'Avocat' : 'Client',
                                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                            ]),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _statusColor(status).withOpacity(0.4)),
                            ),
                            child: Text(
                              status == 'pending' ? 'En attente' : status == 'reviewed' ? 'Traité' : 'Rejeté',
                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(status)),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        _infoRow(Icons.flag_rounded, 'Raison: ${d['reason'] ?? '-'}', Colors.red.shade400),
                        if (d['details'] != null && d['details'].toString().isNotEmpty)
                          _infoRow(Icons.comment_outlined, 'Détails: ${d['details']}', Colors.grey.shade600),
                        if (d['relatedContentType'] != null)
                          _infoRow(Icons.link_rounded, 'Contenu: ${d['relatedContentType']}', Colors.blue.shade400),
                        if (createdAt != null)
                          _infoRow(Icons.access_time_rounded,
                              '${createdAt.day}/${createdAt.month}/${createdAt.year}', Colors.grey.shade500),
                        const SizedBox(height: 10),
                        Row(children: [
                          if (status == 'pending') ...[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _updateStatus(id, 'dismissed'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey.shade700,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text('Rejeter', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _updateStatus(id, 'reviewed'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text('Traiter', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                            onPressed: () => _deleteReport(id),
                            tooltip: 'Supprimer',
                          ),
                        ]),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade800), maxLines: 2, overflow: TextOverflow.ellipsis)),
        ]),
      );
}
