import 'dart:ui';
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

class _FeedHomeScreenState extends State<FeedHomeScreen> with SingleTickerProviderStateMixin {
  int _tab = 0;
  final _auth = AuthService();

  Future<void> _signOut() async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Déconnecter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final List<Widget> screens = [
      _HomeTab(
        onSearch: () => setState(() => _tab = 1),
        onConsultation: () => setState(() => _tab = 2),
        onPostRequest: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostRequestScreen())),
        onChat: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: AppBar(
                backgroundColor: const Color(0xFF0052D4),
                elevation: 0,
                title: const Text('Messages', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
      extendBody: true,
      body: IndexedStack(index: _tab, children: screens),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0052D4).withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: _tab,
            onTap: (i) {
              HapticFeedback.lightImpact();
              setState(() => _tab = i);
            },
            elevation: 0,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF0052D4),
            unselectedItemColor: const Color(0xFF94A3B8),
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: [
              _buildNavItem(Icons.home_rounded, Icons.home_outlined, 0),
              _buildNavItem(Icons.search_rounded, Icons.search_outlined, 1),
              _buildNavItem(Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 2),
              _buildNavItem(Icons.folder_special_rounded, Icons.folder_open_rounded, 3),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData activeIcon, IconData inactiveIcon, int index) {
    final isSelected = _tab == index;
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.all(isSelected ? 10 : 0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0052D4).withOpacity(0.1) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(isSelected ? activeIcon : inactiveIcon, size: 26),
      ),
      label: '',
    );
  }
}

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
    final firstName = user?.displayName?.split(' ').first ?? 'Client';
    final primaryColor = const Color(0xFF0052D4);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: () async {
          setState(() {});
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverAppBar(
              expandedHeight: 140.0,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: primaryColor,
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
                        right: -30,
                        top: -10,
                        child: Icon(Icons.gavel_rounded, size: 160, color: Colors.white.withOpacity(0.1)),
                      ),
                    ],
                  ),
                ),
                titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bonjour 👋', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
                    Text(
                      firstName,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                    ),
                  ],
                ),
              ),
              actions: [
                StreamBuilder<List<NotificationModel>>(
                  stream: _notificationService.getUnreadNotifications(user?.uid ?? ''),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return IconButton(
                      icon: Badge(
                        isLabelVisible: count > 0,
                        label: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10)),
                        backgroundColor: const Color(0xFFEF4444),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                    );
                  },
                ),
                PopupMenuButton(
                  icon: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: primaryColor.withOpacity(0.1),
                      child: Text(
                        firstName[0].toUpperCase(),
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  position: PopupMenuPosition.under,
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileManagementScreen())),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(Icons.person_rounded, size: 18, color: primaryColor),
                        ),
                        const SizedBox(width: 12),
                        const Text('Mon profil', style: TextStyle(fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    PopupMenuItem(
                      onTap: widget.onSignOut,
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.logout_rounded, size: 18, color: Colors.red),
                        ),
                        const SizedBox(width: 12),
                        const Text('Déconnexion', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
              ],
            ),
            
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _HeroBanner(onTap: widget.onSearch),
                      ),
                      const SizedBox(height: 32),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(2)),
                            ),
                            const SizedBox(width: 8),
                            const Text('Actions rapides', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _QuickActionsGrid(
                          onSearch: widget.onSearch,
                          onConsultation: widget.onConsultation,
                          onPostRequest: widget.onPostRequest,
                          onChat: widget.onChat,
                        ),
                      ),
                      const SizedBox(height: 32),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _AIBanner(),
                      ),
                      const SizedBox(height: 32),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(color: const Color(0xFF0F766E), borderRadius: BorderRadius.circular(2)),
                            ),
                            const SizedBox(width: 8),
                            const Text('Domaines juridiques', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 130,
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _LegalDomainsList.domains.length,
                          itemBuilder: (context, index) {
                            final domain = _LegalDomainsList.domains[index];
                            return _DomainCard(domain: domain);
                          },
                        ),
                      ),
                      const SizedBox(height: 100), // padding for bottom nav
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
}

class _HeroBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _HeroBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0052D4).withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E7FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_rounded, size: 14, color: Color(0xFF0052D4)),
                          SizedBox(width: 6),
                          Text('Recherche directe', style: TextStyle(color: Color(0xFF0052D4), fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Trouvez votre\navocat idéal',
                      style: TextStyle(color: Color(0xFF1E293B), fontSize: 24, fontWeight: FontWeight.w900, height: 1.2),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Recherchez par spécialité, région et\nconsultez les scores de performance.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0052D4),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: const Color(0xFF0052D4).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Commencer la recherche', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      _Action(Icons.manage_search_rounded, 'Recherche', const Color(0xFF0052D4), const Color(0xFFEFF6FF), onSearch),
      _Action(Icons.gavel_rounded, 'Consultation', const Color(0xFF0F766E), const Color(0xFFF0FDFA), onConsultation),
      _Action(Icons.campaign_rounded, 'Demande', const Color(0xFFF59E0B), const Color(0xFFFEF3C7), onPostRequest),
      _Action(Icons.question_answer_rounded, 'Messages', const Color(0xFF7C3AED), const Color(0xFFF3E8FF), onChat),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((a) => _ActionTile(action: a)).toList(),
    );
  }
}

class _Action {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  const _Action(this.icon, this.label, this.color, this.bgColor, this.onTap);
}

class _ActionTile extends StatelessWidget {
  final _Action action;
  const _ActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        action.onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: action.bgColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: action.color.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(action.icon, color: action.color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            action.label,
            style: const TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _AIBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AIAssistantScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assistant IA Juridique',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Décrivez votre cas, laissez l\'IA vous guider.',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, height: 1.3),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF6D28D9), size: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _DomainCard extends StatelessWidget {
  final _Domain domain;
  const _DomainCard({required this.domain});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => DirectSearchScreen(preselectedSpeciality: domain.name)));
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16, bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: domain.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(domain.icon, color: domain.color, size: 24),
            ),
            const Spacer(),
            Text(
              domain.name,
              maxLines: 2,
              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w700, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalDomainsList {
  static const domains = [
    _Domain('Droit familial', Icons.family_restroom_rounded, Color(0xFF0052D4)),
    _Domain('Droit pénal', Icons.gavel_rounded, Color(0xFFEF4444)),
    _Domain('Droit commercial', Icons.business_center_rounded, Color(0xFF0F766E)),
    _Domain('Droit civil', Icons.account_balance_rounded, Color(0xFF7C3AED)),
    _Domain('Droit du travail', Icons.work_rounded, Color(0xFFF59E0B)),
    _Domain('Droit immobilier', Icons.home_work_rounded, Color(0xFF0369A1)),
    _Domain('Droit administratif', Icons.corporate_fare_rounded, Color(0xFF059669)),
    _Domain('Propriété Intellectuelle', Icons.lightbulb_rounded, Color(0xFF7C3AED)),
  ];
}

class _Domain {
  final String name;
  final IconData icon;
  final Color color;
  const _Domain(this.name, this.icon, this.color);
}
