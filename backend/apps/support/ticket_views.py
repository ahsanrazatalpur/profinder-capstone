# apps/support/ticket_views.py
#
# Part 5: support tickets, user side.
#
#   GET/POST  /api/support/tickets/                 own tickets / create
#   GET       /api/support/tickets/<id>/            own ticket + visible messages
#   POST      /api/support/tickets/<id>/messages/   reply
#   POST      /api/support/tickets/<id>/close/      owner closes the ticket
#   POST      /api/support/contact/                 guest (no login) message
#
# Security rules enforced here:
#   * Every ticket lookup is filtered by `user=request.user`; someone else's
#     ticket id answers 404 (same as a missing id), never 403.
#   * `is_internal` messages are never returned (see ticket_serializers).
#   * Admin notification failures never fail the user's request.

import logging
from datetime import timedelta

from django.db import transaction
from django.db.models import OuterRef, Subquery
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from apps.notifications.utils import notify_admins
from apps.support.models import SupportTicket, TicketEvent, TicketMessage
from apps.support.ticket_serializers import (
    GuestContactSerializer, TicketCreateSerializer, TicketReplySerializer,
    ticket_detail, ticket_summary,
)

logger = logging.getLogger(__name__)

ACTIVE_STATUSES = (
    SupportTicket.STATUS_OPEN,
    SupportTicket.STATUS_IN_PROGRESS,
    SupportTicket.STATUS_AWAITING_USER,
)
MAX_OPEN_TICKETS_PER_USER = 10
MAX_MESSAGES_PER_TICKET = 200
MAX_GUEST_TICKETS_PER_EMAIL_PER_DAY = 3
LIST_LIMIT = 50


def _notify_staff(title, message, ticket_id):
    """Best effort: runs after the DB transaction commits and never raises."""
    def _send():
        try:
            notify_admins(title, message, notif_type='general',
                          data={'support_ticket_id': ticket_id})
        except Exception:  # noqa: BLE001 - a failed push must not break support
            logger.exception('[SUPPORT] admin notification failed')
    transaction.on_commit(_send)


def _error(message, code, status):
    return Response({'error': message, 'code': code}, status=status)


class _Authenticated:
    permission_classes = [IsAuthenticated]
    throttle_classes = [ScopedRateThrottle]


class TicketListCreateView(_Authenticated, APIView):
    def get_throttles(self):
        # Only creating is rate limited; reading the list is not.
        self.throttle_scope = 'support_ticket_create' if self.request.method == 'POST' else None
        return super().get_throttles()

    def get(self, request):
        last_is_staff = (
            TicketMessage.objects
            .filter(ticket=OuterRef('pk'), is_internal=False)
            .order_by('-created_at', '-pk')
            .values('is_staff')[:1]
        )
        tickets = (
            SupportTicket.objects
            .filter(user=request.user)
            .annotate(last_is_staff=Subquery(last_is_staff))
            .order_by('-last_activity_at', '-pk')[:LIST_LIMIT]
        )
        return Response({'results': [ticket_summary(t, t.last_is_staff) for t in tickets]})

    def post(self, request):
        serializer = TicketCreateSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        open_count = SupportTicket.objects.filter(
            user=request.user, status__in=ACTIVE_STATUSES).count()
        if open_count >= MAX_OPEN_TICKETS_PER_USER:
            return _error('You already have many open tickets. Please wait for a reply '
                          'or close one before opening another.',
                          'too_many_open_tickets', 429)

        with transaction.atomic():
            ticket = SupportTicket.objects.create(
                user=request.user,
                role=request.user.role,
                category=data['category'],
                subject=data['subject'],
                related_booking=data['related_booking'],
                platform=data['platform'],
                app_version=data['app_version'],
                app_language=data['app_language'],
            )
            TicketMessage.objects.create(
                ticket=ticket, author=request.user, is_staff=False, body=data['body'])
            TicketEvent.objects.create(ticket=ticket, actor=request.user, action='created')
            _notify_staff('New support ticket',
                          f'{request.user.name}: {ticket.subject[:80]}', ticket.pk)

        return Response(ticket_detail(ticket), status=201)


