"""
WSGI config for profinder project.

It exposes the WSGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/6.0/howto/deployment/wsgi/
"""

import os
import sys
import traceback

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'profinder.settings')

try:
    from django.core.wsgi import get_wsgi_application
    application = get_wsgi_application()
except Exception as e:
    tb = traceback.format_exc()
    sys.stderr.write("CRITICAL PROFINDER WSGI STARTUP ERROR:\n" + tb + "\n")
    sys.stderr.flush()

    def application(environ, start_response):
        path_info = environ.get('PATH_INFO', '')
        status = '500 Internal Server Error'
        output = (
            f"<html><head><title>ProFinder Startup Error</title></head><body>"
            f"<h2>ProFinder Backend Startup Error</h2>"
            f"<p>Failed to initialize Django WSGI application at {path_info}:</p>"
            f"<pre style='background:#f4f4f4;padding:12px;border:1px solid #ccc;font-size:13px;'>{tb}</pre>"
            f"</body></html>"
        ).encode('utf-8')
        response_headers = [
            ('Content-Type', 'text/html; charset=utf-8'),
            ('Content-Length', str(len(output))),
            ('Access-Control-Allow-Origin', '*'),
            ('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS'),
            ('Access-Control-Allow-Headers', '*'),
        ]
        start_response(status, response_headers)
        return [output]

