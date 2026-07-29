# apps/articles/serializers.py

from rest_framework import serializers
from apps.articles.models import Article, ArticleCategory, ArticleView


class ArticleCategorySerializer(serializers.ModelSerializer):
    articles_count = serializers.SerializerMethodField()

    class Meta:
        model  = ArticleCategory
        fields = ['id', 'name', 'icon', 'color', 'articles_count']

    def get_articles_count(self, obj):
        return obj.articles.filter(is_published=True).count()


class ArticleListSerializer(serializers.ModelSerializer):
    """Lightweight — magazine list/grid cards."""
    category_name  = serializers.CharField(source='category.name',  read_only=True)
    category_color = serializers.CharField(source='category.color', read_only=True)

    class Meta:
        model  = Article
        fields = [
            'id', 'title', 'slug', 'summary', 'cover_image',
            'category', 'category_name', 'category_color',
            'editorial_label', 'read_time', 'views_count',
            'is_published', 'published_at',
        ]


class ArticleDetailSerializer(serializers.ModelSerializer):
    """Full — single article view + admin create/edit."""
    category_name  = serializers.CharField(source='category.name',  read_only=True)
    category_color = serializers.CharField(source='category.color', read_only=True)

    class Meta:
        model  = Article
        fields = [
            'id', 'title', 'slug', 'summary', 'content', 'cover_image',
            'category', 'category_name', 'category_color',
            'editorial_label', 'read_time', 'views_count',
            'is_published', 'published_at', 'created_at', 'updated_at',
        ]
        read_only_fields = [
            'slug', 'views_count', 'published_at', 'created_at', 'updated_at',
        ]

    def validate_title(self, value):
        value = value.strip()
        if len(value) < 5:
            raise serializers.ValidationError("Title must be at least 5 characters.")
        return value

    def validate_content(self, value):
        value = value.strip()
        if len(value) < 20:
            raise serializers.ValidationError("Content must be at least 20 characters.")
        return value


# ── Admin Analytics ──────────────────────────────────────────────────────────

class ArticleViewLogSerializer(serializers.ModelSerializer):
    """Single view log entry for admin analytics."""
    user_name  = serializers.CharField(source='user.name',  read_only=True)
    user_email = serializers.CharField(source='user.email', read_only=True)
    user_role  = serializers.CharField(source='user.role',  read_only=True)

    class Meta:
        model  = ArticleView
        fields = ['id', 'user_name', 'user_email', 'user_role', 'session_key', 'viewed_at']


class ArticleAnalyticsSerializer(serializers.ModelSerializer):
    """Per-article analytics summary for admin dashboard."""
    category_name  = serializers.CharField(source='category.name',  read_only=True)
    category_color = serializers.CharField(source='category.color', read_only=True)
    recent_views   = serializers.SerializerMethodField()
    unique_viewers = serializers.SerializerMethodField()

    class Meta:
        model  = Article
        fields = [
            'id', 'title', 'slug', 'cover_image',
            'category_name', 'category_color',
            'editorial_label', 'is_published',
            'views_count', 'unique_viewers',
            'published_at', 'recent_views',
        ]

    def get_unique_viewers(self, obj):
        return obj.view_logs.filter(
            user__isnull=False).values('user').distinct().count()

    def get_recent_views(self, obj):
        logs = obj.view_logs.select_related('user').order_by('-viewed_at')[:10]
        return ArticleViewLogSerializer(logs, many=True).data