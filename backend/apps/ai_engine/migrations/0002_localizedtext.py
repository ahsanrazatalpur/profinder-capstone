from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('ai_engine', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='LocalizedText',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('lang', models.CharField(max_length=10)),
                ('kind', models.CharField(max_length=20)),
                ('source_key', models.CharField(max_length=64)),
                ('source', models.TextField()),
                ('translated', models.TextField()),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
            options={
                'unique_together': {('lang', 'kind', 'source_key')},
            },
        ),
    ]