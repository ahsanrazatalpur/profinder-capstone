# apps/admin_panel/serializers.py

from django.utils import timezone
from rest_framework import serializers
from apps.admin_panel.models import (
    AdminLog, PromoBanner, UserReport, Complaint, NotificationBroadcast,
    Language, TranslationKey, TranslationString,
    Country, City, Announcement, ModerationAction, Appeal,
)
from apps.admin_panel.moderation import action_status, STATUS_ACTIVE
from apps.users.models import User


class AdminLogSerializer(serializers.ModelSerializer):
    admin_email       = serializers.EmailField(source='admin.email',       read_only=True)
    admin_name        = serializers.CharField(source='admin.name',         read_only=True)
    target_user_email = serializers.SerializerMethodField()
    target_user_name  = serializers.SerializerMethodField()

    class Meta:
        model  = AdminLog
        fields = [
            'id', 'action', 'note', 'created_at',
            'admin_email', 'admin_name',
            'target_user_email', 'target_user_name',
        ]

    def get_target_user_email(self, obj):
        return obj.target_user.email if obj.target_user else None

    def get_target_user_name(self, obj):
        return obj.target_user.name if obj.target_user else None


class PromoBannerSerializer(serializers.ModelSerializer):
    is_currently_active = serializers.SerializerMethodField()

    class Meta:
        model  = PromoBanner
        fields = [
            'id', 'title', 'description', 'image_url',
            'button_text', 'button_link_type', 'button_link_value',
            'target_audience', 'trigger', 'trigger_x_days',
            'is_active', 'priority', 'start_date', 'end_date',
            'is_currently_active', 'created_at', 'updated_at',
        ]

    def get_is_currently_active(self, obj):
        return obj.is_currently_active()


class UserReportSerializer(serializers.ModelSerializer):
    """
    Admin-facing view of a report — full context: kisne kisko report kiya,
    kyun, aur ab tak kya action liya gaya.
    """
    reporter_name        = serializers.CharField(source='reporter.name',  read_only=True)
    reporter_email       = serializers.EmailField(source='reporter.email', read_only=True)
    reported_user_name   = serializers.CharField(source='reported_user.name',  read_only=True)
    reported_user_email  = serializers.EmailField(source='reported_user.email', read_only=True)
    reported_user_role   = serializers.CharField(source='reported_user.role',   read_only=True)
    reported_user_active = serializers.BooleanField(source='reported_user.is_active', read_only=True)
    reviewed_by_email    = serializers.SerializerMethodField()
    reason_display        = serializers.CharField(source='get_reason_display', read_only=True)
    status_display        = serializers.CharField(source='get_status_display', read_only=True)
    # Trust & Safety Part 7 (additive, read-only): fields that already existed on
    # the model but were never exposed, so the admin UI can show priority,
    # evidence and the booking/message a report refers to.
    severity_display      = serializers.CharField(source='get_severity_display', read_only=True)
    related_booking_detail = serializers.SerializerMethodField()
    related_message_detail = serializers.SerializerMethodField()

    class Meta:
        model  = UserReport
        fields = [
            'id', 'reason', 'reason_display', 'description',
            'status', 'status_display', 'admin_note',
            'created_at', 'reviewed_at',
            'reporter_name', 'reporter_email',
            'reported_user', 'reported_user_name', 'reported_user_email',
            'reported_user_role', 'reported_user_active',
            'reviewed_by_email',
            'severity', 'severity_display', 'evidence_url',
            'related_booking', 'related_booking_detail',
            'related_message', 'related_message_detail',
        ]
        read_only_fields = ['severity', 'evidence_url', 'related_booking', 'related_message']

    def get_reviewed_by_email(self, obj):
        return obj.reviewed_by.email if obj.reviewed_by else None

    def get_related_booking_detail(self, obj):
        """Compact booking summary for admins. No booking note / contact data."""
        b = obj.related_booking
        if b is None:
            return None
        return {
            'id': b.pk,
            'status': b.status,
            'status_display': b.get_status_display(),
            'date': b.date.isoformat() if b.date else None,
            'time': b.time.strftime('%H:%M') if b.time else None,
            'customer_name': b.customer.name,
            'professional_name': b.professional.name,
        }

    def get_related_message_detail(self, obj):
        """
        Compact summary of the message a report cites. A message that was
        deleted for everyone keeps its row but its content stays hidden here
        too; only a flag is returned.
        """
        m = obj.related_message
        if m is None:
            return None
        deleted = m.deleted_at is not None
        text = '' if deleted else (m.text or '')
        if len(text) > 1000:
            text = text[:999] + '\u2026'
        return {
            'id': m.pk,
            'conversation_id': m.conversation_id,
            'sender_id': m.sender_id,
            'sender_name': m.sender.name,
            'text': text,
            'created_at': m.created_at.isoformat(),
            'is_deleted': deleted,
            'attachment_count': len(m.attachments.all()),
        }


