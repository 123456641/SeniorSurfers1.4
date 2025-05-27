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
  bool _hasAutoStarted = false; // Prevent multiple auto-starts
  bool _isShowingDialog = false; // Prevent multiple fallback dialogs
  BuildContext? _context;

  final List<OnboardingStepData> _onboardingSteps = [
    OnboardingStepData(
      title: "Welcome to Senior Surfers! 🌊",
      description:
          "Let's take a quick tour to help you get started. This will take you through each section of the app to show you what's available!",
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
          "Welcome to Tutorials! Here you'll find easy-to-follow lessons that teach you new technology skills. Each tutorial is designed specifically for beginners.",
      route: '/tutorials',
    ),
    OnboardingStepData(
      title: "Practice What You Learn 💪",
      description:
          "This is the Practice section! Here you can safely try out what you've learned without any pressure. It's like a practice playground for your new skills.",
      route: '/practice',
    ),
    OnboardingStepData(
      title: "Fun Learning Games 🎮",
      description:
          "Welcome to Games! Learning can be fun! These simple games help you remember what you've learned while enjoying yourself.",
      route: '/games',
    ),
    OnboardingStepData(
      title: "Connect with Others 👥",
      description:
          "This is our Community! Here you can ask questions, share experiences, and learn from other people just like you. Everyone is here to help!",
      route: '/community',
    ),
    OnboardingStepData(
      title: "Tech Dictionary 📖",
      description:
          "Welcome to the Tech Glossary! Don't know what a technology word means? This section explains all the technical terms in simple, easy-to-understand language.",
      route: '/techglossary',
    ),
    OnboardingStepData(
      title: "Track Your Progress 🏆",
      description:
          "This is your Achievements page! Here you can see your learning progress and celebrate your milestones. Every step forward is worth celebrating!",
      route: '/achievements',
    ),
    OnboardingStepData(
      title: "Customize Your Experience ⚙️",
      description:
          "Welcome to Settings! Here you can make the app work better for you - make text bigger, enable voice reading, change colors, and much more!",
      route: '/settingsD',
    ),
    OnboardingStepData(
      title: "You're All Set! 🎉",
      description:
          "Perfect! You've now seen all the main sections of Senior Surfers. You can restart this tour anytime by tapping the help button (?) found throughout the app. Happy learning!",
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
              .from('users')
              .select('onboarding_completed')
              .eq('id', user.id)
              .single();

      return response['onboarding_completed'] ?? false;
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
          .from('users')
          .update({'onboarding_completed': true})
          .eq('id', user.id);
    } catch (e) {
      print('Error marking onboarding complete: $e');
    }
  }

  // Start onboarding (for auto-start)
  Future<void> startOnboarding(BuildContext context) async {
    if (_isOnboardingActive || _hasAutoStarted) return;

    final hasCompleted = await hasCompletedOnboarding();
    if (hasCompleted) return;

    if (!context.mounted) return;

    _hasAutoStarted = true;
    _context = context;
    _currentStep = 0;
    _isOnboardingActive = true;
    _showCurrentStep();
  }

  // Restart onboarding (for help/tour button)
  void restartOnboarding(BuildContext context) {
    if (!context.mounted) return;

    print('🔄 Restarting onboarding...');

    // Clean up any existing onboarding first
    _removeOverlay();

    _context = context;
    _currentStep = 0;
    _isOnboardingActive = true;
    _showCurrentStep();
  }

  // Method to refresh context when navigating (called by mixin)
  void refreshContext(BuildContext context) {
    if (_isOnboardingActive && context.mounted) {
      final oldRoute =
          _context != null
              ? ModalRoute.of(_context!)?.settings.name
              : 'unknown';
      final newRoute = ModalRoute.of(context)?.settings.name ?? 'unknown';

      _context = context;
      print(
        '🔄 Context refreshed for onboarding - from $oldRoute to $newRoute',
      );

      // If we're in the middle of onboarding and the context changed,
      // we might need to show the overlay/dialog for the current step
      if (_currentStep > 0 && !_isShowingDialog && _overlayEntry == null) {
        print(
          '🔄 Context refreshed mid-onboarding, showing current step overlay/dialog',
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_isOnboardingActive && _context != null && _context!.mounted) {
            _showOverlay();
          }
        });
      }
    }
  }

  void _showCurrentStep() {
    if (_context == null ||
        !_context!.mounted ||
        _currentStep >= _onboardingSteps.length)
      return;

    final step = _onboardingSteps[_currentStep];

    // Navigate to the step's route (except for intro step which should already be on home)
    if (!step.isIntro && _context!.mounted) {
      _context!.go(step.route);
      // Longer delay to ensure navigation completes and new page is fully loaded
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (_context != null && _context!.mounted) {
          _showOverlay();
        }
      });
    } else {
      // For intro step, show overlay immediately
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_context != null && _context!.mounted) {
          _showOverlay();
        }
      });
    }
  }

  void _showOverlay() {
    _removeOverlay();

    if (_context == null || !_context!.mounted) {
      print('❌ Context not available for overlay');
      return;
    }

    try {
      // Get the current overlay from the current context
      final overlay = Overlay.maybeOf(_context!);
      if (overlay == null) {
        print('❌ No Overlay found, showing fallback dialog...');
        if (!_isShowingDialog) {
          _showFallbackDialog();
        }
        return;
      }

      _overlayEntry = OverlayEntry(
        builder:
            (context) => OnboardingOverlayWidget(
              step: _onboardingSteps[_currentStep],
              stepNumber: _currentStep + 1,
              totalSteps: _onboardingSteps.length,
              onNext: () {
                print(
                  '🔄 Next button clicked - current step: ${_currentStep + 1}',
                );
                _removeOverlay(); // Remove overlay immediately
                _nextStep();
              },
              onSkip: () {
                print('🔄 Skip button clicked');
                _removeOverlay(); // Remove overlay immediately
                _skipOnboarding();
              },
              onPrevious:
                  _currentStep > 0
                      ? () {
                        print('🔄 Previous button clicked');
                        _removeOverlay(); // Remove overlay immediately
                        _previousStep();
                      }
                      : null,
            ),
      );

      overlay.insert(_overlayEntry!);
      print(
        '✅ Overlay displayed for step ${_currentStep + 1} on route ${_onboardingSteps[_currentStep].route}',
      );
    } catch (e) {
      print('❌ Error showing overlay: $e');
      _overlayEntry = null;
      if (!_isShowingDialog) {
        _showFallbackDialog();
      }
    }
  }

  // Fallback dialog if overlay system fails
  void _showFallbackDialog() {
    if (_context == null ||
        !_context!.mounted ||
        !_isOnboardingActive ||
        _isShowingDialog) {
      return;
    }

    _isShowingDialog = true;
    final step = _onboardingSteps[_currentStep];

    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder:
          (context) => WillPopScope(
            onWillPop: () async => false, // Prevent back button dismissal
            child: AlertDialog(
              title: Text(
                step.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF27445D),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step ${_currentStep + 1} of ${_onboardingSteps.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    step.description,
                    style: const TextStyle(fontSize: 18, height: 1.4),
                  ),
                  if (!step.isIntro && !step.isOutro) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27445D).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: const Color(0xFF27445D),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Currently on: ${_getCurrentPageName()}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF27445D),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _isShowingDialog = false;
                      _previousStep();
                    },
                    child: const Text('Back'),
                  ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _isShowingDialog = false;
                    _skipOnboarding();
                  },
                  child: const Text('Skip Tour'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _isShowingDialog = false;
                    _nextStep();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27445D),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _currentStep == _onboardingSteps.length - 1
                        ? 'Finish'
                        : 'Next',
                  ),
                ),
              ],
            ),
          ),
    );
  }

  String _getCurrentPageName() {
    switch (_onboardingSteps[_currentStep].route) {
      case '/home1':
        return 'Home Page';
      case '/tutorials':
        return 'Tutorials Page';
      case '/practice':
        return 'Practice Page';
      case '/games':
        return 'Games Page';
      case '/community':
        return 'Community Page';
      case '/techglossary':
        return 'Tech Glossary Page';
      case '/achievements':
        return 'Achievements Page';
      case '/settingsD':
        return 'Settings Page';
      default:
        return 'Current Page';
    }
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
    print('🔄 Onboarding skip - finishing');
    _completeOnboarding();
  }

  void _completeOnboarding() async {
    await markOnboardingComplete();
    _removeOverlay();
    _isOnboardingActive = false;
    _isShowingDialog = false;
    _currentStep = 0;
    _hasAutoStarted = true; // Prevent auto-start after completion

    // Navigate back to home
    if (_context != null && _context!.mounted) {
      _context!.go('/home1');
    }

    // Clear context reference
    _context = null;
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      try {
        _overlayEntry!.remove();
      } catch (e) {
        print('❌ Error removing overlay: $e');
      }
      _overlayEntry = null;
    }
    _isShowingDialog = false; // Reset dialog flag when removing overlay
  }

  void dispose() {
    _removeOverlay();
    _isOnboardingActive = false;
    _isShowingDialog = false;
    _context = null;
    // Don't reset _hasAutoStarted on dispose to prevent restarts
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
      color: Colors.black.withOpacity(
        0.85,
      ), // Darker overlay to ensure visibility
      child: GestureDetector(
        onTap: () {}, // Intercept taps to prevent clicking through
        child: SafeArea(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              constraints: const BoxConstraints(maxWidth: 400),
              child: _buildTooltipContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTooltipContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(
        32,
      ), // More padding for better touch targets
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: 5,
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
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF27445D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
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
          const SizedBox(height: 24),

          // Title with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF27445D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getStepIcon(), color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF27445D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Description
          Text(
            step.description,
            style: const TextStyle(
              fontSize: 22,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Current page indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF27445D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF27445D).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: const Color(0xFF27445D),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Currently viewing: ${_getCurrentPageName()}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF27445D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Navigation buttons with better spacing and larger touch targets
          Row(
            children: [
              if (onPrevious != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPrevious,
                    icon: const Icon(Icons.arrow_back, size: 20),
                    label: const Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF27445D),
                      side: const BorderSide(
                        color: Color(0xFF27445D),
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              Expanded(
                child: TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Skip Tour',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onNext,
                  icon: Icon(
                    stepNumber == totalSteps
                        ? Icons.check
                        : Icons.arrow_forward,
                    size: 20,
                  ),
                  label: Text(
                    stepNumber == totalSteps ? 'Finish Tour' : 'Next',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27445D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getStepIcon() {
    switch (stepNumber) {
      case 1:
        return Icons.waving_hand;
      case 2:
        return Icons.home;
      case 3:
        return Icons.school;
      case 4:
        return Icons.fitness_center;
      case 5:
        return Icons.games;
      case 6:
        return Icons.people;
      case 7:
        return Icons.book;
      case 8:
        return Icons.emoji_events;
      case 9:
        return Icons.settings;
      case 10:
        return Icons.celebration;
      default:
        return Icons.info;
    }
  }

  String _getCurrentPageName() {
    switch (step.route) {
      case '/home1':
        return 'Home';
      case '/tutorials':
        return 'Tutorials';
      case '/practice':
        return 'Practice';
      case '/games':
        return 'Games';
      case '/community':
        return 'Community';
      case '/techglossary':
        return 'Tech Glossary';
      case '/achievements':
        return 'Achievements';
      case '/settingsD':
        return 'Settings';
      default:
        return 'Current Page';
    }
  }
}

// Main mixin for home page (can auto-start onboarding)
mixin OnboardingMixin<T extends StatefulWidget> on State<T> {
  bool _hasCheckedOnboarding = false;

  @override
  void initState() {
    super.initState();
    // Don't check routes in initState - wait for didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Refresh onboarding context when page dependencies change
    if (mounted) {
      OnboardingService().refreshContext(context);

      // Check and start onboarding only once and only from home page
      if (!_hasCheckedOnboarding && _isHomePage()) {
        _hasCheckedOnboarding = true;
        _checkAndStartOnboarding();
      }
    }
  }

  // Check if this is the home page (now safe to call after didChangeDependencies)
  bool _isHomePage() {
    try {
      final routeName = ModalRoute.of(context)?.settings.name;
      return widget.runtimeType.toString().contains('HomePage1') ||
          routeName == '/home1' ||
          routeName == null; // Default case for initial route
    } catch (e) {
      // If route info is not available, assume it's home page
      return widget.runtimeType.toString().contains('HomePage1');
    }
  }

  void _checkAndStartOnboarding() async {
    // Small delay to ensure widgets are fully built
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      final onboardingService = OnboardingService();
      final hasCompleted = await onboardingService.hasCompletedOnboarding();

      if (!hasCompleted && mounted) {
        onboardingService.startOnboarding(context);
      }
    }
  }

  void restartOnboarding() {
    if (mounted) {
      OnboardingService().restartOnboarding(context);
    }
  }
}

// Simpler mixin for other pages (only provides help button functionality)
mixin OnboardingHelperMixin<T extends StatefulWidget> on State<T> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh onboarding context when page dependencies change
    if (mounted) {
      OnboardingService().refreshContext(context);
    }
  }

  void restartOnboarding() {
    if (mounted) {
      OnboardingService().restartOnboarding(context);
    }
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
  void dispose() {
    // Clean up onboarding service when app is disposed
    OnboardingService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
