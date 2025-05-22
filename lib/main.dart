import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'welcome_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'dashboard.dart';
import 'tutorial_page.dart';
import 'games_page.dart';
import 'progress/progress.dart';
import 'community forum/comdboard.dart';
import 'package:senior_surfers/settings_page.dart';
import 'achievements_page.dart';
import 'package:senior_surfers/practice_mode_apps/GoogleMeetPage/gmeetwcpage1.dart';
import 'practice_mode.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://jcnglhmzfgcbieeflzif.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpjbmdsaG16ZmdjYmllZWZsemlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI3OTk4MzksImV4cCI6MjA1ODM3NTgzOX0.1HL3EQ_dMoLQoK5fF6A9jY3Uu2BGi99DJeVSAV0bMbs',
  );

  // Initialize notifications
  await AwesomeNotifications().initialize(null, [
    NotificationChannel(
      channelKey: 'tutorial_channel',
      channelName: 'Tutorial Notifications',
      channelDescription: 'Notification channel for tutorial uploads',
      defaultColor: const Color(0xFF3B6EA5),
      ledColor: Colors.white,
    ),
  ], debug: true);

  runApp(const MyApp());
}

// Create a GoRouter configuration
final GoRouter _router = GoRouter(
  debugLogDiagnostics: true,
  initialLocation: '/',
  redirect: (BuildContext context, GoRouterState state) {
    // Get the current user
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    // Check if the user is trying to access admin routes
    final isGoingToAdminRoute =
        state.matchedLocation.startsWith('/admin') &&
        state.matchedLocation != '/admin-login';

    // If user is not logged in and trying to access admin routes, redirect to admin login
    if (currentUser == null && isGoingToAdminRoute) {
      return '/admin-login';
    }

    // If user is logged in and going to admin login, redirect to admin dashboard
    if (currentUser != null && state.matchedLocation == '/admin-login') {
      return '/admin/analysis';
    }

    // No redirect needed
    return null;
  },
  routes: [
    // User routes
    GoRoute(path: '/', builder: (context, state) => const WelcomePage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPagee()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(path: '/tutorials', builder: (context, state) => TutorialPage()),
    GoRoute(path: '/practice', builder: (context, state) => PracticeModePage()),
    GoRoute(path: '/settingsD', builder: (context, state) => SettingsPage()),
    GoRoute(path: '/games', builder: (context, state) => const GamesPage()),
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
      path: '/gmeetDashboard',
      builder: (context, state) => const Gmeet(),
    ),
    GoRoute(
      path: '/gmeetgame',
      builder: (context, state) => const GoogleMeetQuizGame(),
    ),
    GoRoute(path: '/gmeetSignin1', builder: (context, state) => const GMeet2()),
    GoRoute(
      path: '/zoomgame',
      builder: (context, state) => const ZoomQuizGame(),
    ),
    GoRoute(path: '/joinmeet1', builder: (context, state) => const JoinMeet1()),
    GoRoute(path: '/joinmeet2', builder: (context, state) => const JoinMeet2()),
    GoRoute(
      path: '/joinmeet3',
      builder: (context, state) => const JoinMeet3Screen(),
    ),

    // Admin login route (standalone)
    GoRoute(
      path: '/admin-login',
      builder: (context, state) => const AdminLoginPage(),
    ),

    // Admin dashboard routes using ShellRoute
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
              const Text('The requested page was not found.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Go to Dashboard'),
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
    return MaterialApp.router(
      title: 'Senior Surfers',
      debugShowCheckedModeBanner: false,

      // Set up light theme with your app's colors
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Force light brightness
        brightness: Brightness.light,
        // Set default scaffold background to white
        scaffoldBackgroundColor: Colors.white,
        // Text color theme
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
          bodyLarge: TextStyle(color: Colors.black),
          titleMedium: TextStyle(color: Colors.black),
          titleLarge: TextStyle(color: Colors.black),
        ),
        // Card and dialog colors
        cardColor: Colors.white,
        dialogBackgroundColor: Colors.white,
        // AppBar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF27445D),
          elevation: 0,
        ),
      ),

      // Force light theme even when system is in dark mode
      darkTheme: ThemeData(
        // Use the same settings as light theme
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
      ),

      // Always use light theme regardless of system setting
      themeMode: ThemeMode.light,

      // Use go_router instead of named routes
      routerConfig: _router,
    );
  }

  // This method should be called in your main.dart or initialization code
  Future<void> initializeNotifications() async {
    await AwesomeNotifications().initialize(
      // set the icon to null if you want to use the default app icon
      null,
      [
        NotificationChannel(
          channelGroupKey: 'tutorial_group',
          channelKey: 'tutorial_channel',
          channelName: 'Tutorial Notifications',
          channelDescription: 'Notifications about new tutorials and files',
          defaultColor: const Color(0xFF3B6EA5),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
        ),
      ],
      // Channel groups are only visual and are not required
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'tutorial_group',
          channelGroupName: 'Tutorial Group',
        ),
      ],
      debug: true,
    );

    // Request permission
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }
}
