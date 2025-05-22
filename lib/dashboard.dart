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
  String _selectedSection = 'Dashboard';

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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

  void _selectSection(String section) {
    setState(() {
      _selectedSection = section;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isWebMode = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: const HeaderWidget(title: 'Senior Surfers'),
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width:
                _isSidebarExpanded
                    ? (isWebMode ? 280 : 250)
                    : (isWebMode ? 80 : 70),
            child: Container(
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
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isSidebarExpanded ? Icons.menu_open : Icons.menu,
                            color: Colors.white,
                            size: isWebMode ? 28 : 24,
                          ),
                          onPressed: _toggleSidebar,
                        ),
                        if (_isSidebarExpanded) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Navigation',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isWebMode ? 20 : 18,
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
                      itemCount: _navigationItems.length,
                      itemBuilder: (context, index) {
                        final item = _navigationItems[index];
                        return SidebarNavigationTile(
                          item: item,
                          isExpanded: _isSidebarExpanded,
                          isSelected: _selectedSection == item.title,
                          isWebMode: isWebMode,
                          onTap: () {
                            _selectSection(item.title);
                            context.push(item.route);
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
                      isWebMode: isWebMode,
                      onTap: () {
                        _selectSection('Settings');
                        context.push('/settingsD');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main Content Area
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: _buildMainContent(isWebMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isWebMode) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedSection,
                style: TextStyle(
                  fontSize: isWebMode ? 48 : 36,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF27445D),
                ),
              ),
              if (_selectedSection == 'Dashboard')
                Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: isWebMode ? 18 : 16,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          // Content Area
          Expanded(child: _buildContentForSection(_selectedSection, isWebMode)),
        ],
      ),
    );
  }

  Widget _buildContentForSection(String section, bool isWebMode) {
    if (section == 'Dashboard') {
      return GridView.count(
        crossAxisCount: isWebMode ? 3 : 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.2,
        children:
            _navigationItems.map((item) {
              return ContentCard(
                title: item.title,
                imagePath: item.imagePath,
                isWebMode: isWebMode,
                onTap: () {
                  _selectSection(item.title);
                  context.push(item.route);
                },
              );
            }).toList(),
      );
    } else {
      // Placeholder content for other sections
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: isWebMode ? 80 : 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '$section content will be displayed here',
              style: TextStyle(
                fontSize: isWebMode ? 24 : 20,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This is where the $section functionality will be implemented.',
              style: TextStyle(
                fontSize: isWebMode ? 16 : 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
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
  final bool isWebMode;
  final VoidCallback onTap;

  const SidebarNavigationTile({
    super.key,
    required this.item,
    required this.isExpanded,
    required this.isSelected,
    required this.isWebMode,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform:
              _isHovered
                  ? (Matrix4.identity()..scale(1.02))
                  : Matrix4.identity(),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
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
                  children: [
                    Icon(
                      widget.item.icon,
                      color: Colors.white,
                      size: widget.isWebMode ? 24 : 22,
                    ),
                    if (widget.isExpanded) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.item.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.isWebMode ? 16 : 14,
                            fontWeight:
                                widget.isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
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
      ),
    );
  }
}

class ContentCard extends StatefulWidget {
  final String title;
  final String imagePath;
  final bool isWebMode;
  final VoidCallback onTap;

  const ContentCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.isWebMode,
    required this.onTap,
  });

  @override
  State<ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<ContentCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform:
              _isHovered
                  ? (Matrix4.identity()..scale(1.05))
                  : Matrix4.identity(),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color:
                    _isHovered
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                spreadRadius: _isHovered ? 2 : 0,
                blurRadius: _isHovered ? 15 : 8,
                offset: const Offset(0, 4),
              ),
            ],
            border:
                _isHovered
                    ? Border.all(color: Colors.blue.withOpacity(0.5), width: 2)
                    : Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Image.asset(widget.imagePath, fit: BoxFit.contain),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27445D).withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: widget.isWebMode ? 16 : 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF27445D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
