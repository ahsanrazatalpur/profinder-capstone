# apps/admin_panel/migrations/0007_notificationbroadcast.py
#
# Feature: Notification Broadcasts (admin sends/schedules push notifications
# to all users, a segment, or one specific user).

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('admin_panel', '0006_complaint'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='NotificationBroadcast',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title',   models.CharField(max_length=255)),
                ('message', models.TextField()),
                ('audience', models.CharField(max_length=20, default='all', choices=[
                    ('all',           'All Users'),
                    ('customers',     'Customers'),
                    ('professionals', 'Professionals'),
                    ('specific',      'Specific User'),
                ])),
                ('status', models.CharField(max_length=20, default='scheduled', choices=[
                    ('scheduled', 'Scheduled'),
                    ('sent',      'Sent'),
                    ('cancelled', 'Cancelled'),
                    ('failed',    'Failed'),
                ])),
                ('scheduled_at',  models.DateTimeField(null=True, blank=True)),
                ('sent_at',       models.DateTimeField(null=True, blank=True)),
                ('sent_count',    models.PositiveIntegerField(default=0)),
                ('opened_count',  models.PositiveIntegerField(default=0)),
                ('created_at',    models.DateTimeField(auto_now_add=True)),
                ('created_by', models.ForeignKey(
                    on_delete=django.db.models.deletion.SET_NULL, null=True, blank=True,
                    related_name='broadcasts_created', to=settings.AUTH_USER_MODEL)),
                ('specific_user', models.ForeignKey(
                    on_delete=django.db.models.deletion.SET_NULL, null=True, blank=True,
                    related_name='targeted_broadcasts', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['-created_at'],
            },
        ),
    ]