// lib/shared/widgets/rich_html_text.dart
//
// Renders the simple HTML subset produced by the admin's rich-text editor
// (h1–h3, p, ul/li, a, b/strong, i/em, br) as native Flutter widgets — no
// flutter_html dependency, consistent with this project's preference for
// hand-rolled rendering over extra packages (see analytics CustomPainter
// charts). Unrecognized tags degrade gracefully to plain text.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/theme_context_ext.dart';

class RichHtmlText extends StatelessWidget {
  final String html;
  final double baseFontSize;
  final Color? color;

  const RichHtmlText({
    super.key,
    required this.html,
    this.baseFontSize = 14,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final blocks = _splitBlocks(html);
    if (blocks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((b) => _buildBlock(context, b)).toList(),
    );
  }

  // ── Block splitting ──────────────────────────────────────────────────────

  List<_Block> _splitBlocks(String raw) {
    final blocks = <_Block>[];
    final tagPattern = RegExp(
        r'<(h[1-3]|p|ul|li)[^>]*>(.*?)</\1>',
        caseSensitive: false, dotAll: true);

    var remaining = raw.trim();
    if (remaining.isEmpty) return blocks;

    // If there's no recognizable block tag at all, treat the whole string
    // as a single paragraph (covers plain-text descriptions too).
    if (!tagPattern.hasMatch(remaining)) {
      blocks.add(_Block('p', remaining));
      return blocks;
    }

    for (final match in tagPattern.allMatches(remaining)) {
      final tag = match.group(1)!.toLowerCase();
      final inner = match.group(2)!.trim();
      if (tag == 'ul') {
        final liPattern = RegExp(r'<li[^>]*>(.*?)</li>', caseSensitive: false, dotAll: true);
        final items = liPattern.allMatches(inner).map((m) => m.group(1)!.trim()).toList();
        blocks.add(_Block('ul', items.join('\u0000')));
      } else if (inner.isNotEmpty) {
        blocks.add(_Block(tag, inner));
      }
    }
    return blocks;
  }

  // ── Block rendering ─────────────────────────────────────────────────────

  Widget _buildBlock(BuildContext context, _Block block) {
    final textColor = color ?? context.colors.textPrimary;

    switch (block.tag) {
      case 'h1':
        return Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 12),
          child: _richSpan(context, block.content, baseFontSize + 8, FontWeight.w800, textColor),
        );
      case 'h2':
        return Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 10),
          child: _richSpan(context, block.content, baseFontSize + 5, FontWeight.w700, textColor),
        );
      case 'h3':
        return Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 8),
          child: _richSpan(context, block.content, baseFontSize + 2, FontWeight.w700, textColor),
        );
      case 'ul':
        final items = block.content.split('\u0000').where((s) => s.isNotEmpty);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 8),
                      child: Container(
                        width: 5, height: 5,
                        decoration: BoxDecoration(color: context.colors.primary, shape: BoxShape.circle),
                      ),
                    ),
                    Expanded(child: _richSpan(context, item, baseFontSize, FontWeight.normal, textColor)),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      case 'p':
      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _richSpan(context, block.content, baseFontSize, FontWeight.normal, textColor),
        );
    }
  }

  // ── Inline formatting (bold, italic, links) within a block ─────────────

  Widget _richSpan(BuildContext context, String inner, double size, FontWeight weight, Color textColor) {
    final spans = <InlineSpan>[];
    final inlinePattern = RegExp(
        r'<(b|strong|i|em|a)([^>]*)>(.*?)</\1>|<br\s*/?>',
        caseSensitive: false, dotAll: true);

    int cursor = 0;
    for (final match in inlinePattern.allMatches(inner)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: _stripTags(inner.substring(cursor, match.start))));
      }
      final tag = match.group(1)?.toLowerCase();
      if (tag == null) {
        spans.add(const TextSpan(text: '\n'));
      } else if (tag == 'b' || tag == 'strong') {
        spans.add(TextSpan(
            text: _stripTags(match.group(3) ?? ''),
            style: const TextStyle(fontWeight: FontWeight.w700)));
      } else if (tag == 'i' || tag == 'em') {
        spans.add(TextSpan(
            text: _stripTags(match.group(3) ?? ''),
            style: const TextStyle(fontStyle: FontStyle.italic)));
      } else if (tag == 'a') {
        final hrefMatch = RegExp(r'href=["\x27]([^"\x27]*)["\x27]').firstMatch(match.group(2) ?? '');
        final href = hrefMatch?.group(1) ?? '';
        spans.add(TextSpan(
          text: _stripTags(match.group(3) ?? ''),
          style: TextStyle(color: context.colors.primary, decoration: TextDecoration.underline),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (href.isNotEmpty) launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
            },
        ));
      }
      cursor = match.end;
    }
    if (cursor < inner.length) {
      spans.add(TextSpan(text: _stripTags(inner.substring(cursor))));
    }

    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: size, fontWeight: weight, color: textColor, height: 1.5),
        children: spans,
      ),
    );
  }

  String _stripTags(String s) =>
      s.replaceAll(RegExp(r'<[^>]+>'), '').replaceAll('&nbsp;', ' ').replaceAll('&amp;', '&');
}

class _Block {
  final String tag;
  final String content;
  _Block(this.tag, this.content);
}