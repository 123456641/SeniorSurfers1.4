import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'header_widget.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? profilePictureUrl;
  double _fontSize = 16.0;
  String _accountName = 'John Doe';
  String _email = 'johndoe@example.com';
  String _firstName = 'John';
  String _lastName = 'Doe';
  String _phoneNumber = '123-456-7890';

  List<String> fontSizeOptions = ['Small', 'Medium', 'Large'];
  String selectedFontSize = 'Medium';

  final picker = ImagePicker();
  final SupabaseClient supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();
  bool isEditable = false;

  @override
  void initState() {
    super.initState();
    requestStoragePermission();
    fetchProfilePicture();
  }

  Future<void> requestStoragePermission() async {
    await Permission.photos.request();
    await Permission.storage.request();
  }

  Future<void> fetchProfilePicture() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response =
        await supabase
            .from('users')
            .select('profile_picture_url')
            .eq('id', user.id)
            .maybeSingle();

    final url = response?['profile_picture_url'];
    if (url != null && mounted) {
      setState(() {
        profilePictureUrl = url;
      });
    }
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

      await supabase
          .from('users')
          .update({'profile_picture_url': publicUrl})
          .eq('id', user.id);

      setState(() {
        profilePictureUrl = publicUrl;
      });

      print('Image uploaded and saved successfully!');
    } catch (e) {
      print('Upload error: $e');
    }
  }

  void _toggleEditability() {
    setState(() {
      isEditable = !isEditable;
    });
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Changes saved successfully!')));
      setState(() {
        isEditable = false;
      });
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
                        : AssetImage('assets/images/elderpfp.png')
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
        Row(
          children: [
            Text(
              'Account Details',
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(),
            isEditable
                ? TextButton(
                  onPressed: _saveChanges,
                  child: Text(
                    'Apply changes',
                    style: TextStyle(color: Colors.red),
                  ),
                )
                : IconButton(
                  icon: Icon(Icons.edit, color: Colors.red),
                  onPressed: _toggleEditability,
                ),
          ],
        ),
        SizedBox(height: 10),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _firstName,
                decoration: InputDecoration(labelText: 'First Name'),
                enabled: isEditable,
                validator:
                    (value) => value!.isEmpty ? 'Enter first name' : null,
                onSaved: (value) => _firstName = value!,
              ),
              SizedBox(height: 10),
              TextFormField(
                initialValue: _lastName,
                decoration: InputDecoration(labelText: 'Last Name'),
                enabled: isEditable,
                validator: (value) => value!.isEmpty ? 'Enter last name' : null,
                onSaved: (value) => _lastName = value!,
              ),
              SizedBox(height: 10),
              TextFormField(
                initialValue: _phoneNumber,
                decoration: InputDecoration(labelText: 'Phone Number'),
                enabled: isEditable,
                validator:
                    (value) => value!.isEmpty ? 'Enter phone number' : null,
                onSaved: (value) => _phoneNumber = value!,
              ),
              SizedBox(height: 10),
              TextFormField(
                initialValue: _email,
                decoration: InputDecoration(labelText: 'Email'),
                enabled: false,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter email';
                  } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
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
