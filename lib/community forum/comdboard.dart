import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:async';
import 'package:realtime_client/src/realtime_channel.dart';
import '../dashboardsidebar.dart';

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
  String? _expandedTopicId;
  Map<String, List<Map<String, dynamic>>> _topicReplies = {};
  Map<String, bool> _loadingReplies = {};

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

  Future<void> _loadRepliesForTopic(String topicId) async {
    if (_loadingReplies[topicId] == true) return;

    setState(() {
      _loadingReplies[topicId] = true;
    });

    try {
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
          .eq('topic_id', topicId)
          .order('created_at', ascending: true);

      setState(() {
        _topicReplies[topicId] = repliesResponse;
        _loadingReplies[topicId] = false;
      });
    } catch (error) {
      setState(() {
        _loadingReplies[topicId] = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading replies: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _submitReply(String topicId, String content) async {
    try {
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to reply'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      await supabase.from('forum_replies').insert({
        'topic_id': topicId,
        'user_id': userId,
        'content': content.trim(),
      });

      // Reload replies for this topic
      await _loadRepliesForTopic(topicId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply posted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting reply: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SidebarLayoutWrapper(
      currentPage: '/community',
      pageTitle: 'Community Forum',
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return RefreshIndicator(
      onRefresh: _loadForumTopics,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isWideScreen ? 900 : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Create Topic button - Made larger and more prominent
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: isWideScreen ? 24.0 : 20.0,
                              vertical: isWideScreen ? 16.0 : 14.0,
                            ),
                            textStyle: TextStyle(
                              fontSize: isWideScreen ? 18.0 : 16.0,
                              fontWeight: FontWeight.w600,
                            ),
                            elevation: 3,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateTopicPage(),
                              ),
                            ).then((_) => _loadForumTopics());
                          },
                          icon: const Icon(Icons.add, size: 24),
                          label: Text(
                            isWideScreen ? 'Start New Discussion' : 'New Topic',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Show error message if any
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade300),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                  // Display forum topics
                  Expanded(
                    child:
                        _isLoading
                            ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                            : _forumTopics.isEmpty
                            ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.forum_outlined,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No discussions yet',
                                      style: TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Be the first to start a conversation!',
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.grey.shade500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 8.0,
                              ),
                              itemCount: _forumTopics.length,
                              itemBuilder: (context, index) {
                                final topic = _forumTopics[index];
                                final user =
                                    topic['users'] as Map<String, dynamic>;
                                final fullName =
                                    '${user['first_name']} ${user['last_name']}';
                                final createdAt = DateTime.parse(
                                  topic['created_at'],
                                );
                                final timeAgo = timeago.format(createdAt);
                                final topicId = topic['id'];
                                final isExpanded = _expandedTopicId == topicId;

                                return Card(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: isWideScreen ? 8.0 : 4.0,
                                    vertical: 6.0,
                                  ),
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Column(
                                    children: [
                                      // Main topic content
                                      InkWell(
                                        onTap: () async {
                                          if (isExpanded) {
                                            setState(() {
                                              _expandedTopicId = null;
                                            });
                                          } else {
                                            setState(() {
                                              _expandedTopicId = topicId;
                                            });
                                            await _loadRepliesForTopic(topicId);
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(
                                          12.0,
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(
                                            isWideScreen ? 20.0 : 16.0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // User info and expand button
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius:
                                                        isWideScreen ? 24 : 20,
                                                    backgroundImage:
                                                        user['profile_picture_url'] !=
                                                                null
                                                            ? NetworkImage(
                                                              user['profile_picture_url'],
                                                            )
                                                            : null,
                                                    backgroundColor:
                                                        Colors.blue.shade100,
                                                    child:
                                                        user['profile_picture_url'] ==
                                                                null
                                                            ? Text(
                                                              fullName[0],
                                                              style: TextStyle(
                                                                fontSize:
                                                                    isWideScreen
                                                                        ? 18
                                                                        : 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    Colors
                                                                        .blue
                                                                        .shade700,
                                                              ),
                                                            )
                                                            : null,
                                                  ),
                                                  const SizedBox(width: 12.0),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          fullName,
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize:
                                                                isWideScreen
                                                                    ? 16.0
                                                                    : 15.0,
                                                            color:
                                                                Colors
                                                                    .grey
                                                                    .shade700,
                                                          ),
                                                        ),
                                                        Text(
                                                          timeAgo,
                                                          style: TextStyle(
                                                            color:
                                                                Colors
                                                                    .grey
                                                                    .shade500,
                                                            fontSize:
                                                                isWideScreen
                                                                    ? 14.0
                                                                    : 13.0,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Icon(
                                                    isExpanded
                                                        ? Icons.expand_less
                                                        : Icons.expand_more,
                                                    size: 28,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16.0),

                                              // Topic title
                                              Text(
                                                topic['title'],
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize:
                                                      isWideScreen
                                                          ? 20.0
                                                          : 18.0,
                                                  color: const Color(
                                                    0xFF1565C0,
                                                  ),
                                                  height: 1.3,
                                                ),
                                              ),
                                              const SizedBox(height: 12.0),

                                              // Topic content preview
                                              Text(
                                                topic['content'],
                                                style: TextStyle(
                                                  fontSize:
                                                      isWideScreen
                                                          ? 16.0
                                                          : 15.0,
                                                  height: 1.5,
                                                  color: Colors.grey.shade700,
                                                ),
                                                maxLines: isExpanded ? null : 3,
                                                overflow:
                                                    isExpanded
                                                        ? null
                                                        : TextOverflow.ellipsis,
                                              ),

                                              const SizedBox(height: 12.0),

                                              // Replies count
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.comment_outlined,
                                                    size: 18,
                                                    color: Colors.blue.shade600,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '${_topicReplies[topicId]?.length ?? 0} replies',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.blue.shade600,
                                                      fontSize: 14.0,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    isExpanded
                                                        ? 'Tap to collapse'
                                                        : 'Tap to view replies',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade500,
                                                      fontSize: 13.0,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Expanded replies section
                                      if (isExpanded)
                                        _buildRepliesSection(
                                          topicId,
                                          isWideScreen,
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRepliesSection(String topicId, bool isWideScreen) {
    final replies = _topicReplies[topicId] ?? [];
    final isLoading = _loadingReplies[topicId] == true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12.0),
          bottomRight: Radius.circular(12.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),

          // Replies header
          Padding(
            padding: EdgeInsets.all(isWideScreen ? 20.0 : 16.0),
            child: Row(
              children: [
                Icon(Icons.forum, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Discussion',
                  style: TextStyle(
                    fontSize: isWideScreen ? 18.0 : 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Replies list
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (replies.isEmpty)
            Padding(
              padding: EdgeInsets.all(isWideScreen ? 32.0 : 24.0),
              child: Center(
                child: Text(
                  'No replies yet. Be the first to join the conversation!',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: isWideScreen ? 16.0 : 15.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isWideScreen ? 20.0 : 16.0,
                vertical: 8.0,
              ),
              itemCount: replies.length,
              separatorBuilder:
                  (context, index) => const SizedBox(height: 12.0),
              itemBuilder: (context, index) {
                return _buildReplyCard(replies[index], isWideScreen);
              },
            ),

          // Reply input
          _buildReplyInput(topicId, isWideScreen),
        ],
      ),
    );
  }

  Widget _buildReplyCard(Map<String, dynamic> reply, bool isWideScreen) {
    final user = reply['users'] as Map<String, dynamic>? ?? {};
    final firstName = user['first_name'] ?? 'Unknown';
    final lastName = user['last_name'] ?? 'User';
    final fullName = '$firstName $lastName';

    final createdAt = DateTime.parse(reply['created_at']);
    final timeAgo = timeago.format(createdAt);
    final currentUser = supabase.auth.currentUser;
    final isCurrentUserReply =
        currentUser != null && currentUser.id == user['id'];

    return Container(
      padding: EdgeInsets.all(isWideScreen ? 16.0 : 14.0),
      decoration: BoxDecoration(
        color: isCurrentUserReply ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color:
              isCurrentUserReply ? Colors.blue.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: isWideScreen ? 18 : 16,
                backgroundImage:
                    user['profile_picture_url'] != null
                        ? NetworkImage(user['profile_picture_url'])
                        : null,
                backgroundColor: Colors.green.shade100,
                child:
                    user['profile_picture_url'] == null
                        ? Text(
                          fullName[0],
                          style: TextStyle(
                            fontSize: isWideScreen ? 14 : 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        )
                        : null,
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isWideScreen ? 15.0 : 14.0,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: isWideScreen ? 13.0 : 12.0,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrentUserReply)
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Delete Reply'),
                              content: const Text(
                                'Are you sure you want to delete this reply?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                      );

                      if (confirmed == true) {
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

                          // Reload replies
                          String? topicId;
                          for (var entry in _topicReplies.entries) {
                            if (entry.value.any(
                              (r) => r['id'] == reply['id'],
                            )) {
                              topicId = entry.key;
                              break;
                            }
                          }
                          if (topicId != null) {
                            await _loadRepliesForTopic(topicId);
                          }
                        } catch (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error deleting reply: $error'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 20),
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
          ),
          SizedBox(height: isWideScreen ? 12.0 : 10.0),
          Text(
            reply['content'],
            style: TextStyle(
              fontSize: isWideScreen ? 16.0 : 15.0,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyInput(String topicId, bool isWideScreen) {
    final TextEditingController replyController = TextEditingController();
    bool isSubmitting = false;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Container(
          padding: EdgeInsets.all(isWideScreen ? 20.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Join the conversation',
                style: TextStyle(
                  fontSize: isWideScreen ? 16.0 : 15.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12.0),
              TextField(
                controller: replyController,
                decoration: InputDecoration(
                  hintText: 'Write your reply here...',
                  hintStyle: TextStyle(
                    fontSize: isWideScreen ? 16.0 : 15.0,
                    color: Colors.grey.shade500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(
                      color: Colors.blue.shade400,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isWideScreen ? 16.0 : 14.0,
                    vertical: isWideScreen ? 16.0 : 14.0,
                  ),
                ),
                style: TextStyle(fontSize: isWideScreen ? 16.0 : 15.0),
                maxLines: 4,
                minLines: 2,
              ),
              const SizedBox(height: 12.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        isSubmitting
                            ? null
                            : () async {
                              if (replyController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a reply'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              setLocalState(() {
                                isSubmitting = true;
                              });

                              await _submitReply(topicId, replyController.text);

                              replyController.clear();
                              setLocalState(() {
                                isSubmitting = false;
                              });
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isWideScreen ? 20.0 : 16.0,
                        vertical: isWideScreen ? 12.0 : 10.0,
                      ),
                      textStyle: TextStyle(
                        fontSize: isWideScreen ? 16.0 : 15.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    icon:
                        isSubmitting
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Icon(Icons.send, size: 18),
                    label: Text(isSubmitting ? 'Posting...' : 'Post Reply'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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

      await supabase.from('forum_topics').insert({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'user_id': userId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discussion created successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating discussion: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return SidebarLayoutWrapper(
      currentPage: '/community',
      pageTitle: 'Start New Discussion',
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isWideScreen ? 800 : screenWidth * 0.95,
              minHeight: 300,
            ),
            padding: EdgeInsets.all(isWideScreen ? 24.0 : 20.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: EdgeInsets.all(isWideScreen ? 32.0 : 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(
                            Icons.create,
                            color: Colors.blue.shade600,
                            size: isWideScreen ? 28 : 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Create New Discussion',
                            style: TextStyle(
                              fontSize: isWideScreen ? 24.0 : 20.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isWideScreen ? 32.0 : 24.0),

                      // Title field
                      Text(
                        'Discussion Title',
                        style: TextStyle(
                          fontSize: isWideScreen ? 18.0 : 16.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      TextFormField(
                        controller: _titleController,
                        style: TextStyle(fontSize: isWideScreen ? 18.0 : 16.0),
                        decoration: InputDecoration(
                          hintText: 'Enter a clear, descriptive title...',
                          hintStyle: TextStyle(
                            fontSize: isWideScreen ? 16.0 : 15.0,
                            color: Colors.grey.shade500,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color: Colors.blue.shade400,
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isWideScreen ? 16.0 : 14.0,
                            vertical: isWideScreen ? 16.0 : 14.0,
                          ),
                          errorStyle: TextStyle(
                            fontSize: isWideScreen ? 14.0 : 13.0,
                            color: Colors.red.shade600,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title for your discussion';
                          }
                          if (value.trim().length < 5) {
                            return 'Title should be at least 5 characters long';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: isWideScreen ? 24.0 : 20.0),

                      // Content field
                      Text(
                        'Your Message',
                        style: TextStyle(
                          fontSize: isWideScreen ? 18.0 : 16.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      TextFormField(
                        controller: _contentController,
                        style: TextStyle(
                          fontSize: isWideScreen ? 16.0 : 15.0,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Share your thoughts, ask a question, or start a conversation...',
                          hintStyle: TextStyle(
                            fontSize: isWideScreen ? 15.0 : 14.0,
                            color: Colors.grey.shade500,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color: Colors.blue.shade400,
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isWideScreen ? 16.0 : 14.0,
                            vertical: isWideScreen ? 16.0 : 14.0,
                          ),
                          alignLabelWithHint: true,
                          errorStyle: TextStyle(
                            fontSize: isWideScreen ? 14.0 : 13.0,
                            color: Colors.red.shade600,
                          ),
                        ),
                        maxLines: isWideScreen ? 12 : 10,
                        minLines: isWideScreen ? 6 : 5,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your message';
                          }
                          if (value.trim().length < 10) {
                            return 'Message should be at least 10 characters long';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: isWideScreen ? 32.0 : 24.0),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Cancel button
                          TextButton(
                            onPressed:
                                _isSubmitting
                                    ? null
                                    : () {
                                      Navigator.pop(context);
                                    },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: isWideScreen ? 24.0 : 20.0,
                                vertical: isWideScreen ? 16.0 : 14.0,
                              ),
                              textStyle: TextStyle(
                                fontSize: isWideScreen ? 16.0 : 15.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                          const SizedBox(width: 16.0),

                          // Create button
                          ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _submitTopic,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: isWideScreen ? 24.0 : 20.0,
                                vertical: isWideScreen ? 16.0 : 14.0,
                              ),
                              textStyle: TextStyle(
                                fontSize: isWideScreen ? 16.0 : 15.0,
                                fontWeight: FontWeight.w600,
                              ),
                              elevation: 3,
                            ),
                            icon:
                                _isSubmitting
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : const Icon(Icons.create, size: 20),
                            label: Text(
                              _isSubmitting
                                  ? 'Creating...'
                                  : 'Create Discussion',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
