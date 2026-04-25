import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../services/auth_service.dart';

class PostRequestScreen extends StatefulWidget {
  const PostRequestScreen({super.key});
  @override
  State<PostRequestScreen> createState() => _PostRequestScreenState();
}

class _PostRequestScreenState extends State<PostRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _auth = AuthService();
  String? selectedCategory;
  bool _loading = false;

  // Fichier joint
  PlatformFile? _attachedFile;

  final Color primaryColor = const Color(0xFF1565C0);
  final Color backgroundColor = const Color(0xFFF8F9FA);

  // ✅ أسماء موحدة مع lawyer_register_screen و direct_search_screen
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
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png', 'jpeg'],
      withData: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _attachedFile = result.files.first);
    }
  }

  void _removeFile() => setState(() => _attachedFile = null);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')));
      return;
    }
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final profile = await _auth.getUserProfile(user?.uid ?? '');
      await _auth.createRequest(
        userId: user?.uid ?? '',
        userFullName: profile?.fullName ?? user?.displayName ?? 'Utilisateur',
        title: _titleCtrl.text.trim(),
        type: selectedCategory!,
        description: _descCtrl.text.trim(),
        attachedFileName: _attachedFile?.name,
      );
      if (!mounted) return;
      _titleCtrl.clear(); _descCtrl.clear();
      setState(() { selectedCategory = null; _attachedFile = null; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande publiée avec succès !'),
            backgroundColor: Color(0xFF2E7D32)));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.grey[100],
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text('Publier une demande',
            style: TextStyle(color: Colors.black,
                fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline, color: primaryColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(
                    'Une description claire augmente vos chances.',
                    style: TextStyle(color: primaryColor, fontSize: 13),
                  )),
                ]),
              ),
              const SizedBox(height: 25),

              _buildLabel('Titre de la demande'),
              _buildTextField(
                controller: _titleCtrl,
                hint: 'Ex: Aide pour procédure de divorce',
                icon: Icons.edit_note_rounded,
                validator: (v) => v!.isEmpty ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 20),

              _buildLabel('Catégorie juridique'),
              _buildDropdownField(),
              const SizedBox(height: 20),

              _buildLabel('Description détaillée'),
              _buildTextField(
                controller: _descCtrl,
                hint: 'Expliquez les faits, dates importantes...',
                icon: Icons.description_outlined,
                maxLines: 5,
                validator: (v) =>
                    (v?.length ?? 0) < 10 ? 'Description trop courte' : null,
              ),
              const SizedBox(height: 20),

              // ── PIÈCE JOINTE ─────────────────────────────────
              _buildLabel('Document joint (optionnel)'),
              if (_attachedFile == null)
                InkWell(
                  onTap: _pickFile,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.grey.shade300, style: BorderStyle.solid),
                    ),
                    child: Column(children: [
                      Icon(Icons.upload_file_outlined,
                          size: 32, color: primaryColor.withOpacity(0.5)),
                      const SizedBox(height: 8),
                      Text('Joindre un fichier',
                          style: TextStyle(
                              color: primaryColor, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('PDF, DOC, DOCX, JPG, PNG',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 11)),
                    ]),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    Icon(Icons.insert_drive_file_outlined,
                        color: primaryColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_attachedFile!.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                            if (_attachedFile!.size > 0)
                              Text(
                                '${(_attachedFile!.size / 1024).toStringAsFixed(1)} KB',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11),
                              ),
                          ]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                      onPressed: _removeFile,
                    ),
                  ]),
                ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Publier la demande',
                                style: TextStyle(color: Colors.white,
                                    fontSize: 17, fontWeight: FontWeight.bold)),
                            SizedBox(width: 10),
                            Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 4),
    child: Text(label,
        style: const TextStyle(fontWeight: FontWeight.w700,
            fontSize: 15, color: Color(0xFF263238))),
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
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.5), size: 22),
      filled: true,
      fillColor: backgroundColor,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: primaryColor.withOpacity(0.3), width: 1.5)),
      contentPadding: const EdgeInsets.all(18),
    ),
  );

  Widget _buildDropdownField() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        value: selectedCategory,
        hint: Text('Choisir une catégorie',
            style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor),
        items: categories.map((c) =>
            DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (v) => setState(() => selectedCategory = v),
      ),
    ),
  );
}