class _OwnTicketMixin(_Authenticated):
    def own_ticket(self, request, pk, lock=False):
        qs = SupportTicket.objects.filter(user=request.user)
        if lock:
            qs = qs.select_for_update()
        return get_object_or_404(qs, pk=pk)


class TicketDetailView(_OwnTicketMixin, APIView):
    def get(self, request, pk):
        return Response(ticket_detail(self.own_ticket(request, pk)))


class TicketReplyView(_OwnTicketMixin, APIView):
    throttle_scope = 'support_ticket_reply'

    def post(self, request, pk):
        serializer = TicketReplySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        body = serializer.validated_data['body']

        with transaction.atomic():
            ticket = self.own_ticket(request, pk, lock=True)
            if ticket.status == SupportTicket.STATUS_CLOSED:
                return _error('This ticket is closed.', 'ticket_closed', 409)
            if ticket.messages.count() >= MAX_MESSAGES_PER_TICKET:
                return _error('This ticket has reached its message limit.',
                              'message_limit', 409)

            TicketMessage.objects.create(
                ticket=ticket, author=request.user, is_staff=False, body=body)

            now = timezone.now()
            fields = {'last_activity_at': now, 'updated_at': now}
            # Support is waiting on the user, or the user answers a "resolved"
            # ticket: it goes back to the staff queue.
            if ticket.status in (SupportTicket.STATUS_AWAITING_USER,
                                 SupportTicket.STATUS_RESOLVED):
                fields['status'] = SupportTicket.STATUS_OPEN
                TicketEvent.objects.create(
                    ticket=ticket, actor=request.user, action='reopened_by_reply',
                    detail=f'{ticket.status} -> open')
            else:
                TicketEvent.objects.create(ticket=ticket, actor=request.user, action='user_reply')
            SupportTicket.objects.filter(pk=ticket.pk).update(**fields)
            _notify_staff('Support ticket reply',
                          f'{request.user.name} replied regarding "{ticket.subject[:60]}"',
                          ticket.pk)

        ticket.refresh_from_db()
        return Response(ticket_detail(ticket), status=201)


class TicketCloseView(_OwnTicketMixin, APIView):
    throttle_scope = 'support_ticket_reply'

    def post(self, request, pk):
        with transaction.atomic():
            ticket = self.own_ticket(request, pk, lock=True)
            if ticket.status != SupportTicket.STATUS_CLOSED:   # idempotent
                now = timezone.now()
                SupportTicket.objects.filter(pk=ticket.pk).update(
                    status=SupportTicket.STATUS_CLOSED, closed_at=now,
                    last_activity_at=now, updated_at=now)
                TicketEvent.objects.create(
                    ticket=ticket, actor=request.user, action='closed_by_user',
                    detail=f'{ticket.status} -> closed')
        ticket.refresh_from_db()
        return Response(ticket_detail(ticket))


class GuestContactView(APIView):
    """Logged-out contact form. Creates a ticket with no user; the sender gets
    only a reference number back (no read access without an account)."""
    permission_classes = [AllowAny]
    authentication_classes = []      # a stale/bad token must not cause 401
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'support_guest_contact'

    def post(self, request):
        serializer = GuestContactSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        if data['website']:
            # Honeypot tripped: pretend success, store nothing.
            return Response({'status': 'received', 'reference': None}, status=201)

        since = timezone.now() - timedelta(days=1)
        recent = SupportTicket.objects.filter(
            user__isnull=True, contact_email=data['email'], created_at__gte=since).count()
        if recent >= MAX_GUEST_TICKETS_PER_EMAIL_PER_DAY:
            return _error('Too many messages from this address today. Please try again later.',
                          'too_many_requests', 429)

        with transaction.atomic():
            ticket = SupportTicket.objects.create(
                user=None,
                role='guest',
                contact_email=data['email'],
                category=data['category'],
                subject=data['subject'],
                platform=data['platform'],
                app_version=data['app_version'],
                app_language=data['app_language'],
            )
            TicketMessage.objects.create(
                ticket=ticket, author=None, is_staff=False, body=data['body'])
            TicketEvent.objects.create(ticket=ticket, actor=None, action='created_by_guest')
            _notify_staff('New guest support request',
                          f'{ticket.contact_email}: {ticket.subject[:80]}', ticket.pk)

        return Response({'status': 'received', 'reference': ticket.reference}, status=201)