class CreateUserReportSerializer(serializers.ModelSerializer):
    """
    Ye serializer regular users (customer/professional) use karte hain jab
    woh kisi user ko report karte hain.
    POST /api/admin-panel/reports/create/

    Trust & Safety Part 8 (additive): `evidence_url` was already a real,
    optional column on `UserReport` (a reference link, e.g. to an existing
    chat attachment — see the model docstring) but this serializer never
    exposed it, so a reporting user had no way to attach one even though the
    admin-facing `UserReportSerializer` already reads and displays it.
    Adding it here is purely additive: existing clients that omit it keep
    working exactly as before. `severity` is intentionally NOT exposed here
    — it's admin-assigned moderation priority, never user-set (see the
    model's help_text).
    """
    class Meta:
        model  = UserReport
        fields = ['reported_user', 'reason', 'description', 'evidence_url']
        extra_kwargs = {
            'evidence_url': {'required': False, 'allow_blank': True},
        }

    def validate_reported_user(self, value):
        request = self.context.get('request')
        if request and value == request.user:
            raise serializers.ValidationError("You can't report yourself.")
        return value

    def validate_evidence_url(self, value):
        # Mirrors AppealSubmitSerializer.validate_evidence_url — a reference
        # admins will open directly, so keep it web-only.
        if value and not value.lower().startswith(('http://', 'https://')):
            raise serializers.ValidationError('Enter a valid http or https URL.')
        return value


class MyUserReportSerializer(serializers.ModelSerializer):
    """
    Trust & Safety Part 8: what the REPORTING user sees about a report THEY
    submitted. Deliberately a much narrower view than `UserReportSerializer`
    (the admin-facing one) — this is the one contract rule the whole "My
    Reports" screen rests on, so it is spelled out field-by-field:

    Shown:  category (reason), description, submission date, status, and a
            plain-language general outcome derived from status only.
    NEVER shown here, on purpose:
      * the reported user's identity or any of their private information
        (name/email/role/active-state) — this serializer doesn't even
        declare `reported_user`;
      * `admin_note` — internal reviewer notes;
      * the exact moderation punishment handed to the reported user (their
        moderation history is a different user's private record) — only a
        generic "action was taken" / "no action" outcome is derived;
      * `reviewed_by` — the reviewing admin's identity;
      * `related_booking` / `related_message` detail — internal review
        context, not something the reporter submitted or is entitled to see
        back.
    """
    category         = serializers.CharField(source='reason', read_only=True)
    category_display = serializers.CharField(source='get_reason_display', read_only=True)
    status_display   = serializers.CharField(source='get_status_display', read_only=True)
    outcome          = serializers.SerializerMethodField()

    class Meta:
        model  = UserReport
        fields = [
            'id', 'category', 'category_display', 'description',
            'status', 'status_display', 'outcome', 'created_at',
        ]
        read_only_fields = fields

    _OUTCOME_CODES = {
        'pending':      'pending',
        'reviewed':     'reviewed_no_action',
        'action_taken': 'action_taken',
        'dismissed':    'dismissed',
    }

    def get_outcome(self, obj):
        """
        A general, non-specific outcome code — never the punishment itself.
        'action_taken' only ever tells the reporter that *something* was
        done in response to their report, never what that was.
        """
        return self._OUTCOME_CODES.get(obj.status, 'pending')


