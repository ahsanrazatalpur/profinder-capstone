// Unit tests for the admin Trust & Safety layer (Part 7).
// Pure model / mapping logic: no widgets, no network.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profinder_app/features/admin/models/ts_models.dart';
import 'package:profinder_app/features/admin/services/trust_safety_service.dart';
import 'package:profinder_app/features/admin/widgets/ts_ui.dart';
import 'package:profinder_app/l10n/generated/app_localizations_en.dart';

DioException _dioError(int? status, {dynamic data, DioExceptionType? type}) {
  final req = RequestOptions(path: '/x');
  return DioException(
    requestOptions: req,
    type: type ?? DioExceptionType.badResponse,
    response: status == null
        ? null
        : Response<dynamic>(requestOptions: req, statusCode: status, data: data),
  );
}

void main() {
  final l = AppLocalizationsEn();

  group('TsReport.fromJson', () {
    final legacy = <String, dynamic>{
      'id': 7,
      'reason': 'harassment',
      'reason_display': 'Harassment',
      'description': 'rude messages',
      'status': 'pending',
      'admin_note': '',
      'created_at': '2026-09-20T10:00:00Z',
      'reporter_name': 'Rita',
      'reporter_email': 'rita@example.com',
      'reported_user': 42,
      'reported_user_name': 'Omar',
      'reported_user_email': 'omar@example.com',
      'reported_user_role': 'professional',
      'reported_user_active': false,
    };

    test('tolerates a backend without the Part 7 fields', () {
      final r = TsReport.fromJson(legacy);
      expect(r.id, 7);
      expect(r.category, 'harassment');
      expect(r.severity, isNull);
      expect(r.hasEvidence, isFalse);
      expect(r.hasBooking, isFalse);
      expect(r.hasMessage, isFalse);
      expect(r.reportedUserActive, isFalse);
      expect(r.createdAt!.toUtc(), DateTime.utc(2026, 9, 20, 10));
    });

    test('parses severity, evidence and related booking / message', () {
      final r = TsReport.fromJson({
        ...legacy,
        'severity': 'critical',
        'evidence_url': 'https://example.com/p.png',
        'related_booking': 3,
        'related_booking_detail': {
          'id': 3,
          'status': 'pending',
          'status_display': 'Pending',
          'date': '2026-10-01',
          'time': '10:30',
          'customer_name': 'Rita',
          'professional_name': 'Omar',
        },
        'related_message': 9,
        'related_message_detail': {
          'id': 9,
          'conversation_id': 1,
          'sender_id': 42,
          'sender_name': 'Omar',
          'text': 'pay me off-platform',
          'created_at': '2026-09-19T08:00:00Z',
          'is_deleted': false,
          'attachment_count': 2,
        },
      });
      expect(r.severity, 'critical');
      expect(r.hasEvidence, isTrue);
      expect(r.relatedBooking!.time, '10:30');
      expect(r.relatedBooking!.professionalName, 'Omar');
      expect(r.relatedMessage!.text, 'pay me off-platform');
      expect(r.relatedMessage!.attachmentCount, 2);
      expect(r.relatedMessage!.isDeleted, isFalse);
    });

    test('a booking id without a detail object still counts as related', () {
      final r = TsReport.fromJson({...legacy, 'related_booking': 5});
      expect(r.hasBooking, isTrue);
      expect(r.relatedBooking, isNull);
    });

    test('isResolved / targetIsAdmin', () {
      expect(TsReport.fromJson({...legacy, 'status': 'dismissed'}).isResolved, isTrue);
      expect(TsReport.fromJson({...legacy, 'status': 'reviewed'}).isResolved, isFalse);
      expect(TsReport.fromJson({...legacy, 'reported_user_role': 'admin'}).targetIsAdmin, isTrue);
    });
  });

  group('ModerationAction', () {
    ModerationAction make(String state) => ModerationAction.fromJson({
          'id': 1,
          'action_type': 'suspend_temporary',
          'status': state,
          'reason': 'r',
          'performed_by_name': 'Admin A',
        });

    test('only active / scheduled actions are reversible', () {
      expect(make('active').isReversible, isTrue);
      expect(make('scheduled').isReversible, isTrue);
      expect(make('expired').isReversible, isFalse);
      expect(make('reversed').isReversible, isFalse);
    });

    test('performedByLabel prefers name, falls back to email', () {
      expect(make('active').performedByLabel, 'Admin A');
      final noName = ModerationAction.fromJson({
        'id': 2,
        'action_type': 'warning',
        'status': 'active',
        'performed_by_email': 'a@x.com',
      });
      expect(noName.performedByLabel, 'a@x.com');
    });
  });

  group('TsAppeal.fromJson', () {
    test('parses nested moderation_action_detail', () {
      final a = TsAppeal.fromJson({
        'id': 4,
        'status': 'pending',
        'user': 42,
        'user_name': 'Omar',
        'user_email': 'omar@example.com',
        'moderation_action': 11,
        'moderation_action_detail': {
          'id': 11,
          'action_type': 'restrict_messaging',
          'status': 'active',
          'reason': 'spam',
        },
        'reason': 'I did nothing wrong',
        'evidence_url': '',
        'decision_note': '',
      });
      expect(a.isPending, isTrue);
      expect(a.hasEvidence, isFalse);
      expect(a.action!.actionType, ActionType.restrictMessaging);
      expect(a.action!.isReversible, isTrue);
    });
  });

  group('vocabulary helpers', () {
    test('severity ranks critical highest and unknown lowest', () {
      expect(Severity.rank('critical'), greaterThan(Severity.rank('high')));
      expect(Severity.rank('high'), greaterThan(Severity.rank('medium')));
      expect(Severity.rank('medium'), greaterThan(Severity.rank('low')));
      expect(Severity.rank(null), 0);
    });

    test('action type expiry rules', () {
      expect(ActionType.isSuspension(ActionType.suspendTemporary), isTrue);
      expect(ActionType.isSuspension(ActionType.suspendPermanent), isTrue);
      expect(ActionType.isSuspension(ActionType.warning), isFalse);
      expect(ActionType.allowsOptionalExpiry(ActionType.restrictBooking), isTrue);
      expect(ActionType.allowsOptionalExpiry(ActionType.suspendTemporary), isFalse);
    });
  });

  group('TsApiException.fromDio', () {
    test('uses the backend error message on 409', () {
      final e = TsApiException.fromDio(_dioError(409, data: {'error': 'Already active'}));
      expect(e.isConflict, isTrue);
      expect(e.message, 'Already active');
      expect(tsErrorMessage(l, e), 'Already active');
    });

    test('flattens DRF field errors', () {
      final e = TsApiException.fromDio(_dioError(400, data: {
        'expires_at': ['Must be in the future.'],
      }));
      expect(e.fieldErrors['expires_at'], 'Must be in the future.');
      expect(e.message, 'Must be in the future.');
    });

    test('403 and network failures use localized copy', () {
      final forbidden = TsApiException.fromDio(_dioError(403, data: {'detail': 'nope'}));
      expect(tsErrorMessage(l, forbidden), l.tsErrForbidden);
      final offline = TsApiException.fromDio(
        _dioError(null, type: DioExceptionType.connectionError),
      );
      expect(offline.isNetwork, isTrue);
      expect(tsErrorMessage(l, offline), l.tsErrNetwork);
    });

    test('5xx and unknown errors fall back to the generic message', () {
      final e = TsApiException.fromDio(_dioError(500, data: {'error': 'boom'}));
      expect(tsErrorMessage(l, e), l.tsErrGeneric);
      expect(tsErrorMessage(l, StateError('x')), l.tsErrGeneric);
    });
  });

  group('localized labels cover every backend code', () {
    test('categories, statuses, severities, actions, states, appeals, roles', () {
      for (final c in ReportCategory.all) {
        expect(tsCategoryLabel(l, c), isNot(c), reason: 'category $c');
      }
      for (final c in ReportStatus.all) {
        expect(tsStatusLabel(l, c), isNot(c), reason: 'status $c');
      }
      for (final c in Severity.all) {
        expect(tsSeverityLabel(l, c), isNot(c), reason: 'severity $c');
      }
      for (final c in ActionType.all) {
        expect(tsActionTypeLabel(l, c), isNot(c), reason: 'action $c');
        expect(tsActionTypeDescription(l, c), isNotEmpty, reason: 'desc $c');
      }
      for (final c in const ['active', 'scheduled', 'expired', 'reversed']) {
        expect(tsStateLabel(l, c), isNot(c), reason: 'state $c');
      }
      for (final c in AppealStatus.all) {
        expect(tsAppealStatusLabel(l, c), isNot(c), reason: 'appeal $c');
      }
      for (final c in const ['customer', 'professional', 'admin']) {
        expect(tsRoleLabel(l, c), isNot(c), reason: 'role $c');
      }
    });

    test('unknown future codes fall back to backend display, then the code', () {
      expect(tsStatusLabel(l, 'escalated', fallback: 'Escalated'), 'Escalated');
      expect(tsStatusLabel(l, 'escalated'), 'escalated');
    });
  });
}