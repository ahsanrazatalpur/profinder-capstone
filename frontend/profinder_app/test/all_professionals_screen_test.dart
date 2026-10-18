// test/all_professionals_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profinder_app/features/home/screens/all_professionals_screen.dart';
import 'package:profinder_app/l10n/generated/app_localizations.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: child,
  );
}

void main() {
  final fakePros = [
    {
      'id': '1',
      'name': 'John Doe',
      'profession': 'Electrician',
      'hourly_rate': '50',
      'average_rating': '4.8',
      'reviews_count': 10,
      'experience_years': 5,
      'is_available': true,
      'is_verified': true,
    },
    {
      'id': '2',
      'name': 'Jane Smith',
      'profession': 'Doctor',
      'hourly_rate': '100',
      'average_rating': '4.9',
      'reviews_count': 25,
      'experience_years': 8,
      'is_available': false,
      'is_verified': true,
    },
  ];

  testWidgets('AllProfessionalsScreen renders category section and filters without throwing', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        AllProfessionalsScreen(
          title: 'Electricians',
          professionals: fakePros,
          section: ProSection.category,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Electricians'), findsOneWidget);
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Jane Smith'), findsOneWidget);

    // Filter by Available Now
    final availableChip = find.text('Available Now');
    expect(availableChip, findsOneWidget);

    await tester.tap(availableChip);
    await tester.pumpAndSettle();

    // Jane Smith is not available (is_available == false), so only John Doe remains
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Jane Smith'), findsNothing);
  });

  testWidgets('AllProfessionalsScreen renders empty state when no professionals found', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AllProfessionalsScreen(
          title: 'Empty Category',
          professionals: [],
          section: ProSection.category,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('No professionals found'), findsOneWidget);
    expect(find.text('Go Back'), findsOneWidget);
  });

  testWidgets('AllProfessionalsScreen renders all section types safely', (tester) async {
    for (final section in ProSection.values) {
      await tester.pumpWidget(
        _wrap(
          AllProfessionalsScreen(
            title: section.name,
            professionals: fakePros,
            section: section,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });
}
