# Generated for the "Reported Users" feature (UserReport model)

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('admin_panel', '0004_alter_adminlog_action_alter_adminlog_target_user_and_more'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.AlterField(
            model_name='adminlog',
            name='action',
            field=models.CharField(choices=[
                ('verify', 'Verify Professional'),
                ('ban', 'Ban User'),
                ('unban', 'Unban User'),
                ('delete', 'Delete Content'),
                ('approve', 'Approve Portfolio'),
                ('reject', 'Reject Portfolio'),
                ('cancel_booking', 'Cancel Booking'),
                ('create_banner', 'Create Banner'),
                ('edit_banner', 'Edit Banner'),
                ('remind', 'Send Reminder'),
                ('report_reviewed', 'Report Reviewed'),
                ('report_dismissed', 'Report Dismissed'),
            ], max_length=20),
        ),
        migrations.CreateModel(
            name='UserReport',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('reason', models.CharField(choices=[
                    ('spam', 'Spam'),
                    ('harassment', 'Harassment or Abuse'),
                    ('fraud', 'Fraud or Scam'),
                    ('fake_profile', 'Fake Profile'),
                    ('inappropriate_content', 'Inappropriate Content'),
                    ('other', 'Other'),
                ], max_length=30)),
                ('description', models.TextField(blank=True)),
                ('status', models.CharField(choices=[
                    ('pending', 'Pending Review'),
                    ('reviewed', 'Reviewed'),
                    ('action_taken', 'Action Taken'),
                    ('dismissed', 'Dismissed'),
                ], default='pending', max_length=20)),
                ('admin_note', models.TextField(blank=True)),
                ('reviewed_at', models.DateTimeField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('reported_user', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='reports_received', to=settings.AUTH_USER_MODEL)),
                ('reporter', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='reports_made', to=settings.AUTH_USER_MODEL)),
                ('reviewed_by', models.ForeignKey(
                    blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL,
                    related_name='reports_reviewed', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['-created_at'],
            },
        ),
        migrations.AddIndex(
            model_name='userreport',
            index=models.Index(fields=['status'], name='report_status_idx'),
        ),
        migrations.AddIndex(
            model_name='userreport',
            index=models.Index(fields=['reported_user'], name='report_target_idx'),
        ),
    ]