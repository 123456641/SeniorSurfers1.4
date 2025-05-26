import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'dashboardsidebar.dart';
import 'providers/font_size_provider.dart';
import 'widgets/scaled_text.dart';

class HomePage1 extends StatefulWidget {
  const HomePage1({super.key});

  @override
  State<HomePage1> createState() => _HomePage1State();
}

class _HomePage1State extends State<HomePage1> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> featuredTutorials = [];
  bool isLoadingTutorials = false;

  // Map platform names to their image paths
  final Map<String, String> platformImages = {
    'google_meet': 'assets/images/practice/gmeet.png',
    'zoom': 'assets/images/practice/zoom.png',
    'gmail': 'assets/images/practice/gmail.png',
    'viber': 'assets/images/practice/viber.png',
    'whatsapp': 'assets/images/practice/whatsapp.png',
    'cliqq': 'assets/images/practice/cliqq.png',
  };

  final List<QuickAction> quickActions = [
    QuickAction(
      title: "Start Learning",
      description: "Begin with easy tutorials",
      icon: Icons.school,
      color: Colors.blue.shade700,
      route: "/tutorials",
    ),
    QuickAction(
      title: "Tech Glossary",
      description: "Learn technology terms",
      icon: Icons.book,
      color: Colors.green.shade700,
      route: "/glossary",
    ),
    QuickAction(
      title: "Play Games",
      description: "Fun learning activities",
      icon: Icons.games,
      color: Colors.orange.shade700,
      route: "/games",
    ),
    QuickAction(
      title: "Join Community",
      description: "Connect with others",
      icon: Icons.people,
      color: Colors.purple.shade700,
      route: "/community",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchFeaturedTutorials();
  }

  Future<void> _fetchFeaturedTutorials() async {
    setState(() {
      isLoadingTutorials = true;
    });

    try {
      final response = await _supabase
          .from('tutorial_files')
          .select()
          .order('uploaded_at', ascending: false)
          .limit(6);

      setState(() {
        featuredTutorials = List<Map<String, dynamic>>.from(response);
        isLoadingTutorials = false;
      });
    } catch (e) {
      print('Error fetching featured tutorials: $e');
      setState(() {
        isLoadingTutorials = false;
      });
    }
  }

  Future<void> _openTutorial(Map<String, dynamic> tutorial) async {
    final fileType = tutorial['file_type'];
    final fileUrl = tutorial['file_url'];

    if (fileType == 'link' || fileType == 'pdf') {
      if (!await launchUrl(
        Uri.parse(fileUrl),
        mode: LaunchMode.externalApplication,
      )) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open tutorial')),
          );
        }
      }
    } else {
      context.go('/tutorials');
    }
  }

  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'google_meet':
        return Colors.green.shade700;
      case 'zoom':
        return Colors.blue.shade700;
      case 'gmail':
        return Colors.red.shade700;
      case 'viber':
        return Colors.purple.shade700;
      case 'whatsapp':
        return Colors.green.shade700;
      case 'cliqq':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _buildTutorialThumbnail(
    Map<String, dynamic> tutorial, {
    double size = 120,
    required FontSizeProvider fontProvider,
  }) {
    final platform = tutorial['platform'] as String;
    final fallbackImagePath =
        platformImages[platform] ?? 'assets/images/practice/document.png';
    final thumbnailUrl = tutorial['thumbnail_url'];
    final scaleFactor = fontProvider.fontSize / 16.0;

    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: thumbnailUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: size * scaleFactor.clamp(0.8, 1.3),
        placeholder:
            (context, url) => Container(
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  color: _getPlatformColor(platform),
                  strokeWidth: 3,
                ),
              ),
            ),
        errorWidget:
            (context, url, error) => Image.asset(
              fallbackImagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: size * scaleFactor.clamp(0.8, 1.3),
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade100,
                  child: Center(
                    child: Icon(
                      Icons.description,
                      size: size * 0.4 * scaleFactor.clamp(0.8, 1.5),
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              },
            ),
      );
    } else {
      return Container(
        width: double.infinity,
        height: size * scaleFactor.clamp(0.8, 1.3),
        color: Colors.grey.shade100,
        child: Center(
          child: Image.asset(
            fallbackImagePath,
            fit: BoxFit.contain,
            width: size * 0.6 * scaleFactor.clamp(0.8, 1.3),
            height: size * 0.6 * scaleFactor.clamp(0.8, 1.3),
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.description,
                size: size * 0.4 * scaleFactor.clamp(0.8, 1.5),
                color: Colors.grey.shade600,
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return SidebarLayoutWrapper(
          currentPage: '/home',
          pageTitle: 'Welcome Home',
          child: _buildHomeContent(context, fontProvider),
        );
      },
    );
  }

  Widget _buildHomeContent(
    BuildContext context,
    FontSizeProvider fontProvider,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth < 1024;
        final scaleFactor = fontProvider.fontSize / 16.0;

        return Container(
          color: Colors.white, // HIGH CONTRAST: Pure white background
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : (isTablet ? 24 : 32),
              vertical: 16,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header
                  _buildWelcomeHeader(context, isMobile, fontProvider),

                  SizedBox(
                    height: (isMobile ? 24 : 32) * scaleFactor.clamp(0.8, 1.2),
                  ),

                  // Quick Actions
                  _buildQuickActions(context, isMobile, isTablet, fontProvider),

                  SizedBox(
                    height: (isMobile ? 32 : 40) * scaleFactor.clamp(0.8, 1.2),
                  ),

                  // Featured Tutorials
                  _buildFeaturedTutorials(
                    context,
                    isMobile,
                    isTablet,
                    fontProvider,
                  ),

                  SizedBox(
                    height: (isMobile ? 32 : 40) * scaleFactor.clamp(0.8, 1.2),
                  ),

                  // Daily Tips
                  _buildDailyTip(context, isMobile, fontProvider),

                  SizedBox(
                    height: (isMobile ? 24 : 32) * scaleFactor.clamp(0.8, 1.2),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader(
    BuildContext context,
    bool isMobile,
    FontSizeProvider fontProvider,
  ) {
    final scaleFactor = fontProvider.fontSize / 16.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        (isMobile ? 24 : 32) * scaleFactor.clamp(0.8, 1.3),
      ),
      decoration: BoxDecoration(
        // HIGH CONTRAST: Dark blue background with white text
        color: const Color(0xFF27445D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF27445D), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.waving_hand,
                color: Colors.amber.shade400,
                size: (isMobile ? 36 : 44) * scaleFactor.clamp(0.8, 1.5),
              ),
              SizedBox(width: 16 * scaleFactor.clamp(0.8, 1.2)),
              Expanded(
                child: Text(
                  "Welcome Back!",
                  style: TextStyle(
                    fontSize: (isMobile ? 28 : 36) * scaleFactor,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // HIGH CONTRAST: Pure white text
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * scaleFactor.clamp(0.8, 1.2)),
          Text(
            "Ready to learn something new today? Explore our latest tutorials and connect with your community.",
            style: TextStyle(
              fontSize: (isMobile ? 18 : 20) * scaleFactor,
              color: Colors.white, // HIGH CONTRAST: Pure white text
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 24 * scaleFactor.clamp(0.8, 1.2)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.go('/tutorials');
              },
              icon: Icon(
                Icons.play_arrow,
                color: const Color(0xFF27445D),
                size: 24 * scaleFactor.clamp(0.8, 1.5),
              ),
              label: Text(
                "Continue Learning",
                style: TextStyle(
                  fontSize: 18 * scaleFactor,
                  color: const Color(
                    0xFF27445D,
                  ), // HIGH CONTRAST: Dark text on white button
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.white, // HIGH CONTRAST: Pure white button
                foregroundColor: const Color(0xFF27445D),
                padding: EdgeInsets.symmetric(
                  horizontal:
                      (isMobile ? 24 : 32) * scaleFactor.clamp(0.8, 1.3),
                  vertical: (isMobile ? 16 : 20) * scaleFactor.clamp(0.8, 1.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF27445D), width: 2),
                ),
                elevation: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    FontSizeProvider fontProvider,
  ) {
    final scaleFactor = fontProvider.fontSize / 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Start",
          style: TextStyle(
            fontSize: (isMobile ? 24 : 28) * scaleFactor,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 20 * scaleFactor.clamp(0.8, 1.2)),
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount;
            double childAspectRatio;

            if (constraints.maxWidth < 600) {
              crossAxisCount = 2;
              childAspectRatio =
                  0.9; // ADJUSTED: Slightly wider to prevent overflow
            } else if (constraints.maxWidth < 900) {
              crossAxisCount = 3;
              childAspectRatio = 1.0; // ADJUSTED: More balanced proportions
            } else {
              crossAxisCount = 4;
              childAspectRatio = 1.1; // ADJUSTED: Wider for desktop
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing:
                    (isMobile ? 12 : 16) * scaleFactor.clamp(0.8, 1.2),
                mainAxisSpacing:
                    (isMobile ? 12 : 16) * scaleFactor.clamp(0.8, 1.2),
                childAspectRatio: childAspectRatio,
              ),
              itemCount: quickActions.length,
              itemBuilder: (context, index) {
                final action = quickActions[index];
                return _buildQuickActionCard(action, isMobile, fontProvider);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    QuickAction action,
    bool isMobile,
    FontSizeProvider fontProvider,
  ) {
    final scaleFactor = fontProvider.fontSize / 16.0;

    // LARGER TITLE TEXT: No description means more space for title
    final maxTitleSize = isMobile ? 24.0 : 26.0; // LARGER: More space available
    final titleFontSize = ((isMobile ? 20 : 22) * scaleFactor).clamp(
      16.0,
      maxTitleSize,
    );

    return Card(
      elevation: 8,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300, width: 2),
      ),
      child: InkWell(
        onTap: () {
          context.go(action.route);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(
            (isMobile ? 20 : 24) *
                scaleFactor.clamp(
                  0.9,
                  1.3,
                ), // MORE PADDING: More comfortable spacing
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(
                  (isMobile ? 14 : 18) *
                      scaleFactor.clamp(
                        0.8,
                        1.3,
                      ), // LARGER: More space for icon
                ),
                decoration: BoxDecoration(
                  color: action.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: action.color, width: 2),
                ),
                child: Icon(
                  action.icon,
                  color: Colors.white,
                  size:
                      (isMobile ? 32 : 36) *
                      scaleFactor.clamp(0.8, 1.4), // LARGER: Bigger icon
                ),
              ),
              SizedBox(
                height:
                    (isMobile ? 16 : 20) *
                    scaleFactor.clamp(
                      0.8,
                      1.2,
                    ), // MORE SPACE: Between icon and title
              ),
              // LARGER TITLE: No description means more space and bigger text
              Container(
                width: double.infinity,
                child: Text(
                  action.title,
                  style: TextStyle(
                    fontSize:
                        titleFontSize, // LARGER: Bigger, more readable text
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.3, // BETTER: More comfortable line height
                  ),
                  textAlign: TextAlign.center,
                  maxLines:
                      3, // MORE LINES: Allow up to 3 lines for longer text
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // REMOVED: Description completely removed
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedTutorials(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    FontSizeProvider fontProvider,
  ) {
    final scaleFactor = fontProvider.fontSize / 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                "Featured for You",
                style: TextStyle(
                  fontSize: (isMobile ? 24 : 28) * scaleFactor,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // HIGH CONTRAST: Pure black text
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                context.go('/tutorials');
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Text(
                "See All",
                style: TextStyle(
                  fontSize: 16 * scaleFactor,
                  color: Colors.black, // HIGH CONTRAST: Pure black text
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 20 * scaleFactor.clamp(0.8, 1.2)),
        if (isLoadingTutorials)
          Container(
            height: (isMobile ? 280 : 320) * scaleFactor.clamp(0.9, 1.2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF27445D),
                strokeWidth: 4,
              ),
            ),
          )
        else if (featuredTutorials.isEmpty)
          Container(
            height: (isMobile ? 280 : 320) * scaleFactor.clamp(0.9, 1.2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 80 * scaleFactor.clamp(0.8, 1.5),
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(height: 20 * scaleFactor.clamp(0.8, 1.2)),
                  Text(
                    "No tutorials available yet",
                    style: TextStyle(
                      fontSize: (isMobile ? 18 : 20) * scaleFactor,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // HIGH CONTRAST: Pure black text
                    ),
                  ),
                  SizedBox(height: 10 * scaleFactor.clamp(0.8, 1.2)),
                  Text(
                    "Check back later for new content!",
                    style: TextStyle(
                      fontSize: (isMobile ? 16 : 18) * scaleFactor,
                      color: Colors.black87, // HIGH CONTRAST: Very dark text
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: (isMobile ? 280 : 320) * scaleFactor.clamp(0.9, 1.3),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(right: isMobile ? 16 : 0),
              itemCount: featuredTutorials.length,
              itemBuilder: (context, index) {
                final tutorial = featuredTutorials[index];
                return Container(
                  width: (isMobile ? 280 : 320) * scaleFactor.clamp(0.9, 1.2),
                  margin: EdgeInsets.only(
                    right: (isMobile ? 16 : 20) * scaleFactor.clamp(0.8, 1.2),
                  ),
                  child: _buildTutorialCard(tutorial, isMobile, fontProvider),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTutorialCard(
    Map<String, dynamic> tutorial,
    bool isMobile,
    FontSizeProvider fontProvider,
  ) {
    final scaleFactor = fontProvider.fontSize / 16.0;

    return Card(
      elevation: 8,
      color: Colors.white, // HIGH CONTRAST: Pure white background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300, width: 2),
      ),
      child: InkWell(
        onTap: () => _openTutorial(tutorial),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tutorial Image/Thumbnail
            Container(
              height: (isMobile ? 140 : 160) * scaleFactor.clamp(0.8, 1.3),
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  // Tutorial thumbnail
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: _buildTutorialThumbnail(
                      tutorial,
                      size: isMobile ? 140 : 160,
                      fontProvider: fontProvider,
                    ),
                  ),
                  // Platform badge
                  Positioned(
                    top: 12 * scaleFactor.clamp(0.8, 1.2),
                    left: 12 * scaleFactor.clamp(0.8, 1.2),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10 * scaleFactor.clamp(0.8, 1.2),
                        vertical: 6 * scaleFactor.clamp(0.8, 1.2),
                      ),
                      decoration: BoxDecoration(
                        color: _getPlatformColor(tutorial['platform']),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        tutorial['platform']
                            .toString()
                            .replaceAll('_', ' ')
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: (isMobile ? 11 : 12) * scaleFactor,
                          fontWeight: FontWeight.bold,
                          color:
                              Colors
                                  .white, // HIGH CONTRAST: White text on colored background
                        ),
                      ),
                    ),
                  ),
                  // File type indicator
                  Positioned(
                    top: 12 * scaleFactor.clamp(0.8, 1.2),
                    right: 12 * scaleFactor.clamp(0.8, 1.2),
                    child: Container(
                      padding: EdgeInsets.all(8 * scaleFactor.clamp(0.8, 1.2)),
                      decoration: BoxDecoration(
                        color:
                            Colors
                                .black, // HIGH CONTRAST: Pure black background
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        tutorial['file_type'] == 'pdf'
                            ? Icons.picture_as_pdf
                            : Icons.open_in_new,
                        size: 18 * scaleFactor.clamp(0.8, 1.3),
                        color: Colors.white, // HIGH CONTRAST: White icon
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tutorial Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(
                  (isMobile ? 16 : 20) * scaleFactor.clamp(0.8, 1.3),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tutorial['title'] ?? tutorial['file_name'] ?? 'Untitled',
                      style: TextStyle(
                        fontSize: (isMobile ? 17 : 19) * scaleFactor,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // HIGH CONTRAST: Pure black text
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8 * scaleFactor.clamp(0.8, 1.2)),
                    if (tutorial['description'] != null &&
                        tutorial['description'].toString().isNotEmpty)
                      Expanded(
                        child: Text(
                          tutorial['description'].toString(),
                          style: TextStyle(
                            fontSize: (isMobile ? 15 : 16) * scaleFactor,
                            color:
                                Colors.black87, // HIGH CONTRAST: Very dark text
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      Expanded(
                        child: Text(
                          "Learn ${tutorial['platform'].toString().replaceAll('_', ' ')} with this step-by-step guide",
                          style: TextStyle(
                            fontSize: (isMobile ? 15 : 16) * scaleFactor,
                            color:
                                Colors.black87, // HIGH CONTRAST: Very dark text
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    SizedBox(height: 12 * scaleFactor.clamp(0.8, 1.2)),
                    Row(
                      children: [
                        Icon(
                          Icons.play_circle,
                          size: 20 * scaleFactor.clamp(0.8, 1.3),
                          color: _getPlatformColor(tutorial['platform']),
                        ),
                        SizedBox(width: 6 * scaleFactor.clamp(0.8, 1.2)),
                        Text(
                          tutorial['file_type'] == 'pdf'
                              ? 'PDF Guide'
                              : 'Interactive',
                          style: TextStyle(
                            fontSize: 14 * scaleFactor,
                            color: _getPlatformColor(tutorial['platform']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward,
                          size: 20 * scaleFactor.clamp(0.8, 1.3),
                          color: Colors.black, // HIGH CONTRAST: Black arrow
                        ),
                      ],
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

  Widget _buildDailyTip(
    BuildContext context,
    bool isMobile,
    FontSizeProvider fontProvider,
  ) {
    final scaleFactor = fontProvider.fontSize / 16.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        (isMobile ? 24 : 28) * scaleFactor.clamp(0.8, 1.3),
      ),
      decoration: BoxDecoration(
        color: Colors.amber.shade50, // HIGH CONTRAST: Light amber background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.shade600,
          width: 3, // HIGH CONTRAST: Thicker border
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.shade200.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8 * scaleFactor.clamp(0.8, 1.2)),
                decoration: BoxDecoration(
                  color:
                      Colors
                          .amber
                          .shade600, // HIGH CONTRAST: Solid amber background
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade700, width: 2),
                ),
                child: Icon(
                  Icons.lightbulb,
                  color: Colors.white, // HIGH CONTRAST: White icon
                  size: (isMobile ? 28 : 32) * scaleFactor.clamp(0.8, 1.5),
                ),
              ),
              SizedBox(width: 16 * scaleFactor.clamp(0.8, 1.2)),
              Flexible(
                child: Text(
                  "Today's Tip",
                  style: TextStyle(
                    fontSize: (isMobile ? 22 : 24) * scaleFactor,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // HIGH CONTRAST: Pure black text
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * scaleFactor.clamp(0.8, 1.2)),
          Text(
            "Did you know you can make text larger throughout this entire app? Go to Settings and adjust the 'Text Size' slider to make reading easier on your eyes!",
            style: TextStyle(
              fontSize: (isMobile ? 17 : 18) * scaleFactor,
              color: Colors.black, // HIGH CONTRAST: Pure black text
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Data Models
class QuickAction {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String route;

  QuickAction({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
  });
}
