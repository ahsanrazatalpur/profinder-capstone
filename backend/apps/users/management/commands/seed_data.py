# backend/apps/users/management/commands/seed_data.py
"""
ProFinder Master Seed Command
=============================
Ye aik single unified file hai jo ProFinder ke pore ecosystem ka initial/test
data aik hi command mein populate karti hai.

Usage:
    python manage.py seed_data

Includes:
    1. Search Categories (Healthcare, IT, Electrician, Plumber, etc.)
    2. Subscription Plans & Featured Promotion Packages (PKR Pricing)
    3. Languages (English & Urdu) & Pakistan Cities
    4. Core Users & Profiles (Admin, Verified Professionals, Customers)
    5. Realistic Reviews & Ratings
    6. About Us Page Sections
    7. Help Center & Support Content
    8. ProFinder Magazine Articles & Categories
    9. Search Index & Aliases

Idempotent: Safe to run repeatedly without creating duplicate entries.
"""

from decimal import Decimal
from django.core.management import call_command
from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from apps.users.models import User
from apps.profiles.models import UserProfile, ProfessionalProfile
from apps.search.models import Category
from apps.reviews.models import Review
from apps.subscriptions.models import (
    SubscriptionPlan,
    PlanFeature,
    FeaturedPromotionPackage,
)
from apps.admin_panel.models import Language, City, Country


