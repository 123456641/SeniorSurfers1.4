import 'package:flutter/material.dart';
import 'package:device_frame/device_frame.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'gmeetDashboard.dart';

class GoogleMeetSignIn1 extends StatelessWidget {
  const GoogleMeetSignIn1({super.key});

  @override
  Widget build(BuildContext context) {
    return DeviceFrame(
      device: Devices.android.samsungGalaxyS20,
      isFrameVisible: true,
      screen: Scaffold(
        backgroundColor: const Color(0xFF140f0e),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Welcome to Google Meet",
                    style: TextStyle(
                      fontSize: 26, // Smaller font
                      fontWeight: FontWeight.normal,
                      color: Color(0xFFd6c6c3),
                      height: 1.2,
                      fontFamily: 'ProductSans',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Make video calls to friends and family or create and join meetings, all in one app",
                    style: TextStyle(
                      fontSize: 15, // Smaller font
                      fontWeight: FontWeight.normal,
                      color: Color(0xFFd6c6c3),
                      height: 1.4,
                      fontFamily: 'ProductSans',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Image with fallback
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.75,
                      height: MediaQuery.of(context).size.width * 0.55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey[800],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          "https://storage.googleapis.com/a1aa/image/d9c28a59-d11f-4b6a-e0e5-abf0c2f0f79a.jpg",
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image,
                              color: Colors.white54,
                              size: 48,
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircleAvatar(
                        radius: 5,
                        backgroundColor: Colors.pinkAccent,
                      ),
                      SizedBox(width: 8),
                      CircleAvatar(
                        radius: 5,
                        backgroundColor: Color(0xFF6f3a3a),
                      ),
                      SizedBox(width: 8),
                      CircleAvatar(
                        radius: 5,
                        backgroundColor: Color(0xFF6f3a3a),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1f1918),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        // Profile image with fallback
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Image.network(
                            "https://storage.googleapis.com/a1aa/image/68702d7e-75fd-4cd2-3109-080082b4fb35.jpg",
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 36,
                                height: 36,
                                color: Colors.grey[700],
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Boluntate, John Christian J",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2),
                              Text(
                                "202310530@gordoncollege.edu.ph",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFb9a9a7),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          FontAwesomeIcons.chevronDown,
                          color: Color(0xFFb9a9a7),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink[200],
                      foregroundColor: const Color(0xFF140f0e),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      textStyle: const TextStyle(fontSize: 15),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GmeetDashboard1(),
                        ),
                      );
                    },
                    child: const Text("Continue as Boluntate,"),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Use Meet without an account",
                    style: TextStyle(color: Colors.pinkAccent, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Properly handle the legal text to fit
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.pinkAccent,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text: ', ',
                            style: TextStyle(color: Colors.pinkAccent),
                          ),
                          TextSpan(
                            text: 'Contract summary',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.pinkAccent,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text: ' and ',
                            style: TextStyle(color: Colors.pinkAccent),
                          ),
                          TextSpan(
                            text: 'Privacy policy',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.pinkAccent,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
