import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/lawyer_model.dart';
import 'lawyer_profile_screen.dart';
import 'lawyers_result_screen.dart';

class DirectSearchScreen extends StatefulWidget {
  final String? preselectedSpeciality;
  const DirectSearchScreen({super.key, this.preselectedSpeciality});

  @override
  State<DirectSearchScreen> createState() => _DirectSearchScreenState();
}

class _DirectSearchScreenState extends State<DirectSearchScreen> {
  String? _selectedSpeciality;
  String? _selectedWilaya;
  String? _selectedCommune;

  List<LawyerModel> _recommendedLawyers = [];
  bool _isLoadingRecs = false;

  @override
  void initState() {
    super.initState();
    // ✅ تطبيق التخصص المُمرَّر من الـ Questionnaire تلقائياً
    if (widget.preselectedSpeciality != null) {
      _selectedSpeciality = widget.preselectedSpeciality;
    }
  }

  final Color primaryColor = const Color(0xFF1565C0);
  final Color darkText = const Color(0xFF101010);
  final Color greyText = const Color(0xFF757575);

  final List<String> _specialities = [
    'Généraliste',
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

  final Map<String, List<String>> _locations = {
    'Adrar': ['Adrar','Reggane','Timimoun','In Salah','Aoulef'],
    'Chlef': ['Chlef','Ténès','Oued Fodda','Boukadir','El Karimia'],
    'Laghouat': ['Laghouat','Aflou','Ksar El Hirane','Hassi Delaa'],
    'Oum El Bouaghi': ['Oum El Bouaghi','Ain Beida','Ain Mlila','Sigus'],
    'Batna': ['Batna','Barika','Arris','Ain Touta','Merouana','Timgad'],
    'Béjaïa': ['Béjaïa','Akbou','Amizour','El Kseur','Sidi Aïch','Kherrata'],
    'Biskra': ['Biskra','Tolga','Ouled Djellal','Sidi Okba','El Outaya'],
    'Béchar': ['Béchar','Abadla','Kenadsa','Beni Abbes'],
    'Blida': ['Blida','Boufarik','Larbaa','Ouled Yaich','Beni Mered','El Affroun','Bouinan'],
    'Bouira': ['Bouira','Lakhdaria','Sour El Ghouzlane','Ain Bessem'],
    'Tamanrasset': ['Tamanrasset','In Guezzam','Ain Salah','Tin Zaouatine'],
    'Tébessa': ['Tébessa','Bir El Ater','Cheria','Ouenza','El Aouinet'],
    'Tlemcen': ['Tlemcen','Maghnia','Mansourah','Ghazaouet','Remchi','Hennaya'],
    'Tiaret': ['Tiaret','Frenda','Sougueur','Mahdia','Ain Kermes'],
    'Tizi Ouzou': ['Tizi Ouzou','Azazga','Draa Ben Khedda','Larbaâ Nath Irathen','Tigzirt','Boghni'],
    'Alger': ['Alger Centre','Bab Ezzouar','Hydra','Kouba','Birkhadem','Zeralda','Cheraga','Dely Ibrahim','El Harrach','Dar El Beida','Hussain Dey'],
    'Djelfa': ['Djelfa','Hassi Bahbah','Ain Oussera','Messaad','Birine'],
    'Jijel': ['Jijel','El Milia','Taher','Ziama Mansouriah','Chekfa'],
    'Sétif': ['Sétif','El Eulma','Ain Arnat','Ain Abessa','Guenzet','Bouandas','Bougaa'],
    'Saïda': ['Saïda','Ain El Hadjar','Sidi Amar','Youb'],
    'Skikda': ['Skikda','El Harrouch','Azzaba','Collo','Ain Charchar'],
    'Sidi Bel Abbès': ['Sidi Bel Abbès','Sfisef','Tessala','Telagh','Ain Trid'],
    'Annaba': ['Annaba','El Bouni','Sidi Amar','Seraidi','Berrahal','El Hadjar','Ain Berda'],
    'Guelma': ['Guelma','Bouchegouf','Heliopolis','Oued Zenati','Hammam Debagh'],
    'Constantine': ['Constantine','El Khroub','Ali Mendjeli','Didouche Mourad','Hamma Bouziane','Ibn Ziad'],
    'Médéa': ['Médéa','Berrouaghia','Ksar El Boukhari','Ain Boucif','El Azizia'],
    'Mostaganem': ['Mostaganem','Ain Nouissy','Bouguirat','Sidi Ali','Ain Tedles'],
    "M'Sila": ["M'Sila",'Bou Saada','Sidi Aissa','Magra','Ain El Melh'],
    'Mascara': ['Mascara','Sig','Tighennif','Bouhanifia','Mohammadia'],
    'Ouargla': ['Ouargla','Hassi Messaoud','Touggourt','Rouissat','El Hadjira','Temacine'],
    'Oran': ['Oran','Bir El Djir','Es Senia','Ain Turk','Arzew','Gdyel','Sidi Chami','El Kerma'],
    'El Bayadh': ['El Bayadh','Brezina','Boualem','El Bnoud'],
    'Illizi': ['Illizi','Djanet','In Amenas'],
    'Bordj Bou Arreridj': ['Bordj Bou Arreridj','Ras El Oued','Mansoura','Bordj Ghedir','El Anseur'],
    'Boumerdès': ['Boumerdès','Boudouaou','Dellys','Khemis El Khechna','Isser','Thenia'],
    'El Tarf': ['El Tarf','El Kala','Ben Mehidi','Besbes','Ain Assel'],
    'Tindouf': ['Tindouf'],
    'Tissemsilt': ['Tissemsilt','Khemisti','Bordj Bou Naama','Lardjem'],
    'El Oued': ['El Oued','Guemar','Robbah','Reguiba','Kouinine'],
    'Khenchela': ['Khenchela','Ain Touila','Baghai','El Mahmal'],
    'Souk Ahras': ['Souk Ahras','Sedrata','Mdaourouch','Taoura'],
    'Tipaza': ['Tipaza','Cherchell','Bou Ismail','Kolea','Hadjout','Ain Tagourait'],
    'Mila': ['Mila','Chelghoum El Aid','Ferdjioua','Grarem Gouga'],
    'Aïn Defla': ['Aïn Defla','Khemis Miliana','El Attaf','Ain Lechiakh','Djendel'],
    'Naâma': ['Naâma','Mecheria','Ain Sefra','Sfissifa'],
    'Aïn Témouchent': ['Aïn Témouchent','Hammam Bou Hadjar','El Amria','Beni Saf'],
    'Ghardaïa': ['Ghardaïa','Metlili','El Guerrara','Beni Isguen','Berriane'],
    'Relizane': ['Relizane','Mazouna','Ain Tarek','Oued Rhiou'],
    'Timimoun': ['Timimoun','Aougrout','Charouine'],
    'Bordj Badji Mokhtar': ['Bordj Badji Mokhtar','Timiaouine'],
    'Ouled Djellal': ['Ouled Djellal','Sidi Khaled','Ras El Miaad'],
    'Béni Abbès': ['Béni Abbès','Igli','Kerzaz'],
    'In Salah': ['In Salah','In Guezzam','Foggaret Ezzaouia'],
    'In Guezzam': ['In Guezzam','Tin Zaouatine'],
    'Touggourt': ['Touggourt','Temacine','Megarine','El Hadjira'],
    'Djanet': ['Djanet','Bordj El Haoues'],
    'El Meghaier': ['El Meghaier','Djamaa','Still','Sidi Amrane'],
    'El Meniaa': ['El Meniaa','Hassi Gara','Berezina'],
  };

  Future<void> _fetchRecommendations() async {
    if (_selectedSpeciality == null || _selectedWilaya == null) return;
    setState(() => _isLoadingRecs = true);
    try {
      // ✅ جلب كل المحامين ثم فلترة في الكود (لأن speciality محفوظ كـ "A, B, C")
      final snap = await FirebaseFirestore.instance
          .collection('lawyers')
          .get();

      var lawyers = snap.docs
          .map((d) => LawyerModel.fromMap(d.data()))
          .where((l) {
            final lawyerSpec = l.speciality.toLowerCase();
            final searchSpec = (_selectedSpeciality ?? '').toLowerCase();
            final wilayaMatch = (l.wilaya ?? '').toLowerCase() ==
                _selectedWilaya!.trim().toLowerCase();
            return lawyerSpec.contains(searchSpec) && wilayaMatch;
          })
          .toList();

      lawyers.sort((a, b) {
        if (b.finalScore != a.finalScore) return b.finalScore.compareTo(a.finalScore);
        return b.rating.compareTo(a.rating);
      });

      setState(() {
        _recommendedLawyers = lawyers.take(5).toList();
        _isLoadingRecs = false;
      });
    } catch (e) {
      setState(() => _isLoadingRecs = false);
    }
  }

  void _onSelectionChanged() {
    if (_selectedSpeciality != null && _selectedWilaya != null) {
      _fetchRecommendations();
    } else {
      setState(() => _recommendedLawyers = []);
    }
  }

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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Trouvez votre avocat\nidéal",
                style: TextStyle(color: darkText, fontSize: 28, fontWeight: FontWeight.w800, height: 1.2),
              ),
              const SizedBox(height: 10),
              Text(
                "Sélectionnez une spécialité et votre localisation.",
                style: TextStyle(color: greyText, fontSize: 15),
              ),
              const SizedBox(height: 30),

