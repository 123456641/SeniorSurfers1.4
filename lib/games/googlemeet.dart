import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

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
      home: const WelcomeScreen(),
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
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const QuizScreen()),
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
                child: const Text('Start Quiz'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

      if (selectedIndex == questions[currentQuestionIndex].correctAnswerIndex) {
        int timeBonus = _secondsRemaining ~/ 2; // Time bonus
        score += 100 + timeBonus;
      }
      _timerActive = false;
    });

    // Wait for 2 seconds before moving to the next question
    Future.delayed(const Duration(seconds: 2), () {
      moveToNextQuestion();
    });
  }

  void moveToNextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
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
              (context) =>
                  ResultScreen(score: score, totalQuestions: questions.length),
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

  @override
  Widget build(BuildContext context) {
    final currentQuestion = questions[currentQuestionIndex];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Question ${currentQuestionIndex + 1}/${questions.length}',
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
                    value: (currentQuestionIndex + 1) / questions.length,
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

class ResultScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;

  const ResultScreen({
    Key? key,
    required this.score,
    required this.totalQuestions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate performance
    final int maxPossibleScore = totalQuestions * 100;
    final double percentage = (score / maxPossibleScore) * 100;
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
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
              (route) => false,
            );
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Quiz Completed!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
                      score.toString(),
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
              const SizedBox(height: 30),
              Text(
                feedback,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: feedbackColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${percentage.toStringAsFixed(1)}% correct',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const WelcomeScreen(),
                    ),
                    (route) => false,
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Play Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Quiz questions
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

// List of questions for the quiz
final List<Question> questions = [
  Question(
    questionText: 'What is Google Meet?',
    answers: [
      'A video conferencing platform',
      'A text messaging app',
      'A social media platform',
      'An email service',
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText:
        'Which app store is used to install Google Meet on Android phones?',
    answers: ['App Store', 'Play Store', 'Google Store', 'Android Market'],
    correctAnswerIndex: 1,
  ),
  Question(
    questionText:
        'What permission(s) might Google Meet ask for when joining a meeting?',
    answers: [
      'Location only',
      'Contacts only',
      'Camera and microphone',
      'Storage access',
    ],
    correctAnswerIndex: 2,
  ),
  Question(
    questionText: 'How do you join a Google Meet meeting?',
    answers: [
      'Enter a meeting code manually',
      'Click on the meeting link',
      'Receive an automatic invite',
      'Call a specific phone number',
    ],
    correctAnswerIndex: 1,
  ),
  Question(
    questionText: 'What is the first step to create a meeting in Google Meet?',
    answers: [
      'Open the Google Meet app',
      'Send an email invitation',
      'Create a calendar event',
      'Share your screen',
    ],
    correctAnswerIndex: 0,
  ),
  Question(
    questionText:
        'Which of these is NOT an option when creating a new meeting?',
    answers: ['Create link', 'Schedule', 'Group call', 'Private chat'],
    correctAnswerIndex: 3,
  ),
  Question(
    questionText:
        'What option would you choose to set up a meeting for a future date and time?',
    answers: ['Create link', 'Schedule', 'Group call', 'Join meeting'],
    correctAnswerIndex: 1,
  ),
  Question(
    questionText:
        'What feature of Google Meet enables users to see spoken words as text?',
    answers: [
      'Voice recognition',
      'Text translation',
      'Live captions',
      'Audio transcription',
    ],
    correctAnswerIndex: 2,
  ),
  Question(
    questionText: 'What format does a Google Meet link typically follow?',
    answers: [
      'meet.com/abc-def-ghi',
      'googlemeet.com/123-456',
      'meet.google.com/abc-def-ghi',
      'google.com/meet/123',
    ],
    correctAnswerIndex: 2,
  ),
  Question(
    questionText: 'Which Google service is Google Meet integrated with?',
    answers: ['Google Maps', 'Google Photos', 'Google Pay', 'Google Workspace'],
    correctAnswerIndex: 3,
  ),
];
