import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:provider/provider.dart';
import 'welcome_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'dashboard.dart';
import 'tutorial/tutorial_page.dart';
import 'practice_mode.dart';
import 'settings/settings_page.dart';
import 'tech glossary/tech_glossary.dart';
import 'games_page.dart';
import 'admin/admin_dashboard.dart';
import 'admin/admin_login.dart';
import 'notification/notification.dart';
import 'tutorial/googlemeet.dart';
import 'progress/progress.dart';
import 'community forum/comdboard.dart';
//import 'community forum/repliesPage.dart'; // Make sure this file exists
import 'providers/font_size_provider.dart'; // Import the new provider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://jcnglhmzfgcbieeflzif.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpjbmdsaG16ZmdjYmllZWZsemlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI3OTk4MzksImV4cCI6MjA1ODM3NTgzOX0.1HL3EQ_dMoLQoK5fF6A9jY3Uu2BGi99DJeVSAV0bMbs',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appLinks = AppLinks();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();
  }

  void _handleIncomingLinks() {
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null && uri.path == '/reset-password') {
        final token = uri.queryParameters['access_token'];
        if (token != null) {
          Navigator.pushNamed(
            navigatorKey.currentContext!,
            '/reset-password',
            arguments: token,
          );
        }
      }
    }, onError: (err) {
      debugPrint('AppLinks error: $err');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with MultiProvider to provide FontSizeProvider to all widgets
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FontSizeProvider()),
        // Add other providers here if needed
      ],
      child: Consumer<FontSizeProvider>(
        builder: (context, fontSizeProvider, child) {
          return MaterialApp(
            title: 'Senior Surfers',
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              // Apply font size scaling to the entire app
              textTheme: Theme.of(context).textTheme.apply(
                    fontSizeFactor: fontSizeProvider.fontSize / 16.0,
                  ),
            ),
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
              '/communitydashboard': (context) => const ProgressPage(),
              '/community': (context) => const CommunityForumPage(),
              // '/replies': (context) => const repliesPage(), // Only if you have this page
            },
          );
        },
      ),
    );
  }
}