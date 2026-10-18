// test/otp_verification_flow_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:profinder_app/features/auth/screens/otp_verification_screen.dart';
import 'package:profinder_app/features/auth/services/auth_provider.dart';

void main() {
  Widget buildTestWidget({
    required Widget child,
    AuthProvider? authProvider,
  }) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider ?? AuthProvider(),
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('OtpVerificationScreen', () {
    testWidgets('renders all 6 digit PIN input fields, expiry timer, and resend info', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const OtpVerificationScreen(
            email: 'testuser@example.com',
            purpose: 'signup',
          ),
        ),
      );
      await tester.pump();

      // Title & email (title appears in AppBar and body header)
      expect(find.text('Verify Your Email'), findsAtLeastNWidgets(1));
      expect(find.text('testuser@example.com'), findsOneWidget);

      // 6 text fields for OTP
      expect(find.byType(TextFormField), findsNWidgets(6));

      // Expiry countdown text
      expect(find.textContaining('Code expires in'), findsOneWidget);

      // Resend cooldown indication
      expect(find.textContaining("Didn't receive the code?"), findsOneWidget);
      expect(find.textContaining('Resend in'), findsOneWidget);

      // Verify button
      expect(find.text('Verify & Continue'), findsOneWidget);
    });

    testWidgets('verify CTA is disabled when fewer than 6 digits are entered', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const OtpVerificationScreen(
            email: 'testuser@example.com',
            purpose: 'forgot_password',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Enter Verification Code'), findsAtLeastNWidgets(1));

      // Enter only 3 digits
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), '1');
      await tester.enterText(textFields.at(1), '2');
      await tester.enterText(textFields.at(2), '3');
      await tester.pump();

      final verifyBtn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(verifyBtn.onPressed, isNull);
    });
  });
}
