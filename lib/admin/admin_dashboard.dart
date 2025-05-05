import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Map<String, String>> glossary = [
    {'term': 'App', 'definition': 'An application used on smartphones or tablets.'},
    {'term': 'Browser', 'definition': 'A program to access websites like Chrome or Safari.'},
    {'term': 'Click', 'definition': 'Pressing a button on a mouse or screen.'},
  ];

  void _addOrEditTerm({Map<String, String>? existingTerm, int? index}) {
    final _termController = TextEditingController(text: existingTerm?['term']);
    final _definitionController = TextEditingController(text: existingTerm?['definition']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existingTerm == null ? 'Add Term' : 'Edit Term'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _termController,
              decoration: InputDecoration(labelText: 'Term'),
            ),
            TextField(
              controller: _definitionController,
              decoration: InputDecoration(labelText: 'Definition'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTerm = {
                'term': _termController.text.trim(),
                'definition': _definitionController.text.trim(),
              };
              setState(() {
                if (existingTerm == null) {
                  glossary.add(newTerm);
                } else if (index != null) {
                  glossary[index] = newTerm;
                }
              });
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteTerm(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete "${glossary[index]['term']}"?'),
        content: Text('Are you sure you want to delete this term?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                glossary.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addTechTerm() {
    print("Add Tech Term button pressed");
    // TODO: Show dialog or form to add a tech term
  }

  void _addNewTutorial() {
    print("Add New Tutorial button pressed");
    // TODO: Navigate to tutorial creation page or show dialog
  }

  void _deleteUser() {
    print("Delete User button pressed");
    // TODO: Show user list or search field to delete a user
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _addTechTerm,
                  icon: Icon(Icons.library_add),
                  label: Text("Add Tech Term"),
                ),
                ElevatedButton.icon(
                  onPressed: _addNewTutorial,
                  icon: Icon(Icons.video_library),
                  label: Text("Add Tutorial"),
                ),
                ElevatedButton.icon(
                  onPressed: _deleteUser,
                  icon: Icon(Icons.person_remove),
                  label: Text("Delete User"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
            SizedBox(height: 24),
            Text(
              'Glossary Management',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: glossary.length,
                itemBuilder: (context, index) {
                  final item = glossary[index];
                  return Card(
                    child: ListTile(
                      title: Text(item['term']!),
                      subtitle: Text(item['definition']!),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _addOrEditTerm(existingTerm: item, index: index),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteTerm(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _addOrEditTerm(),
              icon: Icon(Icons.add),
              label: Text('Add New Term'),
            ),
          ],
        ),
      ),
    );
  }
}
