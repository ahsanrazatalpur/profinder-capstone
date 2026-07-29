from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from apps.notifications.models import Notification
from apps.notifications.serializers import NotificationSerializer
from apps.notifications.utils import send_fcm_push


class NotificationView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        notifications = Notification.objects.filter(user=request.user)
        serializer = NotificationSerializer(notifications, many=True)
        return Response(serializer.data)

    def patch(self, request, notification_id):
        try:
            notification = Notification.objects.get(id=notification_id, user=request.user)
            notification.is_read = True
            notification.save()
            return Response({"message": "Notification marked as read"})
        except Notification.DoesNotExist:
            return Response({"error": "Not found"}, status=status.HTTP_404_NOT_FOUND)


class SendNotificationView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        title     = request.data.get('title')
        body      = request.data.get('message')
        fcm_token = request.data.get('fcm_token')

        # Database mein save karo
        Notification.objects.create(
            user=request.user,
            title=title,
            message=body,
            type=request.data.get('type', 'general')
        )

        # FCM se push notification bhejo
        if fcm_token:
            send_fcm_push(fcm_token, title, body)

        return Response({"message": "Notification sent"}, status=status.HTTP_201_CREATED)