// lib/features/profile/screens/saved_professionals_screen.dart
//
// SAVED PROFESSIONALS — reads from the on-device FavoritesStore (see
// services/favorites_store.dart for why this is local, not server-synced).

import 'package:flutter/material.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/favorites_store.dart';
import '../../search/screens/professional_detail_screen.dart';
import '../../bookings/screens/booking_screen.dart';
import '../../../l10n/generated/app_localizations.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width > 600;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: UniversalAppBar(
        title: AppLocalizations.of(context)!.savedProfessionalsTitle,
        icon: Icons.bookmark_rounded,
      ),
      body: _loading
          ? Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: AppColors.customerColor,
                  strokeWidth: 3,
                ),
              ),
            )
          : _favorites.isEmpty
              ? _empty(isDark)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.customerColor,
                  child: ListView.separated(
                    padding: EdgeInsets.all(isTablet ? 20 : 16),
                    itemCount: _favorites.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _card(_favorites[i], isDark, isTablet),
                  ),
                ),
    );
  }

  Widget _empty(bool isDark) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 40,
                color: isDark
                    ? Colors.white.withOpacity(0.3)
                    : const Color(0xFFD1D5DB),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              AppLocalizations.of(context)!.savedProfessionalsEmptyTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)!.savedProfessionalsEmptySubtitle,
              style: TextStyle(
                fontSize: 13,
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _card(Map<String, dynamic> pro, bool isDark, bool isTablet) {
    final id         = pro['id']?.toString() ?? '';
    final name       = pro['name']?.toString() ?? AppLocalizations.of(context)!.professionalDefaultName;
    final profession = pro['category_name']?.toString() ?? pro['specialization']?.toString() ?? '';
    final photo      = AppHelpers.getFullImageUrl(pro['photo_url']?.toString());
    final rating     = _num(pro['average_rating']);
    final price      = _num(pro['hourly_rate']);
    final isVerified = pro['is_verified'] == true;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.12)
                : Colors.grey.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Avatar ──────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfessionalDetailScreen(professional: pro),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: isTablet ? 72 : 64,
                height: isTablet ? 72 : 64,
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : context.colors.primaryLight,
                child: photo.isNotEmpty
                    ? Image.network(
                        photo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            AppHelpers.getInitials(name),
                            style: TextStyle(
                              color: context.colors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: isTablet ? 18 : 16,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          AppHelpers.getInitials(name),
                          style: TextStyle(
                            color: context.colors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: isTablet ? 18 : 16,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ── Info ──────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isTablet ? 15.0 : 14.0,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textPrimary,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified_rounded,
                        color: context.colors.accent,
                        size: isTablet ? 17 : 15,
                      ),
                    ],
                  ],
                ),
                if (profession.isNotEmpty)
                  Text(
                    profession,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isTablet ? 12.0 : 11.5,
                      color: AppColors.customerColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: const Color(0xFFF59E0B),
                      size: isTablet ? 15 : 14,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      ' ${rating.toStringAsFixed(1)}  •  \$${price.toStringAsFixed(0)}/hr',
                      style: TextStyle(
                        fontSize: isTablet ? 12.0 : 11.5,
                        color: context.colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Actions ──────────────────────────────────
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _remove(id),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: AppColors.error,
                      size: isTablet ? 22 : 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 16 : 12,
                    vertical: 4,
                  ),
                  backgroundColor: AppColors.customerColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingScreen(professional: pro),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.bookCta,
                  style: TextStyle(
                    fontSize: isTablet ? 12.0 : 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}