import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'post_request_screen.dart';
import 'direct_search_screen.dart';
import 'ai_assistant_screen.dart' show AIAssistantScreen;

const _navy   = Color(0xFF0A1628);
const _navyM  = Color(0xFF112240);
const _gold   = Color(0xFFB8963E);
const _bg     = Color(0xFFF5F7FA);
const _grey   = Color(0xFF8896A5);

class ChooseMethodScreen extends StatelessWidget {
  final VoidCallback? onBack;
  const ChooseMethodScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _navy, size: 20),
          onPressed: () => onBack != null ? onBack!() : Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_navy, _navyM],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: _navy.withOpacity(0.25),
                  blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _gold.withOpacity(0.3)),
                ),
                child: const Icon(Icons.balance_rounded, color: _gold, size: 32),
              ),
              const SizedBox(height: 14),
              Text('how_can_i_help'.tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 22,
                      fontWeight: FontWeight.w900), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text('choose_method'.tr(),
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                  textAlign: TextAlign.center),
            ]),
          ),
          const SizedBox(height: 28),

          _OptionCard(icon: Icons.search_rounded, title: 'i_know_my_case'.tr(),
              subtitle: 'select_legal_domain'.tr(),
              color: const Color(0xFF1565C0),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DirectSearchScreen()))),
          const SizedBox(height: 14),

          _OptionCard(icon: Icons.quiz_rounded, title: 'guided_questionnaire'.tr(),
              subtitle: 'answer_questions'.tr(),
              color: const Color(0xFF6B46C1), badge: 'SMART',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const _QuestionnaireScreen()))),
          const SizedBox(height: 14),

          _OptionCard(icon: Icons.auto_awesome_rounded, title: 'ai_assistant'.tr(),
              subtitle: 'describe_freely'.tr(),
              color: const Color(0xFF7C3AED), badge: 'IA',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AIAssistantScreen()))),
          const SizedBox(height: 14),

          _OptionCard(icon: Icons.mail_outline_rounded, title: 'post_request'.tr(),
              subtitle: 'lawyers_contact_you'.tr(),
              color: const Color(0xFF0D7C66),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PostRequestScreen()))),
        ]),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _OptionCard({required this.icon, required this.title,
      required this.subtitle, required this.color,
      required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(width: 56, height: 56,
                decoration: BoxDecoration(color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: color, size: 28)),
            if (badge != null)
              Positioned(top: -6, right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: color,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(badge!, style: const TextStyle(color: Colors.white,
                      fontSize: 9, fontWeight: FontWeight.w800)),
                )),
          ]),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 16,
                fontWeight: FontWeight.w800, color: _navy)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: _grey, fontSize: 12, height: 1.3)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color.withOpacity(0.4)),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// QUESTIONNAIRE — شجرة قرارات ذكية
// ══════════════════════════════════════════════════════════════════
class _QNode {
  final String id;
  final String question;
  final String? subtitle;
  final List<_QOption> options;
  const _QNode({required this.id, required this.question,
      this.subtitle, required this.options});
}

class _QOption {
  final String label;
  final String? emoji;
  final String? nextId;
  final String? result;
  const _QOption({required this.label, this.emoji, this.nextId, this.result});
}

