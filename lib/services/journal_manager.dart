import '../models/journal_entry_model.dart';

// Global journal manager
class JournalManager {
  static final JournalManager _instance = JournalManager._internal();
  factory JournalManager() => _instance;
  JournalManager._internal();

  final List<JournalEntry> _entries = [
    JournalEntry(
      title: 'My First Journal Entry',
      content: 'Welcome to your journal! This is where you can write down your thoughts, feelings, and experiences. Tap the + button to create your own entries.',
      date: 'Nov 23, 2025',
      time: '12:00 PM',
      mood: 'calm',
    ),
  ];

  List<JournalEntry> get entries => _entries;

  void addEntry(JournalEntry entry) {
    _entries.insert(0, entry);
  }

  void removeEntry(JournalEntry entry) {
    _entries.remove(entry);
  }

  void updateEntry(JournalEntry entry, JournalEntry updates) {
    final index = _entries.indexOf(entry);
    if (index != -1) {
      _entries[index] = updates;
    }
  }

  // For backward compatibility with existing code that uses Maps
  List<Map<String, dynamic>> get entriesAsMaps => _entries.map((entry) => entry.toMap()).toList();

  void addEntryFromMap(Map<String, dynamic> entryMap) {
    _entries.insert(0, JournalEntry.fromMap(entryMap));
  }

  void removeEntryFromMap(Map<String, dynamic> entryMap) {
    final entry = JournalEntry.fromMap(entryMap);
    _entries.remove(entry);
  }
}
