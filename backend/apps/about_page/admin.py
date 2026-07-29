# apps/about_page/admin.py

from django.contrib import admin

from apps.about_page.models import (
    AboutSection, AboutSectionItem,
    AboutSectionTranslation, AboutSectionItemTranslation,
    AboutPageSEO, AboutPageStatus, AboutPageVersion,
)


class AboutSectionItemInline(admin.TabularInline):
    model = AboutSectionItem
    extra = 0
    fields = ('title', 'subtitle', 'value', 'is_enabled', 'order')


@admin.register(AboutSection)
class AboutSectionAdmin(admin.ModelAdmin):
    list_display = ('order', 'section_type', 'section_key', 'title', 'is_enabled', 'updated_at')
    list_filter = ('section_type', 'is_enabled')
    search_fields = ('section_key', 'title', 'subtitle')
    ordering = ('order',)
    inlines = [AboutSectionItemInline]


@admin.register(AboutSectionItem)
class AboutSectionItemAdmin(admin.ModelAdmin):
    list_display = ('section', 'order', 'title', 'value', 'is_enabled')
    list_filter = ('is_enabled', 'section')
    search_fields = ('title', 'subtitle')


@admin.register(AboutSectionTranslation)
class AboutSectionTranslationAdmin(admin.ModelAdmin):
    list_display = ('section', 'language', 'title', 'updated_at')
    list_filter = ('language',)


@admin.register(AboutSectionItemTranslation)
class AboutSectionItemTranslationAdmin(admin.ModelAdmin):
    list_display = ('item', 'language', 'title', 'updated_at')
    list_filter = ('language',)


@admin.register(AboutPageSEO)
class AboutPageSEOAdmin(admin.ModelAdmin):
    list_display = ('meta_title', 'updated_at')


@admin.register(AboutPageStatus)
class AboutPageStatusAdmin(admin.ModelAdmin):
    list_display = ('status', 'published_at', 'published_by', 'current_version')


@admin.register(AboutPageVersion)
class AboutPageVersionAdmin(admin.ModelAdmin):
    list_display = ('version_number', 'label', 'created_by', 'created_at', 'is_restore_of')
    ordering = ('-version_number',)