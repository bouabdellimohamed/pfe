import 'package:flutter/material.dart';
import 'post_request_screen.dart';
import 'direct_search_screen.dart';
import 'ai_assistant_screen.dart' show AIAssistantScreen;

class ChooseMethodScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const ChooseMethodScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    const Color royalBlue = Color(0xFF1976D2);
    const Color darkText = Color(0xFF101010);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: darkText, size: 20),
          onPressed: () {
            if (onBack != null) {
              onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "Comment voulez-vous\nprocéder ?",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: darkText,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Option 1: Recherche directe (type d'affaire connu)
                      _buildPremiumOptionCard(
                        context,
                        icon: Icons.search_rounded,
                        title: "Je connais mon affaire",
                        subtitle:
                            "Sélectionnez le type d'affaire et la localisation",
                        primaryColor: royalBlue,
                        badge: null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DirectSearchScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Option 2: IA / Questionnaire (type d'affaire inconnu)
                      _buildPremiumOptionCard(
                        context,
                        icon: Icons.psychology_rounded,
                        title: "Je ne sais pas",
                        subtitle: "Utilisez l'IA ou un questionnaire guidé",
                        primaryColor: Colors.purple,
                        badge: 'IA',
                        onTap: () {
                          _showAIOrQuestionnaireDialog(context);
                        },
                      ),

                      const SizedBox(height: 20),

                      // Option 3: Publier une demande
                      _buildPremiumOptionCard(
                        context,
                        icon: Icons.mail_outline_rounded,
                        title: "Demande d'avocat",
                        subtitle: "Publiez votre demande, recevez des offres",
                        primaryColor: Colors.teal,
                        badge: null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PostRequestScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAIOrQuestionnaireDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Comment souhaitez-vous\nêtre guidé ?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 24),

              // IA
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.purple,
                  ),
                ),
                title: const Text(
                  'Intelligence Artificielle',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                subtitle: const Text(
                  'Décrivez votre situation, l\'IA identifie votre besoin',
                  style: TextStyle(fontSize: 13),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AIAssistantScreen(),
                    ),
                  );
                },
              ),

              const Divider(),

              // Questionnaire
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.quiz_outlined, color: Colors.orange),
                ),
                title: const Text(
                  'Questionnaire guidé',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                subtitle: const Text(
                  'Répondez à quelques questions pour identifier votre cas',
                  style: TextStyle(fontSize: 13),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _startQuestionnaire(context);
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _startQuestionnaire(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _QuestionnaireScreen()),
    );
  }

  Widget _buildPremiumOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color primaryColor,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: primaryColor.withOpacity(0.1), width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          splashColor: primaryColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(26.0),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 30, color: primaryColor),
                    ),
                    if (badge != null)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Color(0xFF101010),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── QUESTIONNAIRE SCREEN ────────────────────────────────────────
class _QuestionnaireScreen extends StatefulWidget {
  const _QuestionnaireScreen();

  @override
  State<_QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<_QuestionnaireScreen> {
  int _step = 0;
  final Map<int, String> _answers = {};

  static const Color primary = Color(0xFF1565C0);

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Votre situation concerne-t-elle la famille ?',
      'options': [
        'Divorce / Séparation',
        'Garde d\'enfants',
        'Succession / Héritage',
        'Non, autre chose',
      ],
    },
    {
      'question': 'Avez-vous un litige avec une entreprise ou un employeur ?',
      'options': [
        'Licenciement / Travail',
        'Contrat commercial',
        'Consommateur / Achat',
        'Non, autre chose',
      ],
    },
    {
      'question':
          'Avez-vous subi un préjudice (accident, arnaque, agression) ?',
      'options': [
        'Accident corporel',
        'Escroquerie / Fraude',
        'Agression / Violence',
        'Non, autre chose',
      ],
    },
    {
      'question': 'Avez-vous un problème lié à un bien immobilier ?',
      'options': [
        'Achat / Vente',
        'Location / Expulsion',
        'Construction / Voisinage',
        'Non, autre chose',
      ],
    },
  ];

  String _getRecommendation() {
    for (final a in _answers.values) {
      if (a.contains('Divorce') ||
          a.contains('Séparation') ||
          a.contains('Garde') ||
          a.contains('Succession')) return 'Droit de la Famille';
      if (a.contains('Licenciement') || a.contains('Travail'))
        return 'Droit du Travail';
      if (a.contains('commercial') || a.contains('Contrat'))
        return 'Droit Commercial';
      if (a.contains('Accident') ||
          a.contains('Agression') ||
          a.contains('Escroquerie')) return 'Droit Pénal';
      if (a.contains('immobilier') ||
          a.contains('Location') ||
          a.contains('Construction')) return 'Droit Immobilier';
    }
    return 'Droit Civil';
  }

  @override
  Widget build(BuildContext context) {
    final done = _step >= _questions.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          done ? 'Résultat' : 'Question ${_step + 1}/${_questions.length}',
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: done ? _buildResult() : _buildQuestion(_questions[_step]),
      ),
    );
  }

  Widget _buildQuestion(Map<String, dynamic> q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: (_step + 1) / _questions.length,
          backgroundColor: Colors.grey.shade200,
          color: primary,
        ),
        const SizedBox(height: 32),
        Text(
          q['question'],
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 28),
        ...(q['options'] as List<String>).map(
          (opt) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: InkWell(
              onTap: () {
                setState(() {
                  _answers[_step] = opt;
                  // إذا لم يكن "Non, autre chose"، اذهب مباشرة للنتيجة
                  if (opt != 'Non, autre chose') {
                    _step = _questions.length;
                  } else {
                    // وإلا، انتقل للسؤال التالي
                    _step++;
                  }
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  opt,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final recommendation = _getRecommendation();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            size: 60,
            color: primary,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Nous recommandons',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          recommendation,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: primary,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Chercher un avocat',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
