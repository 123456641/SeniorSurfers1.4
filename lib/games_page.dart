import 'package:flutter/material.dart';
import 'games/googlemeet.dart';
import 'games/zoom.dart';
import 'dashboardsidebar.dart';

class GamesPage extends StatelessWidget {
  final List<GameInfo> games = [
    GameInfo(
      title: 'Google Meet',
      description: 'Practice using Google Meet',
      imagePath: 'assets/images/practice/gmeet.png',
      route: '/googlemeet',
      page: const GoogleMeetAdventureGame(),
      color: Colors.green.shade700,
    ),
    GameInfo(
      title: 'Zoom',
      description: 'Practice using Zoom',
      imagePath: 'assets/images/practice/zoom.png',
      route: '/zoom',
      page: const ZoomQuizGame(),
      color: Colors.blue.shade700,
    ),
  ];

  GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SidebarLayoutWrapper(
      currentPage: '/games',
      pageTitle: 'Games',
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth < 1024;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isMobile ? 20 : 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF27445D),
                        const Color(0xFF27445D).withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.games,
                            color: Colors.amber,
                            size: isMobile ? 32 : 40,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Practice Games",
                              style: TextStyle(
                                fontSize: isMobile ? 24 : 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Learn by playing! Practice your video calling skills with these quiz games.",
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Games Grid
                _buildGamesGrid(context, isMobile, isTablet),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGamesGrid(BuildContext context, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Available Games",
          style: TextStyle(
            fontSize: isMobile ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF27445D),
          ),
        ),
        const SizedBox(height: 20),

        // Responsive grid layout
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount;
            double maxCardWidth = 280;
            double spacing = isMobile ? 16 : 24;

            if (constraints.maxWidth < 600) {
              crossAxisCount = 1;
            } else if (constraints.maxWidth < 900) {
              crossAxisCount = 2;
            } else {
              crossAxisCount = (constraints.maxWidth / (maxCardWidth + spacing))
                  .floor()
                  .clamp(2, 4);
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.85,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
              ),
              itemCount: games.length,
              itemBuilder: (context, index) {
                final game = games[index];
                return _buildGameCard(game, isMobile, context);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildGameCard(GameInfo game, bool isMobile, BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => game.page),
            ),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [game.color.withOpacity(0.05), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Game Image/Icon
              Container(
                width: isMobile ? 100 : 120,
                height: isMobile ? 100 : 120,
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: game.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: game.color.withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: game.color.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    game.imagePath,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback icon if image fails to load
                      return Container(
                        decoration: BoxDecoration(
                          color: game.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          game.title.toLowerCase().contains('google')
                              ? Icons.video_call
                              : Icons.videocam,
                          size: isMobile ? 50 : 60,
                          color: game.color,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Game Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  game.title,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF27445D),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 8),

              // Game Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  game.description,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 16),

              // Play Button
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => game.page),
                      ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: game.color,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: isMobile ? 12 : 14,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label: Text(
                    "Play Game",
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class GameInfo {
  final String title;
  final String description;
  final String imagePath;
  final String route;
  final Widget page;
  final Color color;

  const GameInfo({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.route,
    required this.page,
    required this.color,
  });
}
