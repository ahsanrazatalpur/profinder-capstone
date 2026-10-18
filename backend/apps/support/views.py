# apps/support/views.py
#
# Step 1: PUBLIC, read-only Help Center + Privacy Policy endpoints.
# No authentication needed (guests included). Content is never machine
# translated: see services.resolve_translation and the middleware deny list.

from django.db.models import Count, Prefetch, Q
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from apps.support.models import (
    AUDIENCE_ALL, AUDIENCE_CUSTOMER, AUDIENCE_PROFESSIONAL,
    HelpArticle, HelpArticleTranslation, HelpCategory,
    HelpCategoryTranslation, PolicyDocument, PolicyTranslation, PolicyVersion,
)
from apps.support.presenters import present_article, present_category, present_policy
from apps.support.services import SOURCE_LANGUAGE

MIN_QUERY_LEN = 2
MAX_QUERY_LEN = 100
MAX_RESULTS = 50


class PublicReadMixin:
    permission_classes = [AllowAny]
    authentication_classes = []          # public: a stale/bad token must not cause 401
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'support_public_read'


def _lang(request):
    return request.query_params.get('lang') or SOURCE_LANGUAGE


def _audiences(request):
    """Guests / unspecified -> only 'all' content. A role adds its own audience."""
    aud = (request.query_params.get('audience') or '').lower()
    allowed = [AUDIENCE_ALL]
    if aud in (AUDIENCE_CUSTOMER, AUDIENCE_PROFESSIONAL):
        allowed.append(aud)
    return allowed


def _translation_prefetch(model):
    return Prefetch('translations', queryset=model.objects.select_related('language'))


class PrivacyPolicyView(PublicReadMixin, APIView):
    """GET /api/support/policies/privacy/?lang=ur  (latest PUBLISHED version)."""

    def get(self, request):
        version = (
            PolicyVersion.objects
            .filter(document__doc_type=PolicyDocument.TYPE_PRIVACY,
                    status=PolicyVersion.STATUS_PUBLISHED)
            .select_related('document')
            .prefetch_related(_translation_prefetch(PolicyTranslation))
            .order_by('-version_number')
            .first()
        )
        data = present_policy(version, _lang(request)) if version else None
        if data is None:
            return Response({'error': 'Privacy policy is not published yet.'}, status=404)
        return Response(data)


class HelpCategoryListView(PublicReadMixin, APIView):
    """GET /api/support/help/categories/?lang=&audience=customer|professional"""

    def get(self, request):
        lang = _lang(request)
        audiences = _audiences(request)
        published = Q(articles__is_published=True, articles__audience__in=audiences)
        categories = (
            HelpCategory.objects
            .filter(is_active=True, audience__in=audiences)
            .annotate(article_count=Count('articles', filter=published, distinct=True))
            .prefetch_related(_translation_prefetch(HelpCategoryTranslation))
        )
        results = [d for d in (present_category(c, lang, c.article_count) for c in categories)
                   if d is not None]
        return Response({'results': results})


def _published_articles(audiences):
    return (
        HelpArticle.objects
        .filter(is_published=True, audience__in=audiences,
                category__is_active=True, category__audience__in=audiences)
        .select_related('category')
        .prefetch_related(_translation_prefetch(HelpArticleTranslation))
    )


class HelpArticleListView(PublicReadMixin, APIView):
    """GET /api/support/help/articles/?category=<slug>&q=<text>&lang=&audience=

    Search is a case-insensitive `contains` on the stored lower-cased title+body
    (works on SQLite and PostgreSQL). It only matches text a user can actually
    see: English, or a human-reviewed translation.
    """

    def get(self, request):
        lang = _lang(request)
        qs = _published_articles(_audiences(request))

        category = request.query_params.get('category')
        if category:
            qs = qs.filter(category__slug=category)

        q = (request.query_params.get('q') or '').strip().lower()
        if q:
            if len(q) < MIN_QUERY_LEN:
                return Response({'results': [], 'count': 0, 'query': q})
            q = q[:MAX_QUERY_LEN]
            visible = HelpArticleTranslation.objects.filter(
                Q(language__code=SOURCE_LANGUAGE) | Q(is_reviewed=True),
                search_text__icontains=q,
            ).values('article_id')
            qs = qs.filter(pk__in=visible)

        results = [d for d in (present_article(a, lang, with_body=False)
                               for a in qs[:MAX_RESULTS]) if d is not None]
        return Response({'results': results, 'count': len(results), 'query': q})


class HelpArticleDetailView(PublicReadMixin, APIView):
    """GET /api/support/help/articles/<slug>/?lang=&audience="""

    def get(self, request, slug):
        article = _published_articles(_audiences(request)).filter(slug=slug).first()
        data = present_article(article, _lang(request), with_body=True) if article else None
        if data is None:
            return Response({'error': 'Article not found.'}, status=404)
        return Response(data)
