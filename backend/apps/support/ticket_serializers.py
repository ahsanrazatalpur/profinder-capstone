# apps/support/ticket_serializers.py
#
# Part 5: input validation + owner-facing output for support tickets.
#
# Output rules (security):
#   * Only fields the OWNER may see are ever serialized. Internal staff notes
#     (TicketMessage.is_internal), assignment, priority and the audit trail
#     (TicketEvent) are never included.
#   * Staff are identified only by `is_staff` (no name / e-mail leaks).

from django.db.models import Q
from rest_framework import serializers

from apps.bookings.models import Booking
from apps.support.models import SupportTicket

CATEGORY_KEYS = [key for key, _ in SupportTicket.CATEGORY_CHOICES]
MAX_SUBJECT = 150
MAX_BODY = 5000


class _ClientMetaMixin(serializers.Serializer):
    platform = serializers.CharField(max_length=20, required=False, allow_blank=True, default='')
    app_version = serializers.CharField(max_length=20, required=False, allow_blank=True, default='')
    app_language = serializers.CharField(max_length=10, required=False, allow_blank=True, default='')


class TicketCreateSerializer(_ClientMetaMixin):
    subject = serializers.CharField(max_length=MAX_SUBJECT)
    body = serializers.CharField(max_length=MAX_BODY)
    category = serializers.ChoiceField(choices=CATEGORY_KEYS, default='other')
    related_booking = serializers.IntegerField(required=False, allow_null=True, default=None)

    def validate_related_booking(self, value):
        """A ticket may only reference a booking the sender takes part in.
        The same generic error is used whether the booking is missing or
        belongs to someone else, so ids cannot be probed."""
        if value is None:
            return None
        user = self.context['request'].user
        booking = Booking.objects.filter(pk=value).filter(
            Q(customer_id=user.pk) | Q(professional_id=user.pk)).first()
        if booking is None:
            raise serializers.ValidationError('Booking not found.')
        return booking


class TicketReplySerializer(serializers.Serializer):
    body = serializers.CharField(max_length=MAX_BODY)


class GuestContactSerializer(_ClientMetaMixin):
    email = serializers.EmailField(max_length=254)
    subject = serializers.CharField(max_length=MAX_SUBJECT)
    body = serializers.CharField(max_length=MAX_BODY)
    category = serializers.ChoiceField(choices=CATEGORY_KEYS, default='other')
    # Honeypot: hidden in the UI, so a human leaves it empty. Bots fill it.
    website = serializers.CharField(max_length=200, required=False, allow_blank=True, default='')

    def validate_email(self, value):
        return value.strip().lower()


# ─── Output ──────────────────────────────────────────────────────────────────

def ticket_summary(ticket, last_is_staff=None):
    return {
        'id': ticket.pk,
        'reference': ticket.reference,
        'subject': ticket.subject,
        'category': ticket.category,
        'status': ticket.status,
        'created_at': ticket.created_at.isoformat(),
        'last_activity_at': ticket.last_activity_at.isoformat(),
        # True when the newest visible message is from support (UI shows "new reply").
        'last_message_is_staff': bool(last_is_staff),
    }


def ticket_detail(ticket):
    messages = [
        {
            'id': m.pk,
            'body': m.body,
            'is_staff': m.is_staff,
            'created_at': m.created_at.isoformat(),
        }
        for m in ticket.messages.filter(is_internal=False).order_by('created_at', 'pk')
    ]
    data = ticket_summary(ticket, last_is_staff=messages[-1]['is_staff'] if messages else False)
    data['related_booking'] = ticket.related_booking_id
    data['closed_at'] = ticket.closed_at.isoformat() if ticket.closed_at else None
    data['messages'] = messages
    return data
