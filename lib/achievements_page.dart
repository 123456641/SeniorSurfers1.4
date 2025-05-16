import 'package:flutter/material.dart';
import 'header_widget.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final achievements = [
      {
        'title': 'Completed 1 instructional tutorial',
        'unlocked': true,
        'image': 'assets/images/badges/badge1.png',
      },
    ];

    return Scaffold(
      appBar: const HeaderWidget(), // <-- moved here
      body: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Ensure column starts left
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 20.0, bottom: 10.0, left: 20.0),
            child: Text(
              'Achievements',
              style: TextStyle(
                fontSize: 45,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
                color: Color(0xFF27445D),
              ),
              textAlign: TextAlign.left, // optional for Text widget
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                return AchievementBadge(
                  title: achievement['title'] as String,
                  unlocked: achievement['unlocked'] as bool,
                  imagePath:
                      achievement['image'] as String? ??
                      'assets/images/placeholder_badge.png',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AchievementBadge extends StatelessWidget {
  final String title;
  final bool unlocked;
  final String imagePath;

  const AchievementBadge({
    super.key,
    required this.title,
    required this.unlocked,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : Colors.grey[200],
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: unlocked ? Colors.green : Colors.grey,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset(
              imagePath,
              width: 80,
              height: 80,
              fit: BoxFit.contain,
              color: unlocked ? null : Colors.grey.withOpacity(0.6),
              colorBlendMode: unlocked ? null : BlendMode.modulate,
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                color: unlocked ? Colors.black : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
