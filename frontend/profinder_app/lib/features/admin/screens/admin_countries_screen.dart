// lib/features/admin/screens/admin_countries_screen.dart
//
// Content Management → Countries
// Master reference list + a "Merge" tool that normalizes typo variants
// in UserProfile.country (free-text) into the canonical spelling —
// the single most valuable action on this page (see design spec).
//
// Backend:
//   GET    /api/admin-panel/countries/
//   POST   /api/admin-panel/countries/            { name, status }
//   PATCH  /api/admin-panel/countries/<id>/        { status }
//   DELETE /api/admin-panel/countries/<id>/
//   POST   /api/admin-panel/countries/<id>/merge/  { variants: [...] }

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import 'admin_cities_screen.dart';
import '../../../core/theme/theme_context_ext.dart';

class AdminCountriesScreen extends StatefulWidget {
  const AdminCountriesScreen({super.key});

  @override
  State<AdminCountriesScreen> createState() => _AdminCountriesScreenState();
}

class _AdminCountriesScreenState extends State<AdminCountriesScreen> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  List<dynamic> _countries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await _api.get('/admin-panel/countries/');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _countries = r.data is List ? List<dynamic>.from(r.data) : [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load countries'; });
    }
  }

  Future<void> _toggleStatus(dynamic c) async {
    final newStatus = c['status'] == 'active' ? 'coming_soon' : 'active';
    try {
      await _api.patch('/admin-panel/countries/${c['id']}/', {'status': newStatus});
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update.')));
    }
  }

  Future<void> _delete(dynamic c) async {
    try {
      await _api.delete('/admin-panel/countries/${c['id']}/');
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete.')));
    }
  }

  void _addDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Country'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Country name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(dialogContext);
              try {
                await _api.post('/admin-panel/countries/', {'name': nameCtrl.text.trim()});
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

  void _mergeDialog(dynamic country) {
    final variantsCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Merge into "${country['name']}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter typo/variant spellings found in user profiles, comma-separated (e.g. pakistan, Pakistn).',
                style: TextStyle(fontSize: 12)),
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
                final r = await _api.post('/admin-panel/countries/${country['id']}/merge/', {'variants': variants});
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.adminColor,
        onPressed: _addDialog,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Country', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
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
                  const Icon(Icons.public_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Countries', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text('${_countries.where((c) => c['status'] == 'active').length} active',
                            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.85))),
                      ],
                    ),
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
                          child: _countries.isEmpty
                              ? ListView(children: [_emptyState()])
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                                  itemCount: _countries.length,
                                  itemBuilder: (_, i) => _countryCard(_countries[i]),
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _countryCard(dynamic c) {
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
                child: Text(c['name']?.toString() ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              Switch(
                value: isActive,
                activeColor: context.colors.accent,
                onChanged: (_) => _toggleStatus(c),
              ),
            ],
          ),
          Row(
            children: [
              _statChip(Icons.people_outline_rounded, '${c['user_count']} users'),
              const SizedBox(width: 10),
              _statChip(Icons.work_outline_rounded, '${c['professional_count']} pros'),
              const SizedBox(width: 10),
              _statChip(Icons.location_city_rounded, '${c['city_count']} cities'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => AdminCitiesScreen(country: c))),
                  icon: const Icon(Icons.location_city_rounded, size: 15),
                  label: const Text('View Cities', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
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
            Icon(Icons.public_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            const Text('No countries added yet', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          ]),
        ),
      );

  Widget _errorState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 10),
            const Text('Failed to load countries', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor),
            ),
          ],
        ),
      );
}