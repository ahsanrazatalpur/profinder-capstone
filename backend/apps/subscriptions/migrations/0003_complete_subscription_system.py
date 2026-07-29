from django.db import migrations, models
import django.db.models.deletion
from django.conf import settings


class Migration(migrations.Migration):

    dependencies = [
        ('subscriptions', '0002_subscriptionplan_currency'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.AddField(
            model_name='subscriptionplan',
            name='plan_type',
            field=models.CharField(max_length=20, choices=[('customer','Customer'),('professional','Professional')], default='professional'),
        ),
        migrations.AddField(
            model_name='subscriptionplan',
            name='billing',
            field=models.CharField(max_length=20, choices=[('free','Free'),('monthly','Monthly'),('yearly','Yearly')], default='free'),
        ),
        migrations.AddField(
            model_name='subscriptionplan',
            name='duration_days',
            field=models.IntegerField(default=0),
        ),
        migrations.AddField(
            model_name='subscriptionplan',
            name='is_active',
            field=models.BooleanField(default=True),
        ),
        migrations.AddField(
            model_name='subscriptionplan',
            name='updated_at',
            field=models.DateTimeField(auto_now=True),
        ),
        migrations.RemoveField(
            model_name='subscriptionplan',
            name='max_bookings',
        ),
        migrations.RemoveField(
            model_name='subscriptionplan',
            name='features',
        ),
        migrations.CreateModel(
            name='PlanFeature',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True)),
                ('key', models.CharField(max_length=100)),
                ('value', models.CharField(max_length=255)),
                ('feature_type', models.CharField(max_length=10, choices=[('int','Integer'),('bool','Boolean'),('str','String')], default='int')),
                ('label', models.CharField(max_length=255, blank=True)),
                ('plan', models.ForeignKey(to='subscriptions.SubscriptionPlan', on_delete=django.db.models.deletion.CASCADE, related_name='features')),
            ],
            options={'unique_together': {('plan', 'key')}},
        ),
        migrations.AddField(
            model_name='subscription',
            name='user',
            field=models.ForeignKey(to=settings.AUTH_USER_MODEL, on_delete=django.db.models.deletion.CASCADE, related_name='subscriptions', null=True),
        ),
        migrations.AddField(
            model_name='subscription',
            name='created_at',
            field=models.DateTimeField(auto_now_add=True, null=True),
        ),
    ]