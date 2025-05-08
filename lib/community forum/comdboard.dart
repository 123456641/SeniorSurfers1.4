import 'package:flutter/material.dart';
import '../header_widget.dart'; // Assuming you have a header widget

class CommunityForumPage extends StatelessWidget {
  const CommunityForumPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Insert your HeaderWidget here, for example:
            const HeaderWidget(),
            const SizedBox(width: 10),  // Optional space between header and title
            const Text('Community Forum'),
          ],
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // Dashboard Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                // Navigate to Dashboard (adjust accordingly)
                Navigator.pushNamed(context, '/dashboard');
              },
              child: const Text('Go to Dashboard'),
            ),
          ),
          
          // Start a Discussion Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                // Navigate to start discussion page (adjust accordingly)
                Navigator.pushNamed(context, '/start-discussion');
              },
              child: const Text('Start a Discussion'),
            ),
          ),

          // Displaying Discussion Threads
          Expanded(
            child: FutureBuilder(
              future: fetchDiscussions(), // Your function to fetch discussions
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No discussions available.'));
                }

                var discussions = snapshot.data as List<Map<String, dynamic>>;
                return ListView.builder(
                  itemCount: discussions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(discussions[index]['title']),
                      subtitle: Text('Started by: ${discussions[index]['user_name']}'),
                      onTap: () {
                        // Navigate to the discussion details page (adjust accordingly)
                        Navigator.pushNamed(context, '/discussion-details', arguments: discussions[index]);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Example function to fetch discussions (replace with your actual database fetch logic)
  Future<List<Map<String, dynamic>>> fetchDiscussions() async {
    // Replace with your Supabase logic to fetch data
    return [
      {'title': 'Discussion 1', 'user_name': 'User 1'},
      {'title': 'Discussion 2', 'user_name': 'User 2'},
    ];
  }
}




/*

create table discussions (
  id serial primary key,
  title text not null,
  description text,
  user_id uuid references users(id) on delete cascade,
  created_at timestamp with time zone default current_timestamp
);

create table discussion_replies (
  id serial primary key,
  discussion_id int references discussions(id) on delete cascade,
  user_id uuid references users(id) on delete cascade,
  reply_text text not null,
  created_at timestamp with time zone default current_timestamp
);
*/