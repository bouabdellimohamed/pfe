import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../services/auth_service.dart';

class PostRequestScreen extends StatefulWidget {
  const PostRequestScreen({super.key});
  @override
  State<PostRequestScreen> createState() => _PostRequestScreenState();
}

class _PostRequestScreenState extends State<PostRequestScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _auth = AuthService();
  
  String? selectedCategory;
  bool _loading = false;
  PlatformFile? _attachedFile;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final Color primaryColor = const Color(0xFF0052D4);
  final Color backgroundColor = const Color(0xFFF8FAFC);

  final List<String> categories = [
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

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

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
        // Limit for images is 5MB, but we will compress them
        if (file.size > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('file_too_large_msg'.tr(namedArgs: {'size': '5MB'}))),
            );
          }
          return;
        }

        // Show loading or just process
        if (file.bytes != null) {
          // Compression logic
          final image = img.decodeImage(file.bytes!);
          if (image != null) {
            // Resize to a reasonable resolution (max 1200px)
            img.Image resized = image;
            if (image.width > 1200 || image.height > 1200) {
              resized = img.copyResize(image, width: image.width > image.height ? 1200 : null, height: image.height > image.width ? 1200 : null);
            }
            // Encode to JPG with 70% quality to ensure it fits in Firestore
            finalBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 70));
            // Update name to .jpg for consistency
            if (!fileName.toLowerCase().endsWith('.jpg')) {
              fileName = fileName.split('.').first + '.jpg';
            }
          }
        }
      } else {
        // Non-image files (PDF, etc.) remain limited to 700KB
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || selectedCategory == null) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('fill_all_fields'.tr()),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final profile = await _auth.getUserProfile(user?.uid ?? '');
      await _auth.createRequest(
        userId: user?.uid ?? '',
        userFullName: profile?.fullName ?? user?.displayName ?? 'public_request_user'.tr(),
        title: _titleCtrl.text.trim(),
        type: selectedCategory!,
        description: _descCtrl.text.trim(),
        attachedFileName: _attachedFile?.name,
        attachedFileBase64: _attachedFile?.bytes != null ? base64Encode(_attachedFile!.bytes!) : null,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text('request_published_success'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('invalid-argument')) {
          errorMsg = 'error_file_too_large_storage'.tr(); // Specific msg for the 1MB limit
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCategoryBottomSheet() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Text('select_category_title'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  final isSel = selectedCategory == cat;
                  return InkWell(
                    onTap: () {
                      setState(() => selectedCategory = cat);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSel ? primaryColor : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSel ? primaryColor : Colors.grey.shade200),
                        boxShadow: isSel ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.balance_rounded, color: isSel ? Colors.white : const Color(0xFF64748B)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(cat.tr(), style: TextStyle(
                              color: isSel ? Colors.white : const Color(0xFF334155),
                              fontSize: 15,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                            )),
                          ),
                          if (isSel) const Icon(Icons.check_circle_rounded, color: Colors.white),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: primaryColor,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Material(
                color: Colors.white.withOpacity(0.2),
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0052D4), Color(0xFF4364F7), Color(0xFF6FB1FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -20,
                      child: Icon(Icons.campaign_rounded, size: 160, color: Colors.white.withOpacity(0.1)),
                    ),
                    Positioned(
                      left: 24,
                      bottom: 30,
                      right: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('public_network'.tr(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'post_request_title'.tr(),
                            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.tips_and_updates_rounded, color: Color(0xFF2563EB), size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'description_tip'.tr(),
                                  style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        _buildLabel('request_title_label'.tr()),
                        _buildTextField(
                          controller: _titleCtrl,
                          hint: 'request_title_hint'.tr(),
                          icon: Icons.title_rounded,
                          validator: (v) => v!.trim().isEmpty ? 'field_required'.tr() : null,
                        ),
                        const SizedBox(height: 24),

                        _buildLabel('legal_category_label'.tr()),
                        GestureDetector(
                          onTap: _showCategoryBottomSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.category_rounded, color: primaryColor.withOpacity(0.5), size: 22),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    selectedCategory != null ? selectedCategory!.tr() : 'select_category_hint'.tr(),
                                    style: TextStyle(
                                      color: selectedCategory == null ? Colors.grey.shade400 : const Color(0xFF334155),
                                      fontSize: 15,
                                      fontWeight: selectedCategory == null ? FontWeight.w500 : FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(Icons.expand_more_rounded, color: Colors.grey.shade400),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildLabel('detailed_desc_label'.tr()),
                        _buildTextField(
                          controller: _descCtrl,
                          hint: 'detailed_desc_hint'.tr(),
                          icon: Icons.subject_rounded,
                          maxLines: 6,
                          validator: (v) => (v?.trim().length ?? 0) < 20 ? 'at_least_20_chars'.tr() : null,
                        ),
                        const SizedBox(height: 32),

                        _buildLabel('attached_doc_label'.tr()),
                        if (_attachedFile == null)
                          InkWell(
                            onTap: _pickFile,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.cloud_upload_rounded, size: 32, color: primaryColor),
                                  ),
                                  const SizedBox(height: 12),
                                  Text('add_doc_btn'.tr(), style: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 6),
                                  Text('max_size_limit'.tr(), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
                              boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                                  child: Icon(Icons.insert_drive_file_rounded, color: primaryColor, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _attachedFile!.name,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${(_attachedFile!.size / 1024).toStringAsFixed(1)} KB',
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 24),
                                  onPressed: _removeFile,
                                  tooltip: 'Supprimer',
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 48),

                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              shadowColor: primaryColor.withOpacity(0.5),
                            ),
                            child: _loading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('submit_request_btn'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.send_rounded, size: 20),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 4),
    child: Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1E293B)),
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    validator: validator,
    style: const TextStyle(fontSize: 15, color: Color(0xFF334155), height: 1.5),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Padding(
        padding: EdgeInsets.only(bottom: maxLines > 1 ? 100.0 : 0),
        child: Icon(icon, color: primaryColor.withOpacity(0.5), size: 22),
      ),
      filled: true,
      fillColor: backgroundColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor.withOpacity(0.6), width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
      contentPadding: const EdgeInsets.all(20),
    ),
  );
}
