# Generated for report/moderation notifications

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('notifications', '0002_alter_notification_id'),
    ]

    operations = [
        migrations.AlterField(
            model_name='notification',
            name='type',
            field=models.CharField(
                choices=[
                    ('payment', 'Payment'),
                    ('review', 'Review'),
                    ('subscription', 'Subscription'),
                    ('report', 'Report / Moderation'),
                    ('general', 'General'),
                ],
                default='general',
                max_length=20,
            ),
        ),
    ]
