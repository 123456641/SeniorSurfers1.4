import 'package:flutter/material.dart';

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
  bool _showAddTutorial = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('Senior Surfers'),
        backgroundColor: const Color(0xFF3B6EA5),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.settings),
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
              const SizedBox(height: 20),
              DashboardButton(
                label: 'Add Tech Term',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddTechTermScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              DashboardButton(
                label: 'Add Tutorial',
                onPressed: () {
                  setState(() {
                    _showAddTutorial = !_showAddTutorial;
                  });
                },
              ),
              const SizedBox(height: 10),
              DashboardButton(
                label: 'Community Forum',
                onPressed: () {
                  // navigateTo(context, '/community-forum'); // future use
                },
              ),
              if (_showAddTutorial) ...[
                const SizedBox(height: 20),
                const Text(
                  'Add New Tutorial',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tutorial Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _contentController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Tutorial Content',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    String title = _titleController.text;
                    String content = _contentController.text;
                    print('Saving Tutorial: $title\n$content');

                    _titleController.clear();
                    _contentController.clear();
                    setState(() {
                      _showAddTutorial = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B6EA5),
                  ),
                  child: const Text('Submit Tutorial'),
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

class AddTechTermScreen extends StatelessWidget {
  const AddTechTermScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController termController = TextEditingController();
    final TextEditingController definitionController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Tech Term'),
        backgroundColor: const Color(0xFF3B6EA5),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: termController,
              decoration: const InputDecoration(
                labelText: 'Tech Term',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: definitionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Definition',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                String term = termController.text;
                String definition = definitionController.text;

                // TODO: Add saving logic here (e.g., save to Supabase)

                print('Tech Term: $term\nDefinition: $definition');

                Navigator.pop(context); // Go back to dashboard
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B6EA5),
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
