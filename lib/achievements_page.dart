import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'header_widget.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final supabase = Supabase.instance.client;
  List<Achievement> achievements = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Get user's quiz statistics
      final user = supabase.auth.currentUser;
      Map<String, dynamic> stats = {};

      if (user != null) {
        // Fetch user's quiz results from Supabase
        final response = await supabase
            .from('quiz_results')
            .select('*')
            .eq('user_id', user.id)
            .eq('platform', 'Google Meet Quiz');

        final results = response as List<dynamic>;

        // Calculate statistics
        stats = _calculateStats(results);
      }

      // Define all available achievements
      achievements = [
        Achievement(
          id: 'first_play',
          title: 'First Steps!',
          description: 'Played Google Meet Quiz for the first time',
          imagePath: 'assets/images/badges/badge1.png',
          unlocked: stats['gamesPlayed'] >= 1,
          requirement: 1,
          currentProgress: stats['gamesPlayed'] ?? 0,
          type: AchievementType.gamesPlayed,
        ),
        Achievement(
          id: 'first_pass',
          title: 'Getting the Hang of It!',
          description: 'Passed the Google Meet Quiz once',
          imagePath: 'assets/images/badges/badge2.png',
          unlocked: stats['gamesPassed'] >= 1,
          requirement: 1,
          currentProgress: stats['gamesPassed'] ?? 0,
          type: AchievementType.gamesPassed,
        ),
        Achievement(
          id: 'five_plays',
          title: 'Dedicated Learner!',
          description: 'Played Google Meet Quiz 5 times',
          imagePath: 'assets/images/badges/badge3.png',
          unlocked: stats['gamesPlayed'] >= 5,
          requirement: 5,
          currentProgress: stats['gamesPlayed'] ?? 0,
          type: AchievementType.gamesPlayed,
        ),
        Achievement(
          id: 'five_passes',
          title: 'Meet Master!',
          description: 'Passed the Google Meet Quiz 5 times',
          imagePath: 'assets/images/badges/badge4.png',
          unlocked: stats['gamesPassed'] >= 5,
          requirement: 5,
          currentProgress: stats['gamesPassed'] ?? 0,
          type: AchievementType.gamesPassed,
        ),
        Achievement(
          id: 'high_score',
          title: 'Score Champion!',
          description: 'Achieved a score of 800 or higher',
          imagePath: 'assets/images/badges/badge5.png',
          unlocked: stats['highestScore'] >= 800,
          requirement: 800,
          currentProgress: stats['highestScore'] ?? 0,
          type: AchievementType.highScore,
        ),
        Achievement(
          id: 'perfect_score',
          title: 'Perfect Performance!',
          description: 'Achieved a perfect score (1000+)',
          imagePath: 'assets/images/badges/badge6.png',
          unlocked: stats['highestScore'] >= 1000,
          requirement: 1000,
          currentProgress: stats['highestScore'] ?? 0,
          type: AchievementType.perfectScore,
        ),
        Achievement(
          id: 'speed_demon',
          title: 'Speed Demon!',
          description:
              'Completed quiz with average time < 5 seconds per question',
          imagePath: 'assets/images/badges/badge7.png',
          unlocked:
              stats['fastestAverageTime'] > 0 &&
              stats['fastestAverageTime'] < 5,
          requirement: 5,
          currentProgress: stats['fastestAverageTime']?.round() ?? 20,
          type: AchievementType.speed,
        ),
        Achievement(
          id: 'difficulty_master',
          title: 'Difficulty Master!',
          description: 'Passed quiz on all difficulty levels',
          imagePath: 'assets/images/badges/badge8.png',
          unlocked: stats['difficultiesCompleted'] >= 3,
          requirement: 3,
          currentProgress: stats['difficultiesCompleted'] ?? 0,
          type: AchievementType.allDifficulties,
        ),
        Achievement(
          id: 'consistent_player',
          title: 'Consistent Player!',
          description: 'Played quiz on 7 different days',
          imagePath: 'assets/images/badges/badge9.png',
          unlocked: stats['uniqueDaysPlayed'] >= 7,
          requirement: 7,
          currentProgress: stats['uniqueDaysPlayed'] ?? 0,
          type: AchievementType.consistency,
        ),
        Achievement(
          id: 'adaptive_ace',
          title: 'Adaptive Ace!',
          description: 'Achieved skill rating of 1.8+ in adaptive mode',
          imagePath: 'assets/images/badges/badge10.png',
          unlocked: stats['highestSkillRating'] >= 1.8,
          requirement:
              18, // Displayed as 1.8 but stored as 18 for integer display
          currentProgress: ((stats['highestSkillRating'] ?? 0.0) * 10).round(),
          type: AchievementType.skillRating,
        ),
      ];

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load achievements: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Map<String, dynamic> _calculateStats(List<dynamic> results) {
    if (results.isEmpty) {
      return {
        'gamesPlayed': 0,
        'gamesPassed': 0,
        'highestScore': 0,
        'fastestAverageTime': 0.0,
        'difficultiesCompleted': 0,
        'uniqueDaysPlayed': 0,
        'highestSkillRating': 0.0,
      };
    }

    int gamesPlayed = results.length;
    int gamesPassed = results.where((r) => r['passed'] == true).length;
    int highestScore = results
        .map<int>((r) => r['score'] as int? ?? 0)
        .reduce((a, b) => a > b ? a : b);

    // Calculate fastest average time (only from games where time data exists)
    List<double> avgTimes =
        results
            .where((r) => r['average_time_per_question'] != null)
            .map<double>(
              (r) => (r['average_time_per_question'] as num).toDouble(),
            )
            .toList();
    double fastestAverageTime =
        avgTimes.isNotEmpty ? avgTimes.reduce((a, b) => a < b ? a : b) : 0.0;

    // Count unique difficulties completed (passed)
    Set<String> difficultiesCompleted =
        results
            .where((r) => r['passed'] == true)
            .map<String>((r) => r['difficulty'] as String? ?? '')
            .where((d) => d.isNotEmpty)
            .toSet();

    // Count unique days played
    Set<String> uniqueDays =
        results
            .map<String>((r) {
              final dateStr = r['created_at'] as String?;
              if (dateStr != null) {
                return DateTime.parse(dateStr).toIso8601String().split('T')[0];
              }
              return '';
            })
            .where((d) => d.isNotEmpty)
            .toSet();

    // Get highest skill rating
    double highestSkillRating = results
        .map<double>((r) => (r['skill_rating'] as num?)?.toDouble() ?? 0.0)
        .reduce((a, b) => a > b ? a : b);

    return {
      'gamesPlayed': gamesPlayed,
      'gamesPassed': gamesPassed,
      'highestScore': highestScore,
      'fastestAverageTime': fastestAverageTime,
      'difficultiesCompleted': difficultiesCompleted.length,
      'uniqueDaysPlayed': uniqueDays.length,
      'highestSkillRating': highestSkillRating,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: const HeaderWidget(),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading achievements...'),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: const HeaderWidget(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAchievements,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate achievement statistics
    int unlockedCount = achievements.where((a) => a.unlocked).length;
    int totalCount = achievements.length;
    double completionPercentage = (unlockedCount / totalCount) * 100;

    return Scaffold(
      appBar: const HeaderWidget(),
      body: RefreshIndicator(
        onRefresh: _loadAchievements,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with stats
            Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Achievements',
                    style: TextStyle(
                      fontSize: 45,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                      color: Color(0xFF27445D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: Colors.blue[700],
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$unlockedCount of $totalCount Achievements',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                              Text(
                                '${completionPercentage.toStringAsFixed(1)}% Complete',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        CircularProgressIndicator(
                          value: completionPercentage / 100,
                          backgroundColor: Colors.blue[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue[700]!,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Achievement list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  return AchievementBadge(achievement: achievements[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum AchievementType {
  gamesPlayed,
  gamesPassed,
  highScore,
  perfectScore,
  speed,
  allDifficulties,
  consistency,
  skillRating,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String imagePath;
  final bool unlocked;
  final int requirement;
  final int currentProgress;
  final AchievementType type;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.unlocked,
    required this.requirement,
    required this.currentProgress,
    required this.type,
  });
}

class AchievementBadge extends StatelessWidget {
  final Achievement achievement;

  const AchievementBadge({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: achievement.unlocked ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: achievement.unlocked ? Colors.green : Colors.grey[400]!,
          width: 2,
        ),
        boxShadow:
            achievement.unlocked
                ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Badge Image
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        achievement.unlocked
                            ? Colors.transparent
                            : Colors.grey[300],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      achievement.imagePath,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      color:
                          achievement.unlocked
                              ? null
                              : Colors.grey.withOpacity(0.6),
                      colorBlendMode:
                          achievement.unlocked ? null : BlendMode.modulate,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                achievement.unlocked
                                    ? Colors.blue[100]
                                    : Colors.grey[300],
                          ),
                          child: Icon(
                            Icons.emoji_events,
                            color:
                                achievement.unlocked
                                    ? Colors.blue[700]
                                    : Colors.grey[500],
                            size: 30,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (achievement.unlocked)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Achievement Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          achievement.unlocked
                              ? Colors.black
                              : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          achievement.unlocked
                              ? Colors.grey[700]
                              : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Progress indicator
                  if (!achievement.unlocked) ...[
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value:
                                achievement.currentProgress /
                                achievement.requirement,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue[400]!,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getProgressText(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[600],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Unlocked!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getProgressText() {
    switch (achievement.type) {
      case AchievementType.skillRating:
        double current = achievement.currentProgress / 10.0;
        double required = achievement.requirement / 10.0;
        return '${current.toStringAsFixed(1)}/${required.toStringAsFixed(1)}';
      default:
        return '${achievement.currentProgress}/${achievement.requirement}';
    }
  }
}
