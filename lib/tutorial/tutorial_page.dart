import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../header_widget.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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

  // PDF viewing states
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

  @override
  void initState() {
    super.initState();
    fetchTutorials();
  }

  Future<void> fetchTutorials() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get all available platforms first (for filter buttons)
      final platforms = await _supabase
          .from('tutorial_files')
          .select('platform')
          .order('platform');

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

  // Function to download and cache PDF files
  Future<void> _downloadAndOpenPdf(String url, String title) async {
    setState(() {
      isPdfLoading = true;
      isPdfViewVisible = true;
      currentPdfTitle = title;
      currentPdfUrl = url;
      pdfFilePath = null;
    });

    try {
      // Get temporary directory to store PDF
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
          // URL is accessible, download and open inline
          _downloadAndOpenPdf(fileUrl, title);
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
          // Try to download and view PDF directly
          _downloadAndOpenPdf(fileUrl, title);
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

  // Build PDF Viewer UI
  Widget _buildPdfViewer() {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      isPdfViewVisible = false;
                      pdfFilePath = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentPdfTitle ?? 'PDF Viewer',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
          ),
          Expanded(
            child:
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
                    : pdfFilePath == null
                    ? const Center(child: Text('Failed to load PDF'))
                    : PDFView(
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
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // "All" filter chip removed
          ...platformImages.keys
              .map(
                (platform) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
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
              )
              .toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're on a wider screen (web mode)
    final bool isWebMode = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: const HeaderWidget(),
      body:
          isPdfViewVisible
              ? _buildPdfViewer() // Show PDF viewer when a PDF is selected
              : Padding(
                // Otherwise show tutorials grid
                padding: EdgeInsets.all(isWebMode ? 24 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Tutorials',
                          style: TextStyle(
                            fontSize: isWebMode ? 48 : 40,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF27445D),
                          ),
                        ),
                        // Bell button (notification icon) removed
                      ],
                    ),
                    SizedBox(height: isWebMode ? 20 : 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/progress');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF27445D),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: isWebMode ? 24 : 16,
                              vertical: isWebMode ? 12 : 8,
                            ),
                            textStyle: TextStyle(fontSize: isWebMode ? 16 : 14),
                          ),
                          child: const Text('Progress'),
                        ),
                        SizedBox(width: isWebMode ? 24 : 16),
                      ],
                    ),
                    SizedBox(height: isWebMode ? 20 : 12),
                    _buildPlatformFilter(),
                    SizedBox(height: isWebMode ? 20 : 12),
                    isLoading
                        ? const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        )
                        : tutorials.isEmpty
                        ? const Expanded(
                          child: Center(
                            child: Text(
                              'No tutorials available',
                              style: TextStyle(
                                fontSize: 18,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        )
                        : Expanded(
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isWebMode ? 3 : 2,
                                  crossAxisSpacing: isWebMode ? 24 : 16,
                                  mainAxisSpacing: isWebMode ? 24 : 16,
                                  childAspectRatio: isWebMode ? 1.2 : 1.0,
                                ),
                            itemCount: tutorials.length,
                            itemBuilder: (context, index) {
                              final tutorial = tutorials[index];
                              final platform = tutorial['platform'] as String;
                              final imagePath =
                                  platformImages[platform] ??
                                  'assets/images/practice/document.png';

                              return GestureDetector(
                                onTap: () => _openTutorial(tutorial),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      isWebMode ? 16 : 12,
                                    ),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: isWebMode ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: isWebMode ? 8 : 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    color: Colors.white,
                                  ),
                                  padding: EdgeInsets.all(isWebMode ? 16 : 12),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Image.asset(
                                          imagePath,
                                          fit: BoxFit.contain,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            // Return a placeholder if image fails to load
                                            return Icon(
                                              Icons.description,
                                              size: 64,
                                              color: Colors.grey.shade400,
                                            );
                                          },
                                        ),
                                      ),
                                      SizedBox(height: isWebMode ? 12 : 8),
                                      Text(
                                        tutorial['title'] ??
                                            tutorial['file_name'] ??
                                            'Untitled',
                                        style: TextStyle(
                                          fontSize: isWebMode ? 18 : 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (tutorial['description'] != null) ...[
                                        SizedBox(height: isWebMode ? 8 : 4),
                                        Text(
                                          tutorial['description'],
                                          style: TextStyle(
                                            fontSize: isWebMode ? 14 : 12,
                                            color: Colors.grey[600],
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      SizedBox(height: isWebMode ? 8 : 4),
                                      Chip(
                                        label: Text(
                                          platform
                                              .replaceAll('_', ' ')
                                              .toUpperCase(),
                                          style: TextStyle(
                                            fontSize: isWebMode ? 12 : 10,
                                          ),
                                        ),
                                        backgroundColor: _getPlatformColor(
                                          platform,
                                        ),
                                        padding: EdgeInsets.zero,
                                        labelPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  ],
                ),
              ),
    );
  }

  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'google_meet':
        return Colors.blue.shade100;
      case 'zoom':
        return Colors.lightBlue.shade100;
      case 'gmail':
        return Colors.red.shade100;
      case 'viber':
        return Colors.purple.shade100;
      case 'whatsapp':
        return Colors.green.shade100;
      case 'cliqq':
        return Colors.orange.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}
