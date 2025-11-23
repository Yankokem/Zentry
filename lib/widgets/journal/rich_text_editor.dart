import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../config/theme.dart';

/// A rich text editor widget specifically designed for journal entries.
/// 
/// This widget wraps flutter_quill to provide:
/// - Rich text formatting (bold, italic, underline, strikethrough)
/// - Bullet lists and checkboxes
/// - Easy content extraction for storage
/// 
/// Usage:
/// ```dart
/// final controller = RichTextEditorController();
/// 
/// // In your widget:
/// RichTextEditor(
///   controller: controller,
///   initialContent: 'Some text',
///   hintText: 'Start writing...',
/// )
/// 
/// // To get content:
/// final plainText = controller.getPlainText();
/// final jsonContent = controller.getJsonContent();
/// ```
class RichTextEditor extends StatefulWidget {
  final RichTextEditorController controller;
  final String hintText;
  final String? initialContent;
  final bool readOnly;

  const RichTextEditor({
    super.key,
    required this.controller,
    this.hintText = 'Start writing...',
    this.initialContent,
    this.readOnly = false,
  });

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  @override
  void initState() {
    super.initState();
    if (widget.initialContent != null && widget.initialContent!.isNotEmpty) {
      widget.controller.setPlainText(widget.initialContent!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 200, maxHeight: 400),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: quill.QuillEditor.basic(
                    controller: widget.controller._quillController,
                  ),
                ),
              ),
              if (!widget.readOnly) ...[
                const Divider(height: 1),
                // Custom Toolbar at Bottom
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildToolbarButton(
                        icon: Icons.format_bold,
                        onPressed: () => _formatText(quill.Attribute.bold),
                        tooltip: 'Bold',
                        isActive: _isFormatActive(quill.Attribute.bold),
                      ),
                      _buildToolbarButton(
                        icon: Icons.format_italic,
                        onPressed: () => _formatText(quill.Attribute.italic),
                        tooltip: 'Italic',
                        isActive: _isFormatActive(quill.Attribute.italic),
                      ),
                      _buildToolbarButton(
                        icon: Icons.format_underline,
                        onPressed: () => _formatText(quill.Attribute.underline),
                        tooltip: 'Underline',
                        isActive: _isFormatActive(quill.Attribute.underline),
                      ),
                      _buildToolbarButton(
                        icon: Icons.format_strikethrough,
                        onPressed: () => _formatText(quill.Attribute.strikeThrough),
                        tooltip: 'Strikethrough',
                        isActive: _isFormatActive(quill.Attribute.strikeThrough),
                      ),
                      const SizedBox(width: 8),
                      _buildToolbarButton(
                        icon: Icons.format_list_bulleted,
                        onPressed: () => _formatText(quill.Attribute.ul),
                        tooltip: 'Bullet List',
                        isActive: _isFormatActive(quill.Attribute.ul),
                      ),
                      _buildToolbarButton(
                        icon: Icons.check_box_outlined,
                        onPressed: () => _formatText(quill.Attribute.unchecked),
                        tooltip: 'Checkbox',
                        isActive: _isFormatActive(quill.Attribute.unchecked),
                      ),
                      const SizedBox(width: 8),
                      _buildToolbarButton(
                        icon: Icons.undo,
                        onPressed: () => widget.controller._quillController.undo(),
                        tooltip: 'Undo',
                      ),
                      _buildToolbarButton(
                        icon: Icons.redo,
                        onPressed: () => widget.controller._quillController.redo(),
                        tooltip: 'Redo',
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isEnabled = true,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue.shade100 : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive
                ? Colors.blue.shade700
                : (isEnabled ? Colors.grey.shade700 : Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  bool _isFormatActive(quill.Attribute attribute) {
    final controller = widget.controller._quillController;
    return controller.getSelectionStyle().attributes.containsKey(attribute.key);
  }

  void _formatText(quill.Attribute attribute) {
    final controller = widget.controller._quillController;
    final selection = controller.selection;
    
    if (selection.isCollapsed) {
      // If no selection, toggle the attribute for future typing
      controller.formatSelection(attribute);
    } else {
      // Apply to selected text
      controller.formatSelection(attribute);
    }
  }
}

/// Controller for the RichTextEditor
/// 
/// Provides methods to:
/// - Get plain text content
/// - Get JSON content (for storage)
/// - Set content programmatically
/// - Check if content is empty
class RichTextEditorController {
  late final quill.QuillController _quillController;

  RichTextEditorController() {
    _quillController = quill.QuillController.basic();
  }

  /// Get the plain text content (without formatting)
  String getPlainText() {
    return _quillController.document.toPlainText().trim();
  }

  /// Get the content as JSON (preserves formatting)
  String getJsonContent() {
    return json.encode(_quillController.document.toDelta().toJson());
  }

  /// Set plain text content (removes any existing formatting)
  void setPlainText(String text) {
    final document = quill.Document()..insert(0, text);
    _quillController.document = document;
  }

  /// Set content from JSON (preserves formatting)
  void setJsonContent(String jsonString) {
    try {
      // Try to parse as delta JSON first
      final decoded = json.decode(jsonString);
      // Create document from delta JSON
      final document = quill.Document.fromJson(decoded);
      _quillController.document = document;
    } catch (e) {
      // If parsing fails, treat as plain text (for backward compatibility)
      setPlainText(jsonString);
    }
  }

  /// Check if the editor is empty
  bool isEmpty() {
    return getPlainText().isEmpty;
  }

  /// Clear all content
  void clear() {
    _quillController.clear();
  }

  /// Dispose the controller
  void dispose() {
    _quillController.dispose();
  }
}
