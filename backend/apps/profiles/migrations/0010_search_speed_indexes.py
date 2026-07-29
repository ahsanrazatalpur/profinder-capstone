# apps/profiles/migrations/0010_search_speed_indexes.py
#
# Adds GIN trigram indexes on every field the Normal Search endpoint
# filters with icontains() — turns full table scans into index scans,
# which is what makes the "fast keyword-based search" requirement real
# once the data grows past a few hundred rows.

from django.contrib.postgres.indexes import GinIndex
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('profiles', '0009_remove_professionalprofile_response_time_hrs'),
        # Ensures the pg_trgm extension is already enabled before these
        # trigram indexes are created.
        ('users', '0004_search_speed_indexes'),
    ]

    operations = [
        migrations.AddIndex(
            model_name='userprofile',
            index=GinIndex(fields=['city'], name='profile_city_trgm_idx', opclasses=['gin_trgm_ops']),
        ),
        migrations.AddIndex(
            model_name='userprofile',
            index=GinIndex(fields=['area'], name='profile_area_trgm_idx', opclasses=['gin_trgm_ops']),
        ),
        migrations.AddIndex(
            model_name='userprofile',
            index=GinIndex(fields=['country'], name='profile_country_trgm_idx', opclasses=['gin_trgm_ops']),
        ),
        migrations.AddIndex(
            model_name='professionalprofile',
            index=GinIndex(fields=['specialization'], name='prof_specialization_trgm_idx', opclasses=['gin_trgm_ops']),
        ),
        migrations.AddIndex(
            model_name='professionalprofile',
            index=GinIndex(fields=['skills'], name='prof_skills_trgm_idx', opclasses=['gin_trgm_ops']),
        ),
        migrations.AddIndex(
            model_name='professionalprofile',
            index=GinIndex(fields=['company_name'], name='prof_company_trgm_idx', opclasses=['gin_trgm_ops']),
        ),
        migrations.AddIndex(
            model_name='professionalprofile',
            index=GinIndex(fields=['services'], name='prof_services_trgm_idx', opclasses=['gin_trgm_ops']),
        ),
        migrations.AddIndex(
            model_name='professionalprofile',
            index=GinIndex(fields=['tags'], name='prof_tags_trgm_idx', opclasses=['gin_trgm_ops']),
        ),
        migrations.AddIndex(
            model_name='professionalprofile',
            index=GinIndex(fields=['bio'], name='prof_bio_trgm_idx', opclasses=['gin_trgm_ops']),
        ),
        migrations.AddIndex(
            model_name='professionalprofile',
            index=models.Index(fields=['hourly_rate'], name='prof_hourly_rate_idx'),
        ),
        migrations.AddIndex(
            model_name='professionalprofile',
            index=models.Index(fields=['average_rating'], name='prof_avg_rating_idx'),
        ),
    ]