# apps/support/admin_content_views.py
#
# Part 9: admin editor for the Privacy Policy and Help Center articles
# (English-only staff tooling, so admins do not need the Django admin site).
#
#   GET   /api/support/admin/policy/                    versions of the privacy policy
#   POST  /api/support/admin/policy/                    start a new DRAFT version
#   GET   /api/support/admin/policy/<id>/               one version (English text)
#   PATCH /api/support/admin/policy/<id>/               edit a DRAFT (title/body/date/summary)
#   POST  /api/support/admin/policy/<id>/publish/       publish a DRAFT (archives the old one)
#
#   GET   /api/support/admin/help/categories/           category picker
#   GET   /api/support/admin/help/articles/             all articles (+ q / published filters)
#   POST  /api/support/admin/help/articles/             create (always starts unpublished)
#   GET   /api/support/admin/help/articles/<id>/        one article
#   PATCH /api/support/admin/help/articles/<id>/        edit / publish / unpublish
#   DELETE /api/support/admin/help/articles/<id>/       delete (unpublished only)
#
# Rules:
#   * Admin only (`user.role == 'admin'`), same check as the ticket inbox.
#   * Only the ENGLISH text is edited here. Other languages stay in the Django
#     admin because they need human review (`is_reviewed`).
#   * A published / archived policy version is immutable (the model enforces it);
#     a change means a new draft version.
#   * A policy with an unfilled "[PLACEHOLDER" marker can never be published.

import datetime

from django.db import transaction
from django.shortcuts import get_object_or_404
from django.utils.text import slugify
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.admin_panel.models import Language
from apps.support.admin_views import _forbidden, _is_admin
from apps.support.models import (
    AUDIENCE_CHOICES, HelpArticle, HelpArticleTranslation, HelpCategory,
    PolicyDocument, PolicyTranslation, PolicyVersion,
)

PLACEHOLDER_MARK = '[PLACEHOLDER'
AUDIENCE_KEYS = [k for k, _ in AUDIENCE_CHOICES]
MAX_TITLE = 200
MAX_POLICY_BODY = 60000
MAX_ARTICLE_BODY = 20000
MAX_SUMMARY = 500


def _error(message, status=400):
    return Response({'error': message}, status=status)


def _english():
    return Language.objects.filter(code='en').first()


def _clean_text(value, field, maximum, required=True):
    """Return (clean_text, error_message)."""
    if not isinstance(value, str):
        return None, f'{field} must be text.'
    text = value.replace('\r\n', '\n').strip()
    if required and not text:
        return None, f'{field} is required.'
    if len(text) > maximum:
        return None, f'{field} is too long (max {maximum} characters).'
    return text, None


class _AdminView(APIView):
    permission_classes = [IsAuthenticated]


# ─── Privacy policy ──────────────────────────────────────────────────────────

def _privacy_document():
    doc, _ = PolicyDocument.objects.get_or_create(doc_type=PolicyDocument.TYPE_PRIVACY)
    return doc


def _english_row(version):
    return next((t for t in version.translations.all() if t.language.code == 'en'), None)


def _policy_summary(version):
    row = _english_row(version)
    return {
        'id': version.pk,
        'version': version.version_number,
        'status': version.status,
        'is_locked': version.is_locked,
        'effective_date': version.effective_date.isoformat() if version.effective_date else None,
        'published_at': version.published_at.isoformat() if version.published_at else None,
        'change_summary': version.change_summary,
        'title': row.title if row else '',
        'placeholders_left': row.body.count(PLACEHOLDER_MARK) if row else 0,
        'updated_at': row.updated_at.isoformat() if row else version.created_at.isoformat(),
    }


def _policy_detail(version):
    row = _english_row(version)
    data = _policy_summary(version)
    data['body'] = row.body if row else ''
    return data


def _versions_qs():
    return (PolicyVersion.objects.filter(document=_privacy_document())
            .prefetch_related('translations__language'))


class AdminPolicyListView(_AdminView):
    def get(self, request):
        if not _is_admin(request.user):
            return _forbidden()
        return Response({'results': [_policy_summary(v) for v in _versions_qs()]})

    @transaction.atomic
    def post(self, request):
        """Start a new DRAFT, copied from the newest version."""
        if not _is_admin(request.user):
            return _forbidden()
        doc = _privacy_document()
        versions = list(_versions_qs())
        if any(v.status == PolicyVersion.STATUS_DRAFT for v in versions):
            return _error('There is already a draft. Finish or publish it first.', 409)
        english = _english()
        if english is None:
            return _error("The 'en' language is missing. Create it first.", 409)

        source = versions[0] if versions else None
        source_row = _english_row(source) if source else None
        number = (source.version_number + 1) if source else 1
        draft = PolicyVersion.objects.create(
            document=doc, version_number=number, created_by=request.user,
            change_summary='' if source else 'Initial version (draft)')
        PolicyTranslation.objects.create(
            version=draft, language=english,
            title=source_row.title if source_row else 'Privacy Policy',
            body=source_row.body if source_row else '',
            is_reviewed=True)
        draft = _versions_qs().get(pk=draft.pk)
        return Response(_policy_detail(draft), status=201)


