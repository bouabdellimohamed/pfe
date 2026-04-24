import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/lawyer_model.dart';

class LawyerEditProfileScreen extends StatefulWidget {
  final LawyerModel? lawyer;
  const LawyerEditProfileScreen({super.key, this.lawyer});
  @override
  State<LawyerEditProfileScreen> createState() => _LawyerEditProfileScreenState();
}

class _LawyerEditProfileScreenState extends State<LawyerEditProfileScreen> {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String _error = '';
  String? _lawyerUid;

  final List<String> _allSpecialities = [
    'Droit familial', 'Droit pénal', 'Droit commercial',
    'Droit civil', 'Droit immobilier', 'Droit administratif',
    'Droit du travail', 'Droit des sociétés', 'Droit fiscal',
  ];
  final List<String> _selected = [];

  static const _navy = Color(0xFF0D1B2A);
  static const _navyLight = Color(0xFF1B2D42);
  static const _navyCard = Color(0xFF162233);
  static const _gold = Color(0xFFC9A84C);
  static const _textPrimary = Color(0xFFF0EDE8);
  static const _textSecondary = Color(0xFF8A9BB0);

  @override
  void initState() {
    super.initState();
    if (widget.lawyer != null) {
      _initFromModel(widget.lawyer!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.lawyer == null && _loading) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is LawyerModel) {
        _initFromModel(args);
      } else {
        // جلب من Firestore كـ fallback
        _fetchFromFirestore();
      }
    }
  }

  void _initFromModel(LawyerModel l) {
    _lawyerUid = l.uid;
    _nameCtrl.text = l.name;
    _phoneCtrl.text = l.phone ?? '';
    _expCtrl.text = l.experience?.toString() ?? '';
    _bioCtrl.text = l.bio ?? '';
    _selected.clear();
    if (l.speciality.isNotEmpty) {
      _selected.addAll(l.speciality.split(', ').where((s) => s.isNotEmpty));
    }
    setState(() => _loading = false);
  }

  Future<void> _fetchFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { setState(() => _loading = false); return; }
    final profile = await _auth.getLawyerProfile(uid);
    if (profile != null && mounted) _initFromModel(profile);
    else if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _expCtrl.dispose(); _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selected.isEmpty) {
      setState(() => _error = 'Sélectionnez au moins une spécialité'); return;
    }
    setState(() { _saving = true; _error = ''; });
    try {
      final uid = _lawyerUid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
      await _auth.updateLawyerProfile(uid, {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'experience': int.tryParse(_expCtrl.text),
        'speciality': _selected.join(', '),
        'bio': _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Profil mis à jour !'), backgroundColor: Color(0xFF2E7D32)));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _error = 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _navy,
        body: Center(child: CircularProgressIndicator(color: _gold)),
      );
    }
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navyLight,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _navyCard, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x26C9A84C)),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: _textSecondary, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Modifier le profil',
            style: TextStyle(color: _textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: const Color(0x1AC9A84C),
              border: Border.all(color: const Color(0x33C9A84C)),
            ),
            child: const Icon(Icons.balance_rounded, color: _gold, size: 16),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),

            // Section: Infos perso
            _sectionLabel('Informations personnelles'),
            const SizedBox(height: 12),
            _card(children: [
              _field(label: 'Nom complet *', ctrl: _nameCtrl,
                  icon: Icons.person_outline_rounded,
                  validator: (v) => v!.isEmpty ? 'Champ requis' : null),
              const SizedBox(height: 14),
              _field(label: 'Téléphone', ctrl: _phoneCtrl,
                  icon: Icons.phone_outlined, keyboard: TextInputType.phone),
            ]),

            const SizedBox(height: 24),

            // Section: Profil pro
            _sectionLabel('Profil professionnel'),
            const SizedBox(height: 12),
            _card(children: [
              _field(label: "Années d'expérience", ctrl: _expCtrl,
                  icon: Icons.work_outline_rounded, keyboard: TextInputType.number),
              const SizedBox(height: 16),
              Text('Spécialités *',
                  style: const TextStyle(color: _textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              _specialitiesGrid(),
            ]),

            const SizedBox(height: 24),

            // Section: Bio
            _sectionLabel('Bio / Description'),
            const SizedBox(height: 12),
            _card(children: [
              _field(label: 'Bio', ctrl: _bioCtrl,
                  icon: Icons.description_outlined, maxLines: 5),
            ]),

            if (_error.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0x607B1F1F), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x60C62828)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: Color(0xFFEF9A9A), size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_error, style: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 13))),
                ]),
              ),
            ],

            const SizedBox(height: 24),

            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textSecondary,
                  side: BorderSide(color: _textSecondary.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('ANNULER'),
              )),
              const SizedBox(width: 14),
              Expanded(child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold, foregroundColor: _navy,
                  disabledBackgroundColor: _gold.withOpacity(0.35),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(_navy)))
                    : const Text('ENREGISTRER',
                        style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
              )),
            ]),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String t) => Row(children: [
    Container(width: 3, height: 18,
        decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(4))),
    const SizedBox(width: 10),
    Text(t.toUpperCase(), style: const TextStyle(
        color: _textPrimary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
  ]);

  Widget _card({required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _navyCard, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0x14FFFFFF)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _field({
    required String label, required TextEditingController ctrl,
    required IconData icon, int maxLines = 1, TextInputType? keyboard,
    String? Function(String?)? validator,
  }) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: _textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
    const SizedBox(height: 8),
    TextFormField(
      controller: ctrl, maxLines: maxLines, keyboardType: keyboard,
      style: const TextStyle(color: _textPrimary, fontSize: 15),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: _textSecondary, size: 20),
        filled: true, fillColor: _navyLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _textSecondary.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _gold, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFEF5350))),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFEF5350))),
        errorStyle: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 12),
      ),
      validator: validator,
    ),
  ]);

  Widget _specialitiesGrid() {
    final maxed = _selected.length >= 3;
    return Column(children: [
      Align(alignment: Alignment.centerRight,
          child: Text('${_selected.length}/3', style: TextStyle(
              color: maxed ? _gold : _textSecondary, fontSize: 12, fontWeight: FontWeight.w600))),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: _allSpecialities.map((s) {
        final sel = _selected.contains(s);
        final dis = !sel && maxed;
        return GestureDetector(
          onTap: dis ? null : () => setState(() => sel ? _selected.remove(s) : _selected.add(s)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? const Color(0x33C9A84C) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sel ? _gold : dis ? const Color(0x0F8A9BB0) : const Color(0x228A9BB0),
                width: sel ? 1.5 : 1,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (sel) const Padding(padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.check_rounded, size: 14, color: _gold)),
              Text(s, style: TextStyle(
                color: sel ? _gold : dis ? const Color(0x448A9BB0) : _textSecondary,
                fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
              )),
            ]),
          ),
        );
      }).toList()),
    ]);
  }
}
