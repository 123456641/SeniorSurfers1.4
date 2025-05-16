import 'package:flutter/material.dart';
import 'header_widget.dart';
import 'dashboard.dart';
import 'practice_mode_apps/GoogleMeetPage/googleMeet.dart';
import 'practice_mode_apps/ZoomPage/zoom.dart';
import 'practice_mode_apps/GmailPage/gmail.dart';
import 'practice_mode_apps/ViberPage/viber.dart';
import 'practice_mode_apps/WhatsappPage/whatsapp.dart';
import 'practice_mode_apps/CliqqPage/cliqq.dart';

class PracticeModePage extends StatelessWidget {
  final List<_AppButtonData> apps = [
    _AppButtonData(
      "Google Meet",
      "assets/images/practice/gmeet.png",
      GoogleMeetPage(),
    ),
    _AppButtonData("Zoom", "assets/images/practice/zoom.png", ZoomPage()),
    _AppButtonData("Gmail", "assets/images/practice/gmail.png", GmailPage()),
    _AppButtonData("Viber", "assets/images/practice/viber.png", ViberPage()),
    _AppButtonData(
      "WhatsApp",
      "assets/images/practice/whatsapp.png",
      WhatsAppPage(),
    ),
    _AppButtonData("CLIQQ", "assets/images/practice/cliqq.png", CliqqPage()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderWidget(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Practice Mode',
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
                  onPressed: () => Navigator.pushNamed(context, '/progress'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27445D),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Progress'),
                ),
                const SizedBox(width: 16),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Adjust column count based on width
                  int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children:
                        apps.map((app) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => app.page),
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Image.asset(
                                    app.imagePath,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  app.label,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
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

class _AppButtonData {
  final String label;
  final String imagePath;
  final Widget page;

  _AppButtonData(this.label, this.imagePath, this.page);
}
