import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
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
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
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
                    const SnackBar(content: Text('Profile updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Save'),
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
        title: const Text('حذف الحساب'),
        content: const Text(
          'هذا الإجراء لا يمكن عكسه. سيتم حذف جميع بيانات حسابك بشكل دائم.\n\nهل أنت متأكد؟',
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'نعم، احذف حسابي',
              style: TextStyle(color: Colors.white),
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
            SnackBar(content: Text('خطأ في الحذف: $e')),
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
        title: const Text('Delete All Publications'),
        content: const Text(
          'Do you want to delete all your published publications?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Delete'),
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
            const SnackBar(content: Text('تم حذف جميع البطاقات')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e')),
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
        title: const Text('Delete All Consultations'),
        content: const Text(
          'Do you want to delete all your consultations?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Delete'),
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
            const SnackBar(content: Text('تم حذف جميع الاستشارات')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e')),
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
          'Mon Profil',
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
                // ──── معلومات الحساب ────
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'معلومات الحساب',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'الاسم: ${user?.displayName ?? "لم يتم تعيين"}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'البريد: ${user?.email ?? "لم يتم تعيين"}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),

                // ──── الخيارات ────
                _OptionTile(
                  icon: Icons.edit_rounded,
                  label: 'Modifier le profil',
                  color: AppColors.primary,
                  onTap: _editProfile,
                ),
                const SizedBox(height: 12),
                _OptionTile(
                  icon: Icons.bookmark_rounded,
                  label: 'Avocats sauvegardés',
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
                  label: 'Supprimer mes publications',
                  color: Colors.orange,
                  onTap: _deleteAllPublications,
                ),
                const SizedBox(height: 12),
                _OptionTile(
                  icon: Icons.chat_rounded,
                  label: 'Supprimer mes consultations',
                  color: Colors.teal,
                  onTap: _deleteAllConsultations,
                ),
                const SizedBox(height: 20),

                // ──── حذف الحساب (أحمر) ────
                ElevatedButton.icon(
                  onPressed: _deleteAccount,
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: const Text('Supprimer mon compte'),
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
