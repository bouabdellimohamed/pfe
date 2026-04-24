import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
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
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase error: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JURISDZ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: const Color(0xFFF8F9FB),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/feed': (context) => const FeedHomeScreen(),
        '/lawyer-dashboard': (context) => const LawyerMainScreen(),
        '/choice': (context) => const ChooseMethodScreen(),
        '/direct-search': (context) => const DirectSearchScreen(),
        '/lawyer-register': (context) => register.LawyerRegisterScreen(),
        '/lawyer-login': (context) => login.LawyerLoginScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/lawyer-edit-profile') {
          final args = settings.arguments;
          return MaterialPageRoute(
            builder: (_) => args is LawyerModel
                ? edit.LawyerEditProfileScreen(lawyer: args is LawyerModel ? args : null)
                : edit.LawyerEditProfileScreen(),
          );
        }
        return null;
      },
    );
  }
}
