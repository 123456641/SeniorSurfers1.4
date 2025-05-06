import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'header_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'login_page.dart';
import 'dart:async';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? profilePictureUrl;
  double _fontSize = 16.0;
  String _firstName = '';
  String _lastName = '';
  String _phoneNumber = '';
  String _email = '';
  bool _isLoading = true;
  bool _isUploadingImage = false;

  List<String> fontSizeOptions = ['Small', 'Medium', 'Large'];
  String selectedFontSize = 'Medium';

  final picker = ImagePicker();
  final SupabaseClient supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();
  bool isEditable = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _fetchUserData();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid || Platform.isIOS) {
      Map<Permission, PermissionStatus> statuses =
          await [
            Permission.photos,
            Permission.storage,
            Permission.camera,
          ].request();

      print('Permission statuses: $statuses');
    }
  }

  Future<void> _fetchUserData() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('No authenticated user found');
      return;
    }

    print('Fetching data for user: ${user.id}');
    try {
      final response =
          await supabase
              .from('users')
              .select(
                'profile_picture_url, first_name, last_name, phone, email',
              )
              .eq('id', user.id)
              .single();

      print('User data fetched: $response');

      if (mounted) {
        // Force refresh profile picture URL by adding timestamp to prevent caching
        String? pictureUrl = response['profile_picture_url'];
        if (pictureUrl != null) {
          if (pictureUrl.contains('?')) {
            pictureUrl =
                '$pictureUrl&_cache=${DateTime.now().millisecondsSinceEpoch}';
          } else {
            pictureUrl =
                '$pictureUrl?_cache=${DateTime.now().millisecondsSinceEpoch}';
          }
        }

        setState(() {
          profilePictureUrl = pictureUrl;
          _firstName = response['first_name'] ?? '';
          _lastName = response['last_name'] ?? '';
          _phoneNumber = response['phone'] ?? '';
          _email = response['email'] ?? '';
          _isLoading = false;
        });
        print('Set profile picture URL to: $profilePictureUrl');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You must be logged in to update your profile picture'),
        ),
      );
      return;
    }

    // Show image source dialog
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _getAndUploadImage(ImageSource.gallery, user);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _getAndUploadImage(ImageSource.camera, user);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getAndUploadImage(ImageSource source, User user) async {
    try {
      print('Starting image pick and upload process');
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70, // Compress image
        maxWidth: 800,
      );

      if (pickedFile == null) {
        print('No image selected');
        return;
      }

      setState(() {
        _isUploadingImage = true;
      });

      print('Image selected: ${pickedFile.path}');

      // Create a unique file path in Supabase storage
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      // Simplified path structure - just use the filename directly in the bucket
      final filePath = fileName;
      final file = File(pickedFile.path);

      print('Uploading to storage path: $filePath');

      try {
        // Upload the file to Supabase Storage
        await supabase.storage
            .from('profiles')
            .upload(
              filePath,
              file,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );
        print('File uploaded successfully to storage');
      } catch (storageError) {
        print('Storage upload error: $storageError');

        // If the error is because the file already exists, we can continue
        if (!storageError.toString().contains('duplicate')) {
          throw storageError; // Re-throw if it's not a duplicate error
        }
      }

      // Get the public URL for the uploaded file
      final imageUrl = supabase.storage.from('profiles').getPublicUrl(filePath);
      print('Image public URL: $imageUrl');

      try {
        // Update the user's profile in the database
        final updateResponse = await supabase
            .from('users')
            .update({'profile_picture_url': imageUrl})
            .eq('id', user.id);
        print('Database update response: $updateResponse');

        // Verify the update by fetching the latest user data
        final verifyResponse =
            await supabase
                .from('users')
                .select('profile_picture_url')
                .eq('id', user.id)
                .single();

        print(
          'Verification response: ${verifyResponse['profile_picture_url']}',
        );

        if (verifyResponse['profile_picture_url'] != imageUrl) {
          print('WARNING: Verification failed - URLs don\'t match');
        }
      } catch (dbError) {
        print('Database update error: $dbError');
        throw dbError;
      }

      if (mounted) {
        setState(() {
          profilePictureUrl = imageUrl;
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile picture updated successfully')),
        );
      }
    } catch (e) {
      print('Error picking or uploading image: $e');
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile picture. Please try again.',
            ),
          ),
        );
      }
    }
  }

  void _toggleEditability() {
    setState(() {
      isEditable = !isEditable;
    });
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final user = supabase.auth.currentUser;
      if (user == null) return;

      setState(() {
        _isLoading = true;
      });

      try {
        await supabase
            .from('users')
            .update({
              'first_name': _firstName,
              'last_name': _lastName,
              'phone': _phoneNumber,
            })
            .eq('id', user.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully!')),
          );
          setState(() {
            isEditable = false;
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error updating profile: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile. Please try again.'),
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Sign Out"),
          content: Text("Are you sure you want to sign out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await supabase.auth.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => LoginPagee()),
                  );
                }
              },
              child: Text("Sign Out", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderWidget(title: 'Settings'),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () async {
                  // Re-fetch user data when pulled to refresh
                  await _fetchUserData();
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap:
                                  _isUploadingImage
                                      ? null
                                      : _pickAndUploadImage,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[200],
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                                child:
                                    _isUploadingImage
                                        ? Center(
                                          child: CircularProgressIndicator(),
                                        )
                                        : ClipOval(
                                          child:
                                              profilePictureUrl != null
                                                  ? Image.network(
                                                    profilePictureUrl!,
                                                    fit: BoxFit.cover,
                                                    width: 100,
                                                    height: 100,
                                                    errorBuilder: (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      print(
                                                        'Error loading profile image: $error',
                                                      );
                                                      return Icon(
                                                        Icons.person,
                                                        size: 50,
                                                        color: Colors.grey[800],
                                                      );
                                                    },
                                                    loadingBuilder: (
                                                      context,
                                                      child,
                                                      loadingProgress,
                                                    ) {
                                                      if (loadingProgress ==
                                                          null)
                                                        return child;
                                                      return Center(
                                                        child: CircularProgressIndicator(
                                                          value:
                                                              loadingProgress
                                                                          .expectedTotalBytes !=
                                                                      null
                                                                  ? loadingProgress
                                                                          .cumulativeBytesLoaded /
                                                                      (loadingProgress
                                                                              .expectedTotalBytes ??
                                                                          1)
                                                                  : null,
                                                        ),
                                                      );
                                                    },
                                                  )
                                                  : Icon(
                                                    Icons.person,
                                                    size: 50,
                                                    color: Colors.grey[800],
                                                  ),
                                        ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Tap to change profile picture',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(height: 30),
                      _buildAccountDetails(),
                      SizedBox(height: 20),
                      _buildFontSizeChooser(),
                      SizedBox(height: 40),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red,
                        ),
                        onPressed: _showLogoutDialog,
                        child: Text('Log Out'),
                      ),
                    ],
                  ),
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
                decoration: InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                enabled: isEditable,
                validator:
                    (value) => value!.isEmpty ? 'Enter first name' : null,
                onSaved: (value) => _firstName = value!,
              ),
              SizedBox(height: 12),
              TextFormField(
                initialValue: _lastName,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                enabled: isEditable,
                validator: (value) => value!.isEmpty ? 'Enter last name' : null,
                onSaved: (value) => _lastName = value!,
              ),
              SizedBox(height: 12),
              TextFormField(
                initialValue: _phoneNumber,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                enabled: isEditable,
                validator:
                    (value) => value!.isEmpty ? 'Enter phone number' : null,
                onSaved: (value) => _phoneNumber = value!,
              ),
              SizedBox(height: 12),
              TextFormField(
                initialValue: _email,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
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
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
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
          ),
        ),
      ],
    );
  }
}
