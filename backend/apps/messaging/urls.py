# PATH: backend/apps/messaging/urls.py

from django.urls import path
from apps.messaging.views import (
    ConversationListView,
    MessageListView,
    MessageDetailView,
    MarkDeliveredView,
    MarkSeenView,
    PresenceView,
    ReactionView,             # ✅ NEW
    ConversationStateView,    # ✅ NEW — pin/archive/mute/draft
    MediaGalleryView,         # ✅ NEW
    BlockUserView,            # ✅ NEW
    # ReportUserView intentionally NOT imported anymore — see urls.py.
)

urlpatterns = [
    path('conversations/',                                       ConversationListView.as_view(),   name='conversations'),
    path('conversations/<int:conversation_id>/messages/',         MessageListView.as_view(),        name='messages'),
    path('conversations/<int:conversation_id>/mark-delivered/',   MarkDeliveredView.as_view(),      name='mark_delivered'),
    path('conversations/<int:conversation_id>/mark-seen/',        MarkSeenView.as_view(),            name='mark_seen'),
    path('conversations/<int:conversation_id>/state/',            ConversationStateView.as_view(),  name='conversation_state'),  # ✅ NEW
    path('conversations/<int:conversation_id>/media/',            MediaGalleryView.as_view(),       name='conversation_media'),  # ✅ NEW

    path('messages/<int:message_id>/',                            MessageDetailView.as_view(),      name='message_detail'),
    path('messages/<int:message_id>/reactions/',                  ReactionView.as_view(),           name='message_reactions'),   # ✅ NEW

    path('presence/',                                             PresenceView.as_view(),           name='presence_heartbeat'),
    path('presence/<int:user_id>/',                               PresenceView.as_view(),           name='presence_check'),

    path('blocked-users/',                                        BlockUserView.as_view(),          name='blocked_users'),       # ✅ NEW — GET list, POST block
    path('blocked-users/<int:user_id>/',                          BlockUserView.as_view(),          name='unblock_user'),        # ✅ NEW — DELETE unblock
    # 🐛 Trust & Safety Part 10 (final audit) — REMOVED: `path('reports/',
    # ReportUserView.as_view(), ...)`. This routed to apps.messaging's OWN
    # ReportUserView/UserReport model, completely separate from the active
    # apps.admin_panel report system every admin screen, notification, and
    # the Part 8 "My Reports" screen actually reads from. A report submitted
    # here got a success response but was never seen by any admin — a
    # silent data-integrity hole, not a feature. Nothing in this backend or
    # the current Flutter app calls it (the app was already fixed to POST to
    # /api/admin-panel/reports/create/ — see AppConstants.reportUser).
    # The view class, serializer, and UserReport model are left untouched
    # (no data deleted, easy to re-route instead of re-write if ever
    # needed) — only the dead/dangerous URL is removed.
]