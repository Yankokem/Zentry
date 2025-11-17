import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/journal_entry_model.dart';
import '../../services/journal_manager.dart';

class AddJournalScreen extends StatefulWidget {
  final JournalEntry? entryToEdit;

  const AddJournalScreen({
    super.key,
    this.entryToEdit,
  });

  @override
  State<AddJournalScreen> createState() => _AddJournalScreenState();
}

class _AddJournalScreenState extends State<AddJournalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _journalManager = JournalManager();

  String _selectedMood = 'happy';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.entryToEdit != null) {
      _titleController.text = widget.entryToEdit!.title;
      _contentController.text = widget.entryToEdit!.content;
      _selectedMood = widget.entryToEdit!.mood;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'happy':
        return const Color(0xFFFDD835);
      case 'sad':
        return const Color(0xFF42A5F5);
      case 'angry':
        return const Color(0xFFEF5350);
      case 'excited':
        return const Color(0xFFAB47BC);
      case 'calm':
        return const Color(0xFF66BB6A);
      default:
        return Colors.grey;
    }
  }

  Future<void> _saveJournalEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final entry = JournalEntry(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      date: widget.entryToEdit?.date ?? _getCurrentDate(),
      time: widget.entryToEdit?.time ?? _getCurrentTime(),
      mood: _selectedMood,
    );

    if (widget.entryToEdit != null) {
      _journalManager.updateEntry(widget.entryToEdit!, entry);
    } else {
      _journalManager.addEntryFromMap({
        'title': entry.title,
        'content': entry.content,
        'date': entry.date,
        'time': entry.time,
        'mood': entry.mood,
      });
    }

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.entryToEdit != null
              ? 'Journal entry updated'
              : 'Journal entry added'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildMoodChip(String mood, String label, String selectedMood, Function(String) onTap) {
    final isSelected = selectedMood == mood;
    final moodColor = _getMoodColor(mood);

    return GestureDetector(
      onTap: () => onTap(mood),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? moodColor : moodColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? moodColor : moodColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : moodColor.withOpacity(0.8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
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
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
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
          widget.entryToEdit != null ? 'Edit Journal Entry' : 'New Journal Entry',
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
            // Mood Selection Section
            Text(
              'How are you feeling?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMoodChip('happy', 'Happy', _selectedMood, (mood) {
                  setState(() => _selectedMood = mood);
                }),
                _buildMoodChip('sad', 'Sad', _selectedMood, (mood) {
                  setState(() => _selectedMood = mood);
                }),
                _buildMoodChip('angry', 'Angry', _selectedMood, (mood) {
                  setState(() => _selectedMood = mood);
                }),
                _buildMoodChip('excited', 'Excited', _selectedMood, (mood) {
                  setState(() => _selectedMood = mood);
                }),
                _buildMoodChip('calm', 'Calm', _selectedMood, (mood) {
                  setState(() => _selectedMood = mood);
                }),
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
            TextFormField(
              controller: _contentController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Share what\'s on your mind...',
                filled: true,
                fillColor: AppTheme.surface,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your thoughts';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

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
                    : Text(
                        widget.entryToEdit != null ? 'Save Changes' : 'Add Entry',
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