class AdminPolicyDetailView(_AdminView):
    def get(self, request, pk):
        if not _is_admin(request.user):
            return _forbidden()
        version = get_object_or_404(_versions_qs(), pk=pk)
        return Response(_policy_detail(version))

    @transaction.atomic
    def patch(self, request, pk):
        if not _is_admin(request.user):
            return _forbidden()
        version = get_object_or_404(_versions_qs().select_for_update(of=('self',)), pk=pk)
        if version.is_locked:
            return _error('A published policy version cannot be edited. '
                          'Start a new version instead.', 409)
        data = request.data
        row = _english_row(version)
        if row is None:
            english = _english()
            if english is None:
                return _error("The 'en' language is missing. Create it first.", 409)
            row = PolicyTranslation(version=version, language=english, title='Privacy Policy',
                                    body='', is_reviewed=True)

        if 'title' in data:
            text, err = _clean_text(data['title'], 'Title', MAX_TITLE)
            if err:
                return _error(err)
            row.title = text
        if 'body' in data:
            text, err = _clean_text(data['body'], 'Text', MAX_POLICY_BODY)
            if err:
                return _error(err)
            row.body = text
        if 'change_summary' in data:
            text, err = _clean_text(data['change_summary'], 'Change summary', MAX_SUMMARY,
                                    required=False)
            if err:
                return _error(err)
            version.change_summary = text
        if 'effective_date' in data:
            raw = data['effective_date']
            if raw in (None, ''):
                version.effective_date = None
            else:
                try:
                    version.effective_date = datetime.date.fromisoformat(str(raw))
                except ValueError:
                    return _error('Effective date must look like 2026-10-31.')

        row.is_reviewed = True  # English is the source text
        row.save()
        version.save()
        return Response(_policy_detail(_versions_qs().get(pk=pk)))


class AdminPolicyPublishView(_AdminView):
    @transaction.atomic
    def post(self, request, pk):
        if not _is_admin(request.user):
            return _forbidden()
        version = get_object_or_404(_versions_qs().select_for_update(of=('self',)), pk=pk)
        if version.status != PolicyVersion.STATUS_DRAFT:
            return _error('Only a draft can be published.', 409)
        row = _english_row(version)
        if row is None or not row.body.strip() or not row.title.strip():
            return _error('Add the English title and text before publishing.')
        left = row.body.count(PLACEHOLDER_MARK)
        if left:
            return _error(f'{left} [PLACEHOLDER] marker(s) are still in the text. '
                          'Fill them in before publishing.')

        # One published version at a time: retire the current one.
        for old in PolicyVersion.objects.filter(document=version.document,
                                                status=PolicyVersion.STATUS_PUBLISHED):
            old.status = PolicyVersion.STATUS_ARCHIVED
            old.save()

        if version.effective_date is None:
            version.effective_date = datetime.date.today()
        version.status = PolicyVersion.STATUS_PUBLISHED
        version.save()
        return Response(_policy_detail(_versions_qs().get(pk=pk)))


# ─── Help articles ───────────────────────────────────────────────────────────

def _en_translation(obj):
    return next((t for t in obj.translations.all() if t.language.code == 'en'), None)


def _article_summary(article):
    row = _en_translation(article)
    return {
        'id': article.pk,
        'slug': article.slug,
        'category_id': article.category_id,
        'category_title': (_en_translation(article.category).title
                           if _en_translation(article.category) else article.category.slug),
        'audience': article.audience,
        'order': article.order,
        'is_published': article.is_published,
        'title': row.title if row else '',
        'updated_at': (row.updated_at if row else article.updated_at).isoformat(),
    }


def _article_detail(article):
    row = _en_translation(article)
    data = _article_summary(article)
    data['body'] = row.body if row else ''
    return data


def _articles_qs():
    return (HelpArticle.objects.select_related('category')
            .prefetch_related('translations__language', 'category__translations__language'))


