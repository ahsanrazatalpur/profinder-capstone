// Widget tests for the admin support inbox + ticket detail (Part 6b).
// A fake SupportAdminDataSource is used, so no network / Dio is touched.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profinder_app/core/theme/app_theme.dart';
import 'package:profinder_app/features/admin/models/support_admin_models.dart';
import 'package:profinder_app/features/admin/screens/admin_support_ticket_detail_screen.dart';
import 'package:profinder_app/features/admin/screens/admin_support_tickets_screen.dart';
import 'package:profinder_app/services/support_service.dart';

import 'support_admin_fakes.dart';

Widget _host(Widget home, {double textScale = 1.0}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    builder: (context, c) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: c!,
    ),
    home: home,
  );
}

void _screen(WidgetTester tester, {Size size = const Size(800, 1600)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('Inbox', () {
    testWidgets('lists tickets with requester, guest label and badges', (tester) async {
      _screen(tester);
      final source = FakeAdminSource();
      await tester.pumpWidget(_host(AdminSupportTicketsScreen(source: source)));
      await tester.pumpAndSettle();

      expect(find.text('Cannot withdraw'), findsOneWidget);
      expect(find.text('Alice Khan'), findsOneWidget);
      expect(find.text('Guest · guest@example.com'), findsOneWidget);
      expect(find.text('High priority'), findsOneWidget);
      expect(find.text('Needs reply'), findsWidgets); // pill on the first ticket (+ filter chip)
    });

    testWidgets('filter chips show counts and drive the query', (tester) async {
      // Wide enough that every chip is built (the chip row scrolls sideways).
      _screen(tester, size: const Size(1600, 1600));
      final source = FakeAdminSource();
      await tester.pumpWidget(_host(AdminSupportTicketsScreen(source: source)));
      await tester.pumpAndSettle();

      // Default view: active tickets.
      expect(source.listCalls.first['status'], 'active');
      expect(find.text('Needs reply (2)'), findsOneWidget);
      expect(find.text('Active (3)'), findsOneWidget);

      await tester.tap(find.text('Needs reply (2)'));
      await tester.pumpAndSettle();
      expect(source.listCalls.last['needsReply'], true);

      await tester.tap(find.text('Mine (1)'));
      await tester.pumpAndSettle();
      expect(source.listCalls.last['assigned'], 'me');
      expect(source.listCalls.last['status'], 'active');

      await tester.tap(find.text('Closed (9)'));
      await tester.pumpAndSettle();
      expect(source.listCalls.last['status'], 'closed');
    });

    testWidgets('search is debounced and sent as the query', (tester) async {
      _screen(tester);
      final source = FakeAdminSource();
      await tester.pumpWidget(_host(AdminSupportTicketsScreen(source: source)));
      await tester.pumpAndSettle();
      final before = source.listCalls.length;

      await tester.enterText(find.byType(TextField), 'refund');
      await tester.pump(const Duration(milliseconds: 100));
      expect(source.listCalls.length, before); // still waiting for the debounce

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(source.listCalls.last['query'], 'refund');
    });

    testWidgets('empty state and error with retry', (tester) async {
      _screen(tester);
      final empty = FakeAdminSource(page: const SupportResult.ok(AdminTicketPage(count: 0, results: [])));
      await tester.pumpWidget(_host(AdminSupportTicketsScreen(key: const ValueKey('empty'), source: empty)));
      await tester.pumpAndSettle();
      expect(find.text('No tickets here.'), findsOneWidget);

      final failing = FakeAdminSource(page: const SupportResult.fail(SupportFailure.network));
      // New key: otherwise Flutter reuses the first screen's State (and its source).
      await tester.pumpWidget(_host(AdminSupportTicketsScreen(key: const ValueKey('failing'), source: failing)));
      await tester.pumpAndSettle();
      expect(find.text('Failed to load tickets.'), findsOneWidget);
      failing.page = SupportResult.ok(AdminTicketPage(count: 1, results: [adminSummary()]));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Cannot withdraw'), findsOneWidget);
    });

    testWidgets('a non-admin sees an access message, not a generic failure', (tester) async {
      _screen(tester);
      final source = FakeAdminSource(page: const SupportResult.fail(SupportFailure.unauthorized));
      await tester.pumpWidget(_host(AdminSupportTicketsScreen(source: source)));
      await tester.pumpAndSettle();
      expect(find.text('You do not have access to support tickets.'), findsOneWidget);
    });

    testWidgets('load more appends the next page', (tester) async {
      _screen(tester);
      final source = FakeAdminSource(
        page: SupportResult.ok(AdminTicketPage(count: 3, results: [
          adminSummary(),
          adminSummary(id: 2, reference: 'PF-000002', subject: 'Second'),
        ])),
        morePage: SupportResult.ok(AdminTicketPage(count: 3, results: [
          adminSummary(id: 3, reference: 'PF-000003', subject: 'Third one'),
        ])),
      );
      await tester.pumpWidget(_host(AdminSupportTicketsScreen(source: source)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Load more (1 left)'));
      await tester.pumpAndSettle();
      expect(source.listCalls.last['offset'], 2);
      expect(find.text('Third one'), findsOneWidget);
      expect(find.textContaining('Load more'), findsNothing);
    });

    testWidgets('tapping a ticket opens it', (tester) async {
      _screen(tester);
      final source = FakeAdminSource();
      await tester.pumpWidget(_host(AdminSupportTicketsScreen(source: source)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cannot withdraw'));
      await tester.pumpAndSettle();
      expect(find.text('Please share the amount.'), findsOneWidget);
    });
  });

  group('Ticket detail', () {
    Future<FakeAdminSource> open(WidgetTester tester, {FakeAdminSource? source}) async {
      _screen(tester);
      final s = source ?? FakeAdminSource();
      await tester.pumpWidget(_host(AdminSupportTicketDetailScreen(ticketId: 1, source: s)));
      await tester.pumpAndSettle();
      return s;
    }

    testWidgets('shows the conversation, internal notes marked, and context', (tester) async {
      await open(tester);
      expect(find.text('Cannot withdraw'), findsOneWidget);
      expect(find.textContaining('Alice Khan'), findsWidgets);
      expect(find.textContaining('Booking #55'), findsOneWidget);
      expect(find.text('My withdrawal failed.'), findsOneWidget);
      expect(find.text('Please share the amount.'), findsOneWidget);
      // Internal notes are visibly different and labelled.
      expect(find.text('SECRET: looks like fraud check'), findsOneWidget);
      expect(find.text('Internal note · Admin One'), findsOneWidget);
      expect(find.text('Activity (2)'), findsOneWidget);
    });

    testWidgets('public reply is sent as not-internal and clears the box', (tester) async {
      final source = await open(tester);
      expect(find.text('The user will be notified of this reply.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'We are checking.');
      await tester.pump();
      await tester.tap(find.byTooltip('Send reply'));
      await tester.pumpAndSettle();

      expect(source.replyCalls, [
        {'body': 'We are checking.', 'internal': false},
      ]);
      expect(find.text('We are checking.'), findsOneWidget); // now a message; box cleared
      expect(find.text('Awaiting user'), findsOneWidget);    // status moved on
    });

    testWidgets('guest tickets say the reply goes by email', (tester) async {
      await open(tester, source: FakeAdminSource(guest: true));
      expect(find.text('This reply will be emailed to guest@example.com.'), findsOneWidget);
    });

    testWidgets('switching to Internal note sends internal=true', (tester) async {
      final source = await open(tester);
      await tester.tap(find.text('Internal note'));
      await tester.pumpAndSettle();
      expect(find.text('Only admins can see this note.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Escalate to finance');
      await tester.pump();
      await tester.tap(find.byTooltip('Add note'));
      await tester.pumpAndSettle();
      expect(source.replyCalls.single, {'body': 'Escalate to finance', 'internal': true});
    });

    testWidgets('blank text cannot be sent', (tester) async {
      final source = await open(tester);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      await tester.tap(find.byTooltip('Send reply'));
      await tester.pumpAndSettle();
      expect(source.replyCalls, isEmpty);
    });

    testWidgets('a failed reply keeps the text and says why', (tester) async {
      final source = await open(
        tester,
        source: FakeAdminSource(replyOverride: const SupportResult.fail(SupportFailure.conflict)),
      );
      await tester.enterText(find.byType(TextField), 'Please retry');
      await tester.pump();
      await tester.tap(find.byTooltip('Send reply'));
      await tester.pumpAndSettle();
      expect(find.text('This ticket is closed. Reopen it first.'), findsOneWidget);
      expect(find.text('Please retry'), findsOneWidget);
      expect(source.replyCalls.length, 1);
    });

    testWidgets('status and priority menus call update', (tester) async {
      final source = await open(tester);

      await tester.tap(find.text('Status: Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Resolved'));
      await tester.pumpAndSettle();
      expect(source.updateCalls.last['status'], 'resolved');
      expect(find.text('Status: Resolved'), findsOneWidget);

      await tester.tap(find.text('Priority: Normal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('High'));
      await tester.pumpAndSettle();
      expect(source.updateCalls.last['priority'], 'high');
      expect(find.text('High priority'), findsOneWidget);
    });

    testWidgets('assign to me, then unassign', (tester) async {
      final source = await open(tester);
      expect(find.text('Unassigned'), findsOneWidget);

      await tester.tap(find.text('Assign to me'));
      await tester.pumpAndSettle();
      expect(source.updateCalls.last['assignee'], 'me');
      expect(find.text('Unassign'), findsOneWidget);

      await tester.tap(find.text('Unassign'));
      await tester.pumpAndSettle();
      expect(source.updateCalls.last['assignee'], 'none');
      expect(find.text('Assign to me'), findsOneWidget);
    });

    testWidgets('closed ticket: reply is locked, notes allowed, Reopen works', (tester) async {
      final source = await open(tester, source: FakeAdminSource(status: 'closed'));
      expect(find.textContaining('Closed. Reopen it'), findsOneWidget);
      expect(find.text('Only admins can see this note.'), findsOneWidget); // forced to internal

      await tester.enterText(find.byType(TextField), 'Post-mortem note');
      await tester.pump();
      await tester.tap(find.byTooltip('Add note'));
      await tester.pumpAndSettle();
      expect(source.replyCalls.single['internal'], true);

      await tester.tap(find.text('Reopen'));
      await tester.pumpAndSettle();
      expect(source.updateCalls.last['status'], 'open');
      expect(find.textContaining('Closed. Reopen it'), findsNothing);
    });

    testWidgets('missing ticket shows a clear message', (tester) async {
      await open(
        tester,
        source: FakeAdminSource(detailOverride: const SupportResult.fail(SupportFailure.notFound)),
      );
      expect(find.text('This ticket no longer exists.'), findsOneWidget);
    });
  });

  group('Layout', () {
    testWidgets('narrow screen at 2x text: no overflow on inbox or detail', (tester) async {
      tester.view.physicalSize = const Size(360, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final source = FakeAdminSource(assignee: adminPerson(name: 'A very long administrator display name'));
      for (final screen in <Widget>[
        AdminSupportTicketsScreen(source: source),
        AdminSupportTicketDetailScreen(ticketId: 1, source: source),
      ]) {
        await tester.pumpWidget(_host(screen, textScale: 2.0));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });
}
