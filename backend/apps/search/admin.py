from django.contrib import admin
from apps.search.models import Category, SubCategory, Favorite

admin.site.register(Category)
admin.site.register(SubCategory)
admin.site.register(Favorite)