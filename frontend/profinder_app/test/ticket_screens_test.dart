// Widget tests for support tickets (Part 5b): list, new ticket, detail/reply/
// close, and the guest contact form. A fake TicketDataSource is used.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profinder_app/core/theme/app_theme.dart';
import 'package:profinder_app/features/support/models/ticket_models.dart';
import 'package:profinder_app/features/support/screens/guest_contact_screen.dart';
import 'package:profinder_app/features/support/screens/my_tickets_screen.dart';
import 'package:profinder_app/features/support/screens/ticket_detail_screen.dart';
import 'package:profinder_app/l10n/generated/app_localizations.dart';
import 'package:profinder_app/services/support_service.dart';

import 'support_fakes.dart';

Widget _host(
  Widget home, {
  ThemeData? theme,
  Locale locale = const Locale('en'),
  double textScale = 1.0,
}) {
  return MaterialApp(
    theme: theme ?? AppTheme.lightTheme,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, c) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: c!,
    ),
    home: home,
  );
}

void _tallScreen(WidgetTester tester, {Size size = const Size(800, 1800)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('My tickets', () {
    testWidgets('lists tickets with status and the new-reply badge', (tester) async {
      final source = FakeTicketSource(
        tickets: SupportResult.ok([
          ticketSummary(id: 1, subject: 'Cannot withdraw', lastMessageIsStaff: true),
          ticketSummary(
            id: 2,
            reference: 'PF-000002',
            subject: 'Old problem',
            status: TicketStatus.closed,
            lastMessageIsStaff: true,
          ),
        ]),
      );
      await tester.pumpWidget(_host(MyTicketsScreen(source: source)));
      await tester.pumpAndSettle();

      expect(find.text('Cannot withdraw'), findsOneWidget);
      expect(find.text('Old problem'), findsOneWidget);
      expect(find.text('Received'), findsOneWidget);
      expect(find.text('Closed'), findsOneWidget);
      // Badge only on the open ticket, not on the closed one.
      expect(find.text('New reply'), findsOneWidget);
    });

    testWidgets('empty state', (tester) async {
      final source = FakeTicketSource(tickets: const SupportResult.ok(<SupportTicketSummary>[]));
      await tester.pumpWidget(_host(MyTicketsScreen(source: source)));
      await tester.pumpAndSettle();
      expect(find.text('No messages yet'), findsOneWidget);
    });

    testWidgets('error shows retry, retry reloads', (tester) async {
      final source = FakeTicketSource(tickets: const SupportResult.fail(SupportFailure.network));
      await tester.pumpWidget(_host(MyTicketsScreen(source: source)));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);

      source.tickets = SupportResult.ok([ticketSummary()]);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Cannot withdraw'), findsOneWidget);
      expect(source.listCalls, 2);
    });

    testWidgets('tapping a ticket opens its conversation', (tester) async {
      final source = FakeTicketSource();
      await tester.pumpWidget(_host(MyTicketsScreen(source: source)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cannot withdraw'));
      await tester.pumpAndSettle();
      expect(find.text('My withdrawal failed.'), findsOneWidget);
      expect(find.text('Please share the amount.'), findsOneWidget);
    });
  });

  group('New ticket', () {
    Future<FakeTicketSource> openForm(WidgetTester tester, {FakeTicketSource? source}) async {
      _tallScreen(tester);
      final s = source ?? FakeTicketSource(tickets: const SupportResult.ok(<SupportTicketSummary>[]));
      await tester.pumpWidget(_host(MyTicketsScreen(source: s)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      return s;
    }

    testWidgets('empty fields show validation and nothing is sent', (tester) async {
      final source = await openForm(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Send message'));
      await tester.pumpAndSettle();
      expect(find.text('Please fill this in'), findsNWidgets(2));
      expect(source.createCalls, isEmpty);
    });

    testWidgets('sends trimmed text with the chosen category and confirms', (tester) async {
      final source = await openForm(tester);
      await tester.tap(find.text('Payments and withdrawals'));
      await tester.enterText(find.byType(TextFormField).at(0), '  Cannot withdraw  ');
      await tester.enterText(find.byType(TextFormField).at(1), '  My withdrawal failed.  ');
      await tester.tap(find.widgetWithText(FilledButton, 'Send message'));
      await tester.pumpAndSettle();

      expect(source.createCalls, [
        {'subject': 'Cannot withdraw', 'body': 'My withdrawal failed.', 'category': 'payment'},
      ]);
      expect(find.text('Message sent. Your reference number is PF-000001'), findsOneWidget); // back on the list
    });

    testWidgets('a failed send keeps the text and shows the reason', (tester) async {
      final source = await openForm(
        tester,
        source: FakeTicketSource(
          tickets: const SupportResult.ok(<SupportTicketSummary>[]),
          created: const SupportResult.fail(SupportFailure.rateLimited),
        ),
      );
      await tester.enterText(find.byType(TextFormField).at(0), 'Withdrawal issue');
      await tester.enterText(find.byType(TextFormField).at(1), 'Body text');
      await tester.tap(find.widgetWithText(FilledButton, 'Send message'));
      await tester.pumpAndSettle();

      expect(find.text('You have sent too many messages. Please try again after a little while.'), findsOneWidget);
      expect(find.text('Withdrawal issue'), findsOneWidget); // text kept
      expect(source.createCalls.length, 1);
      expect(find.byType(FloatingActionButton), findsNothing); // still on the form
    });
  });

  group('Ticket detail', () {
    testWidgets('shows both sides of the conversation', (tester) async {
      final source = FakeTicketSource();
      await tester.pumpWidget(_host(TicketDetailScreen(ticketId: 1, source: source)));
      await tester.pumpAndSettle();
      expect(find.text('Reference number: PF-000001'), findsOneWidget); // header
      expect(find.text('You'), findsOneWidget);
      expect(find.text('ProFinder Support'), findsOneWidget);
      expect(find.text('My withdrawal failed.'), findsOneWidget);
      expect(find.text('Please share the amount.'), findsOneWidget);
    });

    testWidgets('sending a reply appends it and clears the box', (tester) async {
      final source = FakeTicketSource();
      await tester.pumpWidget(_host(TicketDetailScreen(ticketId: 1, source: source)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'It was 500.');
      await tester.pump();
      await tester.tap(find.byTooltip('Send reply'));
      await tester.pumpAndSettle();

      expect(source.replyCalls, ['It was 500.']);
      expect(find.text('It was 500.'), findsOneWidget); // now a message, box cleared
    });

    testWidgets('send is disabled for blank text', (tester) async {
      final source = FakeTicketSource();
      await tester.pumpWidget(_host(TicketDetailScreen(ticketId: 1, source: source)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      await tester.tap(find.byTooltip('Send reply'));
      await tester.pumpAndSettle();
      expect(source.replyCalls, isEmpty);
    });

    testWidgets('a failed reply keeps the typed text', (tester) async {
      final source = FakeTicketSource(replied: const SupportResult.fail(SupportFailure.network));
      await tester.pumpWidget(_host(TicketDetailScreen(ticketId: 1, source: source)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Please help');
      await tester.pump();
      await tester.tap(find.byTooltip('Send reply'));
      await tester.pumpAndSettle();
      expect(find.text('Please help'), findsOneWidget);
    });

    testWidgets('closed ticket shows a notice and no reply box', (tester) async {
      final source = FakeTicketSource(detail: SupportResult.ok(ticketDetail(status: TicketStatus.closed)));
      await tester.pumpWidget(_host(TicketDetailScreen(ticketId: 1, source: source)));
      await tester.pumpAndSettle();
      expect(find.text('This conversation is closed. Need more help? Send us a new message.'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byTooltip('Mark as solved'), findsNothing);
    });

    testWidgets('closing asks for confirmation first', (tester) async {
      final source = FakeTicketSource();
      await tester.pumpWidget(_host(TicketDetailScreen(ticketId: 1, source: source)));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Mark as solved'));
      await tester.pumpAndSettle();
      expect(find.text('Mark this as solved?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(source.closeCalls, 0);

      await tester.tap(find.byTooltip('Mark as solved'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Mark as solved'));
      await tester.pumpAndSettle();
      expect(source.closeCalls, 1);
      expect(find.text('This conversation is closed. Need more help? Send us a new message.'), findsOneWidget);
    });

    testWidgets('missing ticket shows the not-available message', (tester) async {
      final source = FakeTicketSource(detail: const SupportResult.fail(SupportFailure.notFound));
      await tester.pumpWidget(_host(TicketDetailScreen(ticketId: 1, source: source)));
      await tester.pumpAndSettle();
      expect(find.text('We could not find this message. It may have been removed.'), findsOneWidget);
    });
  });

  group('Guest contact', () {
    testWidgets('validates email, then sends and shows the reference', (tester) async {
      _tallScreen(tester);
      final source = FakeTicketSource();
      await tester.pumpWidget(_host(GuestContactScreen(source: source)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
      await tester.enterText(find.byType(TextFormField).at(1), 'Help me');
      await tester.enterText(find.byType(TextFormField).at(2), 'I cannot log in.');
      await tester.tap(find.widgetWithText(FilledButton, 'Send message'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(source.guestCalls, isEmpty);

      await tester.enterText(find.byType(TextFormField).at(0), ' guest@example.com ');
      await tester.tap(find.widgetWithText(FilledButton, 'Send message'));
      await tester.pumpAndSettle();

      expect(source.guestCalls.single['email'], 'guest@example.com');
      expect(find.text('Message sent'), findsOneWidget);
      expect(find.text('Reference number: PF-000042'), findsOneWidget);
    });

    testWidgets('a silently dropped message looks like success without a reference', (tester) async {
      _tallScreen(tester);
      final source = FakeTicketSource(guest: const SupportResult.ok(GuestReceipt(null)));
      await tester.pumpWidget(_host(GuestContactScreen(source: source)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'a@b.co');
      await tester.enterText(find.byType(TextFormField).at(1), 'Hi');
      await tester.enterText(find.byType(TextFormField).at(2), 'Hello');
      await tester.tap(find.widgetWithText(FilledButton, 'Send message'));
      await tester.pumpAndSettle();
      expect(find.text('Message sent'), findsOneWidget);
      expect(find.textContaining('Reference number:'), findsNothing);
    });

    testWidgets('server rate limit is shown and the form stays', (tester) async {
      _tallScreen(tester);
      final source = FakeTicketSource(guest: const SupportResult.fail(SupportFailure.rateLimited));
      await tester.pumpWidget(_host(GuestContactScreen(source: source)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'a@b.co');
      await tester.enterText(find.byType(TextFormField).at(1), 'Hi');
      await tester.enterText(find.byType(TextFormField).at(2), 'Hello');
      await tester.tap(find.widgetWithText(FilledButton, 'Send message'));
      await tester.pumpAndSettle();
      expect(find.text('You have sent too many messages. Please try again after a little while.'), findsOneWidget);
      expect(find.text('Message sent'), findsNothing);
    });
  });

  group('Layout', () {
    testWidgets('Urdu (RTL), 2x text, narrow, dark: no overflow on any ticket screen', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final source = FakeTicketSource(
        tickets: SupportResult.ok([
          ticketSummary(subject: 'پیسے نکلوانے میں مسئلہ ہے اور بہت لمبا موضوع جو کئی لائنوں میں آئے گا', lastMessageIsStaff: true),
        ]),
        detail: SupportResult.ok(ticketDetail(messages: [
          ticketMessage(1, 'میری رقم نہیں نکل رہی۔'),
          ticketMessage(2, 'Please share the amount.', staff: true),
        ])),
      );
      for (final screen in <Widget>[
        MyTicketsScreen(source: source),
        TicketDetailScreen(ticketId: 1, source: source),
        GuestContactScreen(source: source),
      ]) {
        await tester.pumpWidget(_host(
          screen,
          theme: AppTheme.darkTheme,
          locale: const Locale('ur'),
          textScale: 2.0,
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });
}
