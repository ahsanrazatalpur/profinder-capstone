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
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.adminColor,
                unselectedLabelColor: const Color(0xFF9CA3AF),
                indicatorColor: AppColors.adminColor,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                tabs: [
                  Tab(text: 'Categories (${_categories.length})'),
                  Tab(text: 'Subcategories (${_subcategories.length})'),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.adminColor, strokeWidth: 2.5))
                  : _error != null
                      ? _buildError()
                      : TabBarView(
                          controller: _tabController,
                          children: [_buildCategoriesTab(), _buildSubcategoriesTab()],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.adminColor, Color(0xFFB91C1C)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.category_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Categories',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          IconButton(
            onPressed: () => _tabController.index == 0 ? _showCategoryDialog() : _showSubcategoryDialog(),
            icon: const Icon(Icons.add_circle_rounded, color: Colors.white),
            tooltip: 'Add New',
          ),
        ],
      ),
    );
  }

  // ── Categories Tab ────────────────────────────────────────
  Widget _buildCategoriesTab() {
    if (_categories.isEmpty) return _emptyState('No categories yet', 'Add your first category to get started.');
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.adminColor,
      child: ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        itemCount: _categories.length,
        onReorder: _reorderCategories,
        itemBuilder: (_, i) {
          final c = _categories[i];
          return Container(
            key: ValueKey(c['id']),
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
                  child: const Icon(Icons.drag_indicator_rounded, color: Color(0xFFCBD5E1)),
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
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      Text(
                          '${c['professional_count'] ?? 0} pros · ${c['booking_count'] ?? 0} bookings · ${c['subcategory_count'] ?? 0} subcategories',
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF))),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _toggleFeatured(c),
                  tooltip: c['is_featured'] == true ? 'Featured — tap to unfeature' : 'Not featured — tap to feature',
                  icon: Icon(
                    c['is_featured'] == true ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 20,
                    color: c['is_featured'] == true ? const Color(0xFFF59E0B) : const Color(0xFF9CA3AF),
                  ),
                ),
                IconButton(
                  onPressed: () => _showCategoryDialog(category: c),
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                ),
                IconButton(
                  onPressed: () => _deleteCategory(c),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                ),
              ],
            ),
          );
        },
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
          title: Text(category == null ? 'Add Category' : 'Edit Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 10),
              TextField(controller: iconCtrl, decoration: const InputDecoration(labelText: 'Icon (optional)')),
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
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor),
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
                  _showSnack('Failed to save category.');
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
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
      _showSnack('Failed to update Featured status.');
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
      _showSnack('Cannot delete — professionals are still assigned to this category.');
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
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final s = filtered[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s['name']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                  Text(s['category_name']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF))),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                await _api.delete('/admin-panel/subcategories/${s['id']}/');
                                _load();
                              },
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                            ),
                          ],
                        ),
                      );
                    },
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
          title: const Text('Add Subcategory'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Parent Category'),
                items: _categories
                    .map<DropdownMenuItem<int>>((c) => DropdownMenuItem(value: c['id'], child: Text(c['name'])))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedCategory = v),
              ),
              const SizedBox(height: 10),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor),
              onPressed: () async {
                Navigator.pop(dialogContext);
                if (selectedCategory == null || nameCtrl.text.trim().isEmpty) return;
                try {
                  await _api.post('/admin-panel/subcategories/',
                      {'name': nameCtrl.text.trim(), 'category_id': selectedCategory});
                  _load();
                } catch (e) {
                  _showSnack('Failed to add subcategory.');
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────
  Widget _filterChip(String label, bool active, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.adminColor.withOpacity(0.12) : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? AppColors.adminColor : Colors.transparent),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppColors.adminColor : const Color(0xFF6B7280))),
        ),
      );

  Widget _emptyState(String title, String subtitle) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.category_outlined, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade400)),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 10),
            const Text('Failed to load', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor),
            ),
          ],
        ),
      );

  Future<bool?> _confirm(String title, String message) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}