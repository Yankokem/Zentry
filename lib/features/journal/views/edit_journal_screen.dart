import 'package:flutter/material.dart';

import 'package:zentry/core/core.dart';
import 'package:zentry/features/journal/journal.dart';

class EditJournalScreen extends StatefulWidget {
  final JournalEntry entry;

  const EditJournalScreen({
    super.key,
    required this.entry,
  });

  @override
  State<EditJournalScreen> createState() => _EditJournalScreenState();
}

class _EditJournalScreenState extends State<EditJournalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentEditorController = RichTextEditorController();
  final _journalService = JournalService();
  final _moodService = MoodService();

  String _selectedMood = 'happy';
  List<Mood> _moods = Mood.defaultMoods;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.entry.title;
    _contentEditorController.setJsonContent(widget.entry.content);
    _selectedMood = widget.entry.mood;
    _loadMoods();
  }

  void _loadMoods() {
    // Set initial value from cache
    _moods = Mood.defaultMoods;
    
    // Listen to real-time updates from Firestore
    _moodService.getMoodsStream().listen((moods) {
      if (mounted) {
        setState(() {
          _moods = moods;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentEditorController.dispose();
    super.dispose();
  }

  void _showAddMoodDialog() {
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
                  const Text('Add Custom Feeling'),
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
                          labelText: 'Feeling Name',
                          hintText: 'e.g., Peaceful',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Feeling Color',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        Colors.blue, Colors.green, Colors.purple, Colors.orange,
                        Colors.red, Colors.pink, Colors.teal, Colors.indigo,
                        Colors.amber, Colors.cyan, Colors.lime, Colors.brown,
                      ].map((color) {
                        final isSelected = color.value == selectedColor.value;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.transparent,
                                width: 3,
                              ),
                            ),
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
                          content: Text('Please enter a feeling name'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final moodName = nameController.text.trim().toLowerCase();
                    final displayLabel = moodName[0].toUpperCase() + moodName.substring(1);
                    final colorHex = selectedColor.value.toRadixString(16).padLeft(8, '0').toUpperCase();

                    try {
                      await _moodService.createMood(Mood(
                        name: moodName,
                        label: displayLabel,
                        colorHex: colorHex,
                      ));

                      if (mounted) {
                        Navigator.pop(context);
                        _loadMoods();
                        setState(() {
                          _selectedMood = moodName;
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
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

  Future<void> _saveJournalEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final entry = JournalEntry(
        title: _titleController.text.trim(),
        content: _contentEditorController.getJsonContent(),
        date: widget.entry.date,
        time: widget.entry.time,
        mood: _selectedMood,
      );

      await _journalService.updateEntry(widget.entry.id!, entry);

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journal entry updated'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
          'Edit Journal Entry',
          style: TextStyle(
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
            // Mood Selection Section
            Text(
              'How are you feeling?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _moods.map((mood) {
                      final isSelected = _selectedMood == mood.name;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMood = mood.name;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? mood.color : AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? mood.color : Colors.grey.shade400,
                              width: isSelected ? 2 : 1.5,
                            ),
                          ),
                          child: Text(
                            mood.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : AppTheme.textDark,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showAddMoodDialog,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade400, width: 1.5),
                    ),
                    child: const Icon(Icons.add, size: 20, color: AppTheme.textDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Entry Title
            Text(
              'Entry Title',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Give your thoughts a title',
                filled: true,
                fillColor: AppTheme.surface,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Entry Content
            Text(
              'Your Thoughts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            RichTextEditor(
              controller: _contentEditorController,
              hintText: 'Share what\'s on your mind...',
            ),
            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveJournalEntry,
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
                    : const Text(
                        'Save Changes',
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
    );
  }
}
