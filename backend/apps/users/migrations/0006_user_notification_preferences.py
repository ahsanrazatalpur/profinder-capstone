# Generated for User Notification Preferences
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0005_user_preferred_language'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='push_notifications',
            field=models.BooleanField(default=True),
        ),
        migrations.AddField(
            model_name='user',
            name='email_notifications',
            field=models.BooleanField(default=True),
        ),
    ]
