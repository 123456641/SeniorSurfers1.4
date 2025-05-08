import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io'; // Import for File
import 'header_widget.dart'; // Import the custom header widget
import 'package:permission_handler/permission_handler.dart'; // Import for permission handling

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? profilePictureUrl;
  double _fontSize = 16.0;
  String _accountName = 'John Doe';
  String _email = 'johndoe@example.com';

  List<String> fontSizeOptions = ['Small', 'Medium', 'Large'];
  String selectedFontSize = 'Medium';

  final picker = ImagePicker();
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    requestStoragePermission(); // Request storage permission on start
  }

  // Request storage permissions
  Future<void> requestStoragePermission() async {
    final status = await Permission.photos.request(); // for iOS
    final storageStatus = await Permission.storage.request(); // for Android
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final user = supabase.auth.currentUser;
    if (user == null) {
      print('User not logged in');
      return;
    }

    final filePath =
        'avatars/${user.id}_${DateTime.now().millisecondsSinceEpoch}.png';

    try {
      await supabase.storage.from('profiles').upload(filePath, file);

      final publicUrl = supabase.storage
          .from('profiles')
          .getPublicUrl(filePath);

      setState(() {
        profilePictureUrl = publicUrl;
      });

      await supabase
          .from('users')
          .update({'profile_picture_url': publicUrl})
          .eq('id', user.id);

      print('Image uploaded successfully!');
      print('Public URL: $publicUrl');
    } catch (e) {
      print('Upload error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderWidget(title: 'Settings'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            GestureDetector(
              onTap: _pickAndUploadImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    profilePictureUrl != null
                        ? NetworkImage(profilePictureUrl!)
                        : AssetImage('assets/images/edlerpfp.png')
                            as ImageProvider,
                child:
                    profilePictureUrl == null
                        ? Icon(Icons.camera_alt, size: 30, color: Colors.white)
                        : null,
              ),
            ),
            SizedBox(height: 20),
            Text('Tap to change profile picture'),
            SizedBox(height: 30),
            _buildAccountDetails(),
            SizedBox(height: 20),
            _buildFontSizeChooser(),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Details',
          style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text('Name: $_accountName', style: TextStyle(fontSize: _fontSize)),
        Text('Email: $_email', style: TextStyle(fontSize: _fontSize)),
      ],
    );
  }

  Widget _buildFontSizeChooser() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Font Size',
          style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        DropdownButton<String>(
          value: selectedFontSize,
          onChanged: (String? newValue) {
            setState(() {
              selectedFontSize = newValue!;
              if (selectedFontSize == 'Small') {
                _fontSize = 14.0;
              } else if (selectedFontSize == 'Medium') {
                _fontSize = 16.0;
              } else if (selectedFontSize == 'Large') {
                _fontSize = 18.0;
              }
            });
          },
          items:
              fontSizeOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: TextStyle(fontSize: _fontSize)),
                );
              }).toList(),
        ),
      ],
    );
  }
}

void main() {
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: SettingsPage()));
}
