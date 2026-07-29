// lib/features/profile/screens/saved_professionals_screen.dart
//
// SAVED PROFESSIONALS — reads from the on-device FavoritesStore (see
// services/favorites_store.dart for why this is local, not server-synced).

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/favorites_store.dart';
import '../../search/screens/professional_detail_screen.dart';
import '../../bookings/screens/booking_screen.dart';
import '../../../core/theme/theme_context_ext.dart';

class SavedProfessionalsScreen extends StatefulWidget {
  const SavedProfessionalsScreen({super.key});

  @override
  State<SavedProfessionalsScreen> createState() => _SavedProfessionalsScreenState();
}

class _SavedProfessionalsScreenState extends State<SavedProfessionalsScreen> {
  final FavoritesStore _store = FavoritesStore();
  List<Map<String, dynamic>> _favorites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final favs = await _store.getAll();
    if (!mounted) return;
    setState(() {
      _favorites = favs;
      _loading   = false;
    });
  }

  Future<void> _remove(String id) async {
    await _store.remove(id);
    _load();
  }

  double _num(dynamic v) => v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Saved Professionals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF374151)), onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? _empty()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favorites.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _card(_favorites[i]),
                ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border_rounded, size: 56, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 12),
            const Text('No saved professionals yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 4),
            const Text('Tap the heart on any professional to save them here', style: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)), textAlign: TextAlign.center),
          ],
        ),
      );

  Widget _card(Map<String, dynamic> pro) {
    final id         = pro['id']?.toString() ?? '';
    final name       = pro['name']?.toString() ?? 'Professional';
    final profession = pro['category_name']?.toString() ?? pro['specialization']?.toString() ?? '';
    final photo      = AppHelpers.getFullImageUrl(pro['photo_url']?.toString());
    final rating     = _num(pro['average_rating']);
    final price      = _num(pro['hourly_rate']);
    final isVerified = pro['is_verified'] == true;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfessionalDetailScreen(professional: pro))),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 64, height: 64, color: context.colors.primaryLight,
                child: photo.isNotEmpty
                    ? Image.network(photo, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(AppHelpers.getInitials(name), style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold))))
                    : Center(child: Text(AppHelpers.getInitials(name), style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold))),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                  if (isVerified) ...[const SizedBox(width: 4), Icon(Icons.verified_rounded, color: context.colors.accent, size: 15)],
                ]),
                if (profession.isNotEmpty)
                  Text(profession, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: context.colors.primary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                  Text(' ${rating.toStringAsFixed(1)}  •  \$${price.toStringAsFixed(0)}/hr',
                      style: TextStyle(fontSize: 11.5, color: context.colors.textSecondary)),
                ]),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.favorite_rounded, color: AppColors.error, size: 20),
                onPressed: () => _remove(id),
                tooltip: 'Remove from saved',
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 12)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(professional: pro))),
                child: const Text('Book', style: TextStyle(fontSize: 11.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}