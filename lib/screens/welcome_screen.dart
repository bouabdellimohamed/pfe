import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import 'lawyer_login_screen.dart' as lawyer_login;
import 'lawyer_register_screen.dart' as lawyer_register;

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  static const Color primary = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.balance_rounded,
                      size: 54,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'JURISDZ',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: primary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trouvez l\'avocat qu\'il vous faut',
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(flex: 3),

                  // ── UTILISATEUR ──────────────────────────────
                  _SectionTitle(label: 'Je suis un utilisateur'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _Btn(
                          label: 'Créer un compte',
                          icon: Icons.person_add_outlined,
                          color: primary,
                          filled: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserSignUpScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Btn(
                          label: 'Se connecter',
                          icon: Icons.login_rounded,
                          color: primary,
                          filled: false,
                          onTap: () => _showUserLogin(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── AVOCAT ───────────────────────────────────
                  _SectionTitle(label: 'Je suis un avocat'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _Btn(
                          label: 'Inscription',
                          icon: Icons.how_to_reg_outlined,
                          color: Colors.teal,
                          filled: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  lawyer_register.LawyerRegisterScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Btn(
                          label: 'Se connecter',
                          icon: Icons.login_rounded,
                          color: Colors.teal,
                          filled: false,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => lawyer_login.LawyerLoginScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        );
  }

  void _showUserLogin(BuildContext context) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final auth = AuthService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        bool loading = false;
        String error = '';
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Connexion Utilisateur',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade400,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              error,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: loading
                          ? null
                          : () async {
                              setState(() {
                                loading = true;
                                error = '';
                              });
                              // ← signInAsUser يرفض حسابات المحامين
                              final res = await auth.signInAsUser(
                                email: emailCtrl.text.trim(),
                                password: passCtrl.text,
                              );
                              if (res == null) {
                                Navigator.pop(ctx);
                              } else {
                                setState(() {
                                  loading = false;
                                  error = res;
                                });
                              }
                            },
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Se connecter',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Divider(color: Colors.grey.shade300)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      Expanded(child: Divider(color: Colors.grey.shade300)),
    ],
  );
}

class _Btn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;
  const _Btn({
    required this.label,
    required this.icon,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 18),
    label: Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: filled ? color : Colors.white,
      foregroundColor: filled ? Colors.white : color,
      side: BorderSide(color: color),
      padding: const EdgeInsets.symmetric(vertical: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: filled ? 2 : 0,
    ),
  );
}
