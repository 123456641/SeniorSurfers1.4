// File: lib/pages/onboarding.dart - Replace your existing file with this
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/onboarding_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _handleOnboardingRedirect();
  }

  Future<void> _handleOnboardingRedirect() async {
    // Small delay to show loading
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    try {
      final onboardingService = OnboardingService();
      final hasCompleted = await onboardingService.hasCompletedOnboarding();

      if (hasCompleted) {
        // User has completed onboarding, go to home
        context.go('/home1');
      } else {
        // Start the onboarding overlay system
        context.go('/home1');
        // Small delay to ensure navigation completes
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          onboardingService.startOnboarding(context);
        }
      }
    } catch (e) {
      print('Error checking onboarding status: $e');
      // On error, just go to home
      if (mounted) {
        context.go('/home1');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF27445D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.waves,
                size: 60,
                color: Color(0xFF27445D),
              ),
            ),
            const SizedBox(height: 32),

            // App name
            const Text(
              'Senior Surfers',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF27445D),
              ),
            ),
            const SizedBox(height: 16),

            // Tagline
            const Text(
              'Learn technology at your own pace',
              style: TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Loading indicator
            if (_isLoading) ...[
              const CircularProgressIndicator(
                color: Color(0xFF27445D),
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              const Text(
                'Setting up your experience...',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF27445D),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            // Manual controls (shown if loading takes too long)
            if (!_isLoading) ...[
              ElevatedButton.icon(
                onPressed: () {
                  OnboardingService().restartOnboarding(context);
                },
                icon: const Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                ),
                label: const Text(
                  'Start Tour',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27445D),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/home1'),
                child: const Text(
                  'Skip to Home',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// You can also create a welcome splash screen if needed
class WelcomeSplashScreen extends StatefulWidget {
  const WelcomeSplashScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeSplashScreen> createState() => _WelcomeSplashScreenState();
}

class _WelcomeSplashScreenState extends State<WelcomeSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();

    // Auto proceed after animation
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _proceedToOnboarding();
      }
    });
  }

  Future<void> _proceedToOnboarding() async {
    final onboardingService = OnboardingService();
    final hasCompleted = await onboardingService.hasCompletedOnboarding();

    if (!mounted) return;

    if (hasCompleted) {
      context.go('/home1');
    } else {
      context.go('/home1');
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        onboardingService.startOnboarding(context);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF27445D),
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(75),
                      ),
                      child: const Icon(
                        Icons.waves,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // App name
                    const Text(
                      'Senior Surfers',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tagline
                    const Text(
                      'Technology made simple',
                      style: TextStyle(fontSize: 20, color: Colors.white70),
                    ),
                    const SizedBox(height: 64),

                    // Loading indicator
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