class ComplaintSerializer(serializers.ModelSerializer):
    complainant_name  = serializers.CharField(source='complainant.name',  read_only=True)
    complainant_email = serializers.EmailField(source='complainant.email', read_only=True)
    against_name       = serializers.CharField(source='against.name',  read_only=True)
    against_email      = serializers.EmailField(source='against.email', read_only=True)
    assigned_to_name    = serializers.SerializerMethodField()
    category_display     = serializers.CharField(source='get_category_display', read_only=True)
    status_display        = serializers.CharField(source='get_status_display', read_only=True)
    booking_date          = serializers.SerializerMethodField()

    class Meta:
        model  = Complaint
        fields = [
            'id', 'category', 'category_display', 'description',
            'status', 'status_display', 'resolution_note',
            'created_at', 'resolved_at',
            'complainant_name', 'complainant_email',
            'against', 'against_name', 'against_email',
            'assigned_to_name', 'booking', 'booking_date',
        ]

    def get_assigned_to_name(self, obj):
        return obj.assigned_to.name if obj.assigned_to else None

    def get_booking_date(self, obj):
        return str(obj.booking.date) if obj.booking else None


class NotificationBroadcastSerializer(serializers.ModelSerializer):
    audience_display     = serializers.CharField(source='get_audience_display', read_only=True)
    status_display       = serializers.CharField(source='get_status_display', read_only=True)
    specific_user_name   = serializers.CharField(source='specific_user.name', read_only=True, default=None)
    created_by_name       = serializers.CharField(source='created_by.name', read_only=True, default=None)
    open_rate            = serializers.SerializerMethodField()

    class Meta:
        model  = NotificationBroadcast
        fields = [
            'id', 'title', 'message', 'audience', 'audience_display',
            'specific_user', 'specific_user_name',
            'status', 'status_display', 'scheduled_at', 'sent_at',
            'sent_count', 'opened_count', 'open_rate',
            'created_by_name', 'created_at',
        ]

    def get_open_rate(self, obj):
        if not obj.sent_count:
            return 0
        return round(obj.opened_count * 100 / obj.sent_count, 1)


class LanguageSerializer(serializers.ModelSerializer):
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    completion_percentage = serializers.SerializerMethodField()

    class Meta:
        model  = Language
        fields = ['id', 'name', 'code', 'is_rtl', 'status', 'status_display',
                   'completion_percentage', 'created_at']

    def get_completion_percentage(self, obj):
        total = TranslationKey.objects.count()
        if total == 0:
            return 0
        translated = TranslationString.objects.filter(
            language=obj).exclude(text='').count()
        return round(translated * 100 / total, 1)


class CountrySerializer(serializers.ModelSerializer):
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    user_count       = serializers.SerializerMethodField()
    professional_count = serializers.SerializerMethodField()
    city_count       = serializers.SerializerMethodField()

    class Meta:
        model  = Country
        fields = ['id', 'name', 'status', 'status_display', 'user_count',
                   'professional_count', 'city_count', 'created_at']

    def get_user_count(self, obj):
        from apps.profiles.models import UserProfile
        return UserProfile.objects.filter(country__iexact=obj.name).count()

    def get_professional_count(self, obj):
        from apps.profiles.models import UserProfile
        return UserProfile.objects.filter(
            country__iexact=obj.name, user__role='professional').count()

    def get_city_count(self, obj):
        return obj.cities.count()


