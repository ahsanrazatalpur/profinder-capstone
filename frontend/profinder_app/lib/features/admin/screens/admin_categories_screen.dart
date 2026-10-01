// lib/features/admin/screens/admin_categories_screen.dart
//
// Categories & Subcategories — combined page with 2 tabs, since a
// subcategory without its parent category context is meaningless
// (matches the Business Management design spec: nest, don't separate).
//
// Backend:
//   GET/POST      /api/admin-panel/categories/
//   PATCH/DELETE  /api/admin-panel/categories/<id>/
//   GET/POST      /api/admin-panel/subcategories/?category=<id>
//   PATCH/DELETE  /api/admin-panel/subcategories/<id>/

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../shared/widgets/universal_app_bar.dart';

// Content is centered and width-capped on tablet/desktop so rows of text
// don't stretch uncomfortably wide on large screens.
const double _kWideContentMaxWidth = 760;
const double _kTabletBreakpoint = 720;

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _api = ApiService();

  bool _loading = true;
  String? _error;
  List<dynamic> _categories = [];
  List<dynamic> _subcategories = [];
  int? _subcategoryFilter; // filter subcategories by parent category id

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Rebuilds the header so its "Add" button/tooltip target the tab that
    // is actually visible (Category vs. Subcategory) as the user swipes.
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final catRes = await _api.get('/admin-panel/categories/');
      final subRes = await _api.get('/admin-panel/subcategories/');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _categories = catRes.data is List ? List<dynamic>.from(catRes.data) : [];
        _subcategories = subRes.data is List ? List<dynamic>.from(subRes.data) : [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load categories'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: UniversalAppBar(
        title: 'Categories',
        icon: Icons.category_rounded,
        showBack: false,
        actions: [
          AppBarIconButton(
            icon: Icons.add_circle_rounded,
            tooltip: _tabController.index == 1 ? 'Add Subcategory' : 'Add Category',
            onPressed: () => _tabController.index == 1 ? _showSubcategoryDialog() : _showCategoryDialog(),
            onGradient: true,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.adminColor,
                unselectedLabelColor: const Color(0xFF9CA3AF),
                indicatorColor: AppColors.adminColor,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: 'Categories (${_categories.length})'),
                  Tab(text: 'Subcategories (${_subcategories.length})'),
                ],
              ),
            ),
            Expanded(
              // Cross-fades between loading / error / tab content instead
              // of an abrupt jump-cut when data finishes loading.
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _loading
                    ? const Center(
                        key: ValueKey('loading'),
                        child: CircularProgressIndicator(color: AppColors.adminColor, strokeWidth: 2.5))
                    : _error != null
                        ? _buildError()
                        : TabBarView(
                            key: const ValueKey('content'),
                            controller: _tabController,
                            children: [_buildCategoriesTab(), _buildSubcategoriesTab()],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Categories Tab ────────────────────────────────────────
  Widget _buildCategoriesTab() {
    if (_categories.isEmpty) return _emptyState('No categories yet', 'Add your first category to get started.');
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.adminColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kWideContentMaxWidth),
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            itemCount: _categories.length,
            onReorder: _reorderCategories,
            // A custom drag handle (the 6-dot icon) is already built into
            // each row on the left via ReorderableDragStartListener, so the
            // library's own auto-generated handle on the right is disabled
            // here — otherwise it renders as a stray "=" glyph next to Delete.
            buildDefaultDragHandles: false,
            itemBuilder: (_, i) {
              final c = _categories[i];
              // Keying by ReorderableDragStartListener wraps the whole row
              // so the entire card (not just the handle) can be grabbed on
              // touch, while still allowing hover/tap on the action icons.
              return _HoverLift(
                key: ValueKey(c['id']),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      ReorderableDragStartListener(
                        index: i,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Icon(Icons.drag_indicator_rounded, color: Color(0xFFCBD5E1)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(color: context.colors.primary.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(Icons.category_outlined, size: 18, color: context.colors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['name']?.toString() ?? '',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(
                                '${c['professional_count'] ?? 0} pros · ${c['booking_count'] ?? 0} bookings · ${c['subcategory_count'] ?? 0} subcategories',
                                style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF)),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      // ✅ FIX: These three action icons previously used the
                      // default IconButton hit-box (48x48 each, no gaps),
                      // which on a narrow phone screen pushed the row past
                      // its available width. The row would silently clip,
                      // making the Delete icon appear cut in half (looked
                      // like a stray "=" glyph) and made Edit/Delete taps
                      // land on the wrong control. `_HoverIconButton` now
                      // renders a tight, fixed-size hit box, and each icon
                      // has explicit spacing so all three are fully visible
                      // and independently tappable.
                      _HoverIconButton(
                        onPressed: () => _toggleFeatured(c),
                        tooltip: c['is_featured'] == true ? 'Featured — tap to unfeature' : 'Not featured — tap to feature',
                        icon: c['is_featured'] == true ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: c['is_featured'] == true ? const Color(0xFFF59E0B) : const Color(0xFF9CA3AF),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      _HoverIconButton(
                        onPressed: () => _showCategoryDialog(category: c),
                        tooltip: 'Edit',
                        icon: Icons.edit_outlined,
                        color: const Color(0xFF64748B),
                        size: 17,
                      ),
                      const SizedBox(width: 4),
                      _HoverIconButton(
                        onPressed: () => _deleteCategory(c),
                        tooltip: 'Delete',
                        icon: Icons.delete_outline_rounded,
                        color: AppColors.error,
                        size: 17,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _reorderCategories(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, item);
    });
    // Persist new order values sequentially.
    for (var i = 0; i < _categories.length; i++) {
      try {
        await _api.patch('/admin-panel/categories/${_categories[i]['id']}/', {'order': i});
      } catch (_) {}
    }
  }

  void _showCategoryDialog({dynamic category}) {
    final nameCtrl = TextEditingController(text: category?['name']?.toString() ?? '');
    final iconCtrl = TextEditingController(text: category?['icon']?.toString() ?? '');
    bool isFeatured = category?['is_featured'] == true;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.adminColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  category == null ? Icons.add_rounded : Icons.edit_rounded,
                  color: AppColors.adminColor, size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(category == null ? 'Add Category' : 'Edit Category',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: _dialogFieldDecoration('Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: iconCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: _dialogFieldDecoration('Icon (optional)'),
              ),
              const SizedBox(height: 6),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Featured', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Show on Guest Home\'s Featured Categories (max 6)',
                    style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                value: isFeatured,
                activeColor: AppColors.adminColor,
                onChanged: (v) => setDialogState(() => isFeatured = v),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF6B7280)),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  if (category == null) {
                    await _api.post('/admin-panel/categories/', {
                      'name': nameCtrl.text.trim(),
                      'icon': iconCtrl.text.trim(),
                      'is_featured': isFeatured,
                    });
                  } else {
                    await _api.patch('/admin-panel/categories/${category['id']}/', {
                      'name': nameCtrl.text.trim(),
                      'icon': iconCtrl.text.trim(),
                      'is_featured': isFeatured,
                    });
                  }
                  _load();
                } catch (e) {
                  _showSnack('Failed to save category.', isError: true);
                }
              },
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  /// Quick-toggle Featured directly from the list row, without opening
  /// the full edit dialog — admins manage Featured Categories from here.
  Future<void> _toggleFeatured(dynamic c) async {
    final next = !(c['is_featured'] == true);
    setState(() => c['is_featured'] = next); // optimistic
    try {
      await _api.patch('/admin-panel/categories/${c['id']}/', {'is_featured': next});
    } catch (e) {
      setState(() => c['is_featured'] = !next); // revert on failure
      _showSnack('Failed to update Featured status.', isError: true);
    }
  }

  Future<void> _deleteCategory(dynamic c) async {
    final confirmed = await _confirm('Delete "${c['name']}"?',
        'This cannot be undone. Categories with assigned professionals cannot be deleted.');
    if (confirmed != true) return;
    try {
      await _api.delete('/admin-panel/categories/${c['id']}/');
      _load();
    } catch (e) {
      _showSnack('Cannot delete — professionals are still assigned to this category.', isError: true);
    }
  }

  // ── Subcategories Tab ─────────────────────────────────────
  Widget _buildSubcategoriesTab() {
    final filtered = _subcategoryFilter == null
        ? _subcategories
        : _subcategories.where((s) => s['category_id'] == _subcategoryFilter).toList();

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _filterChip('All', _subcategoryFilter == null, () => setState(() => _subcategoryFilter = null)),
                const SizedBox(width: 8),
                ..._categories.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _filterChip(c['name'], _subcategoryFilter == c['id'],
                          () => setState(() => _subcategoryFilter = c['id'])),
                    )),
              ],
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _emptyState('No subcategories', 'Add one under a parent category.')
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.adminColor,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: _kWideContentMaxWidth),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final s = filtered[i];
                          return _HoverLift(
                            key: ValueKey(s['id']),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white, borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      color: context.colors.primary.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.subdirectory_arrow_right_rounded,
                                        size: 16, color: context.colors.primary),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s['name']?.toString() ?? '',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                            maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text(s['category_name']?.toString() ?? '',
                                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF)),
                                            maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  _HoverIconButton(
                                    onPressed: () async {
                                      await _api.delete('/admin-panel/subcategories/${s['id']}/');
                                      _load();
                                    },
                                    tooltip: 'Delete',
                                    icon: Icons.delete_outline_rounded,
                                    color: AppColors.error,
                                    size: 17,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  void _showSubcategoryDialog() {
    final nameCtrl = TextEditingController();
    int? selectedCategory = _categories.isNotEmpty ? _categories.first['id'] : null;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.adminColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_rounded, color: AppColors.adminColor, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Add Subcategory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                value: selectedCategory,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9CA3AF)),
                decoration: _dialogFieldDecoration('Parent Category'),
                items: _categories
                    .map<DropdownMenuItem<int>>((c) => DropdownMenuItem(
                        value: c['id'], child: Text(c['name'], style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedCategory = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: _dialogFieldDecoration('Name'),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF6B7280)),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                if (selectedCategory == null || nameCtrl.text.trim().isEmpty) return;
                try {
                  await _api.post('/admin-panel/subcategories/',
                      {'name': nameCtrl.text.trim(), 'category_id': selectedCategory});
                  _load();
                } catch (e) {
                  _showSnack('Failed to add subcategory.', isError: true);
                }
              },
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────
  InputDecoration _dialogFieldDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.adminColor, width: 1.5),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
      );

  Widget _filterChip(String label, bool active, VoidCallback onTap) => _HoverScaleChip(
        label: label,
        active: active,
        onTap: onTap,
      );

  Widget _emptyState(String title, String subtitle) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.category_outlined, size: 40, color: Colors.grey.shade300),
                  ),
                  const SizedBox(height: 14),
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _buildError() => Center(
        key: const ValueKey('error'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 14),
            const Text('Failed to load', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );

  Future<bool?> _confirm(String title, String message) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), shape: BoxShape.circle),
            child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 26),
          ),
          title: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4)),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white, size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.adminColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Small shared UI helpers — visual polish only, no logic
