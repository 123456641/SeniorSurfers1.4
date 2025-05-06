import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../header_widget.dart';
import 'dart:async';
import 'package:realtime_client/src/realtime_channel.dart'; // Added import for RealtimeChannel

// Get a reference to Supabase client
final supabase = Supabase.instance.client;

class CommunityForumPage extends StatefulWidget {
  const CommunityForumPage({Key? key}) : super(key: key);

  @override
  State<CommunityForumPage> createState() => _CommunityForumPageState();
}

class _CommunityForumPageState extends State<CommunityForumPage> {
  List<Map<String, dynamic>> _forumTopics = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadForumTopics();
  }

  Future<void> _loadForumTopics() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch forum topics with user information
      // If using the view approach, replace 'users' with 'user_profiles'
      final response = await supabase
          .from('forum_topics')
          .select('''
            *,
            users:user_id (
              id, 
              first_name, 
              last_name, 
              profile_picture_url
            )
          ''')
          .order('created_at', ascending: false);

      setState(() {
        _forumTopics = response;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Error loading forum topics: $error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderWidget(),
      body: RefreshIndicator(
        onRefresh: _loadForumTopics,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align content to left
          children: [
            // Title: Community Forum
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Community Forum',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: Color(0xFF27445D),
                ),
                textAlign: TextAlign.left,
              ),
            ),

            // Dashboard & Create Topic Buttons
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/dashboard');
                    },
                    child: const Text('Dashboard'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateTopicPage(),
                        ),
                      ).then((_) => _loadForumTopics());
                    },
                    child: const Text('Start New Topic'),
                  ),
                ],
              ),
            ),

            // Show error message if any
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // Display forum topics
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _forumTopics.isEmpty
                      ? const Center(
                        child: Text('No topics yet. Be the first to post!'),
                      )
                      : ListView.builder(
                        itemCount: _forumTopics.length,
                        itemBuilder: (context, index) {
                          final topic = _forumTopics[index];
                          final user = topic['users'] as Map<String, dynamic>;
                          final fullName =
                              '${user['first_name']} ${user['last_name']}';
                          final createdAt = DateTime.parse(topic['created_at']);
                          final timeAgo = timeago.format(createdAt);

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    user['profile_picture_url'] != null
                                        ? NetworkImage(
                                          user['profile_picture_url'],
                                        )
                                        : null,
                                child:
                                    user['profile_picture_url'] == null
                                        ? Text(fullName[0])
                                        : null,
                              ),
                              title: Text(
                                topic['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text('Posted by $fullName • $timeAgo'),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => TopicDetailPage(
                                          topicId: topic['id'],
                                          topicTitle: topic['title'],
                                        ),
                                  ),
                                ).then((_) => _loadForumTopics());
                              },
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTopicPage()),
          ).then((_) => _loadForumTopics());
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CreateTopicPage extends StatefulWidget {
  const CreateTopicPage({Key? key}) : super(key: key);

  @override
  State<CreateTopicPage> createState() => _CreateTopicPageState();
}

