from django.urls import path
from apps.bookings.views import BookingView, ProfessionalBookingView, ProfessionalDashboardView

urlpatterns = [
    path('', BookingView.as_view(), name='bookings'),
    path('<int:booking_id>/', BookingView.as_view(), name='booking_cancel'),          # ✅ Customer cancel
    path('professional/', ProfessionalBookingView.as_view(), name='professional_bookings'),
    path('professional/<int:booking_id>/', ProfessionalBookingView.as_view(), name='booking_update'),
    path('professional/dashboard/', ProfessionalDashboardView.as_view(), name='professional_dashboard'),  # ✅ NEW — Home Dashboard
]