// ═══════════════════════════════════════════════════════════════════════════

/// Icon button with a subtle hover background on desktop/web and a tooltip.
/// ✅ FIX: previously wrapped a plain `IconButton`, which carries a default
/// 48x48 minimum hit box and internal padding. Placed three-in-a-row (star/
/// edit/delete) on a narrow phone screen, that pushed the row wider than
/// the card, so the row silently clipped — the Delete icon got cut in half
/// and looked like a stray "=" mark, and taps landed on the wrong button.
/// `constraints`/`padding` are now tightened so the tappable area matches
/// the icon's actual visual size, and callers add explicit spacing between
/// buttons instead of relying on IconButton's built-in padding for gaps.
class _HoverIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;
  final double size;

  const _HoverIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.size = 22,
  });

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    // Tap target is the icon size plus a small fixed margin — enough for a
    // comfortable finger-press without overlapping its neighbors.
    final hitBox = widget.size + 20;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!mounted) return;
        setState(() => _hovering = true);
      },
      onExit: (_) {
        if (!mounted) return;
        setState(() => _hovering = false);
      },
      child: Tooltip(
        message: widget.tooltip,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: hitBox,
              height: hitBox,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _hovering
                    ? (widget.color ?? const Color(0xFF374151)).withOpacity(0.08)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: widget.color, size: widget.size),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps a card with a gentle hover "lift" (translate + deeper shadow) on
