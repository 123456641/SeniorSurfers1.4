import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'welcome_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'dashboard.dart';
import 'tutorial/tutorial_page.dart';
import 'tech glossary/tech_glossary.dart';
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
import 'admin/admin_techterm.dart';
import 'admin/admin_tutorial.dart';
import 'admin/admin_analysis.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://jcnglhmzfgcbieeflzif.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpjbmdsaG16ZmdjYmllZWZsemlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI3OTk4MzksImV4cCI6MjA1ODM3NTgzOX0.1HL3EQ_dMoLQoK5fF6A9jY3Uu2BGi99DJeVSAV0bMbs',
  );

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
        '/settingsD': (context) => SettingsPage(),
        '/techglossary': (context) => TechGlossaryPage(),
        '/games': (context) => const GamesPage(),
        '/admin': (context) => AdminDashboard(),
        '/admin-login': (context) => const AdminLoginPage(),
        '/notification': (context) => NotificationPage(),
        '/progress': (context) => const ProgressPage(),
        '/community': (context) => const CommunityForumPage(),
        '/achievements': (context) => AchievementsPage(),
        '/admincommunity': (context) => AdminCommunityScreen(),
        '/AddTechTermScreen': (context) => const AdminTechTermsPage(),
        'gmeetDashboard': (context) => const GmeetDashboard1(),
        '/admintutorial': (context) => const AddTutorialPage(),
        '/adminanalysis': (context) => const AnalysisPage(),
        '/gmeetgame': (context) => const GoogleMeetQuizGame(),
        '/gmeetSignin1': (context) => const GoogleMeetSignIn1(),
      },
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
