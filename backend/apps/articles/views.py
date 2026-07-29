# apps/articles/views.py

import uuid
from django.db.models import Q, Count
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny, IsAuthenticated
import cloudinary.uploader

from apps.articles.models import Article, ArticleCategory, ArticleView
from apps.articles.serializers import (
    ArticleCategorySerializer,
    ArticleListSerializer,
    ArticleDetailSerializer,
    ArticleAnalyticsSerializer,
)


def _is_admin(user):
    return user.is_authenticated and user.role == 'admin'


def _log_view(request, article):
    """
    Article view log karo.
    Logged-in user → user field set.
    Guest → session_key se track.
    Ek session/user ek article pe sirf ek baar count ho.
    """
    user = request.user if request.user.is_authenticated else None

    session_key = ''
    if not user:
        session_key = request.session.get('magazine_sid', '')
        if not session_key:
            session_key = str(uuid.uuid4())
            request.session['magazine_sid'] = session_key

    # Duplicate guard — same user/session same article dobara count na ho
    # (24-hour window ke andar)
    from django.utils import timezone
    from datetime import timedelta
    window = timezone.now() - timedelta(hours=24)

    already = ArticleView.objects.filter(article=article, viewed_at__gte=window)
    if user:
        already = already.filter(user=user)
    else:
        already = already.filter(session_key=session_key)

    if not already.exists():
        ArticleView.objects.create(
            article=article, user=user, session_key=session_key)
        article.views_count += 1
        article.save(update_fields=['views_count'])


# ─── Categories ───────────────────────────────────────────────────────────────

