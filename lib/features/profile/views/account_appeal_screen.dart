import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:zentry/core/core.dart';
import 'package:zentry/features/admin/admin.dart';
import 'package:zentry/features/journal/journal.dart';

class AccountAppealScreen extends StatefulWidget {
  final String? userId;
  final String? userEmail;
  final String? status;

  const AccountAppealScreen({
    super.key,
    this.userId,
    this.userEmail,
    this.status,
  });

  @override
  State<AccountAppealScreen> createState() => _AccountAppealScreenState();
}

class _AccountAppealScreenState extends State<AccountAppealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentEditorController = RichTextEditorController();
  final _appealService = AccountAppealService();
  final _cloudinaryService = CloudinaryService();
  final _authService = AuthService();

  String _selectedReason = 'suspension';
  bool _isSubmitting = false;
  final List<File> _selectedImages = [];

  final List<String> _reasons = ['suspension', 'ban'];
  final Map<String, String> _reasonDisplay = {
    'suspension': 'Account Suspension',
    'ban': 'Account Ban',
  };

  @override
  void initState() {
    super.initState();
    _contentEditorController.clear();
    // Set reason based on passed status
    if (widget.status != null) {
      _selectedReason = widget.status == 'banned' ? 'ban' : 'suspension';
    }
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

  Future<void> _submitAppeal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Use passed userId/userEmail if available (from login dialog), otherwise use current auth user
      String? userId = widget.userId;
      String? userEmail = widget.userEmail;

      if (kDebugMode) {
        print('🔍 Starting appeal submission...');
        print('  Widget userId: $userId');
        print('  Widget userEmail: $userEmail');
      }

      if (userId == null || userEmail == null) {
        final user = _authService.currentUser;
        if (user == null) {
          _showErrorDialog('Login Required', 'Please log in to submit an appeal');
          return;
        }
        userId = user.uid;
        userEmail = user.email ?? '';
        
        if (kDebugMode) {
          print('  Using current user:');
          print('    userId: $userId');
          print('    userEmail: $userEmail');
        }
      }

      // Upload images to Cloudinary
      List<String> evidenceUrls = [];
      for (var imageFile in _selectedImages) {
        try {
          final url = await _cloudinaryService.uploadImage(
            imageFile,
            uploadType: CloudinaryUploadType.accountAppeal,
          );
          evidenceUrls.add(url);
        } catch (e) {
          if (mounted) {
            _showErrorDialog('Upload Error', 'Failed to upload image: ${e.toString()}');
          }
        }
      }

      // Get rich text content as JSON
      final content = _contentEditorController.getJsonContent();

      if (kDebugMode) {
        print('  Appeal details:');
        print('    Title: ${_titleController.text.trim()}');
        print('    Reason: $_selectedReason');
        print('    Evidence count: ${_selectedImages.length}');
        print('    Evidence URLs: $evidenceUrls');
      }

      final appeal = AccountAppealModel.create(
        userId: userId,
        userEmail: userEmail,
        reason: _selectedReason,
        title: _titleController.text.trim(),
        content: content,
        evidenceUrls: evidenceUrls,
      );

      if (kDebugMode) {
        print('  Creating appeal object:');
        print('    appeal.userId: ${appeal.userId}');
        print('    appeal.userEmail: ${appeal.userEmail}');
        print('    appeal.status: ${appeal.status}');
        print('    appeal.createdAt: ${appeal.createdAt}');
      }

      if (kDebugMode) {
        print('📤 Calling _appealService.submitAppeal()...');
      }

      await _appealService.submitAppeal(appeal);

      if (mounted) {
        _showSuccessDialog('Appeal Submitted', 'Appeal submitted successfully!');
        // Sign out the user after appeal submission is complete
        await _authService.signOut();
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Submit Failed', 'Failed to submit appeal: ${e.toString()}');
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
          onPressed: () async {
            // Sign out user when closing appeal screen
            await _authService.signOut();
            if (context.mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
        ),
        title: const Text(
          'Appeal Suspension or Ban',
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
                  Icon(Icons.security_rounded,
                      size: 20, color: AppTheme.textDark),
                  SizedBox(width: 8),
                  Text(
                    'Appeal Your Account',
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
                'Provide detailed information about why you believe your account restriction should be lifted.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textDark.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),

              // Reason Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedReason,
                decoration: InputDecoration(
                  labelText: 'Restriction Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: _reasons.map((reason) {
                    return DropdownMenuItem(
                      value: reason,
                      child: Text(_reasonDisplay[reason]!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedReason = value!);
                  },
                ),
                const SizedBox(height: 16),

                // Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Appeal Title',
                    hintText: 'Brief summary of your appeal',
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
                const SizedBox(height: 24),

                // Rich Text Editor Label
                const Text(
                  'Appeal Description',
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
                  hintText:
                      'Explain why you believe your restriction should be lifted...',
                ),
                const SizedBox(height: 24),

                // Evidence Section
                const Text(
                  'Supporting Evidence',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add screenshots or documents to support your appeal',
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
                  label: const Text('Add Evidence'),
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
                        '${_selectedImages.length} file(s) selected',
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
                    onPressed: _isSubmitting ? null : _submitAppeal,
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
                            'Submit Appeal',
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
