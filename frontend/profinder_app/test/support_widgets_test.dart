// Widget tests for the shared Help & Support UI foundation (Part 2).
// Checks: renders in light + dark, English + Urdu (RTL) + Arabic (RTL),
// narrow width with 2x text scale (no overflow), tap / clear / retry behavior.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profinder_app/core/theme/app_theme.dart';
import 'package:profinder_app/core/utils/support_icons.dart';
import 'package:profinder_app/features/support/widgets/support_category_tile.dart';
import 'package:profinder_app/features/support/widgets/support_search_field.dart';
import 'package:profinder_app/features/support/widgets/support_section_heading.dart';
import 'package:profinder_app/features/support/widgets/support_state_views.dart';
import 'package:profinder_app/features/support/widgets/support_status_chip.dart';
import 'package:profinder_app/l10n/generated/app_localizations.dart';
import 'package:profinder_app/l10n/generated/app_localizations_en.dart';

Widget _host(
  Widget child, {
  required ThemeData theme,
  Locale locale = const Locale('en'),
  double textScale = 1.0,
}) {
  return MaterialApp(
    theme: theme,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, c) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: c!,
    ),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

Widget _everything({VoidCallback? onTap}) {
  return Column(
    children: [
      const SupportSectionHeading(text: 'Popular topics', icon: Icons.help_outline_rounded),
      const SupportSearchField(hintText: 'Search help'),
      SupportCategoryTile(
        icon: resolveSupportIcon('booking'),
        title: 'Bookings and cancellations with a very long title that must wrap',
        subtitle: 'How to book, change or cancel a booking and get a refund',
        onTap: onTap ?? () {},
      ),
      const Wrap(spacing: 8, runSpacing: 8, children: [
        SupportStatusChip(label: 'Open', icon: Icons.schedule_rounded, tone: SupportChipTone.info),
        SupportStatusChip(label: 'Resolved', icon: Icons.check_circle_rounded, tone: SupportChipTone.success),
        SupportStatusChip(label: 'Waiting', icon: Icons.hourglass_top_rounded, tone: SupportChipTone.warning),
        SupportStatusChip(label: 'Closed', icon: Icons.lock_rounded),
      ]),
      const SizedBox(height: 200, child: SupportEmptyState(title: 'Nothing here', message: 'Try again later')),
      SizedBox(height: 220, child: SupportErrorState(onRetry: () {})),
      const SizedBox(height: 120, child: SupportLoadingState()),
    ],
  );
}

void main() {
  group('helpers', () {
    test('detectTextDirection follows the first strong character', () {
      expect(detectTextDirection(''), isNull);
      expect(detectTextDirection('123 ...'), isNull);
      expect(detectTextDirection('booking'), TextDirection.ltr);
      expect(detectTextDirection('بکنگ'), TextDirection.rtl);
      expect(detectTextDirection('حجز'), TextDirection.rtl);
      expect(detectTextDirection('12 بکنگ'), TextDirection.rtl);
      expect(detectTextDirection('बुकिंग'), TextDirection.ltr);
    });

    test('resolveSupportIcon falls back for unknown / empty keys', () {
      expect(resolveSupportIcon('payment'), Icons.payments_rounded);
      expect(resolveSupportIcon('  PRIVACY '), Icons.privacy_tip_rounded);
      expect(resolveSupportIcon(null), Icons.article_rounded);
      expect(resolveSupportIcon('does-not-exist'), Icons.article_rounded);
    });
  });

  for (final themeName in ['light', 'dark']) {
    for (final code in ['en', 'ur', 'ar']) {
      testWidgets('renders without errors: $themeName / $code', (tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(360, 900);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_host(
          _everything(),
          theme: themeName == 'dark' ? AppTheme.darkTheme : AppTheme.lightTheme,
          locale: Locale(code),
        ));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byType(SupportCategoryTile), findsOneWidget);
        final expected = code == 'en' ? TextDirection.ltr : TextDirection.rtl;
        expect(
          Directionality.of(tester.element(find.byType(SupportCategoryTile))),
          expected,
        );
      });
    }
  }

  testWidgets('narrow screen + 2x text scale does not overflow', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(320, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(
      _everything(),
      theme: AppTheme.lightTheme,
      textScale: 2.0,
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('category tile is tappable', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(
      SupportCategoryTile(icon: Icons.person_rounded, title: 'Account', onTap: () => taps++),
      theme: AppTheme.lightTheme,
    ));
    await tester.tap(find.text('Account'));
    expect(taps, 1);
  });

  testWidgets('search field shows a clear button only when it has text', (tester) async {
    final changes = <String>[];
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_host(
      SupportSearchField(hintText: 'Search help', controller: controller, onChanged: changes.add),
      theme: AppTheme.darkTheme,
    ));
    final clear = AppLocalizationsEn().searchClear;
    expect(find.byTooltip(clear), findsNothing);

    await tester.enterText(find.byType(TextField), 'refund');
    await tester.pump();
    expect(find.byTooltip(clear), findsOneWidget);

    await tester.tap(find.byTooltip(clear));
    await tester.pump();
    expect(controller.text, isEmpty);
    expect(changes.last, '');
    expect(find.byTooltip(clear), findsNothing);
  });

  testWidgets('error state calls retry', (tester) async {
    var retries = 0;
    await tester.pumpWidget(_host(
      SizedBox(height: 300, child: SupportErrorState(onRetry: () => retries++)),
      theme: AppTheme.lightTheme,
    ));
    await tester.tap(find.text(AppLocalizationsEn().retryCta));
    expect(retries, 1);
  });
}