# apps/admin_panel/enforcement.py
"""
Centralized, server-side moderation enforcement layer (Trust & Safety Part 3).

This module answers ONE question, safely and consistently: "does this user
currently have an active moderation restriction, and if so, which one(s)?"

It is a pure READ layer built on top of `ModerationAction` (Part 2). Nothing
here mutates `User.is_active`, blocks a request, sends a notification, or
exposes an API — those are later parts. Views can import and call these
helpers once they're ready to actually enforce something; wiring them into
messaging/booking endpoints is explicitly out of scope for this part.

SECURITY
--------
Every function here re-derives the answer from the database on each call.
Nothing is trusted from the client — there is no "am I restricted?" flag
accepted as input anywhere in this module. A user cannot bypass this by
editing a Flutter request, because the request never carries moderation
status in the first place; the server always looks it up fresh from
`ModerationAction` rows keyed by the authenticated user's id.

AUTOMATIC EXPIRY
----------------
A temporary suspension's `expires_at` is only ever compared against
`timezone.now()` at read time — never written back. That means a temporary
suspension expires the instant the clock passes `expires_at`, with no
background job, cron task, or manual DB update required. `ModerationAction
.is_active` staying `True` after expiry is expected and harmless: it only
means "an admin hasn't explicitly reversed this record," not "this
restriction is currently in force."
"""
from dataclasses import dataclass, field
from typing import List, Optional

from django.db.models import Q
from django.utils import timezone

from apps.admin_panel.models import ModerationAction

# Higher number = stronger suspension. Used only to pick which single action
# best represents an overall suspension when more than one applies at once
# (e.g. a permanent suspension always "wins" over a still-open temporary one).
_SUSPENSION_SEVERITY = {
    ModerationAction.ACTION_SUSPEND_PERMANENT: 2,
    ModerationAction.ACTION_SUSPEND_TEMPORARY: 1,
}


def _is_effectively_active(action: ModerationAction, now) -> bool:
    """
    Single source of truth for "is this specific action in force right now?"
    Computed on every read, never cached/stored, so expiry is automatic.
    """
    if not action.is_active:
        return False
    if action.starts_at and action.starts_at > now:
        return False  # scheduled to start later — not in force yet
    if action.expires_at and action.expires_at <= now:
        return False  # temporary action has expired
    return True


def get_active_actions(user) -> List[ModerationAction]:
    """
    Every `ModerationAction` row targeting `user` that is currently in
    force. The expensive filtering (is_active, not-yet-started,
    not-expired) happens in the database, so this stays cheap even against
    a large history table; `_is_effectively_active` is the source of truth
    this query is built to match.
    """
    now = timezone.now()
    qs = (
        ModerationAction.objects
        .filter(target_user=user, is_active=True, starts_at__lte=now)
        .filter(Q(expires_at__isnull=True) | Q(expires_at__gt=now))
    )
    # Defensive: re-check in Python too, so this function stays correct even
    # if the query above and _is_effectively_active ever drift apart.
    return [a for a in qs if _is_effectively_active(a, now)]


@dataclass
class ModerationStatus:
    """
    A single, consistent snapshot of a user's current moderation state.
    Built from one query so every fact below reflects the same instant in
    time — safer than calling several independent helpers back-to-back,
    which could theoretically straddle an action expiring mid-request.
    """
    active_actions: List[ModerationAction] = field(default_factory=list)

    @property
    def is_suspended(self) -> bool:
        """True if a temporary OR permanent suspension is in force."""
        return any(a.action_type in _SUSPENSION_SEVERITY for a in self.active_actions)

    @property
    def suspension_action(self) -> Optional[ModerationAction]:
        """The single strongest active suspension record, if any."""
        suspensions = [a for a in self.active_actions if a.action_type in _SUSPENSION_SEVERITY]
        if not suspensions:
            return None
        return max(suspensions, key=lambda a: _SUSPENSION_SEVERITY[a.action_type])

    @property
    def suspension_type(self) -> Optional[str]:
        action = self.suspension_action
        return action.action_type if action else None

    @property
    def suspension_expires_at(self):
        """None for a permanent suspension (or if not suspended at all)."""
        action = self.suspension_action
        return action.expires_at if action else None

    @property
    def is_permanently_suspended(self) -> bool:
        return self.suspension_type == ModerationAction.ACTION_SUSPEND_PERMANENT

    @property
    def is_temporarily_suspended(self) -> bool:
        return self.suspension_type == ModerationAction.ACTION_SUSPEND_TEMPORARY

    @property
    def messaging_restricted(self) -> bool:
        """
        Blocked from sending messages. A suspension is the strongest
        restriction and implies every weaker one — a suspended user can't
        message regardless of whether a separate restrict_messaging row
        also exists. An explicit restrict_messaging action blocks messaging
        ONLY, and never touches unrelated account access (browsing,
        bookings, etc. are untouched by it).
        """
        if self.is_suspended:
            return True
        return any(
            a.action_type == ModerationAction.ACTION_RESTRICT_MESSAGING
            for a in self.active_actions
        )

    @property
    def booking_restricted(self) -> bool:
        """
        Blocked from creating new bookings. Same logic as
        `messaging_restricted`: a suspension implies this too; an explicit
        restrict_booking action blocks booking creation ONLY.
        """
        if self.is_suspended:
            return True
        return any(
            a.action_type == ModerationAction.ACTION_RESTRICT_BOOKING
            for a in self.active_actions
        )

    @property
    def has_active_warning(self) -> bool:
        """Informational only — a warning never blocks anything."""
        return any(
            a.action_type == ModerationAction.ACTION_WARNING
            for a in self.active_actions
        )


def get_moderation_status(user) -> ModerationStatus:
    """
    The main entry point for callers that need more than one fact about a
    user's moderation state — one query, one consistent snapshot. Prefer
    this over chaining the individual can_*/is_* helpers below.
    """
    return ModerationStatus(active_actions=get_active_actions(user))


# ── Convenience helpers for call sites that only need a single fact ───────
# Each does its own fresh query. Fine for a single isolated check; if a
# caller needs several facts about the same user, call
# get_moderation_status() once instead, to avoid redundant queries and to
# guarantee every fact reflects the same snapshot.

def is_suspended(user) -> bool:
    """True if the user has an active temporary or permanent suspension."""
    return get_moderation_status(user).is_suspended


def can_send_messages(user) -> bool:
    """False if the user is suspended or has an active messaging restriction."""
    return not get_moderation_status(user).messaging_restricted


def can_create_bookings(user) -> bool:
    """False if the user is suspended or has an active booking restriction."""
    return not get_moderation_status(user).booking_restricted
