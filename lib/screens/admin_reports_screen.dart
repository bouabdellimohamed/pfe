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
  String _filter = 'all';

  Color _statusColor(String status) {
    switch (status) {
      case 'reviewed':
        return const Color(0xFF16A34A);
      case 'dismissed':
        return const Color(0xFF94A3B8);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'reviewed':
        return 'Traité';
      case 'dismissed':
        return 'Rejeté';
      default:
        return 'En attente';
    }
  }

  IconData _roleIcon(String role) =>
      role == 'lawyer' ? Icons.gavel_rounded : Icons.person_rounded;

  Color _roleColor(String role) =>
      role == 'lawyer' ? Colors.indigo : Colors.teal;

  Future<void> _updateStatus(String docId, String status) async {
    await _firestore
        .collection('reports')
        .doc(docId)
        .update({'status': status});
    if (mounted) {
      _showSnack('Statut mis à jour : $status', const Color(0xFF16A34A));
    }
  }

  Future<void> _deleteReport(String docId, {BuildContext? sheetCtx}) async {
    final confirmed = await _confirmDialog(
      title: 'Supprimer le signalement',
      body: 'Cette action est irréversible. Continuer ?',
      confirmLabel: 'Supprimer',
      confirmColor: Colors.red,
    );
    if (confirmed != true) return;
    await _firestore.collection('reports').doc(docId).delete();
    if (sheetCtx != null && sheetCtx.mounted) Navigator.pop(sheetCtx);
    if (mounted) _showSnack('Signalement supprimé', Colors.red);
  }

  Future<void> _deleteContent({
    required String contentId,
    required String contentType,
    required String reportId,
    required BuildContext sheetCtx,
  }) async {
    final collection =
        contentType == 'consultation' ? 'consultations' : 'requests';
    final label =
        contentType == 'consultation' ? 'la consultation' : 'la demande';

    final confirmed = await _confirmDialog(
      title: 'Supprimer $label',
      body: 'Le contenu sera définitivement supprimé. Continuer ?',
      confirmLabel: 'Supprimer',
      confirmColor: Colors.red,
    );
    if (confirmed != true) return;

    await _firestore.collection(collection).doc(contentId).delete();
    await _firestore
        .collection('reports')
        .doc(reportId)
        .update({'status': 'reviewed'});

    if (sheetCtx.mounted) Navigator.pop(sheetCtx);
    if (mounted) _showSnack('Contenu supprimé avec succès', Colors.red);
  }

  Future<void> _banUser({
    required String userId,
    required String role,
    required bool currentlyBanned,
    required BuildContext sheetCtx,
  }) async {
    final action = currentlyBanned ? 'Débloquer' : 'Bloquer';
    final confirmed = await _confirmDialog(
      title: '$action l\'utilisateur',
      body: currentlyBanned
          ? 'Cet utilisateur sera débloqué et pourra utiliser la plateforme.'
          : 'Cet utilisateur sera bloqué et ne pourra plus utiliser la plateforme.',
      confirmLabel: action,
      confirmColor: currentlyBanned ? const Color(0xFF16A34A) : Colors.red,
    );
    if (confirmed != true) return;

    final collection = role == 'lawyer' ? 'lawyers' : 'users';
    await _firestore.collection(collection).doc(userId).update({
      'isBanned': !currentlyBanned,
      if (!currentlyBanned) 'bannedAt': FieldValue.serverTimestamp(),
    });

    if (sheetCtx.mounted) Navigator.pop(sheetCtx);
    if (mounted) {
      _showSnack(
        currentlyBanned ? 'Utilisateur débloqué' : 'Utilisateur bloqué',
        currentlyBanned ? const Color(0xFF16A34A) : Colors.red,
      );
    }
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 16)),
          content: Text(body, style: GoogleFonts.poppins(fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Annuler',
                  style: GoogleFonts.poppins(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmLabel,
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(msg, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<Map<String, dynamic>?> _fetchRelatedContent(
      String? id, String? type) async {
    if (id == null || id.isEmpty || type == null || type.isEmpty) return null;
    final collection = type == 'consultation' ? 'consultations' : 'requests';
    final doc = await _firestore.collection(collection).doc(id).get();
    if (!doc.exists) return null;
    return {'id': doc.id, 'type': type, ...doc.data()!};
  }

  Future<Map<String, dynamic>?> _fetchReportedUser(
      String? userId, String? role) async {
    if (userId == null || userId.isEmpty) return null;
    final collection = role == 'lawyer' ? 'lawyers' : 'users';
    final doc = await _firestore.collection(collection).doc(userId).get();
    if (!doc.exists) return null;
    // Count how many reports this user has
    final reportsSnap = await _firestore
        .collection('reports')
        .where('reportedUserId', isEqualTo: userId)
        .get();
    return {
      'id': doc.id,
      'role': role,
      'reportCount': reportsSnap.docs.length,
      ...doc.data()!
    };
  }

  Future<Map<String, dynamic>?> _fetchReporterUser(String? userId) async {
    if (userId == null || userId.isEmpty) return null;
    // Try users collection first
    var doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) return {'id': doc.id, 'role': 'user', ...doc.data()!};
    // Try lawyers collection
    doc = await _firestore.collection('lawyers').doc(userId).get();
    if (doc.exists) return {'id': doc.id, 'role': 'lawyer', ...doc.data()!};
    return null;
  }

  void _showReportDetails(Map<String, dynamic> d, String reportId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _ReportDetailSheet(
        reportData: d,
        reportId: reportId,
        fetchContent: () => _fetchRelatedContent(
          d['relatedContentId'] as String?,
          d['relatedContentType'] as String?,
        ),
        fetchReportedUser: () => _fetchReportedUser(
          d['reportedUserId'] as String?,
          d['reportedUserRole'] as String?,
        ),
        fetchReporter: () => _fetchReporterUser(d['reporterUserId'] as String?),
        onUpdateStatus: (s) => _updateStatus(reportId, s),
        onDeleteReport: () => _deleteReport(reportId, sheetCtx: sheetCtx),
        onDeleteContent: (contentId, contentType) => _deleteContent(
          contentId: contentId,
          contentType: contentType,
          reportId: reportId,
          sheetCtx: sheetCtx,
        ),
        statusColor: _statusColor(d['status'] ?? 'pending'),
        statusLabel: _statusLabel(d['status'] ?? 'pending'),
        roleColor: _roleColor(d['reportedUserRole'] ?? 'user'),
        roleIcon: _roleIcon(d['reportedUserRole'] ?? 'user'),
        onBanUser: (isBanned) => _banUser(
          userId: d['reportedUserId'] as String? ?? '',
          role: d['reportedUserRole'] as String? ?? 'user',
          currentlyBanned: isBanned,
          sheetCtx: sheetCtx,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Query query =
        _firestore.collection('reports').orderBy('createdAt', descending: true);
    if (_filter != 'all') query = query.where('status', isEqualTo: _filter);

    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in ['all', 'pending', 'reviewed', 'dismissed'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        f == 'all'
                            ? 'Tous'
                            : f == 'pending'
                                ? 'En attente'
                                : f == 'reviewed'
                                    ? 'Traités'
                                    : 'Rejetés',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: AppColors.primary.withAlpha(38),
                      checkmarkColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
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
                    Icon(Icons.flag_outlined,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('Aucun signalement',
                        style: GoogleFonts.poppins(
                            color: AppColors.textSecondary, fontSize: 15)),
                  ]),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final id = docs[i].id;
                  final status = d['status'] ?? 'pending';
                  final role = d['reportedUserRole'] ?? 'user';
                  final createdAt = (d['createdAt'] as Timestamp?)?.toDate();
                  final hasContent =
                      (d['relatedContentId'] ?? '').toString().isNotEmpty;

                  return GestureDetector(
                    onTap: () => _showReportDetails(d, id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: _statusColor(status).withAlpha(77),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: _statusColor(status).withAlpha(15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                      _roleColor(role).withAlpha(30),
                                  child: Icon(_roleIcon(role),
                                      color: _roleColor(role), size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(d['reportedUserName'] ?? 'N/A',
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14)),
                                        Text(
                                            role == 'lawyer'
                                                ? 'Avocat'
                                                : 'Client',
                                            style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color:
                                                    AppColors.textSecondary)),
                                      ]),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status).withAlpha(26),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: _statusColor(status)
                                            .withAlpha(102)),
                                  ),
                                  child: Text(_statusLabel(status),
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: _statusColor(status))),
                                ),
                              ]),
                              const SizedBox(height: 10),
                              _infoRow(
                                  Icons.flag_rounded,
                                  'Raison : ${d['reason'] ?? '-'}',
                                  Colors.red.shade400),
                              if ((d['details'] ?? '').toString().isNotEmpty)
                                _infoRow(
                                    Icons.comment_outlined,
                                    d['details'].toString(),
                                    Colors.grey.shade600),
                              if (createdAt != null)
                                _infoRow(
                                    Icons.access_time_rounded,
                                    '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                    Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Row(children: [
                                if (hasContent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.blue.shade100),
                                    ),
                                    child: Row(children: [
                                      Icon(Icons.attach_file_rounded,
                                          size: 11,
                                          color: Colors.blue.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        d['relatedContentType'] ==
                                                'consultation'
                                            ? 'Consultation liée'
                                            : 'Demande liée',
                                        style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.blue.shade600,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ]),
                                  ),
                                const Spacer(),
                                Text('Voir les détails →',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600)),
                              ]),
                            ]),
                      ),
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
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// Report Detail Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════

