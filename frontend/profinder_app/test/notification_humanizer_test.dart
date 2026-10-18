import 'package:flutter_test/flutter_test.dart';
import 'package:profinder_app/features/notifications/screens/notification_screen.dart';

void main() {
  group('NotificationScreen.humanizeMessage', () {
    test('cleans up legacy payment notifications with booking numbers', () {
      const legacyPaymentMsg =
          'Your payment of 50.00 USD for Booking #31 was successful.';
      final result = NotificationScreen.humanizeMessage(legacyPaymentMsg);
      expect(result,
          'Your payment of 50.00 USD for your booking was successful.');
    });

    test('cleans up legacy booking schedule messages with booking numbers', () {
      const legacyBookingDetail =
          'Ali Khan has booked you.\nBooking #31 | 12 May 2026 at 10:00 AM';
      final result = NotificationScreen.humanizeMessage(legacyBookingDetail);
      expect(result,
          'Ali Khan has booked you.\nScheduled for 12 May 2026 at 10:00 AM');
    });

    test('cleans up standalone booking numbers', () {
      const standaloneMsg =
          'Customer Ahsan has paid 50.00 USD for Booking #31.';
      final result = NotificationScreen.humanizeMessage(standaloneMsg);
      expect(result,
          'Customer Ahsan has paid 50.00 USD for your booking.');
    });

    test('cleans up legacy support ticket reference numbers', () {
      const legacyTicketMsg = 'PF-2026-0001: new reply from support.';
      final result = NotificationScreen.humanizeMessage(legacyTicketMsg);
      expect(result, 'Support: new reply from support.');

      const legacyTicketResolved = 'PF-2026-0001 was marked as resolved.';
      final result2 = NotificationScreen.humanizeMessage(legacyTicketResolved);
      expect(result2, 'your support request was marked as resolved.');
    });

    test('preserves clean already-humanized messages unchanged', () {
      const cleanMsg =
          'Your payment of 50.00 USD to Ahsan Talpur was successful.';
      expect(NotificationScreen.humanizeMessage(cleanMsg), cleanMsg);

      const cleanServiceMsg =
          'Ahsan Talpur has accepted your booking.\nScheduled for 12 May 2026 at 10:00 AM';
      expect(NotificationScreen.humanizeMessage(cleanServiceMsg), cleanServiceMsg);
    });
  });
}
