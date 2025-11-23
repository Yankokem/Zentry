import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// A read-only widget to display rich text content from journal entries
/// 
/// This widget takes JSON delta format and displays the formatted content
/// without allowing editing.
class RichTextViewer extends StatefulWidget {
  final String content;

  const RichTextViewer({
    super.key,
    required this.content,
  });

  @override
  State<RichTextViewer> createState() => _RichTextViewerState();
}

class _RichTextViewerState extends State<RichTextViewer> {
  late quill.QuillController _controller;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    try {
      // Try to parse as delta JSON
      final decoded = json.decode(widget.content);
      final document = quill.Document.fromJson(decoded);
      _controller = quill.QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (e) {
      // If parsing fails, treat as plain text (for backward compatibility)
      final document = quill.Document()..insert(0, widget.content);
      _controller = quill.QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
  }

  @override
  void didUpdateWidget(RichTextViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _controller.dispose();
      _initializeController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return quill.QuillEditor.basic(
      controller: _controller,
    );
  }
}
