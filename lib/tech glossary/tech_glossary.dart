import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../header_widget.dart'; // Import your custom header

class TechGlossaryPage extends StatefulWidget {
  const TechGlossaryPage({super.key});

  @override
  _TechGlossaryPageState createState() => _TechGlossaryPageState();
}

class _TechGlossaryPageState extends State<TechGlossaryPage> {
  FlutterTts flutterTts = FlutterTts();
  final ScrollController _listScrollController = ScrollController();
  final Map<String, GlobalKey> _letterKeys = {};

  final List<Map<String, String>> glossary = [
    {
      'term': 'App (Application)',
      'definition':
          'A program on your phone or tablet that helps you do specific tasks, like sending messages or watching videos.',
    },
    {
      'term': 'Click / Tap',
      'definition':
          'Click – Pressing a button on a computer mouse. Tap – Touching the screen with your finger on a phone or tablet.',
    },
    {
      'term': 'Computer',
      'definition':
          'A machine used to browse the internet, type documents, watch videos, and more.',
    },
    {
      'term': 'Delete',
      'definition': 'To remove something from your device or app.',
    },
    {
      'term': 'Email',
      'definition':
          'A way to send and receive digital letters over the internet.',
    },
    {
      'term': 'Help Button',
      'definition':
          'A button you press when you need help or want to ask a question in the app.',
    },
    {
      'term': 'Internet',
      'definition':
          'A network that connects computers and phones to websites and apps all over the world.',
    },
    {
      'term': 'Password',
      'definition':
          'A secret word or phrase that keeps your accounts safe. Only you should know it!',
    },
    {
      'term': 'Save',
      'definition':
          'To keep your work or information so you can look at it again later.',
    },
    {
      'term': 'Search',
      'definition':
          'To look for something on your phone, computer, or the internet.',
    },
    {
      'term': 'Settings',
      'definition':
          'A place in your phone, computer, or app where you can change how things work.',
    },
    {
      'term': 'Smartphone',
      'definition':
          'A phone that can connect to the internet and run apps, take pictures, and do many things a computer can do.',
    },
    {
      'term': 'Tech Support',
      'definition':
          'People who help you fix problems with your computer, phone, or apps.',
    },
    {
      'term': 'Video Call',
      'definition':
          'A call where you can see and talk to someone using your camera and internet.',
    },
  ];

  Future<void> _speakDefinition(String definition) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(definition);
  }

  @override
  void initState() {
    super.initState();
    for (var entry in glossary) {
      String letter = entry['term']![0].toUpperCase();
      _letterKeys.putIfAbsent(letter, () => GlobalKey());
    }
  }

  void _scrollToLetter(String letter) {
    final key = _letterKeys[letter];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: Duration(milliseconds: 300),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> alphabet = List.generate(
      26,
      (i) => String.fromCharCode(65 + i),
    );

    return Scaffold(
      appBar: HeaderWidget(), // ✅ this is the correct way
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              "Tech Glossary",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color(0xFF27445D),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  color: Colors.grey[200],
                  child: ListView.builder(
                    itemCount: alphabet.length,
                    itemBuilder: (context, index) {
                      String letter = alphabet[index];
                      return InkWell(
                        onTap: () => _scrollToLetter(letter),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          child: Text(
                            letter,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _listScrollController,
                    itemCount: glossary.length,
                    itemBuilder: (context, index) {
                      final term = glossary[index]['term']!;
                      final definition = glossary[index]['definition']!;
                      final letter = term[0].toUpperCase();
                      final key = _letterKeys[letter];
                      final bool isFirstOfLetter =
                          glossary.indexWhere(
                            (item) => item['term']![0].toUpperCase() == letter,
                          ) ==
                          index;

                      return Column(
                        key: isFirstOfLetter ? key : null,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isFirstOfLetter)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Text(
                                letter,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ListTile(
                            title: Text(term),
                            subtitle: Text(definition),
                            onTap: () => _speakDefinition(definition),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
