import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'choose_method_screen.dart';
import 'user_consultation_screen.dart';
import 'user_my_requests_screen.dart';
import 'post_request_screen.dart';
import 'direct_search_screen.dart';
import 'ai_assistant_screen.dart' show AIAssistantScreen;
import 'chat_inbox_screen.dart';

class FeedHomeScreen extends StatefulWidget {
  const FeedHomeScreen({super.key});
  @override
  State<FeedHomeScreen> createState() => _FeedHomeScreenState();
}

class _FeedHomeScreenState extends State<FeedHomeScreen> {
  int _tab = 0;
  final _auth = AuthService();
  static const Color primary = Color(0xFF1565C0);

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Déconnecter',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final List<Widget> screens = [
      _HomeTab(
        onSearch: () => setState(() => _tab = 1),
        onConsultation: () => setState(() => _tab = 2),
        onPostRequest: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PostRequestScreen()),
        ),
        onChat: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => Scaffold(
                    backgroundColor: const Color(0xFF0D1B2A),
                    appBar: AppBar(
                      backgroundColor: const Color(0xFF1B2D42),
                      title: const Text('Messages',
                          style: TextStyle(
                              color: Color(0xFFF0EDE8),
                              fontSize: 17,
                              fontWeight: FontWeight.w700)),
                      leading: BackButton(color: const Color(0xFFF0EDE8)),
                    ),
                    body: const ChatInboxScreen(isLawyer: false),
                  )),
        ),
        onSignOut: _signOut,
      ),
      // Tab Recherche → مباشرة لشاشة الخيارات
      ChooseMethodScreen(
        onBack: () => setState(() => _tab = 0),
      ),
      UserConsultationScreen(uid: user?.uid ?? ''),
      UserMyRequestsScreen(uid: user?.uid ?? ''),
    ];

    return Scaffold(
      body: IndexedStack(index: _tab, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search_rounded),
            label: 'Recherche',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Consultation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox_outlined),
            activeIcon: Icon(Icons.inbox_rounded),
            label: 'Mes demandes',
          ),
        ],
      ),
    );
  }
}

// ── TAB RECHERCHE (بدون سهم رجوع) ────────────────────────────────
class _SearchTab extends StatelessWidget {
  final VoidCallback onSignOut;
  const _SearchTab({required this.onSignOut});
  static const Color primary = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Rechercher',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Color(0xFF101010),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            tooltip: 'Déconnexion',
            onPressed: onSignOut,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Option 1: Je connais mon affaire
              _buildCard(
                context,
                icon: Icons.search_rounded,
                title: 'Je connais mon affaire',
                subtitle: 'Sélectionnez le type d\'affaire et la localisation',
                color: primary,
                badge: null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DirectSearchScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Option 2: Je ne sais pas (واحدة فقط)
              _buildCard(
                context,
                icon: Icons.psychology_rounded,
                title: 'Je ne sais pas',
                subtitle: 'IA ou questionnaire pour identifier votre cas',
                color: Colors.purple,
                badge: 'IA',
                onTap: () => _showAIDialog(context),
              ),
              const SizedBox(height: 18),
              // Option 3: Demande d'avocat
              _buildCard(
                context,
                icon: Icons.mail_outline_rounded,
                title: 'Demande d\'avocat',
                subtitle: 'Publiez votre demande, recevez des offres',
                color: Colors.teal,
                badge: null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PostRequestScreen()),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showAIDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
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
                  MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
                );
              },
            ),
            const Divider(),
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
                  MaterialPageRoute(builder: (_) => const ChooseMethodScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: color.withOpacity(0.12)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 28, color: color),
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
                            color: color,
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF101010),
                        ),
                      ),
                      const SizedBox(height: 4),
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

// ── HOME TAB ──────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onConsultation;
  final VoidCallback onPostRequest;
  final VoidCallback onChat;
  final VoidCallback onSignOut;
  const _HomeTab({
    required this.onSearch,
    required this.onConsultation,
    required this.onPostRequest,
    required this.onChat,
    required this.onSignOut,
  });

  static const Color primary = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonjour 👋',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          user?.displayName?.isNotEmpty == true
                              ? user!.displayName!
                              : 'Bienvenue !',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF263238),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.red),
                    tooltip: 'Déconnexion',
                    onPressed: onSignOut,
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.balance_rounded, color: primary),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Besoin d\'un avocat ?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Trouvez l\'expert juridique\nqu\'il vous faut.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: onSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        'Rechercher',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'Actions rapides',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF263238),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _ActionCard(
                    icon: Icons.search_rounded,
                    label: 'Trouver un avocat',
                    color: primary,
                    onTap: onSearch,
                  ),
                  const SizedBox(width: 12),
                  _ActionCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Consultation',
                    color: Colors.teal,
                    onTap: onConsultation,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ActionCard(
                    icon: Icons.post_add_rounded,
                    label: 'Publier demande',
                    color: Colors.orange,
                    onTap: onPostRequest,
                  ),
                  const SizedBox(width: 12),
                  _ActionCard(
                    icon: Icons.forum_outlined,
                    label: 'Messages',
                    color: Colors.purple,
                    onTap: onChat,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              const Text(
                'Domaines juridiques',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF263238),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Droit familial',
                  'Droit pénal',
                  'Droit commercial',
                  'Droit civil',
                  'Droit du travail',
                  'Droit immobilier',
                ]
                    .map(
                      (s) => InkWell(
                        onTap: onSearch,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: primary.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            s,
                            style: TextStyle(
                              color: primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: color.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
