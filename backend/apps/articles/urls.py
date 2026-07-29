# apps/articles/urls.py

from django.urls import path
from apps.articles.views import (
    ArticleCategoryView,
    ArticleCategoryDetailView,
    ArticleListView,
    ArticleDetailView,
    AdminArticleListView,
    AdminArticleBulkActionView,
    AdminAnalyticsView,
    ArticleImageUploadView,
)

urlpatterns = [
    path('categories/',                   ArticleCategoryView.as_view(),       name='article_categories'),
    path('categories/<int:category_id>/', ArticleCategoryDetailView.as_view(), name='article_category_detail'),

    path('admin/all/',                    AdminArticleListView.as_view(),      name='admin_articles'),
    path('admin/bulk/',                   AdminArticleBulkActionView.as_view(),name='admin_articles_bulk'),
    path('admin/analytics/',              AdminAnalyticsView.as_view(),        name='admin_analytics'),
    path('upload-image/',                 ArticleImageUploadView.as_view(),    name='article_upload_image'),

    path('',                              ArticleListView.as_view(),           name='articles'),
    path('<slug:slug>/',                  ArticleDetailView.as_view(),         name='article_detail'),
]