class _ReportDetailSheet extends StatefulWidget {
  final Map<String, dynamic> reportData;
  final String reportId;
  final Future<Map<String, dynamic>?> Function() fetchContent;
  final Future<Map<String, dynamic>?> Function() fetchReportedUser;
  final Future<Map<String, dynamic>?> Function() fetchReporter;
  final Future<void> Function(String status) onUpdateStatus;
  final Future<void> Function() onDeleteReport;
  final Future<void> Function(String contentId, String contentType)
      onDeleteContent;
  final Color statusColor;
  final String statusLabel;
  final Color roleColor;
  final IconData roleIcon;
  final Future<void> Function(bool currentlyBanned) onBanUser;

  const _ReportDetailSheet({
    required this.reportData,
    required this.reportId,
    required this.fetchContent,
    required this.fetchReportedUser,
    required this.fetchReporter,
    required this.onUpdateStatus,
    required this.onDeleteReport,
    required this.onDeleteContent,
    required this.statusColor,
    required this.statusLabel,
    required this.roleColor,
    required this.roleIcon,
    required this.onBanUser,
  });

  @override
  State<_ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends State<_ReportDetailSheet> {
  Map<String, dynamic>? _content;
  Map<String, dynamic>? _reportedUser;
  Map<String, dynamic>? _reporter;
  bool _loadingContent = false;
  bool _loadingUser = false;
  bool _loadingReporter = false;
  bool _actionLoading = false;

  static const Color _primary = Color(0xFF0052D4);
  static const Color _danger = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _loadContent();
    _loadReportedUser();
    _loadReporter();
  }