class Command(BaseCommand):
    help = "Seeds all initial ProFinder data (Categories, Plans, Users, Reviews, Magazine, Support) in one run."

    def add_arguments(self, parser):
        parser.add_argument(
            "--skip-magazine",
            action="store_true",
            help="Skip magazine articles seeding (useful for faster local runs).",
        )

    def handle(self, *args, **options):
        self.stdout.write(self.style.MIGRATE_HEADING("\n🚀 Starting ProFinder Master Data Seeder...\n"))

        self.seed_languages_and_cities()
        self.seed_categories()
        self.seed_monetization()
        self.seed_users_and_profiles()
        self.seed_reviews()
        self.seed_about_and_support()

        if not options.get("skip_magazine"):
            self.seed_magazine()

        self.seed_search_index()

        self.stdout.write(self.style.SUCCESS("\n🎉 Master Data Seeding COMPLETED Successfully!\n"))

    # ─────────────────────────────────────────────────────────────────────────
    # 1. Languages & Cities
    # ─────────────────────────────────────────────────────────────────────────
    def seed_languages_and_cities(self):
        self.stdout.write(self.style.MIGRATE_LABEL("  [1/8] Seeding Languages & Pakistani Cities..."))
        
        # Languages
        languages = [
            {"code": "en", "name": "English", "is_rtl": False},
            {"code": "ur", "name": "Urdu", "is_rtl": True},
        ]
        for lang in languages:
            Language.objects.get_or_create(
                code=lang["code"],
                defaults={
                    "name": lang["name"],
                    "is_rtl": lang["is_rtl"],
                    "status": "active",
                },
            )

        # Country
        pakistan, _ = Country.objects.get_or_create(
            name="Pakistan",
            defaults={"status": "active"},
        )

        # Key Cities of Pakistan
        major_cities = [
            ("Karachi", "Sindh", "karachi"),
            ("Lahore", "Punjab", "lahore"),
            ("Islamabad", "Islamabad Capital Territory", "islamabad"),
            ("Rawalpindi", "Punjab", "rawalpindi"),
            ("Hyderabad", "Sindh", "hyderabad"),
            ("Sukkur", "Sindh", "sukkur"),
            ("Faisalabad", "Punjab", "faisalabad"),
            ("Peshawar", "Khyber Pakhtunkhwa", "peshawar"),
            ("Quetta", "Balochistan", "quetta"),
            ("Multan", "Punjab", "multan"),
        ]
        for name, province, slug in major_cities:
            City.objects.get_or_create(
                country=pakistan,
                name=name,
                defaults={
                    "province": province,
                    "slug": slug,
                    "status": "active",
                },
            )

    # ─────────────────────────────────────────────────────────────────────────
    # 2. Categories
    # ─────────────────────────────────────────────────────────────────────────
    def seed_categories(self):
        self.stdout.write(self.style.MIGRATE_LABEL("  [2/8] Seeding Professional & Service Categories..."))
        
        categories_data = [
            {"name": "Electricians", "order": 1, "is_featured": True, "icon": "flash_on"},
            {"name": "Plumbers", "order": 2, "is_featured": True, "icon": "plumbing"},
            {"name": "AC & Appliance Repair", "order": 3, "is_featured": True, "icon": "ac_unit"},
            {"name": "Carpenters", "order": 4, "is_featured": True, "icon": "carpenter"},
            {"name": "Painters", "order": 5, "is_featured": True, "icon": "format_paint"},
            {"name": "Cleaners & Maid Service", "order": 6, "is_featured": True, "icon": "cleaning_services"},
            {"name": "Tutors & Education", "order": 7, "is_featured": False, "icon": "school"},
            {"name": "IT & Software Developers", "order": 8, "is_featured": False, "icon": "computer"},
            {"name": "Doctors & Healthcare", "order": 9, "is_featured": False, "icon": "medical_services"},
            {"name": "Lawyers & Legal", "order": 10, "is_featured": False, "icon": "gavel"},
            {"name": "Accountants & Finance", "order": 11, "is_featured": False, "icon": "calculate"},
        ]

        for cat in categories_data:
            Category.objects.get_or_create(
                name=cat["name"],
                defaults={
                    "order": cat["order"],
                    "is_featured": cat["is_featured"],
                    "icon": cat["icon"],
                },
            )

    # ─────────────────────────────────────────────────────────────────────────
    # 3. Monetization & Subscriptions
    # ─────────────────────────────────────────────────────────────────────────
    def seed_monetization(self):
        self.stdout.write(self.style.MIGRATE_LABEL("  [3/8] Seeding Subscription Plans & Featured Packages..."))

        # Customer Plans
        customer_plans = [
            {"name": "Free", "plan_type": "customer", "price": Decimal("0.00"), "billing": "free", "duration_days": 0},
            {"name": "Premium Monthly", "plan_type": "customer", "price": Decimal("499.00"), "billing": "monthly", "duration_days": 30},
            {"name": "Premium Yearly", "plan_type": "customer", "price": Decimal("4999.00"), "billing": "yearly", "duration_days": 365},
        ]
        for p in customer_plans:
            SubscriptionPlan.objects.get_or_create(
                name=p["name"],
                plan_type=p["plan_type"],
                billing=p["billing"],
                defaults={
                    "price": p["price"],
                    "duration_days": p["duration_days"],
                    "currency": "PKR",
                    "is_active": True,
                },
            )

        # Professional Plans
        pro_plans = [
            {"name": "Free", "plan_type": "professional", "price": Decimal("0.00"), "billing": "free", "duration_days": 0},
            {"name": "Pro Monthly", "plan_type": "professional", "price": Decimal("499.00"), "billing": "monthly", "duration_days": 30},
            {"name": "Pro Yearly", "plan_type": "professional", "price": Decimal("4999.00"), "billing": "yearly", "duration_days": 365},
        ]
        for p in pro_plans:
            SubscriptionPlan.objects.get_or_create(
                name=p["name"],
                plan_type=p["plan_type"],
                billing=p["billing"],
                defaults={
                    "price": p["price"],
                    "duration_days": p["duration_days"],
                    "currency": "PKR",
                    "is_active": True,
                },
            )

        # Featured Promotion Packages (for Pros to boost visibility)
        featured_pkgs = [
            {"name": "Weekly Spotlight", "duration_days": 7, "price": Decimal("99.00")},
            {"name": "Fortnight Boost", "duration_days": 15, "price": Decimal("199.00")},
            {"name": "Monthly Dominance", "duration_days": 30, "price": Decimal("349.00")},
        ]
        for pkg in featured_pkgs:
            FeaturedPromotionPackage.objects.get_or_create(
                duration_days=pkg["duration_days"],
                defaults={
                    "name": pkg["name"],
                    "price": pkg["price"],
                    "currency": "PKR",
                    "is_active": True,
                },
            )

    # ─────────────────────────────────────────────────────────────────────────
    # 4. Users & Profiles (Admin, Professionals, Customers)
    # ─────────────────────────────────────────────────────────────────────────
    def seed_users_and_profiles(self):
        self.stdout.write(self.style.MIGRATE_LABEL("  [4/8] Seeding Users (Admin, Pros, Customers)..."))

        # A. Superuser / Admin
        admin_email = "admin@profinder.com"
        admin_user, created = User.objects.get_or_create(
            email=admin_email,
            defaults={
                "name": "Super Admin",
                "role": "admin",
                "is_staff": True,
                "is_superuser": True,
                "is_email_verified": True,
            },
        )
        if created:
            admin_user.set_password("Admin@12345")
            admin_user.save()
            UserProfile.objects.get_or_create(
                user=admin_user,
                defaults={"full_name": "ProFinder Administrator", "city": "Karachi", "country": "Pakistan"},
            )

        # B. Professionals
        elec_cat = Category.objects.filter(name="Electricians").first()
        plumb_cat = Category.objects.filter(name="Plumbers").first()
        ac_cat = Category.objects.filter(name="AC & Appliance Repair").first()

        pros_data = [
            {
                "email": "tariq.electrician@profinder.com",
                "name": "Tariq Mahmood",
                "category": elec_cat,
                "specialization": "Master Electrician & UPS Specialist",
                "skills": "Wiring, UPS Installation, Circuit Breakers, LED Lighting",
                "hourly_rate": Decimal("800.00"),
                "pricing_unit": "per_visit",
                "experience_years": 8,
                "city": "Karachi",
                "area": "Gulshan-e-Iqbal",
                "bio": "Certified electrician with 8+ years experience in domestic and commercial electrical repairs.",
            },
            {
                "email": "rashid.plumber@profinder.com",
                "name": "Rashid Khan",
                "category": plumb_cat,
                "specialization": "Sanitary & Pipe Fitting Expert",
                "skills": "Leakage Repair, Geyser Installation, Water Motor, Drain Cleaning",
                "hourly_rate": Decimal("700.00"),
                "pricing_unit": "per_service",
                "experience_years": 6,
                "city": "Lahore",
                "area": "DHA Phase 5",
                "bio": "Fast, reliable plumbing and sanitary fittings with guarantee. Available for emergencies.",
            },
            {
                "email": "imran.ac@profinder.com",
                "name": "Imran Ali",
                "category": ac_cat,
                "specialization": "Inverter AC Technician & Gas Refilling",
                "skills": "AC Installation, Gas Charging, Deep Chemical Wash, PCB Repair",
                "hourly_rate": Decimal("1500.00"),
                "pricing_unit": "per_service",
                "experience_years": 10,
                "city": "Hyderabad",
                "area": "Qasimabad",
                "bio": "Specialized in DC Inverter AC servicing, compressor replacements, and seasonal maintenance.",
            },
        ]

        for p in pros_data:
            pro_user, u_created = User.objects.get_or_create(
                email=p["email"],
                defaults={
                    "name": p["name"],
                    "role": "professional",
                    "is_email_verified": True,
                },
            )
            if u_created:
                pro_user.set_password("Pro@12345")
                pro_user.save()

            UserProfile.objects.get_or_create(
                user=pro_user,
                defaults={
                    "full_name": p["name"],
                    "city": p["city"],
                    "area": p["area"],
                    "country": "Pakistan",
                    "phone": "+923001234567",
                },
            )

            ProfessionalProfile.objects.get_or_create(
                user=pro_user,
                defaults={
                    "category": p["category"],
                    "specialization": p["specialization"],
                    "skills": p["skills"],
                    "hourly_rate": p["hourly_rate"],
                    "pricing_unit": p["pricing_unit"],
                    "experience_years": p["experience_years"],
                    "bio": p["bio"],
                    "is_verified": True,
                    "identity_verified": True,
                    "is_available": True,
                    "average_rating": Decimal("4.8"),
                },
            )

        # C. Customers
        customers_data = [
            {"email": "ahsan.customer@profinder.com", "name": "Ahsan Raza", "city": "Karachi", "area": "Clifton"},
            {"email": "talha.customer@profinder.com", "name": "Talha Arain", "city": "Hyderabad", "area": "Latifabad"},
        ]
        for c in customers_data:
            cust_user, cu_created = User.objects.get_or_create(
                email=c["email"],
                defaults={
                    "name": c["name"],
                    "role": "customer",
                    "is_email_verified": True,
                },
            )
            if cu_created:
                cust_user.set_password("Customer@12345")
                cust_user.save()

            UserProfile.objects.get_or_create(
                user=cust_user,
                defaults={"full_name": c["name"], "city": c["city"], "area": c["area"], "country": "Pakistan"},
            )

    # ─────────────────────────────────────────────────────────────────────────
    # 5. Reviews
    # ─────────────────────────────────────────────────────────────────────────
    def seed_reviews(self):
        self.stdout.write(self.style.MIGRATE_LABEL("  [5/8] Seeding Realistic Service Reviews..."))

        cust1 = User.objects.filter(email="ahsan.customer@profinder.com").first()
        cust2 = User.objects.filter(email="talha.customer@profinder.com").first()
        pro1 = User.objects.filter(email="tariq.electrician@profinder.com").first()
        pro2 = User.objects.filter(email="rashid.plumber@profinder.com").first()

        sample_reviews = [
            (cust1, pro1, 5, "Bohot zabardast kaam kiya Tariq bhai ne! UPS ka masla 30 minute mein hal kar diya."),
            (cust2, pro1, 5, "Punctual, professional, and very reasonable charges. Highly recommended!"),
            (cust1, pro2, 4, "Plumbing work was very neat. Cleaned the work area afterwards too."),
        ]

        for reviewer, pro, rating, comment in sample_reviews:
            if reviewer and pro:
                Review.objects.get_or_create(
                    reviewer=reviewer,
                    professional=pro,
                    defaults={
                        "rating": rating,
                        "comment": comment,
                        "is_verified_service": True,
                    },
                )

    # ─────────────────────────────────────────────────────────────────────────
    # 6. About Page & Help Center
    # ─────────────────────────────────────────────────────────────────────────
    def seed_about_and_support(self):
        self.stdout.write(self.style.MIGRATE_LABEL("  [6/8] Seeding About Sections & Support FAQs..."))
        try:
            call_command("seed_about_sections")
        except Exception as e:
            self.stdout.write(self.style.WARNING(f"    (About sections notice: {e})"))

        try:
            call_command("seed_support_content")
        except Exception as e:
            self.stdout.write(self.style.WARNING(f"    (Support content notice: {e})"))

    # ─────────────────────────────────────────────────────────────────────────
    # 7. Magazine Articles
    # ─────────────────────────────────────────────────────────────────────────
    def seed_magazine(self):
        self.stdout.write(self.style.MIGRATE_LABEL("  [7/8] Seeding ProFinder Magazine Articles & Urdu Content..."))
        try:
            call_command("seed_magazine_articles")
        except Exception as e:
            self.stdout.write(self.style.WARNING(f"    (Magazine notice: {e})"))

    # ─────────────────────────────────────────────────────────────────────────
    # 8. Search Index & Aliases
    # ─────────────────────────────────────────────────────────────────────────
    def seed_search_index(self):
        self.stdout.write(self.style.MIGRATE_LABEL("  [8/8] Building Search Index & Roman Urdu Aliases..."))
        try:
            call_command("generate_aliases")
        except Exception as e:
            self.stdout.write(self.style.WARNING(f"    (Aliases notice: {e})"))

        try:
            call_command("build_search_index")
        except Exception as e:
            self.stdout.write(self.style.WARNING(f"    (Search index notice: {e})"))
