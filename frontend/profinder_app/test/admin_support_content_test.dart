// Widget tests for the admin Help-content editor (Part 9).
// A fake SupportContentDataSource is used, so no network / Dio is touched.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profinder_app/core/theme/app_theme.dart';
import 'package:profinder_app/features/admin/screens/admin_article_editor_screen.dart';
import 'package:profinder_app/features/admin/screens/admin_policy_editor_screen.dart';
import 'package:profinder_app/features/admin/screens/admin_support_content_screen.dart';

import 'support_content_fakes.dart';

Widget _host(Widget home) => MaterialApp(theme: AppTheme.lightTheme, home: home);

/// Opens [build] on top of a launcher page, so popping the editor is safe.
Widget _launcher(Widget Function() build) => _host(
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => build())),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

void _screen(WidgetTester tester, {Size size = const Size(800, 1800)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('Policy tab', () {
    testWidgets('lists versions; no "new version" button while a draft exists', (tester) async {
      _screen(tester);
      final source = FakeContentSource(policies: [
        policyVersion(id: 2, version: 2),
        policyVersion(id: 1, version: 1, status: 'published', body: 'Done.'),
      ]);
      await tester.pumpWidget(_host(AdminSupportContentScreen(source: source)));
      await tester.pumpAndSettle();

      expect(find.text('Version 2'), findsOneWidget);
      expect(find.text('Version 1'), findsOneWidget);
      expect(find.text('1 blanks to fill'), findsOneWidget);
      expect(find.text('Start new version'), findsNothing);
    });

    testWidgets('"Start new version" creates a draft and opens the editor', (tester) async {
      _screen(tester);
      final source = FakeContentSource(policies: [
        policyVersion(id: 1, version: 1, status: 'published', body: 'Done.'),
      ]);
      await tester.pumpWidget(_host(AdminSupportContentScreen(source: source)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start new version'));
      await tester.pumpAndSettle();

      expect(source.calls, contains('newPolicyVersion'));
      expect(find.widgetWithText(TextField, 'Policy text'), findsOneWidget);
    });
  });

  group('Policy editor', () {
    testWidgets('publish stays off until every blank is filled, then locks the version', (tester) async {
      _screen(tester);
      final source = FakeContentSource(policies: [
        policyVersion(id: 1, body: 'Mail us at [PLACEHOLDER: SUPPORT EMAIL].'),
      ]);
      await tester.pumpWidget(_host(AdminPolicyEditorScreen(versionId: 1, source: source)));
      await tester.pumpAndSettle();

      expect(find.textContaining('1 blank(s) still need'), findsOneWidget);
      final publish = find.widgetWithText(FilledButton, 'Publish');
      expect(tester.widget<FilledButton>(publish).onPressed, isNull);

      await tester.enterText(find.widgetWithText(TextField, 'SUPPORT EMAIL'), 'help@profinder.pk');
      await tester.tap(find.text('Apply to text'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No blanks left'), findsOneWidget);
      expect(tester.widget<FilledButton>(publish).onPressed, isNotNull);

      await tester.tap(publish);
      await tester.pumpAndSettle();
      expect(find.text('Publish version 1?'), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Publish')));
      await tester.pumpAndSettle();

      expect(source.calls, containsAllInOrder(['savePolicy:1', 'publishPolicy:1']));
      expect(source.policies.single.body, 'Mail us at help@profinder.pk.');
      expect(find.textContaining('is published and cannot be edited'), findsOneWidget);
      expect(find.text('Publish'), findsNothing);
    });

    testWidgets('a published version is read-only', (tester) async {
      _screen(tester);
      final source = FakeContentSource(policies: [
        policyVersion(id: 1, status: 'published', body: 'Final text.'),
      ]);
      await tester.pumpWidget(_host(AdminPolicyEditorScreen(versionId: 1, source: source)));
      await tester.pumpAndSettle();

      expect(find.textContaining('cannot be edited'), findsOneWidget);
      expect(find.text('Save draft'), findsNothing);
      expect(find.text('Publish'), findsNothing);
      expect(tester.widget<TextField>(find.widgetWithText(TextField, 'Policy text')).enabled, isFalse);
    });
  });

  group('Articles', () {
    testWidgets('tab lists articles and the Drafts chip filters', (tester) async {
      _screen(tester);
      final source = FakeContentSource(articles: [
        helpArticle(id: 1, title: 'Reset password', published: true),
        helpArticle(id: 2, title: 'Withdraw money'),
      ]);
      await tester.pumpWidget(_host(AdminSupportContentScreen(source: source)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Help articles'));
      await tester.pumpAndSettle();

      expect(find.text('Reset password'), findsOneWidget);
      expect(find.text('Withdraw money'), findsOneWidget);

      await tester.tap(find.text('Drafts'));
      await tester.pumpAndSettle();

      expect(source.articleListFilters.last, false);
      expect(find.text('Reset password'), findsNothing);
      expect(find.text('Withdraw money'), findsOneWidget);
    });

    testWidgets('creating an article sends it as a draft', (tester) async {
      _screen(tester);
      final source = FakeContentSource();
      await tester.pumpWidget(_host(AdminArticleEditorScreen(source: source)));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'How to pay');
      await tester.enterText(find.widgetWithText(TextField, 'Article text'), 'Use the Pay button.');
      await tester.tap(find.text('Create article'));
      await tester.pumpAndSettle();

      expect(source.calls, ['createArticle']);
      expect(source.articles.single.title, 'How to pay');
      expect(source.articles.single.isPublished, isFalse);
      expect(find.text('Saved as a draft.'), findsOneWidget);
    });

    testWidgets('a server error message is shown as it is', (tester) async {
      _screen(tester);
      final source = FakeContentSource(
        articles: [helpArticle(id: 1)],
        failMessage: 'Add a title and text before publishing.',
      );
      await tester.pumpWidget(_host(AdminArticleEditorScreen(articleId: 1, source: source)));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Changed');
      await tester.pump();
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(find.text('Add a title and text before publishing.'), findsOneWidget);
    });

    testWidgets('an unpublished article can be deleted after confirming', (tester) async {
      _screen(tester);
      final source = FakeContentSource(articles: [helpArticle(id: 1)]);
      await tester.pumpWidget(_launcher(() => AdminArticleEditorScreen(articleId: 1, source: source)));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete article'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this article?'), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Delete')));
      await tester.pumpAndSettle();

      expect(source.deleted, [1]);
      expect(find.text('open'), findsOneWidget); // back on the launcher page
    });

    testWidgets('a published article cannot be deleted from the editor', (tester) async {
      _screen(tester);
      final source = FakeContentSource(articles: [helpArticle(id: 1, published: true)]);
      await tester.pumpWidget(_host(AdminArticleEditorScreen(articleId: 1, source: source)));
      await tester.pumpAndSettle();

      expect(find.text('Delete article'), findsNothing);
      expect(find.textContaining('save to delete'), findsOneWidget);
      await tester.tap(find.textContaining('save to delete'));
      await tester.pumpAndSettle();
      expect(source.deleted, isEmpty);
    });
  });
}
