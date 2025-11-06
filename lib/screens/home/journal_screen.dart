import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zentry/config/constants.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  String _selectedFilter = 'All';
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFF9ED69),
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredEntries() {
    var entries = _journalEntries;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      entries = entries.where((entry) {
        return entry['title']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               entry['content']!.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply mood filter
    if (_selectedFilter != 'All') {
      entries = entries.where((entry) => entry['mood'] == _selectedFilter).toList();
    }

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final filteredEntries = _getFilteredEntries();

    return Scaffold(
      backgroundColor: const Color(0xFFF9ED69),
      body: Column(
        children: [
          // Yellow Header - Matching Tasks page exactly
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
                              icon: Icon(_isSearching ? Icons.close : Icons.search),
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
                                _showAddJournalDialog();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (!_isSearching) ...[
                      Text(
                        'My Journal',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E1E1E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Capture your thoughts and feelings',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF1E1E1E).withOpacity(0.7),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_journalEntries.length} entries',
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
                      TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(
                          color: Color(0xFF1E1E1E),
                          fontSize: 20,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search entries...',
                          hintStyle: TextStyle(
                            color: const Color(0xFF1E1E1E).withOpacity(0.5),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Mood Filter Pills - Matching Tasks tabs styling
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildFilterChip('All', '🌟'),
                    const SizedBox(width: 4),
                    _buildFilterChip('Happy', '😊'),
                    const SizedBox(width: 4),
                    _buildFilterChip('Calm', '😌'),
                    const SizedBox(width: 4),
                    _buildFilterChip('Sad', '😢'),
                    const SizedBox(width: 4),
                    _buildFilterChip('Excited', '🤩'),
                    const SizedBox(width: 4),
                    _buildFilterChip('Thoughtful', '🤔'),
                  ],
                ),
              ),
            ),
          ),

          // Journal Entries
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: filteredEntries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty ? Icons.search_off : Icons.book_outlined,
                            size: 80,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty ? 'No entries found' : 'No journal entries yet',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty 
                                ? 'Try a different search term'
                                : 'Tap + to create your first entry',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      itemCount: filteredEntries.length,
                      itemBuilder: (context, index) {
                        return _buildJournalCard(filteredEntries[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String emoji) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF9ED69) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFFF9ED69).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF1E1E1E) : Colors.grey.shade500,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJournalCard(Map<String, dynamic> entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showJournalDetail(entry),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _getMoodEmoji(entry['mood']!),
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry['title']!,
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
                          entry['date']!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    color: Colors.grey.shade600,
                    onPressed: () {
                      _showEntryOptions(entry);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                entry['content']!,
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9ED69).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getMoodEmoji(entry['mood']!),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          entry['mood']!.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                      ],
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
                    entry['time']!,
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

  String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'Happy':
        return '😊';
      case 'Calm':
        return '😌';
      case 'Sad':
        return '😢';
      case 'Excited':
        return '🤩';
      case 'Thoughtful':
        return '🤔';
      default:
        return '😊';
    }
  }

  void _showJournalDetail(Map<String, dynamic> entry) {
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
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF9ED69).withOpacity(0.3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getMoodEmoji(entry['mood']!),
                        style: const TextStyle(fontSize: 40),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      entry['title']!,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        entry['date']!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        entry['time']!,
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
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Text(
                  entry['content']!,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ),
            // Actions
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
                        _showEditJournalDialog(entry);
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

  void _showEntryOptions(Map<String, dynamic> entry) {
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
              leading: const Icon(Icons.edit, color: Color(0xFF1E1E1E)),
              title: const Text('Edit Entry'),
              onTap: () {
                Navigator.pop(context);
                _showEditJournalDialog(entry);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Entry'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(entry);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this journal entry? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _journalEntries.remove(entry);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Journal entry deleted')),
              );
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

  void _showAddJournalDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedMood = 'Happy';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Journal Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedMood,
                  decoration: const InputDecoration(
                    labelText: 'How are you feeling?',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.mood),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Happy', child: Text('😊 Happy')),
                    DropdownMenuItem(value: 'Calm', child: Text('😌 Calm')),
                    DropdownMenuItem(value: 'Sad', child: Text('😢 Sad')),
                    DropdownMenuItem(value: 'Excited', child: Text('🤩 Excited')),
                    DropdownMenuItem(value: 'Thoughtful', child: Text('🤔 Thoughtful')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedMood = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Write your thoughts...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 6,
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
              onPressed: () {
                if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                  setState(() {
                    _journalEntries.insert(0, {
                      'title': titleController.text,
                      'content': contentController.text,
                      'mood': selectedMood,
                      'date': _getCurrentDate(),
                      'time': _getCurrentTime(),
                    });
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Journal entry added')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditJournalDialog(Map<String, dynamic> entry) {
    final titleController = TextEditingController(text: entry['title']);
    final contentController = TextEditingController(text: entry['content']);
    String selectedMood = entry['mood']!;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Journal Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedMood,
                  decoration: const InputDecoration(
                    labelText: 'How are you feeling?',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.mood),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Happy', child: Text('😊 Happy')),
                    DropdownMenuItem(value: 'Calm', child: Text('😌 Calm')),
                    DropdownMenuItem(value: 'Sad', child: Text('😢 Sad')),
                    DropdownMenuItem(value: 'Excited', child: Text('🤩 Excited')),
                    DropdownMenuItem(value: 'Thoughtful', child: Text('🤔 Thoughtful')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedMood = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Write your thoughts...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 6,
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
              onPressed: () {
                if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                  setState(() {
                    entry['title'] = titleController.text;
                    entry['content'] = contentController.text;
                    entry['mood'] = selectedMood;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Journal entry updated')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  // Sample data
  final List<Map<String, dynamic>> _journalEntries = [
    {
      'title': 'A Wonderful Day',
      'content': 'Today was absolutely amazing! I woke up early and went for a morning jog. The weather was perfect, and I felt so energized. Later, I had lunch with friends and we had such great conversations. Feeling grateful for these moments.',
      'mood': 'Happy',
      'date': 'Nov 4, 2025',
      'time': '8:30 PM',
    },
    {
      'title': 'Peaceful Evening',
      'content': 'Spent the evening reading my favorite book by the window. The sunset was beautiful, and everything felt so calm and peaceful. These quiet moments are what I cherish the most.',
      'mood': 'Calm',
      'date': 'Nov 3, 2025',
      'time': '7:15 PM',
    },
    {
      'title': 'Reflective Thoughts',
      'content': 'Been thinking a lot about my goals and where I want to be in the next few years. It\'s important to take time to reflect on what really matters. Life moves fast, and sometimes we need to slow down and think.',
      'mood': 'Thoughtful',
      'date': 'Nov 2, 2025',
      'time': '10:00 PM',
    },
    {
      'title': 'Exciting News!',
      'content': 'Got the job offer I\'ve been waiting for! I can\'t believe it finally happened. All the hard work and preparation paid off. This is going to be an amazing new chapter in my life!',
      'mood': 'Excited',
      'date': 'Nov 1, 2025',
      'time': '3:45 PM',
    },
    {
      'title': 'Missing Home',
      'content': 'Feeling a bit homesick today. Sometimes I miss the simple days when everything felt easier. Called my family and it helped a lot. Grateful to have people who care about me.',
      'mood': 'Sad',
      'date': 'Oct 31, 2025',
      'time': '9:20 PM',
    },
  ];
}