class AdminHelpCategoryListView(_AdminView):
    def get(self, request):
        if not _is_admin(request.user):
            return _forbidden()
        cats = (HelpCategory.objects.prefetch_related('translations__language')
                .order_by('order', 'slug'))
        return Response({'results': [{
            'id': c.pk,
            'slug': c.slug,
            'audience': c.audience,
            'title': (_en_translation(c).title if _en_translation(c) else c.slug),
        } for c in cats]})


def _unique_slug(title):
    base = slugify(title)[:100] or 'article'
    slug, n = base, 2
    while HelpArticle.objects.filter(slug=slug).exists():
        slug = f'{base}-{n}'
        n += 1
    return slug


class AdminHelpArticleListView(_AdminView):
    def get(self, request):
        if not _is_admin(request.user):
            return _forbidden()
        qs = _articles_qs()
        published = request.query_params.get('published')
        if published in ('1', 'true'):
            qs = qs.filter(is_published=True)
        elif published in ('0', 'false'):
            qs = qs.filter(is_published=False)
        q = (request.query_params.get('q') or '').strip().lower()
        if q:
            qs = qs.filter(translations__search_text__icontains=q).distinct()
        return Response({'results': [_article_summary(a) for a in qs]})

    @transaction.atomic
    def post(self, request):
        if not _is_admin(request.user):
            return _forbidden()
        data = request.data
        english = _english()
        if english is None:
            return _error("The 'en' language is missing. Create it first.", 409)
        title, err = _clean_text(data.get('title'), 'Title', MAX_TITLE)
        if err:
            return _error(err)
        body, err = _clean_text(data.get('body'), 'Text', MAX_ARTICLE_BODY)
        if err:
            return _error(err)
        category = HelpCategory.objects.filter(pk=data.get('category_id')).first() \
            if str(data.get('category_id', '')).isdigit() else None
        if category is None:
            return _error('Choose a category.')
        audience = data.get('audience', 'all')
        if audience not in AUDIENCE_KEYS:
            return _error('Invalid audience.')

        article = HelpArticle.objects.create(
            category=category, slug=_unique_slug(title), audience=audience,
            order=HelpArticle.objects.filter(category=category).count(), is_published=False)
        HelpArticleTranslation.objects.create(
            article=article, language=english, title=title, body=body, is_reviewed=True)
        return Response(_article_detail(_articles_qs().get(pk=article.pk)), status=201)


class AdminHelpArticleDetailView(_AdminView):
    def get(self, request, pk):
        if not _is_admin(request.user):
            return _forbidden()
        return Response(_article_detail(get_object_or_404(_articles_qs(), pk=pk)))

    @transaction.atomic
    def patch(self, request, pk):
        if not _is_admin(request.user):
            return _forbidden()
        article = get_object_or_404(_articles_qs(), pk=pk)
        data = request.data
        row = _en_translation(article)
        if row is None:
            english = _english()
            if english is None:
                return _error("The 'en' language is missing. Create it first.", 409)
            row = HelpArticleTranslation(article=article, language=english, title='', body='',
                                         is_reviewed=True)

        if 'title' in data:
            text, err = _clean_text(data['title'], 'Title', MAX_TITLE)
            if err:
                return _error(err)
            row.title = text
        if 'body' in data:
            text, err = _clean_text(data['body'], 'Text', MAX_ARTICLE_BODY)
            if err:
                return _error(err)
            row.body = text
        if 'audience' in data:
            if data['audience'] not in AUDIENCE_KEYS:
                return _error('Invalid audience.')
            article.audience = data['audience']
        if 'category_id' in data:
            category = HelpCategory.objects.filter(pk=data['category_id']).first() \
                if str(data['category_id']).isdigit() else None
            if category is None:
                return _error('Choose a category.')
            article.category = category
        if 'order' in data:
            try:
                article.order = max(int(data['order']), 0)
            except (TypeError, ValueError):
                return _error('Order must be a number.')
        if 'is_published' in data:
            if not isinstance(data['is_published'], bool):
                return _error('is_published must be true or false.')
            if data['is_published'] and not (row.title.strip() and row.body.strip()):
                return _error('Add a title and text before publishing.')
            article.is_published = data['is_published']

        row.is_reviewed = True  # English is the source text
        row.save()
        article.save()
        return Response(_article_detail(_articles_qs().get(pk=pk)))

    def delete(self, request, pk):
        if not _is_admin(request.user):
            return _forbidden()
        article = get_object_or_404(HelpArticle, pk=pk)
        if article.is_published:
            return _error('Unpublish this article before deleting it.', 409)
        article.delete()
        return Response(status=204)
