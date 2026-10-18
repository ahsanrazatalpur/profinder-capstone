# apps/support/admin_views.py
#
# Part 6a: support ticket inbox for admins (English-only staff tooling).
#
#   GET   /api/support/admin/tickets/summary/        counts for the inbox header
#   GET   /api/support/admin/tickets/                list + filters + search
#   GET   /api/support/admin/tickets/<id>/           full ticket (incl. internal notes)
#   PATCH /api/support/admin/tickets/<id>/           status / priority / assignee
#   POST  /api/support/admin/tickets/<id>/reply/     public reply or internal note
#
# Rules:
#   * Admin only (`user.role == 'admin'`), same check as admin_panel.
#   * Internal notes (is_internal) never reach the ticket owner and never bump
#     the ticket's user-facing `last_activity_at`.
#   * Notifying the user is best effort (after commit, never raises). Guest
#     tickets have no account, so the reply is e-mailed to `contact_email`.

import logging

from django.db import transaction
from django.db.models import OuterRef, Q, Subquery
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.utils.html import escape, linebreaks
from rest_framework import serializers
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.notifications.utils import notify_user
from apps.support.models import SupportTicket, TicketEvent, TicketMessage
from apps.support.ticket_serializers import MAX_BODY
from apps.users.brevo_email import send_brevo_email
from apps.users.models import User

logger = logging.getLogger(__name__)

ACTIVE_STATUSES = (
    SupportTicket.STATUS_OPEN,
    SupportTicket.STATUS_IN_PROGRESS,
    SupportTicket.STATUS_AWAITING_USER,
)
STATUS_KEYS = [k for k, _ in SupportTicket.STATUS_CHOICES]
PRIORITY_KEYS = [k for k, _ in SupportTicket.PRIORITY_CHOICES]
CATEGORY_KEYS = [k for k, _ in SupportTicket.CATEGORY_CHOICES]
DEFAULT_LIMIT = 30
MAX_LIMIT = 100


def _is_admin(user):
    return user.is_authenticated and user.role == 'admin'


def _forbidden():
    return Response({'error': 'Admin only.'}, status=403)


def _name(user):
    if user is None:
        return None
    return (getattr(user, 'name', '') or '').strip() or user.email


def _person(user):
    if user is None:
        return None
    return {'id': user.pk, 'name': _name(user), 'email': user.email, 'role': user.role}


# ─── Output ──────────────────────────────────────────────────────────────────

def _summary(ticket, last_public_is_staff=None):
    active = ticket.status in ACTIVE_STATUSES
    return {
        'id': ticket.pk,
        'reference': ticket.reference,
        'subject': ticket.subject,
        'category': ticket.category,
        'status': ticket.status,
        'priority': ticket.priority,
        'role': ticket.role,
        'requester': _person(ticket.user) if ticket.user_id else None,
        'contact_email': ticket.contact_email,
        'assigned_to': _person(ticket.assigned_to) if ticket.assigned_to_id else None,
        'created_at': ticket.created_at.isoformat(),
        'last_activity_at': ticket.last_activity_at.isoformat(),
        # Newest public message is from the user: the ball is in staff's court.
        'needs_reply': bool(active and last_public_is_staff is False),
    }


def _detail(ticket):
    msgs = ticket.messages.select_related('author').order_by('created_at', 'pk')
    messages = [{
        'id': m.pk,
        'body': m.body,
        'is_staff': m.is_staff,
        'is_internal': m.is_internal,
        'author_name': _name(m.author) if m.author_id else None,
        'created_at': m.created_at.isoformat(),
    } for m in msgs]
    public = [m for m in messages if not m['is_internal']]
    data = _summary(ticket, public[-1]['is_staff'] if public else None)
    data.update({
        'related_booking': ticket.related_booking_id,
        'platform': ticket.platform,
        'app_version': ticket.app_version,
        'app_language': ticket.app_language,
        'closed_at': ticket.closed_at.isoformat() if ticket.closed_at else None,
        'messages': messages,
        'events': [{
            'id': e.pk,
            'action': e.action,
            'detail': e.detail,
            'actor_name': _name(e.actor) if e.actor_id else None,
            'created_at': e.created_at.isoformat(),
        } for e in ticket.events.select_related('actor').order_by('created_at', 'pk')],
    })
    return data


# ─── Input ───────────────────────────────────────────────────────────────────

class ReplySerializer(serializers.Serializer):
    body = serializers.CharField(max_length=MAX_BODY)
    internal = serializers.BooleanField(required=False, default=False)


class UpdateSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=STATUS_KEYS, required=False)
    priority = serializers.ChoiceField(choices=PRIORITY_KEYS, required=False)
    # 'me' | null (unassign) | <admin user id>; validated in the view.
    assigned_to = serializers.JSONField(required=False, allow_null=True)


