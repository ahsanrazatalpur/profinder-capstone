// test/google_auth_flow_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:profinder_app/core/widgets/google_logo.dart';
import 'package:profinder_app/features/auth/screens/login_screen.dart';
import 'package:profinder_app/features/auth/services/auth_provider.dart';
import 'package:profinder_app/features/auth/services/google_auth_service.dart';
import 'package:profinder_app/features/auth/widgets/social_auth_button.dart';
import 'package:profinder_app/l10n/generated/app_localizations.dart';

void main() {
  test('GoogleAuthResult factory constructors handle all outcomes', () {
    final success = GoogleAuthResult.success(
      idToken: 'mock-id-token',
      accessToken: 'mock-access-token',
    );
    expect(success.idToken, 'mock-id-token');
    expect(success.accessToken, 'mock-access-token');
    expect(success.isCancelled, false);
    expect(success.errorMessage, isNull);

    final cancelled = GoogleAuthResult.cancelled();
    expect(cancelled.isCancelled, true);
    expect(cancelled.idToken, isNull);
    expect(cancelled.errorMessage, isNull);

    final error = GoogleAuthResult.error('Mock failure');
    expect(error.isCancelled, false);
    expect(error.errorMessage, 'Mock failure');
  });

  testWidgets('LoginScreen renders Google Sign-In button with logo and label', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(480, 900));

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(),
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Google button exists
    expect(find.byType(SocialAuthButton), findsOneWidget);
    expect(find.byType(GoogleLogo), findsOneWidget);
    expect(find.text('Continue with Google'), findsWidgets);
  });
}
