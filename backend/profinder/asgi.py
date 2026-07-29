# PATH: backend/profinder/asgi.py
"""
ASGI config for profinder project.

✅ REBUILT — now routes both regular HTTP (unchanged Django views) and
WebSocket connections (Channels, for real-time chat).
"""

import os

from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'profinder.settings')

# IMPORTANT: get_asgi_application() must be called BEFORE importing
# anything that touches Django models (like our routing/consumers) —
# it initializes Django's app registry first.
django_asgi_app = get_asgi_application()

from channels.routing import ProtocolTypeRouter, URLRouter          # noqa: E402
from apps.messaging.jwt_auth_middleware import JWTAuthMiddlewareStack  # noqa: E402
from apps.messaging.routing import websocket_urlpatterns             # noqa: E402

application = ProtocolTypeRouter({
    'http': django_asgi_app,
    'websocket': JWTAuthMiddlewareStack(
        URLRouter(websocket_urlpatterns)
    ),
})