# ─── Notifications (best effort, after commit) ───────────────────────────────

def _after_commit(fn):
    def _run():
        try:
            fn()
        except Exception:  # noqa: BLE001 - never fail the admin's action over a notification
            logger.exception('[SUPPORT] notifying the ticket owner failed')
    transaction.on_commit(_run)


def _notify_owner(ticket, title, message):
    if ticket.user_id:
        _after_commit(lambda: notify_user(
            ticket.user, title, message, notif_type='general',
            data={'support_ticket_id': ticket.pk}))


def _email_guest(ticket, body):
    """Guest tickets have no account: the reply goes to the e-mail they gave."""
    if ticket.user_id or not ticket.contact_email:
        return
    subject = f'Re: [{ticket.reference}] {ticket.subject}'[:200]
    text = (f'{body}\n\n--\nProFinder Support\nReference: {ticket.reference}\n'
            'You can reply to this email to continue the conversation.')
    html = (f'{linebreaks(escape(body))}<p style="color:#64748b">ProFinder Support<br>'
            f'Reference: {escape(ticket.reference)}<br>'
            'You can reply to this email to continue the conversation.</p>')
    _after_commit(lambda: send_brevo_email(ticket.contact_email, '', subject, html, text))


# ─── Views ───────────────────────────────────────────────────────────────────

def _with_last_public(qs):
    last_is_staff = (TicketMessage.objects
                     .filter(ticket=OuterRef('pk'), is_internal=False)
                     .order_by('-created_at', '-pk')
                     .values('is_staff')[:1])
    return qs.annotate(last_public_is_staff=Subquery(last_is_staff))


class _AdminView(APIView):
    permission_classes = [IsAuthenticated]


class AdminTicketSummaryView(_AdminView):
    def get(self, request):
        if not _is_admin(request.user):
            return _forbidden()
        qs = SupportTicket.objects.all()
        data = {key: qs.filter(status=key).count() for key in STATUS_KEYS}
        active = qs.filter(status__in=ACTIVE_STATUSES)
        data['unassigned_active'] = active.filter(assigned_to__isnull=True).count()
        data['mine_active'] = active.filter(assigned_to=request.user).count()
        data['needs_reply'] = _with_last_public(active).filter(last_public_is_staff=False).count()
        return Response(data)


class AdminTicketListView(_AdminView):
    def get(self, request):
        if not _is_admin(request.user):
            return _forbidden()
        p = request.query_params
        qs = _with_last_public(SupportTicket.objects.select_related('user', 'assigned_to'))

        status = p.get('status')
        if status == 'active':
            qs = qs.filter(status__in=ACTIVE_STATUSES)
        elif status:
            if status not in STATUS_KEYS:
                return Response({'error': 'Invalid status.'}, status=400)
            qs = qs.filter(status=status)
        if p.get('priority'):
            if p['priority'] not in PRIORITY_KEYS:
                return Response({'error': 'Invalid priority.'}, status=400)
            qs = qs.filter(priority=p['priority'])
        if p.get('category'):
            if p['category'] not in CATEGORY_KEYS:
                return Response({'error': 'Invalid category.'}, status=400)
            qs = qs.filter(category=p['category'])

        assigned = p.get('assigned')
        if assigned == 'me':
            qs = qs.filter(assigned_to=request.user)
        elif assigned == 'unassigned':
            qs = qs.filter(assigned_to__isnull=True)
        elif assigned:
            if not assigned.isdigit():
                return Response({'error': 'Invalid assignee.'}, status=400)
            qs = qs.filter(assigned_to_id=int(assigned))

        if p.get('needs_reply') in ('1', 'true'):
            qs = qs.filter(status__in=ACTIVE_STATUSES, last_public_is_staff=False)

        q = (p.get('q') or '').strip()
        if q:
            qs = qs.filter(
                Q(reference__icontains=q) | Q(subject__icontains=q)
                | Q(contact_email__icontains=q) | Q(user__email__icontains=q)
                | Q(user__name__icontains=q))

        try:
            limit = min(max(int(p.get('limit', DEFAULT_LIMIT)), 1), MAX_LIMIT)
            offset = max(int(p.get('offset', 0)), 0)
        except ValueError:
            return Response({'error': 'Invalid paging.'}, status=400)

        qs = qs.order_by('-last_activity_at', '-pk')
        total = qs.count()
        rows = qs[offset:offset + limit]
        return Response({
            'count': total,
            'results': [_summary(t, t.last_public_is_staff) for t in rows],
        })


