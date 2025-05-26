import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  final List<NavigationItem> _navigationItems = [
    NavigationItem(title: 'Home', icon: Icons.home, route: '/home1'),
    NavigationItem(
      title: 'Tutorials',
      icon: Icons.play_circle_outline,
      route: '/tutorials',
    ),
    NavigationItem(
      title: 'Practice',
      icon: Icons.fitness_center,
      route: '/practice',
    ),
    NavigationItem(title: 'Games', icon: Icons.games, route: '/games'),
    NavigationItem(title: 'Community', icon: Icons.forum, route: '/community'),
  ];

  // Items for bottom navigation (mobile) - most important ones
  List<NavigationItem> get _bottomNavItems => [
    _navigationItems[0], // Home
    _navigationItems[1], // Tutorials
    _navigationItems[3], // Games
    _navigationItems[4], // Community
    NavigationItem(
      title: 'Tech Glossary',
      icon: Icons.book,
      route: '/techglossary',
    ), // Replaced "More"
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
  }

  @override
  void didUpdateWidget(SidebarLayoutWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage) {
      _updateBottomNavIndex();
    }
  }

  void _updateBottomNavIndex() {
    // Map current page to bottom nav index
    String currentRoute = widget.currentPage;
    int newIndex = -1;

    if (currentRoute == '/home1') {
      newIndex = 0; // Home is first in bottom nav
    } else if (currentRoute == '/tutorials') {
      newIndex = 1; // Tutorials is second
    } else if (currentRoute == '/games') {
      newIndex = 2; // Games is third
    } else if (currentRoute == '/community') {
      newIndex = 3; // Community is fourth
    } else if (currentRoute == '/techglossary') {
      newIndex = 4; // Tech Glossary is fifth
    }

    if (newIndex != -1) {
      setState(() {
        _selectedBottomIndex = newIndex;
      });
    }
  }

  @override
  void dispose() {
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

  // Force mobile mode - set this to true to always show bottom navigation
  bool get _forceMobileMode =>
      true; // Change to false to use responsive breakpoints

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

  @override
  Widget build(BuildContext context) {
    final isDesktop = _isDesktop(context) && !_forceMobileMode;
    final isTablet = _isTablet(context) && !_forceMobileMode;
    final isMobile = _isMobile(context) || _forceMobileMode;

    return Scaffold(
      // Mobile app bar
      appBar: isMobile ? _buildMobileAppBar() : null,

      // Bottom navigation for mobile
      bottomNavigationBar: isMobile ? _buildBottomNavigation() : null,

      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
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
          // Logo
          Container(
            width: 32,
            height: 32,
            child: Image.asset(
              'assets/images/seniorsurfersLogoNoName.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.waves, color: Colors.white, size: 28);
              },
            ),
          ),
          const SizedBox(width: 12),
          // App title
          const Text(
            'Senior Surfers',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF27445D),
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        // Settings icon at the top right
        IconButton(
          icon: const Icon(Icons.settings),
          iconSize: 28,
          onPressed: () {
            context.go('/settingsD');
          },
          tooltip: 'Settings',
        ),
        // Achievements icon beside settings
        IconButton(
          icon: const Icon(Icons.emoji_events),
          iconSize: 28,
          onPressed: () {
            context.go('/achievements');
          },
          tooltip: 'Achievements',
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
          // Sidebar Header with Logo
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
                  // Logo
                  Container(
                    width: 40,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Senior Surfers',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isDesktop ? 22 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Navigation',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isDesktop ? 14 : 12,
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

          // Top Section - Settings and Achievements
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
              ],
            ),
          ),

          const Divider(color: Colors.white24),

          // Main Navigation Items
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

          // Tech Glossary at bottom (replacing more options)
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
        // Page Header (hidden on mobile if app bar exists)
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
                // Logo in desktop header
                Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(right: 16),
                  child: Image.asset(
                    'assets/images/seniorsurfersLogoNoName.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.waves,
                        color: const Color(0xFF27445D),
                        size: 40,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.pageTitle,
                    style: TextStyle(
                      fontSize: isDesktop ? 32 : 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF27445D),
                    ),
                  ),
                ),
                // Settings and Achievements in desktop header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings),
                      iconSize: 32,
                      color: const Color(0xFF27445D),
                      onPressed: () {
                        context.go('/settingsD');
                      },
                      tooltip: 'Settings',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.emoji_events),
                      iconSize: 32,
                      color: const Color(0xFF27445D),
                      onPressed: () {
                        context.go('/achievements');
                      },
                      tooltip: 'Achievements',
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Main Content - Expanded to fill remaining space
        Expanded(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(isMobile ? 16 : (isDesktop ? 32 : 24)),
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

// Sidebar Navigation Tile Widget
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
