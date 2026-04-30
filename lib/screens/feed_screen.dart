import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'choose_method_screen.dart';
import 'user_consultation_screen.dart';
import 'user_my_requests_screen.dart';
import 'post_request_screen.dart';
import 'direct_search_screen.dart';
import 'ai_assistant_screen.dart' show AIAssistantScreen;
import 'chat_inbox_screen.dart';
import 'user_profile_management_screen.dart';
import 'notifications_screen.dart';

class FeedHomeScreen extends StatefulWidget {
  const FeedHomeScreen({super.key});
  @override
  State<FeedHomeScreen> createState() => _FeedHomeScreenState();
}

class _FeedHomeScreenState extends State<FeedHomeScreen>
    with SingleTickerProviderStateMixin {
  int _tab = 0;
  final _auth = AuthService();
  late AnimationController _fabCtrl;

  Future<void> _signOut() async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Déconnecter',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/auth', (_) => false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _fabCtrl.forward();
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
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
              backgroundColor: AppColors.navy,
              appBar: AppBar(
                backgroundColor: AppColors.navyLight,
                title: Text('Messages',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                leading: const BackButton(color: Colors.white),
              ),
              body: const ChatInboxScreen(isLawyer: false),
            ),
          ),
        ),
        onSignOut: _signOut,
      ),
      ChooseMethodScreen(onBack: () => setState(() => _tab = 0)),
      UserConsultationScreen(uid: user?.uid ?? ''),
      UserMyRequestsScreen(uid: user?.uid ?? ''),
    ];

    return Scaffold(
      body: IndexedStack(index: _tab, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _tab,
            onTap: (i) {
              HapticFeedback.selectionClick();
              setState(() => _tab = i);
            },
            elevation: 0,
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.grey400,
            selectedLabelStyle: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
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
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME TAB
// ─────────────────────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
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

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firstName = user?.displayName?.split(' ').first ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          setState(() {});
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            // ── App Bar ───────────────────────────────────────────────────
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: AppColors.surface,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bonjour 👋',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.textSecondary)),
                  Text(
                    firstName.isNotEmpty ? firstName : 'Bienvenue !',
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                ],
              ),
              actions: [
                // Notifications
                StreamBuilder<List<NotificationModel>>(
                  stream: _notificationService
                      .getUnreadNotifications(user?.uid ?? ''),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return IconButton(
                      tooltip: 'Notifications',
                      icon: Badge(
                        isLabelVisible: count > 0,
                        label: Text('$count',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10)),
                        child: const Icon(Icons.notifications_outlined,
                            color: AppColors.primary),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsScreen()),
                      ),
                    );
                  },
                ),
                // Profile menu
                PopupMenuButton(
                  icon: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      (user?.displayName?.isNotEmpty == true)
                          ? user!.displayName![0].toUpperCase()
                          : 'U',
                      style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                    ),
                  ),
                  position: PopupMenuPosition.under,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const UserProfileManagementScreen())),
                      child: const Row(children: [
                        Icon(Icons.person_outline, size: 18),
                        SizedBox(width: 12),
                        Text('Mon profil'),
                      ]),
                    ),
                    PopupMenuItem(
                      onTap: widget.onSignOut,
                      child: const Row(children: [
                        Icon(Icons.logout_rounded,
                            size: 18, color: AppColors.error),
                        SizedBox(width: 12),
                        Text('Déconnexion',
                            style: TextStyle(color: AppColors.error)),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Hero Banner ───────────────────────────────────────────
                  _HeroBanner(onTap: widget.onSearch),
                  const SizedBox(height: 28),

                  // ── Quick Actions ─────────────────────────────────────────
                  Text('Actions rapides',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 14),
                  _QuickActionsGrid(
                    onSearch: widget.onSearch,
                    onConsultation: widget.onConsultation,
                    onPostRequest: widget.onPostRequest,
                    onChat: widget.onChat,
                  ),
                  const SizedBox(height: 28),

                  // ── AI Assistant Banner ───────────────────────────────────
                  _AIBanner(),
                  const SizedBox(height: 28),

                  // ── Legal Domains ─────────────────────────────────────────
                  Text('Domaines juridiques',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  _LegalDomainsGrid(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO BANNER
// ─────────────────────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _HeroBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A56DB), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('⚡  Recherche rapide',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Trouvez votre avocat idéal',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Par spécialité, wilaya et score de performance',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Rechercher maintenant',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Opacity(
              opacity: 0.15,
              child: const Icon(Icons.balance_rounded,
                  size: 90, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK ACTIONS GRID
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onConsultation;
  final VoidCallback onPostRequest;
  final VoidCallback onChat;

  const _QuickActionsGrid({
    required this.onSearch,
    required this.onConsultation,
    required this.onPostRequest,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _Action(Icons.search_rounded, 'Trouver\nun avocat',
          AppColors.primary, onSearch),
      _Action(Icons.chat_bubble_outline_rounded, 'Consultation\njuridique',
          const Color(0xFF0F766E), onConsultation),
      _Action(Icons.post_add_rounded, 'Publier\nune demande',
          const Color(0xFFD97706), onPostRequest),
      _Action(Icons.forum_outlined, 'Mes\nmessages',
          const Color(0xFF7C3AED), onChat),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      childAspectRatio: 0.75,
      children: actions
          .map((a) => _ActionTile(action: a))
          .toList(),
    );
  }
}

class _Action {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Action(this.icon, this.label, this.color, this.onTap);
}

class _ActionTile extends StatefulWidget {
  final _Action action;
  const _ActionTile({required this.action});

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        HapticFeedback.selectionClick();
        widget.action.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: widget.action.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: widget.action.color.withOpacity(0.2), width: 1),
              ),
              child: Icon(widget.action.icon,
                  color: widget.action.color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              widget.action.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI ASSISTANT BANNER
// ─────────────────────────────────────────────────────────────────────────────
class _AIBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F766E).withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Assistant IA Juridique',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  Text(
                    'Décrivez votre situation, l\'IA identifie votre besoin',
                    style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.85), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEGAL DOMAINS
// ─────────────────────────────────────────────────────────────────────────────
class _LegalDomainsGrid extends StatelessWidget {
  static const _domains = [
    _Domain('Droit familial', Icons.family_restroom_rounded, Color(0xFF1A56DB)),
    _Domain('Droit pénal', Icons.gavel_rounded, Color(0xFFDC2626)),
    _Domain('Droit commercial', Icons.business_center_rounded, Color(0xFF0F766E)),
    _Domain('Droit civil', Icons.account_balance_rounded, Color(0xFF7C3AED)),
    _Domain('Droit du travail', Icons.work_outline_rounded, Color(0xFFD97706)),
    _Domain('Droit immobilier', Icons.home_work_rounded, Color(0xFF0369A1)),
    _Domain('Droit administratif', Icons.corporate_fare_rounded, Color(0xFF059669)),
    _Domain('Droit fiscal', Icons.receipt_long_rounded, Color(0xFFB45309)),
    _Domain('Propriété Intellectuelle', Icons.lightbulb_outline_rounded, Color(0xFF7C3AED)),
    _Domain('Droit des sociétés', Icons.handshake_outlined, Color(0xFF0F766E)),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 3.2,
      ),
      itemCount: _domains.length,
      itemBuilder: (_, i) {
        final d = _domains[i];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      DirectSearchScreen(preselectedSpeciality: d.name)),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: d.color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: d.color.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                Icon(d.icon, color: d.color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(d.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Domain {
  final String name;
  final IconData icon;
  final Color color;
  const _Domain(this.name, this.icon, this.color);
}
