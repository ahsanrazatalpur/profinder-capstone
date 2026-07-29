# apps/reviews/migrations/0003_review_system_upgrade.py
# Generated for the ProFinder Reviews upgrade (photos, replies, helpful
# votes, reports, edit tracking, admin moderation, verified-service badge)

import cloudinary.models
import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('reviews', '0002_alter_review_unique_together'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.AddField(
            model_name='review',
            name='is_verified_service',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='review',
            name='is_edited',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='review',
            name='edited_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='review',
            name='is_hidden',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='review',
            name='hidden_reason',
            field=models.TextField(blank=True),
        ),
        migrations.AddField(
            model_name='review',
            name='hidden_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AlterModelOptions(
            name='review',
            options={'ordering': ['-created_at']},
        ),
        migrations.AddIndex(
            model_name='review',
            index=models.Index(fields=['professional', '-created_at'], name='review_prof_created_idx'),
        ),
        migrations.CreateModel(
            name='ReviewPhoto',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('image', cloudinary.models.CloudinaryField(max_length=255, verbose_name='image')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('review', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='photos', to='reviews.review')),
            ],
        ),
        migrations.CreateModel(
            name='ReviewReply',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('text', models.TextField()),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('review', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='reply', to='reviews.review')),
            ],
        ),
        migrations.CreateModel(
            name='ReviewHelpful',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('review', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='helpful_votes', to='reviews.review')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='helpful_marks', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'unique_together': {('review', 'user')},
            },
        ),
        migrations.CreateModel(
            name='ReviewReport',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('reason', models.CharField(choices=[
                    ('spam', 'Spam'),
                    ('fake', 'Fake Review'),
                    ('abusive', 'Abusive Language'),
                    ('harassment', 'Harassment'),
                    ('off_topic', 'Off-topic'),
                    ('conflict_of_interest', 'Conflict of Interest'),
                    ('other', 'Other'),
                ], max_length=30)),
                ('note', models.TextField(blank=True)),
                ('status', models.CharField(choices=[
                    ('pending', 'Pending'),
                    ('reviewed', 'Reviewed'),
                    ('dismissed', 'Dismissed'),
                    ('actioned', 'Actioned'),
                ], default='pending', max_length=20)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('review', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='reports', to='reviews.review')),
                ('reporter', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='review_reports', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'unique_together': {('review', 'reporter')},
            },
        ),
    ]