const List<_QNode> _tree = [
  _QNode(id: 'root',
    question: 'q_main_domain_title',
    subtitle: 'q_main_domain_subtitle',
    options: [
      _QOption(label: 'Famille & Personnes',         emoji: '👨‍👩‍👧', nextId: 'famille'),
      _QOption(label: 'Travail & Emploi',             emoji: '💼', nextId: 'travail'),
      _QOption(label: 'Bien immobilier',              emoji: '🏠', nextId: 'immo'),
      _QOption(label: 'Business & Contrats',          emoji: '🤝', nextId: 'business'),
      _QOption(label: 'Justice & Pénal',              emoji: '⚖️', nextId: 'penal'),
      _QOption(label: 'Administration & État',        emoji: '🏛️', nextId: 'admin'),
      _QOption(label: 'Autre / Je ne sais pas',       emoji: '❓', nextId: 'autre'),
    ]),

  _QNode(id: 'famille',
    question: 'q_famille_title',
    options: [
      _QOption(label: 'Divorce ou séparation',             emoji: '💔', result: 'Droit familial'),
      _QOption(label: 'Garde des enfants / Pension',       emoji: '👶', result: 'Droit familial'),
      _QOption(label: 'Héritage / Succession',             emoji: '📜', result: 'Droit familial'),
      _QOption(label: 'Violence conjugale / familiale',    emoji: '🚨', result: 'Droit pénal'),
      _QOption(label: 'Adoption / Tutelle',                emoji: '🤲', result: 'Droit familial'),
      _QOption(label: 'Mariage / Contrat de mariage',      emoji: '💍', result: 'Droit civil'),
    ]),

  _QNode(id: 'travail',
    question: 'q_travail_title',
    options: [
      _QOption(label: 'Licenciement abusif / injustifié',  emoji: '🔴', result: 'Droit du travail'),
      _QOption(label: 'Salaire impayé / retard',           emoji: '💰', result: 'Droit du travail'),
      _QOption(label: 'Harcèlement au travail',            emoji: '⚠️', result: 'Droit du travail'),
      _QOption(label: 'Accident du travail',               emoji: '🏥', result: 'Droit du travail'),
      _QOption(label: 'Contrat de travail non respecté',   emoji: '📄', result: 'Droit du travail'),
      _QOption(label: 'Litige avec une entreprise',        emoji: '🏢', result: 'Droit commercial'),
    ]),

  _QNode(id: 'immo',
    question: 'q_immo_title',
    options: [
      _QOption(label: "Achat / Vente d'un bien",          emoji: '🏡', result: 'Droit immobilier'),
      _QOption(label: 'Location / Bail / Expulsion',       emoji: '🔑', result: 'Droit immobilier'),
      _QOption(label: 'Construction / Permis',             emoji: '🔨', result: 'Droit immobilier'),
      _QOption(label: 'Litige avec voisinage',             emoji: '🤼', result: 'Droit immobilier'),
      _QOption(label: "Expropriation par l'État",         emoji: '⚡', result: 'Droit administratif'),
      _QOption(label: 'Copropriété / Syndic',              emoji: '🏢', result: 'Droit immobilier'),
    ]),

  _QNode(id: 'business',
    question: 'q_business_title',
    options: [
      _QOption(label: 'Contrat non respecté',              emoji: '📋', result: 'Droit commercial'),
      _QOption(label: 'Création / Dissolution société',    emoji: '🏭', result: 'Droit des sociétés'),
      _QOption(label: 'Faillite / Dettes',                 emoji: '📉', result: 'Droit commercial'),
      _QOption(label: 'Arnaque / Escroquerie',             emoji: '⚠️', nextId: 'escroquerie'),
      _QOption(label: 'Impôts / Taxes',                    emoji: '💸', result: 'Droit fiscal'),
      _QOption(label: 'Brevet / Marque / Copyright',       emoji: '💡', result: 'Propriété Intellectuelle'),
    ]),

  _QNode(id: 'escroquerie',
    question: "q_escroquerie_title",
    options: [
      _QOption(label: 'Transaction commerciale',           emoji: '💼', result: 'Droit commercial'),
      _QOption(label: 'Achat en ligne / Fraude',           emoji: '💻', result: 'Droit pénal'),
      _QOption(label: 'Faux documents / Usurpation',       emoji: '🪪', result: 'Droit pénal'),
      _QOption(label: 'Arnaque immobilière',               emoji: '🏠', result: 'Droit immobilier'),
    ]),

  _QNode(id: 'penal',
    question: 'q_penal_title',
    options: [
      _QOption(label: "Je suis victime d'une agression",  emoji: '🚨', result: 'Droit pénal'),
      _QOption(label: 'Je suis accusé / poursuivi',        emoji: '⚖️', result: 'Droit pénal'),
      _QOption(label: 'Violation de contrat / Fraude',     emoji: '📄', result: 'Droit civil'),
      _QOption(label: 'Diffamation / Injure / Calomnie',   emoji: '🗣️', result: 'Droit pénal'),
      _QOption(label: 'Cybercriminalité',                  emoji: '💻', result: 'Droit pénal'),
    ]),

  _QNode(id: 'admin',
    question: 'q_admin_title',
    options: [
      _QOption(label: 'Refus de permis / Autorisation',   emoji: '🚫', result: 'Droit administratif'),
      _QOption(label: "Litige avec l'État / Commune",    emoji: '🏛️', result: 'Droit administratif'),
      _QOption(label: 'Nationalité / Visa / Documents',   emoji: '📘', result: 'Droit administratif'),
      _QOption(label: "Marché public / Appel d'offres",  emoji: '📊', result: 'Droit administratif'),
      _QOption(label: 'Recours contre une décision',      emoji: '📩', result: 'Droit administratif'),
    ]),

  _QNode(id: 'autre',
    question: 'q_autre_title',
    options: [
      _QOption(label: 'Problème avec une personne',              emoji: '👤', result: 'Droit civil'),
      _QOption(label: 'Problème avec une entreprise',            emoji: '🏢', result: 'Droit commercial'),
      _QOption(label: "Problème avec l'administration",         emoji: '🏛️', result: 'Droit administratif'),
      _QOption(label: 'Problème personnel / familial',           emoji: '👨‍👩‍👧', result: 'Droit familial'),
      _QOption(label: 'Affaire pénale / judiciaire',             emoji: '⚖️', result: 'Droit pénal'),
    ]),
];

_QNode? _findNode(String id) {
  try { return _tree.firstWhere((n) => n.id == id); } catch (_) { return null; }
}

