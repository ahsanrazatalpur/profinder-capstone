from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('messaging', '0005_alter_message_text'),
    ]

    operations = [
        migrations.AddField(
            model_name='userreport',
            name='action_taken',
            field=models.BooleanField(
                default=False,
                help_text="Tick only if a real violation was found — this triggers a "
                           "warning notification to the reported user. Leave unticked "
                           "for reports that were reviewed but dismissed."
            ),
        ),
    ]
