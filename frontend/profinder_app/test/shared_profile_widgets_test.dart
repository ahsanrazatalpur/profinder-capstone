// test/shared_profile_widgets_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profinder_app/core/theme/app_colors.dart';
import 'package:profinder_app/shared/widgets/app_empty_state.dart';
import 'package:profinder_app/shared/widgets/app_error_state.dart';
import 'package:profinder_app/shared/widgets/profile_menu_tile.dart';
import 'package:profinder_app/shared/widgets/profile_quick_action_card.dart';
import 'package:profinder_app/shared/widgets/profile_section_header.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('ProfileMenuTile', () {
    testWidgets('renders title, subtitle and custom icon', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProfileMenuTile(
            icon: Icons.settings,
            iconColor: AppColors.primary,
            title: 'Account Settings',
            subtitle: 'Manage your preferences',
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Account Settings'), findsOneWidget);
      expect(find.text('Manage your preferences'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('handles tap event when not locked', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          ProfileMenuTile(
            icon: Icons.star,
            iconColor: AppColors.starGold,
            title: 'Reviews',
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Reviews'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('does not trigger tap event when locked', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          ProfileMenuTile(
            icon: Icons.lock,
            iconColor: AppColors.slate500,
            title: 'Premium Features',
            isLocked: true,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Premium Features'));
      await tester.pumpAndSettle();
      expect(tapped, isFalse);
    });
  });

  group('ProfileSectionHeader', () {
    testWidgets('renders uppercase title and optional trailing widget', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const ProfileSectionHeader(
            title: 'Preferences',
            trailing: Text('EDIT'),
          ),
        ),
      );

      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('EDIT'), findsOneWidget);
    });
  });

  group('ProfileQuickActionCard', () {
    testWidgets('renders label and triggers onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          ProfileQuickActionCard(
            label: 'Bookings',
            icon: Icons.calendar_today_rounded,
            iconColor: AppColors.cyan,
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Bookings'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);

      await tester.tap(find.text('Bookings'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });

  group('AppEmptyState', () {
    testWidgets('renders title, subtitle, and action button if provided', (
      tester,
    ) async {
      var actionTapped = false;
      await tester.pumpWidget(
        _wrap(
          AppEmptyState(
            icon: Icons.inbox_rounded,
            title: 'No Payments Yet',
            subtitle:
                'Your payment history will appear here once you complete a booking.',
            actionLabel: 'Browse Services',
            onAction: () => actionTapped = true,
          ),
        ),
      );

      expect(find.text('No Payments Yet'), findsOneWidget);
      expect(
        find.text(
          'Your payment history will appear here once you complete a booking.',
        ),
        findsOneWidget,
      );
      expect(find.text('Browse Services'), findsOneWidget);

      await tester.tap(find.text('Browse Services'));
      await tester.pumpAndSettle();
      expect(actionTapped, isTrue);
    });
  });

  group('AppErrorState', () {
    testWidgets('renders message and invokes onRetry', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        _wrap(
          AppErrorState(
            message: 'Could not connect to the network.',
            retryLabel: 'Try Again',
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.text('Could not connect to the network.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();
      expect(retried, isTrue);
    });
  });
}
