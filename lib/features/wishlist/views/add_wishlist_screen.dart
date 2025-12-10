import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zentry/core/core.dart';
import 'package:zentry/core/services/firebase/notification_manager.dart';
import 'package:zentry/features/wishlist/wishlist.dart';

class AddWishlistScreen extends StatefulWidget {
  final WishlistController controller;
  final Wish? itemToEdit;

  const AddWishlistScreen({
    super.key,
    required this.controller,
    this.itemToEdit,
  });

  @override
  State<AddWishlistScreen> createState() => _AddWishlistScreenState();
}

class _AddWishlistScreenState extends State<AddWishlistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _newMemberController = TextEditingController();
  final _notesController = TextEditingController();
  final _userService = UserService();
  final _firestoreService = FirestoreService();
  final _cloudinaryService = CloudinaryService();
  final List<String> _teamMembers = [];
  List<String> _suggestedEmails = [];
  bool _isSearching = false;

  String _selectedCategory = 'tech';
  bool _isLoading = false;
  File? _selectedImage;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      _titleController.text = widget.itemToEdit!.title;
      _priceController.text = widget.itemToEdit!.price;
      _notesController.text = widget.itemToEdit!.notes;
      _selectedCategory = widget.itemToEdit!.category;
      _teamMembers.addAll(widget.itemToEdit!.sharedWith);
      _uploadedImageUrl = widget.itemToEdit!.imageUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _newMemberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String category) {
    return widget.controller.getCategoryColor(category);
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
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

  Future<String?> _uploadWishlistImage() async {
    if (_selectedImage == null) return _uploadedImageUrl;

    try {
      final imageUrl = await _cloudinaryService.uploadImage(
        _selectedImage!,
        uploadType: CloudinaryUploadType.wishlistImage,
        publicId: 'wishlist_${DateTime.now().millisecondsSinceEpoch}',
      );
      return imageUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _saveWishlistItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    debugPrint(
        '📝 Saving wishlist with ${_teamMembers.length} shared members: $_teamMembers');

    // Upload image if selected
    String? imageUrl = _uploadedImageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadWishlistImage();
    }

    final bool isEditing = widget.itemToEdit != null;

    // Track member changes if editing
    Set<String>? addedMembers;
    Set<String>? removedMembers;
    if (isEditing) {
      final oldMembers = widget.itemToEdit!.sharedWith.toSet();
      final newMembers = _teamMembers.toSet();
      addedMembers = newMembers.difference(oldMembers);
      removedMembers = oldMembers.difference(newMembers);
    }

    // Build sharedWithDetails with status information
    final List<SharedWithDetail> sharedWithDetails = _teamMembers.map((email) {
      // Check if this is an existing share or new invitation
      if (widget.itemToEdit != null) {
        try {
          final existingShare = widget.itemToEdit!.sharedWithDetails
              .firstWhere((s) => s.email == email);
          
          // Keep existing status for old members
          if (existingShare.status == 'accepted' || existingShare.status == 'rejected') {
            return existingShare;
          }
        } catch (e) {
          // Member not found in existing shares, create new pending invitation
        }
      }
      
      // Create new pending invitation for new members
      return SharedWithDetail(
        email: email,
        status: 'pending',
      );
    }).toList();

    final wish = Wish(
      id: widget.itemToEdit?.id,
      userId: widget.itemToEdit?.userId ?? FirebaseAuth.instance.currentUser?.uid ?? '',
      title: _titleController.text.trim(),
      price: _priceController.text.trim(),
      category: _selectedCategory,
      notes: _notesController.text.trim(),
      dateAdded: widget.itemToEdit?.dateAdded ?? _getCurrentDate(),
      completed: widget.itemToEdit?.completed ?? false,
      sharedWith: _teamMembers,
      sharedWithDetails: sharedWithDetails,
      imageUrl: imageUrl,
    );

    debugPrint('📦 Wish object sharedWith: ${wish.sharedWith}');

    bool success;
    String? createdWishId;
    if (isEditing) {
      success = await widget.controller.updateWish(wish);
      createdWishId = wish.id; // Use existing ID for edits
    } else {
      createdWishId = await widget.controller.createWish(wish);
      success = createdWishId != null;
    }

    // Send notifications to shared members
    if (success && createdWishId != null) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        try {
          final currentUserData =
              await _firestoreService.getUserData(currentUser.uid);
          final currentUserName = currentUserData?['fullName'] ?? 'Someone';

          if (isEditing) {
            // Notify newly added members
            if (addedMembers != null && addedMembers.isNotEmpty) {
              for (final memberEmail in addedMembers) {
                if (memberEmail != currentUser.email) {
                  final memberUserDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .where('email', isEqualTo: memberEmail.toLowerCase())
                      .limit(1)
                      .get();

                  if (memberUserDoc.docs.isNotEmpty) {
                    final memberUserId = memberUserDoc.docs.first.id;
                    await NotificationManager().notifyWishlistInvitation(
                      recipientUserId: memberUserId,
                      wishlistTitle: wish.title,
                      wishlistId: createdWishId,
                      inviterName: currentUserName,
                    );
                  }
                }
              }
            }

            // Notify removed members
            if (removedMembers != null && removedMembers.isNotEmpty) {
              for (final memberEmail in removedMembers) {
                if (memberEmail != currentUser.email) {
                  final memberUserDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .where('email', isEqualTo: memberEmail.toLowerCase())
                      .limit(1)
                      .get();

                  if (memberUserDoc.docs.isNotEmpty) {
                    final memberUserId = memberUserDoc.docs.first.id;
                    await NotificationManager().notifyWishlistRemoval(
                      recipientUserId: memberUserId,
                      wishlistTitle: wish.title,
                      wishlistId: wish.id ?? '',
                      removerName: currentUserName,
                    );
                  }
                }
              }
            }

            // Notify existing accepted members about update (excluding newly added and removed)
            final existingMembers =
                _teamMembers.toSet().difference(addedMembers ?? {});
            for (final memberEmail in existingMembers) {
              if (memberEmail != currentUser.email) {
                // Only notify if they have accepted the wishlist
                final shareDetail = wish.sharedWithDetails
                    .firstWhere((s) => s.email == memberEmail, 
                        orElse: () => SharedWithDetail(email: memberEmail, status: 'pending'));
                
                if (shareDetail.isAccepted) {
                  final memberUserDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .where('email', isEqualTo: memberEmail.toLowerCase())
                      .limit(1)
                      .get();

                  if (memberUserDoc.docs.isNotEmpty) {
                    final memberUserId = memberUserDoc.docs.first.id;
                    await NotificationManager().notifyWishlistUpdate(
                      recipientUserId: memberUserId,
                      wishlistTitle: wish.title,
                      wishlistId: wish.id ?? '',
                      updaterName: currentUserName,
                      action: 'updated',
                    );
                  }
                }
              }
            }
          } else {
            // New wishlist - notify all shared members
            for (final memberEmail in _teamMembers) {
              if (memberEmail != currentUser.email) {
                final memberUserDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .where('email', isEqualTo: memberEmail.toLowerCase())
                    .limit(1)
                    .get();

                if (memberUserDoc.docs.isNotEmpty) {
                  final memberUserId = memberUserDoc.docs.first.id;
                  await NotificationManager().notifyWishlistInvitation(
                    recipientUserId: memberUserId,
                    wishlistTitle: wish.title,
                    wishlistId: createdWishId,
                    inviterName: currentUserName,
                  );
                }
              }
            }
          }
        } catch (e) {
          print('Error sending wishlist notifications: $e');
        }
      }
    }
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.itemToEdit != null
              ? 'Wishlist item updated'
              : 'Wishlist item added'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save wishlist item'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.add_circle, color: selectedColor),
                  const SizedBox(width: 12),
                  const Text('Add Custom Category'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Category Name (e.g., "books")',
                          hintText: 'books',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: selectedColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Category Color',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        Colors.blue,
                        Colors.green,
                        Colors.purple,
                        Colors.orange,
                        Colors.red,
                        Colors.pink,
                        Colors.teal,
                        Colors.indigo,
                        Colors.amber,
                        Colors.cyan,
                        Colors.lime,
                        Colors.brown,
                      ].map((color) {
                        final isSelected = color.value == selectedColor.value;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() => selectedColor = color);
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.grey,
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 20)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a category name'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final categoryName =
                        nameController.text.trim().toLowerCase();
                    final displayLabel = categoryName[0].toUpperCase() +
                        categoryName.substring(1);

                    final success = await widget.controller.createCategory(
                      categoryName,
                      displayLabel,
                      selectedColor.value
                          .toRadixString(16)
                          .padLeft(8, '0')
                          .toUpperCase(),
                    );

                    if (success && mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Category created successfully'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestedEmails.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final suggestions = await _userService.searchUsers(query);
      if (mounted) {
        setState(() {
          _suggestedEmails = suggestions
              .where((email) => !_teamMembers.contains(email))
              .toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestedEmails.clear();
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _addSharedWith() async {
    final member = _newMemberController.text.trim();
    if (member.isEmpty) return;

    if (_teamMembers.contains(member)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This email is already added to the shared list'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      final exists = await _firestoreService.userExistsByEmail(member);
      if (mounted) {
        if (exists) {
          setState(() {
            _teamMembers.add(member);
            _newMemberController.clear();
            _suggestedEmails.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email added successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No account found with this email'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking account: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _selectSuggestedEmail(String email) async {
    if (_teamMembers.contains(email)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This email is already added to the shared list'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      final exists = await _firestoreService.userExistsByEmail(email);
      if (mounted) {
        if (exists) {
          setState(() {
            _teamMembers.add(email);
            _newMemberController.clear();
            _suggestedEmails.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email added successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No account found with this email'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking account: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _removeSharedWith(String email) {
    setState(() {
      _teamMembers.remove(email);
    });
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
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
        title: Text(
          widget.itemToEdit != null
              ? 'Edit Wishlist Item'
              : 'New Wishlist Item',
          style: const TextStyle(
            color: Color(0xFF1E1E1E),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Category Section
            Text(
              'Category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: widget.controller,
              builder: (context, _) {
                return Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.controller.categories.map((category) {
                          final isSelected = _selectedCategory == category.name;
                          final categoryColor =
                              _getCategoryColor(category.name);

                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedCategory = category.name);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? categoryColor
                                    : categoryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? categoryColor
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                category.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textDark,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Add category button
                    GestureDetector(
                      onTap: _showAddCategoryDialog,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 20,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Image Attachment Section
            Text(
              'Item Image (Optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: _selectedImage != null || _uploadedImageUrl != null
                    ? 200
                    : 120,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  image: _selectedImage != null
                      ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                      : _uploadedImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_uploadedImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                ),
                child: _selectedImage == null && _uploadedImageUrl == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to add an image of the item',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        children: [
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _selectedImage = null;
                                _uploadedImageUrl = null;
                              }),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Item Name
            Text(
              'Item Name',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'What do you want to get?',
                filled: true,
                fillColor: AppTheme.surface,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an item name';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Price
            Text(
              'Price',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '0.00',
                prefixText: '₱ ',
                filled: true,
                fillColor: AppTheme.surface,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a price';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Share With
            Text(
              'Share With (Optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            // Add new member input
            Column(
              children: [
                TextFormField(
                  controller: _newMemberController,
                  onChanged: _searchUsers,
                  decoration: InputDecoration(
                    hintText: 'Enter email to share with',
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value.trim())) {
                        return 'Please enter a valid email address';
                      }
                    }
                    return null;
                  },
                ),
                // Suggestions dropdown
                if (_suggestedEmails.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestedEmails.length,
                      itemBuilder: (context, index) {
                        final email = _suggestedEmails[index];
                        return ListTile(
                          title: Text(email),
                          onTap: () => _selectSuggestedEmail(email),
                          dense: true,
                          visualDensity: VisualDensity.compact,
                        );
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Display current shared with emails
            if (_teamMembers.isNotEmpty) ...[
              FutureBuilder<Map<String, Map<String, String>>>(
                future: _userService.getUsersDetailsByEmails(_teamMembers),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Skeleton loading for shared members
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(
                          _teamMembers.length,
                          (index) => Container(
                            height: 32,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final usersDetails = snapshot.data ?? {};
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _teamMembers.map((email) {
                      final userDetails = usersDetails[email] ?? {};
                      final displayName =
                          _userService.getDisplayName(userDetails, email);
                      return Chip(
                        label: Text(displayName),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeSharedWith(email),
                        backgroundColor: Colors.grey.shade100,
                        deleteIconColor: Colors.red.shade600,
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 20),

            // Notes
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Why do you want this?',
                filled: true,
                fillColor: AppTheme.surface,
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveWishlistItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.textDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.textDark,
                        ),
                      )
                    : Text(
                        widget.itemToEdit != null ? 'Save Changes' : 'Add Item',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
