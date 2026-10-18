// lib/core/theme/theme_mode_picker.dart
//
// One shared "Theme" picker (Light / Dark / System default) used by every
// place that used to have a dark-mode switch.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import 'theme_provider.dart';

String themeModeLabel(AppLocalizations t, ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return t.darkModeOffLabel; // "Light Mode" (existing, already translated)
    case ThemeMode.dark:
      return t.darkModeOnLabel; // "Dark Mode"
    case ThemeMode.system:
      return t.themeModeSystem;
  }
}

IconData themeModeIcon(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return Icons.light_mode_outlined;
    case ThemeMode.dark:
      return Icons.dark_mode_outlined;
    case ThemeMode.system:
      return Icons.brightness_auto_outlined;
  }
}

Future<void> showThemeModeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) =>
        const SafeArea(child: SingleChildScrollView(child: _ThemeModeSheet())),
  );
}

class _ThemeModeSheet extends StatelessWidget {
  const _ThemeModeSheet();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final provider = context.watch<ThemeProvider>();
    final scheme = Theme.of(context).colorScheme;

    Widget option(ThemeMode mode, {String? subtitle}) {
      final selected = provider.themeMode == mode;
      return ListTile(
        leading: Icon(themeModeIcon(mode)),
        title: Text(themeModeLabel(t, mode)),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: selected
            ? Icon(Icons.check_rounded, color: scheme.primary)
            : null,
        selected: selected,
        onTap: () {
          context.read<ThemeProvider>().setThemeMode(mode);
          Navigator.pop(context);
        },
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 8),
          child: Semantics(
            header: true,
            child: Text(
              t.themeModeTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        option(ThemeMode.light),
        option(ThemeMode.dark),
        option(ThemeMode.system, subtitle: t.themeModeSystemHint),
        const SizedBox(height: 8),
      ],
    );
  }
}
