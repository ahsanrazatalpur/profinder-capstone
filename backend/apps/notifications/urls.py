from django.urls import path
from apps.notifications.views import NotificationClearView, NotificationView

urlpatterns = [
    path('', NotificationView.as_view(), name='notifications'),
    path('<int:notification_id>/read/', NotificationView.as_view(), name='notification_read'),
    path('clear/', NotificationClearView.as_view(), name='notification_clear'),
]