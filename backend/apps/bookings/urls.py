from django.urls import path
from apps.bookings.views import (
    BookingView,
    ProfessionalBookingView,
    ProfessionalDashboardView,
    BookingSuggestTimeView,
    BookingRespondSuggestionView,
    BookingConfirmCompletionView,
)

urlpatterns = [
    path('', BookingView.as_view(), name='bookings'),
    path('<int:booking_id>/', BookingView.as_view(), name='booking_cancel'),
    path('<int:booking_id>/suggest-time/', BookingSuggestTimeView.as_view(), name='booking_suggest_time'),
    path('<int:booking_id>/respond-suggestion/', BookingRespondSuggestionView.as_view(), name='booking_respond_suggestion'),
    path('<int:booking_id>/confirm-completion/', BookingConfirmCompletionView.as_view(), name='booking_confirm_completion'),
    path('professional/', ProfessionalBookingView.as_view(), name='professional_bookings'),
    path('professional/<int:booking_id>/', ProfessionalBookingView.as_view(), name='booking_update'),
    path('professional/dashboard/', ProfessionalDashboardView.as_view(), name='professional_dashboard'),
]
