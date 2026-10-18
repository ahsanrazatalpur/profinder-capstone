// lib/features/support/widgets/support_search_field.dart
//
// Search input for the Help Center. Colors, fill and borders come from the
// app's InputDecorationTheme (light + dark). The text direction follows the
// first strong character the user types, so Urdu / Arabic typed inside an
// English UI (or the reverse) is aligned correctly.

import 'package:flutter/material.dart';

import '../../../core/theme/theme_context_ext.dart';
import '../../../l10n/generated/app_localizations.dart';

final RegExp _rtlChar = RegExp(r'[֐-ࣿיִ-﷿ﹰ-﻿]');
final RegExp _ltrChar = RegExp(r'[A-Za-zÀ-ɏऀ-ॿ]');

/// Direction implied by the first strong (letter) character, or null when the
/// text has none yet (then the ambient direction applies).
TextDirection? detectTextDirection(String text) {
  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    if (_rtlChar.hasMatch(ch)) return TextDirection.rtl;
    if (_ltrChar.hasMatch(ch)) return TextDirection.ltr;
  }
  return null;
}

class SupportSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? clearTooltip;
  final bool autofocus;

  const SupportSearchField({
    super.key,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.clearTooltip,
    this.autofocus = false,
  });

  @override
  State<SupportSearchField> createState() => _SupportSearchFieldState();
}

class _SupportSearchFieldState extends State<SupportSearchField> {
  late final TextEditingController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = AppLocalizations.of(context);
    final hasText = _controller.text.isNotEmpty;

    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      textDirection: detectTextDirection(_controller.text),
      textInputAction: TextInputAction.search,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: context.textStyles.inputText.copyWith(letterSpacing: 0),
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: Icon(Icons.search_rounded, color: colors.textSecondary),
        suffixIcon: hasText
            ? IconButton(
                icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                tooltip: widget.clearTooltip ?? t.searchClear,
                onPressed: _clear,
              )
            : null,
      ),
    );
  }
}
