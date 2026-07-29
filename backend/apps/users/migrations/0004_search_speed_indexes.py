# apps/users/migrations/0004_search_speed_indexes.py
#
# Enables Postgres pg_trgm extension (needed for GIN trigram indexes that
# power fast icontains() keyword search) and indexes User.name + User.role,
# which are queried on every Normal Search request.

from django.contrib.postgres.operations import TrigramExtension
from django.contrib.postgres.indexes import GinIndex
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0003_user_fcm_token'),
    ]

    operations = [
        TrigramExtension(),
        migrations.AddIndex(
            model_name='user',
            index=GinIndex(fields=['name'], name='user_name_trgm_idx', opclasses=['gin_trgm_ops']),
        ),
        migrations.AddIndex(
            model_name='user',
            index=models.Index(fields=['role'], name='user_role_idx'),
        ),
    ]