# apps/support/presenters.py
#
# Turns Help / Policy rows into Flutter-friendly JSON. No DB writes, no network.
#
# Body format (plain text, stored in the DB):
#   "# Heading"      -> {"type": "heading", "text": "Heading"}
#   "- item"         -> {"type": "bullet",  "text": "item"}
#   blank-line paras -> {"type": "paragraph", "text": "..."}
# The client renders `blocks`; `body` is also returned for plain-text fallback.

from apps.support.services import resolve_translation


def parse_blocks(body):
    blocks = []
    para = []

    def flush():
        if para:
            blocks.append({'type': 'paragraph', 'text': ' '.join(para).strip()})
            para.clear()

    for raw in (body or '').replace('\r\n', '\n').split('\n'):
        line = raw.strip()
        if not line:
            flush()
        elif line.startswith('# '):
            flush()
            blocks.append({'type': 'heading', 'text': line[2:].strip()})
        elif line.startswith('- '):
            flush()
            blocks.append({'type': 'bullet', 'text': line[2:].strip()})
        else:
            para.append(line)
    flush()
    return blocks


def _lang_meta(row, served, is_fallback, requested):
    return {
        'language': served,
        'requested_language': (requested or 'en').split('-')[0].split('_')[0].lower(),
        'is_fallback': is_fallback,
        'is_rtl': bool(row.language.is_rtl),
    }


def present_policy(version, lang):
    row, served, is_fallback = resolve_translation(version.translations.all(), lang)
    if row is None:
        return None
    data = {
        'doc_type': version.document.doc_type,
        'version': version.version_number,
        'effective_date': version.effective_date.isoformat() if version.effective_date else None,
        'published_at': version.published_at.isoformat() if version.published_at else None,
        'change_summary': version.change_summary,
        'title': row.title,
        'body': row.body,
        'blocks': parse_blocks(row.body),
    }
    data.update(_lang_meta(row, served, is_fallback, lang))
    return data


def present_category(category, lang, article_count):
    row, served, is_fallback = resolve_translation(category.translations.all(), lang)
    if row is None:
        return None
    data = {
        'slug': category.slug,
        'icon_key': category.icon_key,
        'order': category.order,
        'title': row.title,
        'description': row.description,
        'article_count': article_count,
    }
    data.update(_lang_meta(row, served, is_fallback, lang))
    return data


def present_article(article, lang, with_body):
    row, served, is_fallback = resolve_translation(article.translations.all(), lang)
    if row is None:
        return None
    data = {
        'slug': article.slug,
        'category_slug': article.category.slug,
        'order': article.order,
        'title': row.title,
        'updated_at': row.updated_at.isoformat(),
    }
    if with_body:
        data['body'] = row.body
        data['blocks'] = parse_blocks(row.body)
    else:
        text = ' '.join(b['text'] for b in parse_blocks(row.body)[:2])
        data['snippet'] = text[:160]
    data.update(_lang_meta(row, served, is_fallback, lang))
    return data
