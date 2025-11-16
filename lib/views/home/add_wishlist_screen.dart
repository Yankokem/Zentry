import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../controllers/wishlist_controller.dart';
import '../../models/wish_model.dart';
import '../../services/firebase/firestore_service.dart';
import '../../services/firebase/user_service.dart';

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
  List<String> _teamMembers = [];
  List<String> _suggestedEmails = [];
  bool _isSearching = false;

  String _selectedCategory = 'tech';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      _titleController.text = widget.itemToEdit!.title;
      _priceController.text = widget.itemToEdit!.price;
      _notesController.text = widget.itemToEdit!.notes;
      _selectedCategory = widget.itemToEdit!.category;
      _teamMembers.addAll(widget.itemToEdit!.sharedWith);
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

  Future<void> _saveWishlistItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final wish = Wish(
      id: widget.itemToEdit?.id,
      title: _titleController.text.trim(),
      price: _priceController.text.trim(),
      category: _selectedCategory,
      notes: _notesController.text.trim(),
      dateAdded: widget.itemToEdit?.dateAdded ?? _getCurrentDate(),
      completed: widget.itemToEdit?.completed ?? false,
      sharedWith: _teamMembers,
    );

    bool success;
    if (widget.itemToEdit != null) {
      success = await widget.controller.updateWish(wish);
    } else {
      success = await widget.controller.createWish(wish);
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
                                color:
                                    isSelected ? Colors.black : Colors.grey,
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

                    final categoryName = nameController.text.trim().toLowerCase();
                    final displayLabel = categoryName[0].toUpperCase() + categoryName.substring(1);

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
          _suggestedEmails = suggestions.where((email) => !_teamMembers.contains(email)).toList();
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

  void _selectSuggestedEmail(String email) {
    setState(() {
      _newMemberController.text = email;
      _suggestedEmails.clear();
    });
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
          widget.itemToEdit != null ? 'Edit Wishlist Item' : 'New Wishlist Item',
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
                          final categoryColor = _getCategoryColor(category.name);
                          
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
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          suffixIcon: _isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : null,
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                              return 'Please enter a valid email address';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addSharedWith,
                      icon: const Icon(Icons.add, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.textDark,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _teamMembers.map((email) {
                  return Chip(
                    label: Text(email),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeSharedWith(email),
                    backgroundColor: Colors.grey.shade100,
                    deleteIconColor: Colors.red.shade600,
                  );
                }).toList(),
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



