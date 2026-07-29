# apps/articles/admin.py

from django.contrib import admin
from apps.articles.models import Article, ArticleCategory


@admin.register(ArticleCategory)
class ArticleCategoryAdmin(admin.ModelAdmin):
    list_display  = ('name', 'icon', 'color', 'created_at')
    search_fields = ('name',)


@admin.register(Article)
class ArticleAdmin(admin.ModelAdmin):
    list_display        = ('title', 'category', 'author', 'is_published', 'views_count', 'published_at')
    list_filter         = ('is_published', 'category')
    search_fields       = ('title', 'content')
    prepopulated_fields = {'slug': ('title',)}