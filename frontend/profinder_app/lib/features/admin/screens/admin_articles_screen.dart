// lib/features/admin/screens/admin_articles_screen.dart

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../magazine/models/article_model.dart';
import '../../magazine/services/magazine_service.dart';
import '../../magazine/screens/article_detail_screen.dart';
import 'admin_magazine_analytics_screen.dart'; // ✅ NEW
import '../../../core/theme/theme_context_ext.dart';

class AdminArticlesScreen extends StatefulWidget {
  const AdminArticlesScreen({super.key});

  @override
  State<AdminArticlesScreen> createState() => _AdminArticlesScreenState();
}

class _AdminArticlesScreenState extends State<AdminArticlesScreen>
    with SingleTickerProviderStateMixin {

  final _service = MagazineService();
  final _picker  = ImagePicker();
  final _api     = ApiService();

  late TabController _tabCtrl;

  bool                  _loading    = true;
  String?               _error;
  List<Article>         _articles   = [];
  List<ArticleCategory> _categories = [];
  Map<String, dynamic>  _summary    = {};

  List<Article> get _published => _articles.where((a) => a.isPublished).toList();
  List<Article> get _drafts    => _articles.where((a) => !a.isPublished).toList();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _service.adminGetAll(),
        _service.getCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _loading    = false;
        _articles   = results[0] as List<Article>;
        _categories = results[1] as List<ArticleCategory>;
      });
      // Summary cards (Total Articles / Published This Month / Total Views /
      // Most Read) — fetched separately so a failure here doesn't block the
      // main list from loading.
      try {
        final r = await _api.get('/articles/admin/analytics/');
        if (!mounted) return;
        setState(() => _summary = Map<String, dynamic>.from(r.data['summary'] ?? {}));
      } catch (_) {
        // Cards are supplementary — silently skip if analytics fails.
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load data.'; });
    }
  }

  Future<void> _togglePublish(Article a) async {
    final result = await _service.adminUpdate(a.slug, {'is_published': !a.isPublished});
    if (!mounted) return;
    if (result['success'] == true) {
      await _loadAll();
      _showSnack(
        a.isPublished ? 'Article unpublished.' : 'Article published! ✅',
        a.isPublished ? AppColors.warning : context.colors.accent,
      );
    } else {
      _showSnack('Update failed.', AppColors.error);
    }
  }

  Future<void> _delete(Article a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete article?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: Text(
          '"${a.title}" will be permanently deleted.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final ok = await _service.adminDelete(a.slug);
      if (!mounted) return;
      if (ok) {
        await _loadAll();
        _showSnack('Deleted.', AppColors.error);
      } else {
        _showSnack('Delete failed.', AppColors.error);
      }
    }
  }

  Future<void> _openForm({Article? editing}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ArticleFormDialog(
        editing:    editing,
        categories: _categories,
        service:    _service,
        picker:     _picker,
        onSaved: () { Navigator.pop(context); _loadAll(); },
      ),
    );
  }

  Future<void> _openCategoryManager() async {
    await showDialog(
      context: context,
      builder: (_) => _CategoryManagerDialog(
        categories: _categories,
        service:    _service,
        onChanged:  _loadAll,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
                color: AppColors.adminColor, strokeWidth: 2.5))
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    _buildSummaryCards(),
                    Expanded(child: _buildTabView()),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:       () => _openForm(),
        backgroundColor: AppColors.adminColor,
        icon:  const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Article',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ── AppBar — analytics, categories, refresh ───────────────────────────────
  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    title: const Text(
      'Tips Magazine',
      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
    ),
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF374151)),
      onPressed: () => Navigator.pop(context),
    ),
    actions: [
      // ✅ Analytics button — NEW
      IconButton(
        icon: const Icon(Icons.bar_chart_rounded, color: Color(0xFF374151), size: 22),
        tooltip: 'Analytics',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminMagazineAnalyticsScreen()),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.category_outlined, color: Color(0xFF374151), size: 22),
        tooltip: 'Manage Categories',
        onPressed: _openCategoryManager,
      ),
      IconButton(
        icon: const Icon(Icons.refresh_rounded, color: Color(0xFF9CA3AF), size: 20),
        onPressed: _loadAll,
      ),
    ],
    bottom: TabBar(
      controller:           _tabCtrl,
      indicatorColor:       AppColors.adminColor,
      labelColor:           AppColors.adminColor,
      unselectedLabelColor: const Color(0xFF9CA3AF),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      tabs: [
        Tab(text: 'All (${_articles.length})'),
        Tab(text: 'Published (${_published.length})'),
        Tab(text: 'Drafts (${_drafts.length})'),
      ],
    ),
  );

  // ── Summary Cards: Total Articles / Published This Month / Total Views / Most Read ──
  Widget _buildSummaryCards() {
    if (_summary.isEmpty) return const SizedBox.shrink();
    final cards = [
      ('Total Articles', '${_summary['total_articles'] ?? 0}', Icons.article_rounded, AppColors.adminColor),
      ('Published (Month)', '${_summary['published_this_month'] ?? 0}', Icons.check_circle_outline_rounded, context.colors.accent),
      ('Total Views', '${_summary['total_views'] ?? 0}', Icons.visibility_rounded, AppColors.info),
      ('Most Read', _summary['most_read_title'] != null
          ? '${_summary['most_read_views']} views' : '—', Icons.trending_up_rounded, const Color(0xFF7C3AED)),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: SizedBox(
        height: 64,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cards.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final (label, value, icon, color) = cards[i];
            return Container(
              width: 140,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFF9CA3AF)),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabView() => TabBarView(
    controller: _tabCtrl,
    children: [_buildList(_articles), _buildList(_published), _buildList(_drafts)],
  );
  Widget _buildList(List<Article> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color:  AppColors.adminColor.withOpacity(0.08),
              shape:  BoxShape.circle,
            ),
            child: const Icon(Icons.article_outlined, color: AppColors.adminColor, size: 32),
          ),
          const SizedBox(height: 14),
          const Text(
            'No articles here yet.',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
          ),
        ]),
      );
    }
    return RefreshIndicator(
      color:     AppColors.adminColor,
      onRefresh: _loadAll,
      child: ListView.builder(
        padding:     const EdgeInsets.fromLTRB(14, 14, 14, 90),
        itemCount:   list.length,
        itemBuilder: (_, i) => _buildCard(list[i]),
      ),
    );
  }

  // ── Article Card ──────────────────────────────────────────────────────────
  Widget _buildCard(Article a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
          color:      Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset:     const Offset(0, 2),
        )],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: a.coverImage.isNotEmpty
                ? Image.network(
                    a.coverImage, width: 70, height: 70, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _thumb(a.categoryColor),
                  )
                : _thumb(a.categoryColor),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Status badge + category
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: a.isPublished
                        ? context.colors.accent.withOpacity(0.12)
                        : const Color(0xFFF59E0B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    a.isPublished ? '✅ Published' : '📝 Draft',
                    style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: a.isPublished ? context.colors.accent : const Color(0xFFF59E0B),
                    ),
                  ),
                ),
                const Spacer(),
                if (a.categoryName.isNotEmpty)
                  Text(a.categoryName,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
              ]),

              const SizedBox(height: 6),

              // Title
              Text(
                a.title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // ✅ Editorial label — "ProFinder Health Desk" etc. (not admin name)
              Text(
                a.editorialLabel,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 3),

              // Read time + views
              Text(
                '${a.readTime} min read  ·  ${_fmtCount(a.viewsCount)} views',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),

              const SizedBox(height: 10),

              // Action buttons
              Row(children: [
                _btn('Preview', const Color(0xFF64748B), Icons.visibility_outlined,
                    () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => ArticleDetailScreen(slug: a.slug)))),
                const SizedBox(width: 8),
                _btn(
                  a.isPublished ? 'Unpublish' : 'Publish',
                  a.isPublished ? const Color(0xFFF59E0B) : context.colors.accent,
                  a.isPublished ? Icons.unpublished_outlined : Icons.publish_rounded,
                  () => _togglePublish(a),
                ),
                const SizedBox(width: 8),
                _btn('Edit',   context.colors.primary, Icons.edit_outlined,
                    () => _openForm(editing: a)),
                const SizedBox(width: 8),
                _btn('Delete', AppColors.error,   Icons.delete_outline_rounded,
                    () => _delete(a)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _thumb(String hex) {
    Color c;
    try { c = Color(int.parse(hex.replaceFirst('#', '0xFF'))); }
    catch (_) { c = context.colors.primary; }
    return Container(
      width: 70, height: 70, color: c.withOpacity(0.12),
      child: Icon(Icons.menu_book_rounded, color: c, size: 28),
    );
  }

  Widget _btn(String label, Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }

  String _fmtCount(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  Widget _buildError() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline_rounded, size: 52, color: AppColors.error),
      const SizedBox(height: 12),
      Text(_error!, style: const TextStyle(
          fontSize: 14, color: Color(0xFF374151), fontWeight: FontWeight.w600)),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: _loadAll,
        icon:  const Icon(Icons.refresh_rounded, size: 16),
        label: const Text('Retry'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.adminColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    ]),
  );

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior:        SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }
}


