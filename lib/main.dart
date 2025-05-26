// File: Updated main.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart'; // Add this import
import 'providers/font_size_provider.dart'; // Add this import
import 'welcome_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'dashboard.dart';
import 'tutorial_page_mobile.dart' as mobile;
import 'games_page.dart';
import 'progress/progress.dart';
import 'community forum/comdboard.dart';
import 'package:senior_surfers/settings_page.dart';
import 'achievements_page.dart';
import 'package:senior_surfers/practice_mode_apps/GoogleMeetPage/gmeetwcpage1.dart';
import 'practice_mode.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification/notification.dart';
import 'games/googlemeet.dart';
import 'package:senior_surfers/practice_mode_apps/GoogleMeetPage/gmeetwcpage.dart';
import 'admin/admin_dashboard.dart';
import 'admin/admin_login.dart';
import 'admin/admin_community.dart';
import 'tech_glossary.dart';
import 'admin/admin_tutorial.dart';
import 'admin/admin_analysis.dart';
import 'games/zoom.dart';
import 'practice_mode_apps/GoogleMeetPage/joinmeet.dart';
import 'practice_mode_apps/GoogleMeetPage/joinmeet2.dart';
import 'practice_mode_apps/GoogleMeetPage/joinmeet3.dart';
import 'tutorial_page.dart';
import 'header_widget.dart';
import 'homepage.dart';
import 'package:provider/provider.dart';
import 'providers/font_size_provider.dart';
import 'interactivegames/gmeet.dart';

// Global instance for notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://jcnglhmzfgcbieeflzif.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpjbmdsaG16ZmdjYmllZWZsemlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI3OTk4MzksImV4cCI6MjA1ODM3NTgzOX0.1HL3EQ_dMoLQoK5fF6A9jY3Uu2BGi99DJeVSAV0bMbs',
  );

  // Initialize notifications...
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Wrap the app with providers
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => FontSizeProvider())],
      child: const MyApp(),
    ),
  );
}

// ... (keep all your existing GoRouter configuration exactly the same) ...
final GoRouter _router = GoRouter(
  debugLogDiagnostics: true,
  initialLocation: '/', // This stays as '/' which will show Welcome page
  redirect: (BuildContext context, GoRouterState state) {
    // Get the current user
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    // List of public routes that don't require authentication
    final publicRoutes = ['/', '/login', '/signup', '/admin-login'];
    final currentPath = state.matchedLocation;

    // Check if the user is trying to access admin routes
    final isGoingToAdminRoute =
        currentPath.startsWith('/admin') && currentPath != '/admin-login';

    // Admin route handling
    if (currentUser == null && isGoingToAdminRoute) {
      return '/admin-login';
    }
    if (currentUser != null && currentPath == '/admin-login') {
      return '/admin/analysis';
    }

    // UPDATED: User authentication handling - Always show welcome page first
    if (currentUser == null) {
      // User not logged in - allow access to public routes
      if (publicRoutes.contains(currentPath)) {
        return null; // Show the requested public route (including welcome page)
      } else {
        return '/'; // Redirect to welcome page for protected routes
      }
    } else {
      // User is logged in
      // REMOVED: Auto-redirect to dashboard - let users navigate manually
      // Only redirect login/signup pages since user is already logged in
      if (currentPath == '/login' || currentPath == '/signup') {
        return '/dashboard'; // Redirect logged-in users away from login/signup
      }
      // Allow logged-in users to visit welcome page if they want
    }

    // No redirect needed
    return null;
  },
  routes: [
    // UPDATED: Welcome page as the main landing page
    GoRoute(path: '/', builder: (context, state) => const WelcomePage()),

    // Authentication routes
    GoRoute(path: '/login', builder: (context, state) => const LoginPagee()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),

    // Main app routes (require authentication)
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(path: '/header', builder: (context, state) => const HeaderWidget()),
    GoRoute(path: '/home1', builder: (context, state) => const HomePage1()),
    GoRoute(path: '/tutorials', builder: (context, state) => TutorialPage()),
    GoRoute(path: '/practice', builder: (context, state) => PracticeModePage()),
    GoRoute(path: '/settingsD', builder: (context, state) => SettingsPage()),
    GoRoute(path: '/games', builder: (context, state) => GamesPage()),
    GoRoute(
      path: '/notification',
      builder: (context, state) => NotificationPage(),
    ),
    GoRoute(
      path: '/techglossary',
      builder: (context, state) => const TechGlossaryPage(),
    ),
    GoRoute(
      path: '/progress',
      builder: (context, state) => const ProgressPage(),
    ),
    GoRoute(
      path: '/community',
      builder: (context, state) => const CommunityForumPage(),
    ),
    GoRoute(
      path: '/achievements',
      builder: (context, state) => AchievementsPage(),
    ),
    GoRoute(
      path: '/gmeet-tutorial',
      builder: (context, state) => const GoogleMeetTutorial(),
    ),
    GoRoute(
      path: '/gmeetDashboard',
      builder: (context, state) => const Gmeet(),
    ),
    GoRoute(
      path: '/gmeetgame',
      builder: (context, state) => const GoogleMeetAdventureGame(),
    ),
    GoRoute(path: '/gmeetSignin1', builder: (context, state) => const GMeet2()),
    GoRoute(path: '/joinmeet1', builder: (context, state) => const JoinMeet1()),
    GoRoute(path: '/joinmeet2', builder: (context, state) => const JoinMeet2()),
    GoRoute(
      path: '/joinmeet3',
      builder: (context, state) => const JoinMeet3Screen(),
    ),

    // Admin routes
    GoRoute(
      path: '/admin-login',
      builder: (context, state) => const AdminLoginPage(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return AdminDashboard(child: child);
      },
      routes: [
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AnalysisPage(),
        ),
        GoRoute(
          path: '/admin/analysis',
          builder: (context, state) => const AnalysisPage(),
        ),
        GoRoute(
          path: '/admin/tutorials',
          builder: (context, state) => const AddTutorialPage(),
        ),
        GoRoute(
          path: '/admin/community',
          builder: (context, state) => AdminCommunityScreen(),
        ),
      ],
    ),
  ],
  errorBuilder:
      (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Page Not Found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The requested page "${state.matchedLocation}" was not found.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: const Text('Go to Welcome'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27445D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  // Check if user is logged in to show appropriate page
                  final supabase = Supabase.instance.client;
                  final currentUser = supabase.auth.currentUser;
                  if (currentUser != null) {
                    context.go('/dashboard'); // Go to dashboard if logged in
                  } else {
                    context.go('/'); // Go to welcome page if not logged in
                  }
                },
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        // Base theme configuration
        final baseTheme = ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.black),
            bodyLarge: TextStyle(color: Colors.black),
            titleMedium: TextStyle(color: Colors.black),
            titleLarge: TextStyle(color: Colors.black),
          ),
          cardColor: Colors.white,
          dialogBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF27445D),
            elevation: 0,
          ),
        );

        // Get scaled theme from FontSizeProvider
        final scaledTheme =
            fontProvider.isLoading
                ? baseTheme
                : fontProvider.getScaledTheme(baseTheme);

        return MaterialApp.router(
          title: 'Senior Surfers',
          debugShowCheckedModeBanner: false,
          theme: scaledTheme,
          darkTheme: scaledTheme,
          themeMode: ThemeMode.light,
          routerConfig: _router,
        );
      },
    );
  }
}