class _CreateTopicPageState extends State<CreateTopicPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitTopic() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get current user ID
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to create a topic'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Insert the new topic
      await supabase.from('forum_topics').insert({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'user_id': userId,
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Topic created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating topic: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Topic')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Topic Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter content';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitTopic,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child:
                    _isSubmitting
                        ? const CircularProgressIndicator()
                        : const Text('Create Topic'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TopicDetailPage extends StatefulWidget {
  final String topicId;
  final String topicTitle;

  const TopicDetailPage({
    Key? key,
    required this.topicId,
    required this.topicTitle,
  }) : super(key: key);

  @override
  State<TopicDetailPage> createState() => _TopicDetailPageState();
}

class _TopicDetailPageState extends State<TopicDetailPage> {
  Map<String, dynamic>? _topicDetails;
  List<Map<String, dynamic>> _replies = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final _replyController = TextEditingController();
  bool _isSubmittingReply = false;
  // Change the type from StreamSubscription to RealtimeChannel
  RealtimeChannel? _repliesSubscription;

  @override
  void initState() {
    super.initState();
    _loadTopicAndReplies();
    // Set up real-time listener for replies
    _setupRealtimeSubscription();
  }

  // Set up real-time subscription to handle deleted replies
  void _setupRealtimeSubscription() {
    _repliesSubscription =
        supabase
            .channel('public:forum_replies')
            .onPostgresChanges(
              event: PostgresChangeEvent.delete,
              schema: 'public',
              table: 'forum_replies',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'topic_id',
                value: widget.topicId,
              ),
              callback: (payload) {
                // When a reply is deleted, just refresh the data
                _loadTopicAndReplies();
              },
            )
            .subscribe();
  }

  Future<void> _loadTopicAndReplies() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // First check if the topic still exists
      final topicExists =
          await supabase
              .from('forum_topics')
              .select('id')
              .eq('id', widget.topicId)
              .maybeSingle();

      // If topic no longer exists, show appropriate message and return
      if (topicExists == null) {
        setState(() {
          _errorMessage = 'This topic has been deleted.';
          _isLoading = false;
        });
        return;
      }

      // Fetch topic details with user information
      final topicResponse =
          await supabase
              .from('forum_topics')
              .select('''
            *,
            users:user_id (
              id, 
              first_name, 
              last_name, 
              profile_picture_url
            )
          ''')
              .eq('id', widget.topicId)
              .single();

      // Fetch replies with user information
      final repliesResponse = await supabase
          .from('forum_replies')
          .select('''
            *,
            users:user_id (
              id, 
              first_name, 
              last_name, 
              profile_picture_url
            )
          ''')
          .eq('topic_id', widget.topicId)
          .order('created_at', ascending: true);

      // Only update state if the widget is still mounted
      if (mounted) {
        setState(() {
          _topicDetails = topicResponse;
          _replies = repliesResponse;
          _isLoading = false;
        });
      }
    } catch (error) {
      // Handle errors gracefully
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading topic details: $error';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitReply() async {
    if (_replyController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSubmittingReply = true;
    });

    try {
      // Get current user ID
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to reply'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Insert the new reply
      await supabase.from('forum_replies').insert({
        'topic_id': widget.topicId,
        'user_id': userId,
        'content': _replyController.text.trim(),
      });

      // Clear the input field
      _replyController.clear();

      // Reload replies
      await _loadTopicAndReplies();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply posted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting reply: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingReply = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    // Cancel subscription when widget is disposed
    _repliesSubscription
        ?.unsubscribe(); // Use unsubscribe() instead of remove()
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.topicTitle)),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Topic details
                  if (_topicDetails != null) _buildTopicCard(),

                  // Replies header
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Text(
                          'Replies',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Text(
                            '${_replies.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Replies list
                  Expanded(
                    child:
                        _replies.isEmpty
                            ? const Center(
                              child: Text(
                                'No replies yet. Be the first to reply!',
                              ),
                            )
                            : ListView.builder(
                              itemCount: _replies.length,
                              itemBuilder: (context, index) {
                                // Check if reply still exists before building card
                                final reply = _replies[index];
                                if (reply == null) return const SizedBox();
                                return _buildReplyCard(reply);
                              },
                            ),
                  ),

                  // Reply input
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _replyController,
                            decoration: const InputDecoration(
                              hintText: 'Write a reply...',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            minLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        IconButton(
                          onPressed: _isSubmittingReply ? null : _submitReply,
                          icon:
                              _isSubmittingReply
                                  ? const CircularProgressIndicator()
                                  : const Icon(Icons.send),
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildTopicCard() {
    final user = _topicDetails!['users'] as Map<String, dynamic>;
    final fullName = '${user['first_name']} ${user['last_name']}';
    final createdAt = DateTime.parse(_topicDetails!['created_at']);
    final timeAgo = timeago.format(createdAt);

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage:
                      user['profile_picture_url'] != null
                          ? NetworkImage(user['profile_picture_url'])
                          : null,
                  child:
                      user['profile_picture_url'] == null
                          ? Text(fullName[0])
                          : null,
                ),
                const SizedBox(width: 8.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Text(
              _topicDetails!['title'],
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(_topicDetails!['content']),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyCard(Map<String, dynamic> reply) {
    // Add null safety checks for user info
    final user = reply['users'] as Map<String, dynamic>? ?? {};
    final firstName = user['first_name'] ?? 'Unknown';
    final lastName = user['last_name'] ?? 'User';
    final fullName = '$firstName $lastName';

    final createdAt = DateTime.parse(reply['created_at']);
    final timeAgo = timeago.format(createdAt);
    final currentUser = supabase.auth.currentUser;
    final isCurrentUserReply =
        currentUser != null && currentUser.id == user['id'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: isCurrentUserReply ? Colors.blue.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage:
                      user['profile_picture_url'] != null
                          ? NetworkImage(user['profile_picture_url'])
                          : null,
                  child:
                      user['profile_picture_url'] == null
                          ? Text(fullName[0])
                          : null,
                ),
                const SizedBox(width: 8.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
                if (isCurrentUserReply) ...[
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        // Handle edit reply
                        // Implement edit functionality
                      } else if (value == 'delete') {
                        // Handle delete reply
                        try {
                          await supabase
                              .from('forum_replies')
                              .delete()
                              .eq('id', reply['id']);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reply deleted'),
                              backgroundColor: Colors.green,
                            ),
                          );

                          _loadTopicAndReplies();
                        } catch (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $error'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8.0),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8.0),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8.0),
            Text(reply['content']),
          ],
        ),
      ),
    );
  }
}
