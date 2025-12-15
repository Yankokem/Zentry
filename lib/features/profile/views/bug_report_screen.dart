import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:zentry/core/core.dart';
import 'package:zentry/features/admin/admin.dart';
import 'package:zentry/features/journal/journal.dart';

class BugReportScreen extends StatefulWidget {
  const BugReportScreen({super.key});

  @override
  State<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends State<BugReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentEditorController = RichTextEditorController();
  final _bugReportService = BugReportService();
  final _cloudinaryService = CloudinaryService();

  String _selectedCategory = 'General';
  bool _isSubmitting = false;
  final List<File> _selectedImages = [];

  final List<String> _categories = [
    'General',
    'UI/UX',
    'Performance',
    'Authentication',
    'Data Sync',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _contentEditorController.clear();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentEditorController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles.map((f) => File(f.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Image Error', 'Error picking images: ${e.toString()}');
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitBugReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final authService = AuthService();
      final user = authService.currentUser;
      if (user == null) {
        _showErrorDialog('Login Required', 'Please log in to submit a bug report');
        return;
      }

      // Upload images to Cloudinary
      List<String> imageUrls = [];
      for (var imageFile in _selectedImages) {
        try {
          final url = await _cloudinaryService.uploadImage(
            imageFile,
            uploadType: CloudinaryUploadType.bugReport,
          );
          imageUrls.add(url);
        } catch (e) {
          if (mounted) {
            _showErrorDialog('Upload Error', 'Failed to upload image: ${e.toString()}');
          }
        }
      }

      // Get rich text content as JSON
      final content = _contentEditorController.getJsonContent();

      final bugReport = BugReportModel.create(
        userId: user.uid,
        userEmail: user.email ?? '',
        title: _titleController.text.trim(),
        content: content,
        category: _selectedCategory,
        imageUrls: imageUrls,
      );

      await _bugReportService.submitBugReport(bugReport);

      if (mounted) {
        _showSuccessDialog('Bug Report Submitted', 'Bug report submitted successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Submit Failed', 'Failed to submit bug report: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        icon: const Icon(Icons.error, color: Colors.red, size: 32),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 32),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9ED69),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1E1E1E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Report a Bug',
          style: TextStyle(
            color: Color(0xFF1E1E1E),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bug_report, size: 20, color: AppTheme.textDark),
                  SizedBox(width: 8),
                  Text(
                    'Report a Bug',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Help us improve by providing detailed information about the issue.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textDark.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Bug Title',
                  hintText: 'Brief description of the issue',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value!);
                  },
                ),
                const SizedBox(height: 24),

                // Rich Text Editor Label
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),

                // Rich Text Editor
                RichTextEditor(
                  controller: _contentEditorController,
                  hintText: 'Describe the issue in detail...',
                ),
                const SizedBox(height: 24),

                // Images Section
                const Text(
                  'Screenshots or Evidence',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add images to help us understand the issue better',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),

                // Upload Button
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_photo_alternate_rounded),
                  label: const Text('Add Images'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: AppTheme.textDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Image Preview
                if (_selectedImages.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_selectedImages.length} image(s) selected',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image:
                                            FileImage(_selectedImages[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        padding: const EdgeInsets.all(2),
                                        child: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitBugReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.textDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Submit Bug Report',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
}
