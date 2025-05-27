// File: onboarding_page.dart - REMOVED/REPLACED
// This standalone onboarding page has been replaced with an overlay system
// that appears over the homepage. If this route is accessed, redirect to home.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  @override
  void initState() {
    super.initState();
    // Immediately redirect to home since we use overlay onboarding now
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go('/home1');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF27445D)),
            SizedBox(height: 24),
            Text(
              'Redirecting to Home...',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF27445D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
