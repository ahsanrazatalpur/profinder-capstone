// lib/features/magazine/screens/article_detail_screen.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../models/article_model.dart';
import '../services/magazine_service.dart';
import '../../../core/theme/theme_context_ext.dart';

class ArticleDetailScreen extends StatefulWidget {
  final String slug;
  const ArticleDetailScreen({super.key, required this.slug});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final _service = MagazineService();
  bool     _loading = true;
  String?  _error;
  Article? _article;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final article = await _service.getArticle(widget.slug);
    if (!mounted) return;
    if (article == null) {
      setState(() { _loading = false; _error = 'Article not found.'; });
    } else {
      setState(() { _loading = false; _article = article; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: _loading
          ? Center(child: CircularProgressIndicator(
                color: context.colors.primary, strokeWidth: 2.5))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final a        = _article!;
    final catColor = _hexColor(a.categoryColor);
    final width = MediaQuery.sizeOf(context).width;
    final scale = ResponsiveUtils.scaleForWidth(width);
    // Long-form reading text stretched across a full tablet width is hard
    // to read (lines too long) — capping and centering the body at a
    // reader-friendly width is the standard "reader mode" pattern, while
    // the hero image above still spans the full screen.
    final readingMaxWidth = width > 720 ? 680.0 : width;

    return CustomScrollView(
      slivers: [

        // ── Hero AppBar ────────────────────────────────────
        SliverAppBar(
          expandedHeight: a.coverImage.isNotEmpty ? 260 : 140,
          pinned:         true,
          backgroundColor: context.colors.primary,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:        Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: a.coverImage.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(a.coverImage, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: context.colors.primary)),
                      // gradient overlay so text is readable
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black54],
                            begin:  Alignment.topCenter,
                            end:    Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
                        begin:  Alignment.topLeft,
                        end:    Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.menu_book_rounded,
                          color: Colors.white24, size: 72),
                    ),
                  ),
          ),
        ),

        // ── Article Body ───────────────────────────────────
        SliverToBoxAdapter(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: readingMaxWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(ResponsiveUtils.screenPadding(width), 24, ResponsiveUtils.screenPadding(width), 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Category chip
                    if (a.categoryName.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:        catColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          a.categoryName.toUpperCase(),
                          style: TextStyle(
                            fontSize:      9,
                            fontWeight:    FontWeight.w800,
                            color:         catColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Title
                    Text(
                      a.title,
                      style: TextStyle(
                        fontSize:      ResponsiveUtils.sp(24, scale, min: 22, max: 30),
                        fontWeight:    FontWeight.w900,
                        color:         context.colors.textPrimary,
                        height:        1.25,
                        letterSpacing: -0.4,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Byline row ─────────────────────────────
                    Row(
                      children: [
                        // Editorial label — "ProFinder Health Desk"
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color:        context.colors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: context.colors.divider),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_rounded,
                                    size: 12, color: catColor),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    a.editorialLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize:   12,
                                      fontWeight: FontWeight.w700,
                                      color:      context.colors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Read time
                        Icon(Icons.schedule_outlined,
                            size: 13, color: context.colors.textSecondary),
                        const SizedBox(width: 3),
                        Text('${a.readTime} min read',
                            style: TextStyle(
                                fontSize: 12, color: context.colors.textSecondary)),

                        const SizedBox(width: 10),

                        // Views
                        Icon(Icons.visibility_outlined,
                            size: 13, color: context.colors.textSecondary),
                        const SizedBox(width: 3),
                        Text(_formatCount(a.viewsCount),
                            style: TextStyle(
                                fontSize: 12, color: context.colors.textSecondary)),
                      ],
                    ),

                    // Published date
                    if (a.publishedAt.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(a.publishedAt),
                        style: TextStyle(
                            fontSize: 11, color: context.colors.textSecondary),
                      ),
                    ],

                    const SizedBox(height: 20),
                    Divider(color: context.colors.divider),
                    const SizedBox(height: 20),

                    // Summary callout box
                    if (a.summary.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:        context.colors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: context.colors.primary.withOpacity(0.15)),
                        ),
                        child: Text(
                          a.summary,
                          style: TextStyle(
                            fontSize:   ResponsiveUtils.sp(14, scale, min: 13, max: 17),
                            fontWeight: FontWeight.w600,
                            color:      context.colors.primary,
                            height:     1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Content paragraphs
                    ..._renderContent(a.content, scale),

                    const SizedBox(height: 32),

                    // ── Footer attribution ──────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:        context.colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.colors.divider),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color:  context.colors.primary.withOpacity(0.10),
                              shape:  BoxShape.circle,
                            ),
                            child: Icon(Icons.menu_book_rounded,
                                color: context.colors.primary, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.editorialLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize:   12,
                                    fontWeight: FontWeight.w700,
                                    color:      context.colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'ProFinder Tips Magazine',
                                  style: TextStyle(
                                      fontSize: 11, color: context.colors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _renderContent(String raw, double scale) {
    final paragraphs = raw
        .split(RegExp(r'\n{2,}'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return paragraphs.map((para) {
      if (para.startsWith('##')) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 20),
          child: Text(
            para.replaceFirst(RegExp(r'^#+\s*'), ''),
            style: TextStyle(
              fontSize:      ResponsiveUtils.sp(19, scale, min: 18, max: 23),
              fontWeight:    FontWeight.w800,
              color:         context.colors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          para,
          style: TextStyle(
            fontSize: ResponsiveUtils.sp(15, scale, min: 14, max: 18),
            color:    context.colors.textPrimary,
            height:   1.75,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildError() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.article_outlined, size: 56, color: context.colors.textSecondary),
      const SizedBox(height: 14),
      Text(_error!, style: TextStyle(fontSize: 15,
          color: context.colors.textPrimary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(backgroundColor: context.colors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: const Text('Go Back'),
      ),
    ]),
  );

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month]} ${dt.day}, ${dt.year}';
    } catch (_) { return ''; }
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }

  Color _hexColor(String hex) {
    try { return Color(int.parse(hex.replaceFirst('#', '0xFF'))); }
    catch (_) { return context.colors.primary; }
  }
}