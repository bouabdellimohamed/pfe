import 'package:flutter/material.dart';
import 'lawyers_result_screen.dart'; // تأكدي من وجود هذا الملف

class DirectSearchScreen extends StatefulWidget {
  const DirectSearchScreen({super.key});

  @override
  State<DirectSearchScreen> createState() => _DirectSearchScreenState();
}

class _DirectSearchScreenState extends State<DirectSearchScreen> {
  String? _selectedSpeciality;
  String? _selectedWilaya;
  String? _selectedCommune;

  // وحدنا الألوان لتكون متناسقة مع الهوية القانونية
  final Color primaryColor = const Color(0xFF1565C0);
  final Color darkText = const Color(0xFF101010);
  final Color greyText = const Color(0xFF757575);

  final List<String> _specialities = [
    'Droit familial',
    'Droit pénal',
    'Droit commercial',
    'Droit civil',
    'Droit immobilier',
    'Droit administratif',
    'Droit du travail',
    'Droit des sociétés',
    'Droit fiscal',
    'Propriété Intellectuelle', // قمت بتقصير الاسم ليتناسب مع الجريد
  ];

  final Map<String, List<String>> _locations = {
    'Alger': [
      'Alger Centre',
      'Bab Ezzouar',
      'Hydra',
      'Kouba',
      'Birkhadem',
      'Zeralda',
      'Cheraga',
      'Dely Ibrahim',
      'El Harrach',
    ],
    'Oran': [
      'Oran Centre',
      'Bir El Djir',
      'Es Senia',
      'Ain Turk',
      'Arzew',
      'Gdyel',
      'Sidi Chami',
    ],
    'Blida': [
      'Blida Centre',
      'Boufarik',
      'Larbaa',
      'Ouled Yaich',
      'Beni Mered',
      'El Affroun',
    ],
    'Constantine': [
      'Constantine Centre',
      'El Khroub',
      'Ali Mendjeli',
      'Didouche Mourad',
      'Hamma Bouziane',
    ],
    'Annaba': [
      'Annaba Centre',
      'El Bouni',
      'Sidi Amar',
      'Seraidi',
      'Berrahal',
      'El Hadjar',
    ],
    'Sétif': [
      'Sétif Centre',
      'El Eulma',
      'Ain Arnat',
      'Ain Abessa',
      'Guenzet',
      'Bouandas',
    ],
    'Tizi Ouzou': [
      'Tizi Ouzou Centre',
      'Azazga',
      'Draa Ben Khedda',
      'Larbaâ Nath Irathen',
      'Tigzirt',
    ],
    'Batna': ['Batna Centre', 'Barika', 'Arris', 'Ain Touta', 'Merouana'],
    'Tlemcen': [
      'Tlemcen Centre',
      'Maghnia',
      'Mansourah',
      'Ghazaouet',
      'Remchi',
    ],
    'Béjaïa': ['Béjaïa Centre', 'Akbou', 'Amizour', 'El Kseur', 'Sidi Aïch'],
    'Chlef': ['Chlef Centre', 'Ténès', 'Oued Fodda', 'Boukadir'],
    'Djelfa': ['Djelfa Centre', 'Hassi Bahbah', 'Ain Oussera', 'Messaad'],
    'Biskra': ['Biskra Centre', 'Tolga', 'Ouled Djellal', 'Sidi Okba'],
    'Tébessa': ['Tébessa Centre', 'Bir El Ater', 'Cheria', 'Ouenza'],
    'Skikda': ['Skikda Centre', 'El Harrouch', 'Azzaba', 'Collo'],
    'Sidi Bel Abbès': ['Sidi Bel Abbès Centre', 'Sfisef', 'Tessala', 'Telagh'],
    'Mostaganem': [
      'Mostaganem Centre',
      'Ain Nouissy',
      'Bouguirat',
      'Cassaigne',
    ],
    'M\'Sila': ['M\'Sila Centre', 'Bou Saada', 'Sidi Aissa', 'Magra'],
    'Bordj Bou Arreridj': [
      'BBA Centre',
      'Ras El Oued',
      'Mansoura',
      'Bordj Ghedir',
    ],
    'Boumerdès': [
      'Boumerdès Centre',
      'Boudouaou',
      'Dellys',
      'Khemis El Khechna',
    ],
    'Tipaza': ['Tipaza Centre', 'Cherchell', 'Bou Ismail', 'Kolea', 'Hadjout'],
    'Ghardaïa': ['Ghardaïa Centre', 'Metlili', 'El Guerrara', 'Beni Isguen'],
    'Ouargla': ['Ouargla Centre', 'Hassi Messaoud', 'Touggourt', 'Rouissat'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Recherche directe",
          style: TextStyle(color: darkText, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        // 👈 أضفنا SafeArea لحماية الحواف العلوية
        child: SingleChildScrollView(
          // 👈 هذا هو البطل الذي يمنع الـ Overflow
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Trouvez votre avocat\nidéal",
                style: TextStyle(
                  color: darkText,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Sélectionnez une spécialité et votre localisation.",
                style: TextStyle(color: greyText, fontSize: 15),
              ),
              const SizedBox(height: 30),

              _buildSectionTitle("1. Choisissez une spécialité"),
              const SizedBox(height: 15),
              _buildSpecialityGrid(), // تأكدي أن داخلها shrinkWrap: true

              const SizedBox(height: 30),

              _buildSectionTitle("2. Votre Localisation"),
              const SizedBox(height: 15),
              _buildLocationForm(),

              const SizedBox(height: 40),

              _buildSearchButton(),
              const SizedBox(height: 30), // مساحة إضافية في الأسفل لراحة العين
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets مساعدة مبنية باحترافية ---

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
    );
  }

  /// 🔵 SPECIALITY GRID المطور
  Widget _buildSpecialityGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _specialities.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // عمودين
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.3, // تحسين نسبة العرض إلى الارتفاع
      ),
      itemBuilder: (context, index) {
        final speciality = _specialities[index];
        final isSelected = _selectedSpeciality == speciality;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedSpeciality = speciality;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? primaryColor : Colors.grey[200]!,
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? primaryColor.withOpacity(0.15)
                      : Colors.black.withOpacity(0.03),
                  blurRadius: isSelected ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  speciality,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : darkText,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 📍 LOCATION FORM المطور (يشبه حقول الإدخال في PostRequestScreen)
  /// 📍 LOCATION FORM المطور والمصحح لمنع الـ Overflow جهة اليمين
  Widget _buildLocationForm() {
    return Container(
      // 👈 تأكدي أن الـ margin الأفقي هنا متناسق مع باقي الصفحة
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      padding: const EdgeInsets.all(20), // Padding داخلي متوازن
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        // 👈 هذا يضمن أن الحقول ستأخذ عرض الـ Card بالكامل ولن تتمدد يميناً
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /// Wilaya Dropdown
          _buildDropdownField(
            value: _selectedWilaya,
            hint: 'Sélectionnez une Wilaya',
            icon: Icons.map_rounded,
            items: _locations.keys.toList(),
            onChanged: (value) {
              setState(() {
                _selectedWilaya = value;
                _selectedCommune = null;
              });
            },
          ),

          if (_selectedWilaya != null) const SizedBox(height: 15),

          /// Commune Dropdown (اختياري)
          if (_selectedWilaya != null)
            _buildDropdownField(
              value: _selectedCommune,
              hint:
                  'Commune (optionnel)', // قلصت النص لمنع الـ Overflow الداخلي
              icon: Icons.location_city_rounded,
              items: _locations[_selectedWilaya]!,
              onChanged: (value) {
                setState(() {
                  _selectedCommune = value;
                });
              },
            ),
        ],
      ),
    );
  }

