// test/routing_and_auth_gate_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profinder_app/app/routes/app_routes.dart';
import 'package:profinder_app/features/auth/services/auth_provider.dart';

void main() {
  group('AppRoutes map', () {
    test('contains all expected core route keys', () {
      final routes = AppRoutes.routes;
      expect(routes.containsKey(AppRoutes.login), isTrue);
      expect(routes.containsKey(AppRoutes.register), isTrue);
      expect(routes.containsKey(AppRoutes.forgotPassword), isTrue);
      expect(routes.containsKey(AppRoutes.home), isTrue);
      expect(routes.containsKey(AppRoutes.search), isTrue);
      expect(routes.containsKey(AppRoutes.bookings), isTrue);
      expect(routes.containsKey(AppRoutes.profile), isTrue);
      expect(routes.containsKey(AppRoutes.notifications), isTrue);
      expect(routes.containsKey(AppRoutes.magazine), isTrue);
      expect(routes.containsKey(AppRoutes.admin), isTrue);
      expect(routes.containsKey(AppRoutes.pro), isTrue);
      expect(routes.containsKey(AppRoutes.proBookings), isTrue);
      expect(routes.containsKey(AppRoutes.proProfile), isTrue);
      expect(routes.containsKey(AppRoutes.proPortfolio), isTrue);
    });

    test('all route builders instantiate non-null widgets', () {
      final routes = AppRoutes.routes;
      final dummyContext = _DummyBuildContext();
      for (final entry in routes.entries) {
        final widget = entry.value(dummyContext);
        expect(widget, isNotNull, reason: 'Route ${entry.key} returned null');
      }
    });
  });

  group('HomeGate structure', () {
    test('HomeGate is a const constructible StatelessWidget', () {
      const gate = HomeGate();
      expect(gate, isA<StatelessWidget>());
    });

    test('AuthProvider toggles guest mode flag correctly', () {
      final auth = AuthProvider();
      expect(auth.isGuest, isFalse);

      auth.setGuest();
      expect(auth.isGuest, isTrue);
      expect(auth.isLoggedIn, isFalse);
      expect(auth.role, isNull);
    });
  });
}

class _DummyBuildContext extends Fake implements BuildContext {}
