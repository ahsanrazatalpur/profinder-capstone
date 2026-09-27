// lib/shared/widgets/simple_rich_text_editor.dart
//
// A plain multiline TextField plus a formatting toolbar that wraps the
// current selection in HTML tags — h1-h3, b, i, a, ul/li. Produces exactly
// the HTML subset RichHtmlText (the public/preview renderer) understands.
// No external rich-text-editor package, matching this project's preference
// for hand-rolled widgets over new dependencies.
//
// Paragraphs: admins just leave a blank line between paragraphs; on save,
// wrapPlainParagraphs() below turns blank-line-separated plain chunks into
// <p>...</p> automatically, so nobody has to type tags for ordinary text.

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_context_ext.dart';
import '../../l10n/generated/app_localizations.dart';

class SimpleRichTextEditor extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final int minLines;
  final int maxLines;

  const SimpleRichTextEditor({
    super.key,
    required this.controller,
    this.label = 'Description',
    this.minLines = 5,
    this.maxLines = 14,
  });

  @override
  State<SimpleRichTextEditor> createState() => _SimpleRichTextEditorState();
}

class _SimpleRichTextEditorState extends State<SimpleRichTextEditor> {
  final _focusNode = FocusNode();

  void _wrap(String openTag, String closeTag, {String placeholder = 'text'}) {
    final controller = widget.controller;
    final selection = controller.selection;
    final text = controller.text;

    if (!selection.isValid || selection.isCollapsed) {
      // No selection — insert a tagged placeholder at the cursor.
      final insertAt = selection.isValid ? selection.start : text.length;
      final newText = text.replaceRange(insertAt, insertAt, '$openTag$placeholder$closeTag');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: insertAt + openTag.length,
          extentOffset: insertAt + openTag.length + placeholder.length,
        ),
      );
      return;
    }

    final selected = text.substring(selection.start, selection.end);
    final newText = text.replaceRange(selection.start, selection.end, '$openTag$selected$closeTag');
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + openTag.length + selected.length + closeTag.length),
    );
  }

  void _bulletList() {
    final controller = widget.controller;
    final selection = controller.selection;
    final text = controller.text;

    if (!selection.isValid || selection.isCollapsed) {
      _wrap('<ul>\n  <li>', '</li>\n</ul>', placeholder: 'List item');
      return;
    }
    final selected = text.substring(selection.start, selection.end);
    final lines = selected.split('\n').where((l) => l.trim().isNotEmpty);
    final li = lines.map((l) => '  <li>${l.trim()}</li>').join('\n');
    final replacement = '<ul>\n$li\n</ul>';
    final newText = text.replaceRange(selection.start, selection.end, replacement);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + replacement.length),
    );
  }

  Future<void> _link() async {
    final urlController = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.editorInsertLinkTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        content: TextField(
          controller: urlController,
          autofocus: true,
          style: TextStyle(
            fontSize: 14,
            color: context.colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.editorLinkHint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: context.colors.textSecondary,
            ),
            filled: true,
            fillColor: context.colors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.colors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.colors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.customerColor,
                width: 1.5,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: context.colors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.cancelCta,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, urlController.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.customerColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              AppLocalizations.of(context)!.editorInsertCta,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
    if (url == null || url.isEmpty) return;
    _wrap('<a href="$url">', '</a>', placeholder: AppLocalizations.of(context)!.editorLinkPlaceholder);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: context.colors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.12)
                  : context.colors.divider,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.15)
                    : Colors.grey.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Toolbar ────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : context.colors.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : context.colors.divider,
                    ),
                  ),
                ),
                child: Wrap(
                  spacing: 2,
                  runSpacing: 2,
                  children: [
                    _toolBtn('H1', () => _wrap('<h1>', '</h1>', placeholder: AppLocalizations.of(context)!.editorHeadingPlaceholder)),
                    _toolBtn('H2', () => _wrap('<h2>', '</h2>', placeholder: AppLocalizations.of(context)!.editorHeadingPlaceholder)),
                    _toolBtn('H3', () => _wrap('<h3>', '</h3>', placeholder: AppLocalizations.of(context)!.editorHeadingPlaceholder)),
                    _divider(isDark),
                    _iconBtn(Icons.format_bold_rounded, () => _wrap('<b>', '</b>'), isDark),
                    _iconBtn(Icons.format_italic_rounded, () => _wrap('<i>', '</i>'), isDark),
                    _divider(isDark),
                    _iconBtn(Icons.format_list_bulleted_rounded, _bulletList, isDark),
                    _iconBtn(Icons.link_rounded, _link, isDark),
                  ],
                ),
              ),
              // ── Text Field ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(10),
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  minLines: widget.minLines,
                  maxLines: widget.maxLines,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: context.colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: AppLocalizations.of(context)!.editorHintText,
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: context.colors.textSecondary,
                      letterSpacing: 0.2,
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toolBtn(String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      splashColor: AppColors.customerColor.withOpacity(0.1),
      highlightColor: AppColors.customerColor.withOpacity(0.05),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark
                ? Colors.white.withOpacity(0.8)
                : context.colors.textPrimary,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      splashColor: AppColors.customerColor.withOpacity(0.1),
      highlightColor: AppColors.customerColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 18,
          color: isDark
              ? Colors.white.withOpacity(0.7)
              : context.colors.textSecondary,
        ),
      ),
    );
  }

  Widget _divider(bool isDark) => Container(
        width: 1,
        height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.grey.withOpacity(0.3),
      );
}

/// Turns blank-line-separated plain paragraphs into `<p>...</p>` blocks
/// before saving, so admins never have to hand-type paragraph tags for
/// ordinary text. Chunks that already look like HTML (start with `<`) are
/// left untouched.
String wrapPlainParagraphs(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final chunks = trimmed.split(RegExp(r'\n\s*\n'));
  return chunks.map((chunk) {
    final c = chunk.trim();
    if (c.isEmpty) return '';
    if (c.startsWith('<')) return c;
    return '<p>${c.replaceAll('\n', '<br>')}</p>';
  }).where((c) => c.isNotEmpty).join('\n');
}