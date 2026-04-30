import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/choose_method_screen.dart';
import 'screens/direct_search_screen.dart';
import 'screens/lawyer_register_screen.dart' as register;
import 'screens/lawyer_login_screen.dart' as login;
import 'screens/lawyer_main_screen.dart';
import 'screens/lawyer_edit_profile_screen.dart' as edit;
import 'models/lawyer_model.dart';
import 'screens/feed_screen.dart';
import 'auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  runApp(const JurisdZApp());
}

class JurisdZApp extends StatelessWidget {
  const JurisdZApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JURISDZ — Plateforme Juridique Algérienne',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,

      // Start with SplashScreen (routes to Onboarding or AuthWrapper)
      home: const SplashScreen(),

      routes: {
        '/feed': (context) => const FeedHomeScreen(),
        '/lawyer-dashboard': (context) => const LawyerMainScreen(),
        '/choice': (context) => const ChooseMethodScreen(),
        '/direct-search': (context) => const DirectSearchScreen(),
        '/lawyer-register': (context) => register.LawyerRegisterScreen(),
        '/lawyer-login': (context) => login.LawyerLoginScreen(),
        '/auth': (context) => const AuthWrapper(),
      },

      onGenerateRoute: (settings) {
        if (settings.name == '/lawyer-edit-profile') {
          final args = settings.arguments;
          return MaterialPageRoute(
            builder: (_) => args is LawyerModel
                ? edit.LawyerEditProfileScreen(lawyer: args)
                : edit.LawyerEditProfileScreen(),
          );
        }
        return null;
      },

      // Global page transition
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