// ═══════════════════════════════════════════════════════════════════════════════
//  Article Form Dialog — Create & Edit
// ═══════════════════════════════════════════════════════════════════════════════
class _ArticleFormDialog extends StatefulWidget {
  final Article?              editing;
  final List<ArticleCategory> categories;
  final MagazineService       service;
  final ImagePicker           picker;
  final VoidCallback          onSaved;

  const _ArticleFormDialog({
    required this.editing,
    required this.categories,
    required this.service,
    required this.picker,
    required this.onSaved,
  });

  @override
  State<_ArticleFormDialog> createState() => _ArticleFormDialogState();
}

class _ArticleFormDialogState extends State<_ArticleFormDialog> {
  final _titleCtrl     = TextEditingController();
  final _summaryCtrl   = TextEditingController();
  final _contentCtrl   = TextEditingController();
  final _imageCtrl     = TextEditingController();
  final _readCtrl      = TextEditingController(text: '3');
  final _editorialCtrl = TextEditingController(text: 'ProFinder Editorial'); // ✅ NEW

  int?    _catId;
  bool    _isPublished    = false;
  bool    _saving         = false;
  bool    _uploadingImage = false;
  String? _dialogError;

  // ✅ Suggested editorial labels — admin tap karke quickly select kar sake
  static const _editorialSuggestions = [
    'ProFinder Editorial',
    'ProFinder Health Desk',
    'Legal Advisory Team',
    'ProFinder Home Advisory',
    'Finance & Money Desk',
    'ProFinder Lifestyle',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _titleCtrl.text     = e.title;
      _summaryCtrl.text   = e.summary;
      _contentCtrl.text   = e.content;
      _imageCtrl.text     = e.coverImage;
      _readCtrl.text      = e.readTime.toString();
      _editorialCtrl.text = e.editorialLabel.isNotEmpty
          ? e.editorialLabel
          : 'ProFinder Editorial';
      _catId              = e.categoryId;
      _isPublished        = e.isPublished;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    _contentCtrl.dispose();
    _imageCtrl.dispose();
    _readCtrl.dispose();
    _editorialCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await widget.picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() { _uploadingImage = true; _dialogError = null; });
    try {
      dio.MultipartFile mp;
      if (kIsWeb) {
        final Uint8List bytes = await picked.readAsBytes();
        mp = dio.MultipartFile.fromBytes(bytes, filename: picked.name);
      } else {
        mp = await dio.MultipartFile.fromFile(picked.path, filename: picked.name);
      }
      final url = await widget.service.uploadCoverImage(
          dio.FormData.fromMap({'image': mp}));
      if (url != null) _imageCtrl.text = url;
    } catch (_) {
      setState(() { _dialogError = 'Image upload failed.'; });
    } finally {
      setState(() { _uploadingImage = false; });
    }
  }

  Future<void> _save() async {
    final title     = _titleCtrl.text.trim();
    final content   = _contentCtrl.text.trim();
    final editorial = _editorialCtrl.text.trim();

    if (title.isEmpty || content.isEmpty) {
      setState(() { _dialogError = 'Title and content are required.'; });
      return;
    }
    setState(() { _saving = true; _dialogError = null; });

    final data = <String, dynamic>{
      'title':           title,
      'summary':         _summaryCtrl.text.trim(),
      'content':         content,
      'cover_image':     _imageCtrl.text.trim(),
      'read_time':       int.tryParse(_readCtrl.text.trim()) ?? 3,
      'is_published':    _isPublished,
      'editorial_label': editorial.isEmpty ? 'ProFinder Editorial' : editorial,
      if (_catId != null) 'category': _catId,
    };

    final result = widget.editing != null
        ? await widget.service.adminUpdate(widget.editing!.slug, data)
        : await widget.service.adminCreate(data);

    setState(() { _saving = false; });
    if (result['success'] == true) {
      widget.onSaved();
    } else {
      setState(() { _dialogError = result['message'] ?? 'Save failed.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editing != null;

    return Dialog(
      shape:        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      child: Container(
        width:       double.maxFinite,
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Dialog Header ─────────────────────────────────────────────
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:        AppColors.adminColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.article_outlined,
                  color: AppColors.adminColor, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              isEditing ? 'Edit Article' : 'New Article',
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF), size: 22),
            ),
          ]),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // ── Scrollable Fields ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                _field(_titleCtrl, 'Title *',
                    'e.g. 5 Legal Rights Every Tenant Should Know', 2),
                const SizedBox(height: 12),

                _field(_summaryCtrl, 'Summary (card preview)',
                    'Short 1–2 sentence preview shown on magazine cards', 2),
                const SizedBox(height: 12),

                _field(_contentCtrl, 'Content *',
                    'Write full article. Use ## Heading for subheadings.', 10),
                const SizedBox(height: 12),

                // ── Cover Image ───────────────────────────────────────
                _label('Cover Image'),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _imageCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: _dec('https://… or pick from gallery'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _uploadingImage ? null : _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:        AppColors.adminColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.adminColor.withOpacity(0.25)),
                      ),
                      child: _uploadingImage
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.adminColor))
                          : const Icon(Icons.image_rounded,
                              color: AppColors.adminColor, size: 20),
                    ),
                  ),
                ]),

                const SizedBox(height: 12),

                // ── Editorial Label ✅ NEW ─────────────────────────────
                _label('Editorial / Byline'),
                TextField(
                  controller: _editorialCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: _dec('e.g. ProFinder Health Desk'),
                ),
                const SizedBox(height: 8),

                // Quick suggestion chips
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: _editorialSuggestions.map((s) {
                    final isSelected = _editorialCtrl.text == s;
                    return GestureDetector(
                      onTap: () => setState(() => _editorialCtrl.text = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.adminColor.withOpacity(0.12)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.adminColor.withOpacity(0.4)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            fontSize:   11,
                            fontWeight: FontWeight.w600,
                            color:      isSelected
                                ? AppColors.adminColor
                                : const Color(0xFF374151),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                // ── Category + Read Time ──────────────────────────────
                Row(children: [
                  Expanded(
                    flex: 3,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _label('Category'),
                      DropdownButtonFormField<int>(
                        value:      _catId,
                        isExpanded: true,
                        hint: const Text('Select…',
                            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                          filled: true, fillColor: const Color(0xFFF9FAFB),
                        ),
                        items: widget.categories
                            .map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name,
                                      style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _catId = v),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _label('Read time (min)'),
                      TextField(
                        controller:  _readCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 13),
                        decoration: _dec('3'),
                      ),
                    ]),
                  ),
                ]),

                const SizedBox(height: 14),

                // ── Publish Toggle ────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isPublished
                        ? context.colors.accent.withOpacity(0.06)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isPublished
                          ? context.colors.accent.withOpacity(0.25)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(children: [
                    Icon(
                      _isPublished ? Icons.public_rounded : Icons.edit_note_rounded,
                      color: _isPublished ? context.colors.accent : const Color(0xFF9CA3AF),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          _isPublished ? 'Published' : 'Save as Draft',
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: _isPublished
                                ? context.colors.accent
                                : const Color(0xFF374151),
                          ),
                        ),
                        Text(
                          _isPublished
                              ? 'Visible to all users in Tips Magazine.'
                              : 'Only visible to admins.',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF9CA3AF)),
                        ),
                      ]),
                    ),
                    Switch(
                      value:       _isPublished,
                      activeColor: context.colors.accent,
                      onChanged:   (v) => setState(() => _isPublished = v),
                    ),
                  ]),
                ),

                // ── Error Box ─────────────────────────────────────────
                if (_dialogError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:        AppColors.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_dialogError!,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.error)),
                      ),
                    ]),
                  ),
                ],
              ]),
            ),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // ── Save Button ────────────────────────────────────────────
          SizedBox(
            width: double.infinity, height: 46,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor:         AppColors.adminColor,
                disabledBackgroundColor: AppColors.adminColor.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text(
                      isEditing ? 'Save Changes' : 'Create Article',
                      style: const TextStyle(
                          fontSize:   15,
                          fontWeight: FontWeight.w700,
                          color:      Colors.white),
                    ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint, int maxLines) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label),
        TextField(
          controller: ctrl,
          maxLines:   maxLines,
          style: const TextStyle(fontSize: 13),
          decoration: _dec(hint),
        ),
      ]);

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
  );

  InputDecoration _dec(String hint) => InputDecoration(
    hintText:  hint,
    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:   const BorderSide(color: Color(0xFFE5E7EB))),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:   const BorderSide(color: Color(0xFFE5E7EB))),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:   const BorderSide(color: AppColors.adminColor, width: 1.5)),
    filled:    true,
    fillColor: const Color(0xFFF9FAFB),
  );
}


