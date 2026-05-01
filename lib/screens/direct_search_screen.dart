import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/lawyer_model.dart';
import '../widgets/profile_avatar.dart';
import 'lawyer_profile_screen.dart';
import 'lawyers_result_screen.dart';

class DirectSearchScreen extends StatefulWidget {
  final String? preselectedSpeciality;
  const DirectSearchScreen({super.key, this.preselectedSpeciality});

  @override
  State<DirectSearchScreen> createState() => _DirectSearchScreenState();
}

class _DirectSearchScreenState extends State<DirectSearchScreen> with SingleTickerProviderStateMixin {
  String? _selectedSpeciality;
  String? _selectedWilaya;
  String? _selectedCommune;

  List<LawyerModel> _recommendedLawyers = [];
  bool _isLoadingRecs = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    if (widget.preselectedSpeciality != null) {
      _selectedSpeciality = widget.preselectedSpeciality;
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  final Color primaryColor = const Color(0xFF0052D4);
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final Color darkText = const Color(0xFF1E293B);
  final Color greyText = const Color(0xFF64748B);

  final List<Map<String, dynamic>> _specialities = [
    {'name': 'Généraliste', 'icon': Icons.account_balance_rounded, 'color': const Color(0xFF64748B)},
    {'name': 'Droit familial', 'icon': Icons.family_restroom_rounded, 'color': const Color(0xFF0052D4)},
    {'name': 'Droit pénal', 'icon': Icons.gavel_rounded, 'color': const Color(0xFFEF4444)},
    {'name': 'Droit commercial', 'icon': Icons.handshake_rounded, 'color': const Color(0xFF0F766E)},
    {'name': 'Droit civil', 'icon': Icons.groups_rounded, 'color': const Color(0xFF7C3AED)},
    {'name': 'Droit immobilier', 'icon': Icons.home_work_rounded, 'color': const Color(0xFF0369A1)},
    {'name': 'Droit administratif', 'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFF059669)},
    {'name': 'Droit du travail', 'icon': Icons.work_rounded, 'color': const Color(0xFFF59E0B)},
    {'name': 'Droit des sociétés', 'icon': Icons.business_center_rounded, 'color': const Color(0xFF0052D4)},
    {'name': 'Droit fiscal', 'icon': Icons.request_quote_rounded, 'color': const Color(0xFF7C3AED)},
    {'name': 'Propriété Intellectuelle', 'icon': Icons.lightbulb_rounded, 'color': const Color(0xFF7C3AED)},
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
      final snap = await FirebaseFirestore.instance.collection('lawyers').get();
      var lawyers = snap.docs.map((d) => LawyerModel.fromMap(d.data())).where((l) {
        final lawyerSpec = l.speciality.toLowerCase();
        final searchSpec = (_selectedSpeciality ?? '').toLowerCase();
        final wilayaMatch = (l.wilaya ?? '').toLowerCase() == _selectedWilaya!.trim().toLowerCase();
        return lawyerSpec.contains(searchSpec) && wilayaMatch;
      }).toList();

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
    HapticFeedback.lightImpact();
    if (_selectedSpeciality != null && _selectedWilaya != null) {
      _fetchRecommendations();
    } else {
      setState(() => _recommendedLawyers = []);
    }
  }

  void _performSearch() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LawyersResultScreen(speciality: _selectedSpeciality!, wilaya: _selectedWilaya!),
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
                      right: -20,
                      top: 10,
                      child: Icon(Icons.travel_explore_rounded, size: 150, color: Colors.white.withOpacity(0.1)),
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
                            child: const Text('RECHERCHE DIRECTE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Trouvez votre avocat',
                            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
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
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("1", "Spécialité juridique", "Quelle est la nature de votre affaire ?"),
                      const SizedBox(height: 20),
                      _buildSpecialityGrid(),
                      
                      const SizedBox(height: 40),
                      _buildSectionHeader("2", "Localisation", "Où cherchez-vous votre avocat ?"),
                      const SizedBox(height: 20),
                      _buildLocationForm(),

                      if (_selectedSpeciality != null && _selectedWilaya != null) ...[
                        const SizedBox(height: 40),
                        _buildSectionHeader("3", "Recommandations", "Avocats correspondant à vos critères"),
                        const SizedBox(height: 20),
                        _buildRecommendationsSection(),
                      ],

                      const SizedBox(height: 40),
                      _buildSearchButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String number, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(number, style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: darkText, fontSize: 18, fontWeight: FontWeight.w800)),
              Text(subtitle, style: TextStyle(color: greyText, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialityGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _specialities.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, index) {
        final speciality = _specialities[index];
        final isSelected = _selectedSpeciality == speciality['name'];
        final color = speciality['color'] as Color;

        return GestureDetector(
          onTap: () {
            setState(() => _selectedSpeciality = speciality['name']);
            _onSelectionChanged();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? primaryColor : Colors.grey.shade200,
                width: 1.5,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                else
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    speciality['icon'],
                    color: isSelected ? Colors.white : color,
                    size: 18,
                  ),
                ),
                const Spacer(),
                Text(
                  speciality['name'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF1E293B),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
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
          if (_selectedWilaya != null) ...[
            const SizedBox(height: 16),
            _buildDropdownField(
              value: _selectedCommune,
              hint: 'Commune (optionnel)',
              icon: Icons.location_city_rounded,
              items: _locations[_selectedWilaya]!,
              onChanged: (value) => setState(() => _selectedCommune = value),
            ),
          ]
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.expand_more_rounded, color: greyText),
          hint: Row(
            children: [
              Icon(icon, color: primaryColor.withOpacity(0.5), size: 20),
              const SizedBox(width: 12),
              Text(hint, style: TextStyle(color: greyText, fontSize: 14)),
            ],
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Row(
                children: [
                  Icon(icon, color: primaryColor, size: 20),
                  const SizedBox(width: 12),
                  Text(item, style: TextStyle(color: darkText, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    if (_isLoadingRecs) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2.5),
        ),
      );
    }

    if (_recommendedLawyers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
              child: Icon(Icons.search_off_rounded, color: greyText, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Aucun résultat", style: TextStyle(fontWeight: FontWeight.w700, color: darkText, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    "Aucun avocat enregistré pour $_selectedSpeciality à $_selectedWilaya.",
                    style: TextStyle(color: greyText, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _recommendedLawyers.asMap().entries.map((e) => _buildRecommendationCard(e.value, e.key)).toList(),
    );
  }

  Widget _buildRecommendationCard(LawyerModel lawyer, int index) {
    final bool isTop = index == 0;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => LawyerProfileScreen(lawyer: lawyer)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isTop ? const Color(0xFFF59E0B) : Colors.grey.shade200,
            width: isTop ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isTop ? const Color(0xFFF59E0B).withOpacity(0.1) : Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (isTop)
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFDE68A))),
                child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 20),
              ),
            ProfileAvatar(
              imageBase64: lawyer.profileImageBase64,
              name: lawyer.name,
              size: 56,
              borderColor: isTop ? const Color(0xFFFDE68A) : Colors.grey.shade200,
              borderWidth: 2,
              backgroundColor: primaryColor,
            ),
            const SizedBox(width: 16),
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 12, color: greyText),
                      const SizedBox(width: 4),
                      Text(lawyer.wilaya ?? '', style: TextStyle(color: greyText, fontSize: 12, fontWeight: FontWeight.w500)),
                      if ((lawyer.experience ?? 0) > 0) ...[
                        Text(" • ", style: TextStyle(color: greyText, fontSize: 12)),
                        Text("${lawyer.experience} ans exp", style: TextStyle(color: greyText, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              lawyer.rating > 0 ? lawyer.rating.toStringAsFixed(1) : "Nouveau",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFD97706)),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (lawyer.finalScore > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            "${lawyer.finalScore.toStringAsFixed(0)} pts",
                            style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    final isFormValid = _selectedSpeciality != null && _selectedWilaya != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: isFormValid
            ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]
            : [],
      ),
      child: ElevatedButton(
        onPressed: isFormValid ? _performSearch : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          disabledBackgroundColor: Colors.grey.shade200,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("VOIR TOUS LES RÉSULTATS", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5)),
            SizedBox(width: 12),
            Icon(Icons.search_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}
