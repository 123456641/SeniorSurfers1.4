import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:senior_surfers/settings/settings_page.dart';
import 'welcome_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'dashboard.dart';
import 'tutorial/tutorial_page.dart';
import 'practice_mode.dart';
import 'tech glossary/tech_glossary.dart';
import 'games_page.dart';
import 'admin/admin_dashboard.dart';
import 'admin/admin_login.dart';
import 'notification/notification.dart';
import 'tutorial/googlemeet.dart';
import 'progress/progress.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://jcnglhmzfgcbieeflzif.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpjbmdsaG16ZmdjYmllZWZsemlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI3OTk4MzksImV4cCI6MjA1ODM3NTgzOX0.1HL3EQ_dMoLQoK5fF6A9jY3Uu2BGi99DJeVSAV0bMbs',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Senior Surfers',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomePage(),
        '/login': (context) => const LoginPagee(),
        '/signup': (context) => const SignUpPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/tutorials': (context) => TutorialPage(),
        '/practice': (context) => PracticeModePage(),
        '/settings': (context) => const SettingsPage(),
        '/techglossary': (context) => TechGlossaryPage(),
        '/games': (context) => const GamesPage(),
        '/admin': (context) => AdminDashboard(),
        '/admin-login': (context) => const AdminLoginPage(),
        '/notification': (context) => NotificationPage(),
        '/googlemeet': (context) => const GoogleMeetTutorialPage(),
        '/progress': (context) => const ProgressPage(),
      },
    );
  }
}
