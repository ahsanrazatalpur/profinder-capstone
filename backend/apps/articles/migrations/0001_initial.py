import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='ArticleCategory',
            fields=[
                ('id',         models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name',       models.CharField(max_length=100, unique=True)),
                ('icon',       models.CharField(default='article', help_text="Material icon name, e.g. 'medical_services'", max_length=50)),
                ('color',      models.CharField(default='#2563EB', help_text='Hex color, e.g. #2563EB', max_length=7)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
            options={
                'verbose_name_plural': 'Article categories',
                'ordering': ['name'],
            },
        ),
        migrations.CreateModel(
            name='Article',
            fields=[
                ('id',           models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title',        models.CharField(max_length=255)),
                ('slug',         models.SlugField(blank=True, max_length=280, unique=True)),
                ('summary',      models.CharField(blank=True, help_text='Short preview shown on magazine list cards.', max_length=300)),
                ('content',      models.TextField()),
                ('cover_image',  models.URLField(blank=True)),
                ('is_published', models.BooleanField(default=False)),
                ('views_count',  models.PositiveIntegerField(default=0)),
                ('read_time',    models.PositiveIntegerField(default=1, help_text='Estimated read time in minutes.')),
                ('published_at', models.DateTimeField(blank=True, null=True)),
                ('created_at',   models.DateTimeField(auto_now_add=True)),
                ('updated_at',   models.DateTimeField(auto_now=True)),
                ('author',   models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='articles', to=settings.AUTH_USER_MODEL)),
                ('category', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='articles', to='articles.articlecategory')),
            ],
            options={
                'ordering': ['-published_at', '-created_at'],
            },
        ),
    ]