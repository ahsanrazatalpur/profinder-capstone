# apps/about_page/views.py

from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny

from apps.admin_panel.models import Language
from apps.about_page.models import (
    AboutSection, AboutSectionItem,
    AboutSectionTranslation, AboutSectionItemTranslation,
    AboutPageSEO, AboutPageStatus, AboutPageVersion,
)
from apps.about_page.serializers import (
    AboutSectionAdminSerializer, AboutSectionItemAdminSerializer,
    AboutSectionTranslationSerializer, AboutSectionItemTranslationSerializer,
    AboutPageSEOSerializer, AboutPageStatusSerializer,
    AboutPageVersionListSerializer, AboutPageVersionDetailSerializer,
    AboutSectionPublicSerializer,
)
from apps.about_page.utils import upload_about_image, build_snapshot, restore_snapshot


def _is_admin(user):
    return user.is_authenticated and user.role == 'admin'


ADMIN_ONLY = Response({'error': 'Admin only.'}, status=403)


# ─── Sections (admin) ──────────────────────────────────────────────────────────

class AboutSectionAdminListCreateView(APIView):
    """
    GET  /api/about-page/admin/sections/            → all sections, ordered
    POST /api/about-page/admin/sections/             → create a new section
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        sections = AboutSection.objects.prefetch_related(
            'items__translations__language', 'translations__language').all()
        return Response(AboutSectionAdminSerializer(sections, many=True).data)

    def post(self, request):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        serializer = AboutSectionAdminSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        # New sections default to the end of the order
        max_order = AboutSection.objects.order_by('-order').values_list('order', flat=True).first() or 0
        serializer.save(
            created_by=request.user, updated_by=request.user,
            order=request.data.get('order', max_order + 1))
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class AboutSectionAdminDetailView(APIView):
    """
    GET    /api/about-page/admin/sections/<id>/
    PATCH  /api/about-page/admin/sections/<id>/       → partial update (title,
           subtitle, description, icon, image, CTA, enable/disable, extra_data)
    DELETE /api/about-page/admin/sections/<id>/
    """
    permission_classes = [IsAuthenticated]

    def get_object(self, section_id):
        return get_object_or_404(AboutSection, id=section_id)

    def get(self, request, section_id):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        section = self.get_object(section_id)
        return Response(AboutSectionAdminSerializer(section).data)

    def patch(self, request, section_id):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        section = self.get_object(section_id)
        serializer = AboutSectionAdminSerializer(section, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save(updated_by=request.user)
        return Response(serializer.data)

    def delete(self, request, section_id):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        section = self.get_object(section_id)
        section.delete()
        return Response({'message': 'Section deleted.'}, status=204)


class AboutSectionReorderView(APIView):
    """
    POST /api/about-page/admin/sections/reorder/
    Body: { "order": [{"id": 4, "order": 0}, {"id": 1, "order": 1}, ...] }
    Drives the drag-and-drop reorder UI — one call for the whole new order.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        updates = request.data.get('order', [])
        id_to_order = {u['id']: u['order'] for u in updates}
        sections = AboutSection.objects.filter(id__in=id_to_order.keys())
        for section in sections:
            section.order = id_to_order[section.id]
        AboutSection.objects.bulk_update(sections, ['order'])
        return Response({'message': 'Sections reordered.'})


# ─── Section items / dynamic collections (admin) ───────────────────────────────

class AboutSectionItemAdminListCreateView(APIView):
    """
    GET  /api/about-page/admin/sections/<section_id>/items/
    POST /api/about-page/admin/sections/<section_id>/items/
    Unlimited items per collection section (cards, steps, counters,
    members, partners, certifications, awards, values).
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, section_id):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        section = get_object_or_404(AboutSection, id=section_id)
        items = section.items.prefetch_related('translations__language').all()
        return Response(AboutSectionItemAdminSerializer(items, many=True).data)

    def post(self, request, section_id):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        section = get_object_or_404(AboutSection, id=section_id)
        max_order = section.items.order_by('-order').values_list('order', flat=True).first() or 0
        serializer = AboutSectionItemAdminSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(section=section, order=request.data.get('order', max_order + 1))
        return Response(serializer.data, status=201)


class AboutSectionItemAdminDetailView(APIView):
    """
    GET/PATCH/DELETE /api/about-page/admin/items/<id>/
    """
    permission_classes = [IsAuthenticated]

    def get_object(self, item_id):
        return get_object_or_404(AboutSectionItem, id=item_id)

    def get(self, request, item_id):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        return Response(AboutSectionItemAdminSerializer(self.get_object(item_id)).data)

    def patch(self, request, item_id):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        item = self.get_object(item_id)
        serializer = AboutSectionItemAdminSerializer(item, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)

    def delete(self, request, item_id):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        self.get_object(item_id).delete()
        return Response({'message': 'Item deleted.'}, status=204)


class AboutSectionItemReorderView(APIView):
    """
    POST /api/about-page/admin/sections/<section_id>/items/reorder/
    Body: { "order": [{"id": 12, "order": 0}, {"id": 9, "order": 1}, ...] }
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, section_id):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        updates = request.data.get('order', [])
        id_to_order = {u['id']: u['order'] for u in updates}
        items = AboutSectionItem.objects.filter(section_id=section_id, id__in=id_to_order.keys())
        for item in items:
            item.order = id_to_order[item.id]
        AboutSectionItem.objects.bulk_update(items, ['order'])
        return Response({'message': 'Items reordered.'})


