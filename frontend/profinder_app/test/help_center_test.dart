// Widget tests for the Help Center (Part 4). A fake HelpDataSource is used, so
// no network / Dio / SharedPreferences is touched.
//
// Covers: topics list, category -> article navigation, search (debounce + min
// length + no results), legacy fallback (empty / failed list), error + retry,
// English-fallback note, Urdu (RTL) at 2x text scale on a narrow screen, dark.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profinder_app/core/theme/app_theme.dart';
import 'package:profinder_app/features/support/models/help_models.dart';
import 'package:profinder_app/features/support/models/policy_document.dart';
import 'package:profinder_app/features/support/models/ticket_models.dart';
import 'package:profinder_app/features/support/screens/help_center_screen.dart';
import 'package:profinder_app/l10n/generated/app_localizations.dart';
import 'package:profinder_app/services/support_service.dart';

import 'support_fakes.dart';

class _FakeSource implements HelpDataSource {
  SupportResult<List<HelpCategory>> categories;
  SupportResult<List<HelpArticleSummary>> articles;
  SupportResult<HelpArticle> article;
  final List<String?> queries = [];
  int categoryCalls = 0;

  _FakeSource({
    SupportResult<List<HelpCategory>>? categories,
    SupportResult<List<HelpArticleSummary>>? articles,
    SupportResult<HelpArticle>? article,
  })  : categories = categories ?? SupportResult.ok(_cats()),
        articles = articles ?? SupportResult.ok(_summaries()),
        article = article ?? SupportResult.ok(_article());

  @override
  Future<SupportResult<List<HelpCategory>>> getHelpCategories({
    required String lang,
    String? audience,
  }) async {
    categoryCalls++;
    return categories;
  }

  @override
  Future<SupportResult<List<HelpArticleSummary>>> getHelpArticles({
    required String lang,
    String? audience,
    String? category,
    String? query,
  }) async {
    queries.add(query);
    return articles;
  }

  @override
  Future<SupportResult<HelpArticle>> getHelpArticle({
    required String slug,
    required String lang,
    String? audience,
  }) async =>
      article;
}

List<HelpCategory> _cats({bool fallback = false}) => [
      HelpCategory(
        slug: 'booking',
        iconKey: 'booking',
        title: 'Bookings and refunds',
        description: 'Book, change or cancel a booking',
        articleCount: 3,
        isFallback: fallback,
      ),
      HelpCategory(
        slug: 'account',
        iconKey: 'account',
        title: 'Account',
        description: '',
        articleCount: 2,
        isFallback: fallback,
      ),
    ];

List<HelpArticleSummary> _summaries() => const [
      HelpArticleSummary(
        slug: 'how-to-cancel',
        categorySlug: 'booking',
        title: 'How do I cancel a booking?',
        snippet: 'Open the booking and tap Cancel.',
        isFallback: false,
      ),
    ];

HelpArticle _article({bool fallback = false, bool rtl = false}) => HelpArticle(
      slug: 'how-to-cancel',
      categorySlug: 'booking',
      title: 'How do I cancel a booking?',
      blocks: const [
        PolicyBlock(PolicyBlockType.heading, 'Steps'),
        PolicyBlock(PolicyBlockType.paragraph, 'Open the booking and tap Cancel.'),
        PolicyBlock(PolicyBlockType.bullet, 'Refunds follow the cancellation policy.'),
      ],
      isFallback: fallback,
      isRtl: rtl,
    );

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

const _legacyKey = Key('legacy-help-screen');
Widget _legacy(BuildContext _) => const Scaffold(body: Center(child: Text('LEGACY HELP', key: _legacyKey)));

