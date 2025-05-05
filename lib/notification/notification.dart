import 'package:flutter/material.dart';
import '../header_widget.dart'; // Import your existing header widget

class NotificationPage extends StatelessWidget {
  // Example notifications
  final List<Map<String, String>> notifications = [
    {
      'title': 'New Update Available!',
      'message': 'A new version of the app is available. Please update to get the latest features and improvements.',
    },
    {
      'title': 'Learn How to Distinguish Scams',
      'message': 'New tutorial: Learn how to identify common scams and protect yourself from online fraud.',
    },
    {
      'title': 'Check Out Our Latest Features',
      'message': 'Explore the newest features in our app, designed to make your experience even better!',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderWidget(), // Add the header as you did in the other page
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add padding below the header for spacing
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Recent Notifications:',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Display the notifications
          Expanded(
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    title: Text(
                      notification['title']!,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(notification['message']!),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
