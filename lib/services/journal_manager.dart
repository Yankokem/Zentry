import '../models/journal_entry_model.dart';

// Global journal manager
class JournalManager {
  static final JournalManager _instance = JournalManager._internal();
  factory JournalManager() => _instance;
  JournalManager._internal();

  final List<JournalEntry> _entries = [
    JournalEntry(
      title: 'First day at the gym',
      content: 'Finally decided to get a gym membership. Did some basic cardio and light weights. My arms are already sore but it feels good to start this journey.',
      date: 'Nov 4, 2025',
      time: '8:30 PM',
      mood: 'excited',
    ),
    JournalEntry(
      title: 'Weekend plans',
      content: 'Planning to visit the new coffee shop downtown. Also need to finish that book I started last month. Maybe catch up with Sarah if she\'s free.',
      date: 'Nov 3, 2025',
      time: '7:15 PM',
      mood: 'happy',
    ),
    JournalEntry(
      title: 'Work thoughts',
      content: 'The new project is challenging but interesting. Learning a lot about system architecture. Team is supportive which makes everything easier.',
      date: 'Nov 2, 2025',
      time: '10:00 PM',
      mood: 'calm',
    ),
    JournalEntry(
      title: 'Got the promotion',
      content: 'Manager called me in today and offered the senior position. All those late nights paid off. Starting next month with a new team.',
      date: 'Nov 1, 2025',
      time: '3:45 PM',
      mood: 'excited',
    ),
    JournalEntry(
      title: 'Random thoughts',
      content: 'Sometimes I wonder if I should have taken that other job offer. But I think I made the right choice staying here. The people are great and I\'m learning a lot.',
      date: 'Oct 31, 2025',
      time: '9:20 PM',
      mood: 'sad',
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
