import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/profile_image_service.dart';
import '../widgets/profile_avatar.dart';
import '../theme/app_theme.dart';
import 'favorites_screen.dart';

class UserProfileManagementScreen extends StatefulWidget {
  const UserProfileManagementScreen({super.key});

  @override
  State<UserProfileManagementScreen> createState() =>
      _UserProfileManagementScreenState();
}

class _UserProfileManagementScreenState
    extends State<UserProfileManagementScreen> {
  final _auth = AuthService();
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _profileImageBase64;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  /// ✅ تحميل صورة الملف الشخصي من Firestore
  Future<void> _loadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _profileImageBase64 = doc.data()?['profileImageBase64'];
        });
      }
    } catch (_) {}
  }

  /// ✅ تغيير صورة الملف الشخصي
  Future<void> _changeProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // عرض خيارات: تغيير أو حذف
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('photo_profil'.tr(),
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _bottomSheetOption(
              icon: Icons.photo_library_rounded,
              label: 'choose_from_gallery'.tr(),
              color: AppColors.primary,
              onTap: () => Navigator.pop(ctx, 'pick'),
            ),
            if (_profileImageBase64 != null) ...[
              const SizedBox(height: 10),
              _bottomSheetOption(
                icon: Icons.delete_outline_rounded,
                label: 'delete_photo'.tr(),
                color: Colors.red,
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
            ],
            const SizedBox(height: 10),
            _bottomSheetOption(
              icon: Icons.close_rounded,
              label: 'cancel'.tr(),
              color: Colors.grey,
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );

    if (action == null) return;

    if (action == 'pick') {
      setState(() => _isLoading = true);
      final base64 = await ProfileImageService.pickAndCompressImage(context);
      if (base64 != null) {
        final success =
            await ProfileImageService.saveUserProfileImage(user.uid, base64);
        if (success && mounted) {
          setState(() => _profileImageBase64 = base64);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('photo_updated'.tr()),
            backgroundColor: Colors.green,
          ));
        }
      }
      if (mounted) setState(() => _isLoading = false);
    } else if (action == 'remove') {
      setState(() => _isLoading = true);
      final success = await ProfileImageService.removeProfileImage(
        user.uid,
        isLawyer: false,
      );
      if (success && mounted) {
        setState(() => _profileImageBase64 = null);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('photo_removed'.tr()),
        ));
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _bottomSheetOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ╔═══════════════════════════════════════╗
  // ║  تعديل بيانات الملف الشخصي             ║
  // ╚═══════════════════════════════════════╝
  Future<void> _editProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final nameController = TextEditingController(
      text: user.displayName ?? '',
    );
    final emailController = TextEditingController(
      text: user.email ?? '',
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('edit_profile_dialog_title'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'full_name'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'email_address'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                setState(() => _isLoading = true);

                // Update name
                if (nameController.text.isNotEmpty) {
                  await user.updateDisplayName(nameController.text);
                }

                // Update email
                if (emailController.text != user.email) {
                  await user.updateEmail(emailController.text);
                }

                // ✅ Fix: use fullName not displayName
                await _firestore.collection('users').doc(user.uid).update({
                  'fullName': nameController.text,
                  'email': emailController.text,
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('profile_updated_success')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('error'.tr() + ': $e')),
                  );
                }
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: Text('save_btn'.tr()),
          ),
        ],
      ),
    );
  }

  // ╔═══════════════════════════════════════╗
  // ║  حذف الحساب (مع تأكيد)                 ║
  // ╚═══════════════════════════════════════╝
  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_account_confirm_title'.tr()),
        content: Text(
          'delete_account_confirm_msg'.tr(),
          style: const TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              'yes_delete_account'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isLoading = true);

        // حذف بيانات المستخدم من Firestore
        await _firestore.collection('users').doc(user.uid).delete();

        // حذف حساب Firebase
        await user.delete();

        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('error'.tr() + ': $e')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // ╔═══════════════════════════════════════╗
  // ║  حذف جميع البطاقات المنشورة            ║
  // ╚═══════════════════════════════════════╝
  Future<void> _deleteAllPublications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_all_pubs_confirm_title'.tr()),
        content: Text(
          'delete_all_pubs_confirm_msg'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isLoading = true);

        // حذف جميع البطاقات
        final publications = await _firestore
            .collection('publications')
            .where('userId', isEqualTo: user.uid)
            .get();

        for (var doc in publications.docs) {
          await doc.reference.delete();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('all_pubs_deleted'.tr())),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('error'.tr() + ': $e')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // ╔═══════════════════════════════════════╗
  // ║  حذف جميع الاستشارات                  ║
  // ╚═══════════════════════════════════════╝
  Future<void> _deleteAllConsultations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_all_consultations_confirm_title'.tr()),
        content: Text(
          'delete_all_consultations_confirm_msg'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isLoading = true);

        // حذف جميع الاستشارات
        final consultations = await _firestore
            .collection('consultations')
            .where('userId', isEqualTo: user.uid)
            .get();

        for (var doc in consultations.docs) {
          await doc.reference.delete();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('all_consultations_deleted'.tr())),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('error'.tr() + ': $e')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'profile_title'.tr(),
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: const BackButton(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ──── صورة الملف الشخصي ────
                Center(
                  child: GestureDetector(
                    onTap: _changeProfileImage,
                    child: ProfileAvatar(
                      imageBase64: _profileImageBase64,
                      name: user?.displayName,
                      size: 110,
                      borderColor: AppColors.primary.withOpacity(0.3),
                      borderWidth: 3,
                      badge: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _changeProfileImage,
                    child: Text(
                      _profileImageBase64 != null
                          ? 'change_photo_btn'.tr()
                          : 'add_photo_btn'.tr(),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ──── معلومات الحساب ────
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'account_info_section'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'name_label'.tr() + ': ${user?.displayName ?? "pending".tr()}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'email_label_short'.tr() + ': ${user?.email ?? "pending".tr()}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),

                // ──── الخيارات ────
                _OptionTile(
                  icon: Icons.edit_rounded,
                  label: 'edit_profile_btn'.tr(),
                  color: AppColors.primary,
                  onTap: _editProfile,
                ),
                const SizedBox(height: 12),
                _OptionTile(
                  icon: Icons.bookmark_rounded,
                  label: 'saved_lawyers_btn'.tr(),
                  color: Colors.amber,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FavoritesScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _OptionTile(
                  icon: Icons.description_rounded,
                  label: 'delete_all_publications_btn'.tr(),
                  color: Colors.orange,
                  onTap: _deleteAllPublications,
                ),
                const SizedBox(height: 12),
                _OptionTile(
                  icon: Icons.chat_rounded,
                  label: 'delete_all_consultations_btn'.tr(),
                  color: Colors.teal,
                  onTap: _deleteAllConsultations,
                ),
                const SizedBox(height: 20),

                // ──── حذف الحساب (أحمر) ────
                ElevatedButton.icon(
                  onPressed: _deleteAccount,
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: Text('delete_account_btn'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
    );
  }
}

// ──── Options Tile ────
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: color, size: 16),
            ],
          ),
        ),
      );
}