# ─── Multilingual content (admin) ──────────────────────────────────────────────

class AboutSectionTranslationAdminView(APIView):
    """
    PUT /api/about-page/admin/sections/<section_id>/translations/<language_id>/
    Upserts the translation for one (section, language) pair — the admin's
    language tab saves one language at a time.
    """
    permission_classes = [IsAuthenticated]

    def put(self, request, section_id, language_id):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        section = get_object_or_404(AboutSection, id=section_id)
        language = get_object_or_404(Language, id=language_id)
        translation, _ = AboutSectionTranslation.objects.get_or_create(
            section=section, language=language)
        serializer = AboutSectionTranslationSerializer(translation, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)

    def delete(self, request, section_id, language_id):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        AboutSectionTranslation.objects.filter(
            section_id=section_id, language_id=language_id).delete()
        return Response({'message': 'Translation removed — default-language text will show instead.'}, status=204)


class AboutSectionItemTranslationAdminView(APIView):
    """PUT/DELETE /api/about-page/admin/items/<item_id>/translations/<language_id>/"""
    permission_classes = [IsAuthenticated]

    def put(self, request, item_id, language_id):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        item = get_object_or_404(AboutSectionItem, id=item_id)
        language = get_object_or_404(Language, id=language_id)
        translation, _ = AboutSectionItemTranslation.objects.get_or_create(
            item=item, language=language)
        serializer = AboutSectionItemTranslationSerializer(translation, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)

    def delete(self, request, item_id, language_id):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        AboutSectionItemTranslation.objects.filter(
            item_id=item_id, language_id=language_id).delete()
        return Response({'message': 'Translation removed.'}, status=204)


# ─── Image upload (admin) ──────────────────────────────────────────────────────

class AboutImageUploadView(APIView):
    """
    POST /api/about-page/admin/upload-image/
    Body: multipart/form-data, key = 'image'
    Response: { 'url': '<optimized delivery url>' }

    The returned URL already has Cloudinary's f_auto/q_auto transform
    baked in (WebP where the browser supports it, auto compression),
    covering "automatic compression and WebP optimization" without any
    separate image-processing step. Attach the URL to a section/item's
    `image` field on the next PATCH to replace it; upload again with a
    new file to swap the preview before saving.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        image = request.FILES.get('image')
        if not image:
            return Response({'error': 'No image file provided.'}, status=400)
        try:
            public_id, url = upload_about_image(image)
            return Response({'url': url, 'public_id': public_id})
        except Exception as e:
            return Response({'error': f'Upload failed: {str(e)}'}, status=500)


# ─── SEO (admin) ────────────────────────────────────────────────────────────────

class AboutPageSEOAdminView(APIView):
    """GET/PATCH /api/about-page/admin/seo/ — singleton SEO record."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        return Response(AboutPageSEOSerializer(AboutPageSEO.load()).data)

    def patch(self, request):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        seo = AboutPageSEO.load()
        serializer = AboutPageSEOSerializer(seo, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save(updated_by=request.user)
        return Response(serializer.data)


# ─── Publish workflow (admin) ──────────────────────────────────────────────────

class AboutPageStatusAdminView(APIView):
    """GET /api/about-page/admin/status/ — current draft/published state."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        return Response(AboutPageStatusSerializer(AboutPageStatus.load()).data)


class AboutPagePreviewView(APIView):
    """
    GET /api/about-page/admin/preview/?lang=en&include_disabled=true
    Renders the *live draft* tables (whatever the admin currently has
    saved, published or not) through the same shape the public endpoint
    uses, so "Preview" shows exactly what Publish would push live.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        lang = request.query_params.get('lang')
        include_disabled = request.query_params.get('include_disabled') == 'true'

        qs = AboutSection.objects.prefetch_related(
            'items__translations__language', 'translations__language')
        if not include_disabled:
            qs = qs.filter(is_enabled=True)
        sections = sorted(qs.all(), key=lambda s: s.order)

        seo = AboutPageSEO.load()
        return Response({
            'sections': AboutSectionPublicSerializer(
                sections, many=True, lang=lang, include_disabled=include_disabled).data,
            'seo': AboutPageSEOSerializer(seo).data,
            'is_preview': True,
        })


class AboutPagePublishView(APIView):
    """
    POST /api/about-page/admin/publish/
    Body (optional): { "label": "Added new certifications" }
    Snapshots the entire live draft state as a new version and marks it
    as the currently-published version. The public endpoint immediately
    starts serving this snapshot.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        last_version = AboutPageVersion.objects.order_by('-version_number').first()
        next_number = (last_version.version_number + 1) if last_version else 1

        version = AboutPageVersion.objects.create(
            version_number=next_number,
            snapshot=build_snapshot(),
            label=request.data.get('label', ''),
            created_by=request.user,
        )
        page_status = AboutPageStatus.load()
        page_status.status = 'published'
        page_status.published_at = timezone.now()
        page_status.published_by = request.user
        page_status.current_version = version
        page_status.save()

        return Response({
            'message': f'About Page published as version {next_number}.',
            'status': AboutPageStatusSerializer(page_status).data,
        })


class AboutPageUnpublishView(APIView):
    """
    POST /api/about-page/admin/unpublish/
    Takes the About page off the public API without deleting any content
    or version history — the public endpoint responds as "not published"
    until Publish is pressed again.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        page_status = AboutPageStatus.load()
        page_status.status = 'unpublished'
        page_status.save()
        return Response({
            'message': 'About Page unpublished.',
            'status': AboutPageStatusSerializer(page_status).data,
        })


class AboutPageVersionListView(APIView):
    """GET /api/about-page/admin/versions/ — version history list."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        versions = AboutPageVersion.objects.select_related('created_by').all()
        return Response(AboutPageVersionListSerializer(versions, many=True).data)


class AboutPageVersionDetailView(APIView):
    """GET /api/about-page/admin/versions/<id>/ — full snapshot for inspection/diffing."""
    permission_classes = [IsAuthenticated]

    def get(self, request, version_id):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        version = get_object_or_404(AboutPageVersion, id=version_id)
        return Response(AboutPageVersionDetailSerializer(version).data)


class AboutPageVersionRestoreView(APIView):
    """
    POST /api/about-page/admin/versions/<id>/restore/
    Replays a historical snapshot back onto the live *draft* tables. Does
    NOT auto-publish — the admin reviews via Preview and hits Publish to
    make the restored content go live, same as any other draft edit.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, version_id):
        if not _is_admin(request.user):
            return ADMIN_ONLY
        version = get_object_or_404(AboutPageVersion, id=version_id)
        restore_snapshot(version.snapshot)
        return Response({
            'message': f'Draft restored from version {version.version_number}. '
                       f'Review in Preview, then Publish to make it live.',
        })


