// File: lib/services/onboarding_service.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingService {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  OverlayEntry? _overlayEntry;
  int _currentStep = 0;
  bool _isOnboardingActive = false;
  BuildContext? _context;

  final List<OnboardingStepData> _onboardingSteps = [
    OnboardingStepData(
      title: "Welcome to Senior Surfers! 🌊",
      description:
          "Let's take a quick tour to help you get started. This will make everything much easier to use!",
      route: '/home1',
      isIntro: true,
    ),
    OnboardingStepData(
      title: "Your Home Base 🏠",
      description:
          "This is your home page where you can see everything at a glance. You can always return here by tapping the Home button.",
      route: '/home1',
    ),
    OnboardingStepData(
      title: "Learn Step by Step 📚",
      description:
          "Tutorials teach you new technology skills with easy-to-follow instructions. Perfect for beginners!",
      route: '/tutorials',
    ),
    OnboardingStepData(
      title: "Practice Makes Perfect 💪",
      description:
          "Practice lets you try what you've learned in a safe environment. No pressure, just practice!",
      route: '/practice',
    ),
    OnboardingStepData(
      title: "Fun Learning Games 🎮",
      description:
          "Games make learning fun! Play simple games that help you remember what you've learned.",
      route: '/games',
    ),
    OnboardingStepData(
      title: "Connect with Others 👥",
      description:
          "Community is where you can ask questions and share experiences with other learners just like you.",
      route: '/community',
    ),
    OnboardingStepData(
      title: "Tech Dictionary 📖",
      description:
          "Don't know what a word means? The Tech Glossary explains technology terms in simple language.",
      route: '/techglossary',
    ),
    OnboardingStepData(
      title: "Track Your Progress 🏆",
      description:
          "See your achievements and celebrate your learning milestones!",
      route: '/achievements',
    ),
    OnboardingStepData(
      title: "Customize Your Experience ⚙️",
      description:
          "Adjust settings to make the app work better for you - bigger text, different colors, and more!",
      route: '/settingsD',
    ),
    OnboardingStepData(
      title: "You're All Set! 🎉",
      description:
          "Great job! You now know how to navigate Senior Surfers. You can replay this tour anytime from Settings. Happy learning!",
      route: '/home1',
      isOutro: true,
    ),
  ];

  // Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;

      final response =
          await Supabase.instance.client
              .from('profiles')
              .select('onboarding_complete')
              .eq('id', user.id)
              .single();

      return response['onboarding_complete'] ?? false;
    } catch (e) {
      print('Error checking onboarding status: $e');
      return false;
    }
  }

  // Mark onboarding as complete
  Future<void> markOnboardingComplete() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client
          .from('profiles')
          .update({'onboarding_complete': true})
          .eq('id', user.id);
    } catch (e) {
      print('Error marking onboarding complete: $e');
    }
  }

  // Start onboarding
  Future<void> startOnboarding(BuildContext context) async {
    if (_isOnboardingActive) return;

    final hasCompleted = await hasCompletedOnboarding();
    if (hasCompleted) return;

    _context = context;
    _currentStep = 0;
    _isOnboardingActive = true;
    _showCurrentStep();
  }

  // Restart onboarding (for help/tour button)
  void restartOnboarding(BuildContext context) {
    _context = context;
    _currentStep = 0;
    _isOnboardingActive = true;
    _showCurrentStep();
  }

  void _showCurrentStep() {
    if (_context == null || _currentStep >= _onboardingSteps.length) return;

    final step = _onboardingSteps[_currentStep];

    // Navigate to the step's route if it's not intro/outro
    if (!step.isIntro && !step.isOutro && _context!.mounted) {
      _context!.go(step.route);
    }

    // Small delay to ensure navigation completes
    Future.delayed(const Duration(milliseconds: 300), () {
      _showOverlay();
    });
  }

  void _showOverlay() {
    _removeOverlay();

    if (_context == null) return;

    _overlayEntry = OverlayEntry(
      builder:
          (context) => OnboardingOverlayWidget(
            step: _onboardingSteps[_currentStep],
            stepNumber: _currentStep + 1,
            totalSteps: _onboardingSteps.length,
            onNext: _nextStep,
            onSkip: _skipOnboarding,
            onPrevious: _currentStep > 0 ? _previousStep : null,
          ),
    );

    Overlay.of(_context!).insert(_overlayEntry!);
  }

  void _nextStep() {
    if (_currentStep < _onboardingSteps.length - 1) {
      _currentStep++;
      _showCurrentStep();
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      _showCurrentStep();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  void _completeOnboarding() async {
    await markOnboardingComplete();
    _removeOverlay();
    _isOnboardingActive = false;
    _currentStep = 0;

    // Navigate back to home
    if (_context != null && _context!.mounted) {
      _context!.go('/home1');
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void dispose() {
    _removeOverlay();
    _isOnboardingActive = false;
  }
}

// Onboarding Step Data Model
class OnboardingStepData {
  final String title;
  final String description;
  final String route;
  final bool isIntro;
  final bool isOutro;

  OnboardingStepData({
    required this.title,
    required this.description,
    required this.route,
    this.isIntro = false,
    this.isOutro = false,
  });
}

// Onboarding Overlay Widget
class OnboardingOverlayWidget extends StatelessWidget {
  final OnboardingStepData step;
  final int stepNumber;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback? onPrevious;

  const OnboardingOverlayWidget({
    super.key,
    required this.step,
    required this.stepNumber,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
    this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.75),
      child: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 400),
            child: _buildTooltipContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildTooltipContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          Row(
            children: [
              Text(
                'Step $stepNumber of $totalSteps',
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF27445D),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF27445D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${(stepNumber / totalSteps * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF27445D),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF27445D),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            step.description,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // Buttons
          Row(
            children: [
              if (onPrevious != null) ...[
                TextButton(
                  onPressed: onPrevious,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(fontSize: 18, color: Color(0xFF27445D)),
                  ),
                ),
                const SizedBox(width: 16),
              ],

              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'Skip Tour',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27445D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  stepNumber == totalSteps ? 'Finish' : 'Next',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Mixin to easily add onboarding to any page
mixin OnboardingMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    _checkAndStartOnboarding();
  }

  void _checkAndStartOnboarding() async {
    // Small delay to ensure widgets are built
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      final onboardingService = OnboardingService();
      final hasCompleted = await onboardingService.hasCompletedOnboarding();

      if (!hasCompleted) {
        onboardingService.startOnboarding(context);
      }
    }
  }

  void restartOnboarding() {
    OnboardingService().restartOnboarding(context);
  }
}

// Onboarding Manager Widget - Wrap your app with this
class OnboardingManager extends StatefulWidget {
  final Widget child;

  const OnboardingManager({super.key, required this.child});

  @override
  State<OnboardingManager> createState() => _OnboardingManagerState();
}

class _OnboardingManagerState extends State<OnboardingManager> {
  @override
  void initState() {
    super.initState();
    _initializeOnboarding();
  }

  void _initializeOnboarding() async {
    // Wait for the first frame to be rendered
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        final onboardingService = OnboardingService();
        final hasCompleted = await onboardingService.hasCompletedOnboarding();

        if (!hasCompleted) {
          onboardingService.startOnboarding(context);
        }
      }
    });
  }

  @override
  void dispose() {
    OnboardingService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
