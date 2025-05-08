import 'package:flutter/material.dart';

class AddTutorialPage extends StatelessWidget {
  const AddTutorialPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Tutorial'),
        backgroundColor: const Color(0xFF3B6EA5), // blue color
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Tutorial',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Add your form or other UI components to add a tutorial
            TextField(
              decoration: InputDecoration(
                labelText: 'Tutorial Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                labelText: 'Tutorial Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 6,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle tutorial submission logic
              },
              child: const Text('Submit Tutorial'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B6EA5), // blue color
              ),
            ),
          ],
        ),
      ),
    );
  }
}
