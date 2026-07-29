# PATH: backend/apps/messaging/models.py
#
# ✅ REBUILT — production-ready messaging foundation.
# Customer <-> Professional only (enforced at the view/serializer layer,
# since a cross-FK role constraint isn't natively expressible at the DB
# level without a trigger — see views.py's ConversationListView.post).

from django.db import models
from django.conf import settings


class Conversation(models.Model):
    """
    One conversation = exactly one customer <-> one professional pair.
    Created lazily the first time either side sends a message.
    """
    customer     = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='conversations_as_customer')
    professional = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='conversations_as_professional')
    created_at   = models.DateTimeField(auto_now_add=True)
    updated_at   = models.DateTimeField(auto_now=True)  # bumped on every new message — used to sort the list

    class Meta:
        unique_together = ('customer', 'professional')
        ordering = ['-updated_at']
        indexes = [
            models.Index(fields=['-updated_at'], name='conv_updated_at_idx'),
        ]

    def __str__(self):
        return f"{self.customer.email} <-> {self.professional.email}"


class Message(models.Model):
    STATUS_SENDING   = 'sending'    # client-side optimistic state only — never actually persisted as this
    STATUS_SENT      = 'sent'       # reached the server / saved to DB
    STATUS_DELIVERED = 'delivered'  # recipient's device has fetched it
    STATUS_SEEN      = 'seen'       # recipient has opened the conversation and read it

    STATUS_CHOICES = [
        (STATUS_SENDING,   'Sending'),
        (STATUS_SENT,      'Sent'),
        (STATUS_DELIVERED, 'Delivered'),
        (STATUS_SEEN,      'Seen'),
    ]

    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, related_name='messages')
    sender       = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='sent_messages')

    # Text is optional — a message can be image-only (see Attachment below)
    text = models.TextField(blank=True)

    # ✅ Reply / quote — points to another Message in the SAME conversation.
    # SET_NULL so replies don't cascade-delete if the original is removed.
    reply_to = models.ForeignKey('self', on_delete=models.SET_NULL, null=True, blank=True, related_name='replies')

    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default=STATUS_SENT, db_index=True)

    # ── Lifecycle timestamps ──────────────────────────────────────────
    created_at   = models.DateTimeField(auto_now_add=True)             # = "sent_at"
    delivered_at = models.DateTimeField(null=True, blank=True)
    read_at      = models.DateTimeField(null=True, blank=True)         # replaces the old boolean is_read
    edited_at    = models.DateTimeField(null=True, blank=True)
    deleted_at   = models.DateTimeField(null=True, blank=True)         # soft delete — row stays, content hidden

    class Meta:
        ordering = ['created_at']
        indexes = [
            models.Index(fields=['conversation', 'created_at'], name='msg_conv_created_idx'),
            models.Index(fields=['conversation', 'status'],     name='msg_conv_status_idx'),
        ]

    @property
    def is_edited(self):
        return self.edited_at is not None

    @property
    def is_deleted(self):
        return self.deleted_at is not None

    def __str__(self):
        preview = self.text[:30] if self.text else '[attachment]'
        return f"{self.sender.email}: {preview}"


class Attachment(models.Model):
    """
    Separate model (not a field on Message) so a single message can carry
    multiple files later, and so new file_type values (video, document...)
    can be added without touching the Message table.
    """
    FILE_TYPE_IMAGE = 'image'
    FILE_TYPE_AUDIO = 'audio'  # ✅ NEW — voice messages reuse this same model
    FILE_TYPE_CHOICES = [
        (FILE_TYPE_IMAGE, 'Image'),
        (FILE_TYPE_AUDIO, 'Audio'),
        # future: ('video', 'Video'), ('document', 'Document')
    ]

    message    = models.ForeignKey(Message, on_delete=models.CASCADE, related_name='attachments')
    # ✅ CHANGED: ImageField -> FileField (ImageField rejects non-image
    # files like .m4a/.aac voice notes at the Pillow-validation level)
    file       = models.FileField(upload_to='chat_attachments/')
    file_type  = models.CharField(max_length=20, choices=FILE_TYPE_CHOICES, default=FILE_TYPE_IMAGE)
    duration_seconds = models.PositiveIntegerField(null=True, blank=True)  # ✅ NEW — voice note length
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"Attachment #{self.id} on Message #{self.message_id}"


