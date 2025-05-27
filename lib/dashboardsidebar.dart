import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Main Layout Wrapper that all pages will use
class SidebarLayoutWrapper extends StatefulWidget {
  final Widget child;
  final String currentPage;
  final String pageTitle;

  const SidebarLayoutWrapper({
    super.key,
    required this.child,
    required this.currentPage,
    required this.pageTitle,
  });

  @override
  State<SidebarLayoutWrapper> createState() => _SidebarLayoutWrapperState();
}

class _SidebarLayoutWrapperState extends State<SidebarLayoutWrapper>
    with TickerProviderStateMixin {
  bool _isSidebarExpanded = true;
  late AnimationController _animationController;
  int _selectedBottomIndex = 0;

  // Onboarding state
  bool _showOnboarding = false;
  int _currentOnboardingStep = 0;
  OverlayEntry? _overlayEntry;
  final GlobalKey _homeNavKey = GlobalKey();
  final GlobalKey _tutorialNavKey = GlobalKey();
  final GlobalKey _gamesNavKey = GlobalKey();
  final GlobalKey _communityNavKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();
  final GlobalKey _sidebarToggleKey = GlobalKey();

  final List<NavigationItem> _navigationItems = [
    NavigationItem(title: 'Home', icon: Icons.home, route: '/home1'),
    NavigationItem(
      title: 'Tutorials',
      icon: Icons.play_circle_outline,
      route: '/tutorials',
    ),
    NavigationItem(title: 'Games', icon: Icons.games, route: '/games'),
    NavigationItem(title: 'Community', icon: Icons.forum, route: '/community'),
  ];

  // Items for bottom navigation (mobile) - most important ones
  List<NavigationItem> get _bottomNavItems => [
    _navigationItems[0], // Home
    _navigationItems[1], // Tutorials
    _navigationItems[2], // Games
    _navigationItems[3], // Community
    NavigationItem(
      title: 'Tech Glossary',
      icon: Icons.book,
      route: '/techglossary',
    ),
  ];

  // Onboarding steps for seniors
  List<OnboardingStep> get _onboardingSteps => [
    OnboardingStep(
      title: "Welcome to Senior Surfers!",
      description:
          "Let's take a quick tour to help you get started. This will only take a minute!",
      targetKey: null,
      isIntro: true,
    ),
    OnboardingStep(
      title: "Start Here - Home",
      description:
          "This is your Home button. Tap here anytime to return to the main page.",
      targetKey: _homeNavKey,
      position: TooltipPosition.bottom,
    ),
    OnboardingStep(
      title: "Learn New Skills",
      description:
          "Tutorials will teach you step-by-step how to use technology safely and easily.",
      targetKey: _tutorialNavKey,
      position: TooltipPosition.bottom,
    ),
    OnboardingStep(
      title: "Have Fun with Games",
      description:
          "Games are a great way to practice what you've learned in a fun way!",
      targetKey: _gamesNavKey,
      position: TooltipPosition.bottom,
    ),
    OnboardingStep(
      title: "Connect with Others",
      description:
          "Community lets you ask questions and share experiences with other learners.",
      targetKey: _communityNavKey,
      position: TooltipPosition.bottom,
    ),
    OnboardingStep(
      title: "Adjust Your Settings",
      description:
          "Settings lets you make the app bigger, change colors, or adjust other preferences.",
      targetKey: _settingsKey,
      position: TooltipPosition.left,
    ),
    OnboardingStep(
      title: "You're All Set!",
      description:
          "Great job! You can replay this tour anytime from Settings. Happy learning!",
      targetKey: null,
      isOutro: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
    _updateBottomNavIndex();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    if (!hasSeenOnboarding && widget.currentPage == '/home1') {
      // Small delay to ensure widgets are built
      Future.delayed(const Duration(milliseconds: 500), () {
        _startOnboarding();
      });
    }
  }

  void _startOnboarding() {
    setState(() {
      _showOnboarding = true;
      _currentOnboardingStep = 0;
    });
    _showOnboardingOverlay();
  }

  void _showOnboardingOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder:
          (context) => OnboardingOverlay(
            step: _onboardingSteps[_currentOnboardingStep],
            stepNumber: _currentOnboardingStep + 1,
            totalSteps: _onboardingSteps.length,
            onNext: _nextOnboardingStep,
            onSkip: _skipOnboarding,
            onPrevious:
                _currentOnboardingStep > 0 ? _previousOnboardingStep : null,
          ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _nextOnboardingStep() {
    if (_currentOnboardingStep < _onboardingSteps.length - 1) {
      setState(() {
        _currentOnboardingStep++;
      });
      _showOnboardingOverlay();
    } else {
      _completeOnboarding();
    }
  }

  void _previousOnboardingStep() {
    if (_currentOnboardingStep > 0) {
      setState(() {
        _currentOnboardingStep--;
      });
      _showOnboardingOverlay();
    }
  }

  void _skipOnboarding() async {
    _completeOnboarding();
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    _removeOverlay();
    setState(() {
      _showOnboarding = false;
      _currentOnboardingStep = 0;
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void didUpdateWidget(SidebarLayoutWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage) {
      _updateBottomNavIndex();
    }
  }

  void _updateBottomNavIndex() {
    String currentRoute = widget.currentPage;
    int newIndex = -1;

    if (currentRoute == '/home1') {
      newIndex = 0;
    } else if (currentRoute == '/tutorials') {
      newIndex = 1;
    } else if (currentRoute == '/games') {
      newIndex = 2;
    } else if (currentRoute == '/community') {
      newIndex = 3;
    } else if (currentRoute == '/techglossary') {
      newIndex = 4;
    }

    if (newIndex != -1) {
      setState(() {
        _selectedBottomIndex = newIndex;
      });
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  // Responsive breakpoints
  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;
  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1024;
  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  bool get _forceMobileMode => true;

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
      if (_isSidebarExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _onBottomNavTap(int index) {
    if (index < _bottomNavItems.length) {
      final item = _bottomNavItems[index];
      setState(() {
        _selectedBottomIndex = index;
      });
      context.go(item.route);
    }
  }

  // Add method to restart onboarding
  void _restartOnboarding() {
    _startOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = _isDesktop(context) && !_forceMobileMode;
    final isTablet = _isTablet(context) && !_forceMobileMode;
    final isMobile = _isMobile(context) || _forceMobileMode;

    return Scaffold(
      appBar: isMobile ? _buildMobileAppBar() : null,
      bottomNavigationBar: isMobile ? _buildBottomNavigation() : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              if (!isMobile)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width:
                      _isSidebarExpanded
                          ? (isDesktop ? 300 : 280)
                          : (isDesktop ? 90 : 80),
                  child: _buildSidebar(context),
                ),
              Expanded(
                child: Container(
                  color: Colors.grey[50],
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: _buildMainContent(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 40, // Slightly larger for seniors
            height: 40,
            child: Image.asset(
              'assets/images/seniorsurfersLogoNoName.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.waves, color: Colors.white, size: 32);
              },
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Senior Surfers',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ), // Larger text
          ),
        ],
      ),
      backgroundColor: const Color(0xFF27445D),
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          key: _settingsKey,
          icon: const Icon(Icons.settings),
          iconSize: 32, // Larger for seniors
          onPressed: () {
            context.go('/settingsD');
          },
          tooltip: 'Settings',
        ),
        IconButton(
          icon: const Icon(Icons.emoji_events),
          iconSize: 32, // Larger for seniors
          onPressed: () {
            context.go('/achievements');
          },
          tooltip: 'Achievements',
        ),
        // Add help button for easy access to onboarding
        IconButton(
          icon: const Icon(Icons.help_outline),
          iconSize: 32,
          onPressed: _restartOnboarding,
          tooltip: 'Help & Tour',
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
          ), // More padding for seniors
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                _bottomNavItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = _selectedBottomIndex == index;

                  GlobalKey? navKey;
                  if (index == 0)
                    navKey = _homeNavKey;
                  else if (index == 1)
                    navKey = _tutorialNavKey;
                  else if (index == 2)
                    navKey = _gamesNavKey;
                  else if (index == 3)
                    navKey = _communityNavKey;

                  return GestureDetector(
                    key: navKey,
                    onTap: () => _onBottomNavTap(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12, // Larger touch area
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? const Color(0xFF27445D).withOpacity(0.15)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            color:
                                isSelected
                                    ? const Color(0xFF27445D)
                                    : Colors.grey[600],
                            size: 28, // Larger icons for seniors
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.title,
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? const Color(0xFF27445D)
                                      : Colors.grey[600],
                              fontSize: 14, // Larger text for seniors
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final isDesktop = _isDesktop(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF27445D),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 20 : 16),
            child: Row(
              children: [
                IconButton(
                  key: _sidebarToggleKey,
                  icon: Icon(
                    _isSidebarExpanded ? Icons.menu_open : Icons.menu,
                    color: Colors.white,
                    size: isDesktop ? 32 : 28, // Larger for seniors
                  ),
                  onPressed: _toggleSidebar,
                ),
                if (_isSidebarExpanded) ...[
                  const SizedBox(width: 12),
                  Container(
                    width: 44, // Larger logo
                    height: 44,
                    child: Image.asset(
                      'assets/images/seniorsurfersLogoNoName.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.waves, color: Colors.white, size: 36);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Senior Surfers',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isDesktop ? 24 : 22, // Larger text
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Navigation',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isDesktop ? 16 : 14, // Larger text
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: Colors.white24),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                SidebarNavigationTile(
                  item: NavigationItem(
                    title: 'Settings',
                    icon: Icons.settings,
                    route: '/settingsD',
                  ),
                  isExpanded: _isSidebarExpanded,
                  isSelected: widget.currentPage == '/settingsD',
                  isDesktop: isDesktop,
                  onTap: () {
                    context.go('/settingsD');
                  },
                ),
                SidebarNavigationTile(
                  item: NavigationItem(
                    title: 'Achievements',
                    icon: Icons.emoji_events,
                    route: '/achievements',
                  ),
                  isExpanded: _isSidebarExpanded,
                  isSelected: widget.currentPage == '/achievements',
                  isDesktop: isDesktop,
                  onTap: () {
                    context.go('/achievements');
                  },
                ),
                // Add help/tour button in sidebar too
                SidebarNavigationTile(
                  item: NavigationItem(
                    title: 'Help & Tour',
                    icon: Icons.help_outline,
                    route: '', // Empty route since it's an action
                  ),
                  isExpanded: _isSidebarExpanded,
                  isSelected: false,
                  isDesktop: isDesktop,
                  onTap: _restartOnboarding,
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white24),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                final item = _navigationItems[index];
                return SidebarNavigationTile(
                  item: item,
                  isExpanded: _isSidebarExpanded,
                  isSelected: widget.currentPage == item.route,
                  isDesktop: isDesktop,
                  onTap: () {
                    context.go(item.route);
                  },
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(8),
            child: SidebarNavigationTile(
              item: NavigationItem(
                title: 'Tech Glossary',
                icon: Icons.book,
                route: '/techglossary',
              ),
              isExpanded: _isSidebarExpanded,
              isSelected: widget.currentPage == '/techglossary',
              isDesktop: _isDesktop(context),
              onTap: () {
                context.go('/techglossary');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final isDesktop = _isDesktop(context);
    final isTablet = _isTablet(context);
    final isMobile = _isMobile(context);

    return Column(
      children: [
        if (!isMobile)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isDesktop ? 32 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52, // Larger logo
                  height: 52,
                  margin: const EdgeInsets.only(right: 16),
                  child: Image.asset(
                    'assets/images/seniorsurfersLogoNoName.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.waves,
                        color: const Color(0xFF27445D),
                        size: 44,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.pageTitle,
                    style: TextStyle(
                      fontSize: isDesktop ? 36 : 32, // Larger text for seniors
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF27445D),
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings),
                      iconSize: 36, // Larger for seniors
                      color: const Color(0xFF27445D),
                      onPressed: () {
                        context.go('/settingsD');
                      },
                      tooltip: 'Settings',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.emoji_events),
                      iconSize: 36, // Larger for seniors
                      color: const Color(0xFF27445D),
                      onPressed: () {
                        context.go('/achievements');
                      },
                      tooltip: 'Achievements',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.help_outline),
                      iconSize: 36,
                      color: const Color(0xFF27445D),
                      onPressed: _restartOnboarding,
                      tooltip: 'Help & Tour',
                    ),
                  ],
                ),
              ],
            ),
          ),

        Expanded(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(
              isMobile ? 20 : (isDesktop ? 32 : 24),
            ), // More padding
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

// Navigation Item Model
class NavigationItem {
  final String title;
  final IconData icon;
  final String route;

  NavigationItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}

// Onboarding Step Model
class OnboardingStep {
  final String title;
  final String description;
  final GlobalKey? targetKey;
  final TooltipPosition position;
  final bool isIntro;
  final bool isOutro;

  OnboardingStep({
    required this.title,
    required this.description,
    this.targetKey,
    this.position = TooltipPosition.bottom,
    this.isIntro = false,
    this.isOutro = false,
  });
}

enum TooltipPosition { top, bottom, left, right }

// Onboarding Overlay Widget
class OnboardingOverlay extends StatelessWidget {
  final OnboardingStep step;
  final int stepNumber;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback? onPrevious;

  const OnboardingOverlay({
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
      color: Colors.black.withOpacity(0.7), // Semi-transparent overlay
      child: Stack(
        children: [
          // Highlight target if it exists
          if (step.targetKey != null) _buildHighlight(context),

          // Tooltip
          _buildTooltip(context),
        ],
      ),
    );
  }

  Widget _buildHighlight(BuildContext context) {
    final RenderBox? renderBox =
        step.targetKey!.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox();

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    return Positioned(
      left: position.dx - 8,
      top: position.dy - 8,
      child: Container(
        width: size.width + 16,
        height: size.height + 16,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltip(BuildContext context) {
    if (step.isIntro || step.isOutro) {
      return _buildCenterTooltip(context);
    }

    final RenderBox? renderBox =
        step.targetKey?.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return _buildCenterTooltip(context);

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    double left = 0;
    double top = 0;

    switch (step.position) {
      case TooltipPosition.bottom:
        left = position.dx + (size.width / 2) - 150;
        top = position.dy + size.height + 20;
        break;
      case TooltipPosition.top:
        left = position.dx + (size.width / 2) - 150;
        top = position.dy - 200;
        break;
      case TooltipPosition.left:
        left = position.dx - 320;
        top = position.dy + (size.height / 2) - 100;
        break;
      case TooltipPosition.right:
        left = position.dx + size.width + 20;
        top = position.dy + (size.height / 2) - 100;
        break;
    }

    // Keep tooltip on screen
    left = left.clamp(20.0, screenSize.width - 320);
    top = top.clamp(20.0, screenSize.height - 200);

    return Positioned(
      left: left,
      top: top,
      child: _buildTooltipContent(context),
    );
  }

  Widget _buildCenterTooltip(BuildContext context) {
    return Center(child: _buildTooltipContent(context));
  }

  Widget _buildTooltipContent(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24), // More padding for seniors
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
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
                  fontSize: 16, // Larger text for seniors
                  color: Color(0xFF27445D),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF27445D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(stepNumber / totalSteps * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF27445D),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 22, // Large text for seniors
              fontWeight: FontWeight.bold,
              color: Color(0xFF27445D),
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            step.description,
            style: const TextStyle(
              fontSize: 18, // Large text for seniors
              color: Colors.black87,
              height: 1.4, // Better line spacing
            ),
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              if (onPrevious != null) ...[
                TextButton(
                  onPressed: onPrevious,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(fontSize: 16, color: Color(0xFF27445D)),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Skip Tour',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27445D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ), // Larger buttons
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  stepNumber == totalSteps ? 'Finish' : 'Next',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ), // Larger text
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Sidebar Navigation Tile Widget (updated for seniors)
class SidebarNavigationTile extends StatefulWidget {
  final NavigationItem item;
  final bool isExpanded;
  final bool isSelected;
  final bool isDesktop;
  final VoidCallback onTap;

  const SidebarNavigationTile({
    super.key,
    required this.item,
    required this.isExpanded,
    required this.isSelected,
    required this.isDesktop,
    required this.onTap,
  });

  @override
  State<SidebarNavigationTile> createState() => _SidebarNavigationTileState();
}

class _SidebarNavigationTileState extends State<SidebarNavigationTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isDesktop ? 12 : 8,
        vertical: 6, // More spacing for seniors
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal:
                    widget.isExpanded ? (widget.isDesktop ? 20 : 16) : 12,
                vertical:
                    widget.isDesktop ? 18 : 16, // More padding for seniors
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color:
                    widget.isSelected
                        ? Colors.white.withOpacity(0.15)
                        : _isHovered
                        ? Colors.white.withOpacity(0.1)
                        : Colors.transparent,
                border:
                    widget.isSelected
                        ? Border.all(color: Colors.white.withOpacity(0.3))
                        : null,
              ),
              child: Row(
                mainAxisAlignment:
                    widget.isExpanded
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.item.icon,
                    color: Colors.white,
                    size:
                        widget.isDesktop ? 28 : 26, // Larger icons for seniors
                  ),
                  if (widget.isExpanded) ...[
                    SizedBox(width: widget.isDesktop ? 20 : 16),
                    Expanded(
                      child: Text(
                        widget.item.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize:
                              widget.isDesktop
                                  ? 20
                                  : 18, // Larger text for seniors
                          fontWeight:
                              widget.isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
