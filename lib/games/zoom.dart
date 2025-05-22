import 'package:flutter/material.dart';
import 'dart:async';
import '../games_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ZoomQuizGame extends StatelessWidget {
  const ZoomQuizGame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zoom Quiz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D8CFF), // Zoom Blue
          primary: const Color(0xFF2D8CFF),
          secondary: const Color(0xFF0E71EB), // Zoom Dark Blue
          background: Colors.white,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF232333),
          ),
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF232333)),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/difficulty': (context) => const DifficultySelectionScreen(),
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
                Icons.videocam_rounded,
                size: 120,
                color: Colors.white,
              ),
              const SizedBox(height: 40),
              const Text(
                'Zoom',
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
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/difficulty');
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
                child: const Text('Start Quiz'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/games');
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
}

class DifficultySelectionScreen extends StatelessWidget {
  const DifficultySelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Difficulty'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Choose Your Challenge Level',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF232333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              DifficultyCard(
                title: 'Beginner',
                description: 'Basic Zoom features and functions',
                icon: Icons.school,
                color: Colors.green,
                onTap: () => _navigateToQuiz(context, QuizDifficulty.beginner),
              ),
              const SizedBox(height: 16),
              DifficultyCard(
                title: 'Intermediate',
                description: 'Moderately challenging Zoom knowledge',
                icon: Icons.trending_up,
                color: Colors.blue,
                onTap:
                    () => _navigateToQuiz(context, QuizDifficulty.intermediate),
              ),
              const SizedBox(height: 16),
              DifficultyCard(
                title: 'Advanced',
                description: 'Complex Zoom features and best practices',
                icon: Icons.star,
                color: Colors.red,
                onTap: () => _navigateToQuiz(context, QuizDifficulty.advanced),
              ),
              const SizedBox(height: 16),
              DifficultyCard(
                title: 'Adaptive',
                description: 'Questions adjust based on your performance',
                icon: Icons.psychology,
                color: Colors.purple,
                onTap: () => _navigateToQuiz(context, QuizDifficulty.adaptive),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToQuiz(BuildContext context, QuizDifficulty difficulty) {
    Navigator.pushNamed(context, '/quiz', arguments: difficulty);
  }
}

class DifficultyCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const DifficultyCard({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

enum QuizDifficulty { beginner, intermediate, advanced, adaptive }

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

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
  QuizDifficulty difficulty = QuizDifficulty.beginner;
  List<Question> currentQuestions = [];

  // Adaptive quiz variables
  int consecutiveCorrect = 0;
  int consecutiveWrong = 0;
  QuizDifficulty adaptiveLevel = QuizDifficulty.beginner;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as QuizDifficulty?;
      if (args != null) {
        setState(() {
          difficulty = args;
          if (difficulty == QuizDifficulty.adaptive) {
            adaptiveLevel = QuizDifficulty.beginner;
          }
          _loadQuestions();
        });
        startTimer();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadQuestions() {
    switch (difficulty == QuizDifficulty.adaptive
        ? adaptiveLevel
        : difficulty) {
      case QuizDifficulty.beginner:
        currentQuestions = beginnerQuestions;
        break;
      case QuizDifficulty.intermediate:
        currentQuestions = intermediateQuestions;
        break;
      case QuizDifficulty.advanced:
        currentQuestions = advancedQuestions;
        break;
      case QuizDifficulty.adaptive:
        currentQuestions = beginnerQuestions;
        break;
    }
  }

  void startTimer() {
    setState(() {
      _secondsRemaining = 20;
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
    setState(() {
      hasAnswered = true;
      selectedAnswerIndex = selectedIndex;

      bool isCorrect =
          selectedIndex ==
          currentQuestions[currentQuestionIndex].correctAnswerIndex;

      if (isCorrect) {
        int timeBonus = _secondsRemaining ~/ 2; // Time bonus
        score += 100 + timeBonus;

        if (difficulty == QuizDifficulty.adaptive) {
          consecutiveCorrect++;
          consecutiveWrong = 0;
          _adjustAdaptiveDifficulty();
        }
      } else {
        if (difficulty == QuizDifficulty.adaptive) {
          consecutiveWrong++;
          consecutiveCorrect = 0;
          _adjustAdaptiveDifficulty();
        }
      }
      _timerActive = false;
    });

    // Wait for 2 seconds before moving to the next question
    Future.delayed(const Duration(seconds: 2), () {
      moveToNextQuestion();
    });
  }

  void _adjustAdaptiveDifficulty() {
    QuizDifficulty newLevel = adaptiveLevel;

    if (consecutiveCorrect >= 3 && adaptiveLevel != QuizDifficulty.advanced) {
      // Increase difficulty
      switch (adaptiveLevel) {
        case QuizDifficulty.beginner:
          newLevel = QuizDifficulty.intermediate;
          break;
        case QuizDifficulty.intermediate:
          newLevel = QuizDifficulty.advanced;
          break;
        case QuizDifficulty.advanced:
          break;
        case QuizDifficulty.adaptive:
          break;
      }
    } else if (consecutiveWrong >= 2 &&
        adaptiveLevel != QuizDifficulty.beginner) {
      // Decrease difficulty
      switch (adaptiveLevel) {
        case QuizDifficulty.advanced:
          newLevel = QuizDifficulty.intermediate;
          break;
        case QuizDifficulty.intermediate:
          newLevel = QuizDifficulty.beginner;
          break;
        case QuizDifficulty.beginner:
          break;
        case QuizDifficulty.adaptive:
          break;
      }
    }

    if (newLevel != adaptiveLevel) {
      setState(() {
        adaptiveLevel = newLevel;
        _loadQuestions();
        consecutiveCorrect = 0;
        consecutiveWrong = 0;
      });
    }
  }

  void moveToNextQuestion() {
    if (currentQuestionIndex < currentQuestions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        hasAnswered = false;
        selectedAnswerIndex = null;
      });
      startTimer();
    } else {
      // Quiz completed
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (context) => ResultScreen(
                score: score,
                totalQuestions: currentQuestions.length,
                difficulty: difficulty,
              ),
        ),
      );
    }
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

  String _getDifficultyDisplayName() {
    if (difficulty == QuizDifficulty.adaptive) {
      switch (adaptiveLevel) {
        case QuizDifficulty.beginner:
          return 'Adaptive (Beginner)';
        case QuizDifficulty.intermediate:
          return 'Adaptive (Intermediate)';
        case QuizDifficulty.advanced:
          return 'Adaptive (Advanced)';
        case QuizDifficulty.adaptive:
          return 'Adaptive';
      }
    } else {
      switch (difficulty) {
        case QuizDifficulty.beginner:
          return 'Beginner';
        case QuizDifficulty.intermediate:
          return 'Intermediate';
        case QuizDifficulty.advanced:
          return 'Advanced';
        case QuizDifficulty.adaptive:
          return 'Adaptive';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentQuestions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentQuestion = currentQuestions[currentQuestionIndex];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              Text(
                'Question ${currentQuestionIndex + 1}/${currentQuestions.length}',
              ),
              Text(
                _getDifficultyDisplayName(),
                style: const TextStyle(fontSize: 12),
              ),
            ],
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
                    value: (currentQuestionIndex + 1) / currentQuestions.length,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  // Timer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer,
                        color:
                            _secondsRemaining < 5 ? Colors.red : Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_secondsRemaining s',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              _secondsRemaining < 5 ? Colors.red : Colors.white,
                        ),
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
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/', (route) => false);
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
        return const Color(0xFF2D8CFF); // Zoom Blue
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

// Result Screen with Supabase integration
class ResultScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final QuizDifficulty difficulty;

  const ResultScreen({
    Key? key,
    required this.score,
    required this.totalQuestions,
    required this.difficulty,
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

  @override
  void initState() {
    super.initState();
    // Save results when screen loads
    saveQuizResults();
  }

  String _getDifficultyString() {
    switch (widget.difficulty) {
      case QuizDifficulty.beginner:
        return 'Beginner';
      case QuizDifficulty.intermediate:
        return 'Intermediate';
      case QuizDifficulty.advanced:
        return 'Advanced';
      case QuizDifficulty.adaptive:
        return 'Adaptive';
    }
  }

  // Function to save quiz results to Supabase
  Future<void> saveQuizResults() async {
    // Only save if results haven't been saved yet
    if (_resultsSaved) return;

    try {
      setState(() {
        _isSaving = true;
        _errorMessage = null;
      });

      // Get current user
      final currentUser = supabase.auth.currentUser;

      if (currentUser == null) {
        setState(() {
          _errorMessage = 'User not logged in';
          _isSaving = false;
        });
        return;
      }

      // Calculate max possible score
      final int maxPossibleScore = widget.totalQuestions * 100;

      // Insert quiz result
      await supabase.from('quiz_results').insert({
        'user_id': currentUser.id,
        'platform': 'Zoom', // Hardcoded for this specific quiz
        'difficulty': _getDifficultyString(),
        'score': widget.score,
        'max_possible_score': maxPossibleScore,
        'passed': isPassed,
      });

      setState(() {
        _resultsSaved = true;
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save results: ${e.toString()}';
        _isSaving = false;
      });
      debugPrint('Error saving quiz results: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate performance
    final int maxPossibleScore = widget.totalQuestions * 100;
    final double percentage = (widget.score / maxPossibleScore) * 100;
    String feedback;
    Color feedbackColor;

    if (percentage >= 80) {
      feedback = 'Excellent!';
      feedbackColor = Colors.green;
    } else if (percentage >= 60) {
      feedback = 'Good job!';
      feedbackColor = Colors.blue;
    } else if (percentage >= 40) {
      feedback = 'Not bad!';
      feedbackColor = Colors.orange;
    } else {
      feedback = 'Keep practicing!';
      feedbackColor = Colors.red;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home),
          color: Colors.white,
          onPressed: () {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (route) => false);
          },
        ),
      ),
      extendBodyBehindAppBar: true,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60), // Space for app bar
                Text(
                  isPassed ? 'You Passed!' : 'Quiz Completed',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${_getDifficultyString()} Level',
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 20),
                // Pass/Fail message
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: isPassed ? Colors.green : Colors.red.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPassed
                        ? 'You have passed! Click below to learn a new tutorial.'
                        : 'You need more practice. Return to tutorial or try again.',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 30),
                CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.score.toString(),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        'points',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  feedback,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: feedbackColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 30),
                // Saving status
                if (_isSaving)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Saving results...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                if (_resultsSaved)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Results saved!',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 30),
                // Action buttons
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/difficulty', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Try Again'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/games', (route) => false);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('Back to Games'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Question model
class Question {
  final String questionText;
  final List<String> answers;
  final int correctAnswerIndex;

  Question({
    required this.questionText,
    required this.answers,
    required this.correctAnswerIndex,
  });
}

// Beginner level questions
final List<Question> beginnerQuestions = [
  Question(
    questionText: "What is the primary purpose of Zoom?",
    answers: [
      "Video conferencing and communication",
      "File storage",
      "Photo editing",
      "Gaming",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText: "How do you join a Zoom meeting?",
    answers: [
      "Click on the meeting link or enter Meeting ID",
      "Send an email",
      "Call the host",
      "Download a file",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText: "What does the mute button do in Zoom?",
    answers: [
      "Turns off your microphone",
      "Turns off your camera",
      "Ends the meeting",
      "Changes your background",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText: "Where can you find the chat feature in Zoom?",
    answers: [
      "In the bottom toolbar during a meeting",
      "In the top menu",
      "Only available to hosts",
      "In the settings menu",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText: "What is a Zoom Meeting ID?",
    answers: [
      "A unique number to identify a meeting",
      "Your user password",
      "The meeting duration",
      "The number of participants",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText: "How do you turn on your camera in Zoom?",
    answers: [
      "Click the video button in the toolbar",
      "Press the spacebar",
      "Type in chat",
      "Click your name",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText: "What does 'Share Screen' allow you to do?",
    answers: [
      "Show your computer screen to other participants",
      "Take a screenshot",
      "Save the meeting",
      "Record the meeting",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText: "How can you change your display name in a Zoom meeting?",
    answers: [
      "Right-click on your video and select 'Rename'",
      "Type in the chat",
      "Ask the host to change it",
      "It cannot be changed during a meeting",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText:
        "What is the maximum number of participants in a basic Zoom account?",
    answers: [
      "100 participants",
      "50 participants",
      "200 participants",
      "Unlimited",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText:
        "How long can a basic Zoom meeting last with multiple participants?",
    answers: ["40 minutes", "60 minutes", "2 hours", "Unlimited time"],
    correctAnswerIndex: 0,
  ),
];

// Intermediate level questions
final List<Question> intermediateQuestions = [
  Question(
    questionText: "What is a Zoom Waiting Room?",
    answers: [
      "A feature that allows hosts to control when participants join",
      "A virtual background option",
      "A chat room before the meeting",
      "A recording storage area",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText: "How can you create breakout rooms in Zoom?",
    answers: [
      "Host must enable and assign participants to separate rooms",
      "Participants can create them automatically",
      "Only available in mobile apps",
      "Through the chat feature",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText:
        "What is the difference between 'Mute All' and 'Mute Upon Entry'?",
    answers: [
      "'Mute All' mutes current participants, 'Mute Upon Entry' mutes future joiners",
      "They are the same feature",
      "'Mute All' is permanent, 'Mute Upon Entry' is temporary",
      "Only hosts can use 'Mute All'",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText: "What keyboard shortcut mutes/unmutes you in Zoom?",
    answers: [
      "Alt+A (Windows) or Cmd+Shift+A (Mac)",
      "Ctrl+M",
      "Spacebar",
      "Alt+M",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText: "How can you enable virtual backgrounds in Zoom?",
    answers: [
      "Go to Settings > Virtual Background",
      "Click on your video during a meeting",
      "Use the chat commands",
      "Only available for premium accounts",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText: "What is Zoom's 'Spotlight Video' feature?",
    answers: [
      "Makes one person's video the main focus for all participants",
      "Adds special lighting effects",
      "Records only that person's video",
      "Increases video quality",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText: "How can participants raise their hand in Zoom?",
    answers: [
      "Click the 'Raise Hand' button in the Reactions menu",
      "Type 'raise hand' in chat",
      "Wave at the camera",
      "Press the spacebar twice",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText: "What is the purpose of Zoom's 'Polling' feature?",
    answers: [
      "To conduct surveys and get real-time feedback from participants",
      "To schedule future meetings",
      "To share files with participants",
      "To control participant permissions",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText:
        "How can you share only a specific application window instead of your entire screen?",
    answers: [
      "Select 'Application Window' when clicking Share Screen",
      "Minimize other applications first",
      "Use Alt+Tab before sharing",
      "This feature is not available",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText: "What is Zoom's 'Co-host' feature?",
    answers: [
      "Allows another participant to have host-like privileges",
      "Enables dual camera setup",
      "Shares hosting costs",
      "Creates a backup recording",
    ],
    correctAnswerIndex: 0,
  ),
];

// Advanced level questions
final List<Question> advancedQuestions = [
  Question(
    questionText: "What is Zoom's API and what can it be used for?",
    answers: [
      "Application Programming Interface for integrating Zoom into other applications",
      "A mobile app version",
      "An advanced camera feature",
      "A security protocol",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText: "How does Zoom's end-to-end encryption work?",
    answers: [
      "Encrypts communication between participants, only they can decrypt it",
      "Stores all data on secure servers",
      "Uses password protection only",
      "Available only for premium accounts",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText:
        "What is Zoom Phone and how does it integrate with Zoom Meetings?",
    answers: [
      "A cloud-based phone system that integrates with video conferencing",
      "A mobile app for phone calls only",
      "A hardware device for better audio",
      "A contact management system",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText:
        "What are Zoom Webinars and how do they differ from regular meetings?",
    answers: [
      "Large-scale events with view-only attendees and interactive hosts/panelists",
      "Meetings recorded automatically",
      "Meetings with premium video quality",
      "Private meetings with encryption",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText: "How does Zoom's Load Balancing work in large deployments?",
    answers: [
      "Distributes traffic across multiple data centers for optimal performance",
      "Balances audio and video quality",
      "Manages participant entry timing",
      "Controls bandwidth usage per user",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText: "What is Zoom's SDK and what platforms does it support?",
    answers: [
      "Software Development Kit for iOS, Android, Windows, macOS, and Web",
      "A security diagnostic kit",
      "A screen sharing development tool",
      "A mobile-only development platform",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText:
        "How can administrators manage Zoom settings organization-wide?",
    answers: [
      "Through the Zoom Admin Portal with centralized policy management",
      "Individual user settings only",
      "Through email notifications",
      "Via mobile device management only",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText: "What is Zoom's HIPAA compliance feature and who can use it?",
    answers: [
      "Healthcare-specific security controls for covered entities",
      "Available to all users automatically",
      "Only for government organizations",
      "A premium audio feature",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText:
        "How does Zoom's Cloud Recording differ from Local Recording in terms of processing and storage?",
    answers: [
      "Cloud recording processes in Zoom's servers with unlimited storage options",
      "Cloud recording has lower quality than local",
      "Local recording uploads automatically to cloud",
      "They are identical in functionality",
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText:
        "What advanced authentication methods does Zoom support for enterprise security?",
    answers: [
      "SAML, OAuth, LDAP integration, and two-factor authentication",
      "Password protection only",
      "Biometric authentication exclusively",
      "Social media login integration",
    ],
    correctAnswerIndex: 0,
  ),
];
