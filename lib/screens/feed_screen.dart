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
                  'Droit administratif',
                  'Droit des sociétés',
                  'Droit fiscal',
                  'Propriété Intellectuelle',
                ]
                    .map(
                      (s) => InkWell(
                        // ✅ يفتح DirectSearchScreen مع التخصص محدداً مسبقاً
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DirectSearchScreen(
                              preselectedSpeciality: s,
                            ),
                          ),
                        ),
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
