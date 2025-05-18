import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../header_widget.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui' as ui;
import 'dart:html' as html;
import 'package:flutter/services.dart';

class TutorialPage extends StatefulWidget {
  const TutorialPage({Key? key}) : super(key: key);

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> tutorials = [];
  bool isLoading = true;
  String? selectedPlatform;
  Map<String, dynamic>? selectedTutorial;

  // PDF viewing states
  bool isPdfViewVisible = false;
  String? currentPdfUrl;
  String? currentPdfTitle;
  bool isPdfLoading = false;
  String? pdfFilePath;

  // Web PDF viewer
  String? _iframeViewerId;

  // Map platform names to their image paths (fallback images)
  final Map<String, String> platformImages = {
    'google_meet': 'assets/images/practice/gmeet.png',
    'zoom': 'assets/images/practice/zoom.png',
    'gmail': 'assets/images/practice/gmail.png',
    'viber': 'assets/images/practice/viber.png',
    'whatsapp': 'assets/images/practice/whatsapp.png',
    'cliqq': 'assets/images/practice/cliqq.png',
  };

  @override
  void initState() {
    super.initState();
    fetchTutorials();
  }

  @override
  void dispose() {
    // Clean up web resources if needed
    if (kIsWeb && _iframeViewerId != null) {
      // Remove the iframe element when the widget is disposed
      html.Element? element = html.document.getElementById(_iframeViewerId!);
      if (element != null) {
        element.remove();
      }
    }
    super.dispose();
  }

  Future<void> fetchTutorials() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch tutorial files
      final response = await _supabase
          .from('tutorial_files')
          .select()
          .order('uploaded_at', ascending: false);

      // If a platform is selected, filter the results
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

        // Reset selected tutorial if it's no longer in the filtered list
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

  // Function to handle PDF files based on platform
  Future<void> _handlePdfFile(String url, String title) async {
    setState(() {
      isPdfLoading = true;
      isPdfViewVisible = true;
      currentPdfTitle = title;
      currentPdfUrl = url;
      pdfFilePath = null;
    });

    if (kIsWeb) {
      // For web platform, display PDF within the app using iframe
      _displayPdfInWebView(url);
      setState(() {
        isPdfLoading = false;
      });
    } else {
      // For mobile platforms, download and use PDFView
      _downloadAndOpenPdfMobile(url);
    }
  }

  // Create and display a PDF viewer using iframe for web
  void _displayPdfInWebView(String url) {
    // Cleanup any existing iframe
    if (_iframeViewerId != null) {
      html.Element? oldElement = html.document.getElementById(_iframeViewerId!);
      if (oldElement != null) {
        oldElement.remove();
      }
    }

    // Create a unique ID for this iframe
    _iframeViewerId = 'pdf-iframe-${DateTime.now().millisecondsSinceEpoch}';

    // Register the view factory
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(_iframeViewerId!, (int viewId) {
      final iframe =
          html.IFrameElement()
            ..style.border = 'none'
            ..style.height = '100%'
            ..style.width = '100%'
            ..src = url;
      return iframe;
    });

    // The iframe will be used in the build method
    setState(() {
      isPdfLoading = false;
    });
  }

