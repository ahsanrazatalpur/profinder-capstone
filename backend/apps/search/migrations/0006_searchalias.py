# apps/search/migrations/0006_searchalias.py
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('search', '0005_searchindex'),
    ]

    operations = [
        migrations.CreateModel(
            name='SearchAlias',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('alias', models.CharField(max_length=100)),
                ('canonical', models.CharField(help_text='English profession word, e.g. lawyer', max_length=100)),
                ('language', models.CharField(blank=True, default='', max_length=10)),
                ('source', models.CharField(blank=True, default='manual', max_length=20)),
                ('is_active', models.BooleanField(default=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
            options={'unique_together': {('alias', 'canonical')}},
        ),
    ]
