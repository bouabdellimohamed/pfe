import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// خدمة التبليغات (Signalement) — المحامي يبلّغ عن العميل والعكس
class SignalementService {
  static final _firestore = FirebaseFirestore.instance;

  /// الأسباب المحتملة للتبليغ
  static List<String> get reportReasons => [
    'report_reason_insults',
    'report_reason_harassment',
    'report_reason_spam',
    'report_reason_fake_profile',
    'report_reason_inappropriate',
    'report_reason_fraud',
    'report_reason_other',
  ];

  /// إرسال تبليغ إلى Firestore
  static Future<void> submitReport({
    required String reporterUserId,
    required String reportedUserId,
    required String reportedUserName,
    required String reportedUserRole, // 'user' | 'lawyer'
    required String reason,
    String? details,
    String? relatedContentId, // ID of consultation/request if applicable
    String? relatedContentType, // 'consultation' | 'request'
  }) async {
    // ✅ Check if the reporter has already reported this user
    final existingReport = await _firestore.collection('reports')
        .where('reporterUserId', isEqualTo: reporterUserId)
        .where('reportedUserId', isEqualTo: reportedUserId)
        .limit(1)
        .get();
        
    if (existingReport.docs.isNotEmpty) {
      throw 'report_already_submitted'.tr();
    }

    await _firestore.collection('reports').add({
      'reporterUserId': reporterUserId,
      'reportedUserId': reportedUserId,
      'reportedUserName': reportedUserName,
      'reportedUserRole': reportedUserRole,
      'reason': reason,
      'details': details,
      'relatedContentId': relatedContentId,
      'relatedContentType': relatedContentType,
      'status': 'pending', // pending | reviewed | dismissed
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ✅ Auto-ban logic: Ban user if they reach 5 reports
    try {
      final reportsSnapshot = await _firestore.collection('reports')
          .where('reportedUserId', isEqualTo: reportedUserId)
          .get();
          
      if (reportsSnapshot.docs.length >= 5) {
        final collectionName = reportedUserRole == 'lawyer' ? 'lawyers' : 'users';
        await _firestore.collection(collectionName).doc(reportedUserId).update({
          'isBanned': true,
          'bannedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error applying auto-ban: $e');
    }
  }

  /// عرض نافذة التبليغ
  static void showReportDialog({
    required BuildContext context,
    required String reportedUserId,
    required String reportedUserName,
    required String reportedUserRole,
    String? relatedContentId,
    String? relatedContentType,
  }) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    String? selectedReason;
    final detailsController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.flag_rounded,
                            color: Color(0xFFEF4444), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'report_title'.tr(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'report_subtitle'.tr(namedArgs: {'name': reportedUserName}),
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Reason selection
                  Text(
                    'report_reason_label'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 14),

                  ...reportReasons.map((reason) {
                    final isSelected = selectedReason == reason;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => selectedReason = reason);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEF4444).withOpacity(0.08)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFEF4444).withOpacity(0.4)
                                  : Colors.grey.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? const Color(0xFFEF4444)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFEF4444)
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check,
                                        color: Colors.white, size: 14)
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  reason.tr(),
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF334155),
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // Details field
                  Text(
                    'report_details_label'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200, width: 1.5),
                    ),
                    child: TextField(
                      controller: detailsController,
                      maxLines: 3,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF334155), height: 1.5),
                      decoration: InputDecoration(
                        hintText: 'report_details_hint'.tr(),
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('cancel'.tr(),
                              style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: isSubmitting || selectedReason == null
                              ? null
                              : () async {
                                  setState(() => isSubmitting = true);
                                  try {
                                    await submitReport(
                                      reporterUserId: currentUser.uid,
                                      reportedUserId: reportedUserId,
                                      reportedUserName: reportedUserName,
                                      reportedUserRole: reportedUserRole,
                                      reason: selectedReason!,
                                      details: detailsController.text.trim().isNotEmpty
                                          ? detailsController.text.trim()
                                          : null,
                                      relatedContentId: relatedContentId,
                                      relatedContentType: relatedContentType,
                                    );
                                    if (ctx.mounted) {
                                      Navigator.pop(ctx);
                                      HapticFeedback.mediumImpact();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.check_circle_rounded,
                                                color: Colors.white),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                  'report_submitted'.tr(),
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                        backgroundColor:
                                            const Color(0xFF16A34A),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ));
                                    }
                                  } catch (e) {
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text('error'.tr() + ': $e'),
                                        backgroundColor: Colors.red,
                                      ));
                                    }
                                  } finally {
                                    if (ctx.mounted) {
                                      setState(() => isSubmitting = false);
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            disabledBackgroundColor:
                                const Color(0xFFEF4444).withOpacity(0.4),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text('report_submit_btn'.tr(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
