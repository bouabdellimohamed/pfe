import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AdminAccountsScreen extends StatefulWidget {
  const AdminAccountsScreen({super.key});
  @override
  State<AdminAccountsScreen> createState() => _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends State<AdminAccountsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _searchCtrl = TextEditingController();
  String _searchType = 'user'; // 'user' | 'lawyer'
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  bool _searched = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() { _loading = true; _searched = true; _results = []; });

    try {
      final collection = _searchType == 'lawyer' ? 'lawyers' : 'users';
      final nameField = _searchType == 'lawyer' ? 'name' : 'fullName';

      // Search by name prefix
      final snap = await _firestore
          .collection(collection)
          .orderBy(nameField)
          .startAt([q])
          .endAt(['$q\uf8ff'])
          .limit(20)
          .get();

      // Also search by email
      final snapEmail = await _firestore
          .collection(collection)
          .where('email', isGreaterThanOrEqualTo: q)
          .where('email', isLessThanOrEqualTo: '$q\uf8ff')
          .limit(10)
          .get();

      final allDocs = {...snap.docs, ...snapEmail.docs}.toList();

      setState(() {
        _results = allDocs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          return {'id': d.id, 'collection': collection, ...data};
        }).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteAccount(String collection, String docId, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 8),
          Text('Supprimer le compte', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Vous allez supprimer le compte de:', style: GoogleFonts.poppins(fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
            child: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.red.shade700)),
          ),
          const SizedBox(height: 10),
          Text('Cette action est irréversible.', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer définitivement', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      // Delete Firestore document
      await _firestore.collection(collection).doc(docId).delete();

      // Delete related notifications
      final notifSnap = await _firestore.collection('notifications').where('userId', isEqualTo: docId).get();
      for (final doc in notifSnap.docs) { await doc.reference.delete(); }

      // Remove from local results
      setState(() => _results.removeWhere((r) => r['id'] == docId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Compte de $name supprimé avec succès'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleBan(String collection, String docId, bool isBanned, String name) async {
    try {
      await _firestore.collection(collection).doc(docId).update({
        'isBanned': !isBanned,
        if (!isBanned) 'bannedAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        final idx = _results.indexWhere((r) => r['id'] == docId);
        if (idx != -1) _results[idx]['isBanned'] = !isBanned;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(!isBanned ? '$name a été banni' : 'Bannissement levé pour $name'),
          backgroundColor: !isBanned ? Colors.orange : Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(children: [
            // Type selector
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _searchType = 'user'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _searchType == 'user' ? AppColors.primary : Colors.grey.shade100,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                      border: Border.all(color: _searchType == 'user' ? AppColors.primary : Colors.grey.shade300),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.person_rounded, size: 18, color: _searchType == 'user' ? Colors.white : Colors.grey),
                      const SizedBox(width: 6),
                      Text('Clients', style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: _searchType == 'user' ? Colors.white : Colors.grey.shade700,
                      )),
                    ]),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _searchType = 'lawyer'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _searchType == 'lawyer' ? AppColors.primary : Colors.grey.shade100,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                      border: Border.all(color: _searchType == 'lawyer' ? AppColors.primary : Colors.grey.shade300),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.gavel_rounded, size: 18, color: _searchType == 'lawyer' ? Colors.white : Colors.grey),
                      const SizedBox(width: 6),
                      Text('Avocats', style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: _searchType == 'lawyer' ? Colors.white : Colors.grey.shade700,
                      )),
                    ]),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            // Search field
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom ou email...',
                    hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _search,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Chercher', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ]),
          ]),
        ),
        const Divider(height: 1),
        // Results
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : !_searched
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.manage_accounts_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Recherchez un compte', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('par nom ou email', style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13)),
                      ]),
                    )
                  : _results.isEmpty
                      ? Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('Aucun résultat trouvé', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                          ]),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _results.length,
                          itemBuilder: (context, i) {
                            final r = _results[i];
                            final docId = r['id'] as String;
                            final collection = r['collection'] as String;
                            final isLawyer = collection == 'lawyers';
                            final name = isLawyer ? (r['name'] ?? 'N/A') : (r['fullName'] ?? 'N/A');
                            final email = r['email'] ?? '';
                            final isBanned = r['isBanned'] == true;
                            final isVerified = r['isVerified'] == true;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: isBanned ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: (isLawyer ? Colors.indigo : Colors.teal).withOpacity(0.12),
                                      child: Icon(
                                        isLawyer ? Icons.gavel_rounded : Icons.person_rounded,
                                        color: isLawyer ? Colors.indigo : Colors.teal, size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Row(children: [
                                          Expanded(
                                            child: Text(name,
                                                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
                                                maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ),
                                          if (isVerified)
                                            const Icon(Icons.verified_rounded, color: Colors.blue, size: 16),
                                          if (isBanned)
                                            const Icon(Icons.block_rounded, color: Colors.red, size: 16),
                                        ]),
                                        Text(isLawyer ? 'Avocat' : 'Client',
                                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                                        if (email.isNotEmpty)
                                          Text(email,
                                              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
                                              maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ]),
                                    ),
                                  ]),
                                  if (isLawyer && r['speciality'] != null) ...[
                                    const SizedBox(height: 6),
                                    Text('Spécialité: ${r['speciality']}',
                                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _toggleBan(collection, docId, isBanned, name),
                                        icon: Icon(isBanned ? Icons.lock_open_rounded : Icons.block_rounded, size: 15),
                                        label: Text(isBanned ? 'Débannir' : 'Bannir',
                                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: isBanned ? Colors.green : Colors.orange,
                                          side: BorderSide(color: isBanned ? Colors.green.shade300 : Colors.orange.shade300),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _deleteAccount(collection, docId, name),
                                        icon: const Icon(Icons.delete_outline_rounded, size: 15),
                                        label: Text('Supprimer', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      ],
    );
  }
}
