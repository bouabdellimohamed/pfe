import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'lawyer_dashboard_screen.dart';
import 'lawyer_requests_screen.dart';
import 'chat_inbox_screen.dart';

class LawyerMainScreen extends StatefulWidget {
  const LawyerMainScreen({super.key});
  @override
  State<LawyerMainScreen> createState() => _LawyerMainScreenState();
}

class _LawyerMainScreenState extends State<LawyerMainScreen> {
  int _tab = 0;
  final _auth = AuthService();

  static const _navy = Color(0xFF0D1B2A);
  static const _navyLight = Color(0xFF1B2D42);
  static const _gold = Color(0xFFC9A84C);
  static const _textSecondary = Color(0xFF8A9BB0);

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _navyLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion',
            style: TextStyle(color: Color(0xFFF0EDE8), fontWeight: FontWeight.w700)),
        content: const Text('Voulez-vous vraiment vous déconnecter ?',
            style: TextStyle(color: Color(0xFF8A9BB0))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: Color(0xFF8A9BB0))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Déconnecter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await _auth.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: IndexedStack(
        index: _tab,
        children: const [
          LawyerDashboardScreen(),
          LawyerRequestsScreen(),
          _MessagesTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _navyLight,
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _tab,
            onTap: (i) => setState(() => _tab = i),
            backgroundColor: _navyLight,
            selectedItemColor: _gold,
            unselectedItemColor: _textSecondary,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inbox_outlined),
                activeIcon: Icon(Icons.inbox_rounded),
                label: 'Publications',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.forum_outlined),
                activeIcon: Icon(Icons.forum_rounded),
                label: 'Messages',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── onglet Messages intégré directement ─────────────────────────
class _MessagesTab extends StatelessWidget {
  const _MessagesTab();

  static const _navy = Color(0xFF0D1B2A);
  static const _navyLight = Color(0xFF1B2D42);
  static const _textPrimary = Color(0xFFF0EDE8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navyLight,
        automaticallyImplyLeading: false,
        title: const Text('Messages',
            style: TextStyle(color: _textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: const ChatInboxScreen(isLawyer: true),
    );
  }
}
