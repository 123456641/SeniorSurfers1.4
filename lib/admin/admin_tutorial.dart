//admin_tutorial.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../tutorial/pdf_viewer_page.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class AddTutorialPage extends StatefulWidget {
  const AddTutorialPage({super.key});

  @override
  State<AddTutorialPage> createState() => _AddTutorialPageState();
}

class _AddTutorialPageState extends State<AddTutorialPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> tutorialFiles = [];
  bool isLoading = true;
  bool isUploading = false;
  String? selectedPlatform;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  // File upload related variables
  PlatformFile? _selectedFileInfo;
  String? _fileName;
  final TextEditingController _fileDescriptionController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTutorialFiles();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    _fileDescriptionController.dispose();
    super.dispose();
  }

  Future<void> fetchTutorialFiles() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get all files from tutorial_files table
      final files = await _supabase
          .from('tutorial_files')
          .select()
          .order('uploaded_at', ascending: false);

      setState(() {
        tutorialFiles = files;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading tutorials: $e')));
    }
  }

  Future<void> _addNewTutorial() async {
    if (selectedPlatform == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a title and select a platform'),
        ),
      );
      // In _addNewTutorial method, after successful upload, add:
      if (_selectedFileInfo != null) {
        final String notificationTitle = 'New Tutorial File Available';
        final String notificationBody =
            'A new tutorial "${_titleController.text}" has been uploaded with file "${_selectedFileInfo!.name}".';

        // Send local notification
        _sendNotification(notificationTitle, notificationBody);

        // Save to database for all users to see
        await _saveNotificationToDatabase(notificationTitle, notificationBody);
      } else if (_linkController.text.isNotEmpty) {
        final String notificationTitle = 'New Tutorial Link Available';
        final String notificationBody =
            'A new tutorial "${_titleController.text}" has been added.';

        // Send local notification
        _sendNotification(notificationTitle, notificationBody);

        // Save to database for all users to see
        await _saveNotificationToDatabase(notificationTitle, notificationBody);
      }
    }

    setState(() {
      isLoading = true;
      isUploading = true;
    });

    try {
      // If we have a selected file, upload it
      if (_selectedFileInfo != null) {
        await _uploadFile();
      } else {
        // If no file, just create an entry in tutorial_files with link
        await _supabase.from('tutorial_files').insert({
          'file_name': _titleController.text,
          'file_type': 'link',
          'file_size': 0,
          'file_url': _linkController.text,
          'description': _descriptionController.text,
          'platform': selectedPlatform,
          'uploaded_at': DateTime.now().toIso8601String(),
          'user_id': _supabase.auth.currentUser?.id,
        });
        _sendNotification(
          'File Uploaded',
          'The file "${_selectedFileInfo!.name}" has been uploaded successfully.',
        );
      }

      _titleController.clear();
      _descriptionController.clear();
      _linkController.clear();
      setState(() {
        selectedPlatform = null;
        _selectedFileInfo = null;
        _fileName = null;
        isUploading = false;
        isLoading = false;
      });
      _fileDescriptionController.clear();

      fetchTutorialFiles(); // Refresh the list

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tutorial added successfully')),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
        isUploading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding tutorial: $e')));
    }
  }

  // Function to pick files directly from the device
  Future<void> _pickFile() async {
    if (!mounted) return;

    try {
      // Wait for the next frame to ensure the widget is fully built
      await Future.delayed(Duration.zero);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'ppt', 'pptx', 'doc', 'docx'],
        withData: true, // Important for web and handling file data directly
      );

      if (result != null && result.files.isNotEmpty) {
        if (!mounted) return;

        setState(() {
          _selectedFileInfo = result.files.first;
          _fileName = _selectedFileInfo!.name;
        });

        print('Selected file: ${_selectedFileInfo!.name}');
        print('File size: ${_selectedFileInfo!.size} bytes');

        // Don't try to log the path on web as it will be null
        if (!kIsWeb && _selectedFileInfo!.path != null) {
          print('File path: ${_selectedFileInfo!.path}');
        } else if (kIsWeb) {
          print(
            'Running on web platform - path is null, bytes available: ${_selectedFileInfo!.bytes != null}',
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File selected: ${_selectedFileInfo!.name}')),
        );
      }
    } catch (e) {
      print('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('File picking error: $e')));
      }
    }
  }

  // Function to upload file to Supabase storage
  Future<void> _uploadFile() async {
    if (_selectedFileInfo == null) {
      print('No file selected');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No file selected')));
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      final fileExtension = _selectedFileInfo!.name.split('.').last;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_selectedFileInfo!.name}';
      final filePath = 'tutorial-files/$fileName';

      print('Starting upload of file: ${_selectedFileInfo!.name}');
      print('Uploading file to: $filePath');
      print('File size: ${_selectedFileInfo!.size} bytes');

      // For larger files, show progress
      if (_selectedFileInfo!.size > 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading large file, please wait...')),
        );
      }

      // Determine proper content type based on file extension
      String contentType;
      switch (fileExtension.toLowerCase()) {
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'ppt':
          contentType = 'application/vnd.ms-powerpoint';
          break;
        case 'pptx':
          contentType =
              'application/vnd.openxmlformats-officedocument.presentationml.presentation';
          break;
        case 'doc':
          contentType = 'application/msword';
          break;
        case 'docx':
          contentType =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        default:
          contentType = 'application/octet-stream';
      }

      String uploadResponse;

      // Simplified upload logic - use bytes for web, path for native platforms when available
      if (kIsWeb) {
        // Web platform - always use bytes
        if (_selectedFileInfo!.bytes != null) {
          uploadResponse = await _supabase.storage
              .from('tutorial-files')
              .uploadBinary(
                filePath,
                _selectedFileInfo!.bytes!,
                fileOptions: FileOptions(
                  contentType: contentType,
                  upsert: true,
                ),
              );
        } else {
          throw Exception('File bytes are null for web upload');
        }
      } else {
        // Native platforms - try path first, fallback to bytes
        if (_selectedFileInfo!.path != null) {
          final file = File(_selectedFileInfo!.path!);
          if (await file.exists()) {
            uploadResponse = await _supabase.storage
                .from('tutorial-files')
                .upload(
                  filePath,
                  file,
                  fileOptions: FileOptions(
                    contentType: contentType,
                    upsert: true,
                  ),
                );
          } else {
            throw Exception('File does not exist at the specified path');
          }
        } else if (_selectedFileInfo!.bytes != null) {
          // Fallback to bytes if path is not available
          uploadResponse = await _supabase.storage
              .from('tutorial-files')
              .uploadBinary(
                filePath,
                _selectedFileInfo!.bytes!,
                fileOptions: FileOptions(
                  contentType: contentType,
                  upsert: true,
                ),
              );
        } else {
          throw Exception(
            'Neither file path nor bytes are available for upload',
          );
        }
      }

      print('Upload response: $uploadResponse');

      // Get the public URL for the uploaded file
      final fileUrl = _supabase.storage
          .from('tutorial-files')
          .getPublicUrl(filePath);

      print('File uploaded successfully. URL: $fileUrl');

      // Create an entry in the tutorial_files table to track the file
      await _supabase.from('tutorial_files').insert({
        'file_name': _selectedFileInfo!.name,
        'file_type': fileExtension,
        'file_size': _selectedFileInfo!.size,
        'file_path': filePath,
        'file_url': fileUrl,
        'description': _fileDescriptionController.text,
        'title':
            _titleController.text.isEmpty
                ? _selectedFileInfo!.name
                : _titleController.text,
        'platform': selectedPlatform,
        'uploaded_at': DateTime.now().toIso8601String(),
        'user_id': _supabase.auth.currentUser?.id,
      });

      setState(() {
        isUploading = false;
        _selectedFileInfo = null;
        _fileName = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error during file upload: $e');
      setState(() {
        isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Add file directly without creating a tutorial
  Future<void> _addFileOnly() async {
    if (_selectedFileInfo == null || selectedPlatform == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file and platform')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      isUploading = true;
    });

    try {
      // Upload file directly to tutorial_files table
      await _uploadFile();

      // After successful upload, create notification
      final String notificationTitle = 'New File Available';
      final String notificationBody =
          'A new file "${_selectedFileInfo!.name}" has been uploaded.';

      // Send local notification
      await _sendNotification(notificationTitle, notificationBody);

      // Save to database for all users to see
      await _saveNotificationToDatabase(notificationTitle, notificationBody);

      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        selectedPlatform = null;
        _selectedFileInfo = null;
        _fileName = null;
        isLoading = false;
        isUploading = false;
      });
      _fileDescriptionController.clear();

      fetchTutorialFiles();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File uploaded successfully')),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
        isUploading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading file: $e')));
    }
  }

  void _showPlatformSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Platform'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildPlatformOption('Google Meet', 'google_meet'),
                _buildPlatformOption('Zoom', 'zoom'),
                _buildPlatformOption('Gmail', 'gmail'),
                _buildPlatformOption('Viber', 'viber'),
                _buildPlatformOption('WhatsApp', 'whatsapp'),
                _buildPlatformOption('Cliqq', 'cliqq'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlatformOption(String name, String value) {
    return ListTile(
      title: Text(name),
      onTap: () {
        setState(() {
          selectedPlatform = value;
        });
        Navigator.of(context).pop();
      },
    );
  }

  // Open a file URL in browser
  // Method with fix for nullable title parameter
  Future<void> _openFileURL(
    String url, [
    String? fileType,
    String? title,
  ]) async {
    // Try to determine file type from URL if not provided
    fileType ??= url.toLowerCase().endsWith('.pdf') ? 'pdf' : null;

    // Default title if null - Added fix for nullable title
    final String safeTitle = title ?? 'File Viewer';

    // Handle PDFs with the internal viewer
    if (fileType == 'pdf') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => PDFViewerPage(
                title: safeTitle,
                fileUrl: url, // Changed from pdfAssetPath
                requiresAuth: false, // Add this based on your security needs
              ),
        ),
      );
    } else {
      // For other files, open in external application
      if (!await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open file: $url')));
      }
    }
  }

  // Delete file from storage and database
  Future<void> _deleteFile(Map<String, dynamic> file) async {
    try {
      // Delete from storage if it's an actual file (not just a link)
      if (file['file_path'] != null && file['file_type'] != 'link') {
        await _supabase.storage.from('tutorial-files').remove([
          file['file_path'],
        ]);
      }

      // Delete from database
      await _supabase.from('tutorial_files').delete().eq('id', file['id']);

      fetchTutorialFiles();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting file: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('Senior Surfers'),
        backgroundColor: const Color(0xFF3B6EA5),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child:
            isLoading &&
                    tutorialFiles
                        .isEmpty // Only show loading if actually loading initial data
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Tutorial or File',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Tutorial Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _linkController,
                        decoration: const InputDecoration(
                          labelText: 'Link (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _showPlatformSelectionDialog,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: const Color(0xFF3B6EA5),
                        ),
                        child: Text(
                          selectedPlatform != null
                              ? 'Selected Platform: ${selectedPlatform!.replaceAll('_', ' ').toUpperCase()}'
                              : 'Select Platform',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Upload File (Optional)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickFile,
                              icon: const Icon(Icons.attach_file),
                              label: Text(
                                _fileName ?? 'Select PDF, PPT, or Document',
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedFileInfo != null) ...[
                        const SizedBox(height: 8),
                        Card(
                          color: const Color(0xFFEBF2FA),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: const BorderSide(
                              color: Color(0xFF3B6EA5),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getFileIcon(
                                        _selectedFileInfo!.name.split('.').last,
                                      ),
                                      color: const Color(0xFF3B6EA5),
                                      size: 28,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Selected File: ${_selectedFileInfo!.name}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _selectedFileInfo = null;
                                          _fileName = null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Size: ${_formatFileSize(_selectedFileInfo!.size)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ready to upload',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _fileDescriptionController,
                          decoration: const InputDecoration(
                            labelText: 'File Description (Optional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isUploading ? null : _addNewTutorial,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B6EA5),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                elevation: 4,
                              ),
                              child:
                                  isUploading
                                      ? const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.0,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'UPLOADING...',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )
                                      : const Text(
                                        'SAVE TUTORIAL',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                            ),
                          ),
                          if (_selectedFileInfo != null) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isUploading ? null : _addFileOnly,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E8B57),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  elevation: 4,
                                ),
                                child:
                                    isUploading
                                        ? const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.0,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'UPLOADING...',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        )
                                        : const Text(
                                          'UPLOAD FILE ONLY',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Current Files',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      tutorialFiles.isEmpty
                          ? const Center(
                            child: Text(
                              'No files available yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                          : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: tutorialFiles.length,
                            itemBuilder: (context, index) {
                              final item = tutorialFiles[index];
                              final bool isLink = item['file_type'] == 'link';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                child: ListTile(
                                  leading: Icon(
                                    isLink
                                        ? Icons.link
                                        : _getFileIcon(item['file_type']),
                                    size: 36,
                                    color:
                                        isLink
                                            ? Colors.blueAccent
                                            : Colors.redAccent,
                                  ),
                                  title: Text(
                                    item['title'] ??
                                        item['file_name'] ??
                                        'Untitled',
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (item['description'] != null)
                                        Text(item['description']),
                                      Text(
                                        'Platform: ${item['platform']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'Unknown'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (!isLink)
                                        Text(
                                          'File Type: ${item['file_type']?.toString().toUpperCase() ?? 'Unknown'}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      if (!isLink && item['file_size'] != null)
                                        Text(
                                          'Size: ${_formatFileSize(item['file_size'])}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (item['file_url'] != null)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.open_in_new,
                                            color: Colors.green,
                                          ),
                                          onPressed:
                                              () => _openFileURL(
                                                item['file_url'],
                                                item['file_type'],
                                                item['title'] ??
                                                    item['file_name'] ??
                                                    'File Viewer',
                                              ),
                                        ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _deleteFile(item),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    ],
                  ),
                ),
      ),
    );
  }

  // First, let's fix the notification methods:

  Future<void> _sendNotification(String title, String body) async {
    try {
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'tutorial_channel',
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Message,
        ),
      );
      print('Local notification sent: $title - $body');
    } catch (e) {
      print('Error sending local notification: $e');
    }
  }

  Future<void> _saveNotificationToDatabase(String title, String message) async {
    try {
      await _supabase.from('notifications').insert({
        'title': title,
        'message': message,
        'created_at':
            DateTime.now().toIso8601String(), // Explicitly set created_at
        'is_read': false, // Default to unread
        'user_id':
            _supabase
                .auth
                .currentUser
                ?.id, // Admin who created the notification
        'for_all_users': true, // Make it available to all users
      });
      print('Notification saved to database: $title');
    } catch (e) {
      print('Error saving notification to database: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving notification: $e')));
    }
  }

  // Helper function to get appropriate icon for file type
  IconData _getFileIcon(String? fileType) {
    if (fileType == null) return Icons.insert_drive_file;

    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Helper function to format file size
  String _formatFileSize(int? bytes) {
    if (bytes == null) return 'Unknown size';

    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
