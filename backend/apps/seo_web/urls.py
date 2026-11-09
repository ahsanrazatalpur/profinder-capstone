from django.urls import path
from . import views

app_name = 'seo_web'

urlpatterns = [
    # Homepage
    path('', views.home_view, name='home'),

    # Search
    path('search/', views.search_view, name='search'),

    # Category Landing Pages
    path('categories/<slug:category_slug>/', views.category_detail_view, name='category_detail'),

    # Profession Landing Pages
    path('profession/<slug:profession_slug>/', views.profession_detail_view, name='profession_detail'),

    # Individual Professional Profile Pages
    path('professionals/<slug:slug>/', views.professional_detail_view, name='professional_detail'),

    # Individual Service Pages
    path('services/<slug:service_slug>/', views.service_detail_view, name='service_detail'),

    # Location-based Landing Pages
    path('pakistan/', views.country_view, name='country'),
    path('pakistan/<slug:province_slug>/', views.province_view, name='province'),
    path('pakistan/<slug:province_slug>/<slug:city_slug>/', views.city_view, name='city'),
    path('pakistan/<slug:province_slug>/<slug:city_slug>/<slug:category_slug>/', views.city_category_view, name='city_category'),

    # Technical SEO / Crawlers
    path('robots.txt', views.robots_txt_view, name='robots_txt'),
    path('llms.txt', views.llms_txt_view, name='llms_txt'),
    path('sitemap.xml', views.sitemap_index_view, name='sitemap_index'),
    path('sitemap-categories.xml', views.sitemap_categories_view, name='sitemap_categories'),
    path('sitemap-professions.xml', views.sitemap_professions_view, name='sitemap_professions'),
    path('sitemap-professionals.xml', views.sitemap_professionals_view, name='sitemap_professionals'),
    path('sitemap-locations.xml', views.sitemap_locations_view, name='sitemap_locations'),
    path('sitemap-services.xml', views.sitemap_services_view, name='sitemap_services'),
]
