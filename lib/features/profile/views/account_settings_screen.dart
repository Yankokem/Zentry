import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:zentry/core/core.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();

  String? _profileImageUrl;
  File? _selectedImage;
  bool _isLoading = false;
  bool _isSaving = false;
  String _phoneNumber = '';
  String _countryCode = '';
  String? _selectedCountry;
  
  // Password fields
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isGoogleUser = false;
  bool _hasPassword = false;
  bool _showPasswordSection = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _zipCodeController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _firestoreService.getUserData(user.uid);

        if (userData != null && mounted) {
          final storedPhoneNumber = userData['phoneNumber'] as String? ?? '';
          final storedCountryCode = userData['countryCode'] as String? ?? '';
          
          setState(() {
            _firstNameController.text = userData['firstName'] as String? ?? '';
            _lastNameController.text = userData['lastName'] as String? ?? '';
            _emailController.text = user.email ?? '';
            _phoneNumber = storedPhoneNumber;
            _profileImageUrl = userData['profileImageUrl'] as String?;
            // If no country code saved, default to PH
            _countryCode = storedCountryCode.isNotEmpty ? storedCountryCode : 'PH';

            // Load location fields
            _selectedCountry = userData['country'] as String?;

            // Check if user is Google sign-in and if they have a password
            final providerData = user.providerData;
            _isGoogleUser = providerData.any((info) => info.providerId == 'google.com');
            _hasPassword = providerData.any((info) => info.providerId == 'password');
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<String?> _uploadProfileImage(String userId) async {
    if (_selectedImage == null) return _profileImageUrl;

    try {
      // Upload to Cloudinary using the account photo preset
      // Note: publicId removed because unsigned presets don't support it
      final imageUrl = await _cloudinaryService.uploadImage(
        _selectedImage!,
        uploadType: CloudinaryUploadType.accountPhoto,
      );
      
      // Update the preview immediately after successful upload
      if (mounted) {
        debugPrint('Image URL from Cloudinary: $imageUrl');
        setState(() {
          _profileImageUrl = imageUrl;
          _selectedImage = null; // Clear selected image since upload succeeded
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      return imageUrl;
    } catch (e) {
      // Extract the actual error message
      String errorMsg = e.toString();
      if (errorMsg.contains('Exception:')) {
        errorMsg = errorMsg.replaceAll('Exception: ', '');
      }
      if (errorMsg.contains('Failed to upload image to Cloudinary:')) {
        errorMsg = errorMsg.replaceAll('Failed to upload image to Cloudinary: ', '');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
      // Re-throw so _saveChanges can handle it
      rethrow;
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Upload profile image if changed
      String? imageUrl;
      try {
        imageUrl = await _uploadProfileImage(user.uid);
      } catch (e) {
        // If image upload fails, continue with other updates
        // Error message already shown in _uploadProfileImage
        imageUrl = null;
      }

      // Update display name in Firebase Auth
      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      await user.updateDisplayName(fullName);

      // Update email if changed
      if (_emailController.text.trim() != user.email) {
        await user.verifyBeforeUpdateEmail(_emailController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Verification email sent. Please check your inbox.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }

      // Handle password update
      if (_newPasswordController.text.trim().isNotEmpty) {
        // Validate password match
        if (_newPasswordController.text.trim() != _confirmPasswordController.text.trim()) {
          throw Exception('New passwords do not match');
        }
        
        if (_newPasswordController.text.trim().length < 6) {
          throw Exception('Password must be at least 6 characters');
        }
        
        if (_hasPassword) {
          // User already has a password - need to verify current password
          if (_currentPasswordController.text.trim().isEmpty) {
            throw Exception('Please enter your current password');
          }
          
          // Re-authenticate with current password
          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: _currentPasswordController.text.trim(),
          );
          await user.reauthenticateWithCredential(credential);
        } else if (_isGoogleUser) {
          // Google user setting password for the first time
          // Need to re-authenticate with Google before adding password
          final GoogleAuthProvider googleProvider = GoogleAuthProvider();
          await user.reauthenticateWithProvider(googleProvider);
        }
        
        // Update to new password
        await user.updatePassword(_newPasswordController.text.trim());
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully')),
          );
          // Update _hasPassword flag
          setState(() {
            _hasPassword = true;
          });
        }
      }

      // Update Firestore data
      await _firestoreService.updateUserData(user.uid, {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'fullName': fullName,
        'phoneNumber': _phoneNumber,
        'countryCode': _countryCode,
        'country': _selectedCountry ?? '',
        if (imageUrl != null) 'profileImageUrl': imageUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Clear password fields after successful save
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _showPasswordSection = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving changes: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Account Settings'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveChanges,
              child: Text(
                'Save',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFF9ED69) // Yellow for dark mode
                      : Colors.black, // Black for light mode
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Photo Section
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey[300],
                                child: _selectedImage != null
                                    ? Container(
                                        color: Colors.grey[300],
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.image_outlined,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Ready to upload',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : _profileImageUrl != null
                                        ? Image.network(
                                            _profileImageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              debugPrint('Error loading network image in account settings: $error');
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded /
                                                          loadingProgress.expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
                                          )
                                        : Container(
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Colors.grey,
                                            ),
                                          ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap to change photo',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Personal Information Section
                Text(
                  'Personal Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),

                // First Name
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Last Name
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Contact Information Section
                Text(
                  'Contact Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),

                // Phone Number
                IntlPhoneField(
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                  ),
                  initialCountryCode: _countryCode,
                  initialValue: _phoneNumber.isNotEmpty
                      ? _phoneNumber.replaceAll(RegExp(r'^\+\d+\s*'), '').trim()
                      : null,
                  onChanged: (phone) {
                    setState(() {
                      _phoneNumber = phone.completeNumber;
                      _countryCode = phone.countryISOCode;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Country Selector
                InkWell(
                  onTap: () {
                    showCountryPicker(
                      context: context,
                      showPhoneCode: false,
                      onSelect: (Country country) {
                        setState(() {
                          _selectedCountry = country.name;
                        });
                      },
                    );
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Country',
                      prefixIcon: const Icon(Icons.public),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                    ),
                    child: Text(
                      _selectedCountry ?? 'Select Country',
                      style: TextStyle(
                        color: _selectedCountry != null
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Security Section
                Text(
                  'Security',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),

                // Password Section
                if (_isGoogleUser && !_hasPassword)
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusLarge),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.security,
                          color: Colors.orange[700],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You signed in with Google. Add a password to enable email sign-in.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.orange[700],
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (_isGoogleUser && !_hasPassword) const SizedBox(height: 16),

                // Toggle password section
                InkWell(
                  onTap: () {
                    setState(() {
                      _showPasswordSection = !_showPasswordSection;
                      if (!_showPasswordSection) {
                        _currentPasswordController.clear();
                        _newPasswordController.clear();
                        _confirmPasswordController.clear();
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lock_outline),
                            const SizedBox(width: 12),
                            Text(
                              _hasPassword ? 'Change Password' : 'Set Password',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                        Icon(_showPasswordSection
                            ? Icons.expand_less
                            : Icons.expand_more),
                      ],
                    ),
                  ),
                ),

                // Password fields (shown when expanded)
                if (_showPasswordSection) ...[
                  const SizedBox(height: 16),
                  
                  if (_hasPassword) ...[
                    TextFormField(
                      controller: _currentPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMedium),
                        ),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _newPasswordController,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      hintText: 'At least 6 characters',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                    ),
                    obscureText: true,
                  ),
                ],

                const SizedBox(height: 32),

                // Info Card
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusLarge),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Changing your email will require verification. You will receive a verification email at your new address.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.blue[700],
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
