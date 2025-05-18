import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_tutorial.dart'; // Import the Tutorial management page
import 'admin_analysis.dart'; // Import the Analysis page
import 'admin_community.dart'; // Import the Community forum management page

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Senior Surfers',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF7F9FB),
      ),
      home: const AdminDashboard(),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0; // Default to Analysis page (index 0)
  String? profilePictureUrl;
  String firstName = 'Admin';
  String lastName = 'User';
  String email = 'admin@seniorSurfers.com';
  bool _isLoading = true;

  final SupabaseClient supabase = Supabase.instance.client;

  // List of pages for the body content
  final List<Widget> _pages = [
    const AnalysisPage(),
    const AddTutorialPage(),
    const AdminCommunityScreen(), // Community Forum page
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response =
          await supabase
              .from('users')
              .select('profile_picture_url, first_name, last_name, email')
              .eq('id', user.id)
              .single();

      // Force refresh profile picture URL by adding timestamp to prevent caching
      String? pictureUrl = response['profile_picture_url'];
      if (pictureUrl != null) {
        if (pictureUrl.contains('?')) {
          pictureUrl =
              '$pictureUrl&_cache=${DateTime.now().millisecondsSinceEpoch}';
        } else {
          pictureUrl =
              '$pictureUrl?_cache=${DateTime.now().millisecondsSinceEpoch}';
        }
      }

      setState(() {
        profilePictureUrl = pictureUrl;
        firstName = response['first_name'] ?? 'Admin';
        lastName = response['last_name'] ?? 'User';
        email = response['email'] ?? 'admin@seniorSurfers.com';
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add the logout function here
  Future<void> _handleLogout() async {
    try {
      await supabase.auth.signOut();
      // After logout, navigate to login screen
      // You may need to replace this with your actual login screen navigation
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
        // If you don't have named routes, use something like:
        // Navigator.of(context).pushReplacement(
        //   MaterialPageRoute(builder: (context) => const LoginScreen()),
        // );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),

      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Colors.white,
            child:
                _isLoading
                    ?
                    // Show loading indicator while fetching user data
                    Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3B6EA5),
                      ),
                    )
                    : Column(
                      children: [
                        // Admin profile section

                        // Profile picture and name
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: const Color(0xFFE0E0E0),
                                backgroundImage:
                                    profilePictureUrl != null
                                        ? NetworkImage(profilePictureUrl!)
                                        : null,
                                // If no image is available, use a fallback icon
                                child:
                                    profilePictureUrl == null
                                        ? const Icon(
                                          Icons.person,
                                          size: 40,
                                          color: Color(0xFF3B6EA5),
                                        )
                                        : null,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$firstName $lastName',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                            ],
                          ),
                        ),

                        // Navigation menu items
                        _buildSidebarItem(0, 'Analysis', Icons.analytics),
                        _buildSidebarItem(
                          1,
                          'Manage Tutorial',
                          Icons.video_library,
                        ),
                        _buildSidebarItem(2, 'Community Forum', Icons.forum),

                        const Spacer(), // Pushes logout to bottom
                        // Logout option
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: InkWell(
                            onTap: _handleLogout,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16.0,
                                horizontal: 24.0,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.logout,
                                    color: Colors.redAccent,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Log Out',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
          ),

          // Vertical divider
          Container(width: 1, color: Colors.grey.withOpacity(0.3)),

          // Main content area
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3B6EA5), Color(0xFF3B6EA5)],
                  stops: [0.0, 0.3],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _pages[_selectedIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, String title, IconData icon) {
    bool isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2F6) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? const Color(0xFF3B6EA5) : Colors.transparent,
              width: 4.0,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF3B6EA5) : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF3B6EA5) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
