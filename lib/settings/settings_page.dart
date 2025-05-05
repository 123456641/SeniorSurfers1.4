import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../header_widget.dart';
import 'sidebar_button.dart';
import 'input_field.dart';
import '../providers/font_size_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<Map<String, dynamic>> fontSizePresets = [
    {'name': 'Small', 'size': 14.0},
    {'name': 'Medium', 'size': 16.0},
    {'name': 'Large', 'size': 18.0},
    {'name': 'Extra Large', 'size': 20.0},
  ];

  double fontSize = 16.0;
  String currentFontSize = 'Medium';
  late FontSizeProvider fontSizeProvider;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fontSizeProvider = Provider.of<FontSizeProvider>(context);
    setState(() {
      fontSize = fontSizeProvider.fontSize;
      currentFontSize = fontSizeProvider.fontSizeName;
    });
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adjust Font Size'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Choose a font size for the entire app:',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ...fontSizePresets.map((preset) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              fontSize = preset['size'];
                              currentFontSize = preset['name'];
                            });
                            fontSizeProvider.updateFontSize(
                              preset['size'],
                              preset['name'],
                            );
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 20.0,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  currentFontSize == preset['name']
                                      ? Colors.blue.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(
                                color:
                                    currentFontSize == preset['name']
                                        ? Colors.blue
                                        : Colors.transparent,
                                width: 2.0,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  preset['name'],
                                  style: TextStyle(
                                    fontSize: preset['size'],
                                    fontWeight:
                                        currentFontSize == preset['name']
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                                if (currentFontSize == preset['name'])
                                  const Icon(Icons.check, color: Colors.blue),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 15),
                    Text(
                      'Custom Size: ${fontSize.toStringAsFixed(1)}',
                      style: TextStyle(fontSize: 14),
                    ),
                    Slider(
                      value: fontSize,
                      min: 12,
                      max: 24,
                      divisions: 12,
                      label: fontSize.toStringAsFixed(1),
                      onChanged: (newValue) {
                        setState(() {
                          fontSize = newValue;
                          currentFontSize = 'Custom';
                        });
                        fontSizeProvider.updateFontSize(newValue, 'Custom');
                      },
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Preview Text',
                        style: TextStyle(fontSize: fontSize),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderWidget(),
      body: Row(
        children: [
          Container(
            width: 180,
            color: const Color(0xFFEAEAEA),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey,
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Allyson Soritcho',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const Divider(thickness: 1, height: 30),
                SidebarButton('Account Details', isActive: true),
                SidebarButton(
                  'Font Size ($currentFontSize)',
                  onTap: _showFontSizeDialog, // Directly call the function
                ),
                SidebarButton('Offline Mode'),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Account Details',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 20),
                    buildFieldGroup('First name', 'Allyson'),
                    buildFieldGroup('Last name', 'Soritcho'),
                    buildFieldGroup(
                      'Email',
                      'ally@gmail.com',
                      inputType: TextInputType.emailAddress,
                    ),
                    buildFieldGroup(
                      'Phone number',
                      '09090990909',
                      inputType: TextInputType.phone,
                    ),
                    buildFieldGroup(
                      'Password',
                      '**********',
                      obscureText: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFieldGroup(
    String label,
    String initialValue, {
    TextInputType inputType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InputField(
          label: label,
          initialValue: initialValue,
          inputType: inputType,
          obscureText: obscureText,
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            // TODO: Add Supabase update logic here
          },
          child: const Text(
            'Change',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
