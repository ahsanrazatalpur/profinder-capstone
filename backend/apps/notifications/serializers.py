from rest_framework import serializers
from apps.notifications.models import Notification


def resolve_target_type(notif_type, title, message):
    """
    Which part of the app a notification belongs to, so the app can open the
    right screen when it is tapped. Returns one of:
    'booking', 'payment', 'review', 'subscription', 'report', 'appeal',
    'professional_signup', 'support', 'general'.

    This runs on the ORIGINAL (English) text, before the response is
    machine-translated, so it works for every app language. The field name ends
    in `_type`, which the translation middleware never touches. What each value
    opens depends on the viewer's role and is decided in the app.
    """
    text_title = (title or '').lower()
    text_message = (message or '').lower()
    if notif_type == 'report' and 'appeal' in text_title:
        return 'appeal'
    if notif_type in ('payment', 'review', 'subscription', 'report'):
        return notif_type
    if text_title.startswith('new professional signup'):
        return 'professional_signup'
    if 'support' in text_title:
        return 'support'
    if 'booking' in text_title or 'booking' in text_message or 'booked' in text_message:
        return 'booking'
    return 'general'


class NotificationSerializer(serializers.ModelSerializer):
    target_type = serializers.SerializerMethodField()

    class Meta:
        model = Notification
        fields = ['id', 'user', 'title', 'message', 'type', 'target_type',
                  'is_read', 'created_at']
        read_only_fields = ['user', 'created_at']

    def get_target_type(self, obj):
        return resolve_target_type(obj.type, obj.title, obj.message)