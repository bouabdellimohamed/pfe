import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/consultation_model.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

class UserConsultationScreen extends StatefulWidget {
  final String uid;
  const UserConsultationScreen({super.key, required this.uid});
  @override
  State<UserConsultationScreen> createState() => _UserConsultationScreenState();
}

class _UserConsultationScreenState extends State<UserConsultationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _auth = AuthService();

  final List<String> _allSpecialities = [
    'Droit familial',
    'Droit pénal',
    'Droit commercial',
    'Droit civil',
    'Droit immobilier',
    'Droit administratif',
    'Droit du travail',
    'Droit des sociétés',
    'Droit fiscal',
    'Droit constitutionnel'
  ];

  String? _selectedSpeciality;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0052D4) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF0052D4) : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: selected
              ? [BoxShadow(color: const Color(0xFF0052D4).withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Text(
          label.tr(),
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade700,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 20,
                right: 20,
                bottom: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0052D4), Color(0xFF4364F7), Color(0xFF6FB1FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF0052D4),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                  spreadRadius: -10,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'consultations'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'describe_situation'.tr(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabs,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.all(4),
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    labelColor: const Color(0xFF0052D4),
                    unselectedLabelColor: Colors.white.withOpacity(0.8),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    tabs: [
                      Tab(text: 'new_consultation'.tr()),
                      Tab(text: 'history'.tr()),
                      Tab(text: 'shares'.tr()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _NewConsultationForm(uid: widget.uid, auth: _auth, allSpecialities: _allSpecialities),
                _ConsultationHistory(uid: widget.uid, auth: _auth),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 0, 12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _filterChip('Tous', _selectedSpeciality == null, () {
                              setState(() => _selectedSpeciality = null);
                            }),
                            ..._allSpecialities.map((s) {
                              final isSelected = _selectedSpeciality == s;
                              return _filterChip(s, isSelected, () {
                                setState(() => _selectedSpeciality = isSelected ? null : s);
                              });
                            }),
                            const SizedBox(width: 20),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: _SharedConsultations(
                        uid: widget.uid,
                        auth: _auth,
                        selectedSpeciality: _selectedSpeciality,
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
}

class _NewConsultationForm extends StatefulWidget {
  final String uid;
  final AuthService auth;
  final List<String> allSpecialities;

  const _NewConsultationForm({
    required this.uid,
    required this.auth,
    required this.allSpecialities,
  });
  @override
  State<_NewConsultationForm> createState() => _NewConsultationFormState();
}

class _NewConsultationFormState extends State<_NewConsultationForm> {
  final _questionCtrl = TextEditingController();
  String? _type;
  bool _loading = false;
  PlatformFile? _attachedFile;

  Future<void> _pickFile() async {
    HapticFeedback.lightImpact();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png', 'jpeg'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final extension = file.extension?.toLowerCase() ?? '';
      final isImage = ['jpg', 'jpeg', 'png'].contains(extension);

      Uint8List? finalBytes = file.bytes;
      String fileName = file.name;

      if (isImage) {
        if (file.size > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('file_too_large_msg'.tr(namedArgs: {'size': '5MB'}))),
            );
          }
          return;
        }

        if (file.bytes != null) {
          final image = img.decodeImage(file.bytes!);
          if (image != null) {
            img.Image resized = image;
            if (image.width > 1200 || image.height > 1200) {
              resized = img.copyResize(image, width: image.width > image.height ? 1200 : null, height: image.height > image.width ? 1200 : null);
            }
            finalBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 70));
            if (!fileName.toLowerCase().endsWith('.jpg')) {
              fileName = fileName.split('.').first + '.jpg';
            }
          }
        }
      } else {
        if (file.size > 700 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('file_too_large_msg'.tr(namedArgs: {'size': '700KB'}))),
            );
          }
          return;
        }
      }

      setState(() => _attachedFile = PlatformFile(
        name: fileName,
        size: finalBytes?.length ?? 0,
        bytes: finalBytes,
      ));
    }
  }

  void _removeFile() {
    HapticFeedback.lightImpact();
    setState(() => _attachedFile = null);
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_type == null || _questionCtrl.text.trim().length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('choose_type_and_length'.tr()),
          backgroundColor: Colors.orange));
      return;
    }
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final profile = await widget.auth.getUserProfile(widget.uid);
      await widget.auth.createConsultation(
        userId: widget.uid,
        userFullName: profile?.fullName ?? user?.displayName ?? 'lawyer'.tr(),
        type: _type!,
        question: _questionCtrl.text.trim(),
        attachedFileName: _attachedFile?.name,
        attachedFileBase64: _attachedFile?.bytes != null ? base64Encode(_attachedFile!.bytes!) : null,
      );
      if (!mounted) return;
      _questionCtrl.clear();
      setState(() {
        _type = null;
        _attachedFile = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('consultation_sent'.tr()),
          backgroundColor: Color(0xFF2E7D32)));
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('invalid-argument')) {
          errorMsg = 'error_file_too_large_storage'.tr();
        }
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('legal_specialty'.tr(),
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: widget.allSpecialities.length,
              itemBuilder: (ctx, i) {
                final t = widget.allSpecialities[i];
                final sel = _type == t;
                
                IconData icon;
                Color color;
                switch (t) {
                  case 'Droit familial': icon = Icons.family_restroom_rounded; color = const Color(0xFF0052D4); break;
                  case 'Droit pénal': icon = Icons.gavel_rounded; color = const Color(0xFFEF4444); break;
                  case 'Droit commercial': icon = Icons.business_center_rounded; color = const Color(0xFF0F766E); break;
                  case 'Droit civil': icon = Icons.account_balance_rounded; color = const Color(0xFF7C3AED); break;
                  case 'Droit du travail': icon = Icons.work_rounded; color = const Color(0xFFF59E0B); break;
                  case 'Droit immobilier': icon = Icons.home_work_rounded; color = const Color(0xFF0369A1); break;
                  case 'Droit administratif': icon = Icons.corporate_fare_rounded; color = const Color(0xFF059669); break;
                  case 'Droit des sociétés': icon = Icons.domain_rounded; color = const Color(0xFF0052D4); break;
                  case 'Droit fiscal': icon = Icons.request_quote_rounded; color = const Color(0xFF7C3AED); break;
                  case 'Droit constitutionnel': icon = Icons.account_balance_rounded; color = const Color(0xFF0F766E); break;
                  default: icon = Icons.balance_rounded; color = const Color(0xFF0052D4); break;
                }

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _type = t);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: 130,
                    margin: const EdgeInsets.only(right: 14, bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFF0052D4) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? const Color(0xFF0052D4) : Colors.grey.shade200,
                        width: 1.5,
                      ),
                      boxShadow: sel
                          ? [BoxShadow(color: const Color(0xFF0052D4).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                          : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: sel ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: sel ? Colors.white : color, size: 24),
                        ),
                        const Spacer(),
                        Text(
                          t.tr(),
                          maxLines: 2,
                          style: TextStyle(
                            color: sel ? Colors.white : const Color(0xFF1E293B),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          Text('detailed_question'.tr(),
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: TextField(
              controller: _questionCtrl,
              maxLines: 6,
              style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5),
              decoration: InputDecoration(
                hintText: 'describe_situation'.tr(),
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text('attached_doc_label'.tr(),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          if (_attachedFile == null)
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200, width: 1.5, style: BorderStyle.solid),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFF0052D4).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.attach_file_rounded, color: Color(0xFF0052D4), size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('add_doc_btn'.tr(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF334155))),
                          Text('max_size_limit'.tr(namedArgs: {'size': '700'}), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF0052D4).withOpacity(0.3), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF0052D4).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF0052D4), size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_attachedFile!.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${(_attachedFile!.size / 1024).toStringAsFixed(1)} KB', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: _removeFile, icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent)),
                ],
              ),
            ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0052D4),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('submit_consultation'.tr(),
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        SizedBox(width: 10),
                        Icon(Icons.send_rounded, size: 20),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ConsultationHistory extends StatelessWidget {
  final String uid;
  final AuthService auth;
  const _ConsultationHistory({required this.uid, required this.auth});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConsultationModel>>(
      stream: auth.getUserConsultations(uid),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0052D4)));
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Erreur:\n${snap.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0052D4).withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history_rounded, size: 64, color: Color(0xFF0052D4)),
                ),
                const SizedBox(height: 24),
                Text('no_history'.tr(),
                    style: const TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('your_consultations_appear_here'.tr(),
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
              ],
            ),
          );
        }
        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, i) => Dismissible(
            key: Key(list[i].id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 28),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
                  SizedBox(height: 4),
                  Text('delete'.tr(), style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            confirmDismiss: (_) async {
              HapticFeedback.mediumImpact();
              return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text('confirm_delete'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      content: Text('irreversible_action'.tr()),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text('cancel'.tr(), style: const TextStyle(color: Colors.grey))),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          child: Text('delete'.tr(), style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ) ??
                  false;
            },
            onDismissed: (_) {
              FirebaseFirestore.instance.collection('consultations').doc(list[i].id).delete();
            },
            child: _ConsultCard(c: list[i]),
          ),
        );
      },
    );
  }
}

