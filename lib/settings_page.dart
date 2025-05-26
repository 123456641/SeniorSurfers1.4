import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/font_size_provider.dart';
import 'dashboardsidebar.dart';
import 'widgets/scaled_text.dart';

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
  bool _isFontSizeChanged = false;

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

  void _onFontSizeChanged(double newSize) {
    Provider.of<FontSizeProvider>(context, listen: false).setFontSize(newSize);
    setState(() {
      _isFontSizeChanged = true;
    });
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
      return;
    }

    try {
      final response =
          await supabase
              .from('users')
              .select(
                'profile_picture_url, first_name, last_name, phone, email',
              )
              .eq('id', user.id)
              .single();

      if (mounted) {
        String? pictureUrl = response['profile_picture_url'];
        if (pictureUrl != null) {
          pictureUrl =
              pictureUrl.contains('?')
                  ? '$pictureUrl&_cache=${DateTime.now().millisecondsSinceEpoch}'
                  : '$pictureUrl?_cache=${DateTime.now().millisecondsSinceEpoch}';
        }

        setState(() {
          profilePictureUrl = pictureUrl;
          _firstName = response['first_name'] ?? '';
          _lastName = response['last_name'] ?? '';
          _phoneNumber = response['phone'] ?? '';
          _email = response['email'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _pickAndUploadImage() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ScaledText(
                  'Choose Photo Source',
                  baseFontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library, size: 32),
                  title: const ScaledText('Gallery', baseFontSize: 16),
                  onTap: () {
                    Navigator.pop(context);
                    _getAndUploadImage(ImageSource.gallery, user);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, size: 32),
                  title: const ScaledText('Camera', baseFontSize: 16),
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
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 800,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      final Uint8List bytes = await pickedFile.readAsBytes();
      final String fileName =
          'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

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

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String imageUrl = supabase.storage
          .from('profiles')
          .getPublicUrl(fileName);
      imageUrl =
          imageUrl.contains('?')
              ? '$imageUrl&t=$timestamp'
              : '$imageUrl?t=$timestamp';

      await supabase
          .from('users')
          .update({'profile_picture_url': imageUrl})
          .eq('id', user.id);

      if (mounted) {
        setState(() {
          profilePictureUrl = imageUrl;
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile picture: $e'),
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
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            isEditable = false;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
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
          title: const ScaledText(
            "Sign Out",
            baseFontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          content: const ScaledText(
            "Are you sure you want to sign out?",
            baseFontSize: 16,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const ScaledText("Cancel", baseFontSize: 16),
            ),
            ElevatedButton(
              onPressed: () async {
                await supabase.auth.signOut();
                if (mounted) {
                  context.go('/');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const ScaledText(
                "Sign Out",
                baseFontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return SidebarLayoutWrapper(
          currentPage: '/settingsD',
          pageTitle: 'Settings',
          child: _buildSettingsContent(fontProvider),
        );
      },
    );
  }

  Widget _buildSettingsContent(FontSizeProvider fontProvider) {
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
          onRefresh: _fetchUserData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child:
                  isLargeScreen
                      ? _buildLargeScreenLayout(fontProvider)
                      : _buildSmallScreenLayout(fontProvider),
            ),
          ),
        );
  }

  Widget _buildLargeScreenLayout(FontSizeProvider fontProvider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildProfilePicture(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showLogoutDialog,
                      icon: const Icon(Icons.logout),
                      label: const ScaledText('Sign Out', baseFontSize: 16),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(flex: 2, child: _buildAccountDetails(fontProvider)),
      ],
    );
  }

  Widget _buildSmallScreenLayout(FontSizeProvider fontProvider) {
    return Column(
      children: [
        _buildProfilePicture(),
        const SizedBox(height: 24),
        _buildAccountDetails(fontProvider),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout),
            label: const ScaledText('Sign Out', baseFontSize: 16),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePicture() {
    return Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: _isUploadingImage ? null : _pickAndUploadImage,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  border: Border.all(color: const Color(0xFF27445D), width: 3),
                ),
                child:
                    _isUploadingImage
                        ? const Center(child: CircularProgressIndicator())
                        : ClipOval(
                          child:
                              profilePictureUrl != null
                                  ? Image.network(
                                    profilePictureUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.person, size: 70);
                                    },
                                  )
                                  : const Icon(Icons.person, size: 70),
                        ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF27445D),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const ScaledText(
          'Tap to change photo',
          baseFontSize: 14,
          color: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildAccountDetails(FontSizeProvider fontProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ScaledText(
                  'Account Details',
                  baseFontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                const Spacer(),
                isEditable
                    ? ElevatedButton.icon(
                      onPressed: _saveChanges,
                      icon: const Icon(Icons.save),
                      label: const ScaledText('Save', baseFontSize: 14),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    )
                    : ElevatedButton.icon(
                      onPressed: _toggleEditability,
                      icon: const Icon(Icons.edit),
                      label: const ScaledText('Edit', baseFontSize: 14),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27445D),
                      ),
                    ),
              ],
            ),
            const Divider(height: 32),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(
                    label: 'First Name',
                    value: _firstName,
                    enabled: isEditable,
                    onSaved: (value) => _firstName = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Last Name',
                    value: _lastName,
                    enabled: isEditable,
                    onSaved: (value) => _lastName = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Phone',
                    value: _phoneNumber,
                    enabled: isEditable,
                    onSaved: (value) => _phoneNumber = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Email',
                    value: _email,
                    enabled: false,
                    onSaved: (value) => _email = value ?? '',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Font Size Settings
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.text_fields, color: Color(0xFF27445D)),
                      const SizedBox(width: 8),
                      const ScaledText(
                        'Text Size',
                        baseFontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      const Spacer(),
                      if (_isFontSizeChanged)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isFontSizeChanged = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Font size applied to entire app!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const ScaledText('Applied!', baseFontSize: 12),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const ScaledText('A', baseFontSize: 12),
                      Expanded(
                        child: Slider(
                          value: fontProvider.fontSize,
                          min: fontProvider.minFontSize,
                          max: fontProvider.maxFontSize,
                          divisions: 20,
                          activeColor: const Color(0xFF27445D),
                          onChanged: _onFontSizeChanged,
                        ),
                      ),
                      const ScaledText('A', baseFontSize: 18),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27445D),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ScaledText(
                          '${fontProvider.fontSize.round()}px',
                          baseFontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const ScaledText(
                      'Sample text: This shows how text appears throughout the app.',
                      baseFontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        fontProvider.resetToDefault();
                        setState(() {
                          _isFontSizeChanged = true;
                        });
                      },
                      child: const ScaledText(
                        'Reset to Default',
                        baseFontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required bool enabled,
    required Function(String?) onSaved,
  }) {
    return TextFormField(
      initialValue: value,
      enabled: enabled,
      onSaved: onSaved,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF27445D), width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      style: TextStyle(
        color: enabled ? Colors.black87 : Colors.grey.shade600,
        fontSize: 16,
      ),
    );
  }
}
