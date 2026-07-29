// lib/features/admin/screens/admin_cities_screen.dart
//
// Content Management → Cities (nested under a Country — a city without
// its country context is meaningless, per design spec).
//
// Backend:
//   GET    /api/admin-panel/cities/?country=<id>
//   POST   /api/admin-panel/cities/            { name, country, status }
//   PATCH  /api/admin-panel/cities/<id>/        { status }
//   DELETE /api/admin-panel/cities/<id>/
//   POST   /api/admin-panel/cities/<id>/merge/  { variants: [...] }

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/theme_context_ext.dart';

class AdminCitiesScreen extends StatefulWidget {
  final dynamic country; // {id, name, ...} — null means "all cities"
  const AdminCitiesScreen({super.key, this.country});

  @override
  State<AdminCitiesScreen> createState() => _AdminCitiesScreenState();
}

class _AdminCitiesScreenState extends State<AdminCitiesScreen> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  List<dynamic> _cities = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final query = widget.country != null ? '?country=${widget.country['id']}' : '';
      final r = await _api.get('/admin-panel/cities/$query');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _cities = r.data is List ? List<dynamic>.from(r.data) : [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load cities'; });
    }
  }

  Future<void> _toggleStatus(dynamic c) async {
    final newStatus = c['status'] == 'active' ? 'coming_soon' : 'active';
    try {
      await _api.patch('/admin-panel/cities/${c['id']}/', {'status': newStatus});
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update.')));
    }
  }

  Future<void> _delete(dynamic c) async {
    try {
      await _api.delete('/admin-panel/cities/${c['id']}/');
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete.')));
    }
  }

  void _addDialog() {
    if (widget.country == null) return; // Adding requires a country context
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add City to ${widget.country['name']}'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'City name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(dialogContext);
              try {
                await _api.post('/admin-panel/cities/', {
                  'name': nameCtrl.text.trim(), 'country': widget.country['id'],
                });
                _load();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add — may already exist.')));
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mergeDialog(dynamic city) {
    final variantsCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Merge into "${city['name']}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter typo/variant spellings, comma-separated.', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            TextField(controller: variantsCtrl, decoration: const InputDecoration(hintText: 'variant1, variant2, ...')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor),
            onPressed: () async {
              final variants = variantsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
              if (variants.isEmpty) return;
              Navigator.pop(dialogContext);
              try {
                final r = await _api.post('/admin-panel/cities/${city['id']}/merge/', {'variants': variants});
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.data['message']?.toString() ?? 'Merged.')));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Merge failed.')));
              }
            },
            child: const Text('Merge', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNested = widget.country != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: isNested
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.adminColor,
              onPressed: _addDialog,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Add City', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.adminColor, Color(0xFFB91C1C)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Row(
                children: [
                  if (isNested)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    )
                  else
                    const Icon(Icons.location_city_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(isNested ? 'Cities — ${widget.country['name']}' : 'All Cities',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.adminColor))
                  : _error != null
                      ? _errorState()
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.adminColor,
                          child: _cities.isEmpty
                              ? ListView(children: [_emptyState()])
                              : ListView.builder(
                                  padding: EdgeInsets.fromLTRB(16, 8, 16, isNested ? 90 : 20),
                                  itemCount: _cities.length,
                                  itemBuilder: (_, i) => _cityCard(_cities[i]),
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cityCard(dynamic c) {
    final isActive = c['status'] == 'active';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['name']?.toString() ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    if (!isNested)
                      Text(c['country_name']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ),
              Switch(value: isActive, activeColor: context.colors.accent, onChanged: (_) => _toggleStatus(c)),
            ],
          ),
          Row(
            children: [
              _statChip(Icons.people_outline_rounded, '${c['user_count']} users'),
              const SizedBox(width: 10),
              _statChip(Icons.work_outline_rounded, '${c['professional_count']} pros'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _mergeDialog(c),
                  icon: const Icon(Icons.merge_type_rounded, size: 15),
                  label: const Text('Merge', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                onPressed: () => _delete(c),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool get isNested => widget.country != null;

  Widget _statChip(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF))),
        ],
      );

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Center(
          child: Column(children: [
            Icon(Icons.location_city_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            const Text('No cities added yet', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          ]),
        ),
      );

  Widget _errorState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 10),
            const Text('Failed to load cities', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor),
            ),
          ],
        ),
      );
}