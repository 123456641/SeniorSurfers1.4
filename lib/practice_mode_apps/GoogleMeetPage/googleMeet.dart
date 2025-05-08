import 'package:flutter/material.dart';
import 'package:device_frame/device_frame.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'gmeetDashboard.dart';

class GoogleMeetPage extends StatelessWidget {
  const GoogleMeetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DeviceFrame(
      device: Devices.android.samsungGalaxyS20,
      isFrameVisible: true,
      screen: Builder(
        builder: (context) {
          final size = MediaQuery.of(context).size;

          return Scaffold(
            backgroundColor: const Color(0xFF140f0e),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),
                      const Text(
                        "Welcome to Google Meet",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFFd6c6c3),
                          height: 1.25,
                          fontFamily: 'ProductSans',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Make video calls to friends and family or create and join meetings, all in one app",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFFd6c6c3),
                          height: 1.55,
                          fontFamily: 'ProductSans',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            "https://storage.googleapis.com/a1aa/image/d9c28a59-d11f-4b6a-e0e5-abf0c2f0f79a.jpg",
                            width: size.width * 0.8, // 80% of screen width
                            height: size.width * 0.6, // proportionally adjusted
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircleAvatar(radius: 6, backgroundColor: Colors.pinkAccent),
                          SizedBox(width: 8),
                          CircleAvatar(radius: 6, backgroundColor: Color(0xFF6f3a3a)),
                          SizedBox(width: 8),
                          CircleAvatar(radius: 6, backgroundColor: Color(0xFF6f3a3a)),
                        ],
                      ),
                      const SizedBox(height: 48),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1f1918),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: Image.network(
                                "https://storage.googleapis.com/a1aa/image/68702d7e-75fd-4cd2-3109-080082b4fb35.jpg",
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Boluntate, John Christian J",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "202310530@gordoncollege.edu.ph",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFFb9a9a7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(FontAwesomeIcons.chevronDown, color: Color(0xFFb9a9a7)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink[200],
                          foregroundColor: const Color(0xFF140f0e),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const gmeetDashboard()),
                          );
                        },
                        child: const Text("Continue as Boluntate,"),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Use Meet without an account",
                        style: TextStyle(color: Colors.pinkAccent, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                color: Colors.pinkAccent,
                                fontSize: 14,
                              ),
                            ),
                            TextSpan(text: ', ', style: TextStyle(color: Colors.pinkAccent)),
                            TextSpan(
                              text: 'Contract summary',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                color: Colors.pinkAccent,
                                fontSize: 14,
                              ),
                            ),
                            TextSpan(text: ' and ', style: TextStyle(color: Colors.pinkAccent)),
                            TextSpan(
                              text: 'Privacy policy',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                color: Colors.pinkAccent,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