void main() {
  testWidgets('shows topics, then category articles, then the article', (tester) async {
    final source = _FakeSource();
    await tester.pumpWidget(_host(HelpCenterScreen(source: source)));
    await tester.pumpAndSettle();

    expect(find.text('Bookings and refunds'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);

    await tester.tap(find.text('Bookings and refunds'));
    await tester.pumpAndSettle();
    expect(find.text('How do I cancel a booking?'), findsOneWidget);

    await tester.tap(find.text('How do I cancel a booking?'));
    await tester.pumpAndSettle();
    expect(find.text('Steps'), findsOneWidget);
    expect(find.text('Refunds follow the cancellation policy.'), findsOneWidget);
  });

  testWidgets('search waits for min length + debounce, then lists results', (tester) async {
    final source = _FakeSource();
    await tester.pumpWidget(_host(HelpCenterScreen(source: source)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'r');
    await tester.pump(const Duration(milliseconds: 600));
    expect(source.queries, isEmpty); // 1 char: no request

    await tester.enterText(find.byType(TextField), 'refund');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(source.queries, ['refund']);
    expect(find.text('How do I cancel a booking?'), findsOneWidget);
  });

  testWidgets('search with no matches shows the empty state', (tester) async {
    final source = _FakeSource(articles: const SupportResult.ok(<HelpArticleSummary>[]));
    await tester.pumpWidget(_host(HelpCenterScreen(source: source)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('No results found'), findsOneWidget);
  });

  testWidgets('empty category list falls back to the legacy screen', (tester) async {
    final source = _FakeSource(categories: const SupportResult.ok(<HelpCategory>[]));
    await tester.pumpWidget(_host(HelpCenterScreen(source: source, fallbackBuilder: _legacy)));
    await tester.pumpAndSettle();
    expect(find.byKey(_legacyKey), findsOneWidget);
  });

  testWidgets('failed list falls back to the legacy screen', (tester) async {
    final source = _FakeSource(categories: const SupportResult.fail(SupportFailure.network));
    await tester.pumpWidget(_host(HelpCenterScreen(source: source, fallbackBuilder: _legacy)));
    await tester.pumpAndSettle();
    expect(find.byKey(_legacyKey), findsOneWidget);
  });

  testWidgets('without a fallback, a failed list shows error and retry reloads', (tester) async {
    final source = _FakeSource(categories: const SupportResult.fail(SupportFailure.network));
    await tester.pumpWidget(_host(HelpCenterScreen(source: source)));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);

    source.categories = SupportResult.ok(_cats());
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Account'), findsOneWidget);
    expect(source.categoryCalls, 2);
  });

  testWidgets('signed-in user: Contact support opens their tickets', (tester) async {
    final source = _FakeSource();
    final tickets = FakeTicketSource(tickets: const SupportResult.ok(<SupportTicketSummary>[]));
    await tester.pumpWidget(_host(
      HelpCenterScreen(source: source, ticketSource: tickets, audience: 'customer'),
    ));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Contact support'),
      200,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)),
    );
    await tester.tap(find.text('Contact support'));
    await tester.pumpAndSettle();
    expect(find.text('No messages yet'), findsOneWidget);
  });

  testWidgets('guest: Contact support opens the logged-out form', (tester) async {
    final source = _FakeSource();
    await tester.pumpWidget(_host(
      HelpCenterScreen(source: source, ticketSource: FakeTicketSource()),
    ));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Contact support'),
      200,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)),
    );
    await tester.tap(find.text('Contact support'));
    await tester.pumpAndSettle();
    expect(find.text('Your email'), findsOneWidget);
  });

  testWidgets('with content published, legacy screen stays reachable via More ways', (tester) async {
    final source = _FakeSource();
    await tester.pumpWidget(_host(HelpCenterScreen(source: source, fallbackBuilder: _legacy)));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('More ways to reach us'),
      200,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)),
    );
    await tester.tap(find.text('More ways to reach us'));
    await tester.pumpAndSettle();
    expect(find.byKey(_legacyKey), findsOneWidget);
  });

  testWidgets('no articles and no legacy screen: still offers Contact support', (tester) async {
    final source = _FakeSource(categories: const SupportResult.ok(<HelpCategory>[]));
    await tester.pumpWidget(_host(HelpCenterScreen(source: source, ticketSource: FakeTicketSource())));
    await tester.pumpAndSettle();
    expect(find.text('Contact support'), findsOneWidget);
  });

  testWidgets('English-fallback note is shown on the article screen', (tester) async {
    final source = _FakeSource(article: SupportResult.ok(_article(fallback: true)));
    await tester.pumpWidget(_host(HelpCenterScreen(source: source)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bookings and refunds'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('How do I cancel a booking?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('shown in English'), findsOneWidget);
  });

  testWidgets('Urdu (RTL), 2x text, narrow screen, dark: no overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final source = _FakeSource();
    await tester.pumpWidget(_host(
      HelpCenterScreen(source: source, fallbackBuilder: _legacy),
      theme: AppTheme.darkTheme,
      locale: const Locale('ur'),
      textScale: 2.0,
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Account'), findsOneWidget);
  });
}
