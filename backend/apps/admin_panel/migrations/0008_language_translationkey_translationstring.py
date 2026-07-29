# apps/admin_panel/migrations/0008_language_translationkey_translationstring.py
#
# Feature: Languages & Translations (multi-language content management).

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('admin_panel', '0007_notificationbroadcast'),
    ]

    operations = [
        migrations.CreateModel(
            name='Language',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name',   models.CharField(max_length=50)),
                ('code',   models.CharField(max_length=10, unique=True)),
                ('is_rtl', models.BooleanField(default=False)),
                ('status', models.CharField(max_length=10, default='beta', choices=[
                    ('active',   'Active'),
                    ('beta',     'Beta'),
                    ('disabled', 'Disabled'),
                ])),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
            options={'ordering': ['name']},
        ),
        migrations.CreateModel(
            name='TranslationKey',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('key',         models.CharField(max_length=255, unique=True)),
                ('description', models.CharField(max_length=255, blank=True)),
                ('created_at',  models.DateTimeField(auto_now_add=True)),
            ],
            options={'ordering': ['key']},
        ),
        migrations.CreateModel(
            name='TranslationString',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('text',       models.TextField(blank=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('key', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='translations', to='admin_panel.translationkey')),
                ('language', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='translations', to='admin_panel.language')),
            ],
            options={'unique_together': {('language', 'key')}},
        ),
    ]