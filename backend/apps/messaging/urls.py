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
    ReportUserView,           # ✅ NEW
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
    path('reports/',                                              ReportUserView.as_view(),         name='report_user'),         # ✅ NEW
]