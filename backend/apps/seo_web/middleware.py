import re
from django.http import HttpResponsePermanentRedirect
from django.utils.deprecation import MiddlewareMixin
from .models import SlugRedirect


class SEOUrlNormalizationMiddleware(MiddlewareMixin):
    """
    Ensures canonical URL structure and executes 301 permanent redirects:
    1. Checks SlugRedirect table for historical slug changes.
    2. Enforces lowercasing and trailing slashes on public SEO URLs to avoid duplicate content penalties.
    """

    EXEMPT_PREFIXES = ('/api/', '/admin/', '/static/', '/media/', '/accounts/')

    def process_request(self, request):
        path = request.path

        # Ignore non-public or binary assets
        for prefix in self.EXEMPT_PREFIXES:
            if path.startswith(prefix):
                return None

        # Ignore files with extensions (e.g. favicon.ico, sitemap.xml, robots.txt, llms.txt)
        if '.' in path.rsplit('/', 1)[-1]:
            # Still check SlugRedirect for specific file paths if any
            redirect = SlugRedirect.objects.filter(old_path=path).first()
            if redirect:
                return HttpResponsePermanentRedirect(redirect.new_path)
            return None

        # 1. Check database for 301 redirects
        redirect = SlugRedirect.objects.filter(old_path=path).first()
        if redirect:
            query = request.META.get('QUERY_STRING')
            target = redirect.new_path
            if query:
                target = f"{target}?{query}"
            return HttpResponsePermanentRedirect(target)

        # 2. Check uppercase paths on public routes
        # E.g. /Categories/Healthcare/ -> /categories/healthcare/
        if any(c.isupper() for c in path):
            normalized = path.lower()
            query = request.META.get('QUERY_STRING')
            target = f"{normalized}?{query}" if query else normalized
            return HttpResponsePermanentRedirect(target)

        return None
