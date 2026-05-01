import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
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

  static const _gold      = Color(0xFFC9A84C);
  static const _textSec   = Color(0xFF8A9BB0);

  Future<void> _signOut() async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2D42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.1))),
        title: Text('logout_confirm_title'.tr(),
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        content: Text('confirm_logout'.tr(),
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr(),
                style: GoogleFonts.poppins(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('logout'.tr(),
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await _auth.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/auth', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        key: ValueKey(context.locale.languageCode),
        index: _tab,
        children: const [
          LawyerDashboardScreen(),
          LawyerRequestsScreen(),
          _MessagesTab(),
        ],
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F2027).withOpacity(0.85),
              border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.08))),
            ),
            child: SafeArea(
              top: false,
              child: BottomNavigationBar(
                currentIndex: _tab,
                onTap: (i) {
                  HapticFeedback.selectionClick();
                  setState(() => _tab = i);
                },
                backgroundColor: Colors.transparent,
                selectedItemColor: _gold,
                unselectedItemColor: Colors.white54,
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                selectedLabelStyle: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
                items: [
                  BottomNavigationBarItem(
                    icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_outlined)),
                    activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_rounded)),
                    label: 'home'.tr(),
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.inbox_outlined)),
                    activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.inbox_rounded)),
                    label: 'publications'.tr(),
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.forum_outlined)),
                    activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.forum_rounded)),
                    label: 'messages'.tr(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Messages tab ─────────────────────────────────────────────────────────────
class _MessagesTab extends StatelessWidget {
  const _MessagesTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
              ),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: AppBar(
                    backgroundColor: Colors.transparent,
                    automaticallyImplyLeading: false,
                    elevation: 0,
                    title: Text('messages'.tr(),
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
            const Expanded(child: ChatInboxScreen(isLawyer: true)),
          ],
        ),
      ),
    );
  }
}
