import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/font_size_provider.dart';
import 'dashboardsidebar.dart';

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  State<TutorialPage> createState() => _TutorialPage();
}

class _TutorialPage extends State<TutorialPage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> tutorials = [];
  bool isLoading = true;
  String? selectedPlatform;
  Map<String, dynamic>? selectedTutorial;

  // Tab controller for bookmark categories
  late TabController _tabController;
  int _selectedCategoryIndex = 0;

  // PDF viewing states for mobile
  bool isPdfViewVisible = false;
  String? currentPdfUrl;
  String? currentPdfTitle;
  bool isPdfLoading = false;
  String? pdfFilePath;

  // Map platform names to their image paths
  final Map<String, String> platformImages = {
    'google_meet': 'assets/images/practice/gmeet.png',
    'zoom': 'assets/images/practice/zoom.png',
    'gmail': 'assets/images/practice/gmail.png',
    'viber': 'assets/images/practice/viber.png',
    'whatsapp': 'assets/images/practice/whatsapp.png',
    'cliqq': 'assets/images/practice/cliqq.png',
  };

  // Category definitions for bookmark tabs
  final List<CategoryTab> categories = [
    CategoryTab(title: 'All', key: null, color: const Color(0xFF27445D)),
    CategoryTab(
      title: 'Google Meet',
      key: 'google_meet',
      color: Colors.green.shade700,
    ),
    CategoryTab(title: 'Zoom', key: 'zoom', color: Colors.blue.shade700),
    CategoryTab(title: 'Gmail', key: 'gmail', color: Colors.red.shade700),
    CategoryTab(title: 'Viber', key: 'viber', color: Colors.purple.shade700),
    CategoryTab(
      title: 'WhatsApp',
      key: 'whatsapp',
      color: Colors.green.shade700,
    ),
    CategoryTab(title: 'CliQQ', key: 'cliqq', color: Colors.orange.shade700),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedCategoryIndex = _tabController.index;
          selectedPlatform = categories[_selectedCategoryIndex].key;
        });
        fetchTutorials();
      }
    });
    fetchTutorials();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper method to get font size safely
  double _getFontSize(BuildContext context, {double multiplier = 1.0}) {
    try {
      final fontSizeProvider = Provider.of<FontSizeProvider>(
        context,
        listen: false,
      );
      return fontSizeProvider.fontSize * multiplier;
    } catch (e) {
      // Fallback to default font size if provider not found
      return 16.0 * multiplier;
    }
  }

  // Helper method to build text with safe font size
  Widget _buildText(
    String text,
    BuildContext context, {
    double multiplier = 1.0,
    FontWeight? fontWeight,
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return Text(
      text,
      style: TextStyle(
        fontSize: _getFontSize(context, multiplier: multiplier),
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis, // Default overflow handling
    );
  }

  Future<void> fetchTutorials() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await _supabase
          .from('tutorial_files')
          .select()
          .order('uploaded_at', ascending: false);

      List<Map<String, dynamic>> filteredTutorials = [];
      if (selectedPlatform != null) {
        for (var tutorial in response as List) {
          if (tutorial['platform'] == selectedPlatform) {
            filteredTutorials.add(tutorial);
          }
        }
      } else {
        filteredTutorials = List<Map<String, dynamic>>.from(response);
      }

      setState(() {
        tutorials = filteredTutorials;
        isLoading = false;

        if (selectedTutorial != null) {
          bool tutorialExists = false;
          for (var tutorial in filteredTutorials) {
            if (tutorial['id'] == selectedTutorial!['id']) {
              tutorialExists = true;
              break;
            }
          }
          if (!tutorialExists) {
            selectedTutorial = null;
          }
        }
      });
    } catch (e) {
      print('Error fetching tutorials: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading tutorials: $e')));
      }
    }
  }

  // Mobile-specific PDF handling
  Future<void> _handlePdfFile(String url, String title) async {
    setState(() {
      isPdfLoading = true;
      isPdfViewVisible = true;
      currentPdfTitle = title;
      currentPdfUrl = url;
      pdfFilePath = null;
    });

    await _downloadAndOpenPdfMobile(url);
  }

  Future<void> _downloadAndOpenPdfMobile(String url) async {
    try {
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          pdfFilePath = filePath;
          isPdfLoading = false;
        });
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading PDF: $e');
      setState(() {
        isPdfLoading = false;
        isPdfViewVisible = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load PDF: $e. Opening in external app.'),
            duration: const Duration(seconds: 4),
          ),
        );
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _openTutorial(Map<String, dynamic> tutorial) async {
    setState(() {
      selectedTutorial = tutorial;
    });

    final fileType = tutorial['file_type'];
    final fileUrl = tutorial['file_url'];
    final title = tutorial['title'] ?? tutorial['file_name'] ?? 'Untitled';

    if (fileType == 'link') {
      if (!await launchUrl(
        Uri.parse(fileUrl),
        mode: LaunchMode.externalApplication,
      )) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $fileUrl')),
          );
        }
      }
    } else if (fileType == 'pdf') {
      try {
        final response = await http
            .head(Uri.parse(fileUrl))
            .timeout(const Duration(seconds: 5));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          _handlePdfFile(fileUrl, title);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'PDF URL returned error ${response.statusCode}. Opening in external app.',
                ),
                duration: const Duration(seconds: 4),
              ),
            );
            launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Issue checking PDF URL: $e. Attempting to open anyway.',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
          _handlePdfFile(fileUrl, title);
        }
      }
    } else {
      if (!await launchUrl(
        Uri.parse(fileUrl),
        mode: LaunchMode.externalApplication,
      )) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open file: $fileUrl')),
          );
        }
      }
    }
  }

  // FIXED: Compact special tutorial section with smaller size
  Widget _buildSpecialTutorials() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ), // SMALLER: Reduced margins
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ), // SMALLER: Reduced border radius
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, // SMALLER: Reduced blur
            offset: const Offset(0, 2), // SMALLER: Reduced offset
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          12,
        ), // SMALLER: Reduced padding from 20 to 12
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SMALLER: Compact header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(
                    8,
                  ), // SMALLER: Reduced padding from 12 to 8
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(
                      8,
                    ), // SMALLER: Reduced radius
                  ),
                  child: Icon(
                    Icons.stars,
                    color: Colors.green.shade700,
                    size: 20, // SMALLER: Reduced from 28 to 20
                  ),
                ),
                const SizedBox(width: 12), // SMALLER: Reduced from 16 to 12
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildText(
                        'Interactive Tutorials',
                        context,
                        multiplier: 1.1, // SMALLER: Reduced from 1.3 to 1.1
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF27445D),
                        maxLines: 1, // SMALLER: Reduced from 2 to 1
                      ),
                      const SizedBox(height: 2), // SMALLER: Reduced from 4 to 2
                      _buildText(
                        'Step-by-step guided tutorials with audio',
                        context,
                        multiplier: 0.8, // SMALLER: Reduced from 0.9 to 0.8
                        color: Colors.grey.shade600,
                        maxLines: 1, // SMALLER: Reduced from 2 to 1
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), // SMALLER: Reduced from 20 to 12
            // SMALLER: Compact Google Meet Installation Tutorial Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  10,
                ), // SMALLER: Reduced radius
                border: Border.all(color: Colors.green.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 3, // SMALLER: Reduced blur
                    offset: const Offset(0, 1), // SMALLER: Reduced offset
                  ),
                ],
              ),
              child: InkWell(
                onTap: () {
                  context.go('/gmeet-tutorial');
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(
                    12,
                  ), // SMALLER: Reduced from 16 to 12
                  child: Row(
                    children: [
                      // SMALLER: Compact leading icon
                      Container(
                        padding: const EdgeInsets.all(
                          8,
                        ), // SMALLER: Reduced padding
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          'assets/images/practice/gmeet.png',
                          width: 24, // SMALLER: Reduced from 32 to 24
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.video_call,
                              color: Colors.green.shade700,
                              size: 24, // SMALLER: Reduced from 32 to 24
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ), // SMALLER: Reduced from 16 to 12
                      // SMALLER: Compact content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildText(
                              'How to Install Google Meet',
                              context,
                              multiplier:
                                  1.0, // SMALLER: Reduced from 1.1 to 1.0
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF27445D),
                              maxLines: 1, // SMALLER: Reduced from 2 to 1
                            ),
                            const SizedBox(
                              height: 4,
                            ), // SMALLER: Reduced from 8 to 4
                            _buildText(
                              'Interactive guide with audio',
                              context,
                              multiplier:
                                  0.8, // SMALLER: Reduced from 0.9 to 0.8
                              color: Colors.grey.shade600,
                              maxLines: 1, // SMALLER: Reduced from 2 to 1
                            ),
                            const SizedBox(
                              height: 6,
                            ), // SMALLER: Reduced from 8 to 6
                            // SMALLER: Compact feature badges
                            SingleChildScrollView(
                              // SMALLER: Add scroll for overflow
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                // SMALLER: Use Row instead of Wrap for more compact layout
                                children: [
                                  _buildCompactFeatureBadge(
                                    '📱 Setup',
                                    Colors.blue,
                                  ),
                                  const SizedBox(width: 6),
                                  _buildCompactFeatureBadge(
                                    '🔊 Audio',
                                    Colors.green,
                                  ),
                                  const SizedBox(width: 6),
                                  _buildCompactFeatureBadge(
                                    '👥 Senior',
                                    Colors.purple,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8), // SMALLER: Reduced from 16 to 8
                      // SMALLER: Compact trailing icon
                      Container(
                        padding: const EdgeInsets.all(
                          6,
                        ), // SMALLER: Reduced from 8 to 6
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(
                            6,
                          ), // SMALLER: Reduced radius
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 18, // SMALLER: Reduced from 24 to 18
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10), // SMALLER: Reduced from 16 to 10
            // SMALLER: Compact Coming Soon Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(
                10,
              ), // SMALLER: Reduced from 16 to 10
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(
                  8,
                ), // SMALLER: Reduced radius
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.construction,
                    color: Colors.amber.shade700,
                    size: 18, // SMALLER: Reduced from 24 to 18
                  ),
                  const SizedBox(width: 8), // SMALLER: Reduced from 12 to 8
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildText(
                          'More Interactive Tutorials Coming Soon!',
                          context,
                          multiplier: 0.9, // SMALLER: Reduced from 1.0 to 0.9
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade800,
                          maxLines: 1, // SMALLER: Reduced from 2 to 1
                        ),
                        const SizedBox(
                          height: 2,
                        ), // SMALLER: Reduced from 4 to 2
                        _buildText(
                          'Zoom, WhatsApp, and more apps coming',
                          context,
                          multiplier:
                              0.75, // SMALLER: Reduced from 0.85 to 0.75
                          color: Colors.amber.shade700,
                          maxLines: 1, // SMALLER: Reduced from 3 to 1
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SMALLER: Compact feature badge with smaller dimensions
  Widget _buildCompactFeatureBadge(String text, Color color) {
    final HSLColor hslColor = HSLColor.fromColor(color);
    final Color darkColor = hslColor.withLightness(0.3).toColor();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ), // SMALLER: Reduced padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8), // SMALLER: Reduced radius
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: _buildText(
        text,
        context,
        multiplier: 0.65, // SMALLER: Reduced from 0.75 to 0.65
        color: darkColor,
        fontWeight: FontWeight.w500,
        maxLines: 1,
      ),
    );
  }

  // FIXED: Feature badge with constrained width (kept for compatibility)
  Widget _buildFeatureBadge(String text, Color color) {
    final HSLColor hslColor = HSLColor.fromColor(color);
    final Color darkColor = hslColor.withLightness(0.3).toColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: _buildText(
        text,
        context,
        multiplier: 0.75,
        color: darkColor,
        fontWeight: FontWeight.w500,
        maxLines: 1,
      ),
    );
  }

  // FIXED: Bookmark tabs with proper scrolling and responsive sizing
  Widget _buildBookmarkTabs() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        // FIXED: Ensure horizontal scrolling
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          // FIXED: Use Row instead of ListView.builder for better control
          children: List.generate(categories.length, (index) {
            final category = categories[index];
            final isSelected = index == _selectedCategoryIndex;

            // FIXED: Calculate dynamic width based on text length and screen size
            final screenWidth = MediaQuery.of(context).size.width;
            final baseWidth = screenWidth < 600 ? 80.0 : 100.0;
            final textLength = category.title.length;
            final dynamicWidth = (baseWidth + (textLength * 2)).clamp(
              baseWidth,
              baseWidth * 1.5,
            );

            return GestureDetector(
              onTap: () {
                _tabController.animateTo(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: CustomPaint(
                  painter: BookmarkPainter(
                    color: category.color,
                    isSelected: isSelected,
                  ),
                  child: Container(
                    width: dynamicWidth, // FIXED: Use dynamic width
                    height: 44,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(
                      bottom: 8,
                      left: 4,
                      right: 4,
                    ),
                    child: Text(
                      category.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: _getFontSize(
                          context,
                          multiplier: 0.7,
                        ).clamp(10.0, 14.0),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPdfViewer() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF27445D),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              isPdfViewVisible = false;
              pdfFilePath = null;
            });
          },
        ),
        title: Text(
          currentPdfTitle ?? 'PDF Viewer',
          style: TextStyle(
            fontSize: _getFontSize(context),
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () {
              if (currentPdfUrl != null) {
                launchUrl(
                  Uri.parse(currentPdfUrl!),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
            tooltip: 'Open in external app',
          ),
        ],
      ),
      body:
          isPdfLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    _buildText('Loading PDF...', context),
                  ],
                ),
              )
              : pdfFilePath != null
              ? PDFView(
                filePath: pdfFilePath!,
                enableSwipe: true,
                swipeHorizontal: false,
                autoSpacing: true,
                pageFling: true,
                pageSnap: true,
                fitPolicy: FitPolicy.BOTH,
                onError: (error) {
                  print('Error loading PDF: $error');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error loading PDF: $error')),
                  );
                },
                onPageError: (page, error) {
                  print('Error loading page $page: $error');
                },
              )
              : const Center(child: Text('Failed to load PDF')),
    );
  }

  Widget _buildThumbnailImage(
    Map<String, dynamic> tutorial, {
    double size = 64,
  }) {
    final platform = tutorial['platform'] as String;
    final fallbackImagePath =
        platformImages[platform] ?? 'assets/images/practice/document.png';
    final thumbnailUrl = tutorial['thumbnail_url'];

    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: thumbnailUrl,
        fit: BoxFit.cover,
        width: size,
        height: size,
        placeholder:
            (context, url) => Center(
              child: SizedBox(
                width: size / 2,
                height: size / 2,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        errorWidget:
            (context, url, error) => Image.asset(
              fallbackImagePath,
              fit: BoxFit.contain,
              width: size,
              height: size,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.description,
                  size: size * 0.75,
                  color: Colors.grey.shade400,
                );
              },
            ),
      );
    } else {
      return Image.asset(
        fallbackImagePath,
        fit: BoxFit.contain,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.description,
            size: size * 0.75,
            color: Colors.grey.shade400,
          );
        },
      );
    }
  }

  // FIXED: Tutorial detail with proper overflow handling
  Widget _buildTutorialDetail(Map<String, dynamic> tutorial) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Back button for mobile
          if (MediaQuery.of(context).size.width < 600)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    selectedTutorial = null;
                  });
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to List'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: const Color(0xFF27445D),
                ),
              ),
            ),

          // FIXED: Tutorial image with proper constraints
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width:
                    MediaQuery.of(context).size.width *
                    (MediaQuery.of(context).size.width < 600 ? 0.8 : 0.4),
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: _buildThumbnailImage(tutorial, size: 200),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // FIXED: Title with overflow handling
          Center(
            child: ConstrainedBox(
              // FIXED: Add constraints
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: _buildText(
                tutorial['title'] ?? tutorial['file_name'] ?? 'Untitled',
                context,
                multiplier: 1.4,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF27445D),
                textAlign: TextAlign.center,
                maxLines: 3, // FIXED: Add maxLines
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Platform badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getPlatformColor(tutorial['platform']),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _buildText(
                tutorial['platform']
                    .toString()
                    .replaceAll('_', ' ')
                    .toUpperCase(),
                context,
                multiplier: 0.9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                maxLines: 1, // FIXED: Add maxLines
              ),
            ),
          ),
          const SizedBox(height: 20),

          // FIXED: Description with overflow handling
          if (tutorial['description'] != null &&
              tutorial['description'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildText(
                tutorial['description'].toString(),
                context,
                color: Colors.grey[700],
                maxLines: 10, // FIXED: Add reasonable maxLines
              ),
            ),
          const SizedBox(height: 32),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(
                tutorial['file_type'] == 'pdf'
                    ? Icons.picture_as_pdf
                    : Icons.open_in_new,
                color: Colors.white,
              ),
              label: Text(
                tutorial['file_type'] == 'pdf' ? 'Open PDF' : 'Open Tutorial',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _getFontSize(context),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27445D),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final fileType = tutorial['file_type'];
                final fileUrl = tutorial['file_url'];
                final title =
                    tutorial['title'] ?? tutorial['file_name'] ?? 'Untitled';

                if (fileType == 'pdf') {
                  _handlePdfFile(fileUrl, title);
                } else {
                  launchUrl(
                    Uri.parse(fileUrl),
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialsList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Special tutorials section at the top
        _buildSpecialTutorials(),

        // Existing tutorials list
        Expanded(
          child:
              tutorials.isEmpty
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          _buildText(
                            'No tutorials available',
                            context,
                            multiplier: 1.2,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 8),
                          _buildText(
                            selectedPlatform != null
                                ? 'Try selecting a different platform or clear filters'
                                : 'Check back later for new content',
                            context,
                            multiplier: 0.9,
                            color: Colors.grey[500],
                            textAlign: TextAlign.center,
                            maxLines: 2, // FIXED: Add maxLines
                          ),
                        ],
                      ),
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: tutorials.length,
                    itemBuilder: (context, index) {
                      final tutorial = tutorials[index];
                      final bool isSelected =
                          selectedTutorial != null &&
                          tutorial['id'] == selectedTutorial!['id'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          side:
                              isSelected
                                  ? const BorderSide(
                                    color: Color(0xFF27445D),
                                    width: 2,
                                  )
                                  : BorderSide.none,
                        ),
                        child: InkWell(
                          // FIXED: Use InkWell for better tap handling
                          onTap: () => _openTutorial(tutorial),
                          borderRadius: BorderRadius.circular(12.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                // Leading image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _buildThumbnailImage(
                                    tutorial,
                                    size: 56,
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // FIXED: Content with proper overflow handling
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Title
                                      _buildText(
                                        tutorial['title'] ??
                                            tutorial['file_name'] ??
                                            'Untitled',
                                        context,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                        maxLines: 2, // FIXED: Add maxLines
                                      ),
                                      const SizedBox(height: 8),

                                      // Platform badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getPlatformColor(
                                            tutorial['platform'],
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: _getPlatformColor(
                                              tutorial['platform'],
                                            ).withOpacity(0.3),
                                          ),
                                        ),
                                        child: _buildText(
                                          tutorial['platform']
                                              .toString()
                                              .replaceAll('_', ' ')
                                              .toUpperCase(),
                                          context,
                                          multiplier: 0.75,
                                          color: _getPlatformColor(
                                            tutorial['platform'],
                                          ),
                                          fontWeight: FontWeight.bold,
                                          maxLines: 1, // FIXED: Add maxLines
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Trailing icon
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF27445D,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    tutorial['file_type'] == 'pdf'
                                        ? Icons.picture_as_pdf
                                        : Icons.open_in_new,
                                    color: const Color(0xFF27445D),
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
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

  @override
  Widget build(BuildContext context) {
    // If PDF is being viewed, show the PDF viewer directly
    if (isPdfViewVisible) {
      return _buildPdfViewer();
    }

    // Otherwise, use the sidebar wrapper
    return SidebarLayoutWrapper(
      currentPage: '/tutorials',
      pageTitle: 'Tutorials',
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bookmark-style category tabs
        _buildBookmarkTabs(),

        // Main content area
        Expanded(
          child:
              selectedTutorial == null
                  ? _buildTutorialsList()
                  : _buildTutorialDetail(selectedTutorial!),
        ),
      ],
    );
  }
}

// Data model for category tabs
class CategoryTab {
  final String title;
  final String? key;
  final Color color;

  CategoryTab({required this.title, required this.key, required this.color});
}

// Custom painter for bookmark shape
class BookmarkPainter extends CustomPainter {
  final Color color;
  final bool isSelected;

  BookmarkPainter({required this.color, required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final path = Path();

    // Create bookmark shape
    path.moveTo(0, 0); // Top left
    path.lineTo(size.width, 0); // Top right
    path.lineTo(size.width, size.height - 12); // Right side
    path.lineTo(size.width / 2, size.height); // Bottom point
    path.lineTo(0, size.height - 12); // Left side
    path.close();

    // Add shadow for selected state
    if (isSelected) {
      final shadowPaint =
          Paint()
            ..color = Colors.black.withOpacity(0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      final shadowPath = Path.from(path);
      shadowPath.transform(Matrix4.translationValues(0, 2, 0).storage);
      canvas.drawPath(shadowPath, shadowPaint);
    }

    canvas.drawPath(path, paint);

    // Add highlight for selected state
    if (isSelected) {
      final highlightPaint =
          Paint()
            ..color = Colors.white.withOpacity(0.2)
            ..style = PaintingStyle.fill;
      canvas.drawPath(path, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is BookmarkPainter &&
        (oldDelegate.color != color || oldDelegate.isSelected != isSelected);
  }
}