# ─── Public API (Guest, Customer, Professional, Admin — all read-only) ────────

class AboutPagePublicView(APIView):
    """
    GET /api/about-page/?lang=en
    No authentication required. Serves the last *published* snapshot only
    — draft edits never leak here until an admin publishes them. Every
    role (guest, customer, professional, admin) reads through this same
    endpoint; editing is only ever possible via the /admin/ endpoints.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        page_status = AboutPageStatus.load()
        if page_status.status != 'published' or not page_status.current_version:
            return Response({'error': 'About page is not currently published.'}, status=404)

        lang = request.query_params.get('lang')
        snapshot = page_status.current_version.snapshot
        sections = [s for s in snapshot.get('sections', []) if s.get('is_enabled', True)]
        sections.sort(key=lambda s: s.get('order', 0))

        def resolve(text_default, translations, field):
            if lang:
                match = next((t for t in translations if t.get('language_code') == lang), None)
                if match and match.get(field):
                    return match[field]
            return text_default

        rendered_sections = []
        for s in sections:
            items = [i for i in s.get('items', []) if i.get('is_enabled', True)]
            items.sort(key=lambda i: i.get('order', 0))
            rendered_items = [{
                'id': None,
                'title': resolve(i.get('title', ''), i.get('translations', []), 'title'),
                'subtitle': resolve(i.get('subtitle', ''), i.get('translations', []), 'subtitle'),
                'description': resolve(i.get('description', ''), i.get('translations', []), 'description'),
                'icon': i.get('icon', ''),
                'image_url': i.get('image', ''),
                'value': resolve(i.get('value', ''), i.get('translations', []), 'value'),
                'link_url': i.get('link_url', ''),
                'extra_data': i.get('extra_data', {}),
                'order': i.get('order', 0),
            } for i in items]

            rendered_sections.append({
                'section_type': s.get('section_type', 'custom'),
                'section_key': s.get('section_key'),
                'title': resolve(s.get('title', ''), s.get('translations', []), 'title'),
                'subtitle': resolve(s.get('subtitle', ''), s.get('translations', []), 'subtitle'),
                'description': resolve(s.get('description', ''), s.get('translations', []), 'description'),
                'icon': s.get('icon', ''),
                'image_url': s.get('image', ''),
                'cta_text': resolve(s.get('cta_text', ''), s.get('translations', []), 'cta_text'),
                'cta_url': s.get('cta_url', ''),
                'cta_style': s.get('cta_style', 'primary'),
                'extra_data': s.get('extra_data', {}),
                'order': s.get('order', 0),
                'items': rendered_items,
            })

        return Response({
            'sections': rendered_sections,
            'seo': snapshot.get('seo', {}),
            'version': page_status.current_version.version_number,
            'published_at': page_status.published_at,
        })