class UserPresence(models.Model):
    """
    One row per user. Updated via a lightweight "heartbeat" the client
    calls periodically while the app is foregrounded, plus explicitly
    on app close/background (best-effort).
    """
    user      = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='presence')
    is_online = models.BooleanField(default=False)
    last_seen = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.email} - {'online' if self.is_online else 'offline'}"


# ✅ NEW — Message reactions (❤️👍😂...). One reaction per user per
# message — tapping a different emoji REPLACES their existing one,
# tapping the same one again removes it (toggle), same as WhatsApp.
class Reaction(models.Model):
    message    = models.ForeignKey(Message, on_delete=models.CASCADE, related_name='reactions')
    user       = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='message_reactions')
    emoji      = models.CharField(max_length=8)  # a single emoji grapheme, e.g. "❤️"
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('message', 'user')

    def __str__(self):
        return f"{self.user.email} reacted {self.emoji} to Message #{self.message_id}"


# ✅ NEW — Pin / Archive / Mute / Draft — all PER USER PER CONVERSATION,
# so they're naturally one row each rather than 4 separate models. E.g.
# a customer can archive a conversation while the professional still
# sees it in their active list.
class ConversationUserState(models.Model):
    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, related_name='user_states')
    user         = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='conversation_states')

    is_pinned    = models.BooleanField(default=False)
    is_archived  = models.BooleanField(default=False)
    is_muted     = models.BooleanField(default=False)
    muted_until  = models.DateTimeField(null=True, blank=True)  # null + is_muted=True = muted forever

    draft_text   = models.TextField(blank=True)  # ✅ NEW — persisted "unsent" text, synced across devices
    updated_at   = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('conversation', 'user')

    @property
    def is_currently_muted(self):
        if not self.is_muted:
            return False
        if self.muted_until is None:
            return True
        from django.utils import timezone
        return timezone.now() < self.muted_until

    def __str__(self):
        return f"{self.user.email} state on Conversation #{self.conversation_id}"


# ✅ NEW — "Delete for me": the message stays intact for the OTHER
# participant; this user just no longer sees it. One row per
# (message, user) that chose to hide it.
class MessageDeletion(models.Model):
    message    = models.ForeignKey(Message, on_delete=models.CASCADE, related_name='deletions')
    user       = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='deleted_messages')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('message', 'user')


# ✅ NEW — Blocking. A blocks B → B's messages to A are rejected server-side
# and A won't receive push notifications from B (see views.py / push.py).
class BlockedUser(models.Model):
    blocker    = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='blocked_users')
    blocked    = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='blocked_by')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('blocker', 'blocked')

    def __str__(self):
        return f"{self.blocker.email} blocked {self.blocked.email}"


# ✅ NEW — Report a user, optionally pointing at a specific message as
# evidence. Reviewed by admins in the Django admin panel (no dedicated
# moderation UI requested — kept simple).
class UserReport(models.Model):
    REASON_SPAM        = 'spam'
    REASON_HARASSMENT  = 'harassment'
    REASON_INAPPROPRIATE = 'inappropriate'
    REASON_SCAM        = 'scam'
    REASON_OTHER       = 'other'
    REASON_CHOICES = [
        (REASON_SPAM,          'Spam'),
        (REASON_HARASSMENT,    'Harassment or bullying'),
        (REASON_INAPPROPRIATE, 'Inappropriate content'),
        (REASON_SCAM,          'Scam or fraud'),
        (REASON_OTHER,         'Other'),
    ]

    reporter     = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='reports_made')
    reported     = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='reports_received')
    reason       = models.CharField(max_length=20, choices=REASON_CHOICES)
    details      = models.TextField(blank=True)
    message      = models.ForeignKey(Message, on_delete=models.SET_NULL, null=True, blank=True, related_name='reports')
    created_at   = models.DateTimeField(auto_now_add=True)
    is_reviewed  = models.BooleanField(default=False)  # admin marks true once handled

    def __str__(self):
        return f"{self.reporter.email} reported {self.reported.email} ({self.reason})"