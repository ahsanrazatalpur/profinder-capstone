# apps/admin_panel/migrations/0009_country_city_announcement.py
#
# Feature: Countries, Cities (service-area management) & Announcements
# (in-app banner/system messages).

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('admin_panel', '0008_language_translationkey_translationstring'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='Country',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=100, unique=True)),
                ('status', models.CharField(max_length=15, default='coming_soon', choices=[
                    ('active',      'Active'),
                    ('coming_soon', 'Coming Soon'),
                ])),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
            options={'ordering': ['name']},
        ),
        migrations.CreateModel(
            name='City',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=100)),
                ('status', models.CharField(max_length=15, default='coming_soon', choices=[
                    ('active',      'Active'),
                    ('coming_soon', 'Coming Soon'),
                ])),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('country', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='cities', to='admin_panel.country')),
            ],
            options={
                'ordering': ['name'],
                'unique_together': {('name', 'country')},
            },
        ),
        migrations.CreateModel(
            name='Announcement',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title',   models.CharField(max_length=255)),
                ('message', models.TextField()),
                ('type', models.CharField(max_length=15, default='info', choices=[
                    ('info',        'Info'),
                    ('warning',     'Warning'),
                    ('maintenance', 'Maintenance'),
                ])),
                ('audience', models.CharField(max_length=20, default='all', choices=[
                    ('all',           'All Users'),
                    ('customers',     'Customers'),
                    ('professionals', 'Professionals'),
                ])),
                ('is_active',  models.BooleanField(default=True)),
                ('start_date', models.DateTimeField(null=True, blank=True)),
                ('end_date',   models.DateTimeField(null=True, blank=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('created_by', models.ForeignKey(
                    on_delete=django.db.models.deletion.SET_NULL, null=True, blank=True,
                    related_name='announcements_created', to=settings.AUTH_USER_MODEL)),
            ],
            options={'ordering': ['-created_at']},
        ),
    ]