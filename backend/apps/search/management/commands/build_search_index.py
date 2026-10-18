# python manage.py build_search_index   (safe to re-run any time)
#
# Works while the website is live: on SQLite another process may hold the
# write lock for a moment ("database is locked"), so every write is retried
# a few times and rows are saved in small batches.
import time

from django.core.management.base import BaseCommand
from django.db import OperationalError, close_old_connections

from apps.search.indexing import build_index_for_user
from apps.users.models import User

RETRIES = 8
WAIT_SECONDS = 2


class Command(BaseCommand):
    help = 'Backfill / rebuild the cross-script SearchIndex for all professionals.'

    def add_arguments(self, parser):
        parser.add_argument('--missing-only', action='store_true',
                            help='only index professionals that have no index row yet')

    def _build_with_retry(self, user):
        for attempt in range(1, RETRIES + 1):
            try:
                build_index_for_user(user)
                return True
            except OperationalError as exc:            # "database is locked"
                if 'locked' not in str(exc).lower() or attempt == RETRIES:
                    raise
                close_old_connections()
                time.sleep(WAIT_SECONDS)
        return False

    def handle(self, *args, **opts):
        qs = (User.objects.filter(role='professional')
              .select_related('professionalprofile__category', 'userprofile'))
        if opts['missing_only']:
            qs = qs.filter(search_index__isnull=True)
        users = list(qs)
        done = 0
        for user in users:
            self._build_with_retry(user)
            done += 1
            if done % 50 == 0:
                self.stdout.write(f'  {done}/{len(users)} ...')
        self.stdout.write(self.style.SUCCESS(f'Indexed {done} professionals.'))