/// platforms that support a mouse cursor. No-ops on touch-only devices.
class _HoverLift extends StatefulWidget {
  final Widget child;

  const _HoverLift({super.key, required this.child});

  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (!mounted) return;
        setState(() => _hovering = true);
      },
      onExit: (_) {
        if (!mounted) return;
        setState(() => _hovering = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: _hovering
            ? (Matrix4.identity()..translate(0.0, -2.0))
            : Matrix4.identity(),
        decoration: _hovering
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              )
            : null,
        child: widget.child,
      ),
    );
  }
}

/// Filter chip used in the Subcategories tab, with an animated selected
/// state and a subtle hover background on desktop/web.
class _HoverScaleChip extends StatefulWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _HoverScaleChip({required this.label, required this.active, required this.onTap});

  @override
  State<_HoverScaleChip> createState() => _HoverScaleChipState();
}

class _HoverScaleChipState extends State<_HoverScaleChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!mounted) return;
        setState(() => _hovering = true);
      },
      onExit: (_) {
        if (!mounted) return;
        setState(() => _hovering = false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.active
                ? AppColors.adminColor.withOpacity(0.12)
                : (_hovering ? const Color(0xFFEDEFF3) : const Color(0xFFF5F7FA)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.active ? AppColors.adminColor : Colors.transparent),
          ),
          child: Text(widget.label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: widget.active ? FontWeight.w700 : FontWeight.w500,
                  color: widget.active ? AppColors.adminColor : const Color(0xFF6B7280))),
        ),
      ),
    );
  }
}