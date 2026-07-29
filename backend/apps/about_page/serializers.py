# apps/about_page/serializers.py

from rest_framework import serializers

from apps.about_page.models import (
    AboutSection, AboutSectionItem,
    AboutSectionTranslation, AboutSectionItemTranslation,
    AboutPageSEO, AboutPageStatus, AboutPageVersion,
)
from apps.about_page.utils import optimized_url


# ─── Admin serializers (full read/write) ───────────────────────────────────────

class AboutSectionItemTranslationSerializer(serializers.ModelSerializer):
    language_code = serializers.CharField(source='language.code', read_only=True)

    class Meta:
        model = AboutSectionItemTranslation
        fields = ['id', 'language', 'language_code', 'title', 'subtitle', 'description', 'value']


class AboutSectionTranslationSerializer(serializers.ModelSerializer):
    language_code = serializers.CharField(source='language.code', read_only=True)

    class Meta:
        model = AboutSectionTranslation
        fields = ['id', 'language', 'language_code', 'title', 'subtitle', 'description', 'cta_text']


class AboutSectionItemAdminSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()
    translations = AboutSectionItemTranslationSerializer(many=True, read_only=True)

    class Meta:
        model = AboutSectionItem
        fields = [
            'id', 'section', 'title', 'subtitle', 'description', 'icon',
            'image', 'image_url', 'value', 'link_url', 'extra_data',
            'is_enabled', 'order', 'translations', 'created_at', 'updated_at',
        ]
        extra_kwargs = {'image': {'write_only': True, 'required': False}}

    def get_image_url(self, obj):
        return optimized_url(obj.image)


class AboutSectionAdminSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()
    items = AboutSectionItemAdminSerializer(many=True, read_only=True)
    translations = AboutSectionTranslationSerializer(many=True, read_only=True)
    is_collection_type = serializers.SerializerMethodField()

    class Meta:
        model = AboutSection
        fields = [
            'id', 'section_type', 'section_key', 'title', 'subtitle',
            'description', 'icon', 'image', 'image_url', 'cta_text', 'cta_url',
            'cta_style', 'extra_data', 'is_enabled', 'order',
            'is_collection_type', 'items', 'translations',
            'created_by', 'updated_by', 'created_at', 'updated_at',
        ]
        read_only_fields = ['created_by', 'updated_by']
        extra_kwargs = {'image': {'write_only': True, 'required': False}}

    def get_image_url(self, obj):
        return optimized_url(obj.image)

    def get_is_collection_type(self, obj):
        return obj.is_collection_type()


class AboutPageSEOSerializer(serializers.ModelSerializer):
    og_image_url = serializers.SerializerMethodField()

    class Meta:
        model = AboutPageSEO
        fields = [
            'meta_title', 'meta_description', 'meta_keywords',
            'og_image', 'og_image_url', 'updated_by', 'updated_at',
        ]
        read_only_fields = ['updated_by']
        extra_kwargs = {'og_image': {'write_only': True, 'required': False}}

    def get_og_image_url(self, obj):
        return optimized_url(obj.og_image)


class AboutPageStatusSerializer(serializers.ModelSerializer):
    current_version_number = serializers.IntegerField(
        source='current_version.version_number', read_only=True, default=None)

    class Meta:
        model = AboutPageStatus
        fields = ['status', 'published_at', 'published_by', 'current_version_number']


class AboutPageVersionListSerializer(serializers.ModelSerializer):
    """Lightweight — omits the full snapshot payload for the history list view."""
    created_by_name = serializers.CharField(source='created_by.name', read_only=True, default='')

    class Meta:
        model = AboutPageVersion
        fields = ['id', 'version_number', 'label', 'is_restore_of', 'created_by_name', 'created_at']


class AboutPageVersionDetailSerializer(serializers.ModelSerializer):
    class Meta:
        model = AboutPageVersion
        fields = ['id', 'version_number', 'label', 'snapshot', 'is_restore_of', 'created_by', 'created_at']


# ─── Public serializers (read-only, language-resolved, enabled-only) ──────────

class AboutSectionItemPublicSerializer(serializers.Serializer):
    """
    Resolves translated text for `lang` (falling back to the default-
    language field when no translation row exists) and hides admin-only
    fields. Built as a plain Serializer, not a ModelSerializer, because
    the "which text wins" logic depends on request context (the language),
    not on the model shape.
    """
    def __init__(self, *args, lang=None, **kwargs):
        self.lang = lang
        super().__init__(*args, **kwargs)

    def to_representation(self, item):
        translation = None
        if self.lang:
            translation = next(
                (t for t in item.translations.all() if t.language.code == self.lang), None)
        return {
            'id': item.id,
            'title': (translation.title if translation and translation.title else item.title),
            'subtitle': (translation.subtitle if translation and translation.subtitle else item.subtitle),
            'description': (translation.description if translation and translation.description else item.description),
            'icon': item.icon,
            'image_url': optimized_url(item.image),
            'value': (translation.value if translation and translation.value else item.value),
            'link_url': item.link_url,
            'extra_data': item.extra_data,
            'order': item.order,
            'is_enabled': item.is_enabled,
        }


class AboutSectionPublicSerializer(serializers.Serializer):
    def __init__(self, *args, lang=None, include_disabled=False, **kwargs):
        self.lang = lang
        self.include_disabled = include_disabled
        super().__init__(*args, **kwargs)

    def to_representation(self, section):
        translation = None
        if self.lang:
            translation = next(
                (t for t in section.translations.all() if t.language.code == self.lang), None)
        source_items = section.items.all() if self.include_disabled else (
            i for i in section.items.all() if i.is_enabled)
        sorted_items = sorted(source_items, key=lambda i: i.order)
        return {
            'id': section.id,
            'section_type': section.section_type,
            'section_key': section.section_key,
            'title': (translation.title if translation and translation.title else section.title),
            'subtitle': (translation.subtitle if translation and translation.subtitle else section.subtitle),
            'description': (translation.description if translation and translation.description else section.description),
            'icon': section.icon,
            'image_url': optimized_url(section.image),
            'cta_text': (translation.cta_text if translation and translation.cta_text else section.cta_text),
            'cta_url': section.cta_url,
            'cta_style': section.cta_style,
            'extra_data': section.extra_data,
            'order': section.order,
            'is_enabled': section.is_enabled,
            'items': AboutSectionItemPublicSerializer(sorted_items, many=True, lang=self.lang).data,
        }