import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import '../models/consultation_model.dart';

///  Écran de détail d'une consultation (avec toutes les réponses)
class ConsultationDetailScreen extends StatelessWidget {
  final ConsultationModel consultation;

  const ConsultationDetailScreen({super.key, required this.consultation});

  @override
  Widget build(BuildContext context) {
    final answered = consultation.status == 'answered';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0052D4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'consultation_detail'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //  Carte Question 
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0052D4).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          consultation.type.tr(),
                          style: const TextStyle(
                            color: Color(0xFF0052D4),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _StatusBadge(answered: answered),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'question_label'.tr(),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    consultation.question,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 15,
                      height: 1.7,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  //  Fichier joint 
                  if (consultation.attachedFileName != null &&
                      consultation.attachedFileBase64 != null) ...[
                    const SizedBox(height: 16),
                    _AttachedFileWidget(
                      fileName: consultation.attachedFileName!,
                      fileBase64: consultation.attachedFileBase64!,
                    ),
                  ],

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(consultation.createdAt),
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section Réponses
            if (consultation.answers.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.gavel_rounded, color: Color(0xFF0052D4), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'answers_label'.tr(
                      namedArgs: {'count': consultation.answers.length.toString()},
                    ),
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...consultation.answers
                  .asMap()
                  .entries
                  .map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _AnswerCard(
                          answer: entry.value,
                          index: entry.key + 1,
                        ),
                      ))
                  .toList(),
            ] else if (answered) ...[
              
              Row(
                children: [
                  const Icon(Icons.gavel_rounded, color: Color(0xFF0052D4), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'lawyer_answer'.tr(),
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0052D4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.gavel_rounded, size: 12, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          consultation.lawyerName ?? 'Avocat',
                          style: const TextStyle(
                            color: Color(0xFF0052D4),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      consultation.answer ?? '',
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Aucune réponse encore
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.hourglass_top_rounded,
                          size: 48, color: Color(0xFFD97706)),
                      const SizedBox(height: 12),
                      Text(
                        'waiting_for_answer'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFD97706),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'lawyers_will_answer_soon'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

//  Widget Carte Réponse 
class _AnswerCard extends StatelessWidget {
  final ConsultationAnswer answer;
  final int index;

  const _AnswerCard({required this.answer, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0EAFF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0052D4).withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avocat
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F7FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
              border: Border(bottom: BorderSide(color: Color(0xFFE0EAFF))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0052D4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.gavel_rounded, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    answer.lawyerName,
                    style: const TextStyle(
                      color: Color(0xFF0052D4),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0052D4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'answer_number'.tr(namedArgs: {'n': index.toString()}),
                    style: const TextStyle(
                      color: Color(0xFF0052D4),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Corps de la réponse
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  answer.answer,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(answer.answeredAt),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

//  Widget Section Card 
class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

// Widget Statut 
class _StatusBadge extends StatelessWidget {
  final bool answered;
  const _StatusBadge({required this.answered});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: answered
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: answered ? const Color(0xFF16A34A) : const Color(0xFFD97706),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            answered ? Icons.check_circle_rounded : Icons.access_time_rounded,
            size: 12,
            color: answered ? const Color(0xFF16A34A) : const Color(0xFFD97706),
          ),
          const SizedBox(width: 4),
          Text(
            answered ? 'answered'.tr() : 'pending'.tr(),
            style: TextStyle(
              color: answered ? const Color(0xFF16A34A) : const Color(0xFFD97706),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

//  Widget Fichier attaché 
class _AttachedFileWidget extends StatelessWidget {
  final String fileName;
  final String fileBase64;

  const _AttachedFileWidget({required this.fileName, required this.fileBase64});

  bool get _isImage =>
      ['jpg', 'jpeg', 'png'].contains(fileName.split('.').last.toLowerCase());

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _isImage
                ? () => showDialog(
                      context: context,
                      builder: (ctx) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(base64Decode(fileBase64)),
                            ),
                            Positioned(
                              right: 10,
                              top: 10,
                              child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                : null,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0052D4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        base64Decode(fileBase64),
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.insert_drive_file_rounded,
                      color: Color(0xFF0052D4), size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fileName,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_isImage)
            const Icon(Icons.zoom_in_rounded, color: Color(0xFF0052D4), size: 20),
        ],
      ),
    );
  }
}