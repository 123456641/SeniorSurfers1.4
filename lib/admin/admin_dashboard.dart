import 'package:flutter/material.dart';
import 'package:senior_surfers/settings_page.dart';
import 'admin_techterm.dart';
import 'admin_tutorial.dart'; // Import the Add Tutorial page

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Senior Surfers',
      theme: ThemeData(primarySwatch: Colors.blue),
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
  bool _showAddTechTerm = false;

  final TextEditingController _termController = TextEditingController();
  final TextEditingController _definitionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('Senior Surfers'),
        backgroundColor: const Color(0xFF3B6EA5),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Admin Dashboard',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              DashboardButton(
                label: 'Add Tutorial',
                onPressed: () {
                  // Navigate to the Add Tutorial page instead of showing a form
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddTutorialPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              DashboardButton(
                label: 'Add Tech Term',
                onPressed: () {
                  setState(() {
                    _showAddTechTerm = !_showAddTechTerm;
                  });
                },
              ),
              const SizedBox(height: 10),

              DashboardButton(
                label: 'Community Forum',
                onPressed: () {
                  Navigator.pushNamed(context, '/admincommunity');
                },
              ),

              // Add Tech Term Form
              if (_showAddTechTerm) ...[
                const SizedBox(height: 20),
                const Text(
                  'Add New Tech Term',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _termController,
                  decoration: const InputDecoration(
                    labelText: 'Tech Term',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _definitionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Definition',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    String term = _termController.text;
                    String definition = _definitionController.text;
                    print('Saving Tech Term: $term\n$definition');

                    _termController.clear();
                    _definitionController.clear();
                    setState(() {
                      _showAddTechTerm = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B6EA5),
                  ),
                  child: const Text('Submit Tech Term'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const DashboardButton({
    Key? key,
    required this.label,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          backgroundColor: const Color(0xFF3B6EA5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 4,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}
