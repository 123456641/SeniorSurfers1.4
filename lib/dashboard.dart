import 'package:flutter/material.dart';
import 'package:senior_surfers/header_widget.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  bool _isSidebarExpanded = true;
  late AnimationController _animationController;
  late Animation<double> _sidebarAnimation;
  String _selectedSection = 'Tutorials'; // Changed default to Tutorials
  int _selectedBottomIndex = 0; // Tutorials is first in bottom nav

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      title: 'Tutorials',
      icon: Icons.play_circle_outline,
      imagePath: 'assets/images/tutorial.png',
      route: '/tutorials',
    ),
    NavigationItem(
      title: 'Practice',
      icon: Icons.fitness_center,
      imagePath: 'assets/images/practice.png',
      route: '/practice',
    ),
    NavigationItem(
      title: 'Tech Glossary',
      icon: Icons.book,
      imagePath: 'assets/images/tech_glossary.png',
      route: '/techglossary',
    ),
    NavigationItem(
      title: 'Games',
      icon: Icons.games,
      imagePath: 'assets/images/games.png',
      route: '/games',
    ),
    NavigationItem(
      title: 'Community',
      icon: Icons.forum,
      imagePath: 'assets/images/community_forum.png',
      route: '/community',
    ),
    NavigationItem(
      title: 'Achievements',
      icon: Icons.emoji_events,
      imagePath: 'assets/images/achievements.png',
      route: '/achievements',
    ),
  ];

  // Items for bottom navigation (mobile) - removed Dashboard
  List<NavigationItem> get _bottomNavItems => [
    _navigationItems[0], // Tutorials
    _navigationItems[1], // Practice
    _navigationItems[3], // Games
    _navigationItems[4], // Community
    NavigationItem(
      title: 'More',
      icon: Icons.more_horiz,
      imagePath: '',
      route: '/more',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _sidebarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Auto-navigate to tutorials on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/tutorials');
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Responsive breakpoints
  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;
  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 768 &&
      MediaQuery.of(context).size.width < 1200;
  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;

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

  void _selectSection(String section, {int? bottomIndex}) {
    setState(() {
      _selectedSection = section;
      if (bottomIndex != null) {
        _selectedBottomIndex = bottomIndex;
      }
    });
  }

  void _onBottomNavTap(int index) {
    if (index < _bottomNavItems.length) {
      final item = _bottomNavItems[index];
      if (item.title == 'More') {
        _showMoreOptionsBottomSheet();
      } else {
        _selectSection(item.title, bottomIndex: index);
        if (item.route.isNotEmpty) {
          context.go(item.route); // Changed to go() instead of push()
        }
      }
    }
  }

  void _showMoreOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      'More Options',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF27445D),
                      ),
                    ),
                  ),
                  // Show remaining navigation items (Tech Glossary, Achievements)
                  ListTile(
                    leading: Icon(
                      _navigationItems[2].icon,
                      color: const Color(0xFF27445D),
                    ),
                    title: Text(
                      _navigationItems[2].title, // Tech Glossary
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _selectSection(_navigationItems[2].title);
                      context.go(_navigationItems[2].route);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      _navigationItems[5].icon,
                      color: const Color(0xFF27445D),
                    ),
                    title: Text(
                      _navigationItems[5].title, // Achievements
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _selectSection(_navigationItems[5].title);
                      context.go(_navigationItems[5].route);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.settings,
                      color: Color(0xFF27445D),
                    ),
                    title: const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _selectSection('Settings');
                      context.go('/settingsD');
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = _isDesktop(context);
    final isTablet = _isTablet(context);
    final isMobile = _isMobile(context);

    return Scaffold(
      // Mobile app bar
      appBar: isMobile ? _buildMobileAppBar() : null,

      // Bottom navigation for mobile
      bottomNavigationBar: isMobile ? _buildBottomNavigation() : null,

      body: SafeArea(
        child: Row(
          children: [
            // Sidebar - Hide on mobile, show on tablet/desktop
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

            // Main Content Area
            Expanded(
              child: Container(
                color: Colors.grey[50],
                height: double.infinity,
                child: _buildMainContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      title: const Text(
        'Senior Surfers',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      backgroundColor: const Color(0xFF27445D),
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // Handle notifications
          },
        ),
        IconButton(
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: () {
            // Handle profile
          },
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                _bottomNavItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = _selectedBottomIndex == index;

                  return GestureDetector(
                    onTap: () => _onBottomNavTap(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? const Color(0xFF27445D).withOpacity(0.1)
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
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.title,
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? const Color(0xFF27445D)
                                      : Colors.grey[600],
                              fontSize: 12,
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
          // Sidebar Header
          Container(
            padding: EdgeInsets.all(isDesktop ? 20 : 16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isSidebarExpanded ? Icons.menu_open : Icons.menu,
                    color: Colors.white,
                    size: isDesktop ? 28 : 24,
                  ),
                  onPressed: _toggleSidebar,
                ),
                if (_isSidebarExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Senior Surfers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isDesktop ? 22 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: Colors.white24),

          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                final item = _navigationItems[index];
                return SidebarNavigationTile(
                  item: item,
                  isExpanded: _isSidebarExpanded,
                  isSelected: _selectedSection == item.title,
                  isDesktop: isDesktop,
                  onTap: () {
                    _selectSection(item.title);
                    if (item.route.isNotEmpty) {
                      context.go(
                        item.route,
                      ); // Changed to go() instead of push()
                    }
                  },
                );
              },
            ),
          ),

          // Settings at bottom
          Container(
            padding: const EdgeInsets.all(8),
            child: SidebarNavigationTile(
              item: NavigationItem(
                title: 'Settings',
                icon: Icons.settings,
                imagePath: '',
                route: '/settingsD',
              ),
              isExpanded: _isSidebarExpanded,
              isSelected: _selectedSection == 'Settings',
              isDesktop: isDesktop,
              onTap: () {
                _selectSection('Settings');
                context.go('/settingsD');
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
        // Page Header (hidden on mobile if app bar exists)
        if (!isMobile) ...[
          Container(
            padding: EdgeInsets.all(isDesktop ? 32 : 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedSection,
                  style: TextStyle(
                    fontSize: isDesktop ? 48 : 36,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF27445D),
                  ),
                ),
                Text(
                  'Learn technology step by step',
                  style: TextStyle(
                    fontSize: isDesktop ? 18 : 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Content Area - Show a welcome message instead of dashboard grid
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : (isDesktop ? 32 : 24),
              isMobile ? 16 : 0,
              isMobile ? 16 : (isDesktop ? 32 : 24),
              isMobile ? 16 : (isDesktop ? 32 : 24),
            ),
            child: _buildWelcomeContent(context),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeContent(BuildContext context) {
    final isDesktop = _isDesktop(context);
    final isMobile = _isMobile(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school,
            size: isMobile ? 80 : (isDesktop ? 120 : 100),
            color: const Color(0xFF27445D),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Senior Surfers!',
            style: TextStyle(
              fontSize: isMobile ? 24 : (isDesktop ? 36 : 30),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF27445D),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Learn technology at your own pace with our step-by-step tutorials, practice exercises, and helpful community.',
            style: TextStyle(
              fontSize: isMobile ? 16 : (isDesktop ? 20 : 18),
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              context.go('/tutorials');
            },
            icon: const Icon(Icons.play_circle_outline, color: Colors.white),
            label: Text(
              'Start Learning',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27445D),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 32,
                vertical: isMobile ? 12 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final String title;
  final IconData icon;
  final String imagePath;
  final String route;

  NavigationItem({
    required this.title,
    required this.icon,
    required this.imagePath,
    required this.route,
  });
}

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
        vertical: 4,
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
                vertical: widget.isDesktop ? 16 : 12,
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
                    size: widget.isDesktop ? 26 : 24,
                  ),
                  if (widget.isExpanded) ...[
                    SizedBox(width: widget.isDesktop ? 20 : 16),
                    Expanded(
                      child: Text(
                        widget.item.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: widget.isDesktop ? 18 : 16,
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
