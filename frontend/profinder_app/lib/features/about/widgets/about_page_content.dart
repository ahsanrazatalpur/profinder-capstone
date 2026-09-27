// lib/features/about/widgets/about_page_content.dart
//
// Pure rendering of a list of AboutSection into scrollable content. Used by:
//  - AboutScreen (public — fetches the published snapshot)
//  - AdminAboutPreviewScreen (admin — fetches the live draft)
// Keeping this in one place means Preview always shows exactly what Publish
// would push live, with zero risk of the two drifting apart over time.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/theme_context_ext.dart';
import '../../../core/utils/about_icons.dart';
import '../../../shared/widgets/rich_html_text.dart';
import '../models/about_page_model.dart';
import '../../../l10n/generated/app_localizations.dart';

class AboutPageContent extends StatelessWidget {
  final List<AboutSection> sections;

  /// Preview mode (admin) shows a small "Disabled" ribbon on sections that
  /// won't appear publicly, instead of hiding them outright — so the admin
  /// can see everything that exists, not just what's live.
  final bool showDisabledBadge;

  const AboutPageContent({super.key, required this.sections, this.showDisabledBadge = false});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: sections.length,
      itemBuilder: (context, index) => _buildSection(context, sections[index]),
    );
  }

  // ── Safe link launch ─────────────────────────────────────────────────────
  //
  // ✅ FIX: every launchUrl(...) call used to fire-and-forget — if the
  // intent had nowhere to go (e.g. no dialer/mail app, or Android 11+
  // blocking the intent because AndroidManifest.xml is missing a
  // <queries> block for tel/mailto/https), the tap silently did nothing.
  // This checks canLaunchUrl first and surfaces a SnackBar on failure so
  // it's visible instead of a dead tap.
  Future<void> _safeLaunch(BuildContext context, Uri uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
    try {
      final can = await canLaunchUrl(uri);
      if (!can) {
        if (context.mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.aboutLinkNoAppFound(uri.toString())),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return;
      }
      final ok = await launchUrl(uri, mode: mode);
      if (!ok && context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.aboutLinkCouldNotOpen(uri.toString())),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.aboutLinkError(e.toString())),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // ── Section dispatch ─────────────────────────────────────────────────────

  Widget _buildSection(BuildContext context, AboutSection section) {
    Widget body;
    switch (section.sectionType) {
      case 'hero_banner':
        body = _heroBanner(context, section);
        break;
      case 'company_story':
      case 'mission':
      case 'vision':
        body = _textSection(context, section);
        break;
      case 'why_choose_us':
      case 'core_values':
        body = _cardGridSection(context, section);
        break;
      case 'how_it_works':
        body = _stepsSection(context, section);
        break;
      case 'statistics':
        body = _statisticsSection(context, section);
        break;
      case 'team_members':
        body = _teamSection(context, section);
        break;
      case 'investors_partners':
      case 'certifications':
      case 'awards':
        body = _logoRowSection(context, section);
        break;
      case 'contact_info':
        body = _contactInfoSection(context, section);
        break;
      case 'social_media':
        body = _socialMediaSection(context, section);
        break;
      case 'app_info':
        body = _appInfoSection(context, section);
        break;
      case 'legal_links':
        body = _legalLinksSection(context, section);
        break;
      default:
        body = _textSection(context, section);
    }

    if (showDisabledBadge && !section.isEnabled) {
      return Stack(
        children: [
          Opacity(opacity: 0.4, child: body),
          Positioned(
            top: 8,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                AppLocalizations.of(context)!.aboutDisabledBadgeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return body;
  }

  // ── Section layouts ─────────────────────────────────────────────────────

  Widget _sectionPadding(Widget child) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
        child: child,
      );

  Widget _heroBanner(BuildContext context, AboutSection s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.colors.primary, context.colors.primaryDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: s.imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          if (s.imageUrl.isNotEmpty) const SizedBox(height: 20),
          if (s.title.isNotEmpty)
            Text(
              s.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          if (s.subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              s.subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14.5,
                height: 1.4,
              ),
            ),
          ],
          if (s.hasCta) ...[
            const SizedBox(height: 20),
            _ctaButton(context, s, onWhite: true),
          ],
        ],
      ),
    );
  }

  Widget _textSection(BuildContext context, AboutSection s) {
    return _sectionPadding(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ FIX: icon used to sit stacked ABOVE the title in its own row —
          // now icon + title sit inline on one line (icon left, title
          // right), title picked up the accent color, subtitle got a
          // tinted color too instead of plain gray — closer to how
          // feature sections look in polished apps.
          if (s.icon.isNotEmpty || s.title.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (s.icon.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      resolveAboutIcon(s.icon),
                      color: context.colors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (s.title.isNotEmpty)
                  Expanded(
                    child: Text(
                      s.title,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: context.colors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          if (s.subtitle.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              s.subtitle,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.colors.primary.withOpacity(0.7),
              ),
            ),
          ],
          if (s.imageUrl.isNotEmpty) ...[
            const SizedBox(height: 14),
            // ✅ FIX: was BoxFit.contain in a fixed 180px box — for a
            // portrait photo that meant a small centered image with dead
            // space on both sides ("dull"). Now it's a taller, full-width
            // cover crop with bigger rounded corners.
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: CachedNetworkImage(
                  imageUrl: s.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
          if (s.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            RichHtmlText(html: s.description),
          ],
          if (s.hasCta) ...[
            const SizedBox(height: 8),
            _ctaButton(context, s),
          ],
        ],
      ),
    );
  }

  Widget _cardGridSection(BuildContext context, AboutSection s) {
    return _sectionPadding(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(context, s),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: s.items.length,
            itemBuilder: (context, i) => _card(context, s.items[i]),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, AboutSectionItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.divider),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.1)
                : Colors.grey.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              resolveAboutIcon(item.icon),
              color: context.colors.primary,
              size: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
            ),
            maxLines: 2,
          ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                item.description,
                style: TextStyle(
                  fontSize: 11.5,
                  color: context.colors.textSecondary,
                  height: 1.35,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepsSection(BuildContext context, AboutSection s) {
    return _sectionPadding(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(context, s),
          const SizedBox(height: 16),
          ...s.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == s.items.length - 1;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: context.colors.divider,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          if (item.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: context.colors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _statisticsSection(BuildContext context, AboutSection s) {
    return _sectionPadding(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(context, s),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: s.items.map((item) {
              final suffix = item.extraData['suffix']?.toString() ?? '';
              return Container(
                width: (MediaQuery.of(context).size.width - 20 * 2 - 12) / 2,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.colors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '${item.value}$suffix',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: context.colors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _teamSection(BuildContext context, AboutSection s) {
    return _sectionPadding(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(context, s),
          const SizedBox(height: 14),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: s.items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final m = s.items[i];
                final designation = m.extraData['designation']?.toString() ?? '';
                return Container(
                  width: 130,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.colors.divider),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: context.colors.primary.withOpacity(0.1),
                        backgroundImage: m.imageUrl.isNotEmpty
                            ? CachedNetworkImageProvider(m.imageUrl)
                            : null,
                        child: m.imageUrl.isEmpty
                            ? Icon(Icons.person_rounded, color: context.colors.primary)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        m.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      if (designation.isNotEmpty)
                        Text(
                          designation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: context.colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoRowSection(BuildContext context, AboutSection s) {
    return _sectionPadding(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(context, s),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: s.items.map((item) {
              return GestureDetector(
                onTap: item.linkUrl.isNotEmpty
                    ? () => _safeLaunch(context, Uri.parse(item.linkUrl), mode: LaunchMode.externalApplication)
                    : null,
                child: Container(
                  width: 100,
                  height: 100,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.colors.divider),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: item.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          fit: BoxFit.contain,
                        )
                      : Center(
                          child: Text(
                            item.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textPrimary,
                            ),
                          ),
                        ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _contactInfoSection(BuildContext context, AboutSection s) {
    final e = s.extraData;
    final rows = <Widget>[];
    void addRow(IconData icon, String? value, {VoidCallback? onTap}) {
      if (value == null || value.trim().isEmpty) return;
      rows.add(_infoRow(context, icon, value, onTap: onTap, showChevron: onTap != null));
    }
    final phone = e['phone']?.toString();
    final email = e['email']?.toString();
    final address = e['address']?.toString();

    // ✅ FIX: contact rows were plain text before — now tappable, each
    // opening the right app (dialer / mail / maps) instead of doing nothing.
    addRow(Icons.phone_rounded, phone,
        onTap: phone != null && phone.trim().isNotEmpty
            ? () => _safeLaunch(context, Uri(scheme: 'tel', path: phone.trim().replaceAll(RegExp(r'\s+'), '')))
            : null);
    addRow(Icons.email_rounded, email,
        onTap: email != null && email.trim().isNotEmpty
            ? () => _safeLaunch(context, Uri(scheme: 'mailto', path: email.trim()))
            : null);
    addRow(Icons.location_on_rounded, address,
        onTap: address != null && address.trim().isNotEmpty
            ? () => _safeLaunch(
                context,
                Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address.trim())}'),
                mode: LaunchMode.externalApplication,
              )
            : null);
    addRow(Icons.access_time_rounded, e['hours']?.toString()); // not tappable — nothing to open

    if (rows.isEmpty && s.description.isEmpty) return const SizedBox.shrink();
    return _sectionPadding(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(context, s),
          const SizedBox(height: 12),
          if (s.description.isNotEmpty) RichHtmlText(html: s.description),
          ...rows,
        ],
      ),
    );
  }

  Widget _socialMediaSection(BuildContext context, AboutSection s) {
    final platforms = {
      'facebook': Icons.facebook_rounded,
      'instagram': Icons.camera_alt_rounded,
      'twitter': Icons.alternate_email_rounded,
      'linkedin': Icons.business_center_rounded,
      'youtube': Icons.play_circle_fill_rounded,
    };
    final links = <MapEntry<String, String>>[];
    s.extraData.forEach((key, value) {
      if (platforms.containsKey(key) && value != null && value.toString().trim().isNotEmpty) {
        links.add(MapEntry(key, value.toString()));
      }
    });
    if (links.isEmpty) return const SizedBox.shrink();

    return _sectionPadding(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(context, s),
          const SizedBox(height: 12),
          Row(
            children: links.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  onTap: () => _safeLaunch(context, Uri.parse(entry.value), mode: LaunchMode.externalApplication),
                  borderRadius: BorderRadius.circular(24),
                  splashColor: context.colors.primary.withOpacity(0.1),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.colors.primary.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      platforms[entry.key],
                      color: context.colors.primary,
                      size: 20,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _appInfoSection(BuildContext context, AboutSection s) {
    final e = s.extraData;
    final playStore = e['play_store_url']?.toString() ?? '';
    final appStore = e['app_store_url']?.toString() ?? '';
    if (playStore.isEmpty && appStore.isEmpty && s.description.isEmpty) return const SizedBox.shrink();

    return _sectionPadding(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(context, s),
          if (s.description.isNotEmpty) ...[const SizedBox(height: 8), RichHtmlText(html: s.description)],
          const SizedBox(height: 12),
          Row(
            children: [
              if (playStore.isNotEmpty)
                Expanded(child: _storeButton(context, AppLocalizations.of(context)!.aboutGooglePlayLabel, Icons.shop_rounded, playStore)),
              if (playStore.isNotEmpty && appStore.isNotEmpty) const SizedBox(width: 10),
              if (appStore.isNotEmpty)
                Expanded(child: _storeButton(context, AppLocalizations.of(context)!.aboutAppStoreLabel, Icons.apple_rounded, appStore)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _storeButton(BuildContext context, String label, IconData icon, String url) {
    return OutlinedButton.icon(
      onPressed: () => _safeLaunch(context, Uri.parse(url), mode: LaunchMode.externalApplication),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: context.colors.primary.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _legalLinksSection(BuildContext context, AboutSection s) {
    final links = (s.extraData['links'] as List? ?? [])
        .whereType<Map>()
        .map((m) => MapEntry(m['label']?.toString() ?? '', m['url']?.toString() ?? ''))
        .where((e) => e.key.isNotEmpty && e.value.isNotEmpty)
        .toList();
    if (links.isEmpty) return const SizedBox.shrink();

    return _sectionPadding(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(context, s),
          const SizedBox(height: 8),
          ...links.map((e) => _infoRow(
                context,
                Icons.description_outlined,
                e.key,
                onTap: () => _safeLaunch(context, Uri.parse(e.value), mode: LaunchMode.externalApplication),
                showChevron: true,
              )),
        ],
      ),
    );
  }

  // ── Shared small pieces ─────────────────────────────────────────────────

  Widget _sectionHeading(BuildContext context, AboutSection s) {
    if (s.title.isEmpty && s.subtitle.isEmpty && s.imageUrl.isEmpty && s.description.isEmpty && s.icon.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ FIX: same icon-inline-with-title + colored heading treatment
        // as _textSection, so every section type looks consistent —
        // this heading previously never even rendered the section icon.
        if (s.icon.isNotEmpty || s.title.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (s.icon.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    resolveAboutIcon(s.icon),
                    color: context.colors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (s.title.isNotEmpty)
                Expanded(
                  child: Text(
                    s.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.colors.primary,
                    ),
                  ),
                ),
            ],
          ),
        if (s.subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            s.subtitle,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: context.colors.primary.withOpacity(0.7),
            ),
          ),
        ],
        // ✅ FIX: these two were being filled in by the admin (Image /
        // Rich Description fields on the section editor) but never
        // actually rendered anywhere for collection-type sections
        // (Team, Awards, Why Choose Us, etc.) — this heading is shared
        // by all of them, so adding it here fixes every one at once.
        if (s.imageUrl.isNotEmpty) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: CachedNetworkImage(
                imageUrl: s.imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
        if (s.description.isNotEmpty) ...[
          const SizedBox(height: 10),
          RichHtmlText(html: s.description),
        ],
      ],
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text, {VoidCallback? onTap, bool showChevron = false}) {
    // ✅ FIX: tappable rows (phone/email/address/legal links) looked like
    // plain black text, so nobody could tell they were clickable. Now
    // anything with an onTap gets the accent color + underline like a link.
    final isLink = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      splashColor: context.colors.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: context.colors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: isLink ? context.colors.primary : context.colors.textPrimary,
                  fontWeight: isLink ? FontWeight.w600 : FontWeight.normal,
                  decoration: isLink ? TextDecoration.underline : TextDecoration.none,
                  decorationColor: context.colors.primary.withOpacity(0.4),
                ),
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: context.colors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _ctaButton(BuildContext context, AboutSection s, {bool onWhite = false}) {
    void onPressed() {
      final url = s.ctaUrl.trim();
      if (url.isEmpty) return;
      if (url.startsWith('http')) {
        _safeLaunch(context, Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        Navigator.pushNamed(context, url);
      }
    }

    if (s.ctaStyle == 'link') {
      return TextButton(
        onPressed: onPressed,
        child: Text(
          s.ctaText,
          style: TextStyle(
            color: onWhite ? Colors.white : context.colors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    if (s.ctaStyle == 'secondary' || onWhite) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: onWhite ? Colors.white : context.colors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          s.ctaText,
          style: TextStyle(
            color: onWhite ? Colors.white : context.colors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: context.colors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      child: Text(
        s.ctaText,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}