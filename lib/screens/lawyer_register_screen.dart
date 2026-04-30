import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:io';
import '../services/auth_service.dart';
import '../data/algeria_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LawyerRegisterScreen extends StatefulWidget {
  const LawyerRegisterScreen({super.key});
  @override
  State<LawyerRegisterScreen> createState() => _LawyerRegisterScreenState();
}

class _LawyerRegisterScreenState extends State<LawyerRegisterScreen> {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _locationUrlCtrl = TextEditingController(); // ✅ حقل رابط الموقع

  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isGeneralist = false;
  String _error = '';

  PlatformFile? _pickedDoc;

  String? _wilaya, _daira, _commune;
  List<String> _dairas = [];
  List<String> _communes = [];

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
    'Propriété Intellectuelle',
  ];
  final List<String> _selected = [];

  static const _navy = Color(0xFF0D1B2A);
  static const _navyLight = Color(0xFF1B2D42);
  static const _gold = Color(0xFFC9A84C);
  static const _textPrimary = Color(0xFFF0EDE8);
  static const _textSecondary = Color(0xFF8A9BB0);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _phoneCtrl.dispose();
    _expCtrl.dispose();
    _locationUrlCtrl.dispose(); // ✅ تحرير المتحكم
    super.dispose();
  }

  void _onWilayaChanged(String? w) {
    setState(() {
      _wilaya = w;
      _daira = null;
      _commune = null;
      _dairas = w != null ? (AlgeriaData.wilayaDairas[w] ?? []) : [];
      _communes = [];
    });
  }

  void _onDairaChanged(String? d) {
    setState(() {
      _daira = d;
      _commune = null;
      _communes = d != null ? (AlgeriaData.dairaCommunes[d] ?? []) : [];
    });
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedDoc = result.files.first);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isGeneralist && _selected.isEmpty) {
      setState(() => _error =
          'Sélectionnez au moins une spécialité ou cochez "Avocat généraliste"');
      return;
    }
    if (_wilaya == null) {
      setState(() => _error = 'Veuillez sélectionner votre wilaya');
      return;
    }
    if (_pickedDoc == null) {
      setState(() => _error = 'Veuillez joindre un document justificatif');
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });

    Uint8List? docBytes = _pickedDoc!.bytes;
    if (docBytes == null && _pickedDoc!.path != null) {
      try {
        docBytes = await File(_pickedDoc!.path!).readAsBytes();
      } catch (e) {
        setState(() {
          _loading = false;
          _error = 'Impossible de lire le fichier. Essayez un autre.';
        });
        return;
      }
    }
    if (docBytes == null) {
      setState(() {
        _loading = false;
        _error = 'Fichier illisible. Veuillez choisir un autre document.';
      });
      return;
    }

    final err = await _auth.registerLawyer(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      name: _nameCtrl.text.trim(),
      speciality: _isGeneralist ? 'Généraliste' : _selected.join(', '),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      experience: int.tryParse(_expCtrl.text),
      isGeneralist: _isGeneralist,
      wilaya: _wilaya,
      daira: _daira,
      commune: _commune,
      documentBytes: docBytes,
      documentName: _pickedDoc!.name,
      // لا تنسَ إضافة الحقل في الخدمة الخاصة بك إذا لزم الأمر،
      // ويتم حفظه في Firestore كما يلي:
    );

    if (!mounted) return;

    if (err == null) {
      // ✅ حفظ رابط الموقع في Firestore عند التسجيل
      try {
        await FirebaseFirestore.instance
            .collection('lawyers')
            .doc(_auth.currentUser?.uid)
            .set({
          'locationUrl': _locationUrlCtrl.text.trim().isEmpty
              ? null
              : _locationUrlCtrl.text.trim(),
        }, SetOptions(merge: true));
      } catch (_) {}

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: _navyLight,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.hourglass_top_rounded, color: _gold),
            SizedBox(width: 10),
            Text('Demande envoyée',
                style: TextStyle(
                    color: _textPrimary, fontWeight: FontWeight.w700)),
          ]),
          content: const Text(
            'Votre dossier a été soumis avec succès.\n\n'
            '1. Veuillez vérifier votre boîte mail et cliquer sur le lien de confirmation.\n'
            '2. Un administrateur va examiner vos informations et votre document.\n\n'
            'Vous pourrez vous connecter une fois votre email vérifié et votre compte approuvé.',
            style: TextStyle(color: _textSecondary, height: 1.5),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: _navy,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Compris',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/lawyer-login');
    } else {
      setState(() {
        _loading = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              sliver: SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Informations personnelles',
                            Icons.person_outline_rounded),
                        const SizedBox(height: 14),
                        _card(children: [
                          _field(
                              label: 'Nom complet *',
                              ctrl: _nameCtrl,
                              hint: 'Maître Jean Dupont',
                              icon: Icons.person_outline_rounded,
                              validator: (v) =>
                                  v!.isEmpty ? 'Champ requis' : null),
                          const SizedBox(height: 14),
                          _field(
                              label: 'Email professionnel *',
                              ctrl: _emailCtrl,
                              hint: 'avocat@cabinet.dz',
                              icon: Icons.mail_outline_rounded,
                              keyboard: TextInputType.emailAddress,
                              validator: (v) =>
                                  v!.isEmpty ? 'Champ requis' : null),
                          const SizedBox(height: 14),
                          _field(
                              label: 'Téléphone',
                              ctrl: _phoneCtrl,
                              hint: '0555123456',
                              icon: Icons.phone_outlined,
                              keyboard: TextInputType.phone,
                              validator: (v) {
                                if (v != null && v.isNotEmpty) {
                                  if (!RegExp(r'^0[567]\d{8}$').hasMatch(v)) {
                                    return 'Numéro invalide (ex: 0555123456)';
                                  }
                                }
                                return null;
                              }),
                        ]),
                        const SizedBox(height: 24),
                        _sectionTitle('Localisation du cabinet',
                            Icons.location_on_outlined),
                        const SizedBox(height: 14),
                        _card(children: [
                          Text(
                              'Aidez les clients à vous trouver en indiquant votre wilaya.',
                              style: TextStyle(
                                  color: _textSecondary.withOpacity(0.8),
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic)),
                          const SizedBox(height: 14),
                          _dropdown(
                              label: 'Wilaya *',
                              value: _wilaya,
                              items: AlgeriaData.wilayaDairas.keys.toList(),
                              hint: 'Sélectionnez votre wilaya',
                              onChanged: _onWilayaChanged,
                              validator: (v) =>
                                  v == null ? 'Champ requis' : null),
                          const SizedBox(height: 14),
                          _dropdown(
                              label: 'Daïra',
                              value: _daira,
                              items: _dairas,
                              hint: _wilaya == null
                                  ? 'Choisissez une wilaya d\'abord'
                                  : 'Optionnel',
                              onChanged: _onDairaChanged),
                          const SizedBox(height: 14),
                          _dropdown(
                              label: 'Commune',
                              value: _commune,
                              items: _communes,
                              hint: _daira == null
                                  ? 'Choisissez une daïra d\'abord'
                                  : 'Optionnel',
                              onChanged: (v) => setState(() => _commune = v)),
                          const SizedBox(height: 14),
                          // ✅ تم إضافة حقل رابط الموقع
                          _field(
                              label: 'رابط موقع المكتب (Google Maps / GPS)',
                              ctrl: _locationUrlCtrl,
                              hint: 'أدخل رابط الخرائط...',
                              icon: Icons.map_outlined),
                        ]),
                        const SizedBox(height: 24),
                        _sectionTitle(
                            'Profil professionnel', Icons.gavel_rounded),
                        const SizedBox(height: 14),
                        _card(children: [
                          _field(
                              label: "Années d'expérience",
                              ctrl: _expCtrl,
                              hint: 'ex: 10',
                              icon: Icons.work_outline_rounded,
                              keyboard: TextInputType.number),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _navy,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.06)),
                            ),
                            child: Row(children: [
                              Checkbox(
                                value: _isGeneralist,
                                onChanged: (v) =>
                                    setState(() => _isGeneralist = v ?? false),
                                activeColor: _gold,
                                checkColor: _navy,
                                side: BorderSide(
                                    color: _textSecondary.withOpacity(0.4)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    const Text('Avocat généraliste',
                                        style: TextStyle(
                                            color: _textPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(
                                        'Cochez si vous gérez tous types de dossiers',
                                        style: TextStyle(
                                            color: _textSecondary,
                                            fontSize: 12)),
                                  ])),
                            ]),
                          ),
                          const SizedBox(height: 16),
                          Text('Spécialités *',
                              style: const TextStyle(
                                  color: _textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('Choisissez jusqu\'à 3 domaines principaux.',
                              style: TextStyle(
                                  color: _textSecondary.withOpacity(0.7),
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic)),
                          const SizedBox(height: 12),
                          _specialitiesGrid(),
                        ]),
                        const SizedBox(height: 24),
                        _sectionTitle(
                            'Document justificatif', Icons.upload_file_rounded),
                        const SizedBox(height: 14),
                        _card(children: [
                          Text(
                            'Joignez un document prouvant votre qualité d\'avocat (carte du barreau, diplôme, attestation, etc.)',
                            style: TextStyle(
                                color: _textSecondary.withOpacity(0.85),
                                fontSize: 12,
                                fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: _loading ? null : _pickDocument,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _navy,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _pickedDoc != null
                                      ? _gold
                                      : Colors.white.withOpacity(0.1),
                                  width: _pickedDoc != null ? 1.5 : 1,
                                ),
                              ),
                              child: Row(children: [
                                Icon(
                                  _pickedDoc != null
                                      ? Icons.check_circle_rounded
                                      : Icons.upload_file_outlined,
                                  color: _pickedDoc != null
                                      ? _gold
                                      : _textSecondary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(
                                        _pickedDoc != null
                                            ? _pickedDoc!.name
                                            : 'Appuyez pour choisir un fichier',
                                        style: TextStyle(
                                          color: _pickedDoc != null
                                              ? _textPrimary
                                              : _textSecondary,
                                          fontSize: 13,
                                          fontWeight: _pickedDoc != null
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (_pickedDoc != null)
                                        Text(
                                            '${(_pickedDoc!.size / 1024).toStringAsFixed(1)} KB · PDF / Image',
                                            style: TextStyle(
                                                color: _textSecondary,
                                                fontSize: 11))
                                      else
                                        Text('PDF, JPG, PNG acceptés',
                                            style: TextStyle(
                                                color: _textSecondary
                                                    .withOpacity(0.6),
                                                fontSize: 11)),
                                    ])),
                                if (_pickedDoc != null)
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _pickedDoc = null),
                                    child: Icon(Icons.close_rounded,
                                        color: _textSecondary, size: 18),
                                  ),
                              ]),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _sectionTitle('Sécurité', Icons.shield_outlined),
                        const SizedBox(height: 14),
                        _card(children: [
                          _field(
                              label: 'Mot de passe *',
                              ctrl: _passCtrl,
                              hint: '••••••••',
                              icon: Icons.lock_outline_rounded,
                              obscure: _obscurePass,
                              suffix: _toggleIcon(
                                  _obscurePass,
                                  () => setState(
                                      () => _obscurePass = !_obscurePass)),
                              validator: (v) => v!.length < 8
                                  ? 'Minimum 8 caractères'
                                  : null),
                          const SizedBox(height: 14),
                          _field(
                              label: 'Confirmer le mot de passe *',
                              ctrl: _confirmCtrl,
                              hint: '••••••••',
                              icon: Icons.lock_outline_rounded,
                              obscure: _obscureConfirm,
                              suffix: _toggleIcon(
                                  _obscureConfirm,
                                  () => setState(() =>
                                      _obscureConfirm = !_obscureConfirm)),
                              validator: (v) => v != _passCtrl.text
                                  ? 'Les mots de passe ne correspondent pas'
                                  : null),
                        ]),
                        if (_error.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _errorBanner(_error),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _gold,
                              foregroundColor: _navy,
                              disabledBackgroundColor: _gold.withOpacity(0.35),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation(_navy)))
                                : const Text("S'INSCRIRE COMME AVOCAT",
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Déjà un compte ?',
                                  style: TextStyle(
                                      color: _textSecondary, fontSize: 14)),
                              TextButton(
                                onPressed: () => Navigator.pushReplacementNamed(
                                    context, '/lawyer-login'),
                                style: TextButton.styleFrom(
                                    foregroundColor: _gold),
                                child: const Text('Se connecter',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                              ),
                            ]),
                      ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _navyLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x26C9A84C)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _textSecondary, size: 16),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x1AC9A84C),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x33C9A84C)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.balance_rounded, color: _gold, size: 14),
              SizedBox(width: 6),
              Text('ESPACE AVOCAT',
                  style: TextStyle(
                      color: _gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2)),
            ]),
          ),
          const SizedBox(height: 12),
          const Text('Créez votre\nprofil professionnel',
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  letterSpacing: -0.5)),
          const SizedBox(height: 6),
          const Text('Rejoignez la plateforme juridique en Algérie',
              style: TextStyle(color: _textSecondary, fontSize: 13)),
        ]),
      );

  Widget _sectionTitle(String title, IconData icon) => Row(children: [
        Icon(icon, color: _gold, size: 16),
        const SizedBox(width: 8),
        Text(title.toUpperCase(),
            style: const TextStyle(
                color: _gold,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2)),
      ]);

  Widget _card({required List<Widget> children}) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _navyLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x1AC9A84C)),
          boxShadow: [
            const BoxShadow(
                color: Color(0x30000000), blurRadius: 18, offset: Offset(0, 6))
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _field({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboard,
    Widget? suffix,
    String? Function(String?)? validator,
  }) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: _textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboard,
          style: const TextStyle(color: _textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0x808A9BB0), fontSize: 13),
            prefixIcon: Icon(icon, color: _textSecondary, size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: _navy,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0x14FFFFFF))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _gold, width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFEF5350))),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFEF5350))),
            errorStyle: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 12),
          ),
          validator: validator,
        ),
      ]);

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required String hint,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: _textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _navy,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            hint: Text(hint,
                style: const TextStyle(color: Color(0x808A9BB0), fontSize: 13)),
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: _textSecondary),
            dropdownColor: _navyLight,
            style: const TextStyle(color: _textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            items: items
                .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                .toList(),
            onChanged: items.isEmpty ? null : onChanged,
            validator: validator,
          ),
        ),
      ]);

  Widget _specialitiesGrid() {
    final maxed = _selected.length >= 3;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allSpecialities.map((s) {
        final sel = _selected.contains(s);
        final dis = !sel && maxed;
        return GestureDetector(
          onTap: dis
              ? null
              : () => setState(() {
                    sel ? _selected.remove(s) : _selected.add(s);
                  }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? const Color(0x33C9A84C) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sel
                    ? _gold
                    : dis
                        ? const Color(0x0F8A9BB0)
                        : const Color(0x228A9BB0),
                width: sel ? 1.5 : 1,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (sel)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.check_rounded, size: 14, color: _gold),
                ),
              Text(s,
                  style: TextStyle(
                    color: sel
                        ? _gold
                        : dis
                            ? const Color(0x448A9BB0)
                            : _textSecondary,
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                  )),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _toggleIcon(bool obscure, VoidCallback onTap) => IconButton(
        icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: _textSecondary,
            size: 20),
        onPressed: onTap,
      );

  Widget _errorBanner(String msg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0x607B1F1F),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x60C62828)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF9A9A), size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg,
                  style:
                      const TextStyle(color: Color(0xFFEF9A9A), fontSize: 13))),
        ]),
      );
}
