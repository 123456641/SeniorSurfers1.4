import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class GoogleMeetAdventureGame extends StatefulWidget {
  const GoogleMeetAdventureGame({super.key});

  @override
  State<GoogleMeetAdventureGame> createState() =>
      _GoogleMeetAdventureGameState();
}

class _GoogleMeetAdventureGameState extends State<GoogleMeetAdventureGame>
    with TickerProviderStateMixin {
  int currentLevel = 0;
  int totalStars = 0;
  bool isAudioOn = true;
  bool isVideoOn = true;
  bool isScreenSharing = false;
  bool isTtsEnabled = true;
  List<String> unlockedFamilyMembers = ['Grandma Rose'];

  late AnimationController _celebrationController;
  late AnimationController _pulseController;
  late FlutterTts flutterTts;

  final List<GameLevel> levels = [
    GameLevel(
      id: 0,
      title: "Welcome to the Family Café!",
      description:
          "Grandma Rose wants to connect with her family. Help her learn Google Meet!",
      scenario:
          "Your granddaughter Emma just moved to college and misses your famous cookies. Let's learn how to video call her!",
      task: "Find and tap the 'Join Meeting' button",
      instruction: "Look for the large green button that says 'Join Meeting'",
      familyMember: "Emma (Granddaughter)",
      reward: "You've unlocked Emma! She's so happy to see you!",
      difficulty: 1,
    ),
    GameLevel(
      id: 1,
      title: "Getting Ready for the Call",
      description: "Before joining, let's make sure you look and sound great!",
      scenario:
          "Emma can't wait to see your face! But first, let's check your camera and microphone.",
      task: "Turn your camera ON",
      instruction:
          "Tap the camera button to make sure Emma can see your beautiful smile",
      familyMember: "Emma (Granddaughter)",
      reward: "Perfect! Emma says you look wonderful today!",
      difficulty: 1,
    ),
    GameLevel(
      id: 2,
      title: "Finding Your Voice",
      description: "Now let's make sure Emma can hear your voice clearly",
      scenario: "Emma is waving at the camera but can't hear you yet!",
      task: "Turn your microphone ON",
      instruction: "Tap the microphone button so Emma can hear your voice",
      familyMember: "Emma (Granddaughter)",
      reward: "\"Hi Grandma! I can hear you perfectly now!\" - Emma",
      difficulty: 1,
    ),
    GameLevel(
      id: 3,
      title: "Sunday Family Brunch",
      description: "The whole family wants to join for Sunday brunch!",
      scenario:
          "Your son David and daughter-in-law Sarah want to join the call with their kids.",
      task: "Add family members to the call",
      instruction: "Tap 'Add People' and invite David's family",
      familyMember: "David's Family",
      reward: "The whole family is here! Time for virtual brunch!",
      difficulty: 2,
    ),
    GameLevel(
      id: 4,
      title: "Sharing Precious Memories",
      description: "Show everyone your new photo album from the garden",
      scenario:
          "You took beautiful photos of your roses and want to share them with everyone!",
      task: "Share your screen to show photos",
      instruction: "Tap 'Present Now' to share your photo album",
      familyMember: "Whole Family",
      reward:
          "\"Your garden looks amazing, Mom!\" - The whole family loves your photos!",
      difficulty: 3,
    ),
    GameLevel(
      id: 5,
      title: "Grandparents' Game Night",
      description: "Connect with other grandparents for weekly game night",
      scenario:
          "Your friend Margaret invited you to the weekly virtual game night with other grandparents.",
      task: "Join a scheduled meeting",
      instruction: "Use the meeting link Margaret sent you",
      familyMember: "Margaret & Friends",
      reward: "You've joined the Grandparents' Club! New friends unlocked!",
      difficulty: 2,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _initTts();
  }

  Future<void> _initTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5); // Slower speech for seniors
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _speakText(String text) async {
    if (isTtsEnabled) {
      await flutterTts.speak(text);
      // Provide haptic feedback to confirm TTS started
      HapticFeedback.lightImpact();
    }
  }

  void _toggleTts() {
    setState(() {
      isTtsEnabled = !isTtsEnabled;
    });

    if (isTtsEnabled) {
      _speakText(
        "Text to speech is now on. Long press any text to hear it read aloud.",
      );
    } else {
      flutterTts.stop();
    }
  }

  // Helper widget for long-press text-to-speech
  Widget _buildTtsText(
    String text, {
    required TextStyle style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return GestureDetector(
      onLongPress: () => _speakText(text),
      child: Container(
        decoration:
            isTtsEnabled
                ? BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                )
                : null,
        padding: isTtsEnabled ? const EdgeInsets.all(2) : null,
        child: Text(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _pulseController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  void _completeLevel() {
    setState(() {
      totalStars += levels[currentLevel].difficulty;
      if (!unlockedFamilyMembers.contains(levels[currentLevel].familyMember)) {
        unlockedFamilyMembers.add(levels[currentLevel].familyMember);
      }
    });

    _celebrationController.forward().then((_) {
      _celebrationController.reset();
    });

    HapticFeedback.lightImpact();
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _celebrationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_celebrationController.value * 0.3),
                    child: const Icon(
                      Icons.star,
                      size: 60,
                      color: Colors.amber,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildTtsText(
                "Wonderful Job!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              _buildTtsText(
                levels[currentLevel].reward,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (currentLevel < levels.length - 1)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          currentLevel++;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text("Next Level"),
                    ),
                  if (currentLevel == levels.length - 1)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showGameCompletionDialog();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      icon: const Icon(Icons.celebration),
                      label: const Text("Celebrate!"),
                    ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text("Review"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGameCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.celebration, size: 80, color: Colors.purple.shade700),
              const SizedBox(height: 16),
              _buildTtsText(
                "🎉 Congratulations! 🎉",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF27445D),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              _buildTtsText(
                "You're now a Google Meet expert!\nYour family is so proud of you!",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        _buildTtsText(
                          "Total Stars Earned: $totalStars",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTtsText(
                      "Family Members Connected: ${unlockedFamilyMembers.length}",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                icon: const Icon(Icons.home),
                label: const Text("Return Home"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Google Meet Family Adventure",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // TTS Toggle Button with tooltip
          Tooltip(
            message:
                isTtsEnabled
                    ? "Turn off voice (currently: long press text to hear)"
                    : "Turn on voice (will allow long press to hear text)",
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: _toggleTts,
                icon: Icon(
                  isTtsEnabled ? Icons.volume_up : Icons.volume_off,
                  size: 28,
                  color: isTtsEnabled ? Colors.amber : Colors.white,
                ),
                style: IconButton.styleFrom(
                  backgroundColor:
                      isTtsEnabled ? Colors.white.withOpacity(0.2) : null,
                ),
              ),
            ),
          ),
          // Stars Counter
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  "$totalStars",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions for TTS
            if (isTtsEnabled)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "💡 Long press any text to hear it read aloud!",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Progress indicator
            _buildProgressIndicator(),

            const SizedBox(height: 24),

            // Current level content
            _buildLevelContent(),

            const SizedBox(height: 32),

            // Mock Google Meet interface
            _buildMockGoogleMeetInterface(),

            const SizedBox(height: 24),

            // Family members section
            _buildFamilyMembersSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTtsText(
                  "Level ${currentLevel + 1} of ${levels.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (currentLevel + 1) / levels.length,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelContent() {
    final level = levels[currentLevel];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTtsText(
            level.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF27445D),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTtsText(
                    level.scenario,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue.shade800,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildTtsText(
            "Your Task:",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 8),
          _buildTtsText(
            level.task,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF27445D),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.tips_and_updates,
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTtsText(
                    level.instruction,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockGoogleMeetInterface() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Mock video area
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Background pattern
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade900, Colors.purple.shade900],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                // Video preview
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Grandma Rose",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!isVideoOn)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "Camera is off",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: isAudioOn ? Icons.mic : Icons.mic_off,
                label: isAudioOn ? "Mute" : "Unmute",
                color: isAudioOn ? Colors.grey.shade600 : Colors.red,
                onTap: () {
                  setState(() {
                    isAudioOn = !isAudioOn;
                  });
                  if (currentLevel == 2 && isAudioOn) {
                    _completeLevel();
                  }
                },
                shouldPulse: currentLevel == 2 && !isAudioOn,
              ),
              _buildControlButton(
                icon: isVideoOn ? Icons.videocam : Icons.videocam_off,
                label: isVideoOn ? "Stop Video" : "Start Video",
                color: isVideoOn ? Colors.grey.shade600 : Colors.red,
                onTap: () {
                  setState(() {
                    isVideoOn = !isVideoOn;
                  });
                  if (currentLevel == 1 && isVideoOn) {
                    _completeLevel();
                  }
                },
                shouldPulse: currentLevel == 1 && !isVideoOn,
              ),
              _buildControlButton(
                icon: Icons.present_to_all,
                label: "Present",
                color: isScreenSharing ? Colors.green : Colors.grey.shade600,
                onTap: () {
                  setState(() {
                    isScreenSharing = !isScreenSharing;
                  });
                  if (currentLevel == 4) {
                    _completeLevel();
                  }
                },
                shouldPulse: currentLevel == 4,
              ),
              _buildControlButton(
                icon: Icons.person_add,
                label: "Add People",
                color: Colors.grey.shade600,
                onTap: () {
                  if (currentLevel == 3) {
                    _completeLevel();
                  }
                },
                shouldPulse: currentLevel == 3,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Join meeting button for first level
          if (currentLevel == 0)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.1),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _completeLevel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 8,
                      ),
                      icon: const Icon(Icons.video_call, size: 24),
                      label: const Text(
                        "Join Meeting",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

          // Meeting link for level 5
          if (currentLevel == 5)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  _buildTtsText(
                    "Meeting link from Margaret:",
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _buildTtsText(
                      "meet.google.com/abc-defg-hij",
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'monospace',
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _completeLevel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: const Icon(Icons.link),
                    label: const Text("Join with Link"),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool shouldPulse = false,
  }) {
    Widget button = Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(30),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );

    if (shouldPulse) {
      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_pulseController.value * 0.15),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.6),
                    blurRadius: 20 * _pulseController.value,
                    spreadRadius: 5 * _pulseController.value,
                  ),
                ],
              ),
              child: button,
            ),
          );
        },
      );
    }

    return button;
  }

  Widget _buildFamilyMembersSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.family_restroom,
                color: Colors.purple.shade700,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTtsText(
                  "Your Family Connections",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF27445D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ...unlockedFamilyMembers.map(
                (member) => _buildFamilyMemberChip(member, true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyMemberChip(String member, bool isUnlocked) {
    return GestureDetector(
      onLongPress: () => _speakText("Connected with $member"),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isUnlocked ? Colors.green.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnlocked ? Colors.green.shade300 : Colors.grey.shade400,
          ),
          // Add subtle border when TTS is enabled to indicate long-press functionality
          boxShadow:
              isTtsEnabled
                  ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUnlocked ? Icons.check_circle : Icons.lock,
              size: 16,
              color: isUnlocked ? Colors.green.shade700 : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              member,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color:
                    isUnlocked ? Colors.green.shade800 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameLevel {
  final int id;
  final String title;
  final String description;
  final String scenario;
  final String task;
  final String instruction;
  final String familyMember;
  final String reward;
  final int difficulty;

  GameLevel({
    required this.id,
    required this.title,
    required this.description,
    required this.scenario,
    required this.task,
    required this.instruction,
    required this.familyMember,
    required this.reward,
    required this.difficulty,
  });
}
