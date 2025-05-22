import 'package:flutter/material.dart';
import 'dart:async';
import '../games_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(const GoogleMeetQuizGame());
}

class GoogleMeetQuizGame extends StatelessWidget {
  const GoogleMeetQuizGame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Meet Quiz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8), // Google Blue
          primary: const Color(0xFF1A73E8),
          secondary: const Color(0xFF34A853), // Google Green
          background: Colors.white,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF202124),
          ),
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF202124)),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/quiz': (context) => const QuizScreen(),
        '/games': (context) => const GamesPage(),
      },
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.video_call_rounded,
                size: 120,
                color: Colors.white,
              ),
              const SizedBox(height: 40),
              const Text(
                'Google Meet',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Knowledge Quiz',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
              const SizedBox(height: 60),
              // Modified to add difficulty selection
              Column(
                children: [
                  const Text(
                    'Select Difficulty',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDifficultyButton(
                        context,
                        'Beginner',
                        Colors.green,
                        DifficultyLevel.beginner,
                      ),
                      const SizedBox(width: 12),
                      _buildDifficultyButton(
                        context,
                        'Intermediate',
                        Colors.orange,
                        DifficultyLevel.intermediate,
                      ),
                      const SizedBox(width: 12),
                      _buildDifficultyButton(
                        context,
                        'Advanced',
                        Colors.red,
                        DifficultyLevel.advanced,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const QuizScreen(
                                initialDifficulty: DifficultyLevel.adaptive,
                              ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Adaptive Mode'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  context.go('/games');
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(
    BuildContext context,
    String text,
    Color color,
    DifficultyLevel difficulty,
  ) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(initialDifficulty: difficulty),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(text),
    );
  }
}

// Enum to define difficulty levels
enum DifficultyLevel { beginner, intermediate, advanced, adaptive }

class QuizScreen extends StatefulWidget {
  final DifficultyLevel initialDifficulty;

  const QuizScreen({
    Key? key,
    this.initialDifficulty = DifficultyLevel.intermediate,
  }) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  int score = 0;
  bool hasAnswered = false;
  int? selectedAnswerIndex;
  Timer? _timer;
  int _secondsRemaining = 20;
  bool _timerActive = false;

  // Performance tracking for adaptive difficulty
  List<bool> answersHistory = [];
  DifficultyLevel currentDifficulty = DifficultyLevel.intermediate;
  double playerSkillRating = 1.0; // Range from 0.0 to 2.0 (1.0 is intermediate)

  // Question pools by difficulty
  late List<Question> beginnerQuestions;
  late List<Question> intermediateQuestions;
  late List<Question> advancedQuestions;

  // Active questions for this session
  late List<Question> activeQuestions;

  // Number of questions to include in a quiz
  final int totalQuestionsPerQuiz = 10;

  @override
  void initState() {
    super.initState();
    // Set initial difficulty
    currentDifficulty = widget.initialDifficulty;

    // Initialize question pools
    _initializeQuestionPools();

    // Select initial questions based on difficulty
    _selectQuestionsForDifficulty();

    // Start the timer
    startTimer();
  }

  void _initializeQuestionPools() {
    // Categorize questions by difficulty
    beginnerQuestions = [
      Question(
        questionText: 'What is Google Meet?',
        answers: [
          'A video conferencing platform',
          'A text messaging app',
          'A social media platform',
          'An email service',
        ],
        correctAnswerIndex: 0,
        difficulty: DifficultyLevel.beginner,
      ),
      Question(
        questionText:
            'Which app store is used to install Google Meet on Android phones?',
        answers: ['App Store', 'Play Store', 'Google Store', 'Android Market'],
        correctAnswerIndex: 1,
        difficulty: DifficultyLevel.beginner,
      ),
      Question(
        questionText:
            'What do you tap after installing the app to start using Google Meet?',
        answers: [
          'Your contacts',
          'The calendar',
          'The Google Meet app icon',
          'A text message',
        ],
        correctAnswerIndex: 2,
        difficulty: DifficultyLevel.beginner,
      ),
      Question(
        questionText:
            'What should you do when Google Meet asks for permission to use your microphone and camera?',
        answers: [
          'Tap “Deny”',
          'Tap “While using the app” or “Only this time”',
          'Turn off your phone',
          'Skip it',
        ],
        correctAnswerIndex: 1,
        difficulty: DifficultyLevel.beginner,
      ),
    ];

    intermediateQuestions = [
      Question(
        questionText:
            'How can you create a meeting in Google Meet for a future date?',
        answers: [
          'Click “Join now”',
          'Tap “New Meeting” then choose “Schedule”',
          'Press “Leave Meeting”',
          'Click the red phone icon',
        ],
        correctAnswerIndex: 1,
        difficulty: DifficultyLevel.intermediate,
      ),
      Question(
        questionText:
            'What does the microphone icon with a line through it mean?',
        answers: [
          'You are speaking',
          'Your microphone is on',
          'You are muted',
          'Your phone is ringing',
        ],
        correctAnswerIndex: 2,
        difficulty: DifficultyLevel.intermediate,
      ),
      Question(
        questionText:
            'Which feature should you use if you want to share a Google Meet meeting with others?',
        answers: ['Reactions', 'Record', 'Create link', 'Turn off captions'],
        correctAnswerIndex: 2,
        difficulty: DifficultyLevel.intermediate,
      ),
      Question(
        questionText: 'How do you check if your camera is on during a meeting?',
        answers: [
          'Press the “Join” button',
          'Tap the camera icon and see if you appear on the screen',
          'Leave the meeting',
          'Use live captions',
        ],
        correctAnswerIndex: 1,
        difficulty: DifficultyLevel.intermediate,
      ),
      Question(
        questionText:
            'Why should you check your microphone and camera settings before joining a meeting?',
        answers: [
          'To update your contacts',
          'To play background music',
          'To make sure you can be seen and heard  ',
          'To improve battery life',
        ],
        correctAnswerIndex: 2,
        difficulty: DifficultyLevel.intermediate,
      ),
    ];

    advancedQuestions = [
      Question(
        questionText:
            'What’s the difference between the “Create link” and “Schedule” options in Google Meet?',
        answers: [
          'Create link lets you play a video; Schedule lets you add emojis',
          'Create link is for future meetings; Schedule is for instant meetings',
          'Create link gives an instant code; Schedule sets a future date and time',
          'They do the same thing',
        ],
        correctAnswerIndex: 2,
        difficulty: DifficultyLevel.advanced,
      ),
      Question(
        questionText:
            'When should you use the ‘Group call’ option when starting a new meeting?',
        answers: [
          'When calling just one person',
          'For meetings with more than two people',
          'When watching YouTube',
          'When recording a voice note',
        ],
        correctAnswerIndex: 1,
        difficulty: DifficultyLevel.advanced,
      ),
      Question(
        questionText:
            'What does enabling live captions do in a Google Meet session?',
        answers: [
          'Translates your background',
          'Changes the wallpaper',
          'Shows real-time subtitles',
          'Records the meeting',
        ],
        correctAnswerIndex: 2,
        difficulty: DifficultyLevel.advanced,
      ),
      Question(
        questionText:
            'What is the maximum number of participants allowed in a standard Google Meet call?',
        answers: ['50', '100', '250', '500'],
        correctAnswerIndex: 2,
        difficulty: DifficultyLevel.advanced,
      ),
      Question(
        questionText:
            'Which button should you use if you want to share your screen during a meeting?',
        answers: ['Live Captions', 'Present Screen', 'Reactions', 'End Call'],
        correctAnswerIndex: 1,
        difficulty: DifficultyLevel.advanced,
      ),
    ];

    // Add more questions to each category as needed
  }

  void _selectQuestionsForDifficulty() {
    // Clear current questions
    activeQuestions = [];

    if (currentDifficulty == DifficultyLevel.adaptive) {
      // For adaptive difficulty, start with intermediate questions
      // and adjust as the user progresses
      activeQuestions = List.from(intermediateQuestions);

      // Add some questions from other difficulties based on current skill rating
      if (playerSkillRating < 0.7) {
        // Add more beginner questions for struggling players
        activeQuestions.addAll(beginnerQuestions);
      } else if (playerSkillRating > 1.3) {
        // Add more advanced questions for skilled players
        activeQuestions.addAll(advancedQuestions);
      }

      // Shuffle questions for variety
      activeQuestions.shuffle();

      // Trim to desired length
      if (activeQuestions.length > totalQuestionsPerQuiz) {
        activeQuestions = activeQuestions.sublist(0, totalQuestionsPerQuiz);
      }
    } else {
      // Fixed difficulty modes
      switch (currentDifficulty) {
        case DifficultyLevel.beginner:
          activeQuestions = List.from(beginnerQuestions);
          break;
        case DifficultyLevel.intermediate:
          activeQuestions = List.from(intermediateQuestions);
          break;
        case DifficultyLevel.advanced:
          activeQuestions = List.from(advancedQuestions);
          break;
        default:
          // Fallback to intermediate
          activeQuestions = List.from(intermediateQuestions);
      }

      // Shuffle and ensure we have enough questions
      activeQuestions.shuffle();

      // If we don't have enough questions in the selected difficulty,
      // borrow from adjacent difficulty levels
      while (activeQuestions.length < totalQuestionsPerQuiz) {
        switch (currentDifficulty) {
          case DifficultyLevel.beginner:
            activeQuestions.add(
              intermediateQuestions[activeQuestions.length %
                  intermediateQuestions.length],
            );
            break;
          case DifficultyLevel.intermediate:
            if (activeQuestions.length % 2 == 0) {
              activeQuestions.add(
                beginnerQuestions[activeQuestions.length %
                    beginnerQuestions.length],
              );
            } else {
              activeQuestions.add(
                advancedQuestions[activeQuestions.length %
                    advancedQuestions.length],
              );
            }
            break;
          case DifficultyLevel.advanced:
            activeQuestions.add(
              intermediateQuestions[activeQuestions.length %
                  intermediateQuestions.length],
            );
            break;
          default:
            break;
        }
      }

      // Trim to desired length
      if (activeQuestions.length > totalQuestionsPerQuiz) {
        activeQuestions = activeQuestions.sublist(0, totalQuestionsPerQuiz);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    setState(() {
      // Adjust time based on difficulty
      switch (currentDifficulty) {
        case DifficultyLevel.beginner:
          _secondsRemaining = 30; // More time for beginners
          break;
        case DifficultyLevel.intermediate:
          _secondsRemaining = 20; // Standard time
          break;
        case DifficultyLevel.advanced:
          _secondsRemaining = 15; // Less time for advanced
          break;
        case DifficultyLevel.adaptive:
          // Adjust based on player skill
          _secondsRemaining = (30 - (playerSkillRating * 7.5)).round().clamp(
            10,
            30,
          );
          break;
      }

      _timerActive = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timerActive = false;
          if (!hasAnswered) {
            checkAnswer(-1); // Time's up, count as wrong answer
          }
          timer.cancel();
        }
      });
    });
  }

  void checkAnswer(int selectedIndex) {
    _timer?.cancel();
    final currentQuestion = activeQuestions[currentQuestionIndex];

    setState(() {
      hasAnswered = true;
      selectedAnswerIndex = selectedIndex;

      // Record if answer was correct
      bool isCorrect = selectedIndex == currentQuestion.correctAnswerIndex;
      answersHistory.add(isCorrect);

      if (isCorrect) {
        // Calculate score based on difficulty and time
        int basePoints;
        switch (currentQuestion.difficulty) {
          case DifficultyLevel.beginner:
            basePoints = 75;
            break;
          case DifficultyLevel.intermediate:
            basePoints = 100;
            break;
          case DifficultyLevel.advanced:
            basePoints = 150;
            break;
          default:
            basePoints = 100;
        }

        int timeBonus = _secondsRemaining ~/ 2; // Time bonus
        score += basePoints + timeBonus;

        // Update player skill rating (increase on correct answers)
        if (currentDifficulty == DifficultyLevel.adaptive) {
          playerSkillRating += 0.1;

          // Cap skill rating
          if (playerSkillRating > 2.0) playerSkillRating = 2.0;
        }
      } else {
        // Update player skill rating (decrease on wrong answers)
        if (currentDifficulty == DifficultyLevel.adaptive) {
          playerSkillRating -= 0.15;

          // Ensure skill rating doesn't go below minimum
          if (playerSkillRating < 0.0) playerSkillRating = 0.0;
        }
      }

      _timerActive = false;
    });

    // Wait for 2 seconds before moving to the next question
    Future.delayed(const Duration(seconds: 2), () {
      moveToNextQuestion();
    });
  }

  void moveToNextQuestion() {
    if (currentQuestionIndex < activeQuestions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        hasAnswered = false;
        selectedAnswerIndex = null;

        // For adaptive difficulty, potentially adjust difficulty every 3 questions
        if (currentDifficulty == DifficultyLevel.adaptive &&
            answersHistory.length % 3 == 0 &&
            answersHistory.isNotEmpty) {
          _adjustDifficulty();
        }
      });
      startTimer();
    } else {
      // Quiz completed
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (context) => ResultScreen(
                score: score,
                totalQuestions: activeQuestions.length,
                difficulty: currentDifficulty,
                skillRating: playerSkillRating,
              ),
        ),
      );
    }
  }

  void _adjustDifficulty() {
    // Look at recent performance (last 3 questions)
    int start = answersHistory.length - 3;
    int correctCount = 0;

    for (int i = start; i < answersHistory.length; i++) {
      if (answersHistory[i]) correctCount++;
    }

    // Debug print
    debugPrint(
      'Adaptive: Skill rating = $playerSkillRating, Recent correct: $correctCount/3',
    );

    // No need to change difficulty levels in adaptive mode
    // as we're using the skill rating to select questions and
    // adjust time limits dynamically
  }

  // Show confirmation dialog before exiting quiz
  Future<bool> _onWillPop() async {
    _timer?.cancel(); // Pause the timer while dialog is shown

    bool exitQuiz =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Exit Quiz?'),
                content: const Text(
                  'Are you sure you want to exit? Your progress will be lost.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false); // Don't exit
                    },
                    child: const Text('CANCEL'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true); // Exit quiz
                    },
                    child: const Text('EXIT'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!exitQuiz && _timerActive) {
      // Resume timer if user cancels
      startTimer();
    }

    return exitQuiz;
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = activeQuestions[currentQuestionIndex];

    // Calculate difficulty text
    String difficultyText;
    Color difficultyColor;

    switch (currentQuestion.difficulty) {
      case DifficultyLevel.beginner:
        difficultyText = 'Beginner';
        difficultyColor = Colors.green;
        break;
      case DifficultyLevel.intermediate:
        difficultyText = 'Intermediate';
        difficultyColor = Colors.orange;
        break;
      case DifficultyLevel.advanced:
        difficultyText = 'Advanced';
        difficultyColor = Colors.red;
        break;
      default:
        difficultyText = 'Custom';
        difficultyColor = Colors.purple;
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Question ${currentQuestionIndex + 1}/${activeQuestions.length}',
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _onWillPop().then((exit) {
                if (exit) {
                  Navigator.of(context).pop();
                }
              });
            },
          ),
        ),
        body: Column(
          children: [
            // Progress and Timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.primary,
              child: Column(
                children: [
                  // Progress bar
                  LinearProgressIndicator(
                    value: (currentQuestionIndex + 1) / activeQuestions.length,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),

                  // Display current difficulty and timer in one row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Difficulty indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: difficultyColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          difficultyText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Timer
                      Row(
                        children: [
                          Icon(
                            Icons.timer,
                            color:
                                _secondsRemaining < 5
                                    ? Colors.red
                                    : Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$_secondsRemaining s',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  _secondsRemaining < 5
                                      ? Colors.red
                                      : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Score
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.grey[200],
              width: double.infinity,
              child: Text(
                'Score: $score',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Question
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentQuestion.questionText,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Answer options
                    ...List.generate(
                      currentQuestion.answers.length,
                      (index) => AnswerOption(
                        answer: currentQuestion.answers[index],
                        index: index,
                        isSelected: selectedAnswerIndex == index,
                        isCorrect: index == currentQuestion.correctAnswerIndex,
                        hasAnswered: hasAnswered,
                        onTap: () {
                          if (!hasAnswered) {
                            checkAnswer(index);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Go back to home button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextButton.icon(
                onPressed: () {
                  _onWillPop().then((exit) {
                    if (exit) {
                      context.go('/games');
                    }
                  });
                },
                icon: const Icon(Icons.home),
                label: const Text('Go Back to Home'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnswerOption extends StatelessWidget {
  final String answer;
  final int index;
  final bool isSelected;
  final bool isCorrect;
  final bool hasAnswered;
  final VoidCallback onTap;

  const AnswerOption({
    Key? key,
    required this.answer,
    required this.index,
    required this.isSelected,
    required this.isCorrect,
    required this.hasAnswered,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine color based on selection and correctness
    Color backgroundColor;
    Color textColor = Colors.white;

    if (!hasAnswered) {
      // Not answered yet
      backgroundColor = _getColorForIndex(index);
      textColor = Colors.white;
    } else {
      // Already answered
      if (isCorrect) {
        backgroundColor = Colors.green;
      } else if (isSelected) {
        backgroundColor = Colors.red;
      } else {
        backgroundColor = _getColorForIndex(index).withOpacity(0.6);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    ['A', 'B', 'C', 'D'][index],
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  answer,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (hasAnswered && isCorrect)
                const Icon(Icons.check_circle, color: Colors.white),
              if (hasAnswered && isSelected && !isCorrect)
                const Icon(Icons.close, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForIndex(int index) {
    switch (index) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.red;
      case 2:
        return Colors.green;
      case 3:
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }
}

// Updated Question class to include difficulty level
class Question {
  final String questionText;
  final List<String> answers;
  final int correctAnswerIndex;
  final DifficultyLevel difficulty;

  Question({
    required this.questionText,
    required this.answers,
    required this.correctAnswerIndex,
    this.difficulty = DifficultyLevel.intermediate,
  });
}

// Modified ResultScreen class with Supabase integration, GoRouter and difficulty info
class ResultScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final DifficultyLevel difficulty;
  final double skillRating;

  const ResultScreen({
    Key? key,
    required this.score,
    required this.totalQuestions,
    this.difficulty = DifficultyLevel.intermediate,
    this.skillRating = 1.0,
  }) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  // Supabase client
  final supabase = Supabase.instance.client;
  bool _isSaving = false;
  bool _resultsSaved = false;
  String? _errorMessage;

  int get passThreshold => (widget.totalQuestions * 100 * 0.6).round();
  bool get isPassed => widget.score >= passThreshold;

  String get difficultyText {
    switch (widget.difficulty) {
      case DifficultyLevel.beginner:
        return 'Beginner';
      case DifficultyLevel.intermediate:
        return 'Intermediate';
      case DifficultyLevel.advanced:
        return 'Advanced';
      case DifficultyLevel.adaptive:
        return 'Adaptive';
      default:
        return 'Custom';
    }
  }

  Future<void> _saveResults() async {
    if (_resultsSaved) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // Check if user is authenticated
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'You must be logged in to save results';
          _isSaving = false;
        });
        return;
      }

      // Calculate additional metrics
      final questionsAnswered = widget.totalQuestions;
      final correctAnswers =
          (widget.score / 100).round(); // Approximation based on score
      final averageTimePerQuestion =
          20.0; // Default value - could be tracked precisely in the future

      // Save quiz results to Supabase with correct column names
      await supabase.from('quiz_results').insert({
        'user_id': user.id,
        'platform': 'Google Meet',
        'score': widget.score,
        'max_possible_score': widget.totalQuestions * 100,
        'difficulty': difficultyText,
        'skill_rating': widget.skillRating,
        'passed': isPassed,
        'created_at': DateTime.now().toIso8601String(),
        'questions_answered': questionsAnswered,
        'correct_answers': correctAnswers,
        'average_time_per_question': averageTimePerQuestion,
        'client_info': {'device': 'mobile'},
      });

      // Check for new achievements after saving results
      await _checkAndUnlockAchievements(user.id);

      setState(() {
        _resultsSaved = true;
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save results: ${e.toString()}';
        _isSaving = false;
      });
    }
  }

  Future<void> _checkAndUnlockAchievements(String userId) async {
    try {
      // Get all quiz results for this user
      final results = await supabase
          .from('quiz_results')
          .select('*')
          .eq('user_id', userId)
          .eq('platform', 'Google Meet Quiz');

      final stats = _calculateAchievementStats(results);

      // Get existing achievements for this user
      final existingAchievements = await supabase
          .from('user_achievements')
          .select('achievement_id')
          .eq('user_id', userId);

      final unlockedAchievementIds =
          existingAchievements
              .map<String>((a) => a['achievement_id'] as String)
              .toSet();

      // Define achievement conditions and check each one
      final achievementChecks = [
        {'id': 'first_play', 'condition': stats['gamesPlayed'] >= 1},
        {'id': 'first_pass', 'condition': stats['gamesPassed'] >= 1},
        {'id': 'five_plays', 'condition': stats['gamesPlayed'] >= 5},
        {'id': 'five_passes', 'condition': stats['gamesPassed'] >= 5},
        {'id': 'high_score', 'condition': stats['highestScore'] >= 800},
        {'id': 'perfect_score', 'condition': stats['highestScore'] >= 1000},
        {
          'id': 'speed_demon',
          'condition':
              stats['fastestAverageTime'] > 0 &&
              stats['fastestAverageTime'] < 5,
        },
        {
          'id': 'difficulty_master',
          'condition': stats['difficultiesCompleted'] >= 3,
        },
        {
          'id': 'consistent_player',
          'condition': stats['uniqueDaysPlayed'] >= 7,
        },
        {'id': 'adaptive_ace', 'condition': stats['highestSkillRating'] >= 1.8},
      ];

      // Check each achievement and unlock if conditions are met
      List<String> newlyUnlocked = [];

      for (final check in achievementChecks) {
        final achievementId = check['id'] as String;
        final condition = check['condition'] as bool;

        if (condition && !unlockedAchievementIds.contains(achievementId)) {
          // Unlock this achievement
          await supabase.from('user_achievements').insert({
            'user_id': userId,
            'achievement_id': achievementId,
            'unlocked_at': DateTime.now().toIso8601String(),
            'game_platform': 'Google Meet Quiz',
          });

          newlyUnlocked.add(achievementId);
        }
      }

      // Show notification for newly unlocked achievements
      if (newlyUnlocked.isNotEmpty && mounted) {
        _showAchievementNotification(newlyUnlocked);
      }
    } catch (e) {
      debugPrint('Error checking achievements: $e');
      // Don't throw error here as it's secondary to saving results
    }
  }

  // Calculate stats for achievement checking
  Map<String, dynamic> _calculateAchievementStats(List<dynamic> results) {
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

    // Calculate fastest average time
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

  // Show achievement notification
  void _showAchievementNotification(List<String> newAchievements) {
    final achievementTitles = {
      'first_play': 'First Steps!',
      'first_pass': 'Getting the Hang of It!',
      'five_plays': 'Dedicated Learner!',
      'five_passes': 'Meet Master!',
      'high_score': 'Score Champion!',
      'perfect_score': 'Perfect Performance!',
      'speed_demon': 'Speed Demon!',
      'difficulty_master': 'Difficulty Master!',
      'consistent_player': 'Consistent Player!',
      'adaptive_ace': 'Adaptive Ace!',
    };

    if (newAchievements.length == 1) {
      final title =
          achievementTitles[newAchievements.first] ?? 'Achievement Unlocked!';

      showDialog(
        context: context,
        builder:
            (context) => AchievementDialog(
              title: title,
              description: 'You\'ve unlocked a new achievement!',
            ),
      );
    } else {
      showDialog(
        context: context,
        builder:
            (context) => AchievementDialog(
              title: 'Multiple Achievements!',
              description:
                  'You\'ve unlocked ${newAchievements.length} new achievements!',
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isPassed
                  ? Theme.of(context).colorScheme.secondary
                  : Colors.orange,
              Theme.of(context).colorScheme.primary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top section with result icon and text
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPassed ? Icons.emoji_events : Icons.refresh,
                      size: 100,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isPassed ? 'Quiz Completed!' : 'Try Again!',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPassed
                          ? 'Great job mastering Google Meet!'
                          : 'Keep practicing to improve your score',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Result card
              Expanded(
                flex: 4,
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Score circle
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isPassed ? Colors.green[50] : Colors.orange[50],
                          border: Border.all(
                            color: isPassed ? Colors.green : Colors.orange,
                            width: 3,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${widget.score}',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: isPassed ? Colors.green : Colors.orange,
                              ),
                            ),
                            Text(
                              'points',
                              style: TextStyle(
                                fontSize: 16,
                                color: isPassed ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Difficulty info
                      Text(
                        'Difficulty: $difficultyText',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Show skill rating for adaptive mode
                      if (widget.difficulty == DifficultyLevel.adaptive)
                        Column(
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              'Skill Rating: ${widget.skillRating.toStringAsFixed(1)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),

                      // Save results button (if user is logged in)
                      if (supabase.auth.currentUser != null && !_resultsSaved)
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveResults,
                          icon:
                              _isSaving
                                  ? Container(
                                    width: 24,
                                    height: 24,
                                    padding: const EdgeInsets.all(2.0),
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                  : const Icon(Icons.save),
                          label: Text(_isSaving ? 'Saving...' : 'Save Results'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),

                      // Show success message when results are saved
                      if (_resultsSaved)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'Results saved!',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                      // Show error message if saving failed
                      if (_errorMessage != null)
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom buttons
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Go to home button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.go('/games');
                        },
                        icon: const Icon(Icons.home),
                        label: const Text('Home'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Try again button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder:
                                  (context) => QuizScreen(
                                    initialDifficulty: widget.difficulty,
                                  ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Add these additional helper classes and extensions as needed

// Extension to help with adaptive difficulty calculations
extension DifficultyHelpers on DifficultyLevel {
  // Convert difficulty level to numeric value for calculations
  double get numericValue {
    switch (this) {
      case DifficultyLevel.beginner:
        return 0.0;
      case DifficultyLevel.intermediate:
        return 1.0;
      case DifficultyLevel.advanced:
        return 2.0;
      case DifficultyLevel.adaptive:
        return 1.0; // Default to intermediate for adaptive
    }
  }

  // Get recommended time limit based on difficulty
  int get recommendedTimeLimit {
    switch (this) {
      case DifficultyLevel.beginner:
        return 30;
      case DifficultyLevel.intermediate:
        return 20;
      case DifficultyLevel.advanced:
        return 15;
      case DifficultyLevel.adaptive:
        return 20; // Default, will be adjusted based on skill
    }
  }
}

// Class to track player performance analytics
class PlayerAnalytics {
  final List<bool> answersHistory;
  final List<int> timeToAnswer;
  final DifficultyLevel startingDifficulty;
  double skillRating;

  PlayerAnalytics({required this.startingDifficulty, this.skillRating = 1.0})
    : answersHistory = [],
      timeToAnswer = [];

  void recordAnswer(bool correct, int timeSpent) {
    answersHistory.add(correct);
    timeToAnswer.add(timeSpent);

    // Update skill rating based on answer and time
    if (correct) {
      // Faster correct answers give bigger skill boost
      double timeBonus = 1.0 - (timeSpent / 30.0).clamp(0.0, 0.9);
      skillRating += 0.1 + (timeBonus * 0.1);
    } else {
      skillRating -= 0.15;
    }

    // Keep skill rating within bounds
    skillRating = skillRating.clamp(0.0, 2.0);
  }

  double get averageTimeToAnswer {
    if (timeToAnswer.isEmpty) return 0;
    return timeToAnswer.reduce((a, b) => a + b) / timeToAnswer.length;
  }

  double get correctAnswerRate {
    if (answersHistory.isEmpty) return 0;
    return answersHistory.where((answer) => answer).length /
        answersHistory.length;
  }

  // Recommend next difficulty based on performance
  DifficultyLevel get recommendedDifficulty {
    if (answersHistory.length < 5) return startingDifficulty;

    if (skillRating > 1.5) {
      return DifficultyLevel.advanced;
    } else if (skillRating < 0.5) {
      return DifficultyLevel.beginner;
    } else {
      return DifficultyLevel.intermediate;
    }
  }
}

// Achievement notification dialog
class AchievementDialog extends StatelessWidget {
  final String title;
  final String description;

  const AchievementDialog({
    Key? key,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.amber[100]!, Colors.orange[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Achievement icon with animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20), // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              description,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Close button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Awesome!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Additional helper method to get achievement descriptions for the profile screen
Map<String, Map<String, String>> getAchievementDefinitions() {
  return {
    'first_play': {
      'title': 'First Steps!',
      'description': 'Complete your first Google Meet quiz',
      'icon': '🎯',
    },
    'first_pass': {
      'title': 'Getting the Hang of It!',
      'description': 'Pass your first Google Meet quiz',
      'icon': '✅',
    },
    'five_plays': {
      'title': 'Dedicated Learner!',
      'description': 'Complete 5 Google Meet quizzes',
      'icon': '📚',
    },
    'five_passes': {
      'title': 'Meet Master!',
      'description': 'Pass 5 Google Meet quizzes',
      'icon': '🏆',
    },
    'high_score': {
      'title': 'Score Champion!',
      'description': 'Achieve a score of 800 or higher',
      'icon': '⭐',
    },
    'perfect_score': {
      'title': 'Perfect Performance!',
      'description': 'Achieve a perfect score of 1000',
      'icon': '💎',
    },
    'speed_demon': {
      'title': 'Speed Demon!',
      'description': 'Answer questions in under 5 seconds on average',
      'icon': '⚡',
    },
    'difficulty_master': {
      'title': 'Difficulty Master!',
      'description': 'Pass quizzes on 3 different difficulty levels',
      'icon': '🎖️',
    },
    'consistent_player': {
      'title': 'Consistent Player!',
      'description': 'Play on 7 different days',
      'icon': '📅',
    },
    'adaptive_ace': {
      'title': 'Adaptive Ace!',
      'description': 'Reach a skill rating of 1.8 or higher',
      'icon': '🧠',
    },
  };
}