class CitySerializer(serializers.ModelSerializer):
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    country_name   = serializers.CharField(source='country.name', read_only=True)
    user_count       = serializers.SerializerMethodField()
    professional_count = serializers.SerializerMethodField()

    class Meta:
        model  = City
        fields = ['id', 'name', 'country', 'country_name', 'status', 'status_display',
                   'user_count', 'professional_count', 'created_at']

    def get_user_count(self, obj):
        from apps.profiles.models import UserProfile
        return UserProfile.objects.filter(city__iexact=obj.name).count()

    def get_professional_count(self, obj):
        from apps.profiles.models import UserProfile
        return UserProfile.objects.filter(
            city__iexact=obj.name, user__role='professional').count()


class AnnouncementSerializer(serializers.ModelSerializer):
    type_display     = serializers.CharField(source='get_type_display', read_only=True)
    audience_display = serializers.CharField(source='get_audience_display', read_only=True)
    created_by_name  = serializers.CharField(source='created_by.name', read_only=True, default=None)

    class Meta:
        model  = Announcement
        fields = ['id', 'title', 'message', 'type', 'type_display',
                   'audience', 'audience_display', 'is_active',
                   'start_date', 'end_date', 'created_by_name', 'created_at']


# ── Moderation actions (Trust & Safety Part 4) ────────────────────────────────

class ModerationActionSerializer(serializers.ModelSerializer):
    """
    Read-only, admin-facing view of a moderation action, including its full
    lifecycle (created -> in force / expired / reversed) and who did what.
    Every field is read-only: this serializer is never used to write.
    """
    action_type_display = serializers.CharField(source='get_action_type_display', read_only=True)
    target_user_name    = serializers.CharField(source='target_user.name',  read_only=True)
    target_user_email   = serializers.EmailField(source='target_user.email', read_only=True)
    performed_by_name   = serializers.SerializerMethodField()
    performed_by_email  = serializers.SerializerMethodField()
    reversed_by_name    = serializers.SerializerMethodField()
    reversed_by_email   = serializers.SerializerMethodField()
    status              = serializers.SerializerMethodField()
    is_in_effect        = serializers.SerializerMethodField()

    class Meta:
        model  = ModerationAction
        fields = [
            'id', 'action_type', 'action_type_display', 'status', 'is_in_effect',
            'target_user', 'target_user_name', 'target_user_email',
            'report',
            'performed_by', 'performed_by_name', 'performed_by_email',
            'reason', 'admin_note',
            'starts_at', 'expires_at', 'is_active', 'created_at',
            'reversed_at', 'reversed_by', 'reversed_by_name', 'reversed_by_email',
            'reversal_reason', 'legacy_ban_applied',
        ]
        read_only_fields = fields

    # `status` is derived on each call (never stored), so it can't go stale.
    def _status(self, obj):
        return action_status(obj)

    def get_status(self, obj):
        return self._status(obj)

    def get_is_in_effect(self, obj):
        return self._status(obj) == STATUS_ACTIVE

    def get_performed_by_name(self, obj):
        return obj.performed_by.name if obj.performed_by else None

    def get_performed_by_email(self, obj):
        return obj.performed_by.email if obj.performed_by else None

    def get_reversed_by_name(self, obj):
        return obj.reversed_by.name if obj.reversed_by else None

    def get_reversed_by_email(self, obj):
        return obj.reversed_by.email if obj.reversed_by else None


