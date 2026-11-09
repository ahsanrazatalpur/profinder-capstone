from decimal import Decimal
from django.core.management.base import BaseCommand
from apps.subscriptions.models import SubscriptionPlan, FeaturedPromotionPackage


class Command(BaseCommand):
    help = "Seeds default Subscription Plans and Featured Promotion Packages for Pakistan (PKR)"

    def handle(self, *args, **options):
        # 1. Customer Plans
        customer_plans = [
            {"name": "Free", "plan_type": "customer", "price": Decimal("0.00"), "billing": "free", "duration_days": 0},
            {"name": "Premium Monthly", "plan_type": "customer", "price": Decimal("499.00"), "billing": "monthly", "duration_days": 30},
            {"name": "Premium Yearly", "plan_type": "customer", "price": Decimal("4999.00"), "billing": "yearly", "duration_days": 365},
        ]
        for p in customer_plans:
            obj, created = SubscriptionPlan.objects.get_or_create(
                name=p["name"],
                plan_type=p["plan_type"],
                billing=p["billing"],
                defaults={
                    "price": p["price"],
                    "duration_days": p["duration_days"],
                    "currency": "PKR",
                    "is_active": True,
                }
            )
            action = "Created" if created else "Exists"
            self.stdout.write(f"  [{action}] Plan: {obj.name} ({obj.plan_type}) - PKR {obj.price}")

        # 2. Professional Plans
        pro_plans = [
            {"name": "Free", "plan_type": "professional", "price": Decimal("0.00"), "billing": "free", "duration_days": 0},
            {"name": "Pro Monthly", "plan_type": "professional", "price": Decimal("499.00"), "billing": "monthly", "duration_days": 30},
            {"name": "Pro Yearly", "plan_type": "professional", "price": Decimal("4999.00"), "billing": "yearly", "duration_days": 365},
        ]
        for p in pro_plans:
            obj, created = SubscriptionPlan.objects.get_or_create(
                name=p["name"],
                plan_type=p["plan_type"],
                billing=p["billing"],
                defaults={
                    "price": p["price"],
                    "duration_days": p["duration_days"],
                    "currency": "PKR",
                    "is_active": True,
                }
            )
            action = "Created" if created else "Exists"
            self.stdout.write(f"  [{action}] Plan: {obj.name} ({obj.plan_type}) - PKR {obj.price}")

        # 3. Featured Promotion Packages
        featured_pkgs = [
            {"name": "Featured 7 Days", "duration_days": 7, "price": Decimal("99.00")},
            {"name": "Featured 15 Days", "duration_days": 15, "price": Decimal("199.00")},
            {"name": "Featured 30 Days", "duration_days": 30, "price": Decimal("349.00")},
        ]
        for pkg in featured_pkgs:
            obj, created = FeaturedPromotionPackage.objects.get_or_create(
                duration_days=pkg["duration_days"],
                defaults={
                    "name": pkg["name"],
                    "price": pkg["price"],
                    "currency": "PKR",
                    "is_active": True,
                }
            )
            action = "Created" if created else "Exists"
            self.stdout.write(f"  [{action}] Package: {obj.name} - PKR {obj.price}")

        self.stdout.write(self.style.SUCCESS("Successfully verified / seeded all monetization plans and packages!"))
