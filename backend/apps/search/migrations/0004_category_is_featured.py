# apps/search/migrations/0004_category_is_featured.py

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('search', '0003_favorite'),
    ]

    operations = [
        migrations.AddField(
            model_name='category',
            name='is_featured',
            field=models.BooleanField(default=False),
        ),
    ]