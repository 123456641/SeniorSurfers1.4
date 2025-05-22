import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'header_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? profilePictureUrl;
  String _firstName = '';
  String _lastName = '';
  String _phoneNumber = '';
  String _email = '';
  bool _isLoading = true;
  bool _isUploadingImage = false;

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
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show image source dialog
    await showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Select Image Source',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    child: Icon(Icons.photo_library, color: Colors.red),
                  ),
                  title: Text('Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _getAndUploadImage(ImageSource.gallery, user);
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    child: Icon(Icons.photo_camera, color: Colors.red),
                  ),
                  title: Text('Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _getAndUploadImage(ImageSource.camera, user);
                  },
                ),
              ],
            ),
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

      if (mounted) {
        setState(() {
          _isUploadingImage = true;
        });
      }

      print('Image selected: ${pickedFile.path}');

      // Read file as bytes to avoid file path issues
      final Uint8List bytes = await pickedFile.readAsBytes();

      // Create a unique file name without complex paths
      final String fileName =
          'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      print('Uploading with file name: $fileName');

      try {
        // Upload bytes directly instead of File object
        await supabase.storage
            .from('profiles')
            .uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
                contentType: 'image/jpeg',
              ),
            );

        print('File uploaded successfully to storage');

        // Get the public URL for the uploaded file with forced cache busting
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        String imageUrl = supabase.storage
            .from('profiles')
            .getPublicUrl(fileName);

        print('Raw image URL: $imageUrl');

        // Add cache-busting parameter to ensure we get the latest image
        imageUrl =
            imageUrl.contains('?')
                ? '$imageUrl&t=$timestamp'
                : '$imageUrl?t=$timestamp';

        print('Image public URL with cache busting: $imageUrl');

        // Update the user's profile in the database
        await supabase
            .from('users')
            .update({'profile_picture_url': imageUrl})
            .eq('id', user.id);

        print('Database updated with new image URL');

        if (mounted) {
          setState(() {
            profilePictureUrl = imageUrl;
            _isUploadingImage = false;
          });

          // Force a refresh to ensure UI updates
          await _fetchUserData();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile picture updated successfully'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (uploadError) {
        print('Storage operation error: $uploadError');
        throw uploadError;
      }
    } catch (e) {
      print('Error in image upload process: $e');
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });

        // Show a more specific error message if possible
        String errorMessage =
            'Failed to update profile picture: ${e.toString()}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
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
      if (user == null) {
        print('Cannot update profile: No authenticated user');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        print('Updating user profile with data:');
        print('First Name: $_firstName');
        print('Last Name: $_lastName');
        print('Phone: $_phoneNumber');
        print('User ID: ${user.id}');

        // Create update data map
        final updateData = {
          'first_name': _firstName,
          'last_name': _lastName,
          'phone': _phoneNumber,
        };

        // Ensure we have data to update
        if (_firstName.isEmpty && _lastName.isEmpty && _phoneNumber.isEmpty) {
          throw Exception('No data to update');
        }

        // Perform the update
        final response =
            await supabase
                .from('users')
                .update(updateData)
                .eq('id', user.id)
                .select();

        // Log the response for debugging
        print('Update response: $response');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile updated successfully!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
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
              content: Text('Failed to update profile: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
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
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Sign Out",
            style: TextStyle(fontSize: isLargeScreen ? 22 : 18),
          ),
          content: Text(
            "Are you sure you want to sign out?",
            style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 0),
          actionsPadding: EdgeInsets.all(16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancel",
                style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await supabase.auth.signOut();
                if (mounted) {
                  // Navigate back to Welcome Page using GoRouter
                  context.go('/');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeScreen ? 20 : 16,
                  vertical: isLargeScreen ? 12 : 8,
                ),
              ),
              child: Text(
                "Sign Out",
                style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we're on a large screen (tablet/desktop)
    final isLargeScreen = MediaQuery.of(context).size.width > 900;
    final isMediumScreen =
        MediaQuery.of(context).size.width > 600 &&
        MediaQuery.of(context).size.width <= 900;

    return Scaffold(
      appBar: HeaderWidget(title: 'Settings'),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.red))
              : RefreshIndicator(
                color: Colors.red,
                onRefresh: () async {
                  // Re-fetch user data when pulled to refresh
                  await _fetchUserData();
                },
                child: Center(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      vertical: 24.0,
                      horizontal:
                          isLargeScreen
                              ? 80.0
                              : isMediumScreen
                              ? 40.0
                              : 16.0,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 1200),
                      child:
                          isLargeScreen
                              ? _buildLargeScreenLayout()
                              : _buildSmallScreenLayout(),
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildLargeScreenLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Profile picture
            Expanded(
              flex: 1,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildProfilePicture(),
                      SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _showLogoutDialog,
                          child: Text(
                            'Sign Out',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 24),
            // Right side - Account details
            Expanded(flex: 2, child: _buildAccountDetails()),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallScreenLayout() {
    return Column(
      children: [
        _buildProfilePicture(),
        SizedBox(height: 30),
        _buildAccountDetails(),
        SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _showLogoutDialog,
            child: Text('Sign Out', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePicture() {
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              GestureDetector(
                onTap: _isUploadingImage ? null : _pickAndUploadImage,
                child: Container(
                  width: isLargeScreen ? 160 : 120,
                  height: isLargeScreen ? 160 : 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child:
                      _isUploadingImage
                          ? Center(
                            child: CircularProgressIndicator(color: Colors.red),
                          )
                          : ClipOval(
                            child:
                                profilePictureUrl != null &&
                                        profilePictureUrl!.isNotEmpty
                                    ? FadeInImage.assetNetwork(
                                      placeholder:
                                          'assets/images/placeholder_profile.png', // Add a placeholder image to your assets
                                      image: profilePictureUrl!,
                                      fit: BoxFit.cover,
                                      width: isLargeScreen ? 160 : 120,
                                      height: isLargeScreen ? 160 : 120,
                                      imageErrorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        print(
                                          'Error loading profile image: $error',
                                        );
                                        return Icon(
                                          Icons.person,
                                          size: isLargeScreen ? 80 : 60,
                                          color: Colors.grey[800],
                                        );
                                      },
                                    )
                                    : Icon(
                                      Icons.person,
                                      size: isLargeScreen ? 80 : 60,
                                      color: Colors.grey[800],
                                    ),
                          ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.all(isLargeScreen ? 12 : 8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: isLargeScreen ? 28 : 22,
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
          style: TextStyle(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
            fontSize: isLargeScreen ? 16 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountDetails() {
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(isLargeScreen ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Account Details',
                  style: TextStyle(
                    fontSize: isLargeScreen ? 22 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                isEditable
                    ? TextButton.icon(
                      onPressed: _saveChanges,
                      icon: Icon(
                        Icons.save,
                        color: Colors.red,
                        size: isLargeScreen ? 24 : 20,
                      ),
                      label: Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: isLargeScreen ? 16 : 14,
                        ),
                      ),
                    )
                    : IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: Colors.red,
                        size: isLargeScreen ? 24 : 20,
                      ),
                      onPressed: _toggleEditability,
                      tooltip: 'Edit profile',
                    ),
              ],
            ),
            Divider(),
            SizedBox(height: isLargeScreen ? 16 : 10),
            Form(
              key: _formKey,
              child: isLargeScreen ? _buildWideForm() : _buildNarrowForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideForm() {
    return Column(
      children: [
        // First row with First Name and Last Name
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                label: 'First Name',
                initialValue: _firstName,
                enabled: isEditable,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Enter first name'
                            : null,
                onSaved: (value) => _firstName = value ?? '',
                icon: Icons.person,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                label: 'Last Name',
                initialValue: _lastName,
                enabled: isEditable,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Enter last name'
                            : null,
                onSaved: (value) => _lastName = value ?? '',
                icon: Icons.person_outline,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        // Second row with Phone and Email
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Phone Number',
                initialValue: _phoneNumber,
                enabled: isEditable,
                validator: null, // Phone is optional
                onSaved: (value) => _phoneNumber = value ?? '',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                label: 'Email',
                initialValue: _email,
                enabled: false,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter email';
                  } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
                onSaved: (value) => _email = value ?? '',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNarrowForm() {
    return Column(
      children: [
        _buildTextField(
          label: 'First Name',
          initialValue: _firstName,
          enabled: isEditable,
          validator:
              (value) =>
                  value == null || value.isEmpty ? 'Enter first name' : null,
          onSaved: (value) => _firstName = value ?? '',
          icon: Icons.person,
        ),
        SizedBox(height: 15),
        _buildTextField(
          label: 'Last Name',
          initialValue: _lastName,
          enabled: isEditable,
          validator:
              (value) =>
                  value == null || value.isEmpty ? 'Enter last name' : null,
          onSaved: (value) => _lastName = value ?? '',
          icon: Icons.person_outline,
        ),
        SizedBox(height: 15),
        _buildTextField(
          label: 'Phone Number',
          initialValue: _phoneNumber,
          enabled: isEditable,
          validator: null, // Phone is optional
          onSaved: (value) => _phoneNumber = value ?? '',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 15),
        _buildTextField(
          label: 'Email',
          initialValue: _email,
          enabled: false,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Enter email';
            } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return 'Enter a valid email address';
            }
            return null;
          },
          onSaved: (value) => _email = value ?? '',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required bool enabled,
    required String? Function(String?)? validator,
    required void Function(String?) onSaved,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.red.withOpacity(0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isLargeScreen ? 20 : 16,
        ),
        labelStyle: TextStyle(fontSize: isLargeScreen ? 16 : 14),
      ),
      style: TextStyle(
        color: enabled ? Colors.black87 : Colors.grey,
        fontSize: isLargeScreen ? 16 : 14,
      ),
      enabled: enabled,
      validator: validator,
      onSaved: onSaved,
      keyboardType: keyboardType,
    );
  }
}
