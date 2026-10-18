from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('ai_engine', '0002_localizedtext'),
    ]

    operations = [
        migrations.AddField('localizedtext', 'source_lang', models.CharField(default='en', max_length=10)),
        migrations.AddField('localizedtext', 'status', models.CharField(
            choices=[('auto', 'Automatic'), ('manual', 'Manual (admin-approved)')], default='auto', max_length=10)),
        migrations.AddField('localizedtext', 'content_ref', models.CharField(blank=True, default='', help_text="Optional origin, e.g. 'search.Category.name'", max_length=120)),
        migrations.AddField('localizedtext', 'version', models.PositiveSmallIntegerField(default=1)),
        migrations.AddField('localizedtext', 'updated_at', models.DateTimeField(auto_now=True)),
        migrations.AddIndex('localizedtext', models.Index(fields=['lang', 'source_key'], name='loctext_lang_key_idx')),
    ]
