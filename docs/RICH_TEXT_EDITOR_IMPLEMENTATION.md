# Rich Text Editor Implementation Tutorial

## Overview

This document explains how the rich text editor was integrated into the Zentry journal feature using the `flutter_quill` package.

## What Was Done

### 1. Added the flutter_quill Package

Added `flutter_quill: ^11.5.0` to `pubspec.yaml`:

```yaml
dependencies:
  flutter_quill: ^11.5.0
```

Then ran:
```bash
flutter pub get
```

### 2. Set Up Localization in main.dart

flutter_quill requires localization delegates to work properly. Updated `lib/main.dart`:

```dart
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_localizations/flutter_localizations.dart';

MaterialApp(
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    quill.FlutterQuillLocalizations.delegate,  // Required
  ],
  supportedLocales: const [
    Locale('en', ''),
  ],
  // ... rest of MaterialApp
)
```

### 3. Created RichTextEditor Widget

Created `lib/widgets/journal/rich_text_editor.dart` with two main components:

#### RichTextEditor StatefulWidget

The main widget that displays the editor with a toolbar at the bottom:

```dart
class RichTextEditor extends StatefulWidget {
  final RichTextEditorController controller;
  final String hintText;
  final String? initialContent;
  final bool readOnly;
  
  const RichTextEditor({
    required this.controller,
    this.hintText = 'Start writing...',
    this.initialContent,
    this.readOnly = false,
  });
}
```

**Layout Structure:**
- Text editor in the middle (takes up most space)
- Toolbar at the bottom with 8 formatting buttons:
  - Bold
  - Italic
  - Underline
  - Strikethrough
  - Bullet List
  - Checkbox
  - Undo
  - Redo

#### RichTextEditorController

A controller class that wraps flutter_quill's `QuillController` and provides simple methods:

```dart
class RichTextEditorController {
  late final quill.QuillController _quillController;

  RichTextEditorController() {
    _quillController = quill.QuillController.basic();
  }

  // Get plain text (for saving)
  String getPlainText() {
    return _quillController.document.toPlainText().trim();
  }

  // Set content from plain text
  void setPlainText(String text) {
    final document = quill.Document()..insert(0, text);
    _quillController.document = document;
  }

  // Check if empty
  bool isEmpty() {
    return getPlainText().isEmpty;
  }

  // Dispose on cleanup
  void dispose() {
    _quillController.dispose();
  }
}
```

### 4. Integrated into add_journal_screen.dart

Updated the journal entry form to use RichTextEditor instead of a basic TextField:

```dart
class _AddJournalScreenState extends State<AddJournalScreen> {
  final _contentEditorController = RichTextEditorController();
  
  @override
  void initState() {
    super.initState();
    // Load existing content when editing
    if (widget.entryToEdit != null) {
      _contentEditorController.setPlainText(widget.entryToEdit!.content);
    }
  }
  
  @override
  void dispose() {
    _contentEditorController.dispose();
    super.dispose();
  }
  
  // In the form
  RichTextEditor(
    controller: _contentEditorController,
    hintText: 'Share what\'s on your mind...',
  )
  
  // When saving
  void _saveJournalEntry() {
    final content = _contentEditorController.getPlainText();
    // Save to database...
  }
}
```

## Available Formatting

Users can apply the following formatting to their journal entries:

| Format | Button | How to Use |
|--------|--------|-----------|
| **Bold** | **B** | Select text and click, or use Ctrl+B |
| **Italic** | *I* | Select text and click, or use Ctrl+I |
| **Underline** | U | Select text and click, or use Ctrl+U |
| **Strikethrough** | ~~S~~ | Select text and click |
| **Bullet List** | • | Click at beginning of line or in middle of text |
| **Checkbox** | ☐ | Click to insert checkbox, click again to check |
| **Undo** | ↶ | Undo last action (Ctrl+Z) |
| **Redo** | ↷ | Redo last undone action (Ctrl+Y) |

## How It Works

1. **User types content** - The QuillEditor captures input
2. **User applies formatting** - Clicking toolbar buttons applies formatting to selected text
3. **Content is saved** - `getPlainText()` extracts just the text (without formatting)
4. **Encrypted and stored** - The plain text is encrypted before saving to Firestore
5. **Content is loaded** - When editing, `setPlainText()` loads content back into editor

## Technical Details

### Plain Text Storage

Even though users can apply rich formatting in the editor, only **plain text** is stored in Firestore. This is because:
- The content is encrypted with AES-256 (requires consistent string format)
- Users see rich formatting while editing, but it's lost when saved
- This is a design choice for simplicity and encryption compatibility

### Why flutter_quill?

- ✅ Industry standard (most popular Flutter rich text package)
- ✅ Mature and well-maintained
- ✅ Mobile-optimized UI
- ✅ Supports all needed formatting (bold, italic, underline, bullets, etc.)
- ✅ Easy to customize

## Troubleshooting

### Error: "FlutterQuillLocalizations.delegate is required"

**Solution:** Make sure you added the localization delegates to MaterialApp in `main.dart` (see Step 2 above).

### Formatting not working

**Solution:** Make sure to select text before applying formatting. Formatting only applies to selected text.

### Editor crashes on load

**Solution:** Ensure the controller is properly disposed in the `dispose()` method of the State.

### Content not saving

**Solution:** Use `controller.getPlainText()` to get the content, not direct controller access.

## Files Modified

- `pubspec.yaml` - Added flutter_quill dependency
- `lib/main.dart` - Added localization configuration
- `lib/widgets/journal/rich_text_editor.dart` - Created new widget and controller
- `lib/views/home/add_journal_screen.dart` - Replaced TextField with RichTextEditor

## Next Steps

To extend the editor in the future:
- Add more formatting options (colors, headers, etc.)
- Store rich text formatting in Firestore (requires encryption changes)
- Add text alignment options
- Add more toolbar customization
