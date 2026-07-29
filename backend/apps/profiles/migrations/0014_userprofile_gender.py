# apps/profiles/migrations/0014_userprofile_gender.py
#
# Adds gender to UserProfile — needed for AI Search intent detection
# (e.g. "female dentist", "male electrician").

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('profiles', '0013_profileview'),
    ]

    operations = [
        migrations.AddField(
            model_name='userprofile',
            name='gender',
            field=models.CharField(
                blank=True, max_length=10,
                choices=[('male', 'Male'), ('female', 'Female'), ('other', 'Other')],
            ),
        ),
    ]