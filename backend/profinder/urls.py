# profinder/urls.py

from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/',                  admin.site.urls),

    # Allauth — Google OAuth
    # Must be 'accounts/' — allauth hardcodes this internally
    path('accounts/',               include('allauth.urls')),

    # REST API endpoints
    path('api/users/',              include('apps.users.urls')),
    path('api/profiles/',           include('apps.profiles.urls')),
    path('api/search/',             include('apps.search.urls')),
    path('api/reviews/',            include('apps.reviews.urls')),
    path('api/payments/',           include('apps.payments.urls')),
    path('api/notifications/',      include('apps.notifications.urls')),
    path('api/subscriptions/',      include('apps.subscriptions.urls')),
    path('api/ai/',                 include('apps.ai_engine.urls')),
    path('api/admin-panel/',        include('apps.admin_panel.urls')),
    path('api/bookings/',           include('apps.bookings.urls')),
    path('api/articles/',           include('apps.articles.urls')),   
    path('api/messaging/',          include('apps.messaging.urls')), 
    path("api/about-page/", include("apps.about_page.urls")), 
]

# 🐛 FIX: nothing was serving MEDIA_URL, so every uploaded file (chat
# images, profile photos, portfolio images, ...) 404'd the moment the app
# tried to display it back — "broken image" for sender AND receiver alike,
# since both were hitting the same dead /media/... URL. Dev-only: in
# production this is handled by your web server / cloud storage instead.
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)