import 'package:flutter/material.dart';
import 'games/chess/chess.dart';
import 'games/solitaire.dart';
import 'games/damma.dart';
import 'games/googlemeet.dart';
import 'header_widget.dart';

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_GameItem> games = [
      _GameItem(
        name: 'Google Meet Quiz',
        widget: const GoogleMeetQuizGame(),
        image: 'assets/images/gmeetgamecover.png',
        description:
            'Test your knowledge with interactive quizzes inspired by Google Meet.',
      ),
      _GameItem(
        name: 'Chess',
        widget: const ChessGame(),
        image: 'assets/images/games/chess.png',
        description:
            'Play the classic game of chess against the computer or a friend.',
      ),
      _GameItem(
        name: 'Damma',
        widget: const DammaGame(),
        image: 'assets/images/games/damma.png',
        description:
            'Challenge yourself with this traditional strategic board game.',
      ),
    ];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: const HeaderWidget(),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Determine if we're on a mobile or web layout
          final isWebLayout = constraints.maxWidth > 600;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWebLayout ? 32.0 : 16.0,
                ),
                child: Row(
                  children: [
                    const Text(
                      'Games',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF27445D),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWebLayout ? 32.0 : 16.0,
                  ),
                  child: _buildGameGrid(context, games, isWebLayout),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGameGrid(
    BuildContext context,
    List<_GameItem> games,
    bool isWebLayout,
  ) {
    // For web, use a different grid layout with more columns
    final crossAxisCount = isWebLayout ? 4 : 2;
    final childAspectRatio = isWebLayout ? 0.8 : 0.9;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return _buildGameCard(context, game, isWebLayout);
      },
    );
  }

  Widget _buildGameCard(
    BuildContext context,
    _GameItem game,
    bool isWebLayout,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => game.widget),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: Image.asset(
                  game.image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    game.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isWebLayout)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        game.description,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameItem {
  final String name;
  final Widget widget;
  final String image;
  final String description;

  _GameItem({
    required this.name,
    required this.widget,
    required this.image,
    this.description = '',
  });
}
