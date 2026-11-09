from django.contrib import admin
from .models import SlugRedirect, ServiceListing


@admin.register(SlugRedirect)
class SlugRedirectAdmin(admin.ModelAdmin):
    list_display = ('old_path', 'new_path', 'status_code', 'created_at')
    search_fields = ('old_path', 'new_path')
    list_filter = ('status_code', 'created_at')


@admin.register(ServiceListing)
class ServiceListingAdmin(admin.ModelAdmin):
    list_display = ('title', 'slug', 'category', 'city', 'profession_key', 'is_active', 'created_at')
    search_fields = ('title', 'slug', 'short_description')
    list_filter = ('is_active', 'category', 'city', 'profession_key')
    prepopulated_fields = {'slug': ('title',)}
