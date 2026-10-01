// lib/features/magazine/screens/article_detail_screen.dart

import 'package:flutter/material.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/utils/responsive_utils.dart';
import '../models/article_model.dart';
import '../services/magazine_service.dart';
import '../../../l10n/generated/app_localizations.dart';

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
      setState(() { _loading = false; _error = AppLocalizations.of(context)!.articleNotFoundError; });
    } else {
      setState(() { _loading = false; _article = article; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: AppColors.customerColor,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.articleLoadingText,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            )
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          backgroundColor: universalBarColor(context),
          elevation: 0,
          leadingWidth: 66,
          leading: const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Center(child: UniversalBackButton()),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: a.coverImage.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        a.coverImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: context.colors.primary),
                      ),
                      // gradient overlay so text is readable
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              isDark
                                  ? const Color(0xFF0F172A).withOpacity(0.6)
                                  : Colors.black.withOpacity(0.4),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.customerColor,
                          AppColors.customerColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white.withOpacity(0.3),
                        size: 72,
                      ),
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
                padding: EdgeInsets.fromLTRB(
                  ResponsiveUtils.screenPadding(width),
                  24,
                  ResponsiveUtils.screenPadding(width),
                  48,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Category chip
                    if (a.categoryName.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: catColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          a.categoryName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: catColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),

                    const SizedBox(height: 14),

                    // Title
                    Text(
                      a.title,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.sp(26, scale, min: 22, max: 32),
                        fontWeight: FontWeight.w900,
                        color: context.colors.textPrimary,
                        height: 1.25,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Byline row ─────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Editorial label — "ProFinder Health Desk"
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : context.colors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : context.colors.divider,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_rounded,
                                  size: 12,
                                  color: catColor,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    a.editorialLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: context.colors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Read time
                        Icon(
                          Icons.schedule_outlined,
                          size: 13,
                          color: context.colors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          AppLocalizations.of(context)!.articleReadTime(a.readTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.textSecondary,
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Views
                        Icon(
                          Icons.visibility_outlined,
                          size: 13,
                          color: context.colors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatCount(a.viewsCount),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    // Published date
                    if (a.publishedAt.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(a.publishedAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: context.colors.textSecondary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    Divider(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : context.colors.divider,
                      height: 1,
                    ),
                    const SizedBox(height: 20),

                    // Summary callout box
                    if (a.summary.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.customerColor.withOpacity(0.08)
                              : context.colors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.customerColor.withOpacity(
                              isDark ? 0.15 : 0.15,
                            ),
                          ),
                        ),
                        child: Text(
                          a.summary,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.sp(15, scale, min: 14, max: 18),
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF93C5FD)
                                : context.colors.primary,
                            height: 1.6,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Content paragraphs
                    ..._renderContent(a.content, scale, isDark),

                    const SizedBox(height: 32),

                    // ── Footer attribution ──────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.03)
                            : context.colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : context.colors.divider,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.customerColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: AppColors.customerColor,
                              size: 18,
                            ),
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
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: context.colors.textPrimary,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                Text(
                                  AppLocalizations.of(context)!.articleFooterMagazineLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: context.colors.textSecondary,
                                    letterSpacing: 0.2,
                                  ),
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

  List<Widget> _renderContent(String raw, double scale, bool isDark) {
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
              fontSize: ResponsiveUtils.sp(20, scale, min: 18, max: 24),
              fontWeight: FontWeight.w800,
              color: context.colors.textPrimary,
              letterSpacing: -0.3,
              height: 1.3,
            ),
          ),
        );
      }
      if (para.startsWith('#')) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 16),
          child: Text(
            para.replaceFirst(RegExp(r'^#+\s*'), ''),
            style: TextStyle(
              fontSize: ResponsiveUtils.sp(18, scale, min: 16, max: 21),
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
              letterSpacing: -0.2,
              height: 1.3,
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
            color: context.colors.textPrimary,
            height: 1.75,
            letterSpacing: 0.2,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.customerColor.withOpacity(0.1),
                      AppColors.customerColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.article_outlined,
                  size: 40,
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _error!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.articleNotFoundMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: context.colors.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(AppLocalizations.of(context)!.goBackCta),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.customerColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
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
    catch (_) { return AppColors.customerColor; }
  }
}