// ═══════════════════════════════════════════════════════════════════════════════
//  Category Manager Dialog
// ═══════════════════════════════════════════════════════════════════════════════
class _CategoryManagerDialog extends StatefulWidget {
  final List<ArticleCategory> categories;
  final MagazineService       service;
  final VoidCallback          onChanged;

  const _CategoryManagerDialog({
    required this.categories,
    required this.service,
    required this.onChanged,
  });

  @override
  State<_CategoryManagerDialog> createState() => _CategoryManagerDialogState();
}

class _CategoryManagerDialogState extends State<_CategoryManagerDialog> {
  final _nameCtrl = TextEditingController();

  late List<ArticleCategory> _cats;
  bool    _saving = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _cats = List.from(widget.categories);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { setState(() { _err = 'Name is required.'; }); return; }
    setState(() { _saving = true; _err = null; });
    final res = await widget.service.adminCreateCategory({'name': name});
    setState(() { _saving = false; });
    if (res['success'] == true) {
      _nameCtrl.clear();
      widget.onChanged();
      final updated = await widget.service.getCategories();
      if (mounted) setState(() => _cats = updated);
    } else {
      setState(() { _err = 'Failed to add.'; });
    }
  }

  Future<void> _delete(ArticleCategory c) async {
    final ok = await widget.service.adminDeleteCategory(c.id);
    if (!mounted) return;
    if (ok) {
      widget.onChanged();
      setState(() => _cats.removeWhere((x) => x.id == c.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:        RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize:      MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(children: [
              const Text('Manage Categories',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                      color: Color(0xFF111827))),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded,
                    color: Color(0xFF9CA3AF), size: 22),
              ),
            ]),
            const SizedBox(height: 14),

            // Existing categories list
            if (_cats.isEmpty)
              const Text('No categories yet.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)))
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount:  _cats.length,
                  itemBuilder: (_, i) {
                    final c = _cats[i];
                    Color col;
                    try {
                      col = Color(int.parse(c.color.replaceFirst('#', '0xFF')));
                    } catch (_) { col = context.colors.primary; }

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color:  col.withOpacity(0.12),
                          shape:  BoxShape.circle,
                        ),
                        child: Icon(Icons.label_rounded, color: col, size: 18),
                      ),
                      title: Text(c.name,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text('${c.articlesCount} articles',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF9CA3AF))),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.error, size: 18),
                        onPressed: () => _delete(c),
                      ),
                    );
                  },
                ),
              ),

            const Divider(height: 24),

            const Text('Add New Category',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: Color(0xFF374151))),
            const SizedBox(height: 10),

            TextField(
              controller: _nameCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText:  'Category name',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                filled: true, fillColor: const Color(0xFFF9FAFB),
              ),
            ),

            if (_err != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_err!,
                    style: const TextStyle(fontSize: 11, color: AppColors.error)),
              ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity, height: 42,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _add,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.adminColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Category',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}