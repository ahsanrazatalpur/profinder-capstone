from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('admin_panel', '0002_alter_adminlog_options_alter_adminlog_action_and_more'),
    ]

    operations = [
        migrations.CreateModel(
            name='PromoBanner',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True)),
                ('title', models.CharField(max_length=200)),
                ('description', models.TextField()),
                ('image_url', models.URLField(blank=True)),
                ('button_text', models.CharField(default='Get Premium', max_length=100)),
                ('button_link_type', models.CharField(max_length=20, choices=[('subscription','Subscription Page'),('category','Specific Category'),('external_url','External URL'),('offer','Offer Page'),('none','No Action')], default='subscription')),
                ('button_link_value', models.CharField(blank=True, max_length=500)),
                ('target_audience', models.CharField(max_length=30, choices=[('everyone','Everyone'),('guest','Guest Only'),('free_customer','Free Customer'),('premium_customer','Premium Customer'),('free_professional','Free Professional'),('premium_professional','Premium Professional'),('all_customers','All Customers'),('all_professionals','All Professionals')], default='everyone')),
                ('trigger', models.CharField(max_length=20, choices=[('app_open','App Open'),('home','Home Page'),('search','Search Page'),('ai_search','AI Search'),('booking','Booking'),('login','After Login'),('every_x_days','Every X Days')], default='home')),
                ('trigger_x_days', models.IntegerField(default=3)),
                ('is_active', models.BooleanField(default=False)),
                ('priority', models.IntegerField(default=0)),
                ('start_date', models.DateTimeField(blank=True, null=True)),
                ('end_date', models.DateTimeField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
            options={'ordering': ['-priority', '-updated_at']},
        ),
    ]