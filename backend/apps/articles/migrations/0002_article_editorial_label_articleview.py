import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('articles', '0001_initial'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.AddField(
            model_name='article',
            name='editorial_label',
            field=models.CharField(
                default='ProFinder Editorial',
                help_text="e.g. 'ProFinder Health Desk', 'Legal Advisory Team'",
                max_length=100,
            ),
        ),
        migrations.CreateModel(
            name='ArticleView',
            fields=[
                ('id',          models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('session_key', models.CharField(blank=True, max_length=64)),
                ('viewed_at',   models.DateTimeField(auto_now_add=True)),
                ('article',     models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='view_logs', to='articles.article')),
                ('user',        models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='article_views', to=settings.AUTH_USER_MODEL)),
            ],
            options={'ordering': ['-viewed_at']},
        ),
    ]