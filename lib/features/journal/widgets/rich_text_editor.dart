import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:zentry/core/core.dart';

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
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      textSelectionTheme: TextSelectionThemeData(
                        cursorColor: Colors.black,
                      ),
                    ),
                    child: quill.QuillEditor.basic(
                      controller: widget.controller._quillController,
                    ),
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
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ToolbarButton(
                          icon: Icons.format_bold,
                          onPressed: () => _formatText(quill.Attribute.bold),
                          tooltip: 'Bold',
                          controller: widget.controller._quillController,
                          attribute: quill.Attribute.bold,
                        ),
                        _ToolbarButton(
                          icon: Icons.format_italic,
                          onPressed: () => _formatText(quill.Attribute.italic),
                          tooltip: 'Italic',
                          controller: widget.controller._quillController,
                          attribute: quill.Attribute.italic,
                        ),
                        _ToolbarButton(
                          icon: Icons.format_underline,
                          onPressed: () => _formatText(quill.Attribute.underline),
                          tooltip: 'Underline',
                          controller: widget.controller._quillController,
                          attribute: quill.Attribute.underline,
                        ),
                        _ToolbarButton(
                          icon: Icons.format_strikethrough,
                          onPressed: () => _formatText(quill.Attribute.strikeThrough),
                          tooltip: 'Strikethrough',
                          controller: widget.controller._quillController,
                          attribute: quill.Attribute.strikeThrough,
                        ),
                        const SizedBox(width: 8),
                        _ToolbarButton(
                          icon: Icons.format_list_bulleted,
                          onPressed: () => _formatText(quill.Attribute.ul),
                          tooltip: 'Bullet List',
                          controller: widget.controller._quillController,
                          attribute: quill.Attribute.ul,
                        ),
                        _ToolbarButton(
                          icon: Icons.check_box_outlined,
                          onPressed: () => _formatText(quill.Attribute.unchecked),
                          tooltip: 'Checkbox',
                          controller: widget.controller._quillController,
                          attribute: quill.Attribute.unchecked,
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
    try {
      final controller = widget.controller._quillController;
      final selection = controller.selection;
      
      if (!selection.isValid || selection.start < 0) return false;
      
      // For list formats, we need to check the block style at the current line
      if (attribute.key == quill.Attribute.ul.key || 
          attribute.key == quill.Attribute.unchecked.key) {
        
        // Get the block (line) at the current cursor position
        final block = controller.document.queryChild(selection.start).node;
        
        if (block != null && block.style.attributes.isNotEmpty) {
          final listAttr = block.style.attributes['list'];
          
          if (attribute.key == quill.Attribute.ul.key) {
            // Only active if it's specifically a bullet list
            return listAttr?.value == 'bullet';
          } else if (attribute.key == quill.Attribute.unchecked.key) {
            // Only active if it's specifically a checklist (not bullet)
            return listAttr?.value == 'unchecked' || listAttr?.value == 'checked';
          }
        }
        return false;
      }
      
      // For inline attributes (bold, italic, etc.)
      final style = controller.getSelectionStyle();
      return style.attributes.containsKey(attribute.key);
    } catch (e) {
      return false;
    }
  }

  void _formatText(quill.Attribute attribute) {
    final controller = widget.controller._quillController;
    final selection = controller.selection;
    
    if (!selection.isValid || selection.start < 0) return;
    
    // Handle inline attributes (bold, italic, etc.)
    if (attribute.key == quill.Attribute.bold.key ||
        attribute.key == quill.Attribute.italic.key ||
        attribute.key == quill.Attribute.underline.key ||
        attribute.key == quill.Attribute.strikeThrough.key) {
      final isActive = _isFormatActive(attribute);
      if (isActive) {
        final unsetAttribute = quill.Attribute.fromKeyValue(attribute.key, null);
        controller.formatSelection(unsetAttribute);
      } else {
        controller.formatSelection(attribute);
      }
      return;
    }
    
    // Handle list attributes (bullet and checklist)
    if (attribute.key == quill.Attribute.ul.key || 
        attribute.key == quill.Attribute.unchecked.key) {
      
      final block = controller.document.queryChild(selection.start).node;
      if (block != null && block.style.attributes.isNotEmpty) {
        final listAttr = block.style.attributes['list'];
        
        // Determine what list type is currently applied
        final isBulletActive = listAttr?.value == 'bullet';
        final isChecklistActive = listAttr?.value == 'unchecked' || listAttr?.value == 'checked';
        
        if (attribute.key == quill.Attribute.ul.key) {
          // Bullet list button clicked
          if (isBulletActive) {
            // Bullet is active, turn it off
            controller.formatSelection(
              quill.Attribute.fromKeyValue('list', null)
            );
          } else {
            // Bullet is not active, turn it on (and clear checklist if present)
            if (isChecklistActive) {
              // Clear checklist first
              controller.formatSelection(
                quill.Attribute.fromKeyValue('list', null)
              );
            }
            // Apply bullet list
            controller.formatSelection(quill.Attribute.ul);
          }
        } else if (attribute.key == quill.Attribute.unchecked.key) {
          // Checklist button clicked
          if (isChecklistActive) {
            // Checklist is active, turn it off
            controller.formatSelection(
              quill.Attribute.fromKeyValue('list', null)
            );
          } else {
            // Checklist is not active, turn it on (and clear bullet if present)
            if (isBulletActive) {
              // Clear bullet first
              controller.formatSelection(
                quill.Attribute.fromKeyValue('list', null)
              );
            }
            // Apply checklist
            controller.formatSelection(quill.Attribute.unchecked);
          }
        }
      } else {
        // No list currently applied, just apply the requested list type
        controller.formatSelection(attribute);
      }
      return;
    }
    
    // For any other attributes, toggle normally
    final isActive = _isFormatActive(attribute);
    if (isActive) {
      controller.formatSelection(attribute);
    } else {
      controller.formatSelection(attribute);
    }
  }
}

/// A stateful toolbar button that updates its active state independently
class _ToolbarButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final quill.QuillController controller;
  final quill.Attribute attribute;

  const _ToolbarButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    required this.controller,
    required this.attribute,
  });

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateState);
    _updateState();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (!mounted) return;
    
    try {
      bool isActive = false;
      final selection = widget.controller.selection;
      
      if (selection.isValid && selection.start >= 0) {
        // For list formats (block attributes), check the block style
        if (widget.attribute.key == quill.Attribute.ul.key || 
            widget.attribute.key == quill.Attribute.unchecked.key) {
          
          final block = widget.controller.document.queryChild(selection.start).node;
          
          if (block != null && block.style.attributes.isNotEmpty) {
            final listAttr = block.style.attributes['list'];
            
            if (widget.attribute.key == quill.Attribute.ul.key) {
              // Only active if it's specifically a bullet list
              isActive = listAttr?.value == 'bullet';
            } else if (widget.attribute.key == quill.Attribute.unchecked.key) {
              // Only active if it's specifically a checklist (not bullet)
              isActive = listAttr?.value == 'unchecked' || listAttr?.value == 'checked';
            }
          }
        } else {
          // For inline attributes
          final style = widget.controller.getSelectionStyle();
          isActive = style.attributes.containsKey(widget.attribute.key);
        }
      }
      
      if (_isActive != isActive) {
        setState(() {
          _isActive = isActive;
        });
      }
    } catch (e) {
      // Ignore errors during state updates
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: InkWell(
        onTap: widget.onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isActive ? Colors.blue.shade100 : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            widget.icon,
            size: 20,
            color: _isActive ? Colors.blue.shade700 : Colors.grey.shade700,
          ),
        ),
      ),
    );
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