  Future<void> _loadContent() async {
    setState(() => _loadingContent = true);
    try {
      final result = await widget.fetchContent();
      if (mounted) setState(() => _content = result);
    } finally {
      if (mounted) setState(() => _loadingContent = false);
    }
  }

  Future<void> _loadReportedUser() async {
    setState(() => _loadingUser = true);
    try {
      final result = await widget.fetchReportedUser();
      if (mounted) setState(() => _reportedUser = result);
    } finally {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  Future<void> _loadReporter() async {
    setState(() => _loadingReporter = true);
    try {
      final result = await widget.fetchReporter();
      if (mounted) setState(() => _reporter = result);
    } finally {
      if (mounted) setState(() => _loadingReporter = false);
    }
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _actionLoading = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.reportData;
    final status = d['status'] ?? 'pending';
    final role = d['reportedUserRole'] ?? 'user';
    final createdAt = (d['createdAt'] as Timestamp?)?.toDate();
    final hasContent = (d['relatedContentId'] ?? '').toString().isNotEmpty;
    final contentType = d['relatedContentType'] as String? ?? '';

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Header card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 10,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: widget.roleColor.withAlpha(30),
                    shape: BoxShape.circle),
                child: Icon(widget.roleIcon, color: widget.roleColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['reportedUserName'] ?? 'N/A',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: const Color(0xFF1E293B))),
                      Text(
                          role == 'lawyer'
                              ? 'Avocat signalé'
                              : 'Client signalé',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ]),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.statusColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: widget.statusColor.withAlpha(102)),
                ),
                child: Text(widget.statusLabel,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: widget.statusColor)),
              ),
            ]),
          ),

          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Report info card
                    _sectionCard(
                      icon: Icons.flag_rounded,
                      iconColor: _danger,
                      title: 'Détails du signalement',
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _detailRow('Raison', d['reason'] ?? '-',
                                Icons.report_gmailerrorred_rounded, _danger),
                            if ((d['details'] ?? '').toString().isNotEmpty)
                              _detailRow('Commentaire', d['details'].toString(),
                                  Icons.comment_rounded, Colors.grey.shade600),
                            if (createdAt != null)
                              _detailRow(
                                  'Date',
                                  '${createdAt.day}/${createdAt.month}/${createdAt.year}  ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                                  Icons.access_time_rounded,
                                  Colors.grey.shade500),
                            _detailRow('ID', widget.reportId, Icons.tag_rounded,
                                Colors.grey.shade400),
                          ]),
                    ),

                    const SizedBox(height: 12),

                    // ── Reporter (who filed the report) card
                    _sectionCard(
                      icon: Icons.campaign_rounded,
                      iconColor: const Color(0xFFD97706),
                      title: 'Signalé par',
                      trailing: _loadingReporter
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Color(0xFFD97706)))
                          : null,
                      child: _loadingReporter
                          ? const SizedBox(height: 8)
                          : _reporter == null
                              ? _userNotFound()
                              : _reporterDetails(_reporter!),
                    ),

                    const SizedBox(height: 12),

                    // ── Reported user profile card
                    _sectionCard(
                      icon: role == 'lawyer'
                          ? Icons.gavel_rounded
                          : Icons.person_rounded,
                      iconColor: role == 'lawyer' ? Colors.indigo : Colors.teal,
                      title: role == 'lawyer'
                          ? 'Profil de l\'avocat signalé'
                          : 'Profil du client signalé',
                      trailing: _loadingUser
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _primary))
                          : null,
                      child: _loadingUser
                          ? const SizedBox(height: 8)
                          : _reportedUser == null
                              ? _userNotFound()
                              : _reportedUserDetails(_reportedUser!),
                    ),

                    const SizedBox(height: 12),

                    // ── Related content card
                    if (hasContent)
                      _sectionCard(
                        icon: contentType == 'consultation'
                            ? Icons.question_answer_rounded
                            : Icons.assignment_rounded,
                        iconColor: _primary,
                        title: contentType == 'consultation'
                            ? 'Consultation signalée'
                            : 'Demande signalée',
                        trailing: _loadingContent
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _primary))
                            : null,
                        child: _loadingContent
                            ? const SizedBox(height: 8)
                            : _content == null
                                ? _contentNotFound()
                                : _contentDetails(_content!),
                      ),

                    const SizedBox(height: 16),
                  ]),
            ),
          ),

          // Action buttons
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 12,
                    offset: const Offset(0, -4))
              ],
            ),
            child: _actionLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: _primary),
                    ),
                  )
                : Column(mainAxisSize: MainAxisSize.min, children: [
                    if (status == 'pending') ...[
                      Row(children: [
                        Expanded(
                          child: _actionButton(
                            label: 'Rejeter',
                            icon: Icons.close_rounded,
                            color: Colors.grey.shade700,
                            bgColor: Colors.grey.shade100,
                            onTap: () => _runAction(
                                () => widget.onUpdateStatus('dismissed')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _actionButton(
                            label: 'Marquer traité',
                            icon: Icons.check_rounded,
                            color: const Color(0xFF16A34A),
                            bgColor: const Color(0xFFDCFCE7),
                            onTap: () => _runAction(
                                () => widget.onUpdateStatus('reviewed')),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                    ],
                    if (hasContent && _content != null) ...[
                      _actionButton(
                        label: contentType == 'consultation'
                            ? 'Supprimer la consultation'
                            : 'Supprimer la demande',
                        icon: Icons.delete_sweep_rounded,
                        color: Colors.white,
                        bgColor: _danger,
                        full: true,
                        onTap: () => _runAction(() => widget.onDeleteContent(
                            d['relatedContentId'] as String, contentType)),
                      ),
                      const SizedBox(height: 10),
                    ],
                    _actionButton(
                      label: 'Supprimer le signalement',
                      icon: Icons.delete_outline_rounded,
                      color: _danger,
                      bgColor: const Color(0xFFFEE2E2),
                      full: true,
                      onTap: () => _runAction(widget.onDeleteReport),
                    ),
                    const SizedBox(height: 10),
                    // Ban / Unban button
                    Builder(builder: (_) {
                      final isBanned = _reportedUser?['isBanned'] == true;
                      return _actionButton(
                        label: isBanned ? 'Débloquer l\'utilisateur' : 'Bloquer l\'utilisateur',
                        icon: isBanned ? Icons.lock_open_rounded : Icons.block_rounded,
                        color: Colors.white,
                        bgColor: isBanned ? const Color(0xFF16A34A) : const Color(0xFF1E293B),
                        full: true,
                        onTap: () => _runAction(() => widget.onBanUser(isBanned)),
                      );
                    }),
                  ]),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
    Widget? trailing,
  }) =>
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: iconColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: const Color(0xFF1E293B))),
              ),
              if (trailing != null) trailing,
            ]),
          ),
          const Divider(height: 20, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: child,
          ),
        ]),
      );

  Widget _detailRow(String label, String value, IconData icon, Color color) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: '$label : ',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500),
                ),
                TextSpan(
                  text: value,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF334155)),
                ),
              ]),
            ),
          ),
        ]),
      );

  Widget _contentDetails(Map<String, dynamic> content) {
    final type = content['type'] as String? ?? '-';
    final title = content['title'] as String? ??
        content['description'] as String? ??
        content['question'] as String? ??
        'Sans titre';
    final createdAt = (content['createdAt'] as Timestamp?)?.toDate();
    final status = content['status'] as String? ?? '-';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _primary.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(type,
            style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w700, color: _primary)),
      ),
      const SizedBox(height: 10),
      Text(title,
          style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B)),
          maxLines: 4,
          overflow: TextOverflow.ellipsis),
      const SizedBox(height: 10),
      if (createdAt != null)
        _detailRow(
            'Créé le',
            '${createdAt.day}/${createdAt.month}/${createdAt.year}',
            Icons.calendar_today_rounded,
            Colors.grey.shade400),
      _detailRow(
          'Statut', status, Icons.info_outline_rounded, Colors.grey.shade400),
      _detailRow(
          'ID', content['id'] ?? '-', Icons.tag_rounded, Colors.grey.shade400),
      Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _danger.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _danger.withAlpha(51)),
        ),
        child: Row(children: [
          Icon(Icons.warning_amber_rounded,
              size: 15, color: _danger.withAlpha(204)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'La suppression de ce contenu est définitive et ne peut pas être annulée.',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: _danger.withAlpha(230), height: 1.4),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _reportedUserDetails(Map<String, dynamic> user) {
    final isLawyer = user['role'] == 'lawyer';
    final name =
        user['name'] as String? ?? user['fullName'] as String? ?? 'N/A';
    final email = user['email'] as String? ?? '-';
    final phone =
        user['phone'] as String? ?? user['phoneNumber'] as String? ?? '-';
    final wilaya = user['wilaya'] as String? ?? '-';
    final isBanned = user['isBanned'] == true;
    final reportCount = user['reportCount'] as int? ?? 0;
    final status = user['status'] as String? ?? '-';
    final speciality = user['speciality'] as String? ?? '';
    final experience = user['experience'];
    final rating = user['rating'];

    final Color banColor = isBanned ? _danger : const Color(0xFF16A34A);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Ban status + report count badges
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: banColor.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: banColor.withAlpha(77)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(isBanned ? Icons.block_rounded : Icons.check_circle_rounded,
                size: 13, color: banColor),
            const SizedBox(width: 4),
            Text(isBanned ? 'Banni' : 'Actif',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: banColor)),
          ]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: reportCount >= 3
                ? _danger.withAlpha(20)
                : Colors.orange.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: reportCount >= 3
                    ? _danger.withAlpha(77)
                    : Colors.orange.withAlpha(77)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.flag_rounded,
                size: 13, color: reportCount >= 3 ? _danger : Colors.orange),
            const SizedBox(width: 4),
            Text('$reportCount signalement${reportCount > 1 ? 's' : ''}',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: reportCount >= 3 ? _danger : Colors.orange)),
          ]),
        ),
      ]),
      const SizedBox(height: 12),

      _detailRow('Nom', name, Icons.person_rounded, const Color(0xFF334155)),
      _detailRow('Email', email, Icons.email_rounded, Colors.grey.shade500),
      _detailRow('Téléphone', phone, Icons.phone_rounded, Colors.grey.shade500),
      _detailRow(
          'Wilaya', wilaya, Icons.location_on_rounded, Colors.grey.shade500),

      if (isLawyer) ...[
        if (speciality.isNotEmpty)
          _detailRow(
              'Spécialité', speciality, Icons.category_rounded, _primary),
        if (experience != null)
          _detailRow('Expérience', '$experience ans',
              Icons.work_history_rounded, Colors.grey.shade500),
        if (rating != null)
          _detailRow('Note', '${(rating as num).toStringAsFixed(1)} / 5',
              Icons.star_rounded, const Color(0xFFF59E0B)),
        _detailRow('Statut du compte', status, Icons.verified_rounded,
            Colors.grey.shade500),
      ],

      _detailRow(
          'ID', user['id'] ?? '-', Icons.tag_rounded, Colors.grey.shade400),
    ]);
  }

  Widget _reporterDetails(Map<String, dynamic> user) {
    final isLawyer = user['role'] == 'lawyer';
    final name =
        user['name'] as String? ?? user['fullName'] as String? ?? 'N/A';
    final email = user['email'] as String? ?? '-';
    final phone =
        user['phone'] as String? ?? user['phoneNumber'] as String? ?? '-';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Role badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: (isLawyer ? Colors.indigo : Colors.teal).withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: (isLawyer ? Colors.indigo : Colors.teal).withAlpha(77)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(isLawyer ? Icons.gavel_rounded : Icons.person_rounded,
              size: 13, color: isLawyer ? Colors.indigo : Colors.teal),
          const SizedBox(width: 4),
          Text(isLawyer ? 'Avocat' : 'Client',
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isLawyer ? Colors.indigo : Colors.teal)),
        ]),
      ),
      const SizedBox(height: 12),

      _detailRow('Nom', name, Icons.person_rounded, const Color(0xFF334155)),
      _detailRow('Email', email, Icons.email_rounded, Colors.grey.shade500),
      _detailRow('Téléphone', phone, Icons.phone_rounded, Colors.grey.shade500),
      _detailRow(
          'ID', user['id'] ?? '-', Icons.tag_rounded, Colors.grey.shade400),
    ]);
  }

  Widget _userNotFound() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(Icons.person_off_rounded, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Text('Profil introuvable ou supprimé.',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey.shade500)),
        ]),
      );

  Widget _contentNotFound() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(Icons.search_off_rounded, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Text('Contenu introuvable ou déjà supprimé.',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey.shade500)),
        ]),
      );

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
    bool full = false,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: full ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 13, color: color)),
          ]),
        ),
      );
}
