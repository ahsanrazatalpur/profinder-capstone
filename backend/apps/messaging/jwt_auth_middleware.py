# PATH: backend/apps/messaging/jwt_auth_middleware.py
#
# ✅ NEW — Authenticates WebSocket connections using the SAME JWT access
# tokens issued by the normal login API (rest_framework_simplejwt).
#
# Flutter side will connect like:
#   ws://<host>/ws/chat/<conversation_id>/?token=<access_token>
#
# WHY a query param and not a header: most WebSocket client libraries
# (including Dart's web_socket_channel) make it awkward to set custom
# headers on the initial handshake, but every one of them can put the
# token in the URL. This is a widely-used, accepted pattern for WS auth.

from urllib.parse import parse_qs
from channels.middleware import BaseMiddleware
from channels.db import database_sync_to_async
from django.contrib.auth.models import AnonymousUser
from rest_framework_simplejwt.tokens import UntypedToken
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError
from rest_framework_simplejwt.authentication import JWTAuthentication


@database_sync_to_async
def get_user_from_token(token):
    """
    Validates the token and loads the User — wrapped in
    database_sync_to_async because Channels consumers run in an async
    context but Django's ORM (and simplejwt's user lookup) is sync.
    """
    try:
        UntypedToken(token)  # raises if expired/invalid/tampered
        jwt_auth = JWTAuthentication()
        validated_token = jwt_auth.get_validated_token(token)
        return jwt_auth.get_user(validated_token)
    except (InvalidToken, TokenError, Exception):
        return AnonymousUser()


class JWTAuthMiddleware(BaseMiddleware):
    async def __call__(self, scope, receive, send):
        query_string = scope.get('query_string', b'').decode()
        params = parse_qs(query_string)
        token = params.get('token', [None])[0]

        if token:
            scope['user'] = await get_user_from_token(token)
        else:
            scope['user'] = AnonymousUser()

        return await super().__call__(scope, receive, send)


def JWTAuthMiddlewareStack(inner):
    return JWTAuthMiddleware(inner)