  // Download and open PDF for mobile platforms
  Future<void> _downloadAndOpenPdfMobile(String url) async {
    try {
      // Get temporary directory to store PDF (only for mobile)
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);

      // Download PDF
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Save PDF to file
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
        // Try external app as fallback
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    }
  }

  // Handle opening files or links
  Future<void> _openTutorial(Map<String, dynamic> tutorial) async {
    setState(() {
      selectedTutorial = tutorial;
    });

    final fileType = tutorial['file_type'];
    final fileUrl = tutorial['file_url'];
    final title = tutorial['title'] ?? tutorial['file_name'] ?? 'Untitled';

    if (fileType == 'link') {
      // Handle external links
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
        // Check if PDF URL is accessible before opening
        final response = await http
            .head(Uri.parse(fileUrl))
            .timeout(const Duration(seconds: 5));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          // URL is accessible, open based on platform
          _handlePdfFile(fileUrl, title);
        } else {
          // URL returns an error, show a message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'PDF URL returned error ${response.statusCode}. Opening in external app.',
                ),
                duration: const Duration(seconds: 4),
              ),
            );
            // Try external app as fallback
            launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication);
          }
        }
      } catch (e) {
        // Error checking URL, try to open anyway
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Issue checking PDF URL: $e. Attempting to open anyway.',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
          // Try to handle PDF based on platform
          _handlePdfFile(fileUrl, title);
        }
      }
    } else {
      // For other file types, open in browser/external app
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

  // Build PDF Viewer UI - Now maximized to full screen
  Widget _buildPdfViewer() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              isPdfViewVisible = false;
              pdfFilePath = null;
              // Clean up web resources if needed
              if (kIsWeb && _iframeViewerId != null) {
                html.Element? element = html.document.getElementById(
                  _iframeViewerId!,
                );
                if (element != null) {
                  element.remove();
                }
                _iframeViewerId = null;
              }
            });
          },
        ),
        title: Text(
          currentPdfTitle ?? 'PDF Viewer',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading PDF...'),
                  ],
                ),
              )
              : kIsWeb && _iframeViewerId != null
              ? HtmlElementView(viewType: _iframeViewerId!)
              : !kIsWeb && pdfFilePath != null
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

  // Build thumbnail image for tutorial
  Widget _buildThumbnailImage(
    Map<String, dynamic> tutorial, {
    double size = 64,
  }) {
    final platform = tutorial['platform'] as String;
    final fallbackImagePath =
        platformImages[platform] ?? 'assets/images/practice/document.png';
    final thumbnailUrl = tutorial['thumbnail_url'];

    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      // Use cached network image for thumbnails to improve performance
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
      // Use platform-specific fallback image
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

  // Build the sidebar for platform selection and tutorial list
  Widget _buildSidebar(bool isWebMode) {
    return Container(
      width: isWebMode ? 300 : 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(1, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Platform',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF27445D),
              ),
            ),
          ),
          // Platform filter buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                // All platforms filter
                FilterChip(
                  label: const Text('ALL'),
                  selected: selectedPlatform == null,
                  onSelected: (selected) {
                    setState(() {
                      selectedPlatform = selected ? null : selectedPlatform;
                    });
                    fetchTutorials();
                  },
                ),
                // Platform specific filters
                ...platformImages.keys.map(
                  (platform) => FilterChip(
                    label: Text(platform.replaceAll('_', ' ').toUpperCase()),
                    selected: selectedPlatform == platform,
                    onSelected: (selected) {
                      setState(() {
                        selectedPlatform = selected ? platform : null;
                      });
                      fetchTutorials();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Tutorials',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF27445D),
              ),
            ),
          ),
          // Tutorial list
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : tutorials.isEmpty
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No tutorials available',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                    : ListView.builder(
                      itemCount: tutorials.length,
                      itemBuilder: (context, index) {
                        final tutorial = tutorials[index];
                        final bool isSelected =
                            selectedTutorial != null &&
                            tutorial['id'] == selectedTutorial!['id'];

                        return Container(
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Colors.blue.withOpacity(0.1)
                                    : null,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                          ),
                          child: ListTile(
                            leading: _buildThumbnailImage(tutorial, size: 36),
                            title: Text(
                              tutorial['title'] ??
                                  tutorial['file_name'] ??
                                  'Untitled',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              tutorial['platform']
                                  .toString()
                                  .replaceAll('_', ' ')
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getPlatformColor(tutorial['platform']),
                              ),
                            ),
                            dense: true,
                            onTap: () => _openTutorial(tutorial),
                            selected: isSelected,
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  // Build the main content area where tutorial details will be displayed
  Widget _buildMainContent(bool isWebMode) {
    if (selectedTutorial == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a tutorial from the sidebar',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // Display selected tutorial details
    final tutorial = selectedTutorial!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: isWebMode ? 200 : 150,
                  height: isWebMode ? 150 : 120,
                  child: _buildThumbnailImage(
                    tutorial,
                    size: isWebMode ? 200 : 150,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tutorial['title'] ?? tutorial['file_name'] ?? 'Untitled',
                      style: TextStyle(
                        fontSize: isWebMode ? 24 : 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF27445D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPlatformColor(tutorial['platform']),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        tutorial['platform']
                            .toString()
                            .replaceAll('_', ' ')
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (tutorial['description'] != null &&
                        tutorial['description'].toString().isNotEmpty)
                      Text(
                        tutorial['description'].toString(),
                        style: TextStyle(fontSize: 16, height: 1.5),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: Icon(
              tutorial['file_type'] == 'pdf'
                  ? Icons.picture_as_pdf
                  : Icons.open_in_new,
              color: Colors.white,
            ),
            label: Text(
              tutorial['file_type'] == 'pdf' ? 'Open PDF' : 'Open Tutorial',
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27445D),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
            onPressed: () {
              // Use the existing file opening logic
              final fileType = tutorial['file_type'];
              final fileUrl = tutorial['file_url'];
              final title =
                  tutorial['title'] ?? tutorial['file_name'] ?? 'Untitled';

              if (fileType == 'pdf') {
                // Use our PDF viewing mechanism for both web and mobile
                _handlePdfFile(fileUrl, title);
              } else {
                launchUrl(
                  Uri.parse(fileUrl),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If PDF viewer is visible, display it in fullscreen
    if (isPdfViewVisible) {
      return _buildPdfViewer();
    }

    // Check if we're on a wider screen (web mode)
    final bool isWebMode = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: const HeaderWidget(),
      body: Column(
        children: [
          // Title bar (Progress button removed)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  'Tutorials',
                  style: TextStyle(
                    fontSize: isWebMode ? 32 : 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF27445D),
                  ),
                ),
              ],
            ),
          ),
          // Main content with sidebar and tutorial display
          Expanded(
            child: Row(
              children: [
                // Left sidebar
                _buildSidebar(isWebMode),
                // Right content area
                Expanded(
                  child: Container(
                    color: Colors.grey.shade50,
                    child: _buildMainContent(isWebMode),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'google_meet':
        return Colors.blue.shade400;
      case 'zoom':
        return Colors.lightBlue.shade400;
      case 'gmail':
        return Colors.red.shade400;
      case 'viber':
        return Colors.purple.shade400;
      case 'whatsapp':
        return Colors.green.shade400;
      case 'cliqq':
        return Colors.orange.shade400;
      default:
        return Colors.grey.shade400;
    }
  }
}
