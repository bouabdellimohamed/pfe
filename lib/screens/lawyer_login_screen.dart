import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class LawyerLoginScreen extends StatefulWidget {
  const LawyerLoginScreen({super.key});
  @override
  State<LawyerLoginScreen> createState() => _LawyerLoginScreenState();
}

class _LawyerLoginScreenState extends State<LawyerLoginScreen>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  String _error = '';

  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  static const _navy = Color(0xFF0D1B2A);
  static const _navyLight = Color(0xFF1B2D42);
  static const _gold = Color(0xFFC9A84C);
  static const _textPrimary = Color(0xFFF0EDE8);
  static const _textSecondary = Color(0xFF8A9BB0);

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = ''; });
    try {
      final err = await _auth.signInAsLawyer(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (!mounted) return;
      if (err != null) {
        setState(() => _error = err);
      } else {
        Navigator.pushReplacementNamed(context, '/lawyer-dashboard');
      }
    } catch (e) {
      setState(() => _error = 'Erreur inattendue: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height
                      - MediaQuery.of(context).padding.vertical,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    _buildHeader(),
                    const SizedBox(height: 48),
                    _buildCard(),
                    const SizedBox(height: 28),
                    _buildFooter(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Column(children: [
    Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle, color: _navyLight,
        border: Border.all(color: _gold.withOpacity(0.5), width: 1.5),
        boxShadow: [BoxShadow(color: _gold.withOpacity(0.15), blurRadius: 24, spreadRadius: 4)],
      ),
      child: const Icon(Icons.balance_rounded, size: 38, color: _gold),
    ),
    const SizedBox(height: 20),
    const Text('ESPACE AVOCAT', style: TextStyle(
      color: _gold, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 4)),
    const SizedBox(height: 8),
    const Text('Connexion', style: TextStyle(
      color: _textPrimary, fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
    const SizedBox(height: 6),
    const Text('Accédez à votre tableau de bord',
        style: TextStyle(color: _textSecondary, fontSize: 14)),
  ]);

  Widget _buildCard() => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: _navyLight,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _gold.withOpacity(0.12)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 28, offset: const Offset(0, 10))],
    ),
    child: Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('Adresse e-mail'),
        const SizedBox(height: 8),
        _field(ctrl: _emailCtrl, hint: 'avocat@cabinet.dz',
            icon: Icons.mail_outline_rounded,
            keyboard: TextInputType.emailAddress,
            validator: (v) => v!.isEmpty ? 'Champ requis' : null),
        const SizedBox(height: 20),
        _label('Mot de passe'),
        const SizedBox(height: 8),
        _field(
          ctrl: _passCtrl, hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          obscure: _obscure,
          suffix: IconButton(
            icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: _textSecondary, size: 20),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
          validator: (v) => v!.isEmpty ? 'Champ requis' : null,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _forgotPassword(),
            style: TextButton.styleFrom(foregroundColor: _gold, padding: const EdgeInsets.symmetric(vertical: 4)),
            child: const Text('Mot de passe oublié ?', style: TextStyle(fontSize: 13)),
          ),
        ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 8),
          _errorBanner(_error),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 54,
          child: ElevatedButton(
            onPressed: _loading ? null : _signIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold, foregroundColor: _navy,
              disabledBackgroundColor: _gold.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _loading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(_navy)))
                : const Text('SE CONNECTER',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          ),
        ),
      ]),
    ),
  );

  Widget _buildFooter() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text("Pas encore de compte ?", style: TextStyle(color: _textSecondary, fontSize: 14)),
    TextButton(
      onPressed: () => Navigator.pushReplacementNamed(context, '/lawyer-register'),
      style: TextButton.styleFrom(foregroundColor: _gold),
      child: const Text("S'inscrire", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
    ),
  ]);

  Widget _label(String t) => Text(t, style: const TextStyle(
      color: _textSecondary, fontSize: 13, fontWeight: FontWeight.w500));

  Widget _field({
    required TextEditingController ctrl, required String hint,
    required IconData icon, bool obscure = false,
    TextInputType? keyboard, Widget? suffix,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: ctrl, obscureText: obscure, keyboardType: keyboard,
    style: const TextStyle(color: _textPrimary, fontSize: 15),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _textSecondary.withOpacity(0.5), fontSize: 14),
      prefixIcon: Icon(icon, color: _textSecondary, size: 20),
      suffixIcon: suffix,
      filled: true, fillColor: _navy,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.07))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _gold, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350))),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350))),
      errorStyle: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 12),
    ),
    validator: validator,
  );

  Widget _errorBanner(String msg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.red.shade900.withOpacity(0.35),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.red.shade700.withOpacity(0.35)),
    ),
    child: Row(children: [
      Icon(Icons.error_outline, color: Colors.red.shade300, size: 18),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(msg, style: TextStyle(color: Colors.red.shade300, fontSize: 13)),
            if (msg.contains('vérifier votre email'))
              TextButton(
                onPressed: () async {
                  setState(() => _loading = true);
                  final res = await _auth.resendVerificationEmail(_emailCtrl.text.trim(), _passCtrl.text);
                  setState(() {
                    _loading = false;
                    _error = res ?? 'Rien renvoyé ! Vérifiez votre boîte mail.';
                  });
                },
                child: const Text('Renvoyer le lien', style: TextStyle(color: _gold, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    ]),
  );

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Entrez votre email pour réinitialiser le mot de passe');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Email envoyé à $email'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      setState(() => _error = 'Erreur: $e');
    }
  }
}