class ArticleCategoryView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        return Response(
            ArticleCategorySerializer(ArticleCategory.objects.all(), many=True).data)

    def post(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        s = ArticleCategorySerializer(data=request.data)
        if s.is_valid():
            s.save()
            return Response(s.data, status=201)
        return Response(s.errors, status=400)


class ArticleCategoryDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, category_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            cat = ArticleCategory.objects.get(id=category_id)
        except ArticleCategory.DoesNotExist:
            return Response({'error': 'Not found.'}, status=404)
        s = ArticleCategorySerializer(cat, data=request.data, partial=True)
        if s.is_valid():
            s.save()
            return Response(s.data)
        return Response(s.errors, status=400)

    def delete(self, request, category_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            ArticleCategory.objects.get(id=category_id).delete()
            return Response({'message': 'Deleted.'})
        except ArticleCategory.DoesNotExist:
            return Response({'error': 'Not found.'}, status=404)


# ─── Public Article List ───────────────────────────────────────────────────────

class ArticleListView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        articles = Article.objects.filter(is_published=True)
        cat_id   = request.query_params.get('category_id')
        query    = request.query_params.get('q')
        if cat_id:
            articles = articles.filter(category_id=cat_id)
        if query:
            articles = articles.filter(
                Q(title__icontains=query) |
                Q(summary__icontains=query) |
                Q(content__icontains=query))
        return Response(ArticleListSerializer(articles, many=True).data)

    def post(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        s = ArticleDetailSerializer(data=request.data)
        if s.is_valid():
            s.save()
            return Response(s.data, status=201)
        return Response(s.errors, status=400)


# ─── Public Article Detail ────────────────────────────────────────────────────

class ArticleDetailView(APIView):
    permission_classes = [AllowAny]

    def _get_article(self, slug, request):
        try:
            a = Article.objects.get(slug=slug)
        except Article.DoesNotExist:
            return None
        if not a.is_published and not _is_admin(request.user):
            return None
        return a

    def get(self, request, slug):
        article = self._get_article(slug, request)
        if not article:
            return Response({'error': 'Article not found.'}, status=404)
        _log_view(request, article)
        return Response(ArticleDetailSerializer(article).data)

    def patch(self, request, slug):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            article = Article.objects.get(slug=slug)
        except Article.DoesNotExist:
            return Response({'error': 'Not found.'}, status=404)
        s = ArticleDetailSerializer(article, data=request.data, partial=True)
        if s.is_valid():
            s.save()
            return Response(s.data)
        return Response(s.errors, status=400)

    def delete(self, request, slug):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            Article.objects.get(slug=slug).delete()
            return Response({'message': 'Deleted.'})
        except Article.DoesNotExist:
            return Response({'error': 'Not found.'}, status=404)


# ─── Admin: All Articles ───────────────────────────────────────────────────────

class AdminArticleListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        articles = Article.objects.all()
        return Response(ArticleListSerializer(articles, many=True).data)


class AdminArticleBulkActionView(APIView):
    """
    POST /api/articles/admin/bulk/
    Body: { "article_ids": [1,2,3], "action": "archive" | "delete" | "publish" | "unpublish" }

    Bulk archive/delete/publish for the Magazine admin list — used when the
    admin multi-selects rows and applies one action to all of them at once.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)

        ids = request.data.get('article_ids', [])
        action = request.data.get('action')
        if not ids or action not in ('archive', 'delete', 'publish', 'unpublish'):
            return Response(
                {'error': 'article_ids and a valid action are required.'}, status=400)

        qs = Article.objects.filter(id__in=ids)
        count = qs.count()

        if action == 'delete':
            qs.delete()
        elif action == 'archive':
            qs.update(is_archived=True, is_published=False)
        elif action == 'publish':
            from django.utils import timezone as tz
            qs.update(is_published=True, is_archived=False)
            qs.filter(published_at__isnull=True).update(published_at=tz.now())
        elif action == 'unpublish':
            qs.update(is_published=False)

        return Response({'message': f'{count} article(s) {action}d.', 'count': count})


# ─── Admin: Analytics ─────────────────────────────────────────────────────────

class AdminAnalyticsView(APIView):
    """
    GET /api/articles/admin/analytics/
    Returns per-article analytics + category breakdown for admin dashboard.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)

        articles = Article.objects.filter(
            is_published=True).order_by('-views_count')

        # Category breakdown — kitne views per category
        cat_breakdown = (
            ArticleView.objects
            .filter(article__is_published=True)
            .values('article__category__name', 'article__category__color')
            .annotate(total_views=Count('id'))
            .order_by('-total_views')
        )

        # Total stats
        from django.utils import timezone
        from datetime import timedelta
        today      = timezone.now().date()
        week_start = timezone.now() - timedelta(days=7)
        month_start = today.replace(day=1)

        total_views   = ArticleView.objects.count()
        views_today   = ArticleView.objects.filter(
            viewed_at__date=today).count()
        views_this_week = ArticleView.objects.filter(
            viewed_at__gte=week_start).count()
        unique_readers = ArticleView.objects.filter(
            user__isnull=False).values('user').distinct().count()

        published_this_month = Article.objects.filter(
            is_published=True, published_at__date__gte=month_start).count()
        total_articles_all = Article.objects.count()
        draft_count = Article.objects.filter(is_published=False, is_archived=False).count()
        archived_count = Article.objects.filter(is_archived=True).count()
        most_read = articles.first()

        return Response({
            'summary': {
                'total_views':          total_views,
                'views_today':          views_today,
                'views_this_week':      views_this_week,
                'unique_readers':       unique_readers,
                'total_articles':       total_articles_all,
                'published_this_month': published_this_month,
                'draft_count':          draft_count,
                'archived_count':       archived_count,
                'most_read_title':      most_read.title if most_read else None,
                'most_read_views':      most_read.views_count if most_read else 0,
            },
            'category_breakdown': list(cat_breakdown),
            'articles': ArticleAnalyticsSerializer(articles, many=True).data,
        })


# ─── Cover Image Upload ────────────────────────────────────────────────────────

class ArticleImageUploadView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        image = request.FILES.get('image')
        if not image:
            return Response({'error': 'No image provided.'}, status=400)
        try:
            result = cloudinary.uploader.upload(image, folder='articles')
            return Response({'url': result['secure_url']})
        except Exception as e:
            return Response({'error': f'Upload failed: {str(e)}'}, status=500)