class MyModerationActionSerializer(serializers.ModelSerializer):
    """
    Trust & Safety Part 8: what the AFFECTED user sees about a moderation
    action taken against THEMSELVES — for the "Account Moderation Status"
    screen. Unlike `ModerationActionSerializer` (admin-facing), this
    deliberately excludes the acting admin's identity (`performed_by_*`),
    the internal `admin_note`, and `report` (which would reveal that/which
    report triggered it) — mirroring the same restraint `MyAppealSerializer`
    already applies for appeals. `reason` IS included: it is the rationale
    for the action taken against this specific user, which the task
    requires showing them (not "internal moderation history" about anyone
    else).

    `can_appeal` / `has_pending_appeal` are computed by the view (via
    context) from that user's own Appeal rows, so this serializer never
    queries per-row.
    """
    action_type_display = serializers.CharField(source='get_action_type_display', read_only=True)
    status               = serializers.SerializerMethodField()
    can_appeal           = serializers.SerializerMethodField()
    has_pending_appeal   = serializers.SerializerMethodField()

    class Meta:
        model  = ModerationAction
        fields = [
            'id', 'action_type', 'action_type_display', 'status',
            'reason', 'starts_at', 'expires_at', 'created_at',
            'can_appeal', 'has_pending_appeal',
        ]
        read_only_fields = fields

    def get_status(self, obj):
        return action_status(obj)

    def get_has_pending_appeal(self, obj):
        pending_ids = self.context.get('pending_appeal_action_ids', set())
        return obj.pk in pending_ids

    def get_can_appeal(self, obj):
        return self.get_status(obj) == STATUS_ACTIVE and not self.get_has_pending_appeal(obj)


class CreateModerationActionSerializer(serializers.Serializer):
    """
    Input for POST /api/admin-panel/moderation-actions/.

    A plain Serializer (not a ModelSerializer) on purpose: only the fields
    below are ever read from the client. `performed_by`, `is_active`,
    `starts_at`, `created_at` and the reversal fields are not declared, so a
    client that sends them has them ignored — they are set by server logic
    in `apps.admin_panel.moderation` only.
    """
    target_user = serializers.PrimaryKeyRelatedField(queryset=User.objects.all())
    action_type = serializers.ChoiceField(choices=ModerationAction.ACTION_CHOICES)
    reason      = serializers.CharField(max_length=2000, trim_whitespace=True)
    admin_note  = serializers.CharField(
        max_length=2000, required=False, allow_blank=True, trim_whitespace=True)
    report      = serializers.PrimaryKeyRelatedField(
        queryset=UserReport.objects.select_related('reported_user'),
        required=False, allow_null=True)
    expires_at  = serializers.DateTimeField(required=False, allow_null=True)

    def validate_target_user(self, user):
        request = self.context.get('request')
        if request and user.pk == request.user.pk:
            raise serializers.ValidationError('You cannot take a moderation action against yourself.')
        if user.role == 'admin':
            raise serializers.ValidationError('Moderation actions cannot target admin accounts.')
        return user

    def validate(self, attrs):
        action_type = attrs['action_type']
        expires_at  = attrs.get('expires_at')
        errors = {}

        if action_type == ModerationAction.ACTION_SUSPEND_TEMPORARY:
            if expires_at is None:
                errors['expires_at'] = 'A temporary suspension requires an expiration time.'
        elif action_type == ModerationAction.ACTION_SUSPEND_PERMANENT:
            if expires_at is not None:
                errors['expires_at'] = 'A permanent suspension must not have an expiration time.'

        if expires_at is not None and 'expires_at' not in errors:
            if expires_at <= timezone.now():
                errors['expires_at'] = 'expires_at must be in the future.'

        report = attrs.get('report')
        target = attrs.get('target_user')
        if report is not None and target is not None and report.reported_user_id != target.pk:
            errors['report'] = 'This report is about a different user than the target_user.'

        if errors:
            raise serializers.ValidationError(errors)
        return attrs


class ReverseModerationActionSerializer(serializers.Serializer):
    """Input for POST /api/admin-panel/moderation-actions/<id>/reverse/."""
    reason = serializers.CharField(max_length=2000, trim_whitespace=True)


# ── Appeals (Trust & Safety Part 6) ───────────────────────────────────────────

