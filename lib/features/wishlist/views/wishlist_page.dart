import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:zentry/core/core.dart';
import 'package:zentry/features/wishlist/wishlist.dart';

class WishlistPage extends StatefulWidget {
  final String? highlightWishId;
  final String? showModalForWishId;

  const WishlistPage({super.key, this.highlightWishId, this.showModalForWishId});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  WishlistController? _controller;
  String _selectedCategory = 'all';
  String _selectedOwnership = 'personal'; // Default to 'personal'
  final UserService _userService = UserService();
  Map<String, Map<String, String>> _userDetails = {};
  String? _highlightedWishId;
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFF9ED69),
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    // Get controller from provider instead of creating a new one
    // Use addPostFrameCallback to ensure provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final provider = Provider.of<WishlistProvider>(context, listen: false);
      if (provider.isInitialized) {
        _controller = provider.controller;
        _loadUserDetails();
        
        // Show modal immediately if showModalForWishId is provided
        if (widget.showModalForWishId != null) {
          _showModalForWishId(widget.showModalForWishId!);
        }
      }
    });

    // Set up highlight if wish ID was provided (for backward compatibility)
    if (widget.highlightWishId != null) {
      _highlightedWishId = widget.highlightWishId;
      // Clear highlight after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _highlightedWishId = null;
          });
        }
      });
    }
  }

  Future<void> _loadUserDetails() async {
    if (_controller == null) return;
    setState(() => _isLoadingUsers = true);
    final allEmails = <String>{};
    for (final wish in _controller!.wishes) {
      allEmails.addAll(wish.sharedWith);
    }

    final details = <String, Map<String, String>>{};
    for (final email in allEmails) {
      final userDetails = await _userService.getUserDetailsByEmail(email);
      details[email] = userDetails;
    }

    if (mounted) {
      setState(() {
        _userDetails = details;
        _isLoadingUsers = false;
      });
    }
  }

  @override
  void dispose() {
    // Don't dispose the controller - it's managed by the Provider
    super.dispose();
  }

  List<Wish> _getFilteredItems() {
    if (_controller == null) return [];
    final wishes = _controller!.wishes;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    // First filter by ownership (personal/shared)
    List<Wish> filtered = wishes;
    if (_selectedOwnership == 'personal') {
      filtered = wishes.where((wish) => wish.isOwner(currentUserId)).toList();
    } else if (_selectedOwnership == 'shared') {
      filtered = wishes.where((wish) => !wish.isOwner(currentUserId)).toList();
    }
    
    // Then filter by category
    if (_selectedCategory != 'all') {
      filtered = filtered.where((item) => item.category == _selectedCategory).toList();
    }

    // Sort by dateAdded in descending order (most recent first)
    filtered.sort((a, b) {
      DateTime? dateA = _parseDate(a.dateAdded);
      DateTime? dateB = _parseDate(b.dateAdded);

      // If parsing fails, treat as equal (maintain original order)
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1; // null dates go to the end
      if (dateB == null) return -1;

      return dateB.compareTo(dateA); // Descending order
    });

    return filtered;
  }

  DateTime? _parseDate(String dateString) {
    try {
      // Expected format: "Jan 1, 2023"
      final months = {
        'Jan': 1,
        'Feb': 2,
        'Mar': 3,
        'Apr': 4,
        'May': 5,
        'Jun': 6,
        'Jul': 7,
        'Aug': 8,
        'Sep': 9,
        'Oct': 10,
        'Nov': 11,
        'Dec': 12
      };

      final parts = dateString.split(' ');
      if (parts.length != 3) return null;

      final month = months[parts[0]];
      final day = int.tryParse(parts[1].replaceAll(',', ''));
      final year = int.tryParse(parts[2]);

      if (month == null || day == null || year == null) return null;

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  Color _getCategoryColor(String category) {
    return _controller?.getCategoryColor(category) ?? Colors.grey;
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
    // Show loading indicator if controller is not yet initialized
    if (_controller == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9ED69),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E1E1E)),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, _) {
        final filteredItems = _getFilteredItems();

        return Scaffold(
          backgroundColor: const Color(0xFFF9ED69),
          body: Column(
            children: [
              // Header - EXACTLY like journal
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF9ED69),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox.shrink(),
                            IconButton(
                              icon: const Icon(Icons.add),
                              color: const Color(0xFF1E1E1E),
                              onPressed: _showAddDialog,
                            ),
                          ],
                        ),
                        Text(
                          'My Wishlist',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E1E1E),
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Things I want to get',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFF1E1E1E)
                                          .withOpacity(0.7),
                                    ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_controller!.completedCount}/${_controller!.totalCount} items',
                                style: const TextStyle(
                                  color: Color(0xFFF9ED69),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildCategoryChip('all', 'All'),
                              const SizedBox(width: 8),
                              ..._controller!.categories.map((category) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: _buildCategoryChip(
                                      category.name, category.label),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Items list with toggle inside
              Expanded(
                child: Container(
                  color: Colors.grey.shade100,
                  child: Column(
                    children: [
                      // Ownership filter toggle
                      Container(
                        color: Colors.grey.shade100,
                        padding: const EdgeInsets.fromLTRB(
                          AppConstants.paddingLarge,
                          12,
                          AppConstants.paddingLarge,
                          12,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: const Color(0xFFF9ED69),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildOwnershipToggle('personal', 'Personal'),
                              ),
                              Expanded(
                                child: _buildOwnershipToggle('shared', 'Shared'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Items list
                      Expanded(
                        child: filteredItems.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                                itemCount: filteredItems.length,
                                itemBuilder: (context, index) {
                                  return _buildWishCard(filteredItems[index]);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Consumer<WishlistProvider>(
            builder: (context, wishlistProvider, _) {
              return FloatingNavBar(
                currentIndex: 1, // Wishlist is index 1
                onTap: (index) {
                  if (index == 1) return; // Already on wishlist
                  Navigator.pushReplacementNamed(context, '/');
                },
                wishlistController: wishlistProvider.isInitialized ? wishlistProvider.controller : null,
              );
            },
          ),
          extendBody: true,
        );
      },
    );
  }

  Widget _buildOwnershipToggle(String ownership, String label) {
    final isSelected = _selectedOwnership == ownership;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOwnership = ownership;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF9ED69) : Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1E1E1E) : const Color(0xFF1E1E1E),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label) {
    final isSelected = _selectedCategory == category;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = category;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF1E1E1E),
      checkmarkColor: const Color(0xFFF9ED69),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFFF9ED69) : const Color(0xFF1E1E1E),
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF1E1E1E) : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildWishCard(Wish item) {
    final color = _getCategoryColor(item.category);
    final isCompleted = item.completed;
    final isHighlighted = _highlightedWishId == item.id;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withOpacity(0.15) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted 
              ? color.withOpacity(0.8)
              : (isCompleted ? Colors.green : color.withOpacity(0.3)),
          width: isHighlighted ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted 
                ? color.withOpacity(0.3)
                : (isCompleted ? Colors.green : color).withOpacity(0.1),
            blurRadius: isHighlighted ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showItemDetails(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Checkbox on the left
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.withOpacity(0.1)
                          : color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_circle : Icons.circle_outlined,
                      color: isCompleted ? Colors.green : color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E1E1E),
                                  decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCompleted)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check, size: 12, color: Colors.green),
                                    SizedBox(width: 4),
                                    Text(
                                      'Acquired',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              item.dateAdded,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '₱${item.price}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    color: Colors.grey.shade600,
                    onPressed: () => _showOptionsMenu(item),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.notes,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                  decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isCompleted ? Colors.green : color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: (isCompleted ? Colors.green : color).withOpacity(0.8),
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      if (_controller != null) {
                        await _controller!.toggleCompleted(item);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.grey.shade300 : Colors.green,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCompleted ? Icons.close : Icons.check,
                            size: 12,
                            color: isCompleted ? Colors.grey.shade600 : Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCompleted ? 'Not Acquired' : 'Mark Acquired',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isCompleted ? Colors.grey.shade600 : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_giftcard,
            size: 80,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No items yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first wish',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  void _showModalForWishId(String wishId) {
    if (_controller == null) return;
    
    // Find the wish item by ID
    final wish = _controller!.wishes.firstWhere(
      (w) => w.id == wishId,
      orElse: () => _controller!.wishes.first, // Fallback to first item if not found
    );
    
    // Small delay to ensure the page is fully built before showing modal
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _showItemDetails(wish);
      }
    });
  }

  void _showItemDetails(Wish item) async {
    final color = _getCategoryColor(item.category);
    final isCompleted = item.completed;

    // Debug logging
    debugPrint('🔍 Showing wishlist details for: ${item.title}');
    debugPrint('   imageUrls count: ${item.imageUrls.length}');
    debugPrint('   imageUrls: ${item.imageUrls}');
    debugPrint('   userId: ${item.userId}');
    debugPrint('   sharedByUserId: ${item.sharedByUserId}');
    debugPrint('   currentUserId: ${FirebaseAuth.instance.currentUser?.uid}');
    debugPrint('   isOwner: ${item.isOwner(FirebaseAuth.instance.currentUser?.uid ?? '')}');

    // Load user details for this specific item
    if (item.sharedWith.isNotEmpty) {
      for (final email in item.sharedWith) {
        if (!_userDetails.containsKey(email)) {
          final details = await _userService.getUserDetailsByEmail(email);
          if (mounted) {
            setState(() {
              _userDetails[email] = details;
            });
          }
        }
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (isCompleted ? Colors.green : color).withOpacity(0.2),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isCompleted ? Colors.green : color)
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: (isCompleted ? Colors.green : color)
                                .withOpacity(0.9),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        item.dateAdded,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '₱${item.price}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Carousel (if images exist)
                    if (item.imageUrls.isNotEmpty) ...[
                      SizedBox(
                        height: 200,
                        child: PageView.builder(
                          itemCount: item.imageUrls.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                // Show full-screen image viewer
                                showDialog(
                                  context: context,
                                  builder: (context) => _FullScreenImageViewer(
                                    imageUrls: item.imageUrls,
                                    initialIndex: index,
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey.shade200,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    item.imageUrls[index],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade300,
                                        child: const Icon(Icons.broken_image),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Item Acquired Toggle - simplified, checkbox removed
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isCompleted
                                      ? 'Item Acquired'
                                      : 'Mark as Acquired',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isCompleted
                                        ? Colors.green
                                        : Colors.grey.shade800,
                                  ),
                                ),
                                Text(
                                  isCompleted
                                      ? 'You have this item in your collection'
                                      : 'Tap to mark this item as acquired',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isCompleted,
                            onChanged: (value) async {
                              final success =
                                  await _controller!.toggleCompleted(item);
                              if (success && mounted) {
                                Navigator.pop(context);
                              }
                            },
                            activeThumbColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Show "Shared By" section if this is a shared wishlist (not owned by current user)
                    if (!item.isOwner(FirebaseAuth.instance.currentUser?.uid ?? '') && 
                        item.sharedByUserId != null && 
                        item.sharedByUserId!.isNotEmpty) ...[
                      FutureBuilder<Map<String, String>?>(
                        future: _userService.getUserDetailsByUid(item.sharedByUserId!),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data == null) {
                            return const SizedBox();
                          }
                          
                          final ownerDetails = snapshot.data ?? {};
                          final ownerName = ownerDetails['fullName'] ?? ownerDetails['email'] ?? 'Unknown';
                          final profileUrl = ownerDetails['profilePictureUrl'] ?? '';
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shared By',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundImage: profileUrl.isNotEmpty
                                        ? NetworkImage(profileUrl)
                                        : null,
                                    backgroundColor: Colors.grey.shade300,
                                    child: profileUrl.isEmpty
                                        ? Text(
                                            ownerName.isNotEmpty
                                                ? ownerName[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ownerName,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          ownerDetails['email'] ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                    ],
                    // Only show Shared With section to the owner and if there are shares
                    if (item.isOwner(FirebaseAuth.instance.currentUser?.uid ?? '') && 
                        item.sharedWithDetails.isNotEmpty) ...[
                      Text(
                        'Shared With',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      ...item.sharedWithDetails.map((shareDetail) {
                        final email = shareDetail.email;
                        final details = _userDetails[email] ?? {};
                        final fullName = details['fullName'] ?? '';
                        final displayName =
                            fullName.isNotEmpty ? fullName : email;
                        final profileUrl =
                            details['profilePictureUrl'] ?? '';
                        final isPending = shareDetail.isPending;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: profileUrl.isNotEmpty
                                    ? NetworkImage(profileUrl)
                                    : null,
                                backgroundColor: isPending 
                                    ? Colors.orange.shade100 
                                    : Colors.grey.shade300,
                                child: profileUrl.isEmpty
                                    ? Text(
                                        displayName.isNotEmpty
                                            ? displayName[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isPending 
                                              ? Colors.orange.shade700 
                                              : Colors.grey.shade700,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (isPending)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Pending',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      'Notes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.notes,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.grey.shade800,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Show edit/delete only to owner
                  if (item.isOwner(FirebaseAuth.instance.currentUser?.uid ?? '')) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditDialog(item);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF9ED69),
                          foregroundColor: const Color(0xFF1E1E1E),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDelete(item);
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Shared users can only view - show info text
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Shared item - View only',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu(Wish item) {
    final isCompleted = item.completed;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                isCompleted ? Icons.radio_button_unchecked : Icons.check_circle,
                color: isCompleted ? Colors.orange : Colors.green,
              ),
              title: Text(
                  isCompleted ? 'Mark as Not Acquired' : 'Mark as Acquired'),
              onTap: () async {
                Navigator.pop(context);
                final success = await _controller!.toggleCompleted(item);
                if (success && mounted) {
                  _showSuccessDialog(
                    isCompleted ? 'Item Marked as Not Acquired' : 'Item Marked as Acquired',
                    isCompleted ? 'Item has been marked as not acquired.' : 'Item has been marked as acquired!'
                  );
                }
              },
            ),
            // Only show edit/delete to owner
            if (item.isOwner(FirebaseAuth.instance.currentUser?.uid ?? '')) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF1E1E1E)),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(item);
                },
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Wish item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _controller!.deleteWish(item);
              if (success && mounted) {
                _showSuccessDialog('Item Deleted', 'The item has been successfully deleted.');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    Navigator.pushNamed(
      context,
      '/add-wish',
      arguments: {
        'controller': _controller,
      },
    );
  }

  void _showEditDialog(Wish item) {
    Navigator.pushNamed(
      context,
      '/add-wish',
      arguments: {
        'controller': _controller,
        'itemToEdit': item,
      },
    );
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
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Category Name (e.g., "Books")',
                        hintText: 'Books',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Category Color',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Color picker - simple grid of colors
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
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey.shade300,
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
                    if (nameController.text.isEmpty) {
                      _showErrorDialog('Validation Error', 'Please fill in all fields');
                      return;
                    }
                    final String name = nameController.text.trim();
                    final String label = name;
                    final String nameLower = name.toLowerCase();

                    final success = await _controller!.createCategory(
                      nameLower,
                      label,
                      selectedColor.value
                          .toRadixString(16)
                          .padLeft(8, '0')
                          .toUpperCase(),
                    );

                    if (success && mounted) {
                      Navigator.pop(context);
                      _showSuccessDialog('Category Created', 'Category created successfully');
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
}

/// Full-screen image viewer with carousel and swipe support
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemCount: widget.imageUrls.length,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              color: Colors.grey[400],
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Unable to load image',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${widget.imageUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
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
