// lib/tutorial/tutorial_page.dart

import 'package:flutter/material.dart';
import 'pdf_viewer_page.dart';  // Import PDF viewer page
import '../header_widget.dart'; // Import custom header widget
import '../dashboard.dart'; // ✅ Import dashboard page

class TutorialPage extends StatelessWidget {
  TutorialPage({Key? key}) : super(key: key);

  final List<_TutorialData> tutorials = [
    _TutorialData("Google Meet", "assets/images/practice/gmeet.png"),
    _TutorialData("Zoom", "assets/images/practice/zoom.png"),
    _TutorialData("Gmail", "assets/images/practice/gmail.png"),
    _TutorialData("Viber", "assets/images/practice/viber.png"),
    _TutorialData("WhatsApp", "assets/images/practice/whatsapp.png"),
    _TutorialData(
      "CLIQQ",
      "assets/images/practice/cliqq.png",
      pdfPath: "assets/pdf/tutorial1.pdf",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderWidget(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tutorials',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color(0xFF27445D),
              ),
            ),
            const SizedBox(height: 20),
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
                  ),
                  child: const Text('Progress'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    // ✅ Navigate to DashboardPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DashboardPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27445D),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Dashboard'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: tutorials.map((t) {
                  return GestureDetector(
                    onTap: () {
                      if (t.label == "Google Meet") {
                        Navigator.pushNamed(context, '/googlemeet');
                      } else if (t.pdfPath.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PDFViewerPage(
                              title: t.label,
                              pdfAssetPath: t.pdfPath,
                            ),
                          ),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Coming Soon'),
                            content: Text(
                              'The tutorial for ${t.label} is not yet available.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Image.asset(t.imagePath, fit: BoxFit.contain),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialData {
  final String label;
  final String imagePath;
  final String pdfPath;

  _TutorialData(this.label, this.imagePath, {this.pdfPath = ""});
}