class _OwnModerationActionField(serializers.PrimaryKeyRelatedField):
    """
    Resolves a moderation-action id, but ONLY among the requester's own
    actions. Someone else's action and a nonexistent id therefore fail with the
    exact same message, so a user can't probe which action ids exist or whose
    they are.
    """
    default_error_messages = {
        'does_not_exist': 'Moderation action not found.',
        'incorrect_type': 'Moderation action not found.',
    }

    def get_queryset(self):
        request = self.context.get('request')
        if request is None or not request.user.is_authenticated:
            return ModerationAction.objects.none()
        return ModerationAction.objects.filter(target_user=request.user)


class AppealSubmitSerializer(serializers.Serializer):
    """
    Input for POST /api/admin-panel/appeals/create/.

    A plain Serializer on purpose: only these three fields are read from the
    client. `user`, `report`, `status`, `reviewed_by`, `decision_note`,
    `resolved_at` and `created_at` are not declared, so anything a client sends
    for them is ignored — they are set by `apps.admin_panel.appeals` only.
    """
    moderation_action = _OwnModerationActionField()
    reason            = serializers.CharField(max_length=2000, trim_whitespace=True)
    evidence_url      = serializers.URLField(max_length=500, required=False, allow_blank=True)

    def validate_evidence_url(self, value):
        # URLField also accepts ftp/ftps; admins open this link, so keep it web-only.
        if value and not value.lower().startswith(('http://', 'https://')):
            raise serializers.ValidationError('Enter a valid http or https URL.')
        return value


class MyAppealSerializer(serializers.ModelSerializer):
    """
    What the APPEALING USER sees about their own appeal. Deliberately excludes
    decision_note, reviewed_by (admin identity) and report (which would reveal
    that/which report was behind the action). Read-only.
    """
    status_display      = serializers.CharField(source='get_status_display', read_only=True)
    action_type         = serializers.CharField(source='moderation_action.action_type', read_only=True)
    action_type_display = serializers.CharField(
        source='moderation_action.get_action_type_display', read_only=True)
    action_reason       = serializers.CharField(source='moderation_action.reason', read_only=True)
    action_status       = serializers.SerializerMethodField()

    class Meta:
        model  = Appeal
        fields = [
            'id', 'moderation_action', 'action_type', 'action_type_display',
            'action_reason', 'action_status',
            'reason', 'evidence_url',
            'status', 'status_display', 'created_at', 'resolved_at',
        ]
        read_only_fields = fields

    def get_action_status(self, obj):
        return action_status(obj.moderation_action)


class AdminAppealSerializer(serializers.ModelSerializer):
    """Full, admin-only view of an appeal, including the internal decision note."""
    status_display       = serializers.CharField(source='get_status_display', read_only=True)
    user_name            = serializers.CharField(source='user.name', read_only=True)
    user_email           = serializers.EmailField(source='user.email', read_only=True)
    reviewed_by_name     = serializers.SerializerMethodField()
    reviewed_by_email    = serializers.SerializerMethodField()
    moderation_action_detail = ModerationActionSerializer(source='moderation_action', read_only=True)

    class Meta:
        model  = Appeal
        fields = [
            'id', 'status', 'status_display',
            'user', 'user_name', 'user_email',
            'moderation_action', 'moderation_action_detail', 'report',
            'reason', 'evidence_url',
            'reviewed_by', 'reviewed_by_name', 'reviewed_by_email',
            'decision_note', 'created_at', 'resolved_at',
        ]
        read_only_fields = fields

    def get_reviewed_by_name(self, obj):
        return obj.reviewed_by.name if obj.reviewed_by else None

    def get_reviewed_by_email(self, obj):
        return obj.reviewed_by.email if obj.reviewed_by else None


class AppealApproveSerializer(serializers.Serializer):
    """Input for POST .../appeals/<id>/approve/ — the internal note is optional."""
    decision_note = serializers.CharField(
        max_length=2000, required=False, allow_blank=True, trim_whitespace=True)


class AppealRejectSerializer(serializers.Serializer):
    """Input for POST .../appeals/<id>/reject/ — rejecting requires an internal note."""
    decision_note = serializers.CharField(max_length=2000, trim_whitespace=True)