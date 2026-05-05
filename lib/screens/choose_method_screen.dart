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

  // ══════════════════════════════════════════════════════════════
  // RACINE — Qui est concerné ?
  // ══════════════════════════════════════════════════════════════
  _QNode(
    id: 'root',
    question: 'Qui est impliqué dans votre problème ?',
    subtitle: 'Choisissez la situation qui vous correspond le mieux',
    options: [
      _QOption(label: 'Un membre de ma famille',             emoji: '👨‍👩‍👧', nextId: 'famille'),
      _QOption(label: 'Mon employeur ou un collègue',        emoji: '💼', nextId: 'travail_qui'),
      _QOption(label: 'Un bien immobilier ou logement',      emoji: '🏠', nextId: 'immo_role'),
      _QOption(label: 'Une autre personne ou citoyen',       emoji: '👤', nextId: 'civil_type'),
      _QOption(label: 'La justice / une affaire pénale',     emoji: '⚖️', nextId: 'penal_qui'),
      _QOption(label: "L'État ou l'administration",          emoji: '🏛️', nextId: 'admin_type'),
      _QOption(label: 'Mon entreprise ou activité commerciale', emoji: '🤝', nextId: 'business_type'),
      _QOption(label: 'Ma santé ou un médecin',              emoji: '🏥', nextId: 'sante'),
      _QOption(label: 'Une assurance',                       emoji: '🛡️', nextId: 'assurance'),
      _QOption(label: 'Internet / Réseaux sociaux',          emoji: '💻', nextId: 'cyber'),
      _QOption(label: 'Un véhicule ou accident de la route', emoji: '🚗', nextId: 'route'),
      _QOption(label: 'Autre / Je ne sais pas',              emoji: '❓', nextId: 'autre'),
    ],
  ),

  // ══════════════════════════════════════════════════════════════
  // FAMILLE
  // ══════════════════════════════════════════════════════════════
  _QNode(
    id: 'famille',
    question: 'Quel est le problème familial ?',
    options: [
      _QOption(label: 'Divorce ou séparation',               emoji: '💔', nextId: 'famille_divorce'),
      _QOption(label: 'Héritage ou succession',              emoji: '📜', nextId: 'famille_heritage'),
      _QOption(label: 'Violence conjugale ou familiale',     emoji: '🚨', nextId: 'famille_violence'),
      _QOption(label: 'Enfants (garde, pension, adoption)',  emoji: '👶', nextId: 'famille_enfants'),
      _QOption(label: 'Mariage ou contrat de mariage',       emoji: '💍', nextId: 'famille_mariage'),
      _QOption(label: 'Tutelle ou curatelle',                emoji: '🤲', result: 'Droit de la famille — Tutelle'),
      _QOption(label: 'Personne disparue ou déclarée absente', emoji: '🔍', result: 'Droit civil — Déclaration d\'absence'),
    ],
  ),

  _QNode(
    id: 'famille_divorce',
    question: 'À quel stade en êtes-vous ?',
    options: [
      _QOption(label: 'Nous voulons divorcer à l\'amiable',         emoji: '🤝', result: 'Droit de la famille — Divorce par consentement mutuel'),
      _QOption(label: 'Mon conjoint refuse le divorce',             emoji: '🚫', result: 'Droit de la famille — Divorce contentieux'),
      _QOption(label: 'Divorce en cours, besoin d\'accompagnement', emoji: '⚖️', result: 'Droit de la famille — Procédure de divorce'),
      _QOption(label: 'Divorce prononcé, problème d\'exécution',    emoji: '📋', result: 'Droit de la famille — Exécution jugement de divorce'),
      _QOption(label: 'Séparation de fait sans jugement',           emoji: '💔', result: 'Droit de la famille — Séparation de corps'),
    ],
  ),

  _QNode(
    id: 'famille_heritage',
    question: 'Quelle est la nature du litige successoral ?',
    options: [
      _QOption(label: 'Partage inégal ou contesté entre héritiers',       emoji: '📋', result: 'Droit de la famille — Partage successoral'),
      _QOption(label: 'Un héritier est exclu ou oublié',                   emoji: '👤', result: 'Droit de la famille — Réserve héréditaire'),
      _QOption(label: 'Testament contesté',                                emoji: '📜', result: 'Droit civil — Contestation de testament'),
      _QOption(label: 'Dettes du défunt à régler',                        emoji: '💸', result: 'Droit civil — Succession avec dettes'),
      _QOption(label: 'Bien immobilier hérité en indivision',             emoji: '🏠', result: 'Droit immobilier — Indivision successorale'),
      _QOption(label: 'Héritier absent ou introuvable',                   emoji: '🔍', result: 'Droit de la famille — Succession avec héritier absent'),
      _QOption(label: 'Donation contestée avant le décès',                emoji: '🎁', result: 'Droit civil — Rapport à succession'),
    ],
  ),

  _QNode(
    id: 'famille_violence',
    question: 'Quelle est la situation ?',
    options: [
      _QOption(label: 'Violence physique par le conjoint',          emoji: '🚨', result: 'Droit pénal — Violence conjugale (victime)'),
      _QOption(label: 'Violence psychologique ou harcèlement moral', emoji: '⚠️', result: 'Droit pénal — Harcèlement moral conjugal'),
      _QOption(label: 'Violence sur enfant ou maltraitance',        emoji: '👶', result: 'Droit pénal — Protection de l\'enfance'),
      _QOption(label: 'Violence sur personne âgée',                 emoji: '👴', result: 'Droit pénal — Maltraitance personne âgée'),
      _QOption(label: 'Je suis accusé de violence',                 emoji: '⚖️', result: 'Droit pénal — Défense accusé violence familiale'),
    ],
  ),

  _QNode(
    id: 'famille_enfants',
    question: 'Quel est le problème concernant les enfants ?',
    options: [
      _QOption(label: 'Garde contestée après séparation',              emoji: '⚖️', result: 'Droit de la famille — Garde d\'enfants'),
      _QOption(label: 'Pension alimentaire impayée',                   emoji: '💰', result: 'Droit de la famille — Recouvrement pension alimentaire'),
      _QOption(label: 'Droit de visite non respecté',                  emoji: '🚫', result: 'Droit de la famille — Droit de visite'),
      _QOption(label: 'Adoption d\'un enfant',                         emoji: '🤲', result: 'Droit de la famille — Adoption'),
      _QOption(label: 'Établissement ou contestation de paternité',    emoji: '🧬', result: 'Droit de la famille — Filiation'),
      _QOption(label: 'Enlèvement parental (conjoint a emmené l\'enfant)', emoji: '🚨', result: 'Droit de la famille — Enlèvement parental'),
    ],
  ),

  _QNode(
    id: 'famille_mariage',
    question: 'Quel est le problème lié au mariage ?',
    options: [
      _QOption(label: 'Refus de mariage (wali, administration...)',    emoji: '🚫', result: 'Droit de la famille — Empêchement au mariage'),
      _QOption(label: 'Mariage non enregistré à l\'état civil',        emoji: '📋', result: 'Droit de la famille — Enregistrement mariage'),
      _QOption(label: 'Mariage forcé ou non consenti',                 emoji: '⚠️', result: 'Droit pénal — Mariage forcé'),
      _QOption(label: 'Contrat de mariage et séparation de biens',     emoji: '📄', result: 'Droit civil — Régime matrimonial'),
      _QOption(label: 'Polygamie ou mariage non déclaré',              emoji: '⚖️', result: 'Droit de la famille — Polygamie et droits'),
    ],
  ),

  // ══════════════════════════════════════════════════════════════
  // TRAVAIL
  // ══════════════════════════════════════════════════════════════
  _QNode(
    id: 'travail_qui',
    question: 'Vous êtes :',
    options: [
      _QOption(label: 'Salarié dans le secteur privé',     emoji: '👷', nextId: 'travail_salarie'),
      _QOption(label: 'Fonctionnaire (secteur public)',    emoji: '🏛️', nextId: 'travail_fonct'),
      _QOption(label: 'Employeur ou dirigeant',            emoji: '🏢', nextId: 'travail_employeur'),
      _QOption(label: 'Travailleur indépendant / freelance', emoji: '🧑‍💻', nextId: 'travail_independant'),
      _QOption(label: 'En recherche d\'emploi',            emoji: '🔍', nextId: 'travail_chomage'),
    ],
  ),

  _QNode(
    id: 'travail_salarie',
    question: 'Quel est le problème avec votre employeur ?',
    options: [
      _QOption(label: 'Licenciement que j\'estime injustifié ou abusif', emoji: '🔴', nextId: 'travail_licenciement'),
      _QOption(label: 'Salaire impayé, retenu ou insuffisant',           emoji: '💰', result: 'Droit du travail — Salaire impayé'),
      _QOption(label: 'Harcèlement moral ou sexuel au travail',          emoji: '⚠️', result: 'Droit du travail — Harcèlement'),
      _QOption(label: 'Accident survenu pendant le travail',             emoji: '🏥', nextId: 'travail_accident'),
      _QOption(label: 'Contrat non respecté par l\'employeur',           emoji: '📄', result: 'Droit du travail — Non-respect contrat'),
      _QOption(label: 'Refus de congé, mutation forcée',                 emoji: '📍', result: 'Droit du travail — Droits du salarié'),
      _QOption(label: 'Discrimination (genre, religion, origine...)',    emoji: '🚫', result: 'Droit du travail — Discrimination'),
      _QOption(label: 'Heures supplémentaires non payées',               emoji: '⏰', result: 'Droit du travail — Heures supplémentaires'),
    ],
  ),

  _QNode(
    id: 'travail_licenciement',
    question: 'Comment s\'est passé le licenciement ?',
    options: [
      _QOption(label: 'Sans préavis ni indemnité',                    emoji: '🔴', result: 'Droit du travail — Licenciement abusif sans indemnité'),
      _QOption(label: 'Avec préavis mais raison contestée',           emoji: '📋', result: 'Droit du travail — Contestation motif licenciement'),
      _QOption(label: 'Suite à une grève ou action syndicale',        emoji: '✊', result: 'Droit du travail — Licenciement syndical (illégal)'),
      _QOption(label: 'Pendant une grossesse ou congé maternité',     emoji: '🤰', result: 'Droit du travail — Licenciement protection maternité'),
      _QOption(label: 'Suite à une plainte pour harcèlement',         emoji: '⚠️', result: 'Droit du travail — Licenciement représailles'),
    ],
  ),

  _QNode(
    id: 'travail_accident',
    question: 'Quelle est la situation après l\'accident ?',
    options: [
      _QOption(label: 'L\'employeur refuse de déclarer l\'accident',  emoji: '🚫', result: 'Droit du travail — Déclaration accident de travail'),
      _QOption(label: 'Indemnisation insuffisante ou refusée',        emoji: '💰', result: 'Droit du travail — Indemnisation accident de travail'),
      _QOption(label: 'Séquelles permanentes, invalidité',            emoji: '🦽', result: 'Droit du travail — Invalidité professionnelle'),
      _QOption(label: 'Accident de trajet domicile-travail',          emoji: '🚗', result: 'Droit du travail — Accident de trajet'),
    ],
  ),

  _QNode(
    id: 'travail_fonct',
    question: 'Quel est votre problème en tant que fonctionnaire ?',
    options: [
      _QOption(label: 'Sanction disciplinaire contestée',             emoji: '🚫', result: 'Droit administratif — Sanction disciplinaire fonctionnaire'),
      _QOption(label: 'Mutation ou affectation imposée',              emoji: '📍', result: 'Droit administratif — Mutation fonctionnaire'),
      _QOption(label: 'Refus de promotion ou d\'avancement',          emoji: '📈', result: 'Droit administratif — Avancement fonctionnaire'),
      _QOption(label: 'Salaire, prime ou indemnité non versée',       emoji: '💰', result: 'Droit du travail — Rémunération fonctionnaire'),
      _QOption(label: 'Harcèlement par un supérieur hiérarchique',    emoji: '⚠️', result: 'Droit administratif — Harcèlement fonctionnaire'),
      _QOption(label: 'Mise à la retraite forcée ou anticipée',       emoji: '👴', result: 'Droit administratif — Retraite fonctionnaire'),
      _QOption(label: 'Licenciement ou révocation contestés',         emoji: '🔴', result: 'Droit administratif — Révocation fonctionnaire'),
    ],
  ),

  _QNode(
    id: 'travail_employeur',
    question: 'Quel est le problème avec votre employé ?',
    options: [
      _QOption(label: 'Faute grave, vol ou fraude',                   emoji: '🔐', nextId: 'travail_employeur_faute'),
      _QOption(label: 'Contestation d\'un licenciement par l\'employé', emoji: '📋', result: 'Droit du travail — Défense employeur licenciement'),
      _QOption(label: 'Concurrence déloyale après départ',            emoji: '⚠️', result: 'Droit commercial — Concurrence déloyale'),
      _QOption(label: 'Grève ou conflit collectif',                   emoji: '✊', result: 'Droit du travail — Conflit collectif'),
      _QOption(label: 'Employé en arrêt maladie abusif',              emoji: '🏥', result: 'Droit du travail — Arrêt maladie contesté'),
    ],
  ),

  _QNode(
    id: 'travail_employeur_faute',
    question: 'Quelle est la gravité de la faute ?',
    options: [
      _QOption(label: 'Vol ou détournement de fonds',                 emoji: '💸', result: 'Droit pénal + Droit du travail — Faute pénale employé'),
      _QOption(label: 'Divulgation de secrets professionnels',        emoji: '🔓', result: 'Droit commercial — Secret professionnel'),
      _QOption(label: 'Insubordination répétée',                      emoji: '🚫', result: 'Droit du travail — Faute grave licenciement'),
      _QOption(label: 'Harcèlement envers d\'autres employés',        emoji: '⚠️', result: 'Droit du travail — Responsabilité employeur harcèlement'),
    ],
  ),

  _QNode(
    id: 'travail_independant',
    question: 'Quel est votre problème ?',
    options: [
      _QOption(label: 'Client qui ne paye pas la prestation',         emoji: '💸', result: 'Droit commercial — Recouvrement créance'),
      _QOption(label: 'Contrat de mission non respecté',              emoji: '📋', result: 'Droit commercial — Inexécution contrat prestation'),
      _QOption(label: 'Litige fiscal ou déclaration contestée',       emoji: '🧾', result: 'Droit fiscal — Indépendant'),
      _QOption(label: 'Requalification en salarié par l\'employeur',  emoji: '⚖️', result: 'Droit du travail — Requalification contrat'),
      _QOption(label: 'Propriété intellectuelle sur mon travail',     emoji: '💡', result: 'Droit de la propriété intellectuelle — Indépendant'),
    ],
  ),

  _QNode(
    id: 'travail_chomage',
    question: 'Quel est le problème ?',
    options: [
      _QOption(label: 'Refus d\'allocations chômage',                 emoji: '🚫', result: 'Droit du travail — Allocations chômage'),
      _QOption(label: 'Discrimination à l\'embauche',                 emoji: '⚠️', result: 'Droit du travail — Discrimination embauche'),
      _QOption(label: 'Promesse d\'embauche non tenue',               emoji: '📋', result: 'Droit du travail — Promesse d\'embauche'),
      _QOption(label: 'Stage non rémunéré ou abusif',                 emoji: '📄', result: 'Droit du travail — Convention de stage'),
    ],
  ),

  // ══════════════════════════════════════════════════════════════
  // IMMOBILIER
  // ══════════════════════════════════════════════════════════════
  _QNode(
    id: 'immo_role',
    question: 'Vous êtes :',
    options: [
      _QOption(label: 'Propriétaire qui loue un bien',              emoji: '🔑', nextId: 'immo_proprio'),
      _QOption(label: 'Locataire dans un logement',                 emoji: '🏠', nextId: 'immo_locataire'),
      _QOption(label: 'Acheteur ou vendeur d\'un bien',             emoji: '🤝', nextId: 'immo_achat'),
      _QOption(label: 'Co-héritier d\'un bien immobilier',          emoji: '👥', result: 'Droit immobilier — Indivision et partage'),
      _QOption(label: 'Propriétaire avec voisinage ou construction', emoji: '🔨', nextId: 'immo_construction'),
      _QOption(label: 'Bien exproprié ou menacé par l\'État',       emoji: '⚡', result: 'Droit administratif — Expropriation'),
    ],
  ),

  _QNode(
    id: 'immo_proprio',
    question: 'Quel est le problème avec votre locataire ?',
    options: [
      _QOption(label: 'Loyer impayé depuis plusieurs mois',          emoji: '💰', result: 'Droit immobilier — Loyer impayé et expulsion'),
      _QOption(label: 'Locataire refuse de quitter les lieux',       emoji: '🚪', result: 'Droit immobilier — Expulsion locataire'),
      _QOption(label: 'Dégradation du logement',                     emoji: '🛠️', result: 'Droit immobilier — Réparation dégradations'),
      _QOption(label: 'Sous-location non autorisée',                 emoji: '🚫', result: 'Droit immobilier — Sous-location illégale'),
      _QOption(label: 'Logement utilisé à des fins illicites',       emoji: '⚠️', result: 'Droit pénal + Immobilier — Usage illicite du bien'),
      _QOption(label: 'Locataire décédé, succession compliquée',     emoji: '📜', result: 'Droit immobilier — Transmission bail'),
    ],
  ),

  _QNode(
    id: 'immo_locataire',
    question: 'Quel est le problème avec votre propriétaire ?',
    options: [
      _QOption(label: 'Expulsion que j\'estime abusive ou illégale', emoji: '🚪', result: 'Droit immobilier — Contestation expulsion'),
      _QOption(label: 'Logement insalubre ou non entretenu',         emoji: '🛠️', result: 'Droit immobilier — Logement indécent'),
      _QOption(label: 'Augmentation abusive du loyer',               emoji: '💸', result: 'Droit immobilier — Contestation augmentation loyer'),
      _QOption(label: 'Caution ou dépôt de garantie non restitué',   emoji: '💰', result: 'Droit immobilier — Restitution caution'),
      _QOption(label: 'Propriétaire harcèle ou menace',              emoji: '⚠️', result: 'Droit pénal — Harcèlement propriétaire'),
      _QOption(label: 'Travaux imposés sans accord',                 emoji: '🔨', result: 'Droit immobilier — Travaux sans accord locataire'),
    ],
  ),

  _QNode(
    id: 'immo_achat',
    question: 'Quel est le problème lié à la transaction ?',
    options: [
      _QOption(label: 'Vendeur refuse de finaliser la vente',        emoji: '🚫', result: 'Droit immobilier — Exécution forcée vente'),
      _QOption(label: 'Vices cachés découverts après l\'achat',      emoji: '🏚️', result: 'Droit immobilier — Vices cachés'),
      _QOption(label: 'Titres de propriété manquants ou frauduleux', emoji: '📋', result: 'Droit immobilier — Authenticité titre de propriété'),
      _QOption(label: 'Arnaque immobilière (faux vendeur...)',        emoji: '⚠️', result: 'Droit pénal — Fraude immobilière'),
      _QOption(label: 'Litige avec l\'agence immobilière',           emoji: '🏢', result: 'Droit commercial — Responsabilité agence'),
      _QOption(label: 'Problème avec le notaire',                    emoji: '📜', result: 'Droit civil — Responsabilité notaire'),
    ],
  ),

  _QNode(
    id: 'immo_construction',
    question: 'Quel est le problème de construction ou de voisinage ?',
    options: [
      _QOption(label: 'Litige sur les limites de propriété',         emoji: '📏', result: 'Droit immobilier — Bornage et limites'),
      _QOption(label: 'Voisin construit illégalement',               emoji: '🏗️', result: 'Droit immobilier — Construction illégale voisin'),
      _QOption(label: 'Malfaçons de l\'entrepreneur',                emoji: '🏚️', result: 'Droit civil — Responsabilité constructeur'),
      _QOption(label: 'Refus de permis de construire',               emoji: '🚫', result: 'Droit administratif — Permis de construire'),
      _QOption(label: 'Nuisances du voisinage (bruit, odeur...)',     emoji: '😤', result: 'Droit civil — Troubles de voisinage'),
      _QOption(label: 'Servitude contestée (passage, vue...)',        emoji: '🚶', result: 'Droit immobilier — Servitudes'),
    ],
  ),

  // ══════════════════════════════════════════════════════════════
  // CIVIL (entre particuliers)
  // ══════════════════════════════════════════════════════════════
  _QNode(
    id: 'civil_type',
    question: 'Quel est le problème avec cette personne ?',
    options: [
      _QOption(label: 'Elle me doit de l\'argent',                   emoji: '💸', nextId: 'civil_dette'),
      _QOption(label: 'Elle m\'a causé un préjudice physique',       emoji: '🤕', nextId: 'civil_prejudice'),
      _QOption(label: 'Diffamation ou atteinte à ma réputation',     emoji: '🗣️', nextId: 'civil_diffamation'),
      _QOption(label: 'Arnaque ou escroquerie',                      emoji: '⚠️', nextId: 'civil_arnaque'),
      _QOption(label: 'Non-respect d\'un accord ou contrat',         emoji: '📋', nextId: 'civil_contrat'),
      _QOption(label: 'Atteinte à ma vie privée',                    emoji: '🔒', result: 'Droit civil — Vie privée et protection des données'),
    ],
  ),

  _QNode(
    id: 'civil_dette',
    question: 'Sur quoi est basée cette dette ?',
    options: [
      _QOption(label: 'Contrat ou bon de commande écrit',             emoji: '📄', result: 'Droit civil — Recouvrement créance contractuelle'),
      _QOption(label: 'Accord verbal uniquement',                     emoji: '🗣️', result: 'Droit civil — Preuve accord verbal'),
      _QOption(label: 'Chèque ou traite impayé',                      emoji: '🏦', result: 'Droit commercial — Chèque sans provision'),
      _QOption(label: 'Prêt d\'argent entre amis ou famille',         emoji: '👥', result: 'Droit civil — Reconnaissance de dette'),
      _QOption(label: 'Prestation réalisée sans paiement',            emoji: '🛠️', result: 'Droit civil — Enrichissement sans cause'),
    ],
  ),

  _QNode(
    id: 'civil_prejudice',
    question: 'Comment le préjudice a-t-il eu lieu ?',
    options: [
      _QOption(label: 'Accident causé par négligence',               emoji: '⚡', result: 'Droit civil — Responsabilité quasi-délictuelle'),
      _QOption(label: 'Agression volontaire',                        emoji: '🚨', result: 'Droit pénal — Coups et blessures'),
      _QOption(label: 'Accident lors d\'un événement ou sport',      emoji: '⚽', result: 'Droit civil — Responsabilité organisateur'),
      _QOption(label: 'Préjudice causé par un animal',               emoji: '🐕', result: 'Droit civil — Responsabilité propriétaire animal'),
      _QOption(label: 'Préjudice psychologique ou moral',            emoji: '😔', result: 'Droit civil — Préjudice moral'),
    ],
  ),

  _QNode(
    id: 'civil_diffamation',
    question: 'Où cela s\'est-il passé ?',
    options: [
      _QOption(label: 'Sur internet ou réseaux sociaux',             emoji: '💻', result: 'Droit pénal — Diffamation en ligne'),
      _QOption(label: 'Par écrit (lettre, journal...)',               emoji: '📰', result: 'Droit pénal — Diffamation écrite'),
      _QOption(label: 'Verbalement devant des témoins',               emoji: '🗣️', result: 'Droit pénal — Injure et diffamation orale'),
      _QOption(label: 'Dans un contexte professionnel',              emoji: '💼', result: 'Droit pénal — Diffamation professionnelle'),
    ],
  ),

  _QNode(
    id: 'civil_arnaque',
    question: 'Quel type d\'arnaque ?',
    options: [
      _QOption(label: 'Arnaque sur internet ou achat en ligne',      emoji: '💻', result: 'Droit pénal — Fraude en ligne'),
      _QOption(label: 'Faux document ou usurpation d\'identité',     emoji: '🪪', result: 'Droit pénal — Usurpation identité'),
      _QOption(label: 'Investissement frauduleux ou pyramide',       emoji: '📉', result: 'Droit pénal — Escroquerie financière'),
      _QOption(label: 'Arnaque à la vente de bien',                  emoji: '🏠', result: 'Droit pénal — Escroquerie vente'),
      _QOption(label: 'Faux professionnel (médecin, avocat...)',      emoji: '🎭', result: 'Droit pénal — Exercice illégal de profession'),
    ],
  ),

  _QNode(
    id: 'civil_contrat',
    question: 'Quel type de contrat n\'a pas été respecté ?',
    options: [
      _QOption(label: 'Contrat de vente ou achat',                   emoji: '🛍️', result: 'Droit civil — Inexécution contrat de vente'),
      _QOption(label: 'Contrat de service ou prestation',            emoji: '🛠️', result: 'Droit civil — Inexécution prestation de service'),
      _QOption(label: 'Contrat de prêt',                             emoji: '🏦', result: 'Droit civil — Inexécution contrat de prêt'),
      _QOption(label: 'Promesse de vente',                           emoji: '📋', result: 'Droit civil — Promesse de vente non tenue'),
    ],
  ),

  // ══════════════════════════════════════════════════════════════
  // PÉNAL
  // ══════════════════════════════════════════════════════════════
  _QNode(
    id: 'penal_qui',
    question: 'Quelle est votre situation face à la justice ?',
    options: [
      _QOption(label: 'Je suis victime et veux porter plainte',      emoji: '🚨', nextId: 'penal_victime'),
      _QOption(label: 'Je suis accusé ou convoqué par la police',    emoji: '⚖️', nextId: 'penal_accuse'),
      _QOption(label: 'Un proche est en garde à vue ou en prison',   emoji: '🔒', nextId: 'penal_proche'),
      _QOption(label: 'J\'ai été condamné et veux faire appel',      emoji: '🔄', result: 'Droit pénal — Voies de recours / appel'),
      _QOption(label: 'Je veux me constituer partie civile',         emoji: '📋', result: 'Droit pénal — Partie civile'),
    ],
  ),

  _QNode(
    id: 'penal_victime',
    question: 'Quelle infraction avez-vous subie ?',
    options: [
      _QOption(label: 'Agression physique ou coups',                 emoji: '🤕', result: 'Droit pénal — Coups et blessures volontaires'),
      _QOption(label: 'Vol, cambriolage ou braquage',                emoji: '🔓', result: 'Droit pénal — Vol qualifié'),
      _QOption(label: 'Escroquerie ou abus de confiance',            emoji: '💸', result: 'Droit pénal — Escroquerie'),
      _QOption(label: 'Viol ou agression sexuelle',                  emoji: '🚨', result: 'Droit pénal — Agression sexuelle (assistance victime)'),
      _QOption(label: 'Menaces de mort ou intimidation',             emoji: '⚠️', result: 'Droit pénal — Menaces et intimidation'),
      _QOption(label: 'Séquestration ou enlèvement',                 emoji: '🔒', result: 'Droit pénal — Séquestration'),
      _QOption(label: 'Cybercriminalité ou piratage',                emoji: '💻', result: 'Droit pénal — Cybercriminalité'),
      _QOption(label: 'Meurtre ou homicide (famille de la victime)', emoji: '💔', result: 'Droit pénal — Homicide (famille victime)'),
    ],
  ),

  _QNode(
    id: 'penal_accuse',
    question: 'À quel stade de la procédure êtes-vous ?',
    options: [
      _QOption(label: 'Convocation au commissariat ou gendarmerie',  emoji: '📩', result: 'Droit pénal — Audition libre (défense)'),
      _QOption(label: 'Garde à vue en cours',                        emoji: '🔒', result: 'Droit pénal — Assistance garde à vue'),
      _QOption(label: 'Mise en examen / sous contrôle judiciaire',   emoji: '📋', result: 'Droit pénal — Mise en examen'),
      _QOption(label: 'Audience ou jugement à venir',                emoji: '⚖️', result: 'Droit pénal — Défense en jugement'),
      _QOption(label: 'Condamné, en attente d\'exécution de peine',  emoji: '📜', result: 'Droit pénal — Aménagement de peine'),
      _QOption(label: 'Mandat d\'arrêt ou avis de recherche',        emoji: '🚨', result: 'Droit pénal — Mandat d\'arrêt (défense)'),
    ],
  ),

  _QNode(
    id: 'penal_proche',
    question: 'Quelle est la situation de votre proche ?',
    options: [
      _QOption(label: 'Garde à vue depuis moins de 48h',            emoji: '🔒', result: 'Droit pénal — Garde à vue (famille)'),
      _QOption(label: 'Détention provisoire',                        emoji: '🏛️', result: 'Droit pénal — Demande remise en liberté'),
      _QOption(label: 'Condamné et en prison',                       emoji: '⛓️', result: 'Droit pénal — Droits des détenus'),
      _QOption(label: 'Jugé sans avocat ou sans interprète',         emoji: '⚠️', result: 'Droit pénal — Violation droits de la défense'),
    ],
  ),

  // ══════════════════════════════════════════════════════════════
  // ADMINISTRATIF
  // ══════════════════════════════════════════════════════════════
  _QNode(
    id: 'admin_type',
    question: 'Quel type de problème avec l\'administration ?',
    options: [
      _QOption(label: 'Refus d\'un document ou permis',              emoji: '🚫', nextId: 'admin_refus'),
      _QOption(label: 'État civil (naissance, mariage, décès...)',   emoji: '📘', nextId: 'admin_etat_civil'),
      _QOption(label: 'Nationalité ou naturalisation',               emoji: '🇩🇿', result: 'Droit administratif — Nationalité'),
      _QOption(label: 'Marché public ou appel d\'offres',            emoji: '📊', result: 'Droit administratif — Marchés publics'),
      _QOption(label: 'Décision administrative contestée',           emoji: '📩', nextId: 'admin_decision'),
      _QOption(label: 'Problème fiscal avec les impôts',             emoji: '💸', nextId: 'admin_fiscal'),
      _QOption(label: 'Litige avec une commune ou daïra',            emoji: '🏘️', result: 'Droit administratif — Responsabilité commune'),
      _QOption(label: 'Dommage causé par un service public',         emoji: '🏛️', result: 'Droit administratif — Responsabilité service public'),
    ],
  ),

  _QNode(
    id: 'admin_refus',
    question: 'Quel type de document ou permis a été refusé ?',
    options: [
      _QOption(label: 'Permis de construire ou de lotir',            emoji: '🔨', result: 'Droit administratif — Permis de construire'),
      _QOption(label: 'Licence commerciale ou d\'exploitation',      emoji: '🏪', result: 'Droit administratif — Licence commerciale'),
      _QOption(label: 'Passeport ou document d\'identité',           emoji: '🪪', result: 'Droit administratif — Documents d\'identité'),
      _QOption(label: 'Importation ou exportation',                  emoji: '📦', result: 'Droit administratif — Licences import-export'),
      _QOption(label: 'Permis de chasse ou de pêche',                emoji: '🎣', result: 'Droit administratif — Permis activités'),
      _QOption(label: 'Inscription ou validation (université...)',   emoji: '🎓', result: 'Droit administratif — Accès service public'),
    ],
  ),

  _QNode(
    id: 'admin_etat_civil',
    question: 'Quel problème d\'état civil ?',
    options: [
      _QOption(label: 'Erreur sur acte de naissance',                emoji: '📋', result: 'Droit administratif — Rectification acte de naissance'),
      _QOption(label: 'Mariage non enregistré',                      emoji: '💍', result: 'Droit administratif — Enregistrement mariage'),
      _QOption(label: 'Changement de nom ou prénom',                 emoji: '✏️', result: 'Droit administratif — Changement d\'état civil'),
      _QOption(label: 'Extrait d\'acte introuvable ou détruit',      emoji: '🔍', result: 'Droit administratif — Reconstitution état civil'),
    ],
  ),

  _QNode(
    id: 'admin_decision',
    question: 'Quelle décision voulez-vous contester ?',
    options: [
      _QOption(label: 'Expropriation ou saisie de bien',             emoji: '⚡', result: 'Droit administratif — Expropriation'),
      _QOption(label: 'Fermeture d\'entreprise ordonnée',            emoji: '🏪', result: 'Droit administratif — Fermeture administrative'),
      _QOption(label: 'Amende ou pénalité administrative',           emoji: '💸', result: 'Droit administratif — Recours contre amende'),
      _QOption(label: 'Décision touchant à l\'urbanisme',            emoji: '🏗️', result: 'Droit administratif — Contentieux urbanisme'),
      _QOption(label: 'Résiliation d\'un contrat par l\'État',       emoji: '📄', result: 'Droit administratif — Résiliation contrat administratif'),
    ],
  ),

  _QNode(
    id: 'admin_fiscal',
    question: 'Quel type de problème fiscal ?',
    options: [
      _QOption(label: 'Redressement fiscal contesté',                emoji: '⚠️', result: 'Droit fiscal — Contentieux redressement fiscal'),
      _QOption(label: 'Saisie ou blocage de compte par les impôts',  emoji: '🏦', result: 'Droit fiscal — Saisie fiscale'),
      _QOption(label: 'TVA ou impôt sur le revenu contesté',         emoji: '🧾', result: 'Droit fiscal — Contentieux fiscal'),
      _QOption(label: 'Fraude fiscale — je suis accusé',             emoji: '⚖️', result: 'Droit pénal — Fraude fiscale (défense)'),
    ],
  ),

  // ══════════════════════════════════════════════════════════════
  // BUSINESS / COMMERCIAL
  // ══════════════════════════════════════════════════════════════
  _QNode(
    id: 'business_type',
    question: 'Quel est le problème pour votre activité ?',
    options: [
      _QOption(label: 'Créer, modifier ou dissoudre une société',    emoji: '🏭', nextId: 'business_societe'),
      _QOption(label: 'Contrat commercial non respecté',             emoji: '📋', nextId: 'business_contrat'),
      _QOption(label: 'Difficultés financières ou faillite',         emoji: '📉', nextId: 'business_faillite'),
      _QOption(label: 'Propriété intellectuelle',                    emoji: '💡', nextId: 'business_pi'),
      _QOption(label: 'Litige avec un concurrent',                   emoji: '⚔️', nextId: 'business_concurrence'),
      _QOption(label: 'Problème bancaire',                           emoji: '🏦', nextId: 'business_banque'),
    ],
  ),

  _QNode(
    id: 'business_societe',
    question: 'Quelle est la nature de la demande ?',
    options: [
      _QOption(label: 'Création d\'une SARL, SPA ou autre',          emoji: '🏭', result: 'Droit des sociétés — Création'),
      _QOption(label: 'Conflit entre associés',                      emoji: '👥', result: 'Droit des sociétés — Conflit entre associés'),
      _QOption(label: 'Cession de parts sociales',                   emoji: '📋', result: 'Droit des sociétés — Cession de parts'),
      _QOption(label: 'Dissolution ou liquidation',                  emoji: '📉', result: 'Droit des sociétés — Dissolution'),
      _QOption(label: 'Modification des statuts',                    emoji: '✏️', result: 'Droit des sociétés — Modification statuts'),
    ],
  ),

  _QNode(
    id: 'business_contrat',
    question: 'Avec qui est le litige commercial ?',
    options: [
      _QOption(label: 'Un fournisseur',                              emoji: '📦', result: 'Droit commercial — Litige fournisseur'),
      _QOption(label: 'Un client',                                   emoji: '🤝', result: 'Droit commercial — Recouvrement client'),
      _QOption(label: 'Un associé ou partenaire',                    emoji: '👥', result: 'Droit des sociétés — Litige partenaire'),
      _QOption(label: 'Un distributeur ou franchisé',                emoji: '🏪', result: 'Droit commercial — Contrat de distribution'),
      _QOption(label: 'Un prestataire de services',                  emoji: '🛠️', result: 'Droit commercial — Inexécution prestation'),
    ],
  ),

  _QNode(
    id: 'business_faillite',
    question: 'Quelle est la situation financière ?',
    options: [
      _QOption(label: 'Cessation de paiement imminente',             emoji: '🚨', result: 'Droit commercial — Procédure de sauvegarde'),
      _QOption(label: 'Créanciers qui poursuivent',                  emoji: '⚠️', result: 'Droit commercial — Défense contre créanciers'),
      _QOption(label: 'Faillite personnelle du dirigeant',           emoji: '👤', result: 'Droit commercial — Faillite personnelle'),
      _QOption(label: 'Saisie de biens de l\'entreprise',            emoji: '🔒', result: 'Droit commercial — Opposition saisie'),
    ],
  ),

  _QNode(
    id: 'business_pi',
    question: 'Quel type de propriété intellectuelle ?',
    options: [
      _QOption(label: 'Marque commerciale copiée ou contestée',      emoji: '™️', result: 'Propriété intellectuelle — Marque'),
      _QOption(label: 'Brevet d\'invention',                         emoji: '💡', result: 'Propriété intellectuelle — Brevet'),
      _QOption(label: 'Droit d\'auteur (œuvre, logiciel, design...)', emoji: '©️', result: 'Propriété intellectuelle — Droit d\'auteur'),
      _QOption(label: 'Secret commercial ou savoir-faire volé',      emoji: '🔓', result: 'Propriété intellectuelle — Secret commercial'),
    ],
  ),

  _QNode(
    id: 'business_concurrence',
    question: 'Quel type de pratique déloyale ?',
    options: [
      _QOption(label: 'Copie de produit ou imitation',               emoji: '📋', result: 'Droit commercial — Contrefaçon'),
      _QOption(label: 'Dénigrement ou fausse publicité',             emoji: '🗣️', result: 'Droit commercial — Dénigrement concurrentiel'),
      _QOption(label: 'Ancien employé qui démarre chez concurrent',  emoji: '👤', result: 'Droit commercial — Clause de non-concurrence'),
      _QOption(label: 'Entente illicite entre concurrents',          emoji: '🤝', result: 'Droit commercial — Pratiques anticoncurrentielles'),
    ],
  ),

  _QNode(
    id: 'business_banque',
    question: 'Quel est le problème bancaire ?',
    options: [
      _QOption(label: 'Refus de financement ou de prêt',             emoji: '🚫', result: 'Droit bancaire — Refus crédit'),
      _QOption(label: 'Frais ou prélèvements abusifs',               emoji: '💸', result: 'Droit bancaire — Frais abusifs'),
      _QOption(label: 'Saisie ou blocage de compte',                 emoji: '🔒', result: 'Droit bancaire — Blocage compte'),
      _QOption(label: 'Garantie bancaire contestée',                 emoji: '📋', result: 'Droit bancaire — Garantie'),
    ],
  ),

  // ══════════════════════════════════════════════════════════════
  // SANTÉ
  // ══════════════════════════════════════════════════════════════
  _QNode(
    id: 'sante',
    question: 'Quel est le problème médical ou de santé ?',
    options: [
      _QOption(label: 'Erreur médicale ou chirurgicale',             emoji: '🏥', result: 'Droit médical — Faute médicale'),
      _QOption(label: 'Refus de soins ou de traitement',             emoji: '🚫', result: 'Droit médical — Accès aux soins'),
      _QOption(label: 'Mauvaise prescription médicamenteuse',        emoji: '💊', result: 'Droit médical — Responsabilité pharmaceutique'),
      _QOption(label: 'Secret médical violé',                        emoji: '🔒', result: 'Droit médical — Violation secret médical'),
      _QOption(label: 'Accident en clinique privée',                 emoji: '🏨', result: 'Droit médical — Responsabilité clinique'),
      _QOption(label: 'Problème avec la CNAS ou mutuelle',           emoji: '🛡️', result: 'Droit social — Litige sécurité sociale'),
      _QOption(label: 'Invalidité ou handicap reconnu',              emoji: '🦽', result: 'Droit social — Droits invalidité'),
    ],
  ),

  // ══════════════════════════════════════════════════════════════
  // ASSURANCE
  // ══════════════════════════════════════════════════════════════
  _QNode(
    id: 'assurance',
    question: 'Quel est le problème avec l\'assurance ?',
    options: [
      _QOption(label: 'Refus d\'indemnisation après sinistre',       emoji: '🚫', result: 'Droit des assurances — Refus indemnisation'),
      _QOption(label: 'Indemnisation insuffisante',                  emoji: '💰', result: 'Droit des assurances — Contestation montant'),
      _QOption(label: 'Résiliation abusive du contrat',              emoji: '📄', result: 'Droit des assurances — Résiliation abusive'),
      _QOption(label: 'Assurance vie — problème lors du décès',      emoji: '📜', result: 'Droit des assurances — Assurance vie'),
      _QOption(label: 'Assurance auto — accident non pris en charge', emoji: '🚗', result: 'Droit des assurances — Assurance auto'),
    ],
  ),

  // ══════════════════════════════════════════════════════════════
  // CYBER
  // ══════════════════════════════════════════════════════════════
  _QNode(
    id: 'cyber',
    question: 'Quel est le problème lié à internet ?',
    options: [
      _QOption(label: 'Piratage de compte ou vol de données',        emoji: '🔓', result: 'Droit pénal — Cybercriminalité / piratage'),
      _QOption(label: 'Harcèlement en ligne ou cyberbullying',       emoji: '⚠️', result: 'Droit pénal — Cyberharcèlement'),
      _QOption(label: 'Diffamation sur les réseaux sociaux',         emoji: '🗣️', result: 'Droit pénal — Diffamation en ligne'),
      _QOption(label: 'Photos ou vidéos publiées sans mon accord',   emoji: '📷', result: 'Droit civil — Atteinte à l\'image'),
      _QOption(label: 'Arnaque à l\'achat en ligne',                 emoji: '🛍️', result: 'Droit pénal — Fraude e-commerce'),
      _QOption(label: 'Usurpation d\'identité numérique',            emoji: '🪪', result: 'Droit pénal — Usurpation identité numérique'),
      _QOption(label: 'Contenu illicite publié sur mon nom',         emoji: '🚫', result: 'Droit civil — Droit à l\'oubli numérique'),
    ],
  ),

  // ══════════════════════════════════════════════════════════════
  // ROUTE / VEHICULE
  // ══════════════════════════════════════════════════════════════
  _QNode(
    id: 'route',
    question: 'Quel est le problème lié au véhicule ou à la route ?',
    options: [
      _QOption(label: 'Accident de la route — je suis victime',      emoji: '🚨', nextId: 'route_victime'),
      _QOption(label: 'Accident de la route — je suis responsable',  emoji: '⚖️', result: 'Droit pénal + Civil — Responsabilité accident route'),
      _QOption(label: 'Infraction ou retrait de permis',             emoji: '🚫', result: 'Droit pénal routier — Infraction'),
      _QOption(label: 'Véhicule volé ou non retrouvé',               emoji: '🔍', result: 'Droit pénal — Vol de véhicule'),
      _QOption(label: 'Litige achat / vente de véhicule',            emoji: '🤝', result: 'Droit civil — Litige véhicule d\'occasion'),
      _QOption(label: 'Défaut ou panne après achat neuf',            emoji: '🔧', result: 'Droit de la consommation — Garantie véhicule neuf'),
    ],
  ),

  _QNode(
    id: 'route_victime',
    question: 'Quelle est la situation après l\'accident ?',
    options: [
      _QOption(label: 'Blessures corporelles graves',                emoji: '🏥', result: 'Droit pénal + Civil — Indemnisation blessures grave'),
      _QOption(label: 'Dégâts matériels uniquement',                 emoji: '🚗', result: 'Droit civil — Indemnisation dégâts matériels'),
      _QOption(label: 'Conducteur responsable non assuré',           emoji: '⚠️', result: 'Droit des assurances — Accident with non-assuré'),
      _QOption(label: 'Délit de fuite du responsable',               emoji: '🚨', result: 'Droit pénal — Délit de fuite'),
      _QOption(label: 'Décès d\'un proche dans l\'accident',         emoji: '💔', result: 'Droit pénal + Civil — Homicide involontaire / indemnisation'),
    ],
  ),

  // ══════════════════════════════════════════════════════════════
  // AUTRE
  // ══════════════════════════════════════════════════════════════
  _QNode(
    id: 'autre',
    question: 'Pouvez-vous préciser un peu plus ?',
    options: [
      _QOption(label: 'Un problème d\'argent ou de dette',           emoji: '💸', nextId: 'civil_dette'),
      _QOption(label: 'Un conflit avec quelqu\'un',                  emoji: '👤', nextId: 'civil_type'),
      _QOption(label: 'Un problème personnel ou familial',           emoji: '👨‍👩‍👧', nextId: 'famille'),
      _QOption(label: 'Un problème with les autorités',              emoji: '🏛️', nextId: 'admin_type'),
      _QOption(label: 'Une affaire judiciaire ou pénale',            emoji: '⚖️', nextId: 'penal_qui'),
      _QOption(label: 'Je veux juste consulter un avocat',           emoji: '🤝', result: 'Consultation générale — Tous types'),
    ],
  ),


  _QNode(
    id: 'immo_construction',
    question: 'Quelle est la nature du litige ?',
    options: [
      _QOption(label: 'Litige avec un voisin (limites, servitude...)', emoji: '🤝', result: 'Droit immobilier'),
      _QOption(label: 'Problème avec l\'entrepreneur / maçon',         emoji: '👷', result: 'Droit civil'),
      _QOption(label: 'Refus de permis de construire',                 emoji: '🚫', result: 'Droit administratif'),
      _QOption(label: 'Malfaçons dans la construction',                emoji: '🏚️', result: 'Droit civil'),
    ],
  ),

  // ── Civil (litige entre personnes) ───────────────────────────
  _QNode(
    id: 'civil',
    question: 'Quel est le problème avec cette personne ?',
    options: [
      _QOption(label: 'Elle me doit de l\'argent',           emoji: '💸', nextId: 'civil_dette'),
      _QOption(label: 'Elle m\'a causé un préjudice physique ou moral', emoji: '🤕', result: 'Droit civil'),
      _QOption(label: 'Diffamation / Atteinte à ma réputation', emoji: '🗣️', result: 'Droit pénal'),
      _QOption(label: 'Arnaque ou escroquerie',              emoji: '⚠️', result: 'Droit pénal'),
      _QOption(label: 'Non-respect d\'un accord entre nous', emoji: '🤝', result: 'Droit civil'),
    ],
  ),

  _QNode(
    id: 'civil_dette',
    question: 'Cette dette est basée sur :',
    options: [
      _QOption(label: 'Un contrat ou bon de commande écrit', emoji: '📄', result: 'Droit civil'),
      _QOption(label: 'Un accord verbal uniquement',         emoji: '🗣️', result: 'Droit civil'),
      _QOption(label: 'Un chèque ou traite impayé',          emoji: '🏦', result: 'Droit commercial'),
      _QOption(label: 'Un prêt entre amis / famille',        emoji: '👥', result: 'Droit civil'),
    ],
  ),

  // ── Pénal ─────────────────────────────────────────────────────
  _QNode(
    id: 'penal_qui',
    question: 'Vous êtes dans quelle situation ?',
    options: [
      _QOption(label: 'Je suis victime et veux porter plainte',  emoji: '🚨', nextId: 'penal_victime'),
      _QOption(label: 'Je suis accusé ou poursuivi en justice',  emoji: '⚖️', nextId: 'penal_accuse'),
      _QOption(label: 'Un proche est en garde à vue ou en prison', emoji: '🔒', result: 'Droit pénal'),
    ],
  ),

  _QNode(
    id: 'penal_victime',
    question: 'Quelle infraction avez-vous subie ?',
    options: [
      _QOption(label: 'Agression physique',                  emoji: '🤕', result: 'Droit pénal'),
      _QOption(label: 'Vol ou cambriolage',                  emoji: '🔓', result: 'Droit pénal'),
      _QOption(label: 'Arnaque / Escroquerie financière',    emoji: '💸', result: 'Droit pénal'),
      _QOption(label: 'Cybercriminalité / Piratage',         emoji: '💻', result: 'Droit pénal'),
      _QOption(label: 'Diffamation ou harcèlement',          emoji: '🗣️', result: 'Droit pénal'),
    ],
  ),

  _QNode(
    id: 'penal_accuse',
    question: 'À quel stade en êtes-vous ?',
    options: [
      _QOption(label: 'Convocation par la police / gendarmerie', emoji: '📩', result: 'Droit pénal'),
      _QOption(label: 'Mise en examen / Instruction en cours',   emoji: '📋', result: 'Droit pénal'),
      _QOption(label: 'Jugement programmé ou en attente',        emoji: '⚖️', result: 'Droit pénal'),
      _QOption(label: 'Condamné, je veux faire appel',           emoji: '🔄', result: 'Droit pénal'),
    ],
  ),

  // ── Administratif ─────────────────────────────────────────────
  _QNode(
    id: 'admin',
    question: 'Quel est votre problème avec l\'administration ?',
    options: [
      _QOption(label: 'Refus d\'un permis ou autorisation',    emoji: '🚫', nextId: 'admin_refus'),
      _QOption(label: 'Documents officiels (nationalité, état civil...)', emoji: '📘', result: 'Droit administratif'),
      _QOption(label: 'Litige suite à un marché public',       emoji: '📊', result: 'Droit administratif'),
      _QOption(label: 'Décision administrative que je conteste', emoji: '📩', result: 'Droit administratif'),
      _QOption(label: 'Problème fiscal avec les impôts',       emoji: '💸', result: 'Droit fiscal'),
    ],
  ),

  _QNode(
    id: 'admin_refus',
    question: 'De quel type de permis s\'agit-il ?',
    options: [
      _QOption(label: 'Permis de construire',     emoji: '🔨', result: 'Droit administratif'),
      _QOption(label: 'Permis d\'exploitation / Activité commerciale', emoji: '🏪', result: 'Droit administratif'),
      _QOption(label: 'Permis de conduire / Véhicule', emoji: '🚗', result: 'Droit administratif'),
      _QOption(label: 'Autre autorisation',        emoji: '📋', result: 'Droit administratif'),
    ],
  ),

  // ── Business ──────────────────────────────────────────────────
  _QNode(
    id: 'business',
    question: 'De quoi s\'agit-il pour votre activité ?',
    options: [
      _QOption(label: 'Créer ou dissoudre une société',        emoji: '🏭', result: 'Droit des sociétés'),
      _QOption(label: 'Contrat commercial non respecté',       emoji: '📋', nextId: 'business_contrat'),
      _QOption(label: 'Faillite ou difficultés financières',   emoji: '📉', result: 'Droit commercial'),
      _QOption(label: 'Brevet, marque ou propriété intellectuelle', emoji: '💡', result: 'Propriété intellectuelle'),
      _QOption(label: 'Litige fiscal',                         emoji: '🧾', result: 'Droit fiscal'),
    ],
  ),

  _QNode(
    id: 'business_contrat',
    question: 'Avec qui est le litige commercial ?',
    options: [
      _QOption(label: 'Un fournisseur',           emoji: '📦', result: 'Droit commercial'),
      _QOption(label: 'Un client',                emoji: '🤝', result: 'Droit commercial'),
      _QOption(label: 'Un associé',               emoji: '👥', result: 'Droit des sociétés'),
      _QOption(label: 'Une banque',               emoji: '🏦', result: 'Droit commercial'),
    ],
  ),
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

  /// Converts a detailed questionnaire result like "Droit de la famille — Divorce contentieux"
  /// into the canonical specialty name used by lawyers: "Droit familial"
  String _extractSpecialty(String result) {
    final lower = result.toLowerCase();
    if (lower.startsWith('droit de la famille') || lower.startsWith('droit familial')) return 'Droit familial';
    if (lower.startsWith('droit pénal') || lower.startsWith('droit penal')) return 'Droit pénal';
    if (lower.startsWith('droit commercial')) return 'Droit commercial';
    if (lower.startsWith('droit civil')) return 'Droit civil';
    if (lower.startsWith('droit immobilier')) return 'Droit immobilier';
    if (lower.startsWith('droit administratif')) return 'Droit administratif';
    if (lower.startsWith('droit du travail')) return 'Droit du travail';
    if (lower.startsWith('droit des sociétés') || lower.startsWith('droit des societes')) return 'Droit des sociétés';
    if (lower.startsWith('droit fiscal')) return 'Droit fiscal';
    if (lower.startsWith('droit bancaire')) return 'Droit bancaire';
    if (lower.startsWith('droit des assurances')) return 'Droit des assurances';
    if (lower.startsWith('droit médical') || lower.startsWith('droit medical')) return 'Droit médical';
    if (lower.startsWith('droit social')) return 'Droit social';
    if (lower.startsWith('droit de la consommation')) return 'Droit de la consommation';
    if (lower.startsWith('propriété intellectuelle') || lower.startsWith('propriete intellectuelle') || lower.startsWith('droit de la propriété')) return 'Propriété Intellectuelle';
    // fallback: return the first part before " — "
    return result.split(' — ').first.split(' + ').first.trim();
  }

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
      'Droit bancaire': Icons.account_balance_rounded,
      'Droit des assurances': Icons.shield_rounded,
      'Droit médical': Icons.local_hospital_rounded,
      'Droit social': Icons.people_rounded,
      'Droit de la consommation': Icons.shopping_cart_rounded,
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
              child: Icon(icons[_extractSpecialty(recommendation)] ?? Icons.balance_rounded,
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
                  builder: (_) => DirectSearchScreen(preselectedSpeciality: _extractSpecialty(recommendation))));
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
