import 'package:flutter/material.dart';
import '../header_widget.dart'; // Your custom header widget
import 'pdf_viewer_page.dart'; // Syncfusion PDF viewer page

class GoogleMeetTutorialPage extends StatelessWidget {
  final Alignment imageAlignment; // New property to control the image position within each step

  const GoogleMeetTutorialPage({super.key, this.imageAlignment = Alignment.centerLeft}); // Default alignment to left

  final List<Map<String, String>> steps = const [
    {
      "description": "Learn how to download the Google Meet app from the Play Store or App Store.",
      "image": "assets/pdf/tutorial1.png",
      "pdf": "assets/pdf/tutorial1.pdf",
    },
    {
      "description": "Install Google Meet on your phone for easy access to meetings.",
      "image": "assets/images/practice/step2_cover.png",
      "pdf": "assets/pdf/tutorial2.pdf",
    },
    {
      "description": "Sign in to Google Meet using your Google account to get started.",
      "image": "assets/images/practice/step3_cover.png",
      "pdf": "assets/pdf/tutorial3.pdf",
    },
    {
      "description": "Learn how to join a meeting using a code.",
      "image": "assets/images/practice/step4_cover.png",
      "pdf": "assets/pdf/tutorial4.pdf",
    },
  ];

  void _showInstructionalMaterial(BuildContext context, String pdfPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerPage(
          title: 'Google Meet Tutorial',
          pdfAssetPath: pdfPath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderWidget(
        title: 'Senior Surfers',
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Google Meet',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color(0xFF27445D),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Follow the steps below to learn how to use Google Meet effectively.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: GestureDetector(
                      onTap: () {
                        _showInstructionalMaterial(context, step['pdf']!);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/pdf/pdfbg.png'), // Background image for the container
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: imageAlignment, // Left-aligned images
                              child: Image.asset(
                                step['image']!,
                                width: 338, // Smaller width for the image
                                height: 203, // Smaller height for the image
                                fit: BoxFit.cover, // Ensure the image is covered inside the given dimensions
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Color(0xFFF6FBFF), // Set background color
                                borderRadius: BorderRadius.circular(30), // Oval shape
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 30.0), // 25px left padding
                                child: Text(
                                  step['description']!,
                                  style: const TextStyle(fontSize: 16, color: Colors.black),
                                ),
                              ),
                            )
                          ],
                        ),
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
}
