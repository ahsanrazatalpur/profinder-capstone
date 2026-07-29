from django.urls import path
from apps.notifications.views import NotificationView, SendNotificationView

urlpatterns = [
    path('', NotificationView.as_view(), name='notifications'),
    path('<int:notification_id>/read/', NotificationView.as_view(), name='notification_read'),
    path('send/', SendNotificationView.as_view(), name='send_notification'),
]