class _QuestionnaireScreen extends StatefulWidget {
  const _QuestionnaireScreen();
  @override
  State<_QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<_QuestionnaireScreen> {
  final List<_QNode> _history = [];
  _QNode? _current;
  String? _result;
  String? _selectedOption;

  @override
  void initState() { super.initState(); _current = _findNode('root'); }

  void _onOptionTap(_QOption option) {
    setState(() => _selectedOption = option.label);
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _selectedOption = null;
        if (option.result != null) {
          _result = option.result;
          _current = null;
        } else if (option.nextId != null) {
          _history.add(_current!);
          _current = _findNode(option.nextId!);
        }
      });
    });
  }

  void _goBack() {
    setState(() {
      if (_result != null) {
        _result = null;
        _current = _history.isNotEmpty ? _history.last : _findNode('root');
      } else if (_history.isNotEmpty) {
        _current = _history.removeLast();
      } else {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _navy, size: 20),
          onPressed: _goBack,
        ),
        title: Text(
          _result != null ? 'result'.tr() : '${'step'.tr()} ${_history.length + 1}',
          style: const TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, anim) => SlideTransition(
          position: Tween<Offset>(
              begin: const Offset(0.05, 0), end: Offset.zero).animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: _result != null
            ? _buildResult(_result!, key: const ValueKey('result'))
            : _buildQuestion(_current!, key: ValueKey(_current!.id)),
      ),
    );
  }

  Widget _buildQuestion(_QNode node, {Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_history.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _history.length / (_tree.length.toDouble()),
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(_gold),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_navy, _navyM],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _gold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _history.isEmpty ? 'main_category'.tr() : 'specify'.tr(),
                style: const TextStyle(color: _gold, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            Text(node.question.tr(), style: const TextStyle(color: Colors.white,
                fontSize: 18, fontWeight: FontWeight.w800, height: 1.3)),
            if (node.subtitle != null) ...[
              const SizedBox(height: 6),
              Text(node.subtitle!.tr(), style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 12, height: 1.4)),
            ],
          ]),
        ),
        const SizedBox(height: 18),
        ...node.options.map((opt) => _OptionTile(
          option: opt, isSelected: _selectedOption == opt.label,
          onTap: () => _onOptionTap(opt),
        )),
      ]),
    );
  }

  Widget _buildResult(String recommendation, {Key? key}) {
    final icons = <String, IconData>{
      'Droit familial': Icons.family_restroom_rounded,
      'Droit pénal': Icons.gavel_rounded,
      'Droit commercial': Icons.handshake_rounded,
      'Droit civil': Icons.balance_rounded,
      'Droit immobilier': Icons.home_rounded,
      'Droit administratif': Icons.account_balance_rounded,
      'Droit du travail': Icons.work_rounded,
      'Droit des sociétés': Icons.business_rounded,
      'Droit fiscal': Icons.receipt_long_rounded,
      'Propriété Intellectuelle': Icons.lightbulb_rounded,
    };

    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_navy, _navyM],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: _navy.withOpacity(0.25),
                blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _gold.withOpacity(0.15), shape: BoxShape.circle,
                border: Border.all(color: _gold.withOpacity(0.3)),
              ),
              child: Icon(icons[recommendation] ?? Icons.balance_rounded,
                  color: _gold, size: 40),
            ),
            const SizedBox(height: 16),
            Text('we_recommend'.tr(),
                style: const TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 8),
            Text(recommendation.tr(), style: const TextStyle(color: Colors.white,
                fontSize: 22, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _gold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _gold.withOpacity(0.3)),
              ),
              child: Text('based_on_answers'.tr(),
                  style: const TextStyle(color: _gold, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200)),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, color: _gold, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(
              'system_analysis'.tr(),
              style: TextStyle(color: _grey, fontSize: 12, height: 1.4),
            )),
          ]),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => DirectSearchScreen(preselectedSpeciality: recommendation)));
            },
            icon: const Icon(Icons.search_rounded, size: 20),
            label: Text('search_lawyer'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold, foregroundColor: _navy,
              elevation: 4, shadowColor: _gold.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 48,
          child: OutlinedButton.icon(
            onPressed: () => setState(() {
              _history.clear(); _result = null; _current = _findNode('root');
            }),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('restart'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _navy,
              side: BorderSide(color: _navy.withOpacity(0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final _QOption option;
  final bool isSelected;
  final VoidCallback onTap;
  const _OptionTile({required this.option, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? _navy : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _navy : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [BoxShadow(
            color: isSelected ? _navy.withOpacity(0.15) : Colors.black.withOpacity(0.03),
            blurRadius: isSelected ? 12 : 6,
            offset: const Offset(0, 3),
          )],
        ),
        child: Row(children: [
          if (option.emoji != null) ...[
            Text(option.emoji!, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
          ],
          Expanded(child: Text(option.label.tr(), style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : _navy))),
          Icon(
            option.result != null
                ? Icons.check_circle_outline_rounded
                : Icons.arrow_forward_ios_rounded,
            size: isSelected ? 18 : 14,
            color: isSelected ? _gold
                : (option.result != null ? _gold : Colors.grey.shade300),
          ),
        ]),
      ),
    );
  }
}
