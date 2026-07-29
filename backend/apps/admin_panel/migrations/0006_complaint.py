# apps/admin_panel/migrations/0006_complaint.py
#
# Feature: Complaints (against professionals/customers, tied to a booking).
#
# Also includes a required fix: admin_panel.UserReport and messaging.UserReport
# previously shared the same related_name ('reports_made' / 'reports_received'),
# which Django rejects (fields.E304 / E305 reverse-accessor clash). This is why
# `makemigrations` could not run at all after this point — nothing past 0005
# could ever be generated until this was resolved. Renamed to
# 'admin_reports_made' / 'admin_reports_received' to make it unique.

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('admin_panel', '0005_userreport_alter_adminlog_action'),
        ('bookings', '0002_booking_cancel_reason_booking_cancelled_by'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        # ── Required fix: resolve related_name clash with messaging.UserReport ──
        migrations.AlterField(
            model_name='userreport',
            name='reported_user',
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name='admin_reports_received',
                to=settings.AUTH_USER_MODEL),
        ),
        migrations.AlterField(
            model_name='userreport',
            name='reporter',
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name='admin_reports_made',
                to=settings.AUTH_USER_MODEL),
        ),

        # ── New: Complaint model ─────────────────────────────────────────────
        migrations.CreateModel(
            name='Complaint',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('category', models.CharField(max_length=30, choices=[
                    ('service_quality', 'Service Quality'),
                    ('no_show',         'No Show'),
                    ('payment_dispute', 'Payment Dispute'),
                    ('other',           'Other'),
                ])),
                ('description',     models.TextField()),
                ('status', models.CharField(max_length=20, default='open', choices=[
                    ('open',        'Open'),
                    ('in_progress', 'In Progress'),
                    ('resolved',    'Resolved'),
                    ('rejected',    'Rejected'),
                ])),
                ('resolution_note', models.TextField(blank=True)),
                ('resolved_at',     models.DateTimeField(null=True, blank=True)),
                ('created_at',      models.DateTimeField(auto_now_add=True)),
                ('against', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='complaints_received', to=settings.AUTH_USER_MODEL)),
                ('assigned_to', models.ForeignKey(
                    on_delete=django.db.models.deletion.SET_NULL, null=True, blank=True,
                    related_name='complaints_assigned', to=settings.AUTH_USER_MODEL)),
                ('booking', models.ForeignKey(
                    on_delete=django.db.models.deletion.SET_NULL, null=True, blank=True,
                    related_name='complaints', to='bookings.booking')),
                ('complainant', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='complaints_made', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['-created_at'],
                'indexes': [models.Index(fields=['status'], name='complaint_status_idx')],
            },
        ),
    ]