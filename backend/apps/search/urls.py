# apps/search/urls.py

from django.urls import path
from apps.search.views import (
    CategoryView,
    FeaturedCategoriesView,
    SubCategoryView,
    NearbyProfessionalsView,
    PriceRangeSearchView,
    SearchView,
    AutoSuggestView,
    HomeFeedView,
    FavoriteListView,
    FavoriteToggleView,
)

urlpatterns = [
    path('categories/',                                  CategoryView.as_view(),            name='categories'),
    path('categories/featured/',                         FeaturedCategoriesView.as_view(),  name='featured_categories'),
    path('categories/<int:category_id>/subcategories/',  SubCategoryView.as_view(),         name='subcategories'),
    path('nearby/',                                      NearbyProfessionalsView.as_view(), name='nearby'),
    path('suggest/',                                     AutoSuggestView.as_view(),         name='suggest'),
    path('price-range/',                                 PriceRangeSearchView.as_view(),    name='price_range'),
    path('home-feed/',                                   HomeFeedView.as_view(),            name='home_feed'),
    path('favorites/',                                   FavoriteListView.as_view(),        name='favorites'),
    path('favorites/<int:professional_id>/toggle/',      FavoriteToggleView.as_view(),      name='favorite_toggle'),
    path('',                                             SearchView.as_view(),               name='search'),
]