class _ConsultCard extends StatelessWidget {
  final ConsultationModel c;
  const _ConsultCard({required this.c});

  @override
  Widget build(BuildContext context) {
    final answered = c.status == 'answered';
    final lawyerName = (c.lawyerName != null && c.lawyerName!.trim().isNotEmpty) ? c.lawyerName! : 'Avocat';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: answered ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      c.type.tr(),
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    answered ? Icons.check_circle_rounded : Icons.access_time_filled_rounded,
                    size: 16,
                    color: answered ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    answered ? 'answered'.tr() : 'pending'.tr(),
                    style: TextStyle(
                      color: answered ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            
            // Question
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.question,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 14,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  if (c.attachedFileName != null && c.attachedFileBase64 != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: const Color(0xFF0052D4).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: (['jpg', 'jpeg', 'png'].contains(c.attachedFileName!.split('.').last.toLowerCase()))
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(base64Decode(c.attachedFileBase64!), fit: BoxFit.cover),
                                  )
                                : const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF0052D4), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(c.attachedFileName!,
                                style: const TextStyle(color: Color(0xFF334155), fontSize: 13, fontWeight: FontWeight.w600),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          if (['jpg', 'jpeg', 'png'].contains(c.attachedFileName!.split('.').last.toLowerCase()))
                            IconButton(
                              icon: const Icon(Icons.fullscreen_rounded, color: Color(0xFF0052D4)),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => Dialog(
                                    backgroundColor: Colors.transparent,
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: Image.memory(base64Decode(c.attachedFileBase64!)),
                                        ),
                                        Positioned(
                                          right: 10, top: 10,
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
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                  
                  if (answered && c.answer != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
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
                                lawyerName,
                                style: const TextStyle(
                                  color: Color(0xFF0052D4),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            c.answer!,
                            style: const TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedConsultations extends StatefulWidget {
  final String uid;
  final AuthService auth;
  final String? selectedSpeciality;

  const _SharedConsultations({
    required this.uid,
    required this.auth,
    required this.selectedSpeciality,
  });

  @override
  State<_SharedConsultations> createState() => _SharedConsultationsState();
}

class _SharedConsultationsState extends State<_SharedConsultations> {
  late Future<String> _userRoleFuture;

  @override
  void initState() {
    super.initState();
    _userRoleFuture = widget.auth.getUserRole(widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _userRoleFuture,
      builder: (ctx, roleSnap) {
        if (roleSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0052D4)));
        }
        final userRole = roleSnap.data ?? 'user';

        Query query = FirebaseFirestore.instance.collection('consultations');
        if (widget.selectedSpeciality != null) {
          query = query.where('type', isEqualTo: widget.selectedSpeciality);
        }

        return StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF0052D4)));
            }
            if (snap.hasError) {
              return Center(child: Text('Erreur:\n${snap.error}'));
            }

            final list = snap.data?.docs.map((e) => ConsultationModel.fromFirestore(e)).toList() ?? [];

            if (list.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0052D4).withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.people_alt_rounded, size: 64, color: Color(0xFF0052D4)),
                    ),
                    const SizedBox(height: 24),
                    Text('no_shares'.tr(),
                        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('select_another_specialty'.tr(),
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                  ],
                ),
              );
            }
            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 20),
              itemBuilder: (_, i) => _SharedConsultCard(
                consultation: list[i],
                userRole: userRole,
                auth: widget.auth,
                currentUserId: widget.uid,
              ),
            );
          },
        );
      },
    );
  }
}

