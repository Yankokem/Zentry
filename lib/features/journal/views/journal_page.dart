import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:zentry/core/core.dart';
import 'package:zentry/features/journal/journal.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final JournalService _journalService = JournalService();
  final MoodService _moodService = MoodService();
  List<JournalEntry> _entries = [];
  List<Mood> _moods = Mood.defaultMoods;
  bool _isLoading = true;

  StreamSubscription? _entriesSubscription;
  StreamSubscription? _moodsSubscription;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFF9ED69),
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _loadEntries();
    _loadMoods();
  }

  void _loadEntries() {
    _entriesSubscription?.cancel();
    _entriesSubscription = _journalService.getEntriesStream().listen((entries) {
      if (mounted) {
        setState(() {
          _entries = entries;
          _isLoading = false;
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Only show error if not a permission denied error caused by logout
        if (!error.toString().contains('permission-denied')) {
          _showErrorDialog('Error loading entries', error.toString());
        }
      }
    });
  }

  void _loadMoods() {
    // Start with default moods immediately
    _moods = Mood.defaultMoods;

    // Then listen for updates from Firestore (will include custom moods)
    _moodsSubscription?.cancel();
    _moodsSubscription = _moodService.getMoodsStream().listen((moods) {
      if (mounted) {
        setState(() {
          _moods = moods;
        });
      }
    });
  }

  @override
  void dispose() {
    _entriesSubscription?.cancel();
    _moodsSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<JournalEntry> _getFilteredEntries() {
    if (_searchQuery.isEmpty) return _entries;

    return _entries.where((entry) {
      return entry.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          entry.content.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Color _getMoodColor(String moodName) {
    try {
      // Try exact match first
      final mood = _moods.firstWhere((m) => m.name == moodName);
      return mood.color;
    } catch (e) {
      // Fallback: try case-insensitive match
      try {
        final mood = _moods
            .firstWhere((m) => m.name.toLowerCase() == moodName.toLowerCase());
        return mood.color;
      } catch (e2) {
        // Last resort: return grey
        return Colors.grey;
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
    final filteredEntries = _getFilteredEntries();

    return Scaffold(
      backgroundColor: const Color(0xFFF9ED69),
      body: Column(
        children: [
          // Header
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
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                  _isSearching ? Icons.close : Icons.search),
                              color: const Color(0xFF1E1E1E),
                              onPressed: () {
                                setState(() {
                                  _isSearching = !_isSearching;
                                  if (!_isSearching) {
                                    _searchQuery = '';
                                    _searchController.clear();
                                  }
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              color: const Color(0xFF1E1E1E),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AddJournalScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (!_isSearching) ...[
                      Text(
                        'My Journal',
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E1E1E),
                                ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Your private thoughts',
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
                              '${_entries.length} entries',
                              style: const TextStyle(
                                color: Color(0xFFF9ED69),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1E1E1E).withOpacity(0.1),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: const TextStyle(
                            color: Color(0xFF1E1E1E),
                            fontSize: 18,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search entries...',
                            hintStyle: TextStyle(
                              color: const Color(0xFF1E1E1E).withOpacity(0.5),
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF1E1E1E),
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Color(0xFF1E1E1E),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isSearching = false;
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Entries list
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1E1E1E),
                      ),
                    )
                  : filteredEntries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchQuery.isNotEmpty
                                    ? Icons.search_off
                                    : Icons.book_outlined,
                                size: 80,
                                color: Colors.grey.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No entries found'
                                    : 'No entries yet',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.grey,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Try different keywords'
                                    : 'Tap + to write your first entry',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey,
                                    ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.all(AppConstants.paddingMedium),
                          itemCount: filteredEntries.length,
                          itemBuilder: (context, index) {
                            return _buildEntryCard(filteredEntries[index]);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(JournalEntry entry) {
    final moodColor = _getMoodColor(entry.mood);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: moodColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: moodColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showDetail(entry),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 50,
                    decoration: BoxDecoration(
                      color: moodColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E1E1E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.date,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    color: Colors.white,
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditJournalScreen(entry: entry),
                          ),
                        );
                      } else if (value == 'delete') {
                        _confirmDelete(entry);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _getPlainTextFromContent(entry.content),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: moodColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.mood.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: moodColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    entry.time,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
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

  void _showDetail(JournalEntry entry) {
    final moodColor = _getMoodColor(entry.mood);

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
                color: moodColor.withOpacity(0.2),
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
                          entry.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
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
                          color: moodColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          entry.mood.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: moodColor.withOpacity(0.9),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        entry.date,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        entry.time,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Image Carousel
            if (entry.imageUrls.isNotEmpty)
              SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: entry.imageUrls.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => _FullScreenImageViewer(
                            imageUrls: entry.imageUrls,
                            initialIndex: index,
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(entry.imageUrls[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${index + 1}/${entry.imageUrls.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: RichTextViewer(content: entry.content),
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
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditJournalScreen(entry: entry),
                          ),
                        );
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
                        _confirmDelete(entry);
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(JournalEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _journalService.deleteEntry(entry.id!);
                Navigator.pop(context);
                if (mounted) {
                  _showSuccessDialog('Entry deleted', 'Your journal entry has been successfully deleted.');
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  _showErrorDialog('Error', e.toString());
                }
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

  void _showEditDialog(JournalEntry entry) {
    final titleController = TextEditingController(text: entry.title);
    final contentController = TextEditingController(text: entry.content);
    String selectedMood = entry.mood;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final moodColor = _getMoodColor(selectedMood);

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.edit, color: moodColor, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Edit Journal Entry',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mood Selection Section
                  Container(
                    padding: const EdgeInsets.all(16),
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
                            Icon(Icons.mood,
                                size: 18, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(
                              'How are you feeling?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Entry Details Section
                  Container(
                    padding: const EdgeInsets.all(16),
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
                            Icon(Icons.edit_note,
                                size: 18, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(
                              'Entry Details',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: titleController,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Entry Title',
                            hintText: 'Give your thoughts a title',
                            labelStyle: TextStyle(color: Colors.grey.shade600),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: moodColor, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            suffixIcon: titleController.text.isNotEmpty
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green, size: 20)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: contentController,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Your Thoughts',
                            hintText: 'Share what\'s on your mind...',
                            labelStyle: TextStyle(color: Colors.grey.shade600),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: moodColor, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          maxLines: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty &&
                      contentController.text.isNotEmpty) {
                    try {
                      final updatedEntry = JournalEntry(
                        id: entry.id,
                        title: titleController.text,
                        content: contentController.text,
                        date: entry.date,
                        time: entry.time,
                        mood: selectedMood,
                      );
                      await _journalService.updateEntry(
                          entry.id!, updatedEntry);
                      Navigator.pop(context);
                      if (mounted) {
                        _showSuccessDialog('Journal entry updated', 'Your journal entry has been successfully updated.');
                      }
                    } catch (e) {
                      if (mounted) {
                        _showErrorDialog('Error', e.toString());
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: moodColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Extract plain text from delta JSON content
  String _getPlainTextFromContent(String content) {
    try {
      // Try to parse as delta JSON
      final decoded = json.decode(content);
      if (decoded is List) {
        // Extract text from delta operations
        final buffer = StringBuffer();
        for (var op in decoded) {
          if (op is Map && op.containsKey('insert')) {
            buffer.write(op['insert']);
          }
        }
        return buffer.toString().trim();
      }
    } catch (e) {
      // If parsing fails, return as-is (backward compatibility)
    }
    return content;
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

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour =
        now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.imageUrls,
    this.initialIndex = 0,
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
                      horizontal: 12, vertical: 6),
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