              _buildSectionTitle("1. Choisissez une spécialité"),
              const SizedBox(height: 15),
              _buildSpecialityGrid(),

              const SizedBox(height: 30),
              _buildSectionTitle("2. Votre Localisation"),
              const SizedBox(height: 15),
              _buildLocationForm(),

              if (_selectedSpeciality != null && _selectedWilaya != null) ...[
                const SizedBox(height: 30),
                _buildRecommendationsSection(),
              ],

              const SizedBox(height: 40),
              _buildSearchButton(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.recommend_rounded, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Avocats recommandés",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText),
                  ),
                  Text(
                    "$_selectedSpeciality • $_selectedWilaya",
                    style: TextStyle(color: greyText, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isLoadingRecs)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
            ),
          )
        else if (_recommendedLawyers.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.search_off_rounded, color: Colors.grey[400], size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Aucun avocat trouvé", style: TextStyle(fontWeight: FontWeight.bold, color: darkText, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(
                        "Pas d'avocats enregistrés pour cette spécialité à $_selectedWilaya.",
                        style: TextStyle(color: greyText, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: _recommendedLawyers.asMap().entries
                .map((e) => _buildRecommendationCard(e.value, e.key))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildRecommendationCard(LawyerModel lawyer, int index) {
    final imageUrl = (lawyer.photoUrl != null && lawyer.photoUrl!.isNotEmpty)
        ? lawyer.photoUrl!
        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(lawyer.name)}&background=1565C0&color=ffffff';

    final medals = ['🥇', '🥈', '🥉'];
    final medal = index < 3 ? medals[index] : '⭐';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LawyerProfileScreen(lawyer: lawyer)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: index == 0 ? const Color(0xFFFFD700).withOpacity(0.5) : Colors.grey[200]!,
            width: index == 0 ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: index == 0 ? primaryColor.withOpacity(0.08) : Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(medal, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),

            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lawyer.name,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: darkText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: greyText),
                      const SizedBox(width: 3),
                      Text(lawyer.wilaya ?? '', style: TextStyle(color: greyText, fontSize: 12)),
                      if ((lawyer.experience ?? 0) > 0) ...[
                        Text("  •  ", style: TextStyle(color: greyText, fontSize: 12)),
                        Text("${lawyer.experience} ans exp.", style: TextStyle(color: greyText, fontSize: 12)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        lawyer.rating > 0 ? lawyer.rating.toStringAsFixed(1) : "Nouveau",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      if (lawyer.reviewCount > 0)
                        Text(" (${lawyer.reviewCount})", style: TextStyle(color: greyText, fontSize: 11)),
                      const Spacer(),
                      if (lawyer.finalScore > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${lawyer.finalScore.toStringAsFixed(0)}pts",
                            style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
    );
  }

  Widget _buildSpecialityGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _specialities.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.3,
      ),
      itemBuilder: (context, index) {
        final speciality = _specialities[index];
        final isSelected = _selectedSpeciality == speciality;

        return GestureDetector(
          onTap: () {
            setState(() => _selectedSpeciality = speciality);
            _onSelectionChanged();
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
                  color: isSelected ? primaryColor.withOpacity(0.15) : Colors.black.withOpacity(0.03),
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

  Widget _buildLocationForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
              _onSelectionChanged();
            },
          ),
          if (_selectedWilaya != null) const SizedBox(height: 15),
          if (_selectedWilaya != null)
            _buildDropdownField(
              value: _selectedCommune,
              hint: 'Commune (optionnel)',
              icon: Icons.location_city_rounded,
              items: _locations[_selectedWilaya]!,
              onChanged: (value) => setState(() => _selectedCommune = value),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(16)),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: greyText, fontSize: 13),
            prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.5), size: 18),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          ),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    final isFormValid = _selectedSpeciality != null && _selectedWilaya != null;

    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: isFormValid
            ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))]
            : [],
      ),
      child: ElevatedButton(
        onPressed: isFormValid ? _performSearch : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("VOIR TOUS LES AVOCATS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            SizedBox(width: 10),
            Icon(Icons.search_rounded, size: 22),
          ],
        ),
      ),
    );
  }

  void _performSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LawyersResultScreen(speciality: _selectedSpeciality!, wilaya: _selectedWilaya!),
      ),
    );
  }
}
