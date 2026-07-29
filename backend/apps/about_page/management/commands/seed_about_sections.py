# apps/about_page/management/commands/seed_about_sections.py
"""
Seeds the 16 spec'd About Page sections with sensible placeholder copy so
the admin starts from a populated page instead of a blank one. Safe to
re-run — existing section_keys are left untouched (get_or_create), so it
never overwrites content an admin has already edited.

Usage: python manage.py seed_about_sections
"""

from django.core.management.base import BaseCommand

from apps.about_page.models import AboutSection

DEFAULT_SECTIONS = [
    dict(section_key='hero_banner', section_type='hero_banner', order=0,
         title='Connecting You With Trusted Professionals',
         subtitle='Find the right help for every job, right in your neighborhood.',
         cta_text='Get Started', cta_style='primary'),
    dict(section_key='company_story', section_type='company_story', order=1,
         title='Our Story',
         subtitle='Built to make finding reliable help effortless.',
         description='<p>Tell your company\'s founding story here.</p>'),
    dict(section_key='mission', section_type='mission', order=2,
         title='Our Mission',
         description='<p>Describe your mission here.</p>'),
    dict(section_key='vision', section_type='vision', order=3,
         title='Our Vision',
         description='<p>Describe your vision here.</p>'),
    dict(section_key='why_choose_us', section_type='why_choose_us', order=4,
         title='Why Choose Us',
         subtitle='Add cards from the Items tab — one per reason.'),
    dict(section_key='how_it_works', section_type='how_it_works', order=5,
         title='How It Works',
         subtitle='Add steps from the Items tab.'),
    dict(section_key='statistics', section_type='statistics', order=6,
         title='By The Numbers',
         subtitle='Add counters from the Items tab.'),
    dict(section_key='core_values', section_type='core_values', order=7,
         title='Our Core Values',
         subtitle='Add values from the Items tab.'),
    dict(section_key='team_members', section_type='team_members', order=8,
         title='Meet The Team', is_enabled=False,
         subtitle='Optional — add team members from the Items tab.'),
    dict(section_key='investors_partners', section_type='investors_partners', order=9,
         title='Investors & Partners', is_enabled=False,
         subtitle='Optional — add logos from the Items tab.'),
    dict(section_key='certifications', section_type='certifications', order=10,
         title='Certifications', is_enabled=False,
         subtitle='Optional — add certifications from the Items tab.'),
    dict(section_key='awards', section_type='awards', order=11,
         title='Awards', is_enabled=False,
         subtitle='Optional — add awards from the Items tab.'),
    dict(section_key='contact_info', section_type='contact_info', order=12,
         title='Get In Touch',
         extra_data={'phone': '', 'email': '', 'address': '', 'hours': ''}),
    dict(section_key='social_media', section_type='social_media', order=13,
         title='Follow Us',
         extra_data={'facebook': '', 'instagram': '', 'twitter': '',
                     'linkedin': '', 'youtube': ''}),
    dict(section_key='app_info', section_type='app_info', order=14,
         title='Get The App',
         extra_data={'play_store_url': '', 'app_store_url': '', 'version': ''}),
    dict(section_key='legal_links', section_type='legal_links', order=15,
         title='Legal',
         extra_data={'links': [
             {'label': 'Privacy Policy', 'url': ''},
             {'label': 'Terms & Conditions', 'url': ''},
         ]}),
]


class Command(BaseCommand):
    help = 'Seeds the 16 default About Page sections (idempotent).'

    def handle(self, *args, **options):
        created_count = 0
        for data in DEFAULT_SECTIONS:
            section, created = AboutSection.objects.get_or_create(
                section_key=data['section_key'], defaults=data)
            if created:
                created_count += 1
                self.stdout.write(self.style.SUCCESS(f"Created: {section.section_key}"))
            else:
                self.stdout.write(f"Already exists, skipped: {section.section_key}")
        self.stdout.write(self.style.SUCCESS(
            f"Done. {created_count} section(s) created, "
            f"{len(DEFAULT_SECTIONS) - created_count} already existed."))