class AdminTicketDetailView(_AdminView):
    def get(self, request, pk):
        if not _is_admin(request.user):
            return _forbidden()
        ticket = get_object_or_404(
            SupportTicket.objects.select_related('user', 'assigned_to'), pk=pk)
        return Response(_detail(ticket))

    def patch(self, request, pk):
        if not _is_admin(request.user):
            return _forbidden()
        serializer = UpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        if not data:
            return Response({'error': 'Nothing to update.'}, status=400)

        new_assignee = None
        assignee_given = 'assigned_to' in data
        if assignee_given:
            raw = data['assigned_to']
            if raw is None:
                new_assignee = None
            elif raw == 'me':
                new_assignee = request.user
            elif isinstance(raw, int) and not isinstance(raw, bool):
                new_assignee = User.objects.filter(pk=raw, role='admin', is_active=True).first()
                if new_assignee is None:
                    return Response({'error': 'Assignee must be an active admin.'}, status=400)
            else:
                return Response({'error': 'Invalid assignee.'}, status=400)

        with transaction.atomic():
            ticket = get_object_or_404(
                SupportTicket.objects.select_for_update(of=('self',)).select_related('user', 'assigned_to'),
                pk=pk)
            fields = {}
            now = timezone.now()

            if 'status' in data and data['status'] != ticket.status:
                new = data['status']
                TicketEvent.objects.create(
                    ticket=ticket, actor=request.user, action='status_changed',
                    detail=f'{ticket.status} -> {new}')
                fields['status'] = new
                fields['closed_at'] = now if new == SupportTicket.STATUS_CLOSED else None
                fields['last_activity_at'] = now
                if new in (SupportTicket.STATUS_RESOLVED, SupportTicket.STATUS_CLOSED):
                    label = 'resolved' if new == SupportTicket.STATUS_RESOLVED else 'closed'
                    _notify_owner(ticket, f'Support ticket {label}',
                                  f'Your support request regarding "{ticket.subject}" was marked as {label}.')

            if 'priority' in data and data['priority'] != ticket.priority:
                TicketEvent.objects.create(
                    ticket=ticket, actor=request.user, action='priority_changed',
                    detail=f'{ticket.priority} -> {data["priority"]}')
                fields['priority'] = data['priority']

            if assignee_given and (new_assignee.pk if new_assignee else None) != ticket.assigned_to_id:
                TicketEvent.objects.create(
                    ticket=ticket, actor=request.user, action='assigned',
                    detail=f'{_name(ticket.assigned_to) or "nobody"} -> '
                           f'{_name(new_assignee) or "nobody"}'[:300])
                fields['assigned_to'] = new_assignee

            if fields:
                fields['updated_at'] = now
                SupportTicket.objects.filter(pk=ticket.pk).update(**fields)

        ticket = SupportTicket.objects.select_related('user', 'assigned_to').get(pk=pk)
        return Response(_detail(ticket))


class AdminTicketReplyView(_AdminView):
    def post(self, request, pk):
        if not _is_admin(request.user):
            return _forbidden()
        serializer = ReplySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        body = serializer.validated_data['body']
        internal = serializer.validated_data['internal']

        with transaction.atomic():
            ticket = get_object_or_404(
                SupportTicket.objects.select_for_update(of=('self',)).select_related('user', 'assigned_to'),
                pk=pk)
            if not internal and ticket.status == SupportTicket.STATUS_CLOSED:
                return Response({'error': 'This ticket is closed. Reopen it before replying.',
                                 'code': 'ticket_closed'}, status=409)

            TicketMessage.objects.create(
                ticket=ticket, author=request.user, is_staff=True,
                is_internal=internal, body=body)

            if internal:
                # Internal notes are invisible to the user: no activity bump,
                # no status change, no notification.
                TicketEvent.objects.create(ticket=ticket, actor=request.user,
                                           action='internal_note')
            else:
                now = timezone.now()
                fields = {'last_activity_at': now, 'updated_at': now}
                if ticket.status in (SupportTicket.STATUS_OPEN, SupportTicket.STATUS_IN_PROGRESS):
                    fields['status'] = SupportTicket.STATUS_AWAITING_USER
                if ticket.assigned_to_id is None:
                    fields['assigned_to'] = request.user
                TicketEvent.objects.create(ticket=ticket, actor=request.user,
                                           action='staff_reply')
                SupportTicket.objects.filter(pk=ticket.pk).update(**fields)
                _notify_owner(ticket, 'Support reply',
                              f'You have a new reply regarding your support request "{ticket.subject}".')
                _email_guest(ticket, body)

        ticket = SupportTicket.objects.select_related('user', 'assigned_to').get(pk=pk)
        return Response(_detail(ticket), status=201)
