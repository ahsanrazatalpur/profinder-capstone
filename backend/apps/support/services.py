# apps/support/services.py
#
# Language resolution for Help / Policy content.
#
# Rule (agreed): show a translation only if a HUMAN has reviewed it; otherwise
# fall back to English and tell the caller it is a fallback so the UI can say
# "shown in English". Nothing here ever calls a machine-translation provider.

SOURCE_LANGUAGE = 'en'


def resolve_translation(translations, lang):
    """Pick the translation to show for `lang` from an iterable of rows that have
    `.language.code` and `.is_reviewed`.

    Returns (row_or_None, served_lang, is_fallback).
      * reviewed row in `lang`          -> (row, lang, False)
      * else English row (any state)    -> (row, 'en', True)   [English is the source]
      * else                            -> (None, None, True)
    """
    lang = (lang or SOURCE_LANGUAGE).split('-')[0].split('_')[0].lower()
    rows = list(translations)
    by_code = {t.language.code.lower(): t for t in rows}

    wanted = by_code.get(lang)
    if wanted is not None and (wanted.is_reviewed or lang == SOURCE_LANGUAGE):
        return wanted, lang, False

    source = by_code.get(SOURCE_LANGUAGE)
    if source is not None:
        return source, SOURCE_LANGUAGE, lang != SOURCE_LANGUAGE
    return None, None, True
