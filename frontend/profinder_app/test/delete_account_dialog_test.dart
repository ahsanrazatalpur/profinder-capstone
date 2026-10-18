// test/delete_account_dialog_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:profinder_app/features/auth/services/auth_provider.dart';
import 'package:profinder_app/features/settings/widgets/delete_account_dialog.dart';

class FakeAuthProvider extends AuthProvider {
  bool requestOtpCalled = false;
  bool confirmDeleteCalled = false;
  String? lastConfirmedPassword;
  String? lastConfirmedOtp;

  @override
  Future<Map<String, dynamic>> requestDeleteAccountOtp() async {
    requestOtpCalled = true;
    return {
      'success': true,
      'data': {'cooldown': 60, 'message': 'Code sent'},
    };
  }

  @override
  Future<Map<String, dynamic>> confirmDeleteAccount({
    String? password,
    String? otp,
  }) async {
    confirmDeleteCalled = true;
    lastConfirmedPassword = password;
    lastConfirmedOtp = otp;
    return {
      'success': true,
      'data': {'message': 'Account deleted successfully'},
    };
  }
}

void main() {
  Widget buildTestWidget({
    required Widget child,
    AuthProvider? authProvider,
  }) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider ?? FakeAuthProvider(),
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('DeleteAccountDialog', () {
    testWidgets('renders password mode by default when hasPassword is true', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const DeleteAccountDialog(
            hasPassword: true,
            userEmail: 'user@example.com',
          ),
        ),
      );
      await tester.pump();

      // Title & danger warning
      expect(find.text('Delete Account'), findsAtLeastNWidgets(1));
      expect(find.textContaining('This action is permanent'), findsOneWidget);

      // Password input field
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('Verify with Gmail OTP instead'), findsOneWidget);

      // Action buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete Account'), findsAtLeastNWidgets(1));

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('switching to OTP mode triggers requestOtp and reveals 6 digit input and paste button', (tester) async {
      final fakeAuth = FakeAuthProvider();
      await tester.pumpWidget(
        buildTestWidget(
          authProvider: fakeAuth,
          child: const DeleteAccountDialog(
            hasPassword: true,
            userEmail: 'user@example.com',
          ),
        ),
      );
      await tester.pump();

      // Tap verify with Gmail OTP instead
      await tester.tap(find.text('Verify with Gmail OTP instead'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should show user email and 6 digit fields
      expect(find.text('user@example.com'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(6));
      expect(find.text('Paste Code from Clipboard'), findsOneWidget);
      expect(find.text('Use Account Password instead'), findsOneWidget);
      expect(fakeAuth.requestOtpCalled, isTrue);

      // Clean up timer by unmounting widget
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('renders OTP mode directly when hasPassword is false (Google OAuth user)', (tester) async {
      final fakeAuth = FakeAuthProvider();
      await tester.pumpWidget(
        buildTestWidget(
          authProvider: fakeAuth,
          child: const DeleteAccountDialog(
            hasPassword: false,
            userEmail: 'googleuser@gmail.com',
          ),
        ),
      );
      await tester.pump();

      // Directly renders email and 6-digit fields without password prompt
      expect(find.text('googleuser@gmail.com'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(6));
      expect(find.text('Paste Code from Clipboard'), findsOneWidget);
      expect(find.text('Use Account Password instead'), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('submitting password in password mode calls confirmDeleteAccount with password', (tester) async {
      final fakeAuth = FakeAuthProvider();
      await tester.pumpWidget(
        buildTestWidget(
          authProvider: fakeAuth,
          child: const DeleteAccountDialog(
            hasPassword: true,
            userEmail: 'user@example.com',
          ),
        ),
      );
      await tester.pump();

      // Enter password
      await tester.enterText(find.byType(TextField), 'MySecret123!');
      await tester.pump();

      // Tap Delete Account button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete Account'));
      await tester.pump();

      expect(fakeAuth.confirmDeleteCalled, isTrue);
      expect(fakeAuth.lastConfirmedPassword, equals('MySecret123!'));

      await tester.pumpWidget(const SizedBox());
    });
  });
}