  // Widget مساعد لبناء الـ Dropdown بتصميم موحد وآمن ضد الـ OverFlow
  Widget _buildDropdownField({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      // 👈 تأكدي أن هذا الحقل يأخذ عرض الحاوية الأب بالكامل
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true, // 👈 مهم جداً! يجعل النص يتمدد لملء العرض
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: greyText,
              fontSize: 13,
            ), // تصغير خط التلميح قليلاً
            prefixIcon: Icon(
              icon,
              color: primaryColor.withOpacity(0.5),
              size: 18,
            ),
            border: InputBorder.none, // إزالة حدود الـ InputField
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 8,
            ), // Padding متوازن
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// 🔍 SEARCH BUTTON المطور
  Widget _buildSearchButton() {
    final isFormValid = _selectedSpeciality != null && _selectedWilaya != null;

    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: isFormValid
            ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: isFormValid ? _performSearch : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "RECHERCHER",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            SizedBox(width: 10),
            Icon(Icons.search_rounded, size: 22),
          ],
        ),
      ),
    );
  }

  /// 🚀 SEARCH FUNCTION (نفس الوظيفة القديمة)
  void _performSearch() {
    debugPrint(
      'Recherche: Spécialité: $_selectedSpeciality, Wilaya: $_selectedWilaya',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LawyersResultScreen(
          speciality: _selectedSpeciality!,
          wilaya: _selectedWilaya!,
        ),
      ),
    );
  }
}