class _SharedConsultCard extends StatefulWidget {
  final ConsultationModel consultation;
  final String userRole;
  final AuthService auth;
  final String currentUserId;

  const _SharedConsultCard({
    required this.consultation,
    required this.userRole,
    required this.auth,
    required this.currentUserId,
  });

  @override
  State<_SharedConsultCard> createState() => _SharedConsultCardState();
}

class _SharedConsultCardState extends State<_SharedConsultCard> {
  bool _isAnswering = false;
  final _answerCtrl = TextEditingController();

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer() async {
    if (_answerCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez écrire votre réponse'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isAnswering = true);
    try {
      final lawyerProfile = await widget.auth.getLawyerProfile(widget.currentUserId);

      await widget.auth.answerConsultation(
        consultationId: widget.consultation.id,
        lawyerId: widget.currentUserId,
        lawyerName: lawyerProfile?.name ?? 'Avocat',
        answer: _answerCtrl.text.trim(),
        userId: widget.consultation.userId,
      );

      if (!mounted) return;
      _answerCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Réponse envoyée avec succès!'),
        backgroundColor: Color(0xFF2E7D32),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _isAnswering = false);
  }

  @override
  Widget build(BuildContext context) {
    final isLawyer = widget.userRole == 'lawyer';
    final answered = widget.consultation.status == 'answered';
    final lawyerName = (widget.consultation.lawyerName != null && widget.consultation.lawyerName!.trim().isNotEmpty)
        ? widget.consultation.lawyerName!
        : 'Avocat';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: answered ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      widget.consultation.type,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    answered ? Icons.check_circle_rounded : Icons.access_time_filled_rounded,
                    size: 16,
                    color: answered ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    answered ? 'answered'.tr() : 'pending'.tr(),
                    style: TextStyle(
                      color: answered ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_rounded, size: 14, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.consultation.userFullName,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.consultation.question,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 14,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  if (answered && widget.consultation.answer != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
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
                                lawyerName,
                                style: const TextStyle(
                                  color: Color(0xFF0052D4),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.consultation.answer!,
                            style: const TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  if (!answered && isLawyer) ...[
                    const SizedBox(height: 24),
                    if (!_isAnswering)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                                ),
                                padding: EdgeInsets.only(
                                  bottom: MediaQuery.of(context).viewInsets.bottom,
                                  top: 30,
                                  left: 24,
                                  right: 24,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.gavel_rounded, color: Color(0xFF0052D4)),
                                        SizedBox(width: 12),
                                        Text(
                                          'legal_answer_title'.tr(),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: TextField(
                                        controller: _answerCtrl,
                                        maxLines: 6,
                                        style: const TextStyle(fontSize: 14, height: 1.5),
                                        decoration: InputDecoration(
                                          hintText: 'write_advice_hint'.tr(),
                                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.all(20),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextButton(
                                            onPressed: () {
                                              _answerCtrl.clear();
                                              Navigator.pop(context);
                                            },
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            ),
                                            child: Text('cancel'.tr(), style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          flex: 2,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _submitAnswer();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF0052D4),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            ),
                                            child: Text('submit_answer_btn'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 30),
                                  ],
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.reply_rounded, size: 18),
                          label: Text('provide_answer_btn'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0052D4),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                  ],
                  
                  if (!answered && !isLawyer) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0052D4).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF0052D4).withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF0052D4)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'only_lawyers_can_answer'.tr(),
                              style: TextStyle(
                                color: Color(0xFF0052D4),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
