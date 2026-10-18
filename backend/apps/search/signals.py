# apps/search/signals.py
#
# Keeps SearchIndex in sync. Failures must NEVER break a profile save, so
# every handler swallows (and logs) its own errors.

import logging

from django.db import transaction
from django.db.models.signals import post_save
from django.dispatch import receiver

from apps.profiles.models import ProfessionalProfile, UserProfile
from apps.search.indexing import build_index_for_user
from apps.search.models import Category, SearchAlias
from apps.users.models import User

log = logging.getLogger(__name__)


def _reindex_later(user_id):
    def _run():
        try:
            user = (User.objects
                    .select_related('professionalprofile__category', 'userprofile')
                    .get(pk=user_id))
            build_index_for_user(user)
        except Exception:                      # pragma: no cover
            log.exception('search index rebuild failed for user %s', user_id)
    transaction.on_commit(_run)


@receiver(post_save, sender=User)
def _user_saved(sender, instance, **kwargs):
    _reindex_later(instance.pk)


@receiver(post_save, sender=ProfessionalProfile)
def _pro_profile_saved(sender, instance, **kwargs):
    _reindex_later(instance.user_id)


@receiver(post_save, sender=UserProfile)
def _user_profile_saved(sender, instance, **kwargs):
    _reindex_later(instance.user_id)


@receiver(post_save, sender=Category)
def _category_saved(sender, instance, **kwargs):
    # a renamed category changes the searchable text of everyone in it
    for uid in (ProfessionalProfile.objects
                .filter(category_id=instance.pk).values_list('user_id', flat=True)):
        _reindex_later(uid)


@receiver(post_save, sender=SearchAlias)
def _alias_saved(sender, instance, **kwargs):
    from apps.search.aliases import reload_aliases
    reload_aliases()