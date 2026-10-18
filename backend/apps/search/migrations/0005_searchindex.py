# apps/search/migrations/0005_searchindex.py
#
# Cross-script / typo-tolerant search index.
# * pg_trgm extension: no-op on non-PostgreSQL databases.
# * Trigram GIN indexes: created only on PostgreSQL (RunPython), so the same
#   migration also runs on SQLite for local development.

import django.db.models.deletion
from django.conf import settings
from django.contrib.postgres.operations import TrigramExtension
from django.db import migrations, models

_INDEXES = (
    ('sidx_latin_trgm_idx',    'latin_text'),
    ('sidx_phonetic_trgm_idx', 'phonetic_text'),
    ('sidx_native_trgm_idx',   'native_text'),
)


def create_trgm_indexes(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return
    for name, col in _INDEXES:
        schema_editor.execute(
            f'CREATE INDEX IF NOT EXISTS {name} ON search_searchindex '
            f'USING gin ({col} gin_trgm_ops)'
        )


def drop_trgm_indexes(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return
    for name, _ in _INDEXES:
        schema_editor.execute(f'DROP INDEX IF EXISTS {name}')


class Migration(migrations.Migration):

    dependencies = [
        ('search', '0004_category_is_featured'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        TrigramExtension(),
        migrations.CreateModel(
            name='SearchIndex',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('native_text', models.TextField(blank=True, default='')),
                ('latin_text', models.TextField(blank=True, default='')),
                ('phonetic_text', models.TextField(blank=True, default='')),
                ('name_latin', models.CharField(blank=True, default='', max_length=300)),
                ('name_phonetic', models.CharField(blank=True, default='', max_length=300)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('user', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='search_index', to=settings.AUTH_USER_MODEL)),
            ],
        ),
        migrations.RunPython(create_trgm_indexes, drop_trgm_indexes),
    ]
