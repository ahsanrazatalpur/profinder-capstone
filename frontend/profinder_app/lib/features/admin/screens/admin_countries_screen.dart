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
import '../../../shared/widgets/universal_app_bar.dart';

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
      _showSnack('Failed to update.');
    }
  }

  Future<void> _delete(dynamic c) async {
    try {
      await _api.delete('/admin-panel/countries/${c['id']}/');
      _load();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to delete.');
    }
  }

  // Confirms destructive delete before hitting the API — UI-only guard,
  // the underlying _delete() call and its error handling are unchanged.
  Future<void> _confirmDelete(dynamic c) async {
    // ✅ FIX: showDialog() called synchronously from a button's onPressed,
    // while the grid behind it still has many hover-tracking MouseRegion
    // cards mounted, crashes Flutter's MouseTracker on web/desktop
    // ("BoxConstraints forces an infinite width" + a flood of cascading
    // "Assertion failed" errors in box.dart / mouse_tracker.dart — the
    // dialog then never renders, just the dark barrier). Waiting one frame
    // lets the click's pointer-up event fully settle before the new route
    // (and its own MouseRegions) gets pushed, which avoids the conflict.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _StyledDialog(
        icon: Icons.delete_outline_rounded,
        iconColor: AppColors.error,
        title: 'Delete "${c['name']}"?',
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) _delete(c);
  }

  void _showSnack(String message, {IconData icon = Icons.error_outline_rounded}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ]),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  void _addDialog() async {
    // ✅ FIX: see _confirmDelete above — same MouseTracker crash fix.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => _StyledDialog(
        icon: Icons.add_road_rounded,
        iconColor: AppColors.adminColor,
        title: 'Add Country',
        content: _StyledTextField(controller: nameCtrl, hintText: 'Country name', autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(dialogContext);
              try {
                await _api.post('/admin-panel/countries/', {'name': nameCtrl.text.trim()});
                _load();
              } catch (e) {
                if (!mounted) return;
                _showSnack('Failed to add — may already exist.');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _mergeDialog(dynamic country) async {
    // ✅ FIX: see _confirmDelete above — same MouseTracker crash fix.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final variantsCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => _StyledDialog(
        icon: Icons.merge_type_rounded,
        iconColor: AppColors.adminColor,
        title: 'Merge into "${country['name']}"',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter typo/variant spellings found in user profiles, comma-separated (e.g. pakistan, Pakistn).',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF6B7280), height: 1.4),
            ),
            const SizedBox(height: 12),
            _StyledTextField(controller: variantsCtrl, hintText: 'variant1, variant2, ...', autofocus: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () async {
              final variants = variantsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
              if (variants.isEmpty) return;
              Navigator.pop(dialogContext);
              try {
                final r = await _api.post('/admin-panel/countries/${country['id']}/merge/', {'variants': variants});
                if (!mounted) return;
                _showSnack(r.data['message']?.toString() ?? 'Merged.', icon: Icons.check_circle_outline_rounded);
              } catch (e) {
                if (!mounted) return;
                _showSnack('Merge failed.');
              }
            },
            child: const Text('Merge'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _countries.where((c) => c['status'] == 'active').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: UniversalAppBar(
        title: 'Countries',
        subtitle: '$activeCount active',
        icon: Icons.public_rounded,
        showBack: false,
      ),
      floatingActionButton: _EntranceScale(
        child: FloatingActionButton.extended(
          // Unique tag prevents "multiple heroes share the same tag"
          // crashes when navigating to/from admin_cities_screen.dart
          // (View Cities), which also has a FAB — without this, both
          // FABs share Flutter's default Hero tag during the route
          // transition, and the crash breaks the whole render tree
          // (blank list, unresponsive taps, stuck dialog barrier).
          heroTag: 'admin_countries_fab',
          backgroundColor: AppColors.adminColor,
          elevation: 3,
          onPressed: _addDialog,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Add Country', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            // Breakpoints: mobile single column, tablet two, desktop three+.
            final crossAxisCount = width >= 1100 ? 3 : (width >= 700 ? 2 : 1);

            return Column(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: _loading
                        ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator(color: AppColors.adminColor))
                        : _error != null
                            ? _ErrorState(key: const ValueKey('error'), onRetry: _load)
                            : _countries.isEmpty
                                ? const _EmptyState(key: ValueKey('empty'))
                                : RefreshIndicator(
                                    key: const ValueKey('content'),
                                    onRefresh: _load,
                                    color: AppColors.adminColor,
                                    child: Center(
                                      child: ConstrainedBox(
                                        // Keeps content readable on very wide desktop windows
                                        // instead of stretching cards edge to edge.
                                        constraints: const BoxConstraints(maxWidth: 1400),
                                        child: crossAxisCount == 1
                                            ? ListView.builder(
                                                padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
                                                // Fixed extent (matches the grid's mainAxisExtent) so
                                                // each _CountryCard's Column gets a bounded height —
                                                // without this, the card's Spacer() throws on every
                                                // frame because ListView gives unbounded height,
                                                // which was breaking layout AND hit-testing (taps)
                                                // for the whole screen, including the FAB.
                                                itemExtent: 196,
                                                itemCount: _countries.length,
                                                itemBuilder: (_, i) {
                                                  final c = _countries[i];
                                                  return _AnimatedListEntry(
                                                    // Keyed by the country's own id (not its list
                                                    // position) so Flutter never hands an in-flight
                                                    // hover/tooltip animation from one row to a
                                                    // different country after a toggle/delete/merge
                                                    // reshuffles the list — that mismatch is what was
                                                    // throwing "multiple tickers were created".
                                                    itemKey: c['id'],
                                                    index: i,
                                                    child: _CountryCard(
                                                      key: ValueKey('country_${c['id']}'),
                                                      country: c,
                                                      onToggle: _toggleStatus,
                                                      onMerge: _mergeDialog,
                                                      onDelete: _confirmDelete,
                                                    ),
                                                  );
                                                },
                                              )
                                            : GridView.builder(
                                                padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: crossAxisCount,
                                                  crossAxisSpacing: 14,
                                                  mainAxisSpacing: 14,
                                                  mainAxisExtent: 196,
                                                ),
                                                itemCount: _countries.length,
                                                itemBuilder: (_, i) {
                                                  final c = _countries[i];
                                                  return _AnimatedListEntry(
                                                    itemKey: c['id'],
                                                    index: i,
                                                    child: _CountryCard(
                                                      key: ValueKey('country_${c['id']}'),
                                                      country: c,
                                                      onToggle: _toggleStatus,
                                                      onMerge: _mergeDialog,
                                                      onDelete: _confirmDelete,
                                                    ),
                                                  );
                                                },
                                              ),
                                      ),
                                    ),
                                  ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A single country record card. Presentation only — every callback
/// (toggle, merge, delete, view-cities navigation) forwards straight to
/// the parent's existing handlers.
class _CountryCard extends StatefulWidget {
  final dynamic country;
  final ValueChanged<dynamic> onToggle;
  final ValueChanged<dynamic> onMerge;
  final ValueChanged<dynamic> onDelete;

  const _CountryCard({
    super.key,
    required this.country,
    required this.onToggle,
    required this.onMerge,
    required this.onDelete,
  });

  @override
  State<_CountryCard> createState() => _CountryCardState();
}

class _CountryCardState extends State<_CountryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.country;
    final isActive = c['status'] == 'active';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        transform: _hovered ? (Matrix4.identity()..translate(0.0, -2.0)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _hovered ? AppColors.adminColor.withOpacity(0.35) : const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: _hovered ? Colors.black.withOpacity(0.08) : Colors.black.withOpacity(0.03),
              blurRadius: _hovered ? 16 : 6,
              offset: Offset(0, _hovered ? 6 : 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Country flag emoji rendered from the country name via
                // Unicode regional indicator symbols — no asset or package
                // needed. Falls back to a generic globe icon if the name
                // can't be mapped to an ISO country code.
                _CountryFlag(name: c['name']?.toString() ?? '', size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    c['name']?.toString() ?? '',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                _StatusSwitch(isActive: isActive, onChanged: (_) => widget.onToggle(c)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _StatChip(icon: Icons.people_outline_rounded, label: '${c['user_count']} users'),
                _StatChip(icon: Icons.work_outline_rounded, label: '${c['professional_count']} pros'),
                _StatChip(icon: Icons.location_city_rounded, label: '${c['city_count']} cities'),
              ],
            ),
            const Spacer(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _HoverOutlinedButton(
                    icon: Icons.location_city_rounded,
                    label: 'View Cities',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AdminCitiesScreen(country: c)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HoverOutlinedButton(
                    icon: Icons.merge_type_rounded,
                    label: 'Merge',
                    onPressed: () => widget.onMerge(c),
                  ),
                ),
                const SizedBox(width: 8),
                _HoverIconButton(
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.error,
                  background: AppColors.error.withOpacity(0.08),
                  tooltip: 'Delete',
                  onPressed: () => widget.onDelete(c),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders the country's flag as an emoji glyph derived from its name.
///
/// Uses Unicode regional indicator symbols (U+1F1E6–U+1F1FF) which every
/// modern platform renders as a flag — no image assets, no extra package,
/// and no network calls. Names that don't match a known country fall back
/// to a neutral globe icon so the layout never breaks.
class _CountryFlag extends StatelessWidget {
  final String name;
  final double size;
  const _CountryFlag({required this.name, this.size = 24});

  /// Maps common country names (and a few common alternate spellings) to
  /// their ISO 3166-1 alpha-2 code. Only the names actually likely to
  /// appear in this admin list are included; anything else falls back to
  /// the globe icon rather than showing a wrong flag.
  static const Map<String, String> _isoByName = {
    'afghanistan': 'AF',
    'albania': 'AL',
    'algeria': 'DZ',
    'argentina': 'AR',
    'australia': 'AU',
    'austria': 'AT',
    'bahrain': 'BH',
    'bangladesh': 'BD',
    'belgium': 'BE',
    'brazil': 'BR',
    'canada': 'CA',
    'china': 'CN',
    'denmark': 'DK',
    'egypt': 'EG',
    'finland': 'FI',
    'france': 'FR',
    'germany': 'DE',
    'greece': 'GR',
    'india': 'IN',
    'indonesia': 'ID',
    'iran': 'IR',
    'iraq': 'IQ',
    'ireland': 'IE',
    'italy': 'IT',
    'japan': 'JP',
    'jordan': 'JO',
    'kenya': 'KE',
    'kuwait': 'KW',
    'lebanon': 'LB',
    'malaysia': 'MY',
    'maldives': 'MV',
    'mexico': 'MX',
    'morocco': 'MA',
    'nepal': 'NP',
    'netherlands': 'NL',
    'new zealand': 'NZ',
    'nigeria': 'NG',
    'norway': 'NO',
    'oman': 'OM',
    'pakistan': 'PK',
    'palestine': 'PS',
    'philippines': 'PH',
    'poland': 'PL',
    'portugal': 'PT',
    'qatar': 'QA',
    'russia': 'RU',
    'saudi arabia': 'SA',
    'singapore': 'SG',
    'south africa': 'ZA',
    'south korea': 'KR',
    'spain': 'ES',
    'sri lanka': 'LK',
    'sudan': 'SD',
    'sweden': 'SE',
    'switzerland': 'CH',
    'syria': 'SY',
    'tanzania': 'TZ',
    'thailand': 'TH',
    'tunisia': 'TN',
    'turkey': 'TR',
    'türkiye': 'TR',
    'uganda': 'UG',
    'ukraine': 'UA',
    'united arab emirates': 'AE',
    'united kingdom': 'GB',
    'united states': 'US',
    'usa': 'US',
    'uk': 'GB',
    'uae': 'AE',
    'vietnam': 'VN',
    'yemen': 'YE',
    'zimbabwe': 'ZW',
  };

  /// Converts a 2-letter ISO code to its flag emoji by offsetting each
  /// letter into the Regional Indicator Symbol block (0x1F1E6 + letter).
  String _flagEmoji(String isoCode) {
    const int base = 0x1F1E6;
    final upper = isoCode.toUpperCase();
    if (upper.length != 2) return '';
    return String.fromCharCodes(
      upper.codeUnits.map((c) => base + (c - 0x41)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iso = _isoByName[name.trim().toLowerCase()];
    final emoji = iso != null ? _flagEmoji(iso) : '';

    // Fallback: neutral globe icon when no ISO mapping exists, so cards
    // for custom/unknown country entries still look intentional.
    if (emoji.isEmpty) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Icon(Icons.public_rounded, size: size * 0.65, color: const Color(0xFF9CA3AF)),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: size * 0.85, height: 1.0),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Active/coming-soon toggle with a status label so the switch state is
/// legible at a glance, not just color-coded.
class _StatusSwitch extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;
  const _StatusSwitch({required this.isActive, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: 0.85,
          child: Switch(value: isActive, activeColor: context.colors.accent, onChanged: onChanged),
        ),
        Text(
          isActive ? 'Active' : 'Coming soon',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: isActive ? context.colors.accent : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF6B7280)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

/// Outlined action button ("View Cities" / "Merge") with a hover tint on
/// desktop/web; falls back to standard press feedback on touch devices.
class _HoverOutlinedButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _HoverOutlinedButton({required this.icon, required this.label, required this.onPressed});

  @override
  State<_HoverOutlinedButton> createState() => _HoverOutlinedButtonState();
}

class _HoverOutlinedButtonState extends State<_HoverOutlinedButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: SizedBox(
        height: 40,
        child: OutlinedButton.icon(
          onPressed: widget.onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.adminColor,
            backgroundColor: _hovered ? AppColors.adminColor.withOpacity(0.06) : Colors.transparent,
            side: BorderSide(color: AppColors.adminColor.withOpacity(_hovered ? 0.6 : 0.35)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
          icon: Icon(widget.icon, size: 14),
          label: Text(widget.label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

/// Circular icon button (delete) with a min 40x40 tap target and a hover
/// background on desktop/web.
class _HoverIconButton extends StatefulWidget {
  final IconData icon;
  final Color? color;
  final Color? background;
  final VoidCallback onPressed;
  final String? tooltip;
  const _HoverIconButton({required this.icon, required this.onPressed, this.color, this.background, this.tooltip});

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? Colors.white;
    final baseBg = widget.background ?? Colors.white.withOpacity(0.16);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _hovered ? baseBg.withOpacity((baseBg.opacity + 0.10).clamp(0.0, 1.0)) : baseBg,
          borderRadius: BorderRadius.circular(11),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          tooltip: widget.tooltip,
          icon: Icon(widget.icon, size: 18, color: baseColor),
          onPressed: widget.onPressed,
        ),
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool autofocus;
  const _StyledTextField({required this.controller, required this.hintText, this.autofocus = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.adminColor, width: 1.4),
        ),
      ),
    );
  }
}

/// Shared dialog chrome (icon + title + rounded card) so Add/Merge/Delete
/// dialogs look consistent; the actions/content passed in are unchanged.
class _StyledDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget content;
  final List<Widget> actions;
  const _StyledDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      // This dialog's text/fill colors (e.g. Color(0xFF111827) titles on a
      // Color(0xFFF9FAFB) field) are hardcoded for a light surface. Material
      // 3's Dialog defaults its background to Theme.of(context).colorScheme
      // .surface, which is a dark near-black slate in this app's dark theme
      // — that combination rendered the dialog as an unreadable black box
      // (dark text on a dark background) in dark mode, making Add Country /
      // Merge / Delete look like they silently do nothing. Forcing white
      // here keeps it legible regardless of the active app theme — same
      // fix as admin_cities_screen.dart's _StyledDialog.
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 14),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
              const SizedBox(height: 14),
              content,
              const SizedBox(height: 20),
              OverflowBar(alignment: MainAxisAlignment.end, children: actions),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 90),
          child: Center(
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), shape: BoxShape.circle),
                child: Icon(Icons.public_rounded, size: 44, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 14),
              const Text('No countries added yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), shape: BoxShape.circle),
            child: const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.error),
          ),
          const SizedBox(height: 14),
          const Text('Failed to load countries', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

/// One-shot scale-in used for the FAB so it doesn't just pop into place.
class _EntranceScale extends StatelessWidget {
  final Widget child;
  const _EntranceScale({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.scale(scale: value, child: child),
      child: child,
    );
  }
}

/// Staggered fade + slide-up entrance for list/grid items. Purely visual —
/// runs once per build using the item's index to offset its start delay,
/// so the list feels populated rather than static.
class _AnimatedListEntry extends StatelessWidget {
  final int index;
  final Widget child;
  // Stable identity for this row (the country's id). Falls back to index
  // only if no id is available, so old callers don't break.
  final dynamic itemKey;
  const _AnimatedListEntry({required this.index, required this.child, this.itemKey});

  @override
  Widget build(BuildContext context) {
    final delay = (index.clamp(0, 12)) * 35;
    return TweenAnimationBuilder<double>(
      key: ValueKey('entry_${itemKey ?? index}'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 320 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, (1 - value) * 14), child: child),
      ),
      child: child,
    );
  }
}