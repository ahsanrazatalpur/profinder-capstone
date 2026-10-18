from django.contrib import admin
from apps.search.models import Category, SubCategory, Favorite, SearchAlias

admin.site.register(Category)
admin.site.register(SubCategory)
admin.site.register(Favorite)


@admin.register(SearchAlias)
class SearchAliasAdmin(admin.ModelAdmin):
    list_display = ('alias', 'canonical', 'language', 'source', 'is_active')
    list_filter = ('language', 'source', 'is_active')
    search_fields = ('alias', 'canonical')