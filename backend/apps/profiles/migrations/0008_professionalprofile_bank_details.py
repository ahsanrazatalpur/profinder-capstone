from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('profiles', '0007_professionalprofile_is_available_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='professionalprofile',
            name='bank_account_name',
            field=models.CharField(blank=True, max_length=255),
        ),
        migrations.AddField(
            model_name='professionalprofile',
            name='bank_account_number',
            field=models.CharField(blank=True, max_length=50),
        ),
        migrations.AddField(
            model_name='professionalprofile',
            name='bank_name',
            field=models.CharField(blank=True, max